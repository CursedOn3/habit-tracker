# HabitFlow - Production-Ready Habit Tracker

A full-featured, cross-platform habit tracking app built with Flutter 3.24+ and Firebase.

---

## Features

- **Authentication**: Email/password + Google Sign-In via Firebase Auth
- **Habit Management**: Add/edit habits with type, goal period, tracking days, time ranges
- **Smart Reminders**: Local notifications scheduled by time and day
- **Location Triggers**: Geofence-based reminders using device location
- **Progress Charts**: Weekly bar charts and monthly line graphs (fl_chart)
- **Streak Tracking**: Automatic streak calculation per habit
- **Offline-First**: Hive local storage with Firestore sync
- **Dark/Light Theme**: Full Material 3 theming
- **Data Export**: CSV export of all habit completion data

---

## Architecture

```
lib/
├── main.dart                       # App entry + Hive init + Firebase init
├── firebase_options.dart           # Firebase config (REPLACE with real values)
├── models/
│   ├── habit.dart                  # Habit, HabitCompletion, HabitType, GoalPeriod
│   ├── habit.g.dart                # Hive adapters (pre-generated)
│   └── app_user.dart               # AppUser model
├── services/
│   ├── auth_service.dart           # Firebase Auth (email + Google)
│   ├── habit_service.dart          # CRUD, charts, sync, CSV export
│   ├── notification_service.dart   # Local notifications
│   └── location_service.dart       # Geolocator wrapper
├── providers/
│   ├── auth_provider.dart          # Auth state + notifier
│   ├── habit_provider.dart         # Habit CRUD notifier + derived providers
│   └── theme_provider.dart         # Theme mode notifier
├── screens/
│   ├── onboarding/                 # 4-page onboarding carousel
│   ├── auth/                       # Login, Register, ForgotPassword
│   ├── home/                       # Dashboard with list, charts, FAB
│   ├── habit/                      # AddEditHabit (bottom sheet), HabitDetail
│   ├── history/                    # History screen with calendar + line chart
│   └── settings/                   # Theme picker, CSV export, sign out
├── widgets/
│   ├── habit_card.dart             # Habit card with progress + quick log
│   ├── weekly_bar_chart.dart       # 7-day bar chart (fl_chart)
│   ├── monthly_line_chart.dart     # 30-day line chart (fl_chart)
│   └── progress_summary.dart       # Stats row (done today, streaks, rate)
└── utils/
    ├── constants.dart              # App-wide constants
    ├── theme.dart                  # Material 3 light + dark themes
    └── helpers.dart                # DateTime extensions, formatters
```

---

## Quick Start

### 1. Prerequisites

```bash
flutter --version   # Requires 3.24+
dart --version      # Requires 3.4+
```

### 2. Firebase Setup (Required)

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project (free Spark tier works)
3. Enable **Authentication** → Sign-in methods:
   - Email/Password ✓
   - Google ✓
4. Create **Firestore Database** → Start in Production Mode

#### Android Setup
1. Add Android app → Package: `com.habitflow.app`
2. Download `google-services.json`
3. Place at `android/app/google-services.json`

#### iOS Setup
1. Add iOS app → Bundle ID: `com.habitflow.app`
2. Download `GoogleService-Info.plist`
3. Open Xcode: drag into `Runner/` target (check "Copy if needed")

#### Generate firebase_options.dart
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=your-firebase-project-id
```

This replaces `lib/firebase_options.dart` with your real credentials.

#### Firestore Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      match /habits/{habitId} {
        allow read, write: if request.auth.uid == userId;
      }
      match /completions/{completionId} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

### 3. Google Maps API Key

Replace `YOUR_GOOGLE_MAPS_API_KEY` in:
- `lib/utils/constants.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/AppDelegate.swift`

Get key from [Google Cloud Console](https://console.cloud.google.com) → APIs → Maps SDK.

### 4. Add Fonts

Download from [Google Fonts - Inter](https://fonts.google.com/specimen/Inter):
```
assets/fonts/Inter-Regular.ttf
assets/fonts/Inter-Medium.ttf
assets/fonts/Inter-SemiBold.ttf
assets/fonts/Inter-Bold.ttf
```

### 5. App Icon

Place 1024×1024 PNG at `assets/icons/app_icon.png`, then:
```bash
flutter pub run flutter_launcher_icons
```

### 6. Run

```bash
flutter pub get
flutter run
```

---

## Build for Production

### Android (Play Store)

```bash
# 1. Generate keystore
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Create android/key.properties (DO NOT commit)
# storePassword=<password>
# keyPassword=<password>
# keyAlias=upload
# storeFile=../upload-keystore.jks

# 3. Build
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

Upload to [Google Play Console](https://play.google.com/console).

### iOS (App Store)

```bash
# Requires Mac + Xcode 15+ + Apple Developer account
flutter build ios --release

# Then in Xcode: Product → Archive → Distribute App → App Store Connect
```

Or:
```bash
flutter build ipa --release
# Output: build/ios/ipa/habit_tracker.ipa
```

---

## Testing Checklist

```
✅ Register account → onboarding shows → dashboard loads
✅ Add habit (each type) → card appears in list
✅ Log completion → progress fills → streak increments
✅ Edit habit → changes reflected
✅ Delete habit → removed from list + Firestore
✅ Weekly chart updates after logging
✅ Notification fires at scheduled time
✅ Toggle dark mode → persists after restart
✅ Export CSV → file sharable/downloadable
✅ Sign out → redirects to login
✅ Sign back in → data persists via Hive
✅ Go offline → habits still load from Hive
✅ Come back online → changes sync to Firestore
```

---

## Dependency Versions

| Package | Version |
|---|---|
| firebase_core | ^3.6.0 |
| firebase_auth | ^5.3.1 |
| cloud_firestore | ^5.4.4 |
| flutter_riverpod | ^2.5.1 |
| hive_flutter | ^1.1.0 |
| fl_chart | ^0.69.0 |
| flutter_local_notifications | ^17.2.3 |
| geolocator | ^12.0.0 |
| google_maps_flutter | ^2.9.0 |
| google_sign_in | ^6.2.1 |

---

Built with Flutter & Firebase — HabitFlow v1.0.0