# CargoConnect Final Testing Checklist

Last updated: 2026-05-18

Use this checklist before presenting or handing off CargoConnect. It covers the Customer App, Driver App, Admin Panel, Backend API, MySQL database, and physical Android device testing.

Related docs:

- `docs/setup/LOCAL_SETUP_GUIDE.md`
- `docs/setup/MYSQL_DATABASE_SETUP.md`
- `docs/api/POSTMAN_TESTING_GUIDE.md`
- `docs/usb_debugging/RUN_ON_PHYSICAL_ANDROID_DEVICE.md`

## 1. Test Environment

- [ ] XAMPP MySQL is running.
- [ ] `cargoconnect_db` exists.
- [ ] All migrations are imported in filename order.
- [ ] Seed data is loaded.
- [ ] Backend `.env` points to local MySQL.
- [ ] Backend starts with `npm run dev`.
- [ ] `GET /api/v1/health` returns `success: true`.
- [ ] `GET /api/v1/health/db` returns `success: true`.
- [ ] Customer App runs as a separate Flutter project.
- [ ] Driver App runs as a separate Flutter project.
- [ ] Admin Panel runs as a separate Flutter Web project.

## 2. Build And Static Checks

Backend:

- [ ] `cd backend`
- [ ] `npm install`
- [ ] `npm run health`

Customer App:

- [ ] `cd customer_app`
- [ ] `flutter pub get`
- [ ] `flutter analyze`

Driver App:

- [ ] `cd driver_app`
- [ ] `flutter pub get`
- [ ] `flutter analyze`

Admin Panel:

- [ ] `cd admin_panel`
- [ ] `flutter pub get`
- [ ] `flutter analyze`

## 3. UI Visual Checks

Customer App:

- [ ] Splash screen displays brand, tagline, animation, and version text.
- [ ] Onboarding has 3 screens, skip/next indicators, and final login CTA.
- [ ] Login, register, OTP, forgot password, and create password forms are visually consistent.
- [ ] Home dashboard shows greeting, active shipment card, quick actions, recent shipments, and bottom navigation.
- [ ] Shipment creation screens use consistent cards, spacing, buttons, and form fields.
- [ ] Checkout, payment, confirmation, invoice, tracking, timeline, history, details, proof, profile, notifications, support, and feedback screens render without overflow.

Driver App:

- [ ] Splash and login screens render correctly.
- [ ] Dashboard shows availability, assigned trips, active trip, route summary, emergency action, and bottom navigation.
- [ ] Assigned trips, trip details, start trip, proof upload, in-transit update, completion, history, emergency, breakdown, fuel request, and profile screens render without overflow.
- [ ] Mandatory upload states clearly disable submit until proof or bill is selected.

Admin Panel:

- [ ] Login and preloader render correctly.
- [ ] Sidebar expands/collapses correctly.
- [ ] Top bar remains usable at desktop and tablet widths.
- [ ] Dashboard cards, charts, and recent activity table render correctly.
- [ ] Shipment, driver, vehicle, customer, payment, invoice, reports, settings, and profile screens use consistent table/card styling.
- [ ] Dialogs, drawers, filters, and action menus are readable and aligned.

## 4. Responsiveness Checks

Mobile apps:

- [ ] Test on a small Android screen.
- [ ] Test on a large Android screen.
- [ ] Text does not overlap buttons, cards, or icons.
- [ ] Forms scroll when the keyboard opens.
- [ ] Bottom navigation remains reachable.
- [ ] Loading, empty, error, and success states fit the screen.

Admin web:

- [ ] Test Chrome desktop width around `1440px`.
- [ ] Test tablet width around `1024px`.
- [ ] Test narrow width around `768px`.
- [ ] Tables remain horizontally usable or adapt cleanly.
- [ ] Filters wrap without overlapping.
- [ ] Dialogs fit within viewport height.

## 5. Authentication Checks

Customer:

- [ ] Customer registration sends or logs OTP.
- [ ] Unverified customer cannot login.
- [ ] OTP verification activates customer account.
- [ ] Verified active customer can login.
- [ ] Customer token is saved by the app/Postman.
- [ ] Logout clears local token/session.
- [ ] Forgot password generates reset OTP.
- [ ] Reset OTP verification works.
- [ ] Create new password works.
- [ ] Authenticated change password works.

Driver:

- [ ] Driver can login with admin-created credentials.
- [ ] Driver cannot register from Driver App.
- [ ] Inactive driver cannot login.
- [ ] Driver logout clears token/session.
- [ ] Driver change password works.

Admin:

- [ ] Admin can login.
- [ ] Non-admin token cannot open admin APIs.
- [ ] Admin logout clears token/session.

## 6. Role Access Checks

