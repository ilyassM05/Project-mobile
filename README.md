# Decentralized E-Learning Mobile App

A Flutter-based mobile application that combines decentralized learning with blockchain technology for course payments and NFT certificates.

## 🚀 Features

- **User Authentication** - Email/password login with role-based access (Student/Instructor)
- **Course Marketplace** - Browse, search, and filter educational courses
- **Blockchain Payments** - Purchase courses with ETH cryptocurrency on Sepolia testnet
- **NFT Certificates** - Earn ERC-721 certificates on course completion
- **Video Learning** - Integrated video player with progress tracking
- **AI Recommendations** - Deep learning model suggests next lessons
- **Instructor Dashboard** - Create and manage courses

## 🛠️ Technology Stack

- **Frontend:** Flutter 3.x (Dart)
- **Backend:** Firebase (Auth, Firestore, Storage)
- **Blockchain:** Ethereum Sepolia Testnet
- **Smart Contracts:** Solidity 0.8.20
- **Web3:** web3dart package
- **RPC Provider:** Infura/Alchemy

## 📁 Project Structure

```
project-root/
├── lib/                    # Flutter application code
│   ├── config/            # Configuration files
│   ├── models/            # Data models
│   ├── services/          # Business logic services
│   ├── providers/         # State management
│   ├── screens/           # UI screens
│   └── widgets/           # Reusable widgets
├── blockchain/            # Smart contracts
│   ├── contracts/         # Solidity contracts
│   ├── scripts/           # Deployment scripts
│   └── test/              # Contract tests
└── docs/                  # Documentation
    ├── implementation_plan.md
    ├── firebase_setup_guide.md
    ├── blockchain_setup_guide.md
    └── technical_specifications.md
```

## 📚 Documentation

- **[Implementation Plan](docs/implementation_plan.md)** - Complete development roadmap
- **[Firebase Setup Guide](docs/firebase_setup_guide.md)** - Step-by-step Firebase configuration
- **[Blockchain Setup Guide](docs/blockchain_setup_guide.md)** - Smart contract deployment guide
- **[Deep Learning Guide](docs/deep_learning_guide.md)** - Next-lesson recommendation model
- **[Technical Specifications](docs/technical_specifications.md)** - Detailed technical specs

## 🔧 Prerequisites

- Flutter SDK 3.x+
- Node.js 16+ (for Hardhat)
- Firebase account
- Infura or Alchemy account (RPC provider)
- Android Studio / Xcode

## ⚡ Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd project-pfa-mobile
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Set Up Firebase
Follow the [Firebase Setup Guide](docs/firebase_setup_guide.md)

### 4. Set Up Blockchain
Follow the [Blockchain Setup Guide](docs/blockchain_setup_guide.md)

### 5. Run the App
```bash
flutter run
```

## 🔐 Environment Variables

Create `.env` files for sensitive configuration:

**Flutter (root directory):**
```
FIREBASE_API_KEY=your_key
RPC_URL=https://sepolia.infura.io/v3/YOUR_API_KEY
COURSE_PAYMENT_ADDRESS=0x...
CERTIFICATE_ADDRESS=0x...
```

**Blockchain (blockchain/.env):**
```
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_API_KEY
PRIVATE_KEY=your_wallet_private_key
```

## 📦 Smart Contracts

### CoursePayment.sol
Handles course purchases with ETH payments.

**Key Functions:**
- `buyCourse(courseId)` - Purchase a course
- `setCoursePrice(courseId, price)` - Set course price (instructor only)
- `hasPurchased(student, courseId)` - Check purchase status

### CourseCertificate.sol (ERC-721)
Mints NFT certificates for course completion.

**Key Functions:**
- `mintCertificate(student, courseId, courseName)` - Issue certificate
- `getCertificate(tokenId)` - View certificate details
- `getStudentCertificates(student)` - List all student certificates

## 🧪 Testing

### Run Flutter Tests
```bash
flutter test
```

### Run Smart Contract Tests
```bash
cd blockchain
npx hardhat test
```

## 🚢 Deployment

### Deploy Smart Contracts
```bash
cd blockchain
npx hardhat run scripts/deploy.js --network sepolia
```

### Build Flutter App
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 📊 Project Timeline

| Phase | Duration | Focus |
|-------|----------|-------|
| Phase 1 | Week 1 | Setup & Firebase |
| Phase 2 | Week 2 | Authentication & UI |
| Phase 3 | Week 3-4 | Blockchain integration |
| Phase 4 | Week 5 | Instructor features |
| Phase 5 | Week 6 | Testing & deployment |

**Total: 6 weeks**

## 🔒 Security Notes

- ⚠️ This app uses **Sepolia testnet** for demonstration purposes
- Private keys are stored using `flutter_secure_storage` (testnet only)
- Production deployment would require hardware wallet integration
- Smart contracts should be audited before mainnet deployment

## 🤝 Contributing

This is an academic project. If you'd like to contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

This project is for educational purposes.

## 🆘 Troubleshooting

### Common Issues

**Firebase Connection Failed**
- Check `google-services.json` is in `android/app/`
- Verify Firebase configuration in Flutter

**Blockchain Transaction Failed**
- Ensure wallet has test ETH (get from [Sepolia Faucet](https://sepoliafaucet.com/))
- Check RPC URL is correct
- Verify contract addresses

**Video Playback Issues**
- Check Firebase Storage permissions
- Verify video URL format
- Test network connection

## 📞 Support

For questions or issues:
- Check the documentation in `/docs`
- Review implementation plan
- Consult technical specifications

## 🎯 Next Steps

1. Complete Firebase setup
2. Deploy smart contracts to Sepolia
3. Build Flutter UI
4. Test end-to-end flows
5. Create demo content

---

**Built with ❤️ using Flutter, Firebase, and Ethereum**
