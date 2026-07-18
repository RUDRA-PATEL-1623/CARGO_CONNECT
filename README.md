# CargoConnect

CargoConnect is a multi-app logistics platform for customer shipment booking,
driver trip execution, admin operations, and MySQL-backed reporting.

## Apps

- `customer_app` - Flutter mobile app for customers.
- `driver_app` - Flutter mobile app for drivers.
- `admin_panel` - Flutter Web admin panel.
- `backend` - Node.js and Express.js API.
- `database` - MySQL migrations, seed data, diagrams, and queries.
- `docs` - Local setup, API testing, USB debugging, and final QA guides.

## Current Scope

The project now includes UI foundations, backend APIs, MySQL schema and seeds,
and real API integration wiring for the primary CargoConnect workflows:

- Customer auth, shipment creation, checkout, mock payment, invoice, tracking,
  history, profile, support, feedback, notifications, and proof views.
- Admin dashboard, shipment approval and assignment, customers, drivers,
  vehicles, payments, invoices, reports, settings, notifications, and exports.
- Driver login, assigned trips, status flow, proof uploads, emergency reports,
  breakdown reports, fuel requests, and notifications.

The local build intentionally uses mock payment confirmation and local file/PDF
generation. External services such as a real payment gateway, production email
or SMS, live maps, push notifications, and phone calling are documented as known
limitations for local testing.

## Quick Start

1. Start XAMPP MySQL.
2. Configure `backend/.env`.
3. Import database migrations and seeds.
4. Start the backend:

```powershell
cd backend
npm run dev
```

5. Run a Flutter app:

```powershell
cd customer_app
flutter run --dart-define=CARGOCONNECT_API_BASE_URL=http://<API_HOST>:5000/api/v1
```

For detailed setup and testing, use the docs below.

## Documentation

- Local setup: `docs/setup/LOCAL_SETUP_GUIDE.md`
- MySQL setup: `docs/setup/MYSQL_DATABASE_SETUP.md`
- Postman testing: `docs/api/POSTMAN_TESTING_GUIDE.md`
- Physical Android device testing: `docs/usb_debugging/RUN_ON_PHYSICAL_ANDROID_DEVICE.md`
- Final real-app QA checklist: `docs/testing/FINAL_REAL_APP_TESTING_CHECKLIST.md`
- Button and screen audit: `docs/testing/BUTTON_AND_SCREEN_AUDIT.md`