- [ ] Customer token can access only customer-owned shipment data.
- [ ] Customer token cannot access `/admin/*`.
- [ ] Customer token cannot access `/driver/*`.
- [ ] Driver token can access only assigned trip data.
- [ ] Driver token cannot access another driver's assignment.
- [ ] Driver token cannot access customer shipment details directly.
- [ ] Admin token can access admin management APIs.
- [ ] Missing token returns `401`.
- [ ] Wrong role returns `403`.
- [ ] Cross-account customer or driver access returns `404` or protected error response.

## 7. Database Checks

- [ ] `SHOW TABLES` lists all expected tables.
- [ ] `users` table contains admin, customers, and drivers.
- [ ] `shipment_categories` contains active categories.
- [ ] `drivers` contains active available drivers.
- [ ] `vehicles` contains available vehicles.
- [ ] `shipments` records are created by customer flow.
- [ ] `payments` records are created after mock payment.
- [ ] `invoices` records are created after mock payment.
- [ ] `assignments` records are created after admin assignment.
- [ ] `trip_logs` records are created for every driver status update.
- [ ] `proof_uploads` contains pickup and delivery proof metadata.
- [ ] `notifications` are generated for booking, approval, assignment, accept, pickup, in-transit, delivered, completed, cancelled, and emergency events where applicable.
- [ ] `audit_logs` records admin shipment and assignment actions.
- [ ] Soft delete columns remain intact where used.
- [ ] Foreign keys prevent orphaned records.

## 8. Customer Shipment Flow

- [ ] Customer logs in.
- [ ] Customer lists shipment categories.
- [ ] Customer selects a category.
- [ ] Price estimate works with valid weight and distance.
- [ ] Invalid category/weight returns validation error.
- [ ] Customer creates shipment with pickup, delivery, package, receiver, and notes.
- [ ] Shipment summary returns the created data.
- [ ] Checkout returns price breakdown and payment methods.
- [ ] Mock payment succeeds.
- [ ] Payment record is `paid`.
- [ ] Invoice record is generated.
- [ ] Order confirmation shows pending status.
- [ ] Customer history includes the new shipment.
- [ ] Customer shipment details load.

## 9. Admin Shipment And Assignment Flow

- [ ] Admin logs in.
- [ ] Dashboard metrics load.
- [ ] Shipment list shows pending paid shipment.
- [ ] Admin details page shows customer, receiver, pickup, delivery, payment, invoice, and timeline data.
- [ ] Admin approve works only for paid pending shipment.
- [ ] Admin reject requires reason.
- [ ] Admin cancel requires reason.
- [ ] Driver list can filter available active drivers.
- [ ] Vehicle list can filter available vehicles.
- [ ] Conflict validation blocks busy driver or unavailable vehicle.
- [ ] Assignment succeeds for approved shipment.
- [ ] Shipment status changes to `assigned`.
- [ ] Audit log is created.

## 10. Driver Trip Flow

- [ ] Assigned trip appears in Driver App and `/driver/trips?group=new`.
- [ ] Driver trip details show customer masked data, receiver, route, package, vehicle, and timeline.
- [ ] Accept works only when assignment is `assigned`.
- [ ] Reject requires reason and returns shipment to dispatch queue.
- [ ] Start works only after accept.
- [ ] Pickup completed works only after start.
- [ ] In transit is blocked until pickup proof exists.
- [ ] Delivery completed is blocked until delivery proof exists.
- [ ] Complete works only after delivery completed.
- [ ] Driver/vehicle availability is released when trip completes.

## 11. Driver Proof Upload

Pickup proof:

- [ ] Upload uses `multipart/form-data`.
- [ ] File field name is `proof`.
- [ ] JPG file accepted.
- [ ] PNG file accepted.
- [ ] WEBP file accepted.
- [ ] Unsupported file type rejected.
- [ ] File larger than configured limit is rejected.
- [ ] Missing proof returns validation error.
- [ ] Metadata stores notes, location text, captured time, file name, MIME type, and size.

Delivery proof:

- [ ] Upload uses `multipart/form-data`.
- [ ] File field name is `proof`.
- [ ] Submit is blocked without proof.
- [ ] Proof appears in customer proof list.
- [ ] Proof details show uploaded by driver, timestamp, location, and verification status.

## 12. Tracking And Timeline

- [ ] Customer tracking loads after assignment.
- [ ] Tracking shows current status.
- [ ] Tracking shows masked driver details after assignment.
- [ ] Tracking shows vehicle details after assignment.
- [ ] ETA and route summary placeholders render.
- [ ] Timeline shows Pending, Approved, Assigned, Accepted, Pickup Completed, In Transit, Delivered, Completed.
- [ ] Completed/current/pending states are accurate.
- [ ] Timestamps come from shipment, assignment, and trip log data.

## 13. Notifications

Customer:

