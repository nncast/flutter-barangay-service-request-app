<p align="center">
  <img src="assets/images/BSR_Logo_1.svg" width="400" alt="Barangay Service System Logo">
</p>

## About

The Barangay Service System mobile app allows residents to submit and track service requests, receive notifications, and communicate with barangay staff. Admin and staff users can manage requests and users through the app.

**Features:**
- User authentication (Login/Register)
- Role-based access (Resident, Staff, Admin)
- Submit service requests
- Track request status with history
- Real-time notifications
- Admin dashboard with statistics
- User management (CRUD for admins)
- Search and filter requests

## Tech Stack

- Flutter 3.x
- Dart
- Provider (State Management)
- HTTP (API calls)
- Shared Preferences (Local storage)
- URL Launcher

## Quick Setup

### 1. Prerequisites

- Flutter SDK installed
- Android Studio / VS Code
- Laragon (for API backend)
- API running at `http://localhost:8000`

### 2. Clone the repository

```bash
cd C:\laragon\www
git clone https://github.com/nncast/barangay_app.git
cd barangay_app
```

### 3. Get dependencies

```bash
flutter pub get
```

### 4. Configure API URL

Open `lib/core/api_service.dart` and update:
```dart
// Use only ONE baseUrl depending on your platform

// OPTION 1: For Android Emulator
// static const String baseUrl = 'http://10.0.2.2:8000/api';

// OPTION 2: For Windows Desktop (default)
static const String baseUrl = 'http://localhost:8000/api';

// OPTION 3: For Physical Device (find your IP using 'ipconfig')
// static const String baseUrl = 'http://192.168.1.100:8000/api';

```

> **Note:** Windows URL is set as default. Change only if using emulator or physical device.

### 5. Run the app

Before running Flutter, make sure your Laravel API is already running:

```bash
php artisan serve
```

You should see something like:
```
INFO  Server running on [http://127.0.0.1:8000].  
```

Then run the Flutter app:

```bash
flutter run
```


---

## Project Structure

```
lib/
├── core/
│   ├── api_service.dart
│   └── models.dart
├── providers/
│   ├── auth_provider.dart
│   ├── request_provider.dart
│   └── user_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── admin/
│   │   ├── admin_home_screen.dart
│   │   └── admin_users_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── requests/
│   │   ├── my_requests_screen.dart
│   │   ├── request_detail_screen.dart
│   │   └── submit_request_screen.dart
│   ├── notifications/
│   │   └── notifications_screen.dart
│   └── profile/
│       └── profile_screen.dart
└── main.dart
```

---

## Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@barangay.gov.ph | Admin1234 |
| Staff | staff@barangay.gov.ph | Staff1234 |
| Resident | maria@example.com | User1234 |

---

## Screens

### Resident
- Dashboard with stats and categories
- Submit new requests
- My requests with status filters
- Request details with history
- Notifications
- Profile

### Admin/Staff
- Dashboard with statistics
- All requests (search & filter)
- Update request status with remarks
- User management (CRUD)
- Profile

---

## Common Issues

**API connection refused?**
- Ensure API is running: `php artisan serve`
- Check baseUrl in `api_service.dart` (default is Windows URL)

**Build errors?**
```bash
flutter clean
flutter pub get
flutter run
```

**Emulator not showing?**
```bash
flutter emulators --launch Pixel_6_API_33
```

## Repository

- Flutter App: [https://github.com/nncast/barangay_app](https://github.com/nncast/barangay_app)
- API Backend: [https://github.com/nncast/barangay-api](https://github.com/nncast/barangay-api)
