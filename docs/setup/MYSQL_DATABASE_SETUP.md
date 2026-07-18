# CargoConnect MySQL Database Setup

Last updated: 2026-05-19

This guide explains how to set up `cargoconnect_db` locally with XAMPP, phpMyAdmin, migrations, and seeds.

## 1. Requirements

Install these first:

- XAMPP
- Node.js LTS
- CargoConnect project files

Default local database settings:

```txt
Host: localhost
Port: 3306
User: root
Password: empty
Database: cargoconnect_db
```

If your MySQL root user has a password, update `backend\.env` before running backend or seed commands.

## 2. Start MySQL In XAMPP

1. Open `XAMPP Control Panel`.
2. Click `Start` next to `MySQL`.
3. Confirm MySQL turns green and shows a port, usually `3306`.
4. Optional: click `Admin` next to MySQL to open phpMyAdmin.

phpMyAdmin URL:

```txt
http://localhost/phpmyadmin
```

If MySQL does not start:

- Stop any other MySQL service using port `3306`.
- Check `C:\xampp\mysql\data\mysql_error.log`.
- Restart XAMPP Control Panel as Administrator.

## 3. Configure Backend Database Environment

From the backend folder:

```powershell
cd D:\Projects\cargoconnect\backend
Copy-Item .env.example .env
```

Use these local values in `backend\.env`:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=cargoconnect_db
DB_CONNECTION_LIMIT=10
```

If you set a root password in XAMPP, set:

```env
DB_PASSWORD=your_mysql_password
```

## 4. Create Database In phpMyAdmin

You can create the database manually before importing migrations.

1. Open:

```txt
http://localhost/phpmyadmin
```

2. Click `New`.
3. Enter database name:

```txt
cargoconnect_db
```

4. Choose collation:

```txt
utf8mb4_unicode_ci
```

5. Click `Create`.

The first migration also creates the database automatically, so this manual step is optional if you import all migrations from the command line.

## 5. Import Migrations With phpMyAdmin

Import migrations in filename order from:

```txt
D:\Projects\cargoconnect\database\migrations
```

Migration order:

```txt
001_create_database.sql
010_create_users.sql
020_create_customers.sql
030_create_drivers.sql
040_create_vehicles.sql
050_create_shipment_categories.sql
060_create_shipments.sql
070_create_assignments.sql
080_create_payments.sql
090_create_invoices.sql
100_create_proof_uploads.sql
110_create_trip_logs.sql
120_create_notifications.sql
130_create_fuel_requests.sql
140_create_emergency_reports.sql
150_create_audit_logs.sql
160_create_app_settings.sql
170_create_auth_otps.sql
180_alter_shipment_categories_add_icon_key.sql
190_alter_trip_logs_add_started_status.sql
200_alter_reports_and_fuel_upload_metadata.sql
210_alter_notifications_extend_event_types.sql
220_create_support_feedback_breakdown_tables.sql
230_alter_trip_logs_add_rejected_status.sql
```

phpMyAdmin import steps:

1. Select `cargoconnect_db` in the left sidebar.
2. Click `Import`.
3. Click `Choose File`.
4. Select the next migration file.
5. Click `Import`.
6. Repeat until all migration files are imported.

Do not skip the alter migrations at the end; they are required by the latest backend APIs, including driver rejection timeline logs.

## 6. Import Migrations With PowerShell

This is faster and less error-prone than importing one file at a time.

Make sure XAMPP MySQL is running, then run:

```powershell
cd D:\Projects\cargoconnect
$mysql = 'C:\xampp\mysql\bin\mysql.exe'
Get-ChildItem .\database\migrations\*.sql |
  Sort-Object Name |
  ForEach-Object { Get-Content $_.FullName | & $mysql -u root }
```

If root has a password:

```powershell
cd D:\Projects\cargoconnect
$mysql = 'C:\xampp\mysql\bin\mysql.exe'
Get-ChildItem .\database\migrations\*.sql |
  Sort-Object Name |
  ForEach-Object { Get-Content $_.FullName | & $mysql -u root -p }
```

## 7. Import Seeds

Seeds add local sample data:

- Shipment categories
- Admin user
- Sample customers
- Sample drivers
- Sample vehicles
- Sample shipments
- Default admin app settings

Preferred method:

```powershell
cd D:\Projects\cargoconnect\backend
npm install
npm run seed
```

The Node seed runner hashes seeded passwords with bcrypt at runtime.

Default seeded credentials:

```txt
Admin: admin@cargoconnect.local / Password123!
Customer: customer@cargoconnect.local / Password123!
Driver: driver@cargoconnect.local / Password123!
Dispatcher: dispatcher@cargoconnect.local / Password123!
Sample customers and drivers: Password123!
```

Common users:

```txt
Customer: customer@cargoconnect.local / Password123!
Driver: driver@cargoconnect.local / Password123!
Admin: admin@cargoconnect.local / Password123!
```

SQL-only seed order:

```txt
001_seed_shipment_categories.sql
010_seed_users_and_profiles.sql
020_seed_vehicles.sql
030_seed_shipments.sql
040_seed_app_settings.sql
```

PowerShell SQL-only import:

```powershell
cd D:\Projects\cargoconnect
$mysql = 'C:\xampp\mysql\bin\mysql.exe'
Get-ChildItem .\database\seeds\*.sql |
  Sort-Object Name |
  ForEach-Object { Get-Content $_.FullName | & $mysql -u root cargoconnect_db }