- [ ] Booking/payment notification appears.
- [ ] Approval notification appears.
- [ ] Driver assignment notification appears.
- [ ] Driver accept notification appears.
- [ ] Pickup/in-transit/delivered/completed notifications appear.
- [ ] Notification read and read-all actions work.
- [ ] Clear notifications action works.

Driver:

- [ ] Assignment notification appears.
- [ ] Cancellation/reassignment notifications appear where applicable.
- [ ] Notification read and clear actions work.

Admin:

- [ ] Booking or emergency notifications appear.
- [ ] Manual notification creation works if tested.

## 14. Reports And Exports

Dashboard:

- [ ] Total shipments count updates.
- [ ] Pending count updates.
- [ ] Active deliveries count updates.
- [ ] Delivered/completed count updates.
- [ ] Available and busy driver counts update.
- [ ] Vehicle utilization updates.
- [ ] Revenue summary updates after payment.
- [ ] Recent activity includes new events.

Reports:

- [ ] Shipment report loads.
- [ ] Driver report loads.
- [ ] Vehicle report loads.
- [ ] Payment report loads.
- [ ] Invoice report loads.
- [ ] Date filters work.
- [ ] Status filters work.
- [ ] Category filters work.
- [ ] Payment method/status filters work.
- [ ] Empty report filter state is readable.

Exports:

- [ ] Shipment CSV export downloads.
- [ ] Shipment PDF export downloads.
- [ ] Driver CSV/PDF exports download.
- [ ] Vehicle CSV/PDF exports download.
- [ ] Payment CSV/PDF exports download.
- [ ] Invoice CSV/PDF exports download.
- [ ] Export files are non-empty.
- [ ] PDF opens locally.
- [ ] CSV opens in spreadsheet editor.

## 15. Error Handling

API:

- [ ] Invalid login returns friendly error.
- [ ] Missing required fields return `422`.
- [ ] Invalid IDs return `404`.
- [ ] Wrong role returns `403`.
- [ ] Missing token returns `401`.
- [ ] Status flow violations return `409`.
- [ ] Double assignment returns conflict validation.
- [ ] Backend returns consistent response envelope with `success`, `message`, `data`, `errors`, and `timestamp` where applicable.

Apps:

- [ ] Loading states appear during network calls.
- [ ] Empty states appear for empty lists.
- [ ] Error states appear when backend is stopped.
- [ ] Retry actions work where available.
- [ ] Form validation prevents invalid submit.
- [ ] File upload errors are visible to the user.
- [ ] Logout returns user to login screen.

## 16. Physical Android Device Testing

Setup:

- [ ] Developer Options enabled.
- [ ] USB debugging enabled.
- [ ] Phone trusts the laptop.
- [ ] `flutter devices` lists the phone.
- [ ] Customer App runs on physical phone.
- [ ] Driver App runs on physical phone.

Base URL:

- [ ] Laptop IP found with `ipconfig`.
- [ ] Backend reachable from phone browser:

```txt
http://<LAPTOP_IP>:5000/api/v1/health
```

- [ ] Customer App run command uses laptop IP:

```powershell
flutter run -d <DEVICE_ID> --dart-define=CARGOCONNECT_API_BASE_URL=http://<LAPTOP_IP>:5000/api/v1
```

- [ ] Driver App run command uses laptop IP:

```powershell
flutter run -d <DEVICE_ID> --dart-define=CARGOCONNECT_API_BASE_URL=http://<LAPTOP_IP>:5000/api/v1
```

Device flow:

- [ ] Customer can login on phone.
- [ ] Customer can create and pay shipment on phone.
- [ ] Driver can login on phone.
- [ ] Driver can upload pickup proof from phone.
- [ ] Driver can upload delivery proof from phone.
- [ ] Customer can track completed shipment on phone.

## 17. Final End-To-End Pass

Perform one clean full pass:

- [ ] Customer creates shipment.
- [ ] Customer completes mock payment.
- [ ] Admin approves shipment.
- [ ] Admin assigns driver and vehicle.
- [ ] Driver accepts trip.
- [ ] Driver starts trip.
- [ ] Driver marks pickup completed.
- [ ] Driver uploads pickup proof.
- [ ] Driver marks in transit.
- [ ] Driver uploads delivery proof.
- [ ] Driver marks delivery completed.
- [ ] Driver completes trip.
- [ ] Customer tracking shows completed.
- [ ] Customer timeline shows completed flow.
- [ ] Customer proofs show pickup and delivery.
- [ ] Admin dashboard metrics update.
- [ ] Admin shipment/payment reports include the test flow.
- [ ] CSV/PDF exports work.

## 18. Sign-Off Notes

Record final test details:

```txt
Tester:
Date:
Backend base URL:
Database:
Customer device:
Driver device:
Admin browser:
Test shipment code:
Assignment code:
Known issues:
Sign-off:
```

