# Technical Specifications

## Project Information

**Project Name:** Decentralized E-Learning Mobile App  
**Platform:** Flutter (iOS & Android)  
**Version:** 1.0.0  
**Last Updated:** December 2024

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Flutter 3.x | Cross-platform mobile UI |
| **State Management** | Provider | App state management |
| **Backend** | Firebase | Authentication, database, storage |
| **Blockchain** | Ethereum (Sepolia) | Payments & NFT certificates |
| **Smart Contracts** | Solidity 0.8.20 | Course payment & certification logic |
| **RPC Provider** | Infura/Alchemy | Blockchain connectivity |
| **Video Player** | video_player + chewie | Video playback |
| **Web3** | web3dart | Blockchain integration |
| **Storage** | flutter_secure_storage | Wallet key security |
| **Deep Learning** | TensorFlow Lite | Next-lesson recommendations |

---

## System Architecture

```
┌─────────────────────────────────────────────┐
│           Mobile Application                │
│         (Flutter + Dart)                    │
│                                             │
│  ┌─────────────┐      ┌─────────────────┐  │
│  │  UI Layer   │      │  Business Logic │  │
│  │  (Screens)  │◄────►│   (Providers)   │  │
│  └─────────────┘      └─────────────────┘  │
│                              │              │
│                    ┌─────────▼──────────┐   │
│                    │     Services       │   │
│                    │  - Auth            │   │
│                    │  - Blockchain      │   │
│                    │  - Storage         │   │
│                    │  - ML (TFLite)     │   │
│                    └─────────┬──────────┘   │
└──────────────────────────────┼──────────────┘
                               │
        ┌──────────────────────┴─────────────────────┐
        │                      │                      │
┌───────▼────────┐  ┌─────────▼──────────┐  ┌───────▼──────────┐
│   Firebase     │  │ Ethereum Blockchain│  │  TFLite Model    │
│  - Auth        │  │  - CoursePayment   │  │  (On-Device)     │
│  - Firestore   │  │  - CourseCertificate│  │  - Next Lesson   │
│  - Storage     │  │  (Sepolia Testnet) │  │  Recommendation  │
└────────────────┘  └────────────────────┘  └──────────────────┘
                              ▲
                              │
                   ┌──────────┴─────────┐
                   │   RPC Provider     │
                   │  (Infura/Alchemy)  │
                   └────────────────────┘
```

---

## Data Models

