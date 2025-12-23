# Firebase Setup Guide

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `elearning-dapp`
4. Enable Google Analytics (optional)
5. Click "Create Project"

---

## Step 2: Add Android App

1. Click "Add app" → Select Android icon
2. Enter Android package name: `com.yourcompany.elearning`
3. Enter app nickname: `E-Learning Mobile`
4. Click "Register app"
5. Download `google-services.json`
6. Place file in: `android/app/google-services.json`

**Update `android/build.gradle`:**
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

**Update `android/app/build.gradle`:**
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

---

## Step 3: Add iOS App (Optional)

1. Click "Add app" → Select iOS icon
2. Enter iOS bundle ID: `com.yourcompany.elearning`
3. Download `GoogleService-Info.plist`
4. Place in: `ios/Runner/GoogleService-Info.plist`
5. Update `ios/Runner/Info.plist` with Firebase configuration

---

## Step 4: Enable Authentication

1. Go to **Authentication** in Firebase Console
2. Click "Get Started"
3. Click "Sign-in method" tab
4. Enable **Email/Password**
5. Save changes

---

## Step 5: Create Firestore Database

1. Go to **Firestore Database**
2. Click "Create database"
3. Select **Start in test mode** (we'll add security rules later)
4. Choose location (closest to your users)
5. Click "Enable"

### Create Collections

Create these collections manually or via code:
- `users`
- `courses`
- `purchases`
- `progress`

### Set Security Rules

Go to **Rules** tab and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Courses collection
    match /courses/{courseId} {
      allow read: if true; // Public read
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.instructorId == request.auth.uid;
    }
    
    // Purchases collection
    match /purchases/{purchaseId} {
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
    
    // Progress collection
    match /progress/{progressId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

Click "Publish"

---

## Step 6: Configure Firebase Storage

1. Go to **Storage**
2. Click "Get started"
3. Start in **test mode**
4. Choose same location as Firestore
5. Click "Done"

### Create Folder Structure

```
/videos
  /{courseId}
    /video1.mp4
    /video2.mp4
/thumbnails
  /{courseId}.jpg
```

### Set Storage Rules

Go to **Rules** tab:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Videos - readable by authenticated users
    match /videos/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Thumbnails - public read
    match /thumbnails/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## Step 7: Flutter Configuration

### Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### Initialize Firebase in Flutter

```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
dart pub global activate flutterfire_cli
flutterfire configure
```

Select your Firebase project when prompted.

### Update `lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

---

## Step 8: Test Firebase Connection

Create test file `lib/test_firebase.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirestore() async {
  final db = FirebaseFirestore.instance;
  
  // Test write
  await db.collection('test').add({
    'message': 'Hello Firebase!',
    'timestamp': FieldValue.serverTimestamp(),
  });
  
  // Test read
  final snapshot = await db.collection('test').get();
  for (var doc in snapshot.docs) {
    print('${doc.id}: ${doc.data()}');
  }
}
```

---

## Step 9: Get Test ETH for Sepolia

Since you'll be doing blockchain transactions, you need test ETH:

1. Create a wallet (will be done in the app)
2. Copy wallet address
3. Go to [Sepolia Faucet](https://sepoliafaucet.com/)
4. Paste your address
5. Request test ETH

---

## Verification Checklist

- [ ] Firebase project created
- [ ] Android app added and `google-services.json` configured
- [ ] iOS app added (if needed)
- [ ] Email/Password authentication enabled
- [ ] Firestore database created with security rules
- [ ] Firebase Storage configured with rules
- [ ] Flutter project configured with Firebase
- [ ] Test connection successful

---

## Troubleshooting

### Android Build Fails
- Check `minSdkVersion` is at least 21
- Verify `google-services.json` is in `android/app/`
- Check Google Services plugin is applied

### iOS Build Fails
- Verify `GoogleService-Info.plist` is added to Xcode project
- Check minimum iOS version is 12.0+
- Run `pod install` in `ios/` folder

### Firestore Permission Denied
- Check security rules allow the operation
- Verify user is authenticated
- Check collection/document paths are correct

---

## Next Steps

After Firebase setup is complete:
1. Set up blockchain integration (RPC provider)
2. Write smart contracts
3. Build Flutter UI
4. Integrate web3dart for blockchain features
