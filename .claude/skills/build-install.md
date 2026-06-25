---
name: build-install
description: Build release APK and install to connected Android device for donkap-pos. Use when user says "build", "install ke hp", "coba di hp", or wants to test on device.
---

## Steps

1. Check connected devices:
```bash
flutter devices
```

2. Run build_runner if any Hive models changed (check git diff for `@HiveType`):
```bash
dart run build_runner build --delete-conflicting-outputs
```

3. Build release APK:
```bash
flutter build apk --release
```

4. Install to the Android device (use the device ID from step 1):
```bash
flutter install -d <device-id> --release
```

Output APK path: `build/app/outputs/flutter-apk/app-release.apk`

## Notes
- If build fails with Hive adapter errors, always run build_runner first
- Connected device must have USB debugging enabled
- `flutter analyze` before building to catch errors early
