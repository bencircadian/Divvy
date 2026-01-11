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

## IMPORTANT: Sound Notification

After finishing responding to my request or running a command, notify me with a sound:

**Windows:**
```powershell
powershell -c "[System.Media.SystemSounds]::Asterisk.Play()"
```

**macOS:**
```bash
afplay /System/Library/Sounds/Funk.aiff
```

**Linux:**
```bash
paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || echo -e '\a'
```