### User Model
```dart
class UserModel {
  final String userId;
  final String email;
  final String displayName;
  final String role; // 'student' or 'instructor'
  final String? walletAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Course Model
```dart
class CourseModel {
  final String courseId;
  final String title;
  final String description;
  final String instructorId;
  final String instructorName;
  final double priceETH;
  final String category;
  final List<String> tags;
  final String thumbnailUrl;
  final List<VideoModel> videos;
  final int totalDuration; // seconds
  final int studentsCount;
  final DateTime createdAt;
}
```

### Video Model
```dart
class VideoModel {
  final String videoId;
  final String title;
  final String url;
  final int duration; // seconds
}
```

### Purchase Model
```dart
class PurchaseModel {
  final String purchaseId;
  final String userId;
  final String courseId;
  final String transactionHash;
  final double priceETH;
  final DateTime purchasedAt;
}
```

### Certificate Model
```dart
class CertificateModel {
  final int tokenId;
  final String studentAddress;
  final String courseId;
  final String courseName;
  final DateTime completionDate;
}
```

---

## API Endpoints

### Firebase Firestore Collections

#### users
- **Path:** `/users/{userId}`
- **Methods:** GET, PUT
- **Access:** Authenticated users (own data only)

#### courses
- **Path:** `/courses/{courseId}`
- **Methods:** GET, POST, PUT, DELETE
- **Access:** Public read, instructor write

#### purchases
- **Path:** `/purchases/{purchaseId}`
- **Methods:** GET, POST
- **Access:** User-specific

#### progress
- **Path:** `/progress/{progressId}`
- **Methods:** GET, PUT
- **Access:** User-specific

---

## Smart Contract Interfaces

### CoursePayment Contract

**Address:** `0x...` (deployed on Sepolia)

**Functions:**
```solidity
function setCoursePrice(string courseId, uint256 priceInWei) public
function buyCourse(string courseId) public payable
function getUserPurchases(address student) public view returns (Purchase[])
function hasPurchased(address student, string courseId) public view returns (bool)
```

**Events:**
```solidity
event CoursePurchased(address indexed student, string courseId, uint256 amount, uint256 timestamp)
event CoursePriceSet(string courseId, uint256 price, address instructor)
```

### CourseCertificate Contract

**Address:** `0x...` (deployed on Sepolia)

**Functions:**
```solidity
function mintCertificate(address student, string courseId, string courseName) public returns (uint256)
function getCertificate(uint256 tokenId) public view returns (Certificate)
function getStudentCertificates(address student) public view returns (uint256[])
function verifyCertificate(uint256 tokenId) public view returns (bool, address, string)
```

**Events:**
```solidity
event CertificateMinted(uint256 indexed tokenId, address indexed student, string courseId, string courseName, uint256 completionDate)
```

---

## Security Specifications

### Authentication
- Firebase Authentication with email/password
- JWT tokens for session management
- Automatic token refresh

### Wallet Security
- Private keys stored in `flutter_secure_storage`
- Keys encrypted at rest
- Never transmitted to backend
- **⚠️ Testnet only - production needs hardware wallet**

### Smart Contract Security
- OpenZeppelin ERC-721 implementation
- Reentrancy protection
- Access control on sensitive functions
- Event emission for transparency

### Firebase Security Rules
- Role-based access control
- User data isolation
- Instructor-only course creation
- Public course reading

### Data Privacy
- Personal data encrypted
- GDPR compliance considerations
- Wallet addresses pseudonymous

---

## Performance Requirements

### Mobile App
- Cold start: < 3 seconds
- Screen transitions: < 300ms
- Video buffering: < 2 seconds

### Blockchain
- Transaction confirmation: 15-30 seconds (Sepolia)
- Gas optimization: < 200,000 gas per transaction
- RPC latency: < 500ms

### Firebase
- Firestore query: < 1 second
- Video streaming: Adaptive bitrate
- Storage bandwidth: Optimized for mobile

---

## Network Requirements

### Blockchain Network
- **Network:** Ethereum Sepolia Testnet
- **Chain ID:** 11155111
- **Block Time:** ~12 seconds
- **RPC:** HTTPS endpoint from Infura/Alchemy

### Firebase
- Firestore region: Closest to users
- Storage region: Same as Firestore
- CDN: Firebase CDN for global delivery

---

## Dependencies

### Flutter Packages
```yaml
dependencies:
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  
  # Blockchain
  web3dart: ^2.7.1
  http: ^1.1.2
  
  # Security
  flutter_secure_storage: ^9.0.0
  
  # Media
  video_player: ^2.8.2
  chewie: ^1.7.4
  
  # State Management
  provider: ^6.1.1
  
  # UI
  cached_network_image: ^3.3.1
  
  # Deep Learning
  tflite_flutter: ^0.10.4
```

### Blockchain Dependencies
```json
{
  "hardhat": "^2.19.0",
  "@openzeppelin/contracts": "^5.0.0",
  "@nomicfoundation/hardhat-toolbox": "^4.0.0"
}
```

---

## Testing Strategy

### Unit Tests
- Service layer tests
- Model validation tests
- Utility function tests

### Integration Tests
- Firebase integration
- Blockchain transaction tests
- End-to-end user flows

### Manual Testing
- UI/UX testing
- Device compatibility
- Network conditions
- Edge cases

---

## Deployment Configuration

### Development
- Firebase project: `elearning-dev`
- Blockchain: Sepolia testnet
- Debug mode enabled

### Production (Future)
- Firebase project: `elearning-prod`
- Blockchain: Ethereum mainnet (or L2)
- Release mode, obfuscated

---

## Monitoring & Analytics

### Firebase Analytics
- User engagement metrics
- Course popularity
- Video completion rates

### Blockchain Events
- Transaction monitoring via events
- Purchase tracking
- Certificate issuance

### Error Tracking
- Firebase Crashlytics
- Custom error logging
- Blockchain transaction failures

---

## Scalability Considerations

### Current Scope (MVP)
- 100-1,000 users
- 50-100 courses
- Testnet transactions (free)

### Future Scaling
- Database sharding
- Video CDN optimization
- Layer 2 blockchain solutions
- Caching strategies

---

## Compliance & Legal

### Data Protection
- User consent for data collection
- Right to deletion
- Data portability

### Blockchain Considerations
- Smart contract immutability
- Transaction irreversibility
- Testnet disclaimers

---

## Version Control

### Git Strategy
- Main branch: Production-ready code
- Develop branch: Active development
- Feature branches: Individual features

### Naming Conventions
- Commits: Conventional commits
- Branches: `feature/`, `fix/`, `docs/`
- Tags: Semantic versioning (v1.0.0)

---

## Documentation

### Code Documentation
- Inline comments for complex logic
- Dartdoc for public APIs
- Smart contract NatSpec comments

### User Documentation
- User guide
- FAQ
- Video tutorials

### Technical Documentation
- API reference
- Architecture decision records
- Deployment guide