```

The SQL seeds are idempotent and use `ON DUPLICATE KEY UPDATE`.

## 8. Check Tables In phpMyAdmin

1. Open:

```txt
http://localhost/phpmyadmin
```

2. Select `cargoconnect_db`.
3. Confirm these tables exist:

```txt
app_settings
assignments
audit_logs
auth_otps
breakdown_reports
customers
drivers
emergency_reports
feedback
fuel_requests
invoices
notifications
payments
proof_uploads
shipment_categories
shipments
support_issues
trip_logs
users
vehicles
```

4. Click a few tables and confirm seed rows exist:

```txt
users
customers
drivers
vehicles
shipment_categories
shipments
app_settings
```

## 9. Check Tables With SQL

Open phpMyAdmin SQL tab and run:

```sql
USE cargoconnect_db;
SHOW TABLES;
```

Check row counts:

```sql
SELECT 'users' AS table_name, COUNT(*) AS rows_count FROM users
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'drivers', COUNT(*) FROM drivers
UNION ALL
SELECT 'vehicles', COUNT(*) FROM vehicles
UNION ALL
SELECT 'shipment_categories', COUNT(*) FROM shipment_categories
UNION ALL
SELECT 'shipments', COUNT(*) FROM shipments;
```

Check constraints and indexes with the repo smoke check:

```powershell
cd D:\Projects\cargoconnect
$mysql = 'C:\xampp\mysql\bin\mysql.exe'
Get-Content .\database\mysql_queries\001_schema_smoke_checks.sql |
  & $mysql -u root cargoconnect_db
```

## 10. Verify Backend Database Connection

Run:

```powershell
cd D:\Projects\cargoconnect\backend
npm run health
```

Start backend:

```powershell
npm run dev
```

In another terminal:

```powershell
Invoke-RestMethod http://localhost:5000/api/v1/health/db
```

Expected response:

```json
{
  "success": true,
  "message": "Database connection is healthy"
}
```

## 11. Reset Database

Warning: this deletes all local CargoConnect data.

Use this only when you want a clean local database.

### Reset With phpMyAdmin

1. Open:

```txt
http://localhost/phpmyadmin
```

2. Click `cargoconnect_db`.
3. Click `Operations`.
4. Click `Drop the database`.
5. Confirm the destructive action.
6. Re-import all migrations.
7. Re-run seeds.

### Reset With SQL

In phpMyAdmin SQL tab:

```sql
DROP DATABASE IF EXISTS cargoconnect_db;
CREATE DATABASE cargoconnect_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

Then run migrations and seeds again.

### Reset With PowerShell

```powershell
cd D:\Projects\cargoconnect
$mysql = 'C:\xampp\mysql\bin\mysql.exe'
@'
DROP DATABASE IF EXISTS cargoconnect_db;
CREATE DATABASE cargoconnect_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
'@ | & $mysql -u root
Get-ChildItem .\database\migrations\*.sql |
  Sort-Object Name |
  ForEach-Object { Get-Content $_.FullName | & $mysql -u root }
cd D:\Projects\cargoconnect\backend
npm run seed
```

If root has a password, add `-p` to each `mysql.exe` command.

## 12. Real Workflow Database Verification

After one full customer, admin, and driver workflow, these checks should show new or updated rows:

```sql
USE cargoconnect_db;

SELECT id, shipment_code, status, payment_status, assigned_driver_id
FROM shipments
ORDER BY id DESC
LIMIT 5;

SELECT id, shipment_id, payment_status, amount
FROM payments
ORDER BY id DESC
LIMIT 5;

SELECT id, shipment_id, invoice_number, payment_status, total_amount
FROM invoices
ORDER BY id DESC
LIMIT 5;

SELECT id, shipment_id, driver_id, vehicle_id, status
FROM assignments
ORDER BY id DESC
LIMIT 5;

SELECT shipment_id, status, created_at
FROM trip_logs
ORDER BY id DESC
LIMIT 10;

SELECT shipment_id, proof_type, uploaded_by_role, file_path
FROM proof_uploads
ORDER BY id DESC
LIMIT 5;
```

Expected final status after a complete local flow:

```txt
shipments.status = completed
assignments.status = completed
payments.payment_status = paid
invoices.payment_status = paid
proof_uploads contains pickup and delivery rows
trip_logs contains assigned/accepted/started/pickup_completed/in_transit/delivered/completed style events
```

## 13. Troubleshooting

MySQL does not start in XAMPP:

- Stop other MySQL services.
- Check whether port `3306` is already used.
- Restart XAMPP as Administrator.

phpMyAdmin import fails:

- Import migrations in filename order.
- Confirm `cargoconnect_db` is selected before importing table migrations.
- Confirm SQL file size is allowed by XAMPP PHP settings.

Backend says database connection failed:

- Confirm XAMPP MySQL is running.
- Confirm `backend\.env` database values.
- Confirm `cargoconnect_db` exists.
- Run `npm run health`.

Seed command fails:

- Run migrations first.
- Confirm `backend\.env` points to `cargoconnect_db`.
- Run `npm install` inside `backend`.
- Check the terminal error for the exact missing table or duplicate constraint.
