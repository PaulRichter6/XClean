# XClean 🪥✨
### 100% Offline, Privacy-First Companion for Oclean Smart Toothbrushes (X Pro Elite / X Elite)

XClean ist eine native, werbefreie und komplett lokale Flutter-App für Oclean-Smart-Zahnbürsten (unterstützt u. a. **Oclean X Pro Elite** und **Oclean X Elite**, Modell `Y2088` / `OCLEANY3P`).

Kein Cloud-Zwang, kein Tracking, kein Benutzerkonto – alle Daten verbleiben via SQLite ausschließlich auf deinem Smartphone.

---

## 🌟 Features

- **100% Offline BLE Kommunikation:** Direkte Bluetooth-Low-Energy-Steuerung ohne Cloud, Server oder Registrierung.
- **Interaktives 3D-Zahnmodell:**
  - Echtes 3D-Kiefermodell (Ober- & Unterkiefer) mit Three.js WebGL & OrbitControls.
  - Farbliche Erkennung nicht oder unzureichend geputzter Zonen (`Fehlt < 10s`, `Mäßig 10-25s`, `Gut > 25s`).
- **Live-Putzbegleiter:**
  - 2-Minuten Timer mit 4 x 30-Sekunden Quadranten.
  - Haptisches Vibrations-Feedback bei jedem Quadrantenwechsel.
- **Intelligente Spülfilterung:**
  - Putzvorgänge unter 15 Sekunden (z. B. beim Abspülen unter Wasser) werden automatisch ignoriert, damit dein Score und deine Statistiken nicht verfälscht werden.
- **Putz-Historie & Statistiken (Revolut-Stil):**
  - Gruppierung nach Tagen (Heute, Gestern, Wochentag).
  - Detailierte Auswertung von Putzdauer, Effektivzeit und Abdeckung.
  - Option zum Löschen einzelner Sitzungen (Swipe-to-Delete).
- **Favoriten & Auto-Connect:**
  - Speichere deine Zahnbürste mit einem Stern ⭐ als Favorit.
  - Automatischer Verbindungsaufbau direkt beim Öffnen der App.
- **Lokale Putz-Erinnerungen:**
  - Einstellbare Push-Benachrichtigungen morgens und abends zum Schutz deines Streaks.
- **Android Homescreen-Widget:**
  - Schnellübersicht über Streak, Score, Akkustand und letzte Putzzeit direkt auf dem Homescreen.
- **Bürstenkopf-Lebensdauer:**
  - Überwachung der verbleibenden Tage und Bürstvorgänge mit 1-Tap-Reset.

---

## 📱 Unterstützte Modelle

- **Oclean X Pro Elite**
- **Oclean X Elite** (Modell `Y2088`, Firmware `1.0.0.32`+)
- Weitere Modelle mit Oclean Type-1 BLE Protokoll (`*B#` Stream & Service `8082caa8-41a6-4021-91c6-56f9b954cc18`)

---

## 🛠️ Build & Installation

### Voraussetzungen
- Flutter SDK (3.24+ empfohlen)
- Android SDK (API 34+)
- Java / JDK 17

### Projekt klonen & Abhängigkeiten laden:
```bash
git clone https://github.com/<DEIN-BENUTZERNAME>/XClean.git
cd XClean
flutter pub get
```

### Debug-APK bauen:
```bash
flutter build apk --debug
```
Die fertige APK befindet sich in:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 🛡️ Datenschutz & Lizenz

- **Datenschutz:** 100% lokal. Keine Tracking-SDKs, keine Analytics, keine Netzwerkverbindungen nach außen.
- **Lizenz:** MIT License.
