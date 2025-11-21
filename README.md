# Lingua Franca - Flutter Authentication App

A Flutter application with Firebase Authentication integration, featuring login, sign-up, and password reset functionality.

## Features

✅ **User Authentication**
- Email/Password Sign Up
- Email/Password Login
- Password Reset (Forgot Password)
- User Session Management
- Automatic Auth State Persistence

✅ **Beautiful UI**
- Gradient background design matching mockup
- Bot mascot icon integration
- Smooth animations and transitions
- Form validation
- Loading states
- Error handling with user-friendly messages

✅ **Security**
- Password visibility toggle
- Minimum password requirements (6 characters)
- Email validation
- Firebase Authentication backend

## Project Structure

```
lib/
├── main.dart                          # App entry point with auth wrapper
├── services/
│   └── auth_service.dart             # Firebase authentication service
└── screens/
    ├── login_screen.dart             # Login page
    ├── signup_screen.dart            # Sign up page
    ├── forgot_password_screen.dart   # Password reset page
    └── home_screen.dart              # Home page after authentication

assets/
└── images/
    └── bot_icon.png                  # Bot mascot icon
```

## Setup Instructions

### 1. Firebase Configuration

Before running the app, you need to configure Firebase. Follow the detailed instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

**Quick Setup (Recommended):**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

Then update `lib/main.dart` to use the generated configuration:
```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

## Dependencies

- `firebase_core: ^3.6.0` - Firebase core functionality
- `firebase_auth: ^5.3.1` - Firebase authentication
- `flutter: sdk: flutter` - Flutter framework
- `cupertino_icons: ^1.0.8` - iOS-style icons

## Features Overview

### Login Screen
- Email address input
- Password input with visibility toggle
- Login button with loading state
- "Forgot Password?" link
- "Sign up" link for new users
- Beautiful gradient background (light blue to purple)
- Bot mascot icon

### Sign Up Screen
- Email address input
- Password input with visibility toggle
- Confirm password with validation
- Sign up button with loading state
- "Login" link for existing users
- Same gradient design as login

### Forgot Password Screen
- Email address input
- Send reset email functionality
- Back button navigation
- Success/error notifications

### Home Screen
- Welcome message
- User email display
- Sign out functionality
- Authenticated user state

## Authentication Flow

1. **Initial Load**: App checks if user is already authenticated
2. **Not Authenticated**: Shows Login Screen
3. **User Signs Up**: Creates account → Redirects to Home Screen
4. **User Logs In**: Validates credentials → Redirects to Home Screen
5. **Forgot Password**: Sends reset email to user's email
6. **Sign Out**: Logs out user → Returns to Login Screen

## Error Handling

The app handles various Firebase authentication errors:
- User not found
- Wrong password
- Email already in use
- Invalid email format
- Weak password
- User disabled
- Network errors

## UI Design

The app follows the mockup design with:
- **Primary Colors**: Light blue (#7BB9E8) to purple (#9B7EC9) gradient
- **Accent Color**: Purple (#6B72AB) for buttons and icons
- **Text**: White text on gradient background
- **Components**: Rounded corners (12px border radius)
- **Transparency**: Semi-transparent input fields

## Testing the App

1. **Sign Up Flow**:
   - Click "Sign up" on login screen
   - Enter valid email (e.g., test@example.com)
   - Enter password (min 6 characters)
   - Confirm password
   - Click "Sign Up"

2. **Login Flow**:
   - Enter registered email
   - Enter password
   - Click "Login"

3. **Forgot Password**:
   - Click "Forgot the password?"
   - Enter registered email
   - Click "Reset Password"
   - Check email inbox for reset link

4. **Sign Out**:
   - Click "Sign Out" on home screen

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web (with additional Firebase web configuration)

## Next Steps

- [ ] Add email verification
- [ ] Implement social authentication (Google, Facebook)
- [ ] Add user profile management
- [ ] Implement Firestore for user data
- [ ] Add password strength indicator
- [ ] Implement biometric authentication
- [ ] Add multi-language support
- [ ] Create onboarding screens

## Troubleshooting

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for common issues and solutions.

## License

This project is open source and available under the MIT License.

## Support

For issues or questions, please refer to:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Flutter Documentation](https://flutter.dev/docs)
