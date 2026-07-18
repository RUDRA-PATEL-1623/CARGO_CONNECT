# CargoConnect Postman Testing Guide

Last updated: 2026-05-19

This guide groups the CargoConnect APIs for Postman testing and gives a full customer, admin, and driver test sequence.

## 1. Prerequisites

Start MySQL and the backend before testing:

```powershell
cd D:\Projects\cargoconnect\backend
npm run dev
```

Health checks:

```txt
GET http://localhost:5000/api/v1/health
GET http://localhost:5000/api/v1/health/db
```

Seeded local credentials:

```txt
Customer: customer@cargoconnect.local / Password123!
Driver: driver@cargoconnect.local / Password123!
Admin: admin@cargoconnect.local / Password123!
Dispatcher: dispatcher@cargoconnect.local / Password123!
```

## 2. Postman Environment Variables

Create a Postman environment named `CargoConnect Local`.

Add these variables:

| Variable | Initial value | Current value |
| --- | --- | --- |
| `baseUrl` | `http://localhost:5000/api/v1` | `http://localhost:5000/api/v1` |
| `customerToken` | empty | empty |
| `adminToken` | empty | empty |
| `driverToken` | empty | empty |
| `shipmentId` | empty | empty |
| `assignmentId` | empty | empty |
| `driverId` | empty | empty |
| `vehicleId` | empty | empty |
| `invoiceId` | empty | empty |
| `proofId` | empty | empty |

Use endpoints with:

```txt
{{baseUrl}}/health
```

## 3. Auth Token Usage

Login responses return the JWT at:

```txt
data.auth.token
```

For protected requests, add this header:

```txt
Authorization: Bearer {{customerToken}}
Authorization: Bearer {{adminToken}}
Authorization: Bearer {{driverToken}}
```

Use the token that matches the route group. Customer tokens cannot call admin or driver routes, and driver tokens cannot access customer-owned shipment routes.

### Save Token Automatically In Postman

In the `Tests` tab of a login request, use one of these snippets.

Customer login:

```javascript
const json = pm.response.json();
pm.environment.set('customerToken', json.data.auth.token);
```

Admin login:

```javascript
const json = pm.response.json();
pm.environment.set('adminToken', json.data.auth.token);
```

Driver login:

```javascript
const json = pm.response.json();
pm.environment.set('driverToken', json.data.auth.token);
```

Save IDs from responses:

```javascript
const json = pm.response.json();
pm.environment.set('shipmentId', json.data.shipment.id);
```

## 4. Endpoint Groups

### Foundation

