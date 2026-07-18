# CargoConnect Seeds

These files seed development/sample data for `cargoconnect_db`.

## Preferred Seed Method

Use the backend seed runner when Node.js dependencies are installed. It hashes seeded passwords with bcrypt at runtime.

```powershell
cd backend
Copy-Item .env.example .env
npm install
npm run seed
```

Default credentials:

- Admin: `admin@cargoconnect.local` / `Password123!`
- Customer: `customer@cargoconnect.local` / `Password123!`
- Driver: `driver@cargoconnect.local` / `Password123!`
- Dispatcher: `dispatcher@cargoconnect.local` / `Password123!`
- Sample customers and drivers: listed usernames / `Password123!`

The test customer also has seeded shipment, support issue, and feedback records for customer API smoke testing.

You can override passwords before running:

```powershell
$env:SEED_ADMIN_PASSWORD='YourAdminPassword'
$env:SEED_DEFAULT_PASSWORD='YourSamplePassword'
npm run seed
```

## SQL-Only Seed Method

The SQL seed files contain pre-generated bcrypt password hashes for local development. Run after all migrations:

```sql
SOURCE database/seeds/001_seed_shipment_categories.sql;
SOURCE database/seeds/010_seed_users_and_profiles.sql;
SOURCE database/seeds/020_seed_vehicles.sql;
SOURCE database/seeds/030_seed_shipments.sql;
SOURCE database/seeds/040_seed_app_settings.sql;
```

These seeds are idempotent and use `ON DUPLICATE KEY UPDATE`.
