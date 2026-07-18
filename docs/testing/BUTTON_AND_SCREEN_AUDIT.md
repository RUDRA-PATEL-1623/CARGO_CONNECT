# CargoConnect Button And Screen Audit

Audit date: 2026-05-19

Scope:

- `customer_app`
- `driver_app`
- `admin_panel`

Purpose:

- Confirm every clickable item has a handler or a clear professional fallback.
- Confirm navigation routes exist and do not crash.
- Confirm real workflow actions are API-backed where the backend supports them.
- Keep local-only external services documented as known limitations.

Status values:

- `working`: Route/action is wired and expected to work in local testing.
- `working - API`: Calls backend and refreshes or updates state from the response.
- `fallback`: Shows a clear message because the external service is not configured locally.
- `local/mock by design`: Intentionally local simulation, for example mock payment.

## Summary

No registered route target is missing in the current Customer App, Driver App, or Admin Panel route registries.

Primary workflow buttons are expected to be functional:

- Customer creates shipment, checks out, pays through mock payment, views invoice, tracks shipment, views proof, submits support and feedback.
- Admin approves, rejects, cancels, assigns, manages drivers/vehicles/customers, views payments/invoices/reports, exports files, updates settings.
- Driver accepts, rejects, starts, uploads proofs, updates status, completes trip, submits emergency/breakdown/fuel requests.

Remaining local limitations are external-service placeholders, not missing app screens:

- Real payment gateway is replaced by mock payment confirmation.
- Live map routing is represented by app UI placeholders unless map services are configured.
- Phone calls, SMS, push notifications, production email, and platform share sheets require external or platform configuration.

## Route Coverage

| App | Route coverage result | Notes |
| --- | --- | --- |
| Customer App | working | All route constants in `customer_app/lib/core/router/app_routes.dart` are registered in the app router. |
| Driver App | working | All route constants in `driver_app/lib/core/router/app_routes.dart` are registered in the app router. |
| Admin Panel | working | All route constants and sidebar items in `admin_panel/lib/core/router/app_routes.dart` are registered in the app router. |

## Customer App Buttons/Screens

