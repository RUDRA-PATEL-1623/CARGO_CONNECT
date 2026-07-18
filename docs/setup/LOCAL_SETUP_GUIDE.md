# CargoConnect Local Setup Guide

Last updated: 2026-05-19

This guide sets up CargoConnect locally on Windows 10 or Windows 11. It covers the Node.js backend, XAMPP MySQL database, Customer Flutter app, Driver Flutter app, Admin Flutter Web panel, and Postman testing.

## 1. Required Tools

Install these tools first.

| Tool | Required for | Notes |
| --- | --- | --- |
| Git | Source control and Flutter dependency resolution | Install from https://git-scm.com/download/win. |
| Chrome | Admin Panel Flutter Web testing | Install from https://www.google.com/chrome/. |
| Node.js LTS | Backend API | Use LTS from https://nodejs.org. Avoid relying on the Current line for handoff machines. |
| Flutter SDK | Customer App, Driver App, Admin Panel | Install stable Flutter and add `flutter\bin` to PATH. |
| Android Studio | Android SDK, emulator, platform tools | Install Android SDK Platform, Platform-Tools, Build-Tools, Emulator, and Command-line Tools. |
| VS Code | Recommended editor | Install Flutter, Dart, ESLint, Prettier, and SQL extensions. |
| XAMPP | Local MySQL/MariaDB and phpMyAdmin | Default install path is usually `C:\xampp`. |
| MySQL/phpMyAdmin | Database creation and inspection | phpMyAdmin is available at `http://localhost/phpmyadmin` when Apache/MySQL are running. |
| Postman | API testing | Use a `CargoConnect Local` environment. |

Optional Winget install commands:

```powershell
winget install --id Git.Git -e
winget install --id Google.Chrome -e
winget install --id OpenJS.NodeJS.LTS -e
winget install --id Microsoft.VisualStudioCode -e
winget install --id Google.AndroidStudio -e
winget install --id Postman.Postman -e
```

Install XAMPP from Apache Friends if Winget does not provide a stable package.

Verify tools after opening a new PowerShell window:

```powershell
git --version
node -v
npm -v
flutter --version
flutter doctor
```

## 2. Flutter And Android Setup

Recommended Flutter SDK location:

```powershell
New-Item -ItemType Directory -Force C:\src
git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter
```

Add this to your user PATH:

```txt
C:\src\flutter\bin
```

Then run:

```powershell
flutter doctor
flutter doctor --android-licenses
```

In Android Studio:

1. Complete the first-run setup wizard.
2. Open `More Actions > SDK Manager`.
3. Install Android SDK Platform, Platform-Tools, Build-Tools, Emulator, and Command-line Tools.
4. Open `More Actions > Device Manager`.
5. Create and start an emulator, for example a Pixel device image.

## 3. Project Folder

If the project is already present:

```powershell
cd D:\Projects\cargoconnect
```

If cloning fresh:

```powershell
git clone <repository-url> D:\Projects\cargoconnect
cd D:\Projects\cargoconnect
```

Open in VS Code:

```powershell
code D:\Projects\cargoconnect
```

## 4. Start XAMPP MySQL

Preferred:

1. Open XAMPP Control Panel.
2. Start `MySQL`.
3. Optional: start `Apache` if you want phpMyAdmin.
4. Open phpMyAdmin at `http://localhost/phpmyadmin`.

PowerShell fallback if the control panel is not convenient:

```powershell
Start-Process -FilePath C:\xampp\mysql\bin\mysqld.exe -ArgumentList "--defaults-file=C:\xampp\mysql\bin\my.ini" -WindowStyle Hidden
```

Default local database settings:

```txt
Host: localhost
Port: 3306
User: root
Password: empty
Database: cargoconnect_db
```

If your MySQL root account has a password, update `backend\.env`.

## 5. Backend Setup

Install dependencies and create the local environment file:

```powershell
cd D:\Projects\cargoconnect\backend
npm install
Copy-Item .env.example .env
```

Recommended local `backend\.env` values:

```env
NODE_ENV=development
PORT=5000
API_PREFIX=/api/v1
APP_NAME=CargoConnect API
BODY_LIMIT=1mb

CORS_ORIGIN=http://localhost:3000,http://localhost:54042,http://localhost:54043

DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=cargoconnect_db
DB_CONNECTION_LIMIT=10

SEED_ADMIN_PASSWORD=Password123!
SEED_DEFAULT_PASSWORD=Password123!
SEED_BCRYPT_ROUNDS=10

JWT_SECRET=replace_with_a_long_random_secret_for_local_dev
JWT_EXPIRES_IN=1d

UPLOAD_DIR=src/uploads
MAX_FILE_SIZE_MB=5

SMTP_HOST=
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=
SMTP_PASSWORD=
MAIL_FROM="CargoConnect <no-reply@cargoconnect.local>"
```

