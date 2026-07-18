# CargoConnect Backend And Database Audit

Date: 2026-05-18  
Scope: Backend API, MySQL schema, seeds, middleware, route registration, upload handling, auth, authorization, and API documentation.

This document is an audit and implementation plan only. No major backend code was changed as part of this step.

## Executive Summary

CargoConnect has a substantial backend foundation in place. The Express app, MySQL pool, JWT auth middleware, role middleware, validation middleware, route registry, operational shipment flow, driver trip flow, notifications, uploads, dashboard metrics, and report exports are mostly implemented.

The highest-priority gaps are:

- Uploaded file URLs are now served locally from `/uploads`.
- `support_issues`, `feedback`, and physical `breakdown_reports` tables were added by migration `220`.
- Customer profile, support issue, and feedback APIs are missing.
- Admin settings APIs are missing even though `app_settings` exists.
- Admin payment and invoice management APIs are not clearly separated from reports.
- Dispatcher role exists in the database/constants but is not supported by admin login or admin route permissions.
- `.env.example` appears to contain real SMTP credentials and should be sanitized immediately.

## API Group Status

| API group | Status | Evidence | Required fix |
|---|---|---|---|
| Auth APIs | Partial | Register, OTP verify/resend, customer/driver/admin login, forgot/reset password, and change password routes exist under `backend/src/routes/customerAuth.routes.js`. | Add explicit logout/session invalidation if desired, decide dispatcher login behavior, and remove secrets from env examples. |
| Customer APIs | Partial | Shipment estimate/create/summary/place order, checkout/payment/invoice, history/details/timeline/tracking/proofs, and notifications exist. | Add customer profile get/update, support issue creation/list/details, and feedback APIs. |
| Admin APIs | Partial | Dashboard, customers, drivers, vehicles, shipments, assignments, reports, requests, categories, and notifications are registered. | Add app settings APIs, dedicated payment management APIs, dedicated invoice management APIs, and dispatcher-capable permissions where required. |
| Driver APIs | Complete | Login, profile, logout acknowledgement, availability update, assigned/history trips, trip details, accept/reject, enforced status flow, ETA/delay updates, proof uploads, emergency/breakdown/fuel requests, and notifications exist. | Keep mobile clients pointed at the documented driver endpoints and apply latest trip-log migration. |
| Notification APIs | Partial | Customer, driver, and admin notification list/read/clear/create routes exist; notification generation service covers major workflow events. | Support reply notifications need a real support issue workflow behind them. |
| Upload APIs | Complete | Multer upload middleware, metadata storage, and local `/uploads` static serving are in place for development. | Use authenticated download endpoints before production if proof files become sensitive. |
| Reports/export APIs | Complete | Admin shipment, driver, vehicle, payment, and invoice report/export routes exist under `backend/src/routes/adminReport.routes.js`. | Keep export queries allowlisted and update docs after any schema additions. |

## Database Entity Coverage

| Entity | Status | Notes |
|---|---|---|
| `users` | Complete | Roles include `admin`, `dispatcher`, `customer`, `driver`. |
| `customers` | Complete | Linked to `users`; includes address and soft delete support. |
| `drivers` | Complete | Linked to `users`; includes license and availability fields. |
| `vehicles` | Complete | Includes registration, capacity, fuel, insurance/service dates, availability, soft delete. |
| `shipment_categories` | Complete | Includes base price, vehicle suggestion, icon key, active status. |
| `shipments` | Complete | Includes create shipment UI fields, status, payment status, timestamps, soft delete. |
| `assignments` | Complete | Links shipment, driver, vehicle, assigned by; includes status and timestamps. |
| `payments` | Complete | Supports amount, method, status, transaction reference, paid timestamp. |
| `invoices` | Complete | Supports invoice number, totals, PDF path, generated timestamp. |
| `proof_uploads` | Complete | Supports pickup/delivery proof metadata, verification, location/timestamp text. |
| `trip_logs` | Complete | Supports status history, notes, location, actor, timestamps. |
| `notifications` | Complete | Event types were extended by migration `210`. |
| `support_issues` | Table only | Migration exists; API layer is still pending. |
| `feedback` | Table only | Migration exists; API layer is still pending. |
| `fuel_requests` | Complete | Includes amount, station, bill upload metadata, status, approval fields. |
| `emergency_reports` | Complete | Also stores breakdown reports through `report_type = 'breakdown'`. |
| `breakdown_reports` | Table only | Migration exists; current driver/admin APIs still use `emergency_reports` with `report_type = 'breakdown'`. |
| `audit_logs` | Complete | Admin shipment/status actions use audit logging support. |
| `app_settings` | Table only | Table exists, but no API layer found. |
| `auth_otps` | Extra complete | Supports registration and password reset OTP flows. |