| Method | Endpoint | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/health` | None | API process health. |
| `GET` | `/health/db` | None | MySQL connection health. |
| `GET` | `/` | None | Route registry. |

### Auth

| Method | Endpoint | Auth | Purpose |
| --- | --- | --- | --- |
| `POST` | `/auth/customer/register` | None | Register customer and send OTP. |
| `POST` | `/auth/customer/verify-otp` | None | Verify registration OTP. |
| `POST` | `/auth/customer/resend-otp` | None | Resend registration OTP. |
| `POST` | `/auth/customer/login` | None | Login verified customer. |
| `POST` | `/auth/driver/login` | None | Login admin-created driver. |
| `POST` | `/auth/admin/login` | None | Login admin or dispatcher. |
| `POST` | `/auth/forgot-password` | None | Request reset OTP. |
| `POST` | `/auth/verify-reset-otp` | None | Verify reset OTP. |
| `POST` | `/auth/create-new-password` | None | Set password using reset token. |
| `POST` | `/auth/reset-password` | None | Reset password directly with reset OTP. |
| `POST` | `/auth/change-password` | Bearer token | Change current user password. |

### Customer

| Method | Endpoint | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/shipment-categories` | Customer | List active shipment categories. |
| `GET` | `/customer/profile` | Customer | Fetch own customer profile. |
| `PATCH` | `/customer/profile` | Customer | Update own editable profile fields. |
| `POST` | `/customer/shipments/estimate` | Customer | Calculate price estimate. |
| `POST` | `/customer/shipments` | Customer | Create pending unpaid shipment. |
| `GET` | `/customer/shipments/:shipmentId/summary` | Customer | Shipment summary. |
| `GET` | `/customer/shipments/:shipmentId/checkout` | Customer | Checkout breakdown. |
| `POST` | `/customer/shipments/:shipmentId/checkout/mock-payment` | Customer | Mock payment and invoice generation. |
| `POST` | `/customer/shipments/:shipmentId/place-order` | Customer | Alternate mock order placement. |
| `GET` | `/customer/shipments` | Customer | Shipment history. |
| `GET` | `/customer/shipments/:shipmentId` | Customer | Shipment details. |
| `GET` | `/customer/shipments/:shipmentId/tracking` | Customer | Tracking summary. |
| `GET` | `/customer/shipments/:shipmentId/timeline` | Customer | Full timeline. |
| `GET` | `/customer/shipments/:shipmentId/proofs` | Customer | Proof list. |
| `GET` | `/customer/shipments/:shipmentId/proofs/:proofId` | Customer | Proof details. |
| `GET` | `/customer/invoices/:invoiceId` | Customer | Invoice preview. |
| `GET` | `/customer/invoices/:invoiceId/download` | Customer | Invoice PDF download. |
| `GET` | `/customer/notifications` | Customer | Notification inbox. |
| `PATCH` | `/customer/notifications/:notificationId/read` | Customer | Mark one notification read. |
| `PATCH` | `/customer/notifications/read-all` | Customer | Mark all notifications read. |
| `DELETE` | `/customer/notifications/clear` | Customer | Clear notifications. |
| `GET` | `/customer/support/issues` | Customer | List own support issues. |
| `POST` | `/customer/support/issues` | Customer | Create support issue. |
| `GET` | `/customer/feedback` | Customer | List own shipment feedback. |
| `POST` | `/customer/feedback` | Customer | Submit shipment feedback. |

### Admin

