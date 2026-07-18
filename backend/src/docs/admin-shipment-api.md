# Admin Shipment APIs

All routes require an admin JWT. Mutating routes enforce status flow and write
an `audit_logs` row in the same transaction.

## Status Flow Rules

- Approve: `pending` -> `approved`; shipment must be `paid`.
- Reject: only `pending` -> `rejected`; reason is required.
- Cancel: allowed before terminal states; terminal states are `delivered`,
  `completed`, `cancelled`, and `rejected`.
- Reassign: allowed only while `approved`, `assigned`, or `accepted`; creates a
  new `assigned` assignment, cancels active previous assignments, marks driver
  `busy`, vehicle `assigned`, and sets shipment status to `assigned`.

## GET `/api/v1/admin/shipments`

Lists shipments with pagination and filters.

Query params:

```txt
page=1
limit=10
search=SHP
status=pending
paymentStatus=paid
categoryId=1
customerId=1
assignedDriverId=1
dateFrom=2026-04-01
dateTo=2026-04-30
```

## GET `/api/v1/admin/shipments/:shipmentId`

Returns shipment details, customer info, payment, invoice, assignments, proofs,
and trip logs.

## PATCH `/api/v1/admin/shipments/:shipmentId/approve`

Sample request:

```json
{
  "notes": "Payment verified and shipment is ready for assignment."
}
```

Sample response:

```json
{
  "success": true,
  "message": "Shipment approved successfully.",
  "data": {
    "shipment": {
      "id": 1,
      "shipmentCode": "SHP-20260430-1234567890",
      "shipmentStatus": "approved",
      "paymentStatus": "paid"
    },
    "message": "Shipment approved successfully."
  }
}
```

## PATCH `/api/v1/admin/shipments/:shipmentId/reject`

Sample request:

```json
{
  "reason": "Pickup location is outside current service area."
}
```

## PATCH `/api/v1/admin/shipments/:shipmentId/cancel`

Sample request:

```json
{
  "reason": "Customer requested cancellation before dispatch."
}
```

## PATCH `/api/v1/admin/shipments/:shipmentId/reassign`

Sample request:

```json
{
  "driverId": 1,
  "vehicleId": 2,
  "notes": "Assigning nearest available driver."
}
```

Sample response:

```json
{
  "success": true,
  "message": "Shipment reassigned successfully.",
  "data": {
    "shipment": {
      "id": 1,
      "shipmentStatus": "assigned"
    },
    "assignment": {
      "assignmentCode": "ASN-20260430-1234567890",
      "assignmentStatus": "assigned",
      "driverId": 1,
      "vehicleId": 2
    }
  }
}
```

## Audit Logs

Each approve, reject, cancel, and reassign action writes:

```txt
entity_type = shipment
entity_id = shipment id
action = shipment.approved | shipment.rejected | shipment.cancelled | shipment.assigned | shipment.reassigned
old_values = previous status/assignment state
new_values = new status/assignment state
```
