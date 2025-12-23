# Deep Learning Guide - Next Lesson Recommendations

## Overview

A lightweight deep learning model to recommend the **next best lesson** to students based on their learning patterns. This is a focused, simple implementation - not a complex recommendation system.

**Goal:** Suggest which video/lesson the student should watch next within their enrolled courses.

---

## Why Deep Learning (Not Traditional ML)?

**Simple Approach:**
- Track: lesson completion, time spent, quiz scores (if any)
- Predict: "What should I watch next?"
- Model: Small neural network (embedding + dense layers)

**Benefits:**
- ✅ Personalized learning paths
- ✅ Improves engagement
- ✅ Simple to implement
- ✅ Runs locally on device (TFLite)

---

## Architecture

### Model Type: Sequential Neural Network

```
Input Features → Embedding Layer → Dense Layers → Output (Next Lesson)
```

**Input Features:**
- User ID (embedded)
- Current course ID (embedded)
- Last watched lesson ID
- Completion percentage
- Time spent on current lesson
- Sequence of previously watched lessons

**Output:**
- Probability distribution over next lessons
- Pick top recommendation

---

## Implementation Steps

### Step 1: Data Collection (Flutter + Firebase)

Track user behavior in Firestore:

**Collection: `learning_patterns`**
```json
{
  "userId": "user-123",
  "courseId": "course-456",
  "watchHistory": [
    {
      "lessonId": "lesson-1",
      "completionRate": 100,
      "timeSpent": 450,
      "timestamp": "2024-12-01T10:00:00Z"
    },
    {
      "lessonId": "lesson-2",
      "completionRate": 80,
      "timeSpent": 320,
      "timestamp": "2024-12-01T11:00:00Z"
    }
  ]
}
```

### Step 2: Model Training (Python + TensorFlow)

**Environment Setup:**
```bash
pip install tensorflow pandas numpy firebase-admin
```

**Training Script: `train_model.py`**

```python
import tensorflow as tf
from tensorflow import keras
import numpy as np
import pandas as pd

# Model architecture
def create_recommendation_model(num_users, num_courses, num_lessons):
    # Input layers
    user_input = keras.layers.Input(shape=(1,), name='user_id')
    course_input = keras.layers.Input(shape=(1,), name='course_id')
    lesson_input = keras.layers.Input(shape=(1,), name='current_lesson')
    completion_input = keras.layers.Input(shape=(1,), name='completion_rate')
    
    # Embedding layers
    user_embedding = keras.layers.Embedding(
        num_users, 16, name='user_embedding'
    )(user_input)
    user_vec = keras.layers.Flatten()(user_embedding)
    
    course_embedding = keras.layers.Embedding(
        num_courses, 8, name='course_embedding'
    )(course_input)
    course_vec = keras.layers.Flatten()(course_embedding)
    
    lesson_embedding = keras.layers.Embedding(
        num_lessons, 8, name='lesson_embedding'
    )(lesson_input)
    lesson_vec = keras.layers.Flatten()(lesson_embedding)
    
    # Concatenate all features
    concat = keras.layers.Concatenate()([
        user_vec, 
        course_vec, 
        lesson_vec, 
        completion_input
    ])
    
    # Dense layers
    dense1 = keras.layers.Dense(64, activation='relu')(concat)
    dropout1 = keras.layers.Dropout(0.3)(dense1)
    dense2 = keras.layers.Dense(32, activation='relu')(dropout1)
    dropout2 = keras.layers.Dropout(0.3)(dense2)
    
    # Output layer (predict next lesson)
    output = keras.layers.Dense(num_lessons, activation='softmax')(dropout2)
    
    # Build model
    model = keras.Model(
        inputs=[user_input, course_input, lesson_input, completion_input],
        outputs=output
    )
    
    model.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    
    return model

# Train model
model = create_recommendation_model(
    num_users=1000,
    num_courses=100,
    num_lessons=500
)

# Train with your data
# model.fit(X_train, y_train, epochs=10, batch_size=32)

# Save model
model.save('next_lesson_model.h5')
```

### Step 3: Convert to TFLite

```python
# Convert to TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save TFLite model
with open('next_lesson_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("Model converted to TFLite!")
```

### Step 4: Upload to Firebase Storage

```python
import firebase_admin
from firebase_admin import credentials, storage

# Initialize Firebase Admin
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'your-project.appspot.com'
})

# Upload model
bucket = storage.bucket()
blob = bucket.blob('models/next_lesson_model.tflite')
blob.upload_from_filename('next_lesson_model.tflite')

print("Model uploaded to Firebase Storage!")
```

---

## Flutter Integration

### Step 1: Add Dependencies

```yaml
dependencies:
  tflite_flutter: ^0.10.4
  firebase_storage: ^11.6.0
```

### Step 2: Download Model

