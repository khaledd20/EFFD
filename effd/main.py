from flask import Flask, request, jsonify
from firebase_admin import credentials, firestore, initialize_app, storage
from datetime import datetime
import matplotlib
matplotlib.use('Agg')  # Ensure matplotlib doesn't try to use a GUI backend
import matplotlib.pyplot as plt
import io

# Initialize Firebase Admin SDK
cred = credentials.Certificate(r'C:\Users\khali\Desktop\early_flash_flood_detection\effd\early-flash-flood-detection-firebase-adminsdk-vpxfs-5eb9edf55c.json')
initialize_app(cred, {'storageBucket': 'early-flash-flood-detection.appspot.com'})  
db = firestore.client()
bucket = storage.bucket()  # Initialize Firebase Storage

app = Flask(__name__)

# Function to save plot to Firebase Storage and return the file URL
def save_plot_to_firebase(image_stream, file_name):
    blob = bucket.blob(file_name)
    blob.upload_from_string(image_stream.getvalue(), content_type='image/png')
    blob.make_public()
    return blob.public_url

# Define an endpoint to trigger the flood analysis process
@app.route('/analyze-flood', methods=['POST'])
def analyze_flood():
    try:
        simulated_data_ref = db.collection('simulatedData').stream()
        data_points = []
        for doc in simulated_data_ref:
            data = doc.to_dict()
            data_points.extend(data.get('dataPoints', []))

        risk_levels = {'high': 0, 'moderate': 0, 'low': 0}
        for data_point in data_points:
            water_level = data_point.get('waterLevel', 0)
            humidity = data_point.get('humidity', 0)
            if water_level > 3.5 or humidity > 90:
                risk_levels['high'] += 1
            elif water_level > 2.5 or humidity > 80:
                risk_levels['moderate'] += 1
            else:
                risk_levels['low'] += 1

        # Generate bar chart
        plt.figure()
        plt.bar(risk_levels.keys(), risk_levels.values())
        plt.xlabel('Risk Level')
        plt.ylabel('Frequency')
        plt.title('Flood Risk Analysis')

        # Save plot to a BytesIO stream
        img_stream = io.BytesIO()
        plt.savefig(img_stream, format='png')
        img_stream.seek(0)  # Go to the beginning of the stream

        # Save the image to Firebase Storage and get the URL
        current_time = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
        image_url = save_plot_to_firebase(img_stream, f"flood_analysis_{current_time}.png")

        # Store the analysis result and image URL in Firestore
        flood_data_ref = db.collection('floodData').document(current_time)
        flood_data_ref.set({
            'riskLevels': risk_levels,
            'date': current_time.split('_')[0],
            'time': current_time.split('_')[1],
            'imageUrl': image_url  # Store image URL
        })

        return jsonify({'message': 'Flood analysis completed successfully', 'imageUrl': image_url}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