| Screen name | Button/action name | Current status | Required fix | File path |
| --- | --- | --- | --- | --- |
| Splash | Auto-navigation | working | None. Verify first launch, completed onboarding, and valid token paths. | `customer_app/lib/features/onboarding/splash_screen.dart` |
| Onboarding | Skip, Next, page indicators, Get Started | working | None. Confirm onboarding flag is saved locally. | `customer_app/lib/features/onboarding/onboarding_screen.dart` |
| Login | Show/hide password, forgot password, login, register link | working - API | None. Validate error messages for invalid credentials. | `customer_app/lib/features/auth/auth_screen.dart` |
| Register | Create account, terms checkbox, login link | working - API | None. Confirm OTP is logged/sent and account stays unverified until OTP. | `customer_app/lib/features/auth/register_screen.dart` |
| OTP Verification | Verify, resend, edit target | working - API | None. | `customer_app/lib/features/auth/otp_verification_screen.dart` |
| Forgot Password | Submit reset request, login link | working - API | None. | `customer_app/lib/features/auth/forgot_password_screen.dart` |
| Create New Password | Password fields, submit | working - API | None. | `customer_app/lib/features/auth/create_password_screen.dart` |
| Home | Quick actions, notification, support, active shipment, recent shipment taps | working - API | None. Confirm cards refresh after shipment creation and trip updates. | `customer_app/lib/features/home/home_screen.dart` |
| Bottom Navigation | Home, Shipments, Tracking, Profile | working | None. | `customer_app/lib/core/widgets/customer_bottom_navigation.dart` |
| Category Selection | Category card tap, Continue | working - API | None. | `customer_app/lib/features/shipment/shipment_screen.dart` |
| Create Shipment | Date/time picker, dropdowns, fragile checkbox, submit | working - API | None. Confirm required-field and weight validation. | `customer_app/lib/features/shipment/create_shipment_screen.dart` |
| Shipment Summary | Edit actions, Proceed to Checkout | working - API | None. | `customer_app/lib/features/shipment/shipment_summary_screen.dart` |
| Checkout/Payment | Coupon, payment selector, terms checkbox, Pay Now | working - API | None. Coupon should show clear feedback if no backend discount is available. | `customer_app/lib/features/payment/payment_screen.dart` |
| Payment Modals | Processing, success, failure actions | working | None. | `customer_app/lib/features/payment/payment_screen.dart` |
| Mock Payment | Payment confirmation | local/mock by design | Replace with real gateway only when gateway integration is requested. | `customer_app/lib/features/payment/payment_screen.dart` |
| Order Confirmation | Invoice, Track Shipment, Home | working | None. | `customer_app/lib/features/payment/order_confirmation_screen.dart` |
| Invoice Preview | Download PDF, share placeholder | working - API / fallback | Download is API-backed. Share depends on platform configuration and must show feedback if unavailable. | `customer_app/lib/features/invoice/invoice_screen.dart` |
| Tracking | Details, support, timeline preview, call driver | working - API / fallback | Call driver is fallback unless phone integration is configured. | `customer_app/lib/features/tracking/tracking_screen.dart` |
| Timeline | Full timeline route | working - API | None. | `customer_app/lib/features/tracking/timeline_screen.dart` |
| Shipment History | Search, filters, clear, load more, card tap | working - API | None. | `customer_app/lib/features/shipment/shipment_history_screen.dart` |
| Shipment Details | Invoice, proof, tracking, support | working - API | None. | `customer_app/lib/features/shipment/shipment_details_screen.dart` |
| Proof View | Proof card, full screen, download/view action | working - API / fallback | Confirm files open from backend metadata. Platform download/share can be fallback locally. | `customer_app/lib/features/shipment/shipment_proof_screen.dart`, `customer_app/lib/features/shipment/shipment_proof_viewer_screen.dart` |
| Profile | Edit profile, change password, notifications, logout | working - API | None. | `customer_app/lib/features/profile/profile_screen.dart` |
| Edit Profile | Save profile | working - API | None. Confirm saved fields persist after relaunch. | `customer_app/lib/features/profile/edit_profile_screen.dart` |
| Change Password | Save password | working - API | None. | `customer_app/lib/features/profile/change_password_screen.dart` |
| Notifications | Mark read, read all, clear, retry | working - API | None. | `customer_app/lib/features/notifications/notifications_screen.dart` |
| Support | Shipment selector, issue type, priority, attachment placeholder, submit, FAQ | working - API / fallback | Attachment upload may remain a placeholder unless support file upload is enabled. | `customer_app/lib/features/support/support_screen.dart` |
| Feedback | Shipment selector, rating, tags, recommend checkbox, submit | working - API | None. | `customer_app/lib/features/support/feedback_screen.dart` |

## Driver App Buttons/Screens

