# Money Manager - Offline Financial Android App

A fully featured, offline-first personal finance management application built using Flutter. All database transactions, local biometrics, daily reminders, and real-time budget alerts run locally on the device — no backend or internet connection required.

---

## Technical Stack & Libraries

- **Framework:** Flutter & Dart (sound null-safety)
- **Local Storage:** SQLite via `sqflite` (utilizing the DAO design pattern)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing & Navigation:** `go_router` (incorporating automatic auth state redirection)
- **Local Push Notifications:** `flutter_local_notifications` (with timezone-aware scheduling)
- **Charts & Visualizations:** `fl_chart` (interactive charts)
- **Animations:** Curved animations, staggered overlays, and 3D gesture-based perspective card tilts.
- **Biometric Security:** `local_auth` (Fingerprint/Face unlock integration)

---

## Core Feature Overview

### 1. Authentication & Security
- **PIN Setup & Login:** First launch prompts for name, currency, and a secure 4-digit PIN (hashed with SHA-256 and stored locally).
- **Biometrics:** Enable biometric unlocking from settings. Uses `local_auth` to authenticate biometrically when launching the application.
- **Protected Routes:** Automatic checks redirect unauthenticated sessions to `/login` and unconfigured sessions to `/pin-setup`.

### 2. Multi-Account Management
- Create, read, update, and delete accounts (types: *Bank, Cash, Credit Card, Savings, Investment*).
- Grid layout with account summaries and **3D interactive touch-tilt gesture transforms**.
- Per-account privacy switch to include/exclude the account from data sharing packages.

### 3. Local Ledgers (Transactions)
- CRUD operations for expense, income, and transfer logs.
- Transfers debit the source account and credit the target account.
- **Recurrence engine:** Set recurrence frequency (daily, weekly, monthly, yearly) and end dates to dynamically project future transactions up to a 12-month horizon.
- **Privacy switches:** Hide individual transactions by marking them private.

### 4. Budgets & Notifications
- Set category budget limits for the current month.
- **Real-Time 80% and 100% Alerts:** Adding/modifying expenses checks limits. Crossing 80% or 100% of a budget category fires an immediate local push notification and an in-app warning.
- **Daily Reminders:** Timezone-aware alarms schedule a daily logging reminder (default: 8 PM, configurable in Settings).

### 5. Analytics Dashboard
- **Net Worth Line Chart:** Visualizes net worth trend line over 30 days.
- **Monthly Bars Chart:** Side-by-side comparisons of monthly income vs expenses.
- **Donut Chart:** Expense percentage breakdown by category.
- **Calendar View:** Highlights dates with recorded transactions and pops up daily transaction summaries.

### 6. Portable Partner Sharing
- **Offline Code Exporter:** Compiles public transactions from shared accounts, filters out private flags, compresses the JSON payload using Gzip, and encodes it into a copy-pasteable Base64Url string or visual QR code.
- **Offline Code Importer:** Decodes the Gzip string, validates, and stores a read-only partner snapshot database record.

---

## Database Schema (SQLite)

The sqlite database schema (`money_manager.db`) contains the following tables:
- **`user_profile`**: Holds user settings, preferred currency, theme preference, PIN hashes, biometrics configs, and reminder configurations.
- **`account`**: Holds financial accounts metadata, color tags, icons, balances, and public sharing permissions.
- **`category`**: Custom and seeded default transaction categories (Food, Rent, Salary, Transport, etc.).
- **`transaction_log`**: Contains the transaction history list with recurrence rules, amounts, types, and privacy flags.
- **`budget`**: Tracks monthly category spending limit amounts.
- **`partner_snapshot`**: Holds imported partner snapshots labeled by custom name and theme color.

---

## Build & Run Instructions

Ensure your local Android development environment is configured. You need the Android SDK platform 34 and OpenJDK 17 installed.

### Pre-requisites (Environment Setup)
1. Add Flutter to your path:
   ```powershell
   $env:PATH = "C:\Users\ADMIN\AppData\Local\Programs\flutter\bin;C:\Users\ADMIN\anaconda3\envs\dev\Library\bin;C:\Users\ADMIN\AppData\AndroidCLI;" + $env:PATH
   $env:JAVA_HOME = "C:\Users\ADMIN\anaconda3\envs\dev\Library"
   ```

2. Accept Android licenses:
   ```powershell
   flutter doctor --android-licenses
   ```

### Compile commands

#### 1. Resolve Dependencies
```powershell
flutter pub get
```

#### 2. Run Debug Mode
```powershell
flutter run
```

#### 3. Build Debug APK
```powershell
flutter build apk --debug
```
*Output file path: `build/app/outputs/flutter-apk/app-debug.apk`*

#### 4. Build Production Release APK
```powershell
flutter build apk --release
```
*Output file path: `build/app/outputs/flutter-apk/app-release.apk`*