```dart
// lib/services/ml_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';

class MLService {
  Interpreter? _interpreter;
  
  Future<void> loadModel() async {
    try {
      // Download from Firebase Storage
      final ref = FirebaseStorage.instance.ref('models/next_lesson_model.tflite');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/next_lesson_model.tflite');
      
      // Download if not exists
      if (!await file.exists()) {
        await ref.writeToFile(file);
      }
      
      // Load interpreter
      _interpreter = await Interpreter.fromFile(file);
      print('Model loaded successfully!');
    } catch (e) {
      print('Error loading model: $e');
    }
  }
  
  Future<String> predictNextLesson({
    required int userId,
    required int courseId,
    required int currentLessonId,
    required double completionRate,
    required List<String> allLessonIds,
  }) async {
    if (_interpreter == null) {
      await loadModel();
    }
    
    // Prepare input
    var input = [
      [userId],
      [courseId],
      [currentLessonId],
      [completionRate]
    ];
    
    // Prepare output buffer
    var output = List.filled(allLessonIds.length, 0.0).reshape([1, allLessonIds.length]);
    
    // Run inference
    _interpreter!.runForMultipleInputs(input, {0: output});
    
    // Get top prediction
    int maxIndex = 0;
    double maxProb = 0.0;
    
    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > maxProb) {
        maxProb = output[0][i];
        maxIndex = i;
      }
    }
    
    return allLessonIds[maxIndex];
  }
}
```

### Step 3: Use in UI

```dart
// In video player or course detail screen
final mlService = MLService();

Future<void> getNextLessonRecommendation() async {
  final nextLessonId = await mlService.predictNextLesson(
    userId: currentUser.id,
    courseId: currentCourse.id,
    currentLessonId: currentLesson.id,
    completionRate: 0.8,
    allLessonIds: course.videos.map((v) => v.videoId).toList(),
  );
  
  // Show recommendation to user
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Recommended Next Lesson'),
      content: Text('We suggest watching: ${getLessonTitle(nextLessonId)}'),
      actions: [
        TextButton(
          onPressed: () => navigateToLesson(nextLessonId),
          child: Text('Start Learning'),
        ),
      ],
    ),
  );
}
```

---

## Simple Alternative (Rule-Based)

If you want to start even simpler before training a DL model, use a **rule-based approach**:

```dart
String recommendNextLesson(List<Video> videos, List<String> watchedIds) {
  // Simple logic:
  // 1. If user completed a lesson, suggest the next one in sequence
  // 2. If user skipped lessons, suggest the first unwatched one
  // 3. Otherwise, suggest most popular among other users
  
  for (var video in videos) {
    if (!watchedIds.contains(video.videoId)) {
      return video.videoId;
    }
  }
  
  // All watched, suggest first lesson for review
  return videos.first.videoId;
}
```

**Then upgrade to DL later** when you have enough user data.

---

## Training Data Requirements

### Minimum Data Needed:
- **100+ users** with watch history
- **10+ courses**
- **500+ lesson interactions**

### Data Collection Period:
- Collect data for 2-4 weeks
- Then train the model
- Retrain monthly with new data

### Cold Start Problem:
- **New users:** Use rule-based recommendations
- **New courses:** Recommend lessons in order
- **After 3-5 interactions:** Switch to DL model

---

## Model Performance

### Expected Accuracy:
- **70-80% accuracy** in predicting next lesson
- Better than random (10-20%)
- Good enough for recommendations

### Model Size:
- TFLite model: **< 5 MB**
- Runs on-device (no API calls)
- Fast inference (< 100ms)

---

## Implementation Timeline

| Step | Duration | Task |
|------|----------|------|
| **1. Data Collection** | Week 1-2 | Track user behavior in Firestore |
| **2. Model Training** | Week 3 | Train TensorFlow model |
| **3. Conversion** | Week 3 | Convert to TFLite |
| **4. Integration** | Week 4 | Add to Flutter app |
| **5. Testing** | Week 4 | Test recommendations |

**Total: 4 weeks** (can be done in parallel with other development)

---

## Deployment Strategy

### Phase 1: Rule-Based (Launch)
- Simple sequential recommendations
- Collect user data

### Phase 2: Hybrid (Month 1)
- Train initial DL model
- Use DL for users with history
- Use rules for new users

### Phase 3: Full DL (Month 2+)
- Fully deployed DL model
- Continuous retraining
- A/B testing

---

## Monitoring & Improvement

### Track Metrics:
- Recommendation acceptance rate
- Time to complete courses
- User engagement

### Improve Model:
- Add more features (quiz scores, etc.)
- Expand to recommend across courses
- Personalize learning pace

---

## Summary

**What You're Building:**
- ✅ Lightweight DL model for next-lesson recommendations
- ✅ Runs locally on device (TFLite)
- ✅ Improves over time with more data
- ✅ Falls back to simple rules when needed

**NOT Building:**
- ❌ Complex course recommendation engine
- ❌ Cloud-based ML pipeline
- ❌ Multi-model ensemble

This is a **focused, achievable addition** that adds real value without overwhelming complexity! 🎯