| Screen name | Button/action name | Current status | Required fix | File path |
| --- | --- | --- | --- | --- |
| Splash/Login | Auto route, username, password, show/hide, forgot password, login | working - API / fallback | Forgot password should show a clear admin-contact fallback if no driver reset flow is exposed in UI. | `driver_app/lib/features/auth/splash_screen.dart`, `driver_app/lib/features/auth/auth_screen.dart` |
| Dashboard | Availability toggle, assigned trips, active trip, route summary, emergency | working - API | None. Confirm availability is blocked when active trip exists. | `driver_app/lib/features/dashboard/dashboard_screen.dart` |
| Bottom Navigation | Dashboard, Trips, History, Profile | working | None. | `driver_app/lib/core/widgets/driver_bottom_navigation.dart` |
| Assigned Trips | Filters, card tap, accept/reject/start/update CTAs | working - API | None. | `driver_app/lib/features/trips/trips_screen.dart` |
| Trip Details | Accept confirmation, reject reason sheet, start/update/proof actions | working - API | None. | `driver_app/lib/features/trips/trip_details_screen.dart` |
| Accept/Reject | Accept, required reject reason, notes | working - API | None. Confirm invalid status returns visible error. | `driver_app/lib/features/trips/trip_details_screen.dart` |
| Start Trip | Checklist, map placeholder, confirmation | working - API | None. Map remains visual placeholder locally. | `driver_app/lib/features/trips/start_trip_screen.dart` |
| Pickup Proof Upload | Select photo, notes, checklist, submit | working - API | None. Confirm submit disabled until proof selected. | `driver_app/lib/features/proof_upload/proof_upload_screen.dart` |
| In Transit | ETA field, status buttons, delayed/report issue, timeline | working - API | None. | `driver_app/lib/features/trips/in_transit_update_screen.dart` |
| Delivery Proof Upload | Select photo, receiver fields, OTP/signature placeholder, notes, submit | working - API / fallback | OTP/signature capture is a placeholder unless platform capture is configured. | `driver_app/lib/features/proof_upload/delivery_proof_screen.dart` |
| Complete Trip | Proof cards, checklist, end trip, success state | working - API | None. | `driver_app/lib/features/trips/complete_trip_screen.dart` |
| Trip History | Search, filters, details link | working - API | None. | `driver_app/lib/features/history/history_screen.dart` |
| Emergency Report | Type, trip selector, description, location, attachment, urgent submit | working - API / fallback | Attachment may be local placeholder if file upload is not selected. | `driver_app/lib/features/emergency/emergency_screen.dart` |
| Breakdown Report | Vehicle, issue, severity, attachment, assistance submit | working - API / fallback | Attachment may be local placeholder if file upload is not selected. | `driver_app/lib/features/emergency/breakdown_report_screen.dart` |
| Fuel Request | Trip selector, fuel amount, bill upload, submit, request status | working - API | None. Confirm bill upload uses `bill` field. | `driver_app/lib/features/fuel/fuel_screen.dart` |
| Profile | Availability, change password, logout | working - API | None. | `driver_app/lib/features/profile/profile_screen.dart` |
| Change Password | Save password | working - API | None. | `driver_app/lib/features/profile/change_password_screen.dart` |

## Admin Panel Buttons/Screens

| Screen name | Button/action name | Current status | Required fix | File path |
| --- | --- | --- | --- | --- |
| Login | Email/username, password, remember me, show/hide, forgot password, login | working - API / fallback | Forgot password can remain clear fallback unless admin reset UI is required. | `admin_panel/lib/features/auth/auth_screen.dart` |
| Admin Shell | Sidebar items, mobile drawer, topbar notifications, profile avatar | working | None. | `admin_panel/lib/layout/admin_shell.dart` |
| Notifications | Notification center actions | working - API | None if admin notification API is enabled; otherwise show empty state. | `admin_panel/lib/features/notifications/admin_notifications_screen.dart` |
| Dashboard | Metric card navigation, charts, recent activity | working - API | None. | `admin_panel/lib/features/dashboard/dashboard_screen.dart` |
| Shipment List | Search, filters, pagination, row select, view, approve, cancel, assign | working - API | None. Bulk actions should show fallback unless specific bulk API is enabled. | `admin_panel/lib/features/shipments/shipments_screen.dart` |
| Shipment Details | Back, approve, reject/cancel, assign/reassign, invoice/proof actions | working - API | None. | `admin_panel/lib/features/shipments/shipment_details_screen.dart` |
| Approval/Rejection Dialogs | Notes, required reason, submit/cancel | working - API | None. | `admin_panel/lib/features/shipments/shipments_screen.dart`, `admin_panel/lib/features/shipments/shipment_details_screen.dart` |
| Driver Assignment | Shipment selector, driver list, vehicle list, conflict validation, confirm | working - API | None. | `admin_panel/lib/features/shipments/shipment_assignment_screen.dart` |
| Driver List | Search, filters, view, edit, activate/deactivate, create driver | working - API | None. | `admin_panel/lib/features/drivers/drivers_screen.dart` |
| Add/Edit Driver | Form fields, generated password, date picker, submit/cancel | working - API | None. | `admin_panel/lib/features/drivers/driver_form_screen.dart`, `admin_panel/lib/features/drivers/widgets/driver_form_dialog.dart` |
| Vehicle List | Search, filters, view, edit, activate/deactivate, assignment shortcut | working - API | None. Assignment shortcut should route to assignment flow or show clear context message. | `admin_panel/lib/features/vehicles/vehicles_screen.dart` |
| Add/Edit Vehicle | Form fields, date pickers, dropdowns, submit/cancel | working - API | None. | `admin_panel/lib/features/vehicles/vehicle_form_screen.dart`, `admin_panel/lib/features/vehicles/widgets/vehicle_form_dialog.dart` |
| Customer Management | Search/filter, view details, activate/deactivate | working - API | None. | `admin_panel/lib/features/customers/customers_screen.dart` |
| Payment Management | Search/filter, view details | working - API | None. Refund/retry actions should show fallback unless a mutation endpoint is enabled. | `admin_panel/lib/features/payments/payments_screen.dart` |
| Invoice Management | Search/filter, preview, download | working - API | None. | `admin_panel/lib/features/invoices/invoices_screen.dart` |
| Reports Dashboard | Date/status filters, cards, export CSV/PDF | working - API | None. | `admin_panel/lib/features/reports/reports_screen.dart` |
| Shipment Reports | Filters, export CSV/PDF | working - API | None. | `admin_panel/lib/features/reports/shipment_reports_screen.dart` |
| Driver Reports | Filters, export CSV/PDF | working - API | None. | `admin_panel/lib/features/reports/driver_reports_screen.dart` |
| Vehicle Reports | Filters, export CSV/PDF | working - API | None. | `admin_panel/lib/features/reports/vehicle_reports_screen.dart` |
| Payment Reports | Filters, export CSV/PDF | working - API | None. | `admin_panel/lib/features/reports/payment_reports_screen.dart` |
| Settings | Status master, notification settings, app settings, business rules, save/reset | working - API | None. Confirm saved settings persist after refresh. | `admin_panel/lib/features/settings/settings_screen.dart` |
| Admin Profile | Change password, activity summary, logout | working - API | None. | `admin_panel/lib/features/profile/profile_screen.dart` |

