# Admin Assignment APIs

All routes require an admin JWT. Assignment APIs create and replace shipment
driver/vehicle assignments with conflict validation.

## Rules

- `POST /admin/assignments` only assigns shipments in `approved` status.
- Assignment creation creates a new `assignments` row and updates shipment
  status to `assigned`.
- Driver must be active and available or stale-busy without another active
  assignment.
- Vehicle must not be `maintenance` or `inactive`.
- Active driver or vehicle double-booking is blocked.
- Replacement is allowed only for `assigned` or `accepted` assignments before
  pickup starts. Existing active assignments for the shipment are cancelled and
  a new assignment is created.
- Assignment mutations write `audit_logs` rows.

Active assignment statuses considered for conflicts:

```txt
assigned, accepted, started, pickup_completed, in_transit
```

## POST `/api/v1/admin/assignments/validate-conflicts`

Validates resources without changing data.

Sample request:

```json
{
  "shipmentId": 1,
  "driverId": 2,
  "vehicleId": 3
}
```

Sample response:

```json
{
  "success": true,
  "message": "Assignment resources are available.",
  "data": {
    "canAssign": true,
    "conflicts": [],
    "resources": {
      "shipment": {
        "id": 1,
        "shipmentStatus": "approved"
      },
      "driver": {
        "id": 2,
        "availabilityStatus": "available"
      },
      "vehicle": {
        "id": 3,
        "availabilityStatus": "available"
      }
    }
  }
}
```

## POST `/api/v1/admin/assignments`

Assigns a driver and vehicle to an approved shipment.

Sample request:

```json
{
  "shipmentId": 1,
  "driverId": 2,
  "vehicleId": 3,
  "notes": "Nearest available team assigned."
}
```

Sample response:

```json
{
  "success": true,
  "message": "Shipment assigned successfully.",
  "data": {
    "shipment": {
      "id": 1,
      "shipmentStatus": "assigned"
    },
    "assignment": {
      "assignmentCode": "ASN-20260430-1234567890",
      "assignmentStatus": "assigned",
      "driverId": 2,
      "vehicleId": 3
    }
  }
}
```

## PATCH `/api/v1/admin/assignments/:assignmentId/replace`

Replaces driver and vehicle for an active assignment before pickup starts.

Sample request:

```json
{
  "driverId": 4,
  "vehicleId": 5,
  "notes": "Original driver unavailable before pickup."
}
```

Conflict responses use status `422` with a `conflicts` array that names the
blocked field and the active assignment causing the conflict.
