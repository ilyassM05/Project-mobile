# Implementation Plan — Decentralized E-Learning Mobile App

## Project Overview

A Flutter-based mobile application for decentralized e-learning that integrates:
- **Firebase** for authentication, database, and video storage
- **Ethereum blockchain** for course purchases and NFT certificates
- **Simple course browsing** (no ML recommendations)

**Key Simplifications:**
- ✅ On-chain NFT metadata (no IPFS)
- ✅ Simple course browsing (no ML model)
- ✅ Focus on core blockchain features

---

## Technical Architecture

### System Components

```
┌─────────────────────────────────────────┐
│         Flutter Mobile App              │
│  • UI/UX (Material Design)              │
│  • State Management (Provider/Riverpod) │
│  • Web3 Integration (web3dart)          │
└─────────────────────────────────────────┘
         ↓↑                    ↓↑
┌──────────────────┐   ┌─────────────────────────┐
│    Firebase      │   │  Ethereum Sepolia       │
│  • Authentication│   │  • CoursePayment.sol    │
│  • Firestore DB  │   │  • CourseCertificate.sol│
│  • Storage       │   │  (ERC-721 NFT)          │
└──────────────────┘   └─────────────────────────┘
                                ↑
                       ┌─────────────────┐
                       │  RPC Provider   │
                       │ Infura/Alchemy  │
                       └─────────────────┘
```

---

## Phase 1: Foundation Setup (Week 1)

### 1.1 Flutter Project Setup

**Tasks:**
- Initialize Flutter project
- Configure folder structure
- Add dependencies to `pubspec.yaml`

**Folder Structure:**
```
lib/
├── main.dart
├── config/
│   ├── firebase_config.dart
│   └── blockchain_config.dart
├── models/
│   ├── user_model.dart
│   ├── course_model.dart
│   ├── purchase_model.dart
│   └── certificate_model.dart
├── services/
│   ├── auth_service.dart
│   ├── course_service.dart
│   ├── blockchain_service.dart
│   └── storage_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── course_provider.dart
│   └── wallet_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── courses/
│   │   ├── course_list_screen.dart
│   │   ├── course_detail_screen.dart
│   │   └── video_player_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── certificates/
│       └── certificates_screen.dart
└── widgets/
    ├── course_card.dart
    ├── video_player_widget.dart
    └── certificate_card.dart
```

**Dependencies (pubspec.yaml):**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  
  # Web3 / Blockchain
  web3dart: ^2.7.1
  http: ^1.1.2
  
  # Security
  flutter_secure_storage: ^9.0.0
  
  # Video Player
  video_player: ^2.8.2
  chewie: ^1.7.4
  
  # State Management
  provider: ^6.1.1
  
  # UI/UX
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  
  # Utils
  intl: ^0.19.0
  uuid: ^4.3.3
```

### 1.2 Firebase Setup

**Steps:**
1. Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app (package name: `com.yourcompany.elearning`)
3. Add iOS app (bundle ID: `com.yourcompany.elearning`)
4. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
5. Configure Firebase in Flutter

**Firebase Configuration File:**
```dart
// lib/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }
}
```

### 1.3 Firestore Database Schema

**Collections:**

#### `users`
```json
{
  "userId": "auto-generated-id",
  "email": "student@example.com",
  "role": "student",
  "displayName": "John Doe",
  "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "createdAt": "2024-12-01T00:00:00Z",
  "updatedAt": "2024-12-01T00:00:00Z"
}
```

#### `courses`
```json
{
  "courseId": "auto-generated-id",
  "title": "Introduction to Blockchain",
  "description": "Learn blockchain basics",
  "instructorId": "user-id",
  "instructorName": "Jane Smith",
  "priceETH": "0.01",
  "category": "Blockchain",
  "tags": ["blockchain", "web3", "crypto"],
  "thumbnailUrl": "https://...",
  "videos": [
    {
      "videoId": "vid-1",
      "title": "Chapter 1: What is Blockchain",
      "url": "gs://bucket/videos/vid-1.mp4",
      "duration": 600
    }
  ],
  "totalDuration": 3600,
  "studentsCount": 120,
  "createdAt": "2024-12-01T00:00:00Z"
}
```

#### `purchases`
```json
{
  "purchaseId": "auto-generated-id",
  "userId": "user-id",
  "courseId": "course-id",
  "transactionHash": "0x...",
  "priceETH": "0.01",
  "purchasedAt": "2024-12-01T00:00:00Z"
}
```

#### `progress`
```json
{
  "progressId": "auto-generated-id",
  "userId": "user-id",
  "courseId": "course-id",
  "videoProgress": {
    "vid-1": 450,
    "vid-2": 0
  },
  "completionPercentage": 75,
  "lastWatchedAt": "2024-12-01T00:00:00Z"
}
```

**Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /courses/{courseId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && resource.data.instructorId == request.auth.uid;
    }
    
    match /purchases/{purchaseId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
    
    match /progress/{progressId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## Phase 2: Authentication & User Management (Week 1-2)

### Authentication Service
- User registration with role selection
- Email/password login
- Wallet creation on signup
- Profile management

### UI Screens
- Login screen
- Register screen
- Profile screen

---

## Phase 3: Course Management (Week 2)

### Course Service
- Fetch all courses
- Search & filter
- Course details
- Purchase history

### UI Components
- Home screen with course grid
- Course detail page
- Video player screen

---

## Phase 4: Blockchain Integration (Week 3-4)

### Smart Contracts

**CoursePayment.sol:**
- `buyCourse(courseId)` - Purchase course with ETH
- `setCoursePrice(courseId, price)` - Set course price
- `getUserPurchases(address)` - Get purchase history

**CourseCertificate.sol (ERC-721):**
- `mintCertificate(student, courseId, courseName)` - Mint NFT
- `getCertificate(tokenId)` - Get certificate data
- `getStudentCertificates(student)` - Get all student certificates

### RPC Provider Setup
1. Sign up at Infura or Alchemy
2. Create Ethereum project
3. Select Sepolia testnet
4. Copy RPC endpoint URL
## Phase 8: Polish & Deployment (Week 6)

- Deploy smart contracts to Sepolia
- Build Android APK
- Build iOS app
- Create demo data

---

## Estimated Timeline: 6 Weeks

---

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [web3dart Package](https://pub.dev/packages/web3dart)
- [Hardhat Documentation](https://hardhat.org/getting-started/)
- [Sepolia Faucet](https://sepoliafaucet.com/)