Leave SMTP empty for local OTP console fallback. Do not commit `backend\.env`.

## 6. MySQL Database Create, Import, Reset, Seed

Make sure XAMPP MySQL is running.

Run all migrations in filename order:

```powershell
cd D:\Projects\cargoconnect
$mysql = 'C:\xampp\mysql\bin\mysql.exe'
Get-ChildItem .\database\migrations\*.sql |
  Sort-Object Name |
  ForEach-Object { Get-Content $_.FullName | & $mysql -u root }
```

If root has a password:

```powershell
Get-ChildItem .\database\migrations\*.sql |
  Sort-Object Name |
  ForEach-Object { Get-Content $_.FullName | & $mysql -u root -p }
```

Reset the database when you need a clean local run:

```powershell
cd D:\Projects\cargoconnect
$mysql = 'C:\xampp\mysql\bin\mysql.exe'
& $mysql -u root -e "DROP DATABASE IF EXISTS cargoconnect_db;"
Get-ChildItem .\database\migrations\*.sql |
  Sort-Object Name |
  ForEach-Object { Get-Content $_.FullName | & $mysql -u root }
```

Run schema smoke checks:

```powershell
Get-Content .\database\mysql_queries\001_schema_smoke_checks.sql |
  & $mysql -u root cargoconnect_db
```

Seed sample data:

```powershell
cd D:\Projects\cargoconnect\backend
npm run seed
```

Seed login credentials:

```txt
Admin: admin@cargoconnect.local / Password123!
Dispatcher: dispatcher@cargoconnect.local / Password123!
Customer: customer@cargoconnect.local / Password123!
Driver: driver@cargoconnect.local / Password123!
```

Additional seeded driver usernames may exist for assignment testing, for example `vikram.driver`, `imran.driver`, and `neha.driver`, all using `Password123!`.

## 7. Run Backend

Start the API:

```powershell
cd D:\Projects\cargoconnect\backend
npm run dev
```

Production-style local start:

```powershell
cd D:\Projects\cargoconnect\backend
npm run start
```

Verify health:

```powershell
Invoke-RestMethod http://localhost:5000/api/v1/health
Invoke-RestMethod http://localhost:5000/api/v1/health/db
npm run health
```

Route registry:

```txt
http://localhost:5000/api/v1
```

If `EADDRINUSE` appears, another process is already using port `5000`. Stop the existing backend terminal, or change `PORT` in `backend\.env` and restart the apps with the matching base URL.

## 8. Backend Base URL Rules

Use one backend base URL per app through `--dart-define=CARGOCONNECT_API_BASE_URL=...`.

| Runtime | Base URL |
| --- | --- |
| Backend and Admin Web on same machine | `http://localhost:5000/api/v1` |
| Android emulator calling host backend | `http://10.0.2.2:5000/api/v1` |
| Physical Android device on same Wi-Fi | `http://<YOUR_LAPTOP_IP>:5000/api/v1` |

Find laptop IP:

```powershell
ipconfig
```

Use the IPv4 address from the active Wi-Fi or Ethernet adapter. The phone and laptop must be on the same network, and Windows Firewall must allow Node.js/private-network access to port `5000`.

## 9. Run Customer App

Android emulator:

```powershell
cd D:\Projects\cargoconnect\customer_app
flutter pub get
flutter devices
flutter run --dart-define=CARGOCONNECT_API_BASE_URL=http://10.0.2.2:5000/api/v1
```

Specific emulator/device:

```powershell
flutter run -d emulator-5554 --dart-define=CARGOCONNECT_API_BASE_URL=http://10.0.2.2:5000/api/v1
```

Physical Android device:

```powershell
flutter run -d <DEVICE_ID> --dart-define=CARGOCONNECT_API_BASE_URL=http://<YOUR_LAPTOP_IP>:5000/api/v1
```

Static check:

```powershell
flutter analyze
```

## 10. Run Driver App

Android emulator:

```powershell
cd D:\Projects\cargoconnect\driver_app
flutter pub get
flutter devices
flutter run --dart-define=CARGOCONNECT_API_BASE_URL=http://10.0.2.2:5000/api/v1
```

Physical Android device:

```powershell
flutter run -d <DEVICE_ID> --dart-define=CARGOCONNECT_API_BASE_URL=http://<YOUR_LAPTOP_IP>:5000/api/v1
```

Static check:

```powershell
flutter analyze
```

## 11. Run Admin Panel In Chrome

