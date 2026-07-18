# Customer Shipment APIs

These endpoints support the customer create-shipment flow using the mobile UI
fields. All routes require a customer JWT.

## POST `/api/v1/customer/shipments/estimate`

Sample request:

```json
{
  "categoryId": 1,
  "packageWeightKg": 24.5,
  "estimatedDistanceKm": 18,
  "isFragile": true
}
```

## POST `/api/v1/customer/shipments`

Creates a pending unpaid shipment request.

Sample request:

```json
{
  "categoryId": 1,
  "pickupAddress": "Bandra Kurla Complex, Mumbai",
  "deliveryAddress": "Lower Parel, Mumbai",
  "packageType": "Electronics",
  "packageWeightKg": 24.5,
  "dimensions": {
    "lengthCm": 40,
    "widthCm": 30,
    "heightCm": 25
  },
  "vehiclePreference": "mini_truck",
  "pickupDateTime": "2026-05-02T10:30:00.000Z",
  "receiverName": "Meera Joshi",
  "receiverPhone": "+919811110001",
  "deliveryNotes": "Call receiver before arrival.",
  "isFragile": true,
  "estimatedDistanceKm": 18
}
```

## GET `/api/v1/customer/shipments/:shipmentId/summary`

Returns pickup, delivery, package, receiver, status, payment, and price summary
for a customer-owned shipment.

## POST `/api/v1/customer/shipments/:shipmentId/place-order`

Creates a mock paid payment, generates an invoice record, and leaves the
shipment `pending` for admin approval.

Sample request:

```json
{
  "paymentMethod": "upi",
  "acceptTerms": true
}
```

Sample response:

```json
{
  "success": true,
  "message": "Shipment order placed successfully.",
  "data": {
    "bookingId": "SHP-20260502-1234567890",
    "status": "pending",
    "message": "Mock payment captured and invoice generated.",
    "invoice": {
      "invoiceNumber": "INV-20260502-1234567890",
      "downloadUrl": "/api/v1/customer/invoices/1/download"
    }
  }
}
```
