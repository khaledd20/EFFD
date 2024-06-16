from flask import Flask, request, jsonify
from firebase_admin import credentials, firestore, initialize_app, storage
from datetime import datetime
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import io
import pandas as pd
from sklearn.preprocessing import StandardScaler, PolynomialFeatures
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedKFold, train_test_split, GridSearchCV
from sklearn.metrics import accuracy_score, classification_report, f1_score, precision_score, recall_score, roc_auc_score
from sklearn.impute import KNNImputer
from sklearn.pipeline import Pipeline
from imblearn.over_sampling import SMOTE, SMOTETomek
import numpy as np
import logging
from gevent.pywsgi import WSGIServer

# Initialize Firebase Admin SDK
cred = credentials.Certificate(r'C:\path\to\your\firebase-adminsdk.json')
initialize_app(cred, {'storageBucket': 'your-bucket-name.appspot.com'})
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
        df['humidity-rainfall'] = df['humidity'] * df['rainfallIntensity']  # New feature
        df.fillna(df.mean(), inplace=True)
        
        imputer = KNNImputer(n_neighbors=5)
        scaler = StandardScaler()
        poly = PolynomialFeatures(degree=2, interaction_only=True)
        
        features = Pipeline(steps=[
            ('imputer', imputer),
            ('poly', poly),
            ('scaler', scaler)
        ]).fit_transform(df)
        
        return features
    except Exception as e:
        logging.error(f"Error processing data: {e}")
        return np.array([])

# Function to select the best model
def select_best_model(X_train, y_train):
    num_folds = min(len(X_train), 5)
    if num_folds < 2:
        logging.error("Not enough data points for any kind of cross-validation.")
        return None
    logging.info(f"Performing {num_folds}-fold cross-validation.")
    cv = StratifiedKFold(n_splits=num_folds)
    
    param_grid = {
        'n_estimators': [100, 200, 300],
        'max_depth': [4, 8, 12],
        'min_samples_split': [2, 5, 10]
    }
    
    model = RandomForestClassifier()
    grid_search = GridSearchCV(model, param_grid, scoring='accuracy', cv=cv)
    grid_search.fit(X_train, y_train)
    return grid_search.best_estimator_

def calculate_risk_score(point):
    weather_weights = {'Sunny': 0, 'Rainy': 3, 'Cloudy': 1, 'Snowy': 2}
    humidity_threshold = 85
    cloud_cover_threshold = 60
    water_level_threshold_low = 1
    water_level_threshold_high = 3
    rainfall_intensity_thresholds = {'Low': 2, 'Moderate': 5, 'High': 8}
    risk_weights = {'Low': 1, 'Moderate': 2, 'High': 3}
    
    total_weight = weather_weights.get(point.get('weather', 'Sunny'), 0)
    total_weight += (point.get('humidity', 0) > humidity_threshold)
    total_weight += (point.get('cloudCover', 0) > cloud_cover_threshold)
    total_weight += risk_weights.get(point.get('waterLevel', 'Low'), 0)
    for intensity, threshold in rainfall_intensity_thresholds.items():
        if point.get('rainfallIntensity', 0) <= threshold:
            total_weight += risk_weights[intensity]
            break

    return 'Low Risk' if total_weight <= 3 else 'Moderate Risk' if total_weight <= 5 else 'High Risk'

# Function to create and save bar charts for flood risk times
def bar_chart(flood_risk_times, region_name):
    times = ['6 am', '12 pm', '6 pm']
    risk_levels = [flood_risk_times.get(time, 'No Data') for time in times]
    risk_values = {'Low Risk': 1, 'Moderate Risk': 2, 'High Risk': 3, 'No Data': 0}
    values = [risk_values[risk] for risk in risk_levels]

    plt.figure(figsize=(10, 6))
    bars = plt.bar(times, values, color='green')
    plt.xlabel('Time of Day')
    plt.ylabel('Flood Risk Level')
    plt.title(f'Flood Risk Chart for {region_name}')
    plt.ylim(0, 4)
    plt.yticks([0, 1, 2, 3], ['No Data', 'Low Risk', 'Moderate Risk', 'High Risk'])

    buf = io.BytesIO()
    plt.savefig(buf, format='png')
    plt.close()
    buf.seek(0)
    return save_plot_to_firebase(buf, f"{region_name}_flood_risk_bar_{datetime.now().strftime('%Y%m%d%H%M%S')}.png")