```powershell
cd D:\Projects\cargoconnect\admin_panel
flutter pub get
flutter run -d chrome --web-port 54042 --dart-define=CARGOCONNECT_API_BASE_URL=http://localhost:5000/api/v1
```

If port `54042` is busy:

```powershell
flutter run -d chrome --web-port 54043 --dart-define=CARGOCONNECT_API_BASE_URL=http://localhost:5000/api/v1
```

Make sure the selected web origin is included in `CORS_ORIGIN` in `backend\.env`, then restart the backend.

Static check:

```powershell
flutter analyze
```

## 12. Run Admin Panel In Edge

If Flutter lists Edge:

```powershell
cd D:\Projects\cargoconnect\admin_panel
flutter devices
flutter run -d edge --web-port 54043 --dart-define=CARGOCONNECT_API_BASE_URL=http://localhost:5000/api/v1
```

## 13. Postman Smoke Test

Create a Postman environment:

```txt
baseUrl = http://localhost:5000/api/v1
customerToken = empty
adminToken = empty
driverToken = empty
shipmentId = empty
assignmentId = empty
invoiceId = empty
```

Start with:

```txt
GET {{baseUrl}}/health
GET {{baseUrl}}/health/db
```

Login sample:

```http
POST {{baseUrl}}/auth/admin/login
Content-Type: application/json
```

```json
{
  "identifier": "admin@cargoconnect.local",
  "password": "Password123!"
}
```

Use `data.auth.token` as:

```txt
Authorization: Bearer <token>
```

## 14. Full Customer, Admin, Driver Test Order

1. Start XAMPP MySQL.
2. Reset/import migrations.
3. Run `npm run seed`.
4. Start backend with `npm run dev`.
5. Confirm `/health` and `/health/db`.
6. Run Admin Panel in Chrome.
7. Run Customer App.
8. Run Driver App.
9. Customer logs in or registers and verifies OTP.
10. Customer creates a shipment.
11. Customer completes checkout/mock payment.
12. Customer sees order confirmation and invoice preview/download.
13. Admin logs in.
14. Admin sees the shipment in the pending/paid list.
15. Admin approves the shipment.
16. Admin assigns an available driver and vehicle.
17. Driver logs in as the assigned driver.
18. Driver accepts the trip.
19. Driver starts the trip.
20. Driver uploads pickup proof and marks pickup completed.
21. Driver moves the trip in transit and updates ETA/status if needed.
22. Customer tracking and timeline show updated status.
23. Driver uploads delivery proof.
24. Driver marks delivery completed and completes the trip.
25. Customer sees completed shipment, timeline, proofs, and invoice.
26. Admin dashboard and reports reflect the completed workflow.

## 15. Common Errors And Fixes

### `listen EADDRINUSE :::5000`

Another backend is already running on port `5000`.

Fix:

```powershell
netstat -ano | findstr :5000
```

Stop the old terminal/process, or change `PORT` in `backend\.env` and update every app base URL.

### Backend cannot connect to MySQL

Symptoms include `ECONNREFUSED`, `Access denied`, or failed `/health/db`.

Fix:

- Start MySQL from XAMPP.
- Check `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, and `DB_NAME`.
- Run:

```powershell
cd D:\Projects\cargoconnect\backend
npm run health
```

### Seed fails because a table is missing

The database is not fully migrated.

Fix:

- Reset the DB and run all files in `database\migrations` in filename order.
- Confirm the latest support, feedback, breakdown, and trip log migrations are included.

### Android emulator cannot reach backend

Use:

```txt
http://10.0.2.2:5000/api/v1
```

Do not use `localhost` from an Android emulator.

### Physical phone cannot reach backend

Use:

```txt
http://<YOUR_LAPTOP_IP>:5000/api/v1
```

The phone and laptop must be on the same Wi-Fi. Allow Node.js through Windows Firewall.

### Admin web CORS error

Add the web origin to `backend\.env`:

```env
CORS_ORIGIN=http://localhost:3000,http://localhost:54042,http://localhost:54043
```

Restart backend.

### File upload fails

Use Postman `Body > form-data`:

```txt
proof: File
```

for pickup and delivery proof. Use:

```txt
bill: File
```

for fuel bill uploads. Check `MAX_FILE_SIZE_MB` and supported image types.

## 16. Known Local Limitations

- Payments use the CargoConnect mock payment confirmation endpoint, not a real gateway.
- OTP email uses console fallback unless SMTP is configured.
- Proof files and generated PDFs are stored locally by the backend.
- Live map routing and production geolocation tracking are placeholders unless configured with external map services.
- Phone calls, SMS, push notifications, and external share sheets depend on platform/service configuration outside this local setup.