## Startup, Env, And App Configuration

| Area | Status | Finding | Required fix |
|---|---|---|---|
| Express startup | Complete | `backend/src/server.js` verifies MySQL and starts the API. `EADDRINUSE` is handled with a clear message and process exit. | None for audit scope. |
| MySQL connection | Complete | `backend/src/config/database.js` uses `mysql2/promise`, a pool, named placeholders, and a connection test helper. | Keep all queries parameterized. |
| `.env` loading | Complete | `backend/src/config/env.js` centralizes config defaults. | None for audit scope. |
| `.env.example` | Risky | The example file appears to include real SMTP credentials. | Replace credentials with placeholders and rotate the exposed SMTP app password. |
| CORS/helmet/body parsing | Complete | Configured in `backend/src/app.js`. | None for audit scope. |
| Upload directory creation | Complete | App ensures upload directories exist at startup. | None for audit scope. |
| Static upload serving | Complete | Services return `/uploads/...` URLs and `app.js` serves the upload directory for local development. | Add authenticated download endpoints before production if files are sensitive. |

## Route Registration

| Route area | Status | Registered paths |
|---|---|---|
| Auth | Complete | `/api/auth/*` |
| Health | Complete | `/api/health` |
| Shipment categories | Complete | `/api/shipment-categories`, `/api/admin/shipment-categories/*` |
| Customer shipment creation | Complete | `/api/customer/shipments/*` |
| Customer checkout/invoices | Complete | `/api/customer/checkout/*`, `/api/customer/payments/*`, `/api/customer/invoices/*` |
| Customer read APIs | Complete | `/api/customer/shipments/history`, details, timeline, tracking, proofs |
| Customer notifications | Complete | `/api/customer/notifications/*` |
| Admin dashboard | Complete | `/api/admin/dashboard/*` |
| Admin customers | Complete | `/api/admin/customers/*` |
| Admin drivers | Complete | `/api/admin/drivers/*` |
| Admin vehicles | Complete | `/api/admin/vehicles/*` |
| Admin shipments | Complete | `/api/admin/shipments/*` |
| Admin assignments | Complete | `/api/admin/assignments/*` |
| Admin reports | Complete | `/api/admin/reports/*` |
| Admin notifications | Complete | `/api/admin/notifications/*` |
| Admin emergency/fuel requests | Complete | `/api/admin/emergency-reports/*`, `/api/admin/fuel-requests/*` |
| Driver trips | Complete | `/api/driver/trips/*` |
| Driver requests | Complete | `/api/driver/emergency-reports/*`, `/api/driver/breakdown-reports/*`, `/api/driver/fuel-requests/*` |
| Driver notifications | Complete | `/api/driver/notifications/*` |
| Customer support | Missing | No customer support issue route found. |
| Customer feedback | Missing | No customer feedback route found. |
| App settings | Missing | No admin settings route found. |
| Dedicated admin payments | Missing | Reports exist, but no management route group found. |
| Dedicated admin invoices | Missing | Reports/customer invoice download exist, but no management route group found. |

## Middleware And Security Findings

| Area | Status | Finding | Required fix |
|---|---|---|---|
| JWT auth | Complete | `authenticate` validates Bearer tokens, rejects purpose tokens, loads the user, and blocks inactive users. | None for audit scope. |
| Role checks | Complete | `requireAdmin` allows both `admin` and `dispatcher`, while `requireAdminOnly` is available for admin-only actions. | Use `requireAdminOnly` on future actions that dispatchers must not perform. |
| Ownership checks | Partial | Customer and driver ownership checks exist in middleware/models/services. | Keep route-by-route review during implementation, especially for new support/profile/feedback endpoints. |
| Validation | Complete | `express-validator` middleware exists and validators are present for major API groups. | Add validators for missing APIs. |
| Error handling | Complete | Standard error and 404 middleware exist. | Keep user-facing messages professional and avoid leaking internals. |
| SQL injection protection | Complete | Models predominantly use `execute` with bind parameters. Dynamic SQL fragments are internal/allowlisted. | Keep future filter/sort fields allowlisted. |
| File upload limits | Complete | Multer middleware enforces size limits and MIME type allowlists. | Add static serving/download authorization. |
| Audit logs | Partial | Admin shipment/status actions use audit logging. | Ensure new admin settings/payment/invoice/support actions also write audit logs where relevant. |

