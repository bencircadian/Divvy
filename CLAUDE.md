# Divvy

A household task management app for iOS, Android, and Web built with Flutter.

## Tech Stack
- **Framework**: Flutter/Dart
- **State Management**: Provider
- **Local Storage**: SharedPreferences
- **Platforms**: iOS, Android (web for development)

## Project Structure
```
lib/
├── main.dart           # App entry with Provider setup
├── models/             # Data models
├── providers/          # State management
├── screens/            # Full-page UI components
└── widgets/            # Reusable UI components
```

## Commands
- `flutter run` - Run the app
- `flutter run -d chrome` - Run in browser
- `flutter analyze` - Check for issues
- `flutter test` - Run tests
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build for iOS (macOS only)

## Conventions
- Use Provider for state management
- Keep widgets small and focused
- Models should have `toJson`/`fromJson` for serialization
- Screens go in `lib/screens/`, widgets in `lib/widgets/`

## IMPORTANT: Sound Notification

After finishing responding to my request or running a command, run this command to notify me by sound:

```bash
afplay /System/Library/Sounds/Funk.aiff
```