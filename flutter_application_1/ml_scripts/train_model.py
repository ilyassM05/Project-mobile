# =============================================================================
# TRAIN_MODEL.PY - User-to-Course Recommendation Model
# =============================================================================
# WHAT IS THIS FILE?
# This script trains a simple recommendation model that predicts:
# "Given a USER and a COURSE, will the user buy it?"
#
# HOW IT WORKS:
# 1. Load user interaction data (who bought what)
# 2. Convert user IDs and course IDs to numbers
# 3. Train an embedding-based neural network
# 4. Save model for use in Flutter app
#
# OUTPUT:
# - assets/model/recommendation_model.tflite (the trained model)
# - assets/model/label_encoders.json (ID mappings)
# =============================================================================

import tensorflow as tf
import numpy as np
import json
import sklearn
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split

# =============================================================================
# STEP 1: Load Data from JSON file
# =============================================================================
print("Loading data...")
with open('data/user_interactions.json', 'r') as f:
    data = json.load(f)

# Get the list of user-course interactions
interactions = data['interactions']

# =============================================================================
# STEP 2: Prepare Data - Extract features and labels
# =============================================================================
# Features = user ID + course ID
# Label = did they purchase? (1 = yes, 0 = no)

user_ids = [i['userId'] for i in interactions]      # ['user_1', 'user_2', ...]
course_ids = [i['courseId'] for i in interactions]  # ['course_5', 'course_12', ...]
labels = [i['purchased'] for i in interactions]     # [1, 0, 1, 0, ...]

# =============================================================================
# STEP 3: Encode IDs to Numbers
# =============================================================================
# Neural networks need numbers, not strings!
# LabelEncoder: 'user_0' → 0, 'user_1' → 1, etc.

user_encoder = LabelEncoder()
course_encoder = LabelEncoder()

user_encoded = user_encoder.fit_transform(user_ids)    # ['user_0', 'user_1'] → [0, 1]
course_encoded = course_encoder.fit_transform(course_ids)  # ['course_0'] → [0]

num_users = len(user_encoder.classes_)     # How many unique users
num_courses = len(course_encoder.classes_) # How many unique courses

print(f"Num Users: {num_users}, Num Courses: {num_courses}")

# =============================================================================
# STEP 4: Save Mappings for Flutter App
# =============================================================================
# Flutter needs to know: 'user_42' → 42
# So it can use the model on real user IDs

mappings = {
    'user_mapping': {str(label): int(idx) for idx, label in enumerate(user_encoder.classes_)},
    'course_mapping': {str(label): int(idx) for idx, label in enumerate(course_encoder.classes_)}
}
with open('assets/model/label_encoders.json', 'w') as f:
    json.dump(mappings, f)

# =============================================================================
# STEP 5: Split Data into Train/Test Sets
# =============================================================================
# 80% for training, 20% for testing

X_user = np.array(user_encoded)
X_course = np.array(course_encoded)
y = np.array(labels).astype('float32')

X_train_user, X_test_user, X_train_course, X_test_course, y_train, y_test = train_test_split(
    X_user, X_course, y, test_size=0.2, random_state=42
)

# =============================================================================
# STEP 6: Define the Neural Network Model
# =============================================================================
# ARCHITECTURE:
#   User ID → Embedding(50) → Flatten
#                                    → Concatenate → Dense(128) → Dense(64) → Output
#   Course ID → Embedding(50) → Flatten
#
# WHAT IS AN EMBEDDING?
# - Converts an ID (like 42) into a meaningful vector of 50 numbers
# - Similar users will have similar embeddings
# - Similar courses will have similar embeddings

embedding_size = 50  # Each user/course becomes a 50-number vector

# ----- User Input Path -----
user_input = tf.keras.layers.Input(shape=(1,), name='user_input')
# Embedding: user_id → 50-dim vector
user_embedding = tf.keras.layers.Embedding(input_dim=num_users + 1, output_dim=embedding_size)(user_input)
user_vec = tf.keras.layers.Flatten()(user_embedding)  # Flatten to 1D

# ----- Course Input Path -----
course_input = tf.keras.layers.Input(shape=(1,), name='course_input')
# Embedding: course_id → 50-dim vector
course_embedding = tf.keras.layers.Embedding(input_dim=num_courses + 1, output_dim=embedding_size)(course_input)
course_vec = tf.keras.layers.Flatten()(course_embedding)  # Flatten to 1D

# ----- Combine User + Course -----
concat = tf.keras.layers.Concatenate()([user_vec, course_vec])  # 50 + 50 = 100 numbers

# ----- Dense (Fully Connected) Layers -----
dense1 = tf.keras.layers.Dense(128, activation='relu')(concat)  # 128 neurons
dense2 = tf.keras.layers.Dense(64, activation='relu')(dense1)   # 64 neurons

# ----- Output Layer -----
# Sigmoid: outputs probability 0-1 (will user buy?)
output = tf.keras.layers.Dense(1, activation='sigmoid')(dense2)

# Build the final model
model = tf.keras.Model(inputs=[user_input, course_input], outputs=output)

# =============================================================================
# STEP 7: Compile the Model
# =============================================================================
# - Optimizer: Adam (adjusts weights during training)
# - Loss: Binary crossentropy (for yes/no classification)
# - Metrics: Accuracy (how often is it correct?)

model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])

# =============================================================================
# STEP 8: Train the Model
# =============================================================================
print("Training model...")
model.fit(
    [X_train_user, X_train_course],  # Inputs: user IDs and course IDs
    y_train,                          # Labels: 1 = purchased, 0 = not
    epochs=10,                        # Train for 10 passes through the data
    batch_size=64,                    # Process 64 samples at a time
    validation_data=([X_test_user, X_test_course], y_test)  # Test on held-out data
)

# =============================================================================
# STEP 9: Convert to TFLite for Mobile
# =============================================================================
# TFLite = TensorFlow Lite (optimized for mobile devices)
# Flutter can run TFLite models on Android/iOS

print("Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# =============================================================================
# STEP 10: Save the Model
# =============================================================================
with open('assets/model/recommendation_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("Model saved to assets/model/recommendation_model.tflite")
