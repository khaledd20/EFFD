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
from sklearn.model_selection import KFold, train_test_split, GridSearchCV
from sklearn.metrics import accuracy_score, classification_report
import numpy as np
import logging

# Initialize Firebase Admin SDK
cred = credentials.Certificate(r'C:\Users\khali\Desktop\early_flash_flood_detection\lib\models\early-flash-flood-detection-firebase-adminsdk-vpxfs-5eb9edf55c.json')
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
    try:
        df = pd.DataFrame(data, columns=['waterLevel', 'humidity', 'rainfallIntensity', 'cloudCover'])
        df['rainfallIntensity'].fillna(df['rainfallIntensity'].mean(), inplace=True)
        scaler = StandardScaler()
        features = scaler.fit_transform(df[['waterLevel', 'humidity', 'rainfallIntensity', 'cloudCover']])
        return features
    except Exception as e:
        logging.error(f"Error processing data: {e}")
        return np.array([])  # Return an empty array if there's an error


# Function to select the best model
def select_best_model(X_train, y_train):
    # Number of data points needs to be at least equal to the number of folds for KFold cross-validation
    num_folds = min(len(X_train), 5)  # Use all data points if less than 5, otherwise use 5-fold

    # If less than 2 folds, we cannot perform cross-validation
    if num_folds < 2:
        logging.error("Not enough data points for any kind of cross-validation.")
        return None

    logging.info(f"Performing {num_folds}-fold cross-validation.")
    cv = KFold(n_splits=num_folds)

    param_grid = {
        'n_estimators': [100, 200],
        'max_depth': [4, 8]
    }

    grid_search = GridSearchCV(RandomForestClassifier(), param_grid=param_grid, scoring='accuracy', cv=cv)
    grid_search.fit(X_train, y_train)

    return grid_search.best_estimator_



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
    rainfall_intensity_thresholds = {'Low': 2, 'Moderate': 5, 'High': float('inf')}
    rainfall_intensity_weights = {'Low': 0, 'Moderate': 2, 'High': 4}

    # Start with weather risk weight
    total_weight = weather_weights.get(point.get('weather', 'Sunny'), 0)

    # Add humidity weight if above threshold
    if point.get('humidity', 0) > humidity_threshold:
        total_weight += humidity_weight

    # Add cloud cover weight if above threshold
    if point.get('cloudCover', 0) > cloud_cover_threshold:
        total_weight += cloud_cover_weight

    # Determine water level risk weight
    water_level = point.get('waterLevel', 0)
    if water_level < water_level_threshold_low:
        total_weight += water_level_weights['Low']
    elif water_level <= water_level_threshold_high:
        total_weight += water_level_weights['Moderate']
    else:
        total_weight += water_level_weights['High']

    # Determine rainfall intensity risk weight
    for intensity, threshold in rainfall_intensity_thresholds.items():
        if point.get('rainfallIntensity', 0) <= threshold:
            total_weight += rainfall_intensity_weights[intensity]
            break

    # Return the risk category based on the total risk weight
    return 'Low Risk' if total_weight <= 5 else 'Moderate Risk' if total_weight <= 7 else 'High Risk'



@app.route('/analyze-flood', methods=['POST'])
def analyze_flood():
    try:
        simulated_data_ref = db.collection('simulatedData').stream()
        current_time = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
        all_regions_data = []

        # Initialize a dictionary to store aggregated data for each region
        region_aggregated_data = {region: [] for region in ['Gombak', 'Kajang', 'Ampang']}

        # Iterate over each document and aggregate the data for each region
        for doc in simulated_data_ref:
            doc_data = doc.to_dict()
            for region in region_aggregated_data.keys():
                region_data = doc_data.get(region, [])
                # Assuming each region_data is a list of dictionaries
                region_aggregated_data[region].extend(region_data)

        # Process the aggregated data for each region
        for region, region_data in region_aggregated_data.items():
            region_features = []
            region_labels = []
            time_of_day = []  # List to hold the time of day for stratification

            for point in region_data:
                required_fields = ['waterLevel', 'humidity', 'rainfallIntensity', 'cloudCover', 'timeOfDay']
                if not all(field in point for field in required_fields):
                    missing_fields = [field for field in required_fields if field not in point]
                    logging.error(f"Missing fields in point for region {region}: {missing_fields}")
                    continue

                region_features.append([point[field] for field in ['waterLevel', 'humidity', 'rainfallIntensity', 'cloudCover']])
                region_labels.append(calculate_risk_score(point))
                time_of_day.append(point['timeOfDay'])

            if len(region_features) < 5:
                logging.warning(f"Insufficient data for cross-validation in {region}. Skipping analysis for this region.")
                continue

            features = preprocess_data(region_features)
            if features.size == 0:
                logging.warning(f"Preprocessing failed for {region}. Skipping analysis for this region.")
                continue

            # Separate '6 pm' data points
            pm6_data = [(f, l) for f, l, t in zip(features, region_labels, time_of_day) if t == '6 pm']
            other_data = [(f, l) for f, l, t in zip(features, region_labels, time_of_day) if t != '6 pm']

            # Split other_data
            X_train_other, X_test_other, y_train_other, y_test_other = train_test_split(
                [x[0] for x in other_data], [x[1] for x in other_data], test_size=0.2, random_state=42)

            # Add '6 pm' data points to the test set
            X_test = X_test_other + [x[0] for x in pm6_data]
            y_test = y_test_other + [x[1] for x in pm6_data]
            X_train = X_train_other
            y_train = y_train_other


            # Select and train the best model
            best_model = select_best_model(X_train, y_train)
            if best_model:
                # Prediction and performance evaluation
                predicted_labels = best_model.predict(X_test)
                logging.debug(f"Predicted labels: {predicted_labels}")

                accuracy = accuracy_score(y_test, predicted_labels)
                report = classification_report(y_test, predicted_labels, zero_division=1)

                 # Calculate flood risk for each time
                flood_risk_times = {}
                for time in ['6 am', '12 pm', '6 pm']:
                    logging.debug(f"Available times in data: {[d['timeOfDay'] for d in region_data]}")
                    time_indices = [i for i, point in enumerate(region_data) if point['timeOfDay'] == time]
                    logging.debug(f"time_indices for {time}: {time_indices}")
                    if time_indices:
                        # Get predicted flood risk labels for the current time slot
                        time_predicted_labels = [predicted_labels[i] for i in time_indices if i < len(predicted_labels)]
                        logging.debug(f"time_predicted_labels for {time} in {region}: {time_predicted_labels}")
                        if time_predicted_labels:  # Check if the list is not empty
                            # Count occurrences of each label
                            label_counts = {label: time_predicted_labels.count(label) for label in set(time_predicted_labels)}
                            # Choose the label with the highest count as the flood risk for this time slot
                            flood_risk_times[time] = max(label_counts, key=label_counts.get)
                        else:
                            flood_risk_times[time] = 'Insufficient Data'
                    else:
                        flood_risk_times[time] = 'Insufficient Data'

                # Ensure all time slots are covered
                for time in ['6 am', '12 pm', '6 pm']:
                    if time not in flood_risk_times:
                        flood_risk_times[time] = 'Insufficient Data'

                region_result = {
                    'region': region,
                    'accuracy': accuracy,
                    'classification_report': report,
                    'flood_risk_times': flood_risk_times
                }
                region_result['flood_risk_times'] = flood_risk_times
                all_regions_data.append(region_result)
            else:
                logging.error(f"Failed to train a model for {region}.")

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
