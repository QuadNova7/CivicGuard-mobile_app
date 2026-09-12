# 🛡️ CivicGuard Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-4CAF50?style=for-the-badge)](https://flutter.dev/multi-platform)
[![Backend](https://img.shields.io/badge/Backend-Kong%20%7C%20Supabase%20%7C%20Microservices-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

> **AI-Powered Citizen Disaster Response, Incident Triage, and Field Crew Coordination Platform.**

The **CivicGuard Mobile App** is a next-generation disaster management client designed for citizens, community volunteers, and municipal emergency response crews. It integrates real-time multimodal hazard verification, live interactive map routing around active flood and road closure zones, offline-first local caching, and direct connectivity to the CivicGuard microservices backend.

---

## 🌟 Key Features & Capabilities

### 1. 🚨 Citizen Incident & SOS Reporting (`/report-issue`)
- **Multimodal Incident Capture**: Report floods, landslides, fallen trees, electrical hazards, and road blockages with on-site camera photos.
- **Accurate Geolocation**: Automatic GPS coordinates retrieval with live reverse-geocoding for precise street and ward identification.
- **Offline Local Cache**: Immediate persistence via `LocalCacheService` ensuring no citizen report is lost even during cellular network dropouts.
- **Real-Time AI Triage Feedback**: Immediate feedback and tracking through composite hazard verdicts (`hazard_verdicts`).

### 2. 🗺️ Live Disaster Hazard & Safe Route Map (`/nearby-reports`)
- **Live Backend & Supabase Integration**: Real-time rendering of confirmed disaster hazards directly from `GET /api/incidents/map/hazards`.
- **Dynamic Hydrological Buffer Zones**: Automatically computes and renders danger buffer rings around active flood and hazard points.
- **Road Closure & Verdict Inspector**: Interactive bottom sheet detailing multi-signal AI reasoning, confidence percentages (e.g., 94% Flood Detection), urgency ratings, and closure status.
- **Safe Route Planning**: On-demand route calculation avoiding closed roads and active disaster perimeters via Mapbox Directions API.

### 3. 🤝 Community Volunteer Hub (`/volunteer-type`, `/community-volunteer`)
- **Open Citizen Missions**: Non-destructive self-registration for essential relief tasks (dry food packing, medical kit assembly, shelter assistance, evacuation guide).
- **Live Shelter Capacities**: Sourced directly from Supabase `public.shelters` and confirmed `hazard_verdicts`.
- **Offline Tracking & Verification**: Local cache state persistence with dynamic sync to the backend volunteer roster (`GET /api/relief/volunteers/roster`).

### 4. 🚒 Emergency Response Crew Console (`/crew-assignments`)
- **Role-Locked Tactical Workspace**: Strict multi-layer security lockdown reserved exclusively for verified Municipal Council Emergency Crews (CMC Water Rescue, 4x4 Offroad Squad, Medical Field Teams).
- **Incident Status Progression**: Real-time assignment workflow (`ASSIGNED` ➔ `EN_ROUTE` ➔ `ON_SITE` ➔ `PHOTO_VERIFIED_RESOLVED`).
- **Mandatory Photo Proof**: Field crews must submit photo resolution evidence before roads are reopened on public maps.

### 5. 📦 Physical Supplies & Relief Donations (`/donations`)
- **Targeted Shelter Pledges**: Citizen donation workflow directing essential supplies (water, canned food, medicine, blankets) to active shelters and open SOS help requests.
- **Authentication Safeguard**: Guest citizens are presented with an authentication modal before dispatching donation pledges to ensure donor accountability.
- **Contribution History (`/my-contributions`)**: Full chronological history of pledges made by the user.

### 6. 📱 My Reports & History Isolation (`/my-reports`)
- **Zero Mock Leakage**: Strictly scoped to reports submitted by the device/authenticated user via `LocalCacheService` and `reported_by` queries.
- **Real-Time Status Tracker**: Clean visual chips (`SUBMITTED`, `VERIFIED`, `CREW_DISPATCHED`, `RESOLVED`).

---

## 🏗️ Architecture & Project Structure

The project follows a **Clean Feature-First Architecture** with modular separation:

```
lib/
├── app.dart                        # Core MaterialApp configuration & routing wrapper
├── main.dart                       # App entry point, IP configuration & cache initialization
├── core/                           # Core infrastructure & global singletons
│   ├── config/                     # Environment configuration & constants
│   ├── network/                    # HTTP client, ApiConfig (IP & Gateway base URL)
│   ├── router/                     # Declarative GoRouter routing & authentication guards
│   ├── services/                   # LocalCacheService (SharedPreferences), LocationService
│   ├── theme/                      # AppTheme (Plus Jakarta Sans, Palette, Gradients)
│   ├── utils/                      # Formatters, Date helpers, Validators
│   └── widgets/                    # Global reusable UI widgets (Buttons, Cards, Dialogs)
├── features/                       # Modular Feature Packages
│   ├── admin/                      # Council administrative dashboards & statistics
│   ├── auth/                       # Login, Register, Role Dialogs, AuthService
│   ├── contributions/              # General community contribution overview
│   ├── coordinator/                # Field coordinator dispatch console
│   ├── crew/                       # Role-locked emergency response crew assignments & execution
│   ├── donations/                  # Relief supply donation pledges & history
│   ├── home/                       # Dashboard, auto-rotating quick actions, hotline bar
│   ├── main_navigation/            # Bottom navigation bar root container
│   ├── map/                        # Leaflet/FlutterMap, live hazard verdicts & safe routes
│   ├── notifications/              # Emergency broadcast alerts & notifications
│   ├── onboarding/                 # First-time language & walkthrough setup
│   ├── profile/                    # User profile, role badges, settings
│   ├── requests/                   # Citizen incident report submission & My Reports
│   ├── splash/                     # Modern Apex Shield animated splash & loader
│   ├── tasks/                      # Field task tracking
│   └── volunteer/                  # Community volunteer hub & relief squads
└── shared/                         # Cross-feature shared Enums, Models & Widgets
    ├── enums/                      # UserRole, RequestStatus, RequestPriority, AssignmentStatus
    └── models/                     # ApiResponse, PaginationModel
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `>= 3.0.0 < 4.0.0`
- **Dart SDK**: `>= 3.0.0`
- **Android Studio** / **VS Code** with Flutter extensions installed
- **Android SDK** (API Level 26+) / **Xcode** (for iOS builds)
- A running instance of the **CivicGuard Backend** (via Docker Compose or local microservices)

### 1. Clone the Repository
```bash
git clone https://github.com/savindu-st/CivicGuard.git
cd "mobile app/civicguard_mobileapp"
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Backend Gateway Connectivity

The mobile application communicates with the backend through the **Kong API Gateway** (default port `8000`).

#### For Physical Android Device over USB:
Forward port 8000 via ADB:
```bash
adb reverse tcp:8000 tcp:8000
```

#### For Android Emulator:
The app defaults to `10.0.2.2:8000` (which maps to `localhost:8000` on the host machine).

#### Custom IP Configuration:
You can set a custom host IP directly in code via `ApiConfig.setBaseIp('192.168.x.x')` or through the in-app settings screen.

### 4. Run the Application
```bash
# Run on connected device or emulator
flutter run

# Run on a specific device
flutter run -d <DEVICE_ID>
```

---

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```
The output APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (AAB for Google Play)
```bash
flutter build appbundle --release
```

### iOS IPA (macOS required)
```bash
flutter build ipa --release
```

---

## 🔒 Security & Role Matrix

| Role | Access Scope | Verification Mechanism |
| :--- | :--- | :--- |
| **Public Citizen** | Incident Reporting, Public Disaster Map, Donation Pledges | Open Access / Guest Mode (Auth requested for submissions) |
| **Community Volunteer** | Relief Packaging, Shelter Missions, Supply Sorting | Open Self-Registration & Offline Local Cache Sync |
| **Emergency Field Crew** | Tactical Crew Assignments, Incident Resolution, Road Reopenings | Strict Role-Lock (`FIELD_CREW` token + pre-assigned by Council) |
| **Council Officer / Admin** | Command Center, Triage, Crew Dispatch, System Metrics | Official Municipal Email Auth (`COUNCIL_OFFICER`) |

---

## 🎨 Design System & Branding

- **Design Philosophy**: Modern, high-veracity emergency response aesthetics with glassmorphism, glowing status accents, and 3D squircle iconography.
- **Typography**: [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans) (Google Fonts).
- **Core Color Tokens**:
  - **Apex Navy** (`#0F172A`, `#0B132B`): Primary foundation & dark surfaces.
  - **Emergency Emerald** (`#10B981`, `#059669`): Active verified statuses, safe zones.
  - **Tactical Blue** (`#0284C7`, `#38BDF8`): System navigation, borders, and safe routes.
  - **Amber Alert** (`#F59E0B`): Pending triage, road warnings.
  - **Critical Coral** (`#EF4444`): Road closures, high-hazard zones.

---

## 🤝 Contributing

1. Fork the Project repository
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <strong>CivicGuard — Safer Communities • Stronger Tomorrow</strong><br>
  <sub>Powered by QuadNova © 2026</sub>
</div>
