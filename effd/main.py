from flask import Flask, request, jsonify
from firebase_admin import credentials, firestore, initialize_app, storage
from datetime import datetime
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import io
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.metrics import accuracy_score, classification_report
import numpy as np
import logging

# Initialize Firebase Admin SDK
cred = credentials.Certificate(r'C:\Users\khali\Desktop\early_flash_flood_detection\effd\early-flash-flood-detection-firebase-adminsdk-vpxfs-5eb9edf55c.json')
initialize_app(cred, {'storageBucket': 'early-flash-flood-detection.appspot.com'})  
db = firestore.client()
bucket = storage.bucket()

app = Flask(__name__)

# Set up basic logging
logging.basicConfig(level=logging.DEBUG)

# Function to save plot to Firebase Storage and return the file URL
def save_plot_to_firebase(image_stream, file_name):
    blob = bucket.blob(file_name)
    blob.upload_from_string(image_stream.getvalue(), content_type='image/png')
    blob.make_public()
    return blob.public_url

# Function to preprocess data
def preprocess_data(data):
    df = pd.DataFrame(data, columns=['waterLevel', 'humidity', 'rainfallIntensity', 'temperature'])
    df['rainfallIntensity'].fillna(df['rainfallIntensity'].mean(), inplace=True)
    scaler = StandardScaler()
    features = scaler.fit_transform(df[['waterLevel', 'humidity', 'rainfallIntensity', 'temperature']])
    return features

# Function to select the best model
def select_best_model(X_train, y_train):
    param_grid = {
        'n_estimators': [100, 200],
        'max_depth': [4, 8]
    }

    grid_search = GridSearchCV(RandomForestClassifier(), param_grid=param_grid, scoring='accuracy')
    grid_search.fit(X_train, y_train)

    return grid_search.best_estimator_

# Function to calculate flood risk score
def calculate_risk_score(point):
    # Define risk weights for each factor
    weather_weights = {'Sunny': 0, 'Rainy': 3, 'Cloudy': 1, 'Snowy': 2}
    humidity_threshold = 75
    humidity_weight = 1
    temperature_threshold_low = 5
    temperature_threshold_high = 35
    temperature_weight = 1
    water_level_threshold_low = 1
    water_level_threshold_high = 2
    water_level_weights = {'Low': 0, 'Moderate': 2, 'High': 4}
    time_of_day_weight = 1
    season_weights = {'Spring': 2, 'Summer': 1, 'Autumn': 2, 'Winter': 3}
    rainfall_intensity_thresholds = {'Low': 2, 'Moderate': 5, 'High': float('inf')}
    rainfall_intensity_weights = {'Low': 0, 'Moderate': 2, 'High': 4}

    # Calculate risk weights for each factor
    total_weight = weather_weights.get(point.get('weather', 'Sunny'), 0)  # 1. Using .get() to handle missing 'weather' attribute
    if point.get('humidity', 0) > humidity_threshold:
        total_weight += humidity_weight
    if (point.get('temperature', 0) < temperature_threshold_low or
            point.get('temperature', 0) > temperature_threshold_high):
        total_weight += temperature_weight
    water_level = point.get('waterLevel', 0)
    if water_level < water_level_threshold_low:
        total_weight += water_level_weights.get('Low', 0)
    elif water_level <= water_level_threshold_high:
        total_weight += water_level_weights.get('Moderate', 0)
    else:
        total_weight += water_level_weights.get('High', 0)
    if point.get('timeOfDay', '6 am') == '6 pm':  # 2. Default to '6 am' if 'timeOfDay' attribute is missing
        total_weight += time_of_day_weight
    total_weight += season_weights.get(point.get('season', 'Spring'), 0)  # 3. Default to 'Spring' if 'season' attribute is missing
    for intensity, threshold in rainfall_intensity_thresholds.items():
        if point.get('rainfallIntensity', 0) <= threshold:
            total_weight += rainfall_intensity_weights.get(intensity, 0)
            break

    # Define flood risk categories based on the total risk weight
    if total_weight <= 7:
        return 'Low Risk'
    elif total_weight <= 9:
        return 'Moderate Risk'
    else:
        return 'High Risk'



