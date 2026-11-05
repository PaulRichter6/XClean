# XClean 🪥✨
### 100% Offline, Privacy-First Companion for Oclean Smart Toothbrushes (X Pro Elite / X Elite)

**XClean** is a native, ad-free, open-source Flutter companion app for Oclean smart toothbrushes (specifically optimized for **Oclean X Pro Elite** and **Oclean X Elite**, model `Y2088` / `OCLEANY3P`).

No cloud accounts, no telemetry, no tracking — 100% of your dental health data stays entirely local on your device via SQLite.

---

## 🌟 Key Features

- **100% Offline BLE Communication:**
  - Direct Bluetooth Low Energy control without external servers, accounts, or internet access.
  - Automatic time synchronization, telemetry retrieval, battery polling, and mode configuration.

- **Interactive 3D Jaw & Dentition Analysis:**
  - Real 3D jaw model (upper & lower jaw) rendered using Three.js WebGL with 360° touch OrbitControls.
  - Heatmap color visualization highlighting missed or insufficiently brushed zones (`Missed < 10s`, `Moderate 10–25s`, `Good > 25s`).

- **Interactive Live Brushing Companion:**
  - 2-minute circular timer divided into 4 x 30-second quadrants.
  - Haptic vibration feedback on quadrant switches (matching the physical toothbrush motor feedback).

- **Smart Rinse Filtering:**
  - Automatically filters out short sessions under 15 seconds (e.g., when turning the brush on under running tap water to clean the bristles).
  - Prevents 0% score corruption on your dashboard and streaks.

- **Revolut / WHOOP-Inspired Brushing History & Analytics:**
  - History grouped cleanly by calendar days (Today, Yesterday, Weekdays).
  - Detailed metrics for duration, effective brushing time, pressure distribution, and coverage.
  - Individual session deletion (Swipe-to-Delete) and bulk rinse cleanup.

- **Favorites & Auto-Connect:**
  - Mark your toothbrush with a star ⭐ as a favorite.
  - Instant auto-connection as soon as the app is opened.

- **100% Local Brushing Reminders:**
  - Configurable morning and evening local push notifications to protect your streak.

- **Android Homescreen Widget:**
  - Dark-mode widget showing your current streak, latest score, battery level, and last brushing time directly on your homescreen.

- **Brush Head Health Tracking:**
  - Real-time wear tracking (days used and total brushing cycles) with 1-tap reset.

---

## 📱 Supported Devices

- **Oclean X Pro Elite**
- **Oclean X Elite** (Model `Y2088`, Firmware `1.0.0.32`+)
- Any Oclean brush utilizing the Type-1 BLE protocol (`*B#` session stream & service `8082caa8-41a6-4021-91c6-56f9b954cc18`)

---

## 🛠️ Build & Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+ recommended)
- Android SDK (API 34+)
- JDK 17

### 1. Clone the repository:
```bash
git clone https://github.com/PaulRichter6/XClean.git
cd XClean
```

### 2. Install dependencies:
```bash
flutter pub get
```

### 3. Build Debug APK:
```bash
flutter build apk --debug
```

The compiled APK will be generated at:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 🔒 Privacy & Architecture

- **No Cloud Dependencies:** Designed from the ground up to never transmit telemetry, metrics, or personal data to external servers.
- **Local Storage:** SQLite database with encrypted SharedPreferences for settings.
- **Open Protocol Implementation:** Reverse-engineered cleanroom BLE implementation of the Oclean packet structure.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
