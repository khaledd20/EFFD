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
from sklearn.model_selection import train_test_split, GridSearchCV, StratifiedKFold
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
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

# Function to save plot to Firebase Storage and return the file URL
def save_plot_to_firebase(image_stream, file_name):
    blob = bucket.blob(file_name)
    blob.upload_from_string(image_stream.getvalue(), content_type='image/png')
    blob.make_public()
    return blob.public_url

# Function to preprocess data
def preprocess_data(data):
    df = pd.DataFrame(data, columns=['waterLevel', 'humidity', 'rainfallIntensity', 'cloudCover'])
    df['rainfallIntensity'].fillna(df['rainfallIntensity'].mean(), inplace=True)
    scaler = StandardScaler()
    features = scaler.fit_transform(df[['waterLevel', 'humidity', 'rainfallIntensity', 'cloudCover']])
    return features

def select_best_model(X_train, y_train):
    # This is a basic approach and might need to be revised for more robust evaluation in a production setting
    if len(X_train) > 1:  # Ensure there is at least some data to split
        X_train_split, X_val_split, y_train_split, y_val_split = train_test_split(
            X_train, y_train, test_size=0.33, random_state=42)  # Hold out 33% of the data for testing
        
        model = RandomForestClassifier(n_estimators=100, max_depth=4)
        model.fit(X_train_split, y_train_split)
        predictions = model.predict(X_val_split)
        accuracy = accuracy_score(y_val_split, predictions)
        print(f"Model trained with an accuracy of: {accuracy:.2f}")
        return model
    else:
        # Not enough data to even split; return a default model or handle the scenario appropriately
        print("Insufficient data for training.")
        return None

# Function to calculate flood risk score
def calculate_risk_score(point):
    # Define risk weights for each factor
    weather_weights = {'Sunny': 0, 'Rainy': 3, 'Cloudy': 1, 'Snowy': 2}
    humidity_threshold = 75
    humidity_weight = 1
    cloud_cover_threshold = 50
    cloud_cover_weight = 1
    water_level_threshold_low = 1
    water_level_threshold_high = 2
    water_level_weights = {'Low': 0, 'Moderate': 2, 'High': 4}
    time_of_day_weight = 1
    season_weights = {'Spring': 2, 'Summer': 1, 'Autumn': 2, 'Winter': 3}
    rainfall_intensity_thresholds = {'Low': 2, 'Moderate': 5, 'High': float('inf')}
    rainfall_intensity_weights = {'Low': 0, 'Moderate': 2, 'High': 4}

    total_weight = weather_weights.get(point.get('weather', 'Sunny'), 0)
    if point.get('humidity', 0) > humidity_threshold:
        total_weight += humidity_weight
    if point.get('cloudCover', 0) > cloud_cover_threshold:
        total_weight += cloud_cover_weight
    water_level = point.get('waterLevel', 0)
    if water_level < water_level_threshold_low:
        total_weight += water_level_weights['Low']
    elif water_level <= water_level_threshold_high:
        total_weight += water_level_weights['Moderate']
    else:
        total_weight += water_level_weights['High']
    total_weight += time_of_day_weight if point.get('timeOfDay', '6 am') == '6 pm' else 0
    total_weight += season_weights.get(point.get('season', 'Spring'), 0)
    for intensity, threshold in rainfall_intensity_thresholds.items():
        if point.get('rainfallIntensity', 0) <= threshold:
            total_weight += rainfall_intensity_weights[intensity]
            break
    return 'Low Risk' if total_weight <= 7 else 'Moderate Risk' if total_weight <= 9 else 'High Risk'


@app.route('/analyze-flood', methods=['POST'])
def analyze_flood():
    try:
        simulated_data_ref = db.collection('simulatedData').stream()

        current_time = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
        all_regions_data = []

        for doc in simulated_data_ref:
            doc_data = doc.to_dict()
            for region in ['Gombak', 'Kajang', 'Ampang']:
                region_features = []
                region_labels = []

                region_data = doc_data.get(region, [])
                for point in region_data:
                    logging.debug(f"Data point for {region}: {point}")
                    required_fields = ['waterLevel', 'humidity', 'rainfallIntensity', 'cloudCover']
                    if not all(field in point for field in required_fields):
                        missing_fields = [field for field in required_fields if field not in point]
                        logging.error(f"Missing fields in point for region {region}: {missing_fields}")
                        return jsonify({'error': f"Missing fields in point for region {region}: {missing_fields}"}), 400
                    region_features.append([point[field] for field in required_fields])
                    region_labels.append(calculate_risk_score(point))

                if not region_features or not region_labels:
                    logging.warning(f"No valid data points found for {region}. Skipping analysis for this region.")
                    continue

                features = preprocess_data(region_features)
                X_train, X_test, y_train, y_test = train_test_split(features, region_labels, test_size=0.2, random_state=42)

                try:
                    best_model = select_best_model(X_train, y_train)
                    best_model.fit(X_train, y_train)
                    predicted_labels = best_model.predict(X_test)

                    accuracy = accuracy_score(y_test, predicted_labels)
                    report = classification_report(y_test, predicted_labels, output_dict=True)  # Convert report to dictionary for JSON serialization

                    # Calculate flood risk times based on the data points
                    flood_risk_times = {}
                    for point in region_data:
                        time = point.get('timeOfDay', '6 am')
                        if time not in flood_risk_times:
                            flood_risk_times[time] = calculate_risk_score(point)

                    # Store the results for the current region
                    region_result = {
                        'region': region,
                        'accuracy': accuracy,
                        'classification_report': report,
                        'flood_risk_times': flood_risk_times
                    }
                    all_regions_data.append(region_result)
                except ValueError as ve:
                    logging.error(f"A ValueError occurred while processing data for {region}: {ve}")
                    return jsonify({'error': f"Insufficient data points for training and testing in {region}."}), 400
                except Exception as e:
                    logging.error(f"An error occurred while processing data for {region}: {e}")
                    return jsonify({'error': f"An error occurred while processing data for {region}."}), 500

        # Store all regions data in one document in Firestore
        flood_data_ref = db.collection('floodData').document(current_time)
        flood_data_ref.set({
            'date': current_time.split('_')[0],
            'time': current_time.split('_')[1],
            'all_regions_data': all_regions_data
        })

        return jsonify({'message': 'Flood analysis completed successfully for all regions', 'data': all_regions_data}), 200
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        return jsonify({'error': str(e)}), 500



if __name__ == '__main__':
    app.run(debug=True)