# Function to create and save line charts for flood risk times
def line_chart(flood_risk_times, region_name):
    times = ['6 am', '12 pm', '6 pm']
    risk_levels = [flood_risk_times.get(time, 'No Data') for time in times]
    risk_values = {'Low Risk': 1, 'Moderate Risk': 2, 'High Risk': 3, 'No Data': 0}
    values = [risk_values[risk] for risk in risk_levels]

    plt.figure(figsize=(10, 6))
    plt.plot(times, values, marker='o', linestyle='-', color='blue')
    plt.xlabel('Time of Day')
    plt.ylabel('Flood Risk Level')
    plt.title(f'Flood Risk Line Chart for {region_name}')
    plt.ylim(0, 4)
    plt.yticks([0, 1, 2, 3], ['No Data', 'Low Risk', 'Moderate Risk', 'High Risk'])
    plt.grid(True)

    buf = io.BytesIO()
    plt.savefig(buf, format='png')
    plt.close()
    buf.seek(0)
    return save_plot_to_firebase(buf, f"{region_name}_flood_risk_line_{datetime.now().strftime('%Y%m%d%H%M%S')}.png")

@app.route('/analyze-flood', methods=['POST'])
def analyze_flood():
    try:
        simulated_data_ref = db.collection('simulatedData').stream()
        current_time = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
        all_regions_data = []

        region_aggregated_data = {region: [] for region in ['Gombak', 'Kajang', 'Ampang']}

        for doc in simulated_data_ref:
            doc_data = doc.to_dict()
            for region in region_aggregated_data.keys():
                region_data = doc_data.get(region, [])
                region_aggregated_data[region].extend(region_data)

        for region, region_data in region_aggregated_data.items():
            region_features = []
            region_labels = []
            time_of_day = []

            for point in region_data:
                required_fields = ['waterLevel', 'humidity', 'rainfallIntensity', 'cloudCover', 'timeOfDay']
                if not all(field in point for field in required_fields):
                    logging.error(f"Missing fields in point for region {region}")
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

            smote_tomek = SMOTETomek(random_state=42)
            X_train, y_train = smote_tomek.fit_resample(features, region_labels)

            pm6_data = [(f, l) for f, l, t in zip(features, region_labels, time_of_day) if t == '6 pm']
            other_data = [(f, l) for f, l, t in zip(features, region_labels, time_of_day) if t != '6 pm']

            X_train_other, X_test_other, y_train_other, y_test_other = train_test_split(
                [x[0] for x in other_data], [x[1] for x in other_data], test_size=0.2, random_state=42)

            X_test = X_test_other + [x[0] for x in pm6_data]
            y_test = y_test_other + [x[1] for x in pm6_data]
            X_train = np.vstack([X_train, X_train_other])
            y_train = np.hstack([y_train, y_train_other])

            best_model = select_best_model(X_train, y_train)
            if best_model:
                predicted_labels = best_model.predict(X_test)
                accuracy = accuracy_score(y_test, predicted_labels)
                f1 = f1_score(y_test, predicted_labels, average='weighted')
                precision = precision_score(y_test, predicted_labels, average='weighted')
                recall = recall_score(y_test, predicted_labels, average='weighted')
                roc_auc = roc_auc_score(y_test, best_model.predict_proba(X_test), multi_class='ovr')
                report = classification_report(y_test, predicted_labels, zero_division=1)

                flood_risk_times = {}
                for time in ['6 am', '12 pm', '6 pm']:
                    time_indices = [i for i, point in enumerate(region_data) if point['timeOfDay'] == time]
                    if time_indices:
                        time_predicted_labels = [predicted_labels[i] for i in time_indices if i < len(predicted_labels)]
                        if time_predicted_labels:
                            label_counts = {label: time_predicted_labels.count(label) for label in set(time_predicted_labels)}
                            flood_risk_times[time] = max(label_counts, key=label_counts.get)
                        else:
                            flood_risk_times[time] = 'Insufficient Data'
                    else:
                        flood_risk_times[time] = 'Insufficient Data'

                for time in ['6 am', '12 pm', '6 pm']:
                    if time not in flood_risk_times:
                        flood_risk_times[time] = 'Insufficient Data'

                region_result = {
                    'region': region,
                    'accuracy': accuracy,
                    'f1_score': f1,
                    'precision': precision,
                    'recall': recall,
                    'roc_auc': roc_auc,
                    'classification_report': report,
                    'flood_risk_times': flood_risk_times
                }

                bar_chart_url = bar_chart(flood_risk_times, region)
                line_chart_url = line_chart(flood_risk_times, region)

                region_result['bar_chart_url'] = bar_chart_url
                region_result['line_chart_url'] = line_chart_url

                all_regions_data.append(region_result)
            else:
                logging.error(f"Failed to train a model for {region}.")

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
    http_server = WSGIServer(('0.0.0.0', 5000), app)
    http_server.serve_forever()
