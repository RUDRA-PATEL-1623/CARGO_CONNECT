# CargoConnect Final Real App Testing Checklist

Last updated: 2026-05-19

Use this checklist for the final local handoff of CargoConnect. It validates the real Node.js API, MySQL database, Customer App, Driver App, Admin Panel, role access, uploads, downloads, reports, and button/screen behavior.

Related docs:

- `docs/setup/LOCAL_SETUP_GUIDE.md`
- `docs/setup/MYSQL_DATABASE_SETUP.md`
- `docs/api/POSTMAN_TESTING_GUIDE.md`
- `docs/testing/BUTTON_AND_SCREEN_AUDIT.md`
- `docs/usb_debugging/RUN_ON_PHYSICAL_ANDROID_DEVICE.md`

## 1. Environment Readiness

- [ ] Git is installed and `git --version` works.
- [ ] Node.js LTS is installed and `node -v` works.
- [ ] npm is installed and `npm -v` works.
- [ ] Flutter stable is installed and `flutter --version` works.
- [ ] `flutter doctor` has no blocking Android or Chrome issues.
- [ ] Android Studio SDK, Platform-Tools, Emulator, and Command-line Tools are installed.
- [ ] Chrome is installed for Admin Panel testing.
- [ ] XAMPP is installed.
- [ ] Postman is installed.
- [ ] VS Code opens the workspace.

## 2. Database Setup

- [ ] XAMPP MySQL is running on port `3306`.
- [ ] `backend\.env` points to the local MySQL instance.
- [ ] `cargoconnect_db` exists.
- [ ] All migrations in `database\migrations` were applied in filename order.
- [ ] Seed data was loaded with `npm run seed`.
- [ ] Schema smoke check passes.
- [ ] Seed credentials work:

```txt
Admin: admin@cargoconnect.local / Password123!
Dispatcher: dispatcher@cargoconnect.local / Password123!
Customer: customer@cargoconnect.local / Password123!
Driver: driver@cargoconnect.local / Password123!
```

Required tables:

- [ ] `users`
- [ ] `customers`
- [ ] `drivers`
- [ ] `vehicles`
- [ ] `shipment_categories`
- [ ] `shipments`
- [ ] `assignments`
- [ ] `payments`
- [ ] `invoices`
- [ ] `proof_uploads`
- [ ] `trip_logs`
- [ ] `notifications`
- [ ] `support_issues`
- [ ] `feedback`
- [ ] `fuel_requests`
- [ ] `emergency_reports`
- [ ] `breakdown_reports`
- [ ] `audit_logs`
- [ ] `app_settings`

## 3. Backend Checks

Run:

```powershell
cd D:\Projects\cargoconnect\backend
npm install
npm run health
npm run dev
```

Verify:

- [ ] `GET http://localhost:5000/api/v1/health` returns `success: true`.
- [ ] `GET http://localhost:5000/api/v1/health/db` returns `success: true`.
- [ ] `GET http://localhost:5000/api/v1` returns route registry data.
- [ ] Invalid route returns the standard 404 response envelope.
- [ ] Validation errors return `422` with an `errors` array.
- [ ] Missing token returns `401`.
- [ ] Wrong role returns `403`.
- [ ] Invalid status transition returns `409`.

## 4. App Startup Checks

Customer App:

```powershell
cd D:\Projects\cargoconnect\customer_app
flutter pub get
flutter analyze
flutter run --dart-define=CARGOCONNECT_API_BASE_URL=http://10.0.2.2:5000/api/v1
```

Driver App:

```powershell
cd D:\Projects\cargoconnect\driver_app
flutter pub get
flutter analyze
flutter run --dart-define=CARGOCONNECT_API_BASE_URL=http://10.0.2.2:5000/api/v1
```

Admin Panel:

```powershell
cd D:\Projects\cargoconnect\admin_panel
flutter pub get
flutter analyze
flutter run -d chrome --web-port 54042 --dart-define=CARGOCONNECT_API_BASE_URL=http://localhost:5000/api/v1
```

## 5. Authentication And Role Access

Customer:

- [ ] Customer registration creates `users` and `customers` rows.
- [ ] OTP is sent by SMTP or logged to console fallback.
- [ ] OTP verification marks the customer verified/active.
- [ ] Customer login returns JWT and profile.
- [ ] Customer logout clears token and returns to login.
- [ ] Forgot/reset/change password validation works.

