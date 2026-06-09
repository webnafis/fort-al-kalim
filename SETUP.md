## PHASE 1 SETUP GUIDE
## ==================
## After Flutter is installed and `flutter pub get` runs,
## you need to complete 2 more steps before the app can run:

## STEP 1 — Create Firebase Project
## ----------------------------------
## 1. Go to: https://console.firebase.google.com
## 2. Click "Add project" → name it "fort-al-kalim"
## 3. Enable Google Analytics (optional)
## 4. In the project, add an Android app:
##    - Package name: com.fortkalim.app
##    - App nickname: Fort Al-Kalim
## 5. Download google-services.json
## 6. Place it at: android/app/google-services.json
## 7. Enable these Firebase services:
##    - Authentication → Sign-in method → Google ✓ and Email/Password ✓
##    - Firestore Database → Create database → Start in test mode
##    - Realtime Database → Create database → Start in test mode
##    - Cloud Messaging → automatically enabled
##
## 8. Free Media Storage (GitHub + jsDelivr CDN):
##    - Create a public GitHub repository (e.g., 'fort-al-kalim-assets')
##    - Upload your game's word images and MP3 audio files to this repo.
##    - To load them super-fast in your app, use the jsDelivr CDN URL:
##      Format: https://cdn.jsdelivr.net/gh/YourUsername/YourRepoName@main/path_to_file.jpg
##    - Paste these CDN links into your Firestore database's 'imageUrl' and 'audioUrl' fields!
##
## 9. Run: dart pub global activate flutterfire_cli
##    Then: flutterfire configure
##    (Make sure to select Android, Web, and Windows when prompted)
##    This auto-generates lib/firebase_options.dart with real values
##
## STEP 2 — Cross-Platform Building
## ---------------------------------------------------
## - For Android: flutter run -d android
## - For Web:     flutter run -d chrome
## - For Windows: flutter run -d windows

## STEP 3 — Android Signing (for release builds only)
## ---------------------------------------------------
## For debug/testing, no signing needed.
## For Play Store: generate a keystore file and add key.properties
##
## After completing steps 1-2, run:
##   flutter run
## The app should boot to the splash screen, then the login screen.