| Method | Endpoint | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/admin/dashboard/metrics` | Admin | Dashboard metrics. |
| `GET` | `/admin/dashboard/recent-activity` | Admin | Recent activity table. |
| `GET` | `/admin/profile` | Admin | Authenticated admin/dispatcher profile. |
| `POST` | `/admin/logout` | Admin | Token-safe logout response; discard JWT client-side. |
| `GET` | `/admin/shipments` | Admin | Shipment list and filters. |
| `GET` | `/admin/shipments/:shipmentId` | Admin | Shipment details. |
| `PATCH` | `/admin/shipments/:shipmentId/approve` | Admin | Approve paid pending shipment. |
| `PATCH` | `/admin/shipments/:shipmentId/reject` | Admin | Reject pending shipment. |
| `PATCH` | `/admin/shipments/:shipmentId/cancel` | Admin | Cancel non-terminal shipment. |
| `PATCH` | `/admin/shipments/:shipmentId/reassign` | Admin | Assign or reassign via shipment route. |
| `POST` | `/admin/assignments/validate-conflicts` | Admin | Validate driver and vehicle availability. |
| `POST` | `/admin/assignments` | Admin | Assign driver and vehicle. |
| `PATCH` | `/admin/assignments/:assignmentId/replace` | Admin | Replace active assignment resources. |
| `GET` | `/admin/customers` | Admin | Customer list. |
| `GET` | `/admin/customers/:customerId` | Admin | Customer details. |
| `PATCH` | `/admin/customers/:customerId/activate` | Admin | Activate customer. |
| `PATCH` | `/admin/customers/:customerId/deactivate` | Admin | Deactivate customer. |
| `GET` | `/admin/drivers` | Admin | Driver list. |
| `POST` | `/admin/drivers` | Admin | Create driver and login. |
| `GET` | `/admin/drivers/:driverId` | Admin | Driver details. |
| `PATCH` | `/admin/drivers/:driverId` | Admin | Update driver. |
| `PATCH` | `/admin/drivers/:driverId/activate` | Admin | Activate driver. |
| `PATCH` | `/admin/drivers/:driverId/deactivate` | Admin | Deactivate driver. |
| `GET` | `/admin/vehicles` | Admin | Vehicle list. |
| `POST` | `/admin/vehicles` | Admin | Create vehicle. |
| `GET` | `/admin/vehicles/:vehicleId` | Admin | Vehicle details. |
| `PATCH` | `/admin/vehicles/:vehicleId` | Admin | Update vehicle. |
| `PATCH` | `/admin/vehicles/:vehicleId/activate` | Admin | Activate vehicle. |
| `PATCH` | `/admin/vehicles/:vehicleId/deactivate` | Admin | Deactivate vehicle. |
| `GET` | `/admin/payments` | Admin | Payment list with search/status/method/date/category filters. |
| `GET` | `/admin/payments/:paymentId` | Admin | Payment details with shipment, customer, invoice context. |
| `GET` | `/admin/invoices` | Admin | Invoice list with search/status/date/category filters. |
| `GET` | `/admin/invoices/:invoiceId` | Admin | Invoice preview/details. |
| `GET` | `/admin/invoices/:invoiceId/download` | Admin | Download locally generated invoice PDF. |
| `GET` | `/admin/reports/shipments` | Admin | Shipment report. |
| `GET` | `/admin/reports/drivers` | Admin | Driver report. |
| `GET` | `/admin/reports/vehicles` | Admin | Vehicle report. |
| `GET` | `/admin/reports/payments` | Admin | Payment report. |
| `GET` | `/admin/reports/invoices` | Admin | Invoice report. |
| `GET` | `/admin/reports/shipments/export?format=csv|pdf` | Admin | Shipment CSV/PDF export. |
| `GET` | `/admin/reports/drivers/export?format=csv|pdf` | Admin | Driver CSV/PDF export. |
| `GET` | `/admin/reports/vehicles/export?format=csv|pdf` | Admin | Vehicle CSV/PDF export. |
| `GET` | `/admin/reports/payments/export?format=csv|pdf` | Admin | Payment CSV/PDF export. |
| `GET` | `/admin/reports/invoices/export?format=csv|pdf` | Admin | Invoice CSV/PDF export. |
| `GET` | `/admin/settings` | Admin | Get grouped database-backed settings. |
| `PATCH` | `/admin/settings` | Admin | Update settings with audit log. |

### Driver

| Method | Endpoint | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/driver/profile` | Driver | Driver profile and active assignment count. |
| `PATCH` | `/driver/availability` | Driver | Update availability when no active assignment exists. |
| `POST` | `/driver/logout` | Driver | Token-safe logout response; discard JWT client-side. |
| `GET` | `/driver/trips` | Driver | Assigned trips. |
| `GET` | `/driver/trips/history` | Driver | Completed/rejected/cancelled trip history. |
| `GET` | `/driver/trips/:assignmentId` | Driver | Trip details. |
| `PATCH` | `/driver/trips/:assignmentId/accept` | Driver | Accept assigned trip. |
| `PATCH` | `/driver/trips/:assignmentId/reject` | Driver | Reject assigned trip. |
| `PATCH` | `/driver/trips/:assignmentId/start` | Driver | Start accepted trip. |
| `PATCH` | `/driver/trips/:assignmentId/pickup-completed` | Driver | Mark pickup completed. |
| `POST` | `/driver/trips/:assignmentId/proofs/pickup` | Driver | Upload pickup proof. |
| `PATCH` | `/driver/trips/:assignmentId/in-transit` | Driver | Mark in transit. |
| `PATCH` | `/driver/trips/:assignmentId/status-update` | Driver | Record ETA, delay, or issue update while in transit. |
| `POST` | `/driver/trips/:assignmentId/proofs/delivery` | Driver | Upload delivery proof. |
| `PATCH` | `/driver/trips/:assignmentId/delivery-completed` | Driver | Mark delivered. |
| `PATCH` | `/driver/trips/:assignmentId/complete` | Driver | Complete trip. |
| `GET` | `/driver/reports` | Driver | Driver reports list. |
| `POST` | `/driver/reports/emergency` | Driver | Submit emergency report. |
| `POST` | `/driver/reports/breakdown` | Driver | Submit breakdown report. |
| `GET` | `/driver/fuel-requests` | Driver | Fuel requests list. |
| `POST` | `/driver/fuel-requests` | Driver | Create fuel request. |
| `POST` | `/driver/fuel-requests/:fuelRequestId/bill` | Driver | Upload fuel bill. |
| `GET` | `/driver/notifications` | Driver | Notification inbox. |

