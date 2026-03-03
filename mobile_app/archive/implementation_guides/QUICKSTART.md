# 🚀 WanderChina Quick Start Guide

## Prerequisites Check

Run these commands to check if you have the required tools:

```bash
# Check if Flutter is installed
flutter --version

# Check if Dart is installed (comes with Flutter)
dart --version

# Check for connected devices
flutter devices
```

---

## Option 1: Quick Web Preview (Fastest) 🌐

The fastest way to see the app is running it in Chrome:

```bash
# Navigate to project directory
cd "/Users/calvinxia/Desktop/China Travel/WanderChina/mobile_app"

# Get all dependencies
flutter pub get

# Run in Chrome browser
flutter run -d chrome
```

**Advantages:**
- No simulator/emulator needed
- Fast startup
- Great for testing UI/animations
- Hot reload works perfectly

**Note:** Some mobile-specific features won't work in web (camera, GPS, etc.)

---

## Option 2: iOS Simulator (macOS only) 📱

```bash
# Navigate to project directory
cd "/Users/calvinxia/Desktop/China Travel/WanderChina/mobile_app"

# Get dependencies
flutter pub get

# List available iOS simulators
xcrun simctl list devices

# Open default simulator
open -a Simulator

# Wait for simulator to boot, then run
flutter run
```

**Recommended Devices:**
- iPhone 15 Pro
- iPhone 14
- iPad Pro 12.9"

---

## Option 3: Android Emulator 🤖

```bash
# Navigate to project directory
cd "/Users/calvinxia/Desktop/China Travel/WanderChina/mobile_app"

# Get dependencies
flutter pub get

# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>

# Run the app
flutter run
```

---

## First Time Setup (Only if Flutter not installed)

### macOS
```bash
# Install Flutter using Homebrew
brew install flutter

# Or download from official website
# https://docs.flutter.dev/get-started/install/macos

# Add Flutter to PATH (if using manual install)
export PATH="$PATH:`pwd`/flutter/bin"

# Run Flutter doctor to check setup
flutter doctor

# Accept Android licenses (if using Android)
flutter doctor --android-licenses
```

### Windows
```powershell
# Download Flutter SDK from
# https://docs.flutter.dev/get-started/install/windows

# Extract and add to PATH
# Run flutter doctor
flutter doctor
```

### Linux
```bash
# Download Flutter SDK from
# https://docs.flutter.dev/get-started/install/linux

# Extract to desired location
tar xf flutter_linux_*-stable.tar.xz

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Run flutter doctor
flutter doctor
```

---

## Common Commands

```bash
# Get dependencies (run after cloning or adding packages)
flutter pub get

# Run app with hot reload
flutter run

# Run in release mode (better performance)
flutter run --release

# Run on specific device
flutter run -d <device_id>

# Check for available devices
flutter devices

# Clean build files
flutter clean

# Rebuild everything
flutter pub get && flutter run

# Check for issues
flutter doctor -v

# Run in verbose mode (for debugging)
flutter run -v
```

---

## Hot Reload Tips ⚡

While the app is running:
- Press `r` to hot reload (fast)
- Press `R` to hot restart (full reload)
- Press `p` to show performance overlay
- Press `q` to quit
- Press `h` to show all options

---

## Troubleshooting

### Issue: "No devices found"

**Solution:**
```bash
# For iOS Simulator
open -a Simulator

# For Chrome
flutter run -d chrome

# For Android
flutter emulators --launch <emulator_id>
```

### Issue: "Packages not found"

**Solution:**
```bash
flutter pub get
```

### Issue: "CocoaPods not installed" (iOS)

**Solution:**
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
flutter run
```

### Issue: "Gradle build failed" (Android)

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "flutter command not found"

**Solution:**
```bash
# Check if Flutter is in PATH
echo $PATH

# Add Flutter to PATH (temporary)
export PATH="$PATH:/path/to/flutter/bin"

# Add to PATH permanently (add to ~/.zshrc or ~/.bashrc)
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

---

## Expected First Run Output

```
Launching lib/main.dart on Chrome in debug mode...
Waiting for connection from debug service on Chrome...
This app is linked to the debug service: ws://127.0.0.1:50216/...
Debug service listening on ws://127.0.0.1:50216/...

✓ Built build/web/main.dart.js
🌎 Chrome is now running at http://localhost:50216

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

💪 Running with sound null safety 💪

An Observatory debugger and profiler on Chrome is available at: ...
```

---

## What You Should See

### 1. Splash Screen (3 seconds)
- Jade to white gradient background
- WanderChina logo with shimmer effect
- "Discover China Your Way" tagline
- Loading indicator

### 2. Onboarding (Swipe through 4 slides)
- Slide 1: Discover China Your Way (Jade green)
- Slide 2: Break Language Barriers (Blue)
- Slide 3: Stay Safe, Explore Confidently (Red)
- Slide 4: Join the Community (Green)

### 3. Home Dashboard
- Weather card with current conditions
- 6 Quick Tools (Map, Translate, Budget, etc.)
- Active Challenge cards (horizontal scroll)
- Nearby Highlights (horizontal scroll)
- Recommended places (vertical list)

### 4. Bottom Navigation
- Home, Discover, Map, Community, Profile tabs
- Smooth transitions between screens

---

## Performance Tips

```bash
# Run in release mode for better performance
flutter run --release

# Enable performance overlay while running
# Press 'p' after launching

# Profile mode (for performance testing)
flutter run --profile

# Check app size
flutter build apk --analyze-size
```

---

## Building for Production

### iOS
```bash
# Build iOS app
flutter build ios --release

# Create IPA file for App Store
flutter build ipa --release
```

### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Install APK on connected device
flutter install
```

### Web
```bash
# Build for web
flutter build web --release

# Preview build
cd build/web
python3 -m http.server 8000
# Open http://localhost:8000
```

---

## Next Steps After Running

1. **Test all screens** - Navigate through Home, Discover, Map, Community, Profile
2. **Test animations** - Check splash, onboarding, and transitions
3. **Test interactions** - Tap cards, buttons, navigation items
4. **Customize content** - Update place names, images, user data
5. **Connect backend** - Integrate with Supabase (already set up in `/supabase` folder)
6. **Add real data** - Replace placeholder data with API calls
7. **Test on device** - Deploy to physical iOS/Android device
8. **Add features** - Implement camera translation, map integration, etc.

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Material Design 3](https://m3.material.io)
- [Flutter Animate Package](https://pub.dev/packages/flutter_animate)
- [Riverpod State Management](https://riverpod.dev)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

---

## Quick Command Reference Card

```bash
# Start developing
cd mobile_app && flutter pub get && flutter run -d chrome

# Hot reload
Press 'r' while app is running

# Restart
Press 'R' while app is running

# Stop
Press 'q' while app is running

# Clean and rebuild
flutter clean && flutter pub get && flutter run

# Check everything is working
flutter doctor -v
```

---

## 🎉 You're Ready!

The app is fully built and ready to run. Just choose your preferred platform (Chrome for fastest preview) and run the commands above. Enjoy exploring your beautiful WanderChina app! 🚀

If you encounter any issues, check the Troubleshooting section or run `flutter doctor -v` for detailed diagnostics.