Driver:

- [ ] Driver can log in with admin-created credentials.
- [ ] Driver cannot self-register from Driver App.
- [ ] Driver token can access only assigned trips.
- [ ] Driver logout clears token.
- [ ] Driver change password works.

Admin:

- [ ] Admin can log in.
- [ ] Dispatcher can log in if testing dispatcher role.
- [ ] Admin token can access management APIs.
- [ ] Admin logout clears token locally.

Cross-role:

- [ ] Customer token cannot call `/admin/*` or `/driver/*`.
- [ ] Driver token cannot access customer shipment details directly.
- [ ] Customer cannot access another customer's shipment.
- [ ] Driver cannot access another driver's assignment.

## 6. Customer Workflow

- [ ] Splash routes intelligently based on onboarding flag and token.
- [ ] Onboarding skip, next, indicators, and get started work.
- [ ] Login, register, OTP, resend, forgot password, reset password, and change password work.
- [ ] Home quick actions navigate correctly.
- [ ] Bottom navigation works.
- [ ] Categories load from API.
- [ ] Category continue opens create shipment.
- [ ] Create shipment validates required fields and submits to API.
- [ ] Price estimate and summary match backend response.
- [ ] Checkout loads backend charge breakdown.
- [ ] Coupon action gives clear feedback.
- [ ] Payment method selector works.
- [ ] Pay now calls mock payment API and handles loading/error/success.
- [ ] Order confirmation shows booking ID and status.
- [ ] Invoice preview loads from API.
- [ ] Invoice PDF download returns a non-empty PDF.
- [ ] Shipment history search/filter/load more works.
- [ ] Shipment card tap opens details.
- [ ] Tracking opens and reflects database status.
- [ ] Timeline shows Pending, Approved, Assigned, Accepted, Pickup Completed, In Transit, Delivered, Completed.
- [ ] Proof view shows uploaded proof metadata and image/file link where available.
- [ ] Notifications list loads, mark-read works, and clear/read-all works where supported.
- [ ] Profile loads from API.
- [ ] Edit profile saves to database and refreshes UI.
- [ ] Support issue submit saves to database.
- [ ] Feedback submit saves to database.
- [ ] Empty and failed API states are readable and retryable where supported.

## 7. Admin Workflow

- [ ] Admin dashboard metrics load from database.
- [ ] Recent activity loads from audit/log/status data.
- [ ] Sidebar and topbar navigation work.
- [ ] Shipment list search/filter/pagination works.
- [ ] Shipment details show customer, receiver, package, payment, invoice, assignment, proofs, and timeline.
- [ ] Approve pending paid shipment works and creates audit log.
- [ ] Reject/cancel requires reason and creates audit log.
- [ ] Assignment screen loads available drivers and vehicles.
- [ ] Conflict validation blocks busy driver or vehicle.
- [ ] Assignment creates `assignments` row and sets shipment to `assigned`.
- [ ] Reassignment validates conflicts.
- [ ] Driver create/edit/view/activate/deactivate works.
- [ ] Vehicle create/edit/view/activate/deactivate works.
- [ ] Customer list/details/search/filter works.
- [ ] Customer activate/deactivate works.
- [ ] Payments list/details/filter works.
- [ ] Invoices list/details/download works.
- [ ] Reports load real database aggregates.
- [ ] CSV export downloads non-empty CSV.
- [ ] PDF export downloads non-empty PDF or shows a clear unavailable response if disabled.
- [ ] Settings load and save to database.
- [ ] Profile loads and logout works.
- [ ] Tables show loading, empty, error, and refreshed states after mutations.

## 8. Driver Workflow

- [ ] Driver dashboard loads assigned/active/completed counts from API.
- [ ] Availability toggle persists when allowed.
- [ ] Assigned trips list loads only this driver's assignments.
- [ ] Trip filters work.
- [ ] Trip card tap opens trip details.
- [ ] Accept trip updates assignment and shipment status.
- [ ] Reject trip requires reason.
- [ ] Start trip requires accepted trip and creates a trip log.
- [ ] Pickup proof selection/upload works.
- [ ] Pickup proof creates `proof_uploads` metadata.
- [ ] Pickup completed creates a trip log.
- [ ] In-transit is blocked until pickup proof exists.
- [ ] ETA/status/delay update creates trip log.
- [ ] Delivery proof selection/upload works.
- [ ] Delivery completed is blocked until delivery proof exists.
- [ ] Complete trip sets final status and releases driver/vehicle availability.
- [ ] Trip history loads completed/rejected/cancelled trips.
- [ ] Emergency report saves to database and notifies admin where supported.
- [ ] Breakdown report saves to database.
- [ ] Fuel request saves to database.
- [ ] Fuel bill upload saves file metadata.
- [ ] Profile and change password work.