## 5. Sample End-To-End Test Sequence

This sequence mirrors the main CargoConnect flow:

```txt
customer creates shipment -> customer pays -> admin approves -> admin assigns -> driver accepts/completes -> customer tracks -> admin reports update
```

### Step 1: Customer Login

```http
POST {{baseUrl}}/auth/customer/login
Content-Type: application/json
```

Body:

```json
{
  "identifier": "customer@cargoconnect.local",
  "password": "Password123!"
}
```

Save `data.auth.token` as `customerToken`.

### Step 2: List Categories

Optional profile check:

```http
GET {{baseUrl}}/customer/profile
Authorization: Bearer {{customerToken}}
```

```http
GET {{baseUrl}}/shipment-categories
Authorization: Bearer {{customerToken}}
```

Copy an active category `id`.

### Step 3: Estimate Shipment Price

```http
POST {{baseUrl}}/customer/shipments/estimate
Authorization: Bearer {{customerToken}}
Content-Type: application/json
```

Body:

```json
{
  "categoryId": 1,
  "packageWeightKg": 5,
  "estimatedDistanceKm": 18,
  "isFragile": true
}
```

### Step 4: Create Shipment

```http
POST {{baseUrl}}/customer/shipments
Authorization: Bearer {{customerToken}}
Content-Type: application/json
```

Body:

```json
{
  "categoryId": 1,
  "pickupAddress": "Bandra Kurla Complex, Mumbai",
  "deliveryAddress": "Lower Parel, Mumbai",
  "packageType": "Electronics accessories",
  "packageWeightKg": 5,
  "dimensions": {
    "lengthCm": 30,
    "widthCm": 20,
    "heightCm": 15
  },
  "vehiclePreference": "mini_truck",
  "pickupDateTime": "2026-05-20T10:30:00.000Z",
  "receiverName": "Meera Joshi",
  "receiverPhone": "+919811110001",
  "deliveryNotes": "Call receiver before arrival.",
  "isFragile": true,
  "estimatedDistanceKm": 18
}
```

Save `data.shipment.id` as `shipmentId`.

### Step 5: Checkout And Mock Payment

```http
GET {{baseUrl}}/customer/shipments/{{shipmentId}}/checkout
Authorization: Bearer {{customerToken}}
```

```http
POST {{baseUrl}}/customer/shipments/{{shipmentId}}/checkout/mock-payment
Authorization: Bearer {{customerToken}}
Content-Type: application/json
```

Body:

```json
{
  "paymentMethod": "upi",
  "acceptTerms": true
}
```

Save invoice details if needed.

### Step 6: Admin Login

```http
POST {{baseUrl}}/auth/admin/login
Content-Type: application/json
```

Body:

```json
{
  "identifier": "admin@cargoconnect.local",
  "password": "Password123!"
}
```

Save `data.auth.token` as `adminToken`.

Optional admin profile check:

```http
GET {{baseUrl}}/admin/profile
Authorization: Bearer {{adminToken}}
```

### Step 7: Approve Shipment

```http
PATCH {{baseUrl}}/admin/shipments/{{shipmentId}}/approve
Authorization: Bearer {{adminToken}}
Content-Type: application/json
```

Body:

```json
{
  "notes": "Payment verified and shipment is ready for assignment."
}
```