## Migration And Seed Findings

| Area | Status | Finding | Required fix |
|---|---|---|---|
| Core migrations | Complete | Core tables exist, including `support_issues`, `feedback`, and `breakdown_reports`. | Add API layers for support and feedback workflows. |
| Alter migrations | Risky | Later migrations use `ALTER TABLE ... ADD COLUMN` and constraint replacement patterns that may not be idempotent. | Make reruns safer or document one-time migration behavior clearly. |
| Seeds | Partial | Admin/customer/driver/vehicle/category/shipment seeds exist; backend seed script supports bcrypt hashing. | Add seeds for support/feedback/breakdown data after adding tables. |
| Seed instructions | Partial | Database docs exist. | Keep seed command and manual import instructions aligned with migration changes. |

## Missing APIs

| Priority | Missing API | Why it matters |
|---|---|---|
| High | Customer profile get/update | Customer App has profile/edit profile flows that need persisted data. |
| High | Customer support issue create/list/details | Support UI and support reply notifications need a real workflow. |
| High | Customer feedback create/list or create-only | Feedback UI currently has no backend persistence. |
| High | Admin app settings get/update | Settings UI has no real backend even though `app_settings` table exists. |
| Medium | Dedicated admin payment list/details/status APIs | Admin payment management should not depend only on report endpoints. |
| Medium | Dedicated admin invoice list/preview/download APIs | Admin invoice management should have first-class endpoints. |
| Medium | Dispatcher login/access policy | Dispatcher role exists but cannot use admin APIs today. |
| Medium | Auth logout/session invalidation | JWT logout can be client-side, but server-side revocation is not present. |

## Missing Tables Or Columns

| Priority | Missing table/column | Required fix |
|---|---|---|
| Medium | Support/feedback API columns | The tables exist; confirm any extra fields needed while implementing the API layer. |
| Medium | Breakdown API mapping | `breakdown_reports` exists, but current driver/admin request APIs still store breakdown requests in `emergency_reports`. Decide whether to migrate API writes to the dedicated table. |
| Medium | App setting audit fields | `app_settings` exists; confirm it has enough fields for setting key/value/type/group/updated_by. Add audit logs for changes. |

## Broken Or Risky Backend Areas

1. Uploaded proof, report, and fuel bill URLs are locally reachable through `/uploads`; production should use authenticated downloads if proofs are sensitive.
2. `.env.example` was sanitized, but any previously exposed SMTP credential should still be rotated.
3. Support issue and feedback UI flows cannot become real until API support is added.
4. Breakdown report APIs currently share `emergency_reports`; the dedicated `breakdown_reports` table now exists but is not yet wired to the API layer.
6. Admin settings has a table but no API layer.
7. Admin payment/invoice screens need dedicated APIs if they must manage records rather than only report on them.
8. Some migrations are not safely rerunnable because alter statements are not idempotent.

## Recommended Implementation Order

1. Rotate any SMTP credential that may have been exposed before `.env.example` was sanitized.
2. Implement customer profile get/update APIs with ownership checks.
3. Implement support issue and feedback API layers on top of the new tables.
4. Decide whether breakdown APIs should write to `breakdown_reports` or continue using `emergency_reports`.
5. Implement admin settings APIs backed by `app_settings`, with validation and audit logs.
6. Implement dedicated admin payment and invoice management APIs.
7. Make later alter migrations safer to rerun or document one-time import expectations.
8. Add authenticated download endpoints before production if proof/report files should not be public on local `/uploads`.
9. Run the full seeded workflow: customer booking, payment, admin approval/assignment, driver completion, customer tracking/proofs, admin reports.

## Verification Notes

Audit was performed by reading backend source, migrations, seed files, and existing API documentation. No server, database, migration, or API mutation command was run during this audit-only step.
