from flask import Flask, request, jsonify
from firebase_admin import credentials, firestore, initialize_app, storage
from datetime import datetime
import matplotlib
matplotlib.use('Agg')  # This directive tells matplotlib to use a backend that does not require a windowing system.
import matplotlib.pyplot as plt
import io
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, GridSearchCV
#from sklearn.tree import plot_tree
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
    # Fill missing values in 'rainfallIntensity' with mean
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

@app.route('/analyze-flood', methods=['POST'])
def analyze_flood():
    try:
        simulated_data_ref = db.collection('simulatedData').stream()
        features, labels, times_of_day = [], [], []
        for doc in simulated_data_ref:
            data = doc.to_dict()
            for point in data.get('dataPoints', []):
                try:
                    features.append([point['waterLevel'], point['humidity'], point['rainfallIntensity'], point['temperature']])
                    water_level, humidity, time_of_day = point['waterLevel'], point['humidity'], point['timeOfDay']
                    times_of_day.append(time_of_day)
                    if water_level > 3.5 or humidity > 90:
                        labels.append('High')  # High risk
                    elif water_level > 2.5 or humidity > 80:
                        labels.append('Moderate')  # Moderate risk
                    else:
                        labels.append('Low')  # Low risk
                except KeyError as e:
                    logging.error(f"Missing data in point: {e}")

        if not features or not labels or not times_of_day:
            raise ValueError("No valid data points found for analysis.")

        # Preprocess data
        features = preprocess_data(features)

        # Split Data
        X_train, X_test, y_train, y_test, times_train, times_test = train_test_split(features, labels, times_of_day, test_size=0.2, random_state=42)

        # Model Training
        best_model = select_best_model(X_train, y_train)
        best_model.fit(X_train, y_train)

        # Flood Prediction
        predicted_labels = best_model.predict(X_test)

        # Model Evaluation
        accuracy = accuracy_score(y_test, predicted_labels)
        report = classification_report(y_test, predicted_labels)

        logging.debug(f"Accuracy: {accuracy}")
        logging.debug(f"Classification Report: {report}")


        # After model training
        #plt.figure(figsize=(20, 10))
        #for i, tree in enumerate(best_model.estimators_):
        #    plt.subplot(2, 5, i + 1)
        #    plot_tree(tree, filled=True, feature_names=['waterLevel', 'humidity', 'rainfallIntensity', 'temperature'], class_names=['Low', 'Moderate', 'High'])
        #    plt.title(f'Decision Tree {i + 1}')
        #plt.tight_layout()
        #plt.savefig("decision_trees.png")  # Save the plot
        #plt.close()  # Close the plot to release memory

        
        # Generate and save bar chart
        plt.figure(figsize=(10, 5))
        colors = ['green', 'yellow', 'red']
        risk_levels = {'Low': 0, 'Moderate': 0, 'High': 0}
        for label in predicted_labels:
            if label == 'Low':
                risk_levels['Low'] += 1
            elif label == 'Moderate':
                risk_levels['Moderate'] += 1
            else:
                risk_levels['High'] += 1
        
        bars = plt.bar(times_test, predicted_labels, color=colors)
        plt.xlabel('Time of Day')
        plt.ylabel('Risk Level')
        plt.title('Flood Risk Analysis (Bar Chart)')
        for bar, label in zip(bars, predicted_labels):
            plt.text(bar.get_x() + bar.get_width() / 2, bar.get_height(), str(label), ha='center', va='bottom')

        img_stream = io.BytesIO()
        plt.savefig(img_stream, format='png')
        img_stream.seek(0)
        current_time = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
        bar_chart_image_url = save_plot_to_firebase(img_stream, f"flood_analysis_bar_{current_time}.png")

        # Generate and save line chart
        plt.figure(figsize=(10, 5))
        plt.plot(times_test, predicted_labels, color='blue', marker='o', linestyle='-', linewidth=2)
        plt.xlabel('Time of Day')
        plt.ylabel('Risk Level')
        plt.title('Flood Risk Analysis (Line Chart)')
        plt.grid(True)

        img_stream = io.BytesIO()
        plt.savefig(img_stream, format='png')
        img_stream.seek(0)
        line_chart_image_url = save_plot_to_firebase(img_stream, f"flood_analysis_line_{current_time}.png")

        # Store the analysis result and image URLs in Firestore
        flood_data_ref = db.collection('floodData').document(current_time)
        flood_data_ref.set({
            'riskLevels': risk_levels,
            'timeOfDayRiskLevels': {time: level for time, level in zip(times_test, predicted_labels)},
            'date': current_time.split('_')[0],
            'time': current_time.split('_')[1],
            'barChartImageUrl': bar_chart_image_url,
            'lineChartImageUrl': line_chart_image_url,
            'accuracy': accuracy,
            'classificationReport': report
        })

        return jsonify({'message': 'Flood analysis completed successfully', 'barChartImageUrl': bar_chart_image_url, 'lineChartImageUrl': line_chart_image_url, 'accuracy': accuracy, 'classificationReport': report}), 200
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
