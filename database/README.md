# CargoConnect Database

This folder contains MySQL schema assets for `cargoconnect_db`.

## Run Order

Run migrations in filename order from `database/migrations`.

```sql
SOURCE database/migrations/001_create_database.sql;
SOURCE database/migrations/010_create_users.sql;
SOURCE database/migrations/020_create_customers.sql;
SOURCE database/migrations/030_create_drivers.sql;
SOURCE database/migrations/040_create_vehicles.sql;
SOURCE database/migrations/050_create_shipment_categories.sql;
SOURCE database/migrations/060_create_shipments.sql;
SOURCE database/migrations/070_create_assignments.sql;
SOURCE database/migrations/080_create_payments.sql;
SOURCE database/migrations/090_create_invoices.sql;
SOURCE database/migrations/100_create_proof_uploads.sql;
SOURCE database/migrations/110_create_trip_logs.sql;
SOURCE database/migrations/120_create_notifications.sql;
SOURCE database/migrations/130_create_fuel_requests.sql;
SOURCE database/migrations/140_create_emergency_reports.sql;
SOURCE database/migrations/150_create_audit_logs.sql;
SOURCE database/migrations/160_create_app_settings.sql;
SOURCE database/migrations/170_create_auth_otps.sql;
SOURCE database/migrations/180_alter_shipment_categories_add_icon_key.sql;
SOURCE database/migrations/190_alter_trip_logs_add_started_status.sql;
SOURCE database/migrations/200_alter_reports_and_fuel_upload_metadata.sql;
SOURCE database/migrations/210_alter_notifications_extend_event_types.sql;
SOURCE database/migrations/220_create_support_feedback_breakdown_tables.sql;
SOURCE database/migrations/230_alter_trip_logs_add_rejected_status.sql;
```

## Smoke Checks

After running the migrations, execute:

```sql
SOURCE database/mysql_queries/001_schema_smoke_checks.sql;
```

No seed data is included in these migrations.

## Seed Data

Seed instructions and idempotent sample data live in `database/seeds`.

Preferred Node.js runner:

```powershell
cd backend
npm run seed
```

SQL-only seed files can also be run in filename order from `database/seeds`.