## 9. Data Consistency Checks

After one full flow:

- [ ] `shipments.status` is `completed`.
- [ ] `shipments.payment_status` is `paid`.
- [ ] `assignments.status` is `completed`.
- [ ] `payments.payment_status` is `paid`.
- [ ] `invoices.payment_status` is `paid`.
- [ ] `proof_uploads` has pickup and delivery rows.
- [ ] `trip_logs` has ordered status events.
- [ ] Customer timeline reflects driver updates.
- [ ] Customer proof view reflects uploaded proof files.
- [ ] Admin dashboard counts changed.
- [ ] Admin shipment/payment/invoice reports include the test data.
- [ ] Notifications were created/read where supported.
- [ ] Admin audit logs exist for approval and assignment actions.

## 10. Upload, Download, Export Checks

- [ ] Pickup proof upload accepts valid JPG, PNG, or WEBP.
- [ ] Delivery proof upload accepts valid JPG, PNG, or WEBP.
- [ ] Invalid file type is rejected.
- [ ] Oversized file is rejected according to `MAX_FILE_SIZE_MB`.
- [ ] Fuel bill upload works if supported by the UI path being tested.
- [ ] Customer invoice PDF download works.
- [ ] Admin invoice PDF download works.
- [ ] Report CSV exports are non-empty.
- [ ] Report PDF exports are non-empty or return a clear unavailable response.

## 11. Responsiveness Checks

Customer and Driver apps:

- [ ] Small Android viewport has no overflow.
- [ ] Large Android viewport has no awkward spacing or clipped controls.
- [ ] Forms scroll above the keyboard.
- [ ] Bottom navigation remains reachable.
- [ ] Loading, empty, error, and success states fit the screen.

Admin Panel:

- [ ] Desktop width around `1440px` works.
- [ ] Tablet width around `1024px` works.
- [ ] Narrow width around `768px` works.
- [ ] Sidebar state changes do not hide content.
- [ ] Tables remain horizontally usable.
- [ ] Filters wrap cleanly.
- [ ] Dialogs fit within viewport height.

## 12. Physical Android Device Checks

- [ ] Developer Options enabled.
- [ ] USB debugging enabled.
- [ ] Phone trusts computer.
- [ ] `flutter devices` lists the phone.
- [ ] Backend reachable from phone browser:

```txt
http://<YOUR_LAPTOP_IP>:5000/api/v1/health
```

- [ ] Customer App run command uses laptop IP.
- [ ] Driver App run command uses laptop IP.
- [ ] Customer can log in and create a shipment on phone.
- [ ] Driver can log in and upload proof on phone.

## 13. Button And Screen Checklist

- [ ] Every visible button, icon button, link, row action, card tap, dialog action, and bottom navigation item either works or shows a clear fallback.
- [ ] No click silently fails.
- [ ] Every navigation target exists.
- [ ] Every data-changing action validates input before submit.
- [ ] Every data-changing action shows loading and success/error feedback.
- [ ] Every mutation refreshes local screen state from the API response or by refetching.
- [ ] Empty lists show empty states.
- [ ] Failed API calls show retry/error states.
- [ ] Logout/profile/settings actions work for the correct role.

## 14. Known Local Limitations

- Payment is mock-confirmed by local API. No real payment gateway is configured.
- OTP email logs to console unless SMTP is configured.
- Uploaded proof files and generated PDFs are local backend files.
- Live maps, turn-by-turn routing, production tracking, SMS, push notifications, real phone calling, and external share sheets require external services or platform configuration.

## 15. Final Sign-Off Record

```txt
Tester:
Date:
Backend base URL:
Database:
Customer device:
Driver device:
Admin browser:
Customer account:
Admin account:
Driver account:
Test shipment code:
Assignment ID:
Invoice ID:
Known issues:
Sign-off:
```

