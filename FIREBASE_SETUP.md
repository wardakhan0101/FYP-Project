# Firebase Setup Instructions

This guide will help you set up Firebase Authentication for your Lingua Franca app.

## Prerequisites

- Flutter SDK installed
- A Google account
- Active internet connection

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter your project name (e.g., "Lingua Franca")
4. Follow the setup wizard:
   - Enable Google Analytics (optional)
   - Accept terms and click "Create project"

## Step 2: Register Your App with Firebase

### For Android:

1. In the Firebase Console, click on the Android icon to add an Android app
2. Enter your Android package name: `com.example.lingua_franca`
   - You can find this in `android/app/build.gradle.kts` under `namespace`
3. Download the `google-services.json` file
4. Place the `google-services.json` file in the `android/app/` directory
5. Open `android/build.gradle.kts` and add the Google Services plugin:
   ```kotlin
   plugins {
       id("com.google.gms.google-services") version "4.4.0" apply false
   }
   ```
6. Open `android/app/build.gradle.kts` and add at the top of plugins block:
   ```kotlin
   id("com.google.gms.google-services")
   ```

### For iOS:

1. In the Firebase Console, click on the iOS icon to add an iOS app
2. Enter your iOS bundle ID: `com.example.linguaFranca`
   - You can find this in `ios/Runner/Info.plist`
3. Download the `GoogleService-Info.plist` file
4. Open your project in Xcode: `open ios/Runner.xcworkspace`
5. Drag the `GoogleService-Info.plist` file into the Runner folder in Xcode
6. Make sure "Copy items if needed" is checked

### For Web (Optional):

1. In the Firebase Console, click on the Web icon to add a Web app
2. Register your web app with a nickname
3. Copy the Firebase configuration
4. Create a file `web/firebase-config.js` and add the configuration

## Step 3: Enable Authentication Methods

1. In the Firebase Console, go to "Authentication" in the left menu
2. Click on the "Sign-in method" tab
3. Enable "Email/Password" authentication:
   - Click on "Email/Password"
   - Toggle "Enable" switch
   - Click "Save"

## Step 4: Run Your App

### Important: FlutterFire CLI (Recommended Alternative)

For easier setup, you can use the FlutterFire CLI:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure your Flutter app
flutterfire configure
```

This will automatically:
- Create a Firebase project (or select an existing one)
- Register your apps
- Download configuration files
- Generate `firebase_options.dart` file

If you use FlutterFire CLI, update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### Without FlutterFire CLI:

If you manually added the configuration files:

```bash
# Run the app
flutter run
```

## Step 5: Test the Authentication

1. Launch the app
2. You should see the Login screen with the bot icon
3. Click "Sign up" to create a new account
4. Enter an email and password (minimum 6 characters)
5. After successful registration, you'll be taken to the home screen
6. Test the "Sign Out" functionality
7. Try logging in with your credentials
8. Test the "Forgot Password" functionality

## Troubleshooting

### Common Issues:

1. **App crashes on startup**
   - Make sure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location
   - Check if the package name matches

2. **Authentication not working**
   - Verify Email/Password is enabled in Firebase Console
   - Check internet connectivity

3. **iOS build errors**
   - Run `pod install` in the `ios` directory
   - Make sure the `GoogleService-Info.plist` is added to the Xcode project

4. **Android build errors**
   - Make sure you added the Google Services plugin to both gradle files
   - Run `flutter clean` and rebuild

## Security Rules

For production, make sure to set up proper security rules in Firebase Console under Firestore Database or Realtime Database if you plan to use them.

## Next Steps

- Add user profile functionality
- Implement email verification
- Add social authentication (Google, Facebook, etc.)
- Set up Firestore for data storage
- Implement password strength validation

## Support

For more information, visit:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