### Step 8: Select Driver And Vehicle

```http
GET {{baseUrl}}/admin/drivers?availability=available&status=active&limit=20
Authorization: Bearer {{adminToken}}
```

Save an available `driverId`.

```http
GET {{baseUrl}}/admin/vehicles?availability=available&limit=20
Authorization: Bearer {{adminToken}}
```

Save an available `vehicleId`.

### Step 9: Validate And Assign

```http
POST {{baseUrl}}/admin/assignments/validate-conflicts
Authorization: Bearer {{adminToken}}
Content-Type: application/json
```

Body:

```json
{
  "shipmentId": "{{shipmentId}}",
  "driverId": "{{driverId}}",
  "vehicleId": "{{vehicleId}}"
}
```

Assign:

```http
POST {{baseUrl}}/admin/assignments
Authorization: Bearer {{adminToken}}
Content-Type: application/json
```

Body:

```json
{
  "shipmentId": "{{shipmentId}}",
  "driverId": "{{driverId}}",
  "vehicleId": "{{vehicleId}}",
  "notes": "Nearest available driver and vehicle assigned."
}
```

Save `data.assignment.id` as `assignmentId`.

### Step 10: Driver Login

Login with the assigned driver's username. Seeded examples include `driver`, `vikram.driver`, `imran.driver`, and `neha.driver`.

The `driver@cargoconnect.local` account has a pre-seeded assigned test trip. For a new shipment you assigned in Step 9, log in as the exact driver selected during assignment, for example `vikram.driver`.

```http
POST {{baseUrl}}/auth/driver/login
Content-Type: application/json
```

Body:

```json
{
  "identifier": "vikram.driver",
  "password": "Password123!"
}
```

Save `data.auth.token` as `driverToken`.

Driver profile check:

```http
GET {{baseUrl}}/driver/profile
Authorization: Bearer {{driverToken}}
```

### Step 11: Driver Accepts Trip

```http
GET {{baseUrl}}/driver/trips?group=new
Authorization: Bearer {{driverToken}}
```

```http
PATCH {{baseUrl}}/driver/trips/{{assignmentId}}/accept
Authorization: Bearer {{driverToken}}
Content-Type: application/json
```

Body:

```json
{}
```

### Step 12: Driver Progresses Trip

Start:

```http
PATCH {{baseUrl}}/driver/trips/{{assignmentId}}/start
Authorization: Bearer {{driverToken}}
Content-Type: application/json
```

Body:

```json
{
  "notes": "Trip started from pickup location."
}
```

Pickup completed:

```http
PATCH {{baseUrl}}/driver/trips/{{assignmentId}}/pickup-completed
Authorization: Bearer {{driverToken}}
Content-Type: application/json
```

Body:

```json
{
  "notes": "Package collected from pickup point."
}
```

Upload pickup proof:

```http
POST {{baseUrl}}/driver/trips/{{assignmentId}}/proofs/pickup
Authorization: Bearer {{driverToken}}
```

Postman body:

```txt
Body > form-data
proof: File, required
notes: Pickup proof uploaded from Postman
locationText: BKC Gate 3, Mumbai
capturedAt: 2026-05-20T11:00:00.000Z
```

In transit:

```http
PATCH {{baseUrl}}/driver/trips/{{assignmentId}}/in-transit
Authorization: Bearer {{driverToken}}
Content-Type: application/json
```

Body:

```json
{
  "etaMinutes": 35,
  "locationText": "Eastern Express Highway"
}
```

Optional ETA or delay update while already in transit:

```http
PATCH {{baseUrl}}/driver/trips/{{assignmentId}}/status-update
Authorization: Bearer {{driverToken}}
Content-Type: application/json
```

Body:

```json
{
  "status": "delayed",
  "delayReason": "Traffic hold near toll gate",
  "etaMinutes": 55,
  "locationText": "Eastern Express Highway"
}
```

Upload delivery proof:

