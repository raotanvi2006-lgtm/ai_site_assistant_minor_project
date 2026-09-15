# Site Intelligence App — Week 1 Skeleton

This zip contains the Dart source files and `pubspec.yaml` only. It does **not**
include the native `android/` and `ios/` platform folders — those must be
generated on your machine by the Flutter SDK itself (they contain
machine-specific build files that only `flutter create` can produce correctly).

## Setup (one-time)

1. Unzip this into an empty folder, e.g. `site_intelligence_app/`.
2. Open a terminal in that folder and run:
   ```bash
   flutter create .
   ```
   This generates `android/`, `ios/`, and other platform folders **without**
   overwriting the `lib/` files or `pubspec.yaml` already in the zip.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Connect your phone (USB debugging enabled) and confirm it's detected:
   ```bash
   flutter devices
   ```
5. Run it:
   ```bash
   flutter run
   ```

## What's in here

```
lib/
 ├─ main.dart
 ├─ models/
 │   ├─ project.dart
 │   └─ update.dart
 ├─ services/
 │   └─ mock_data_service.dart
 └─ screens/
     ├─ role_select_screen.dart
     ├─ worker/
     │   ├─ project_picker_screen.dart
     │   └─ intake_screen.dart
     └─ owner/
         ├─ dashboard_screen.dart
         └─ project_detail_screen.dart
```

This is the Week 1 milestone from the project plan: a navigable app with
separate Worker and Owner flows, running against mock data. The
`MockDataService` is the one file to swap out in Week 5 once the real
FastAPI backend exists.


New features to be added post 8/28:

1. Add a mobile number + name + password based login page with option to create new password
2. Owner should have an option to add a new project (+ icon)