@app.route('/analyze-flood', methods=['POST'])
def analyze_flood():
    try:
        simulated_data_ref = db.collection('simulatedData').stream()
        
        region_features = {'kuala_lumpur': [], 'sarawak': [], 'selangor': []}
        region_labels = {'kuala_lumpur': [], 'sarawak': [], 'selangor': []}
        
        for doc in simulated_data_ref:
            doc_data = doc.to_dict()
            for region in ['kuala_lumpur', 'sarawak', 'selangor']:
                region_data = doc_data.get(region, [])
                for point in region_data:
                    try:
                        region_features[region].append([point['waterLevel'], point['humidity'], point['rainfallIntensity'], point['temperature']])
                        region_labels[region].append(calculate_risk_score(point))
                    except KeyError as e:
                        logging.error(f"Missing data in point: {e}")

        if not any(features for features in region_features.values()) or not any(labels for labels in region_labels.values()):
            raise ValueError("No valid data points found for analysis.")
        
        current_time = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
        all_regions_data = {}
        
        # Analyze each region separately
        for region in ['kuala_lumpur', 'sarawak', 'selangor']:
            features = region_features[region]
            labels = region_labels[region]

            if not features or not labels:
                logging.warning(f"No valid data points found for {region}. Skipping analysis for this region.")
                continue

            features = preprocess_data(features)
            X_train, X_test, y_train, y_test = train_test_split(features, labels, test_size=0.2, random_state=42)

            best_model = select_best_model(X_train, y_train)
            best_model.fit(X_train, y_train)

            predicted_labels = best_model.predict(X_test)

            accuracy = accuracy_score(y_test, predicted_labels)
            report = classification_report(y_test, predicted_labels)

            logging.debug(f"Region: {region}, Accuracy: {accuracy}")
            logging.debug(f"Region: {region}, Classification Report: {report}")

            # Calculate flood risk for each time
            flood_risk_times = {}
            for time in ['6 am', '12 pm', '6 pm']:
                time_indices = [i for i, point in enumerate(region_data) if point['timeOfDay'] == time]
                if time_indices:
                    # Get predicted flood risk labels for the current time slot
                    time_predicted_labels = [predicted_labels[i] for i in time_indices]
                    # Count occurrences of each label
                    label_counts = {label: time_predicted_labels.count(label) for label in set(time_predicted_labels)}
                    # Choose the label with the highest count as the flood risk for this time slot
                    flood_risk_times[time] = max(label_counts, key=label_counts.get)
                else:
                    flood_risk_times[time] = 'Insufficient Data'


            # Generate bar chart
            plt.figure(figsize=(10, 5))
            # Define the flood risk levels and their corresponding colors
            risk_levels = ['Low Risk', 'Moderate Risk', 'High Risk']
            colors = ['green', 'yellow', 'red']
            # Iterate over the time slots and plot the corresponding flood risk level
            for i, time in enumerate(['6 am', '12 pm', '6 pm']):
                risk_level = flood_risk_times.get(time, 'Insufficient Data')
                # Get the index of the risk level in the predefined list
                risk_index = risk_levels.index(risk_level)
                # Plot the bar with the corresponding color
                plt.bar(time, 1, color=colors[risk_index], label=risk_level)
            plt.xlabel('Time of Day')
            plt.ylabel('Flood Risk Level')
            plt.title(f'Flood Risk Analysis for {region}')
            plt.legend(loc='upper right')  # Add legend to show the risk levels
            plt.ylim(0, 1)  # Limit the y-axis to match the risk score range
            plt.xticks(rotation=45)  # Rotate x-axis labels for better readability
            plt.tight_layout()  # Adjust layout to prevent clipping of labels
            bar_chart_image_stream = io.BytesIO()
            plt.savefig(bar_chart_image_stream, format='png')
            bar_chart_image_stream.seek(0)
            bar_chart_image_url = save_plot_to_firebase(bar_chart_image_stream, f"flood_risk_chart_{region}_{current_time}.png")

            all_regions_data[region] = {
                'accuracy': accuracy,
                'classification_report': report,
                'flood_risk_times': flood_risk_times,
                'bar_chart_image_url': bar_chart_image_url
            }



        # Store all regions data in one document in Firestore
        flood_data_ref = db.collection('floodData').document(current_time)
        flood_data_ref.set({
            'date': current_time.split('_')[0],
            'time': current_time.split('_')[1],
            'all_regions_data': all_regions_data
        })

        return jsonify({'message': 'Flood analysis completed successfully for all regions'}), 200
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(debug=True)