```http
POST {{baseUrl}}/driver/trips/{{assignmentId}}/proofs/delivery
Authorization: Bearer {{driverToken}}
```

Postman body:

```txt
Body > form-data
proof: File, required
notes: Delivery proof uploaded from Postman
locationText: Lower Parel Dock 2, Mumbai
capturedAt: 2026-05-20T12:15:00.000Z
```

Delivery completed:

```http
PATCH {{baseUrl}}/driver/trips/{{assignmentId}}/delivery-completed
Authorization: Bearer {{driverToken}}
Content-Type: application/json
```

Body:

```json
{
  "notes": "Delivered to receiver."
}
```

Complete trip:

```http
PATCH {{baseUrl}}/driver/trips/{{assignmentId}}/complete
Authorization: Bearer {{driverToken}}
Content-Type: application/json
```

Body:

```json
{
  "notes": "Trip completed successfully."
}
```

Trip history:

```http
GET {{baseUrl}}/driver/trips/history?limit=20
Authorization: Bearer {{driverToken}}
```

Availability update after completion:

```http
PATCH {{baseUrl}}/driver/availability
Authorization: Bearer {{driverToken}}
Content-Type: application/json
```

Body:

```json
{
  "availabilityStatus": "available"
}
```

### Step 13: Customer Tracks Shipment

```http
GET {{baseUrl}}/customer/shipments/{{shipmentId}}/tracking
Authorization: Bearer {{customerToken}}
```

```http
GET {{baseUrl}}/customer/shipments/{{shipmentId}}/timeline
Authorization: Bearer {{customerToken}}
```

```http
GET {{baseUrl}}/customer/shipments/{{shipmentId}}/proofs
Authorization: Bearer {{customerToken}}
```

Expected final status:

```txt
completed
```

Expected proofs:

```txt
pickup and delivery
```

Optional support issue:

```http
POST {{baseUrl}}/customer/support/issues
Authorization: Bearer {{customerToken}}
Content-Type: application/json
```

Body:

```json
{
  "shipmentId": "{{shipmentId}}",
  "issueType": "delay",
  "priority": "medium",
  "subject": "Need delivery update",
  "description": "Please confirm the latest delivery ETA for this shipment."
}
```

Optional feedback:

```http
POST {{baseUrl}}/customer/feedback
Authorization: Bearer {{customerToken}}
Content-Type: application/json
```

Body:

```json
{
  "shipmentId": "{{shipmentId}}",
  "rating": 5,
  "experienceTags": ["clear_updates", "professional_driver"],
  "comments": "Smooth booking and delivery experience.",
  "wouldRecommend": true
}
```

### Step 14: Admin Checks Reports

```http
GET {{baseUrl}}/admin/dashboard/metrics
Authorization: Bearer {{adminToken}}
```

```http
GET {{baseUrl}}/admin/reports/shipments?limit=10
Authorization: Bearer {{adminToken}}
```

```http
GET {{baseUrl}}/admin/reports/payments?limit=10
Authorization: Bearer {{adminToken}}
```

Management list/detail checks:

```http
GET {{baseUrl}}/admin/payments?limit=10&paymentStatus=paid
Authorization: Bearer {{adminToken}}
```

```http
GET {{baseUrl}}/admin/invoices?limit=10&paymentStatus=paid
Authorization: Bearer {{adminToken}}
```

```http
GET {{baseUrl}}/admin/settings
Authorization: Bearer {{adminToken}}
```

```http
PATCH {{baseUrl}}/admin/settings
Authorization: Bearer {{adminToken}}
Content-Type: application/json
```

Body:

```json
{
  "settings": {
    "business_rules": {
      "tax_percent": 18,
      "allow_cash_on_delivery": true
    },
    "notification_settings": {
      "notify_customer_on_status_change": true
    }
  }
}
```

Use Postman's **Send and Download** for exports:

```http
GET {{baseUrl}}/admin/reports/shipments/export?format=csv
Authorization: Bearer {{adminToken}}
```

