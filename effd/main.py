from flask import Flask, request, jsonify
from firebase_admin import credentials, firestore, initialize_app, storage
from datetime import datetime
import matplotlib
matplotlib.use('Agg')  # This directive tells matplotlib to use a backend that does not require a windowing system.
import matplotlib.pyplot as plt
import io
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
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

@app.route('/analyze-flood', methods=['POST'])
def analyze_flood():
    try:
        simulated_data_ref = db.collection('simulatedData').stream()
        features, labels = [], []
        for doc in simulated_data_ref:
            data = doc.to_dict()
            for point in data.get('dataPoints', []):
                try:
                    features.append([point['waterLevel'], point['humidity']])
                    water_level, humidity = point['waterLevel'], point['humidity']
                    if water_level > 3.5 or humidity > 90:
                        labels.append(2)  # High risk
                    elif water_level > 2.5 or humidity > 80:
                        labels.append(1)  # Moderate risk
                    else:
                        labels.append(0)  # Low risk
                except KeyError as e:
                    logging.error(f"Missing data in point: {e}")

        if not features or not labels:
            raise ValueError("No valid data points found for analysis.")

        # Split Data
        X_train, X_test, y_train, y_test = train_test_split(features, labels, test_size=0.2, random_state=42)

        # Model Training
        clf = RandomForestClassifier(n_estimators=100)
        clf.fit(X_train, y_train)

        # Flood Prediction
        predicted_labels = clf.predict(X_test)

        # Model Evaluation
        accuracy = accuracy_score(y_test, predicted_labels)
        report = classification_report(y_test, predicted_labels)

        logging.debug(f"Accuracy: {accuracy}")
        logging.debug(f"Classification Report: {report}")
        
        # Generate and save bar chart
        plt.figure(figsize=(10, 5))
        colors = ['green', 'yellow', 'red']
        risk_levels = {'Low': 0, 'Moderate': 0, 'High': 0}
        for label in predicted_labels:
            if label == 0:
                risk_levels['Low'] += 1
            elif label == 1:
                risk_levels['Moderate'] += 1
            else:
                risk_levels['High'] += 1
        
        bars = plt.bar(risk_levels.keys(), risk_levels.values(), color=colors)
        plt.xlabel('Risk Level')
        plt.ylabel('Frequency')
        plt.title('Flood Risk Analysis (Bar Chart)')
        for bar, label in zip(bars, risk_levels.values()):
            plt.text(bar.get_x() + bar.get_width() / 2, bar.get_height(), str(label), ha='center', va='bottom')

        img_stream = io.BytesIO()
        plt.savefig(img_stream, format='png')
        img_stream.seek(0)
        current_time = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
        bar_chart_image_url = save_plot_to_firebase(img_stream, f"flood_analysis_bar_{current_time}.png")

        # Generate and save pie chart
        plt.figure(figsize=(6, 6))
        plt.pie(risk_levels.values(), labels=risk_levels.keys(), autopct='%1.1f%%', colors=colors)
        plt.title('Flood Risk Analysis (Pie Chart)')

        img_stream = io.BytesIO()
        plt.savefig(img_stream, format='png')
        img_stream.seek(0)
        pie_chart_image_url = save_plot_to_firebase(img_stream, f"flood_analysis_pie_{current_time}.png")

        # Store the analysis result and image URLs in Firestore
        flood_data_ref = db.collection('floodData').document(current_time)
        flood_data_ref.set({
            'riskLevels': risk_levels,
            'date': current_time.split('_')[0],
            'time': current_time.split('_')[1],
            'barChartImageUrl': bar_chart_image_url,
            'pieChartImageUrl': pie_chart_image_url,
            'accuracy': accuracy,
            'classificationReport': report
        })

        return jsonify({'message': 'Flood analysis completed successfully', 'barChartImageUrl': bar_chart_image_url, 'pieChartImageUrl': pie_chart_image_url, 'accuracy': accuracy, 'classificationReport': report}), 200
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
