# Setup Instructions - Flutter Installation Required

## ⚠️ Flutter SDK Not Detected

To proceed with this project, you need to install Flutter SDK on your Windows system.

## Installation Steps

### 1. Download Flutter
- Visit: https://docs.flutter.dev/get-started/install/windows
- Download the latest stable Flutter SDK (zip file)

### 2. Extract Flutter
- Extract the zip file to a permanent location
- Recommended: `C:\src\flutter`
- **Do NOT** install in `C:\Program Files\` (requires elevated permissions)

### 3. Add Flutter to PATH
1. Search for "Environment Variables" in Windows Start Menu
2. Click "Environment Variables"
3. Under "User variables", find "Path"
4. Click "Edit" → "New"
5. Add: `C:\src\flutter\bin` (or your installation path)
6. Click "OK" to save

### 4. Verify Installation
Open a **new** PowerShell/Command Prompt and run:
```bash
flutter doctor
```

This will check your Flutter installation and show what else needs to be set up.

### 5. Install Required Dependencies
Flutter doctor will guide you to install:
- **Android Studio** (for Android development)
  - Download from: https://developer.android.com/studio
  - During installation, make sure to install Android SDK
- **VS Code** (recommended IDE)
  - Download from: https://code.visualstudio.com/
  - Install Flutter and Dart extensions
- **Git for Windows** (if not already installed)

### 6. Accept Android Licenses
After installing Android Studio:
```bash
flutter doctor --android-licenses
```
Type 'y' to accept all licenses.

## Alternative: Start with Backend First

While installing Flutter, we can work on:
1. **Smart Contracts** - Set up Hardhat and write Solidity contracts
2. **Firebase Setup** - Create and configure Firebase project
3. **ML Model** - Prepare Python environment for the recommendation model

## After Flutter Installation

Once Flutter is installed, run in the project directory:
```bash
flutter create .
```

This will initialize the Flutter project in the current directory.

---

**Let me know once Flutter is installed, or if you'd like to start with the backend components first!**
