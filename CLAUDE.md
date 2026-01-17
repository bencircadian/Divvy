# Divvy

A household task management app for iOS, Android, and Web built with Flutter.

## Tech Stack
- **Framework**: Flutter/Dart
- **State Management**: Provider
- **Backend**: Supabase (auth, database, realtime)
- **Local Storage**: Hive (offline-first)
- **Navigation**: go_router with deep linking
- **Platforms**: iOS, Android, Web

## Project Structure
```
lib/
├── main.dart           # App entry with Provider setup
├── models/             # Data models (toJson/fromJson)
├── providers/          # State management
├── screens/            # Full-page UI components
├── widgets/            # Reusable UI components
├── services/           # Supabase, sync, API calls
└── theme/              # app_theme.dart - colors, spacing, styles
```

## Key Dependencies
- `supabase_flutter` - Backend & auth
- `provider` - State management
- `go_router` - Navigation & deep links
- `hive_flutter` - Offline storage
- `connectivity_plus` - Network detection
- `google_sign_in` / `sign_in_with_apple` - Social auth

## Commands
- `flutter run` - Run the app
- `flutter run -d chrome` - Run in browser
- `flutter analyze` - Check for issues
- `flutter test` - Run tests
- `flutter test --coverage` - Run tests with coverage
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build for iOS (macOS only)

## Deployment (Vercel Web)

**IMPORTANT**: Vercel serves pre-built files from `build/web`. After making code changes, you MUST rebuild and push the build files for deployment.

### Deployment Workflow (ALWAYS follow after code changes):
```bash
# 1. Run tests and analyze
flutter analyze
flutter test

# 2. Build web release
flutter build web --release

# 3. Commit source changes first (if not already done)
git add -A
git commit -m "Your changes description"

# 4. Force-add and commit build files
git add -f build/web
git commit -m "Build: Deploy web with <brief description>"

# 5. Push to GitHub
git push

# 6. Deploy to Vercel (webhook unreliable, always run manually)
npx vercel --prod
```

- GitHub webhook to Vercel is unreliable, so always deploy manually with `npx vercel --prod`
- Production URL: https://divvy-app-sage.vercel.app

## Conventions
- Use Provider for state management
- Keep widgets small and focused
- Models should have `toJson`/`fromJson` for serialization
- Screens go in `lib/screens/`, widgets in `lib/widgets/`
- Use constants from `app_theme.dart` (AppColors, AppSpacing, AppRadius)
- Offline-first: write to Hive, then sync to Supabase

## IDs (for reference)
- Household ID: 481394f2-21d1-48eb-bef0-4c259eb5f1l5
- User ID: a8f88b5f-15b2-4482-91bf-c206d04f9a05

## Mobile Platform Configuration

### iOS Setup

1. **Bundle Identifier**: Set in Xcode → Runner → General → Bundle Identifier
   - Current: `$(PRODUCT_BUNDLE_IDENTIFIER)` (needs actual value)

2. **Sign in with Apple** (required for social auth):
   - In Xcode: Runner → Signing & Capabilities → + Capability → Sign in with Apple
   - Create `ios/Runner/Runner.entitlements`:
     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
     <plist version="1.0">
     <dict>
       <key>com.apple.developer.applesignin</key>
       <array>
         <string>Default</string>
       </array>
     </dict>
     </plist>
     ```

3. **Apple Developer Console**:
   - Register app identifier with Sign in with Apple capability
   - Configure Services ID for web sign-in if needed
   - Add redirect URLs to Supabase dashboard

4. **Deep linking** (already configured):
   - URL schemes: `divvy://`, `io.supabase.divvy://`

### Android Setup

1. **Signing Configuration** (required for release builds):
   - Generate keystore: `keytool -genkey -v -keystore divvy-release.keystore -alias divvy -keyalg RSA -keysize 2048 -validity 10000`
   - Create `android/key.properties`:
     ```properties
     storePassword=<password>
     keyPassword=<password>
     keyAlias=divvy
     storeFile=<path-to-keystore>
     ```
   - Update `android/app/build.gradle.kts` to use the signing config

2. **Google Sign-In** (required for social auth):
   - Get SHA-1 fingerprint: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`
   - Add SHA-1 to Firebase Console or Google Cloud Console
   - Download `google-services.json` to `android/app/`

3. **Package name**: `com.divvy.app` (in `android/app/build.gradle.kts`)

4. **Deep linking** (already configured):
   - URL schemes: `divvy://`, `io.supabase.divvy://login-callback`

### Supabase Auth Configuration

Add these redirect URLs in Supabase Dashboard → Authentication → URL Configuration:
- `divvy://login-callback`
- `io.supabase.divvy://login-callback`
- `https://your-domain.com/auth/callback` (for web)

## IMPORTANT: Sound Notification

After finishing responding to my request or running a command, notify me with a sound:

**Windows:**
```powershell
powershell -Command "[console]::beep(1000,500)"
```

**macOS:**
```bash
afplay /System/Library/Sounds/Funk.aiff
```

**Linux:**
```bash
paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || echo -e '\a'
```