```http
GET {{baseUrl}}/admin/reports/shipments/export?format=pdf
Authorization: Bearer {{adminToken}}
```

## 6. Common Errors

### `401 Unauthorized`

Cause:

- Missing token
- Expired token
- Header is not using `Bearer`

Fix:

```txt
Authorization: Bearer {{customerToken}}
```

Login again and refresh the environment token.

### `403 Forbidden`

Cause:

- Correct token format, wrong role
- Example: customer token calling `/admin/shipments`

Fix:

- Use `adminToken` for `/admin/*`
- Use `driverToken` for `/driver/*`
- Use `customerToken` for `/customer/*`

### `404 Not Found`

Cause:

- Wrong route path
- Customer is trying to access another customer's shipment
- Driver is trying to access another driver's assignment

Fix:

- Confirm the route path and environment `baseUrl`
- Use IDs returned by your own flow

### `409 Conflict`

Cause:

- Status flow is out of order
- Example: driver calls `in-transit` before `pickup-completed`

Fix:

Follow the order:

```txt
assigned -> accepted -> started -> pickup_completed -> in_transit -> delivered -> completed
```

### `422 Unprocessable Entity`

Cause:

- Validation failed
- Required proof missing
- Driver or vehicle already booked
- Shipment category weight limit exceeded

Examples:

```txt
pickup proof is required before moving trip to the next status
Package weight exceeds Small Parcel limit of 10 kg
Assignment resources are not available
```

Fix:

- Read the `errors` field
- Use valid payload values
- Upload required files using form-data field `proof`
- Select available driver and vehicle

### `500 Internal Server Error`

Cause:

- Backend bug
- Database schema mismatch
- MySQL is not reachable

Fix:

```powershell
cd D:\Projects\cargoconnect\backend
npm run health
```

Check the backend terminal log, confirm migrations are applied, and confirm XAMPP MySQL is running.

### CORS Error In Browser, But Postman Works

Cause:

- Browser origin not listed in `backend\.env`

Fix:

Update:

```env
CORS_ORIGIN=http://localhost:3000,http://localhost:54042,http://localhost:54043
```

Restart backend.

### File Upload Fails

Cause:

- Used raw JSON instead of form-data
- Wrong file field name
- File type or size not allowed

Fix:

- Use `Body > form-data`
- For pickup and delivery proof, field name must be `proof`
- For fuel bill upload, field name must be `bill`
- Allowed proof files: JPG, PNG, WEBP
- Check `MAX_FILE_SIZE_MB` in `backend\.env`

### Assigned Driver Cannot See A Newly Assigned Trip

Cause:

- You logged in as the generic seed driver, but assigned the shipment to a different seeded driver.

Fix:

- In the admin assignment response, note the assigned driver.
- Log in as that driver's username or email with `Password123!`.
- Seeded examples may include `vikram.driver`, `imran.driver`, and `neha.driver`.

## 7. Quick Smoke Checklist

Run these in order:

```txt
GET /health
GET /health/db
POST /auth/customer/login
GET /shipment-categories
POST /customer/shipments
POST /customer/shipments/:shipmentId/checkout/mock-payment
POST /auth/admin/login
PATCH /admin/shipments/:shipmentId/approve
POST /admin/assignments
POST /auth/driver/login
GET /driver/profile
PATCH /driver/trips/:assignmentId/accept
PATCH /driver/trips/:assignmentId/start
PATCH /driver/trips/:assignmentId/pickup-completed
POST /driver/trips/:assignmentId/proofs/pickup
PATCH /driver/trips/:assignmentId/in-transit
PATCH /driver/trips/:assignmentId/status-update
POST /driver/trips/:assignmentId/proofs/delivery
PATCH /driver/trips/:assignmentId/delivery-completed
PATCH /driver/trips/:assignmentId/complete
GET /driver/trips/history
GET /customer/shipments/:shipmentId/tracking
GET /admin/reports/shipments
GET /admin/payments
GET /admin/invoices
GET /admin/settings
```