## Missing Screens

No missing registered screens are currently known.

Required screen coverage:

- Customer: Splash, Onboarding, Login, Register, OTP Verification, Forgot Password, Create New Password, Home, Category Selection, Create Shipment, Shipment Summary, Checkout, Payment, Order Confirmation, Invoice Preview, Shipment Tracking, Timeline, Shipment History, Shipment Details, Proof View, Profile, Edit Profile, Change Password, Notifications, Support, Feedback.
- Driver: Splash/Login, Dashboard, Assigned Trips, Trip Details, Accept/Reject Trip, Start Trip, Pickup Proof Upload, In Transit, Delivery Proof Upload, Complete Trip, Trip History, Emergency Report, Breakdown Report, Fuel Request, Profile, Change Password.
- Admin: Login, Dashboard, Shipment List, Shipment Details, Approval/Rejection Dialogs, Driver Assignment, Driver List, Add/Edit Driver, Vehicle List, Add/Edit Vehicle, Customer Management, Payment Management, Invoice Management, Reports Dashboard, Shipment Reports, Driver Reports, Vehicle Reports, Payment Reports, Settings, Admin Profile.

## Local Mock Or Fallback Actions

These are acceptable for local development because they depend on external services:

| Area | Action | Local behavior |
| --- | --- | --- |
| Customer payment | Real payment gateway | Uses mock payment endpoint and creates real payment/invoice records. |
| Customer/Driver tracking | Live map route and turn-by-turn map | Shows app map/route UI placeholder unless map services are configured. |
| Customer tracking | Call driver | Shows fallback if phone calling is not configured. |
| Notifications | Push notification delivery | Database notifications are available; push delivery requires external setup. |
| Auth OTP | Production email/SMS | Uses SMTP if configured or console fallback locally. |
| Sharing | Native share sheet | May show fallback depending on platform integration. |
| Admin payments | Refund/retry/reconcile | Should show fallback unless separate payment mutation APIs are added. |

## Manual Button Audit Steps

1. Start backend and all apps.
2. Log in as each role using seed credentials.
3. Open every sidebar, bottom-nav, topbar, table, card, dialog, and form screen.
4. Click every visible action once.
5. For submit buttons, test invalid input first and confirm validation appears.
6. For API actions, confirm loading and success/error feedback appears.
7. Refresh or reopen the screen after mutations and confirm data comes from the backend.
8. Stop the backend and confirm app error states are readable.
9. Restore backend and confirm retry/reload works where offered.

