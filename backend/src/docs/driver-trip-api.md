# Driver Trip API

Driver trip APIs are protected with JWT auth and the `driver` role. A driver can only read or mutate assignments linked to their own driver profile.

## Status Rules

- Accept is allowed only when `assignment_status = assigned` and `shipment_status = assigned`.
- Reject is allowed only when `assignment_status = assigned` and `shipment_status = assigned`.
- Accept changes the assignment to `accepted`, the shipment to `accepted`, creates an `accepted` trip log, and writes an audit log.
- Reject changes the assignment to `rejected`, returns the shipment to `approved` for dispatch reassignment, creates a `rejected` trip log, releases driver/vehicle availability when no other active assignments remain, and writes an audit log.
- Progress updates must move one step at a time: `accepted -> started -> pickup_completed -> in_transit -> delivered -> completed`.
- Every progress update creates a `trip_logs` row and audit log.
- `started` is an assignment/trip-log state. Shipments stay `accepted` while the trip is started because shipment statuses do not include a separate `started` state.
- Pickup proof is required before `pickup_completed -> in_transit`.
- Delivery proof is required before `in_transit -> delivered` and also checked before `delivered -> completed`.
- Proof files are uploaded with `multipart/form-data` field name `proof` and stored in `proof_uploads`.
- ETA, delay, and issue updates while already `in_transit` create timeline logs without changing shipment status.

## Endpoints

### GET `/api/v1/driver/profile`

Fetch the authenticated driver's profile and active assignment count.

### PATCH `/api/v1/driver/availability`

Update driver availability when the driver has no active assignments.

Sample request:

```json
{
  "availabilityStatus": "available"
}
```

Allowed values: `available`, `offline`, `on_leave`. The system owns the `busy` state while an assignment is active.

### POST `/api/v1/driver/logout`

Stateless logout acknowledgement. The client should discard the JWT.

### GET `/api/v1/driver/trips`

List trips assigned to the authenticated driver.

Query parameters:

- `page` optional positive integer, default `1`
- `limit` optional integer from `1` to `50`, default `10`
- `search` optional text, matches assignment/shipment/address/receiver/package
- `group` optional: `new`, `accepted`, `in_progress`, `completed`, `rejected`, `history`
- `status` optional assignment status
- `shipmentStatus` optional shipment status
- `dateFrom` / `dateTo` optional ISO dates filtered by scheduled pickup date

Sample response:

```json
{
  "success": true,
  "message": "Driver assigned trips fetched successfully.",
  "data": {
    "driver": {
      "id": 1,
      "driverCode": "DRV-0001",
      "availabilityStatus": "busy"
    },
    "trips": [
      {
        "id": 7,
        "assignmentCode": "ASN-20260430-1234560001",
        "assignmentStatus": "assigned",
        "shipment": {
          "id": 15,
          "shipmentCode": "SHP-20260430-0001",
          "shipmentStatus": "assigned"
        },
        "customer": {
          "name": "Aarav Mehta",
          "phoneMasked": "******7890"
        },
        "receiver": {
          "name": "Priya Shah",
          "phone": "+919876543210"
        },
        "actions": {
          "canAccept": true,
          "canReject": true
        }
      }
    ],
    "meta": {
      "total": 1,
      "page": 1,
      "limit": 10,
      "totalPages": 1,
      "hasMore": false
    },
    "emptyState": null
  },
  "timestamp": "2026-04-30T10:00:00.000Z"
}
```

### GET `/api/v1/driver/trips/history`

List completed, rejected, and cancelled driver-owned trips. Supports the same query parameters as `/driver/trips`.

### GET `/api/v1/driver/trips/:assignmentId`

Fetch one driver-owned assignment with shipment, receiver, package, vehicle, timeline, and proof placeholders.

### POST `/api/v1/driver/trips/:assignmentId/proofs/pickup`

Upload pickup proof for a driver-owned trip. Allowed when the assignment is `started` or `pickup_completed`.

Multipart form fields:

- `proof` required image file, JPG/PNG/WEBP
- `notes` optional
- `locationText` optional
- `latitude` and `longitude` optional pair
- `capturedAt` optional ISO date

Sample response:

```json
{
  "success": true,
  "message": "Pickup proof uploaded successfully.",
  "data": {
    "proof": {
      "id": 21,
      "proofCode": "PRF-20260430-1234560001",
      "proofType": "pickup",
      "fileUrl": "/uploads/proofs/pickup-1714460000000-123456789.jpg",
      "fileName": "pickup.jpg",
      "fileMimeType": "image/jpeg",
      "fileSizeBytes": 184220,
      "verificationStatus": "pending"
    }
  },
  "timestamp": "2026-04-30T10:00:00.000Z"
}
```

### POST `/api/v1/driver/trips/:assignmentId/proofs/delivery`

Upload delivery proof for a driver-owned trip. Allowed when the assignment is `in_transit` or `delivered`.

### PATCH `/api/v1/driver/trips/:assignmentId/accept`

Accept a newly assigned trip.

Sample response:

```json
{
  "success": true,
  "message": "Trip accepted successfully.",
  "data": {
    "trip": {
      "id": 7,
      "assignmentCode": "ASN-20260430-1234560001",
      "assignmentStatus": "accepted",
      "shipment": {
        "id": 15,
        "shipmentCode": "SHP-20260430-0001",
        "shipmentStatus": "accepted"
      },
      "actions": {
        "canAccept": false,
        "canReject": false
      }
    },
    "message": "Trip accepted successfully."
  },
  "timestamp": "2026-04-30T10:00:00.000Z"
}
```

Conflict response if the trip is no longer newly assigned:

```json
{
  "success": false,
  "message": "Only newly assigned trips can be accepted or rejected",
  "errors": {
    "assignmentStatus": "accepted"
  },
  "timestamp": "2026-04-30T10:00:00.000Z"
}
```

### PATCH `/api/v1/driver/trips/:assignmentId/reject`

Reject a newly assigned trip with a required reason.

Sample request:

```json
{
  "reason": "Vehicle unavailable for this pickup window"
}
```

Sample response:

```json
{
  "success": true,
  "message": "Trip rejected successfully.",
  "data": {
    "trip": {
      "id": 7,
      "assignmentStatus": "rejected",
      "rejectionReason": "Vehicle unavailable for this pickup window",
      "shipment": {
        "id": 15,
        "shipmentStatus": "approved"
      }
    },
    "message": "Trip rejected successfully and returned to dispatch queue."
  },
  "timestamp": "2026-04-30T10:00:00.000Z"
}
```

### PATCH `/api/v1/driver/trips/:assignmentId/start`

Start an accepted trip. Requires `assignment_status = accepted` and `shipment_status = accepted`.

### PATCH `/api/v1/driver/trips/:assignmentId/pickup-completed`

Mark pickup complete. Requires `assignment_status = started` and `shipment_status = accepted`.

### PATCH `/api/v1/driver/trips/:assignmentId/in-transit`

Mark shipment in transit. Requires `assignment_status = pickup_completed`, `shipment_status = pickup_completed`, and an uploaded pickup proof.

If the trip is already `in_transit`, this endpoint records a safe in-transit update instead of failing. This keeps mobile ETA updates compatible while still preventing status skipping.

### PATCH `/api/v1/driver/trips/:assignmentId/status-update`

Record an in-transit ETA, delay, or issue update without changing assignment/shipment status.

Sample request:

```json
{
  "status": "delayed",
  "delayReason": "Traffic hold near toll gate",
  "notes": "ETA revised after route congestion.",
  "etaMinutes": 55,
  "locationText": "Eastern Express Highway"
}
```

Allowed `status` values: `in_transit`, `delayed`, `issue_reported`.

### PATCH `/api/v1/driver/trips/:assignmentId/delivery-completed`

Mark delivery complete. Requires `assignment_status = in_transit` and `shipment_status = in_transit`.

### PATCH `/api/v1/driver/trips/:assignmentId/complete`

Complete a delivered trip. Requires `assignment_status = delivered` and `shipment_status = delivered`. This marks the shipment complete, increments the driver completed-trip counter, and releases driver/vehicle availability when no other active assignments remain.

Progress update request body, all fields optional:

```json
{
  "notes": "Leaving pickup dock after package handover.",
  "locationText": "BKC Gate 3, Mumbai",
  "latitude": 19.0671,
  "longitude": 72.8679,
  "etaMinutes": 45
}
```

Sample progress response:

```json
{
  "success": true,
  "message": "Trip marked in transit successfully.",
  "data": {
    "trip": {
      "id": 7,
      "assignmentCode": "ASN-20260430-1234560001",
      "assignmentStatus": "in_transit",
      "shipment": {
        "id": 15,
        "shipmentCode": "SHP-20260430-0001",
        "shipmentStatus": "in_transit"
      },
      "actions": {
        "canMarkDeliveryCompleted": true,
        "canComplete": false
      }
    },
    "tripLog": {
      "id": 44
    },
    "message": "Trip marked in transit successfully."
  },
  "timestamp": "2026-04-30T10:00:00.000Z"
}
```

Skip response example:

```json
{
  "success": false,
  "message": "Trip must be pickup_completed before it can move to in_transit",
  "errors": {
    "currentAssignmentStatus": "accepted",
    "requiredAssignmentStatus": "pickup_completed",
    "nextAssignmentStatus": "in_transit"
  },
  "timestamp": "2026-04-30T10:00:00.000Z"
}
```

Missing proof response example:

```json
{
  "success": false,
  "message": "pickup proof is required before moving trip to the next status",
  "errors": {
    "requiredProofType": "pickup",
    "uploadEndpoint": "/api/v1/driver/trips/7/proofs/pickup"
  },
  "timestamp": "2026-04-30T10:00:00.000Z"
}
```

## Postman Flow

1. Login as a driver with `POST /api/v1/auth/driver/login`.
2. Save `data.auth.token` as `driverToken`.
3. Add header `Authorization: Bearer {{driverToken}}`.
4. Fetch profile with `GET /api/v1/driver/profile`.
5. List assignments with `GET /api/v1/driver/trips?group=new`.
6. Copy a returned `id` as `assignmentId`.
7. Fetch details with `GET /api/v1/driver/trips/{{assignmentId}}`.
8. Accept with `PATCH /api/v1/driver/trips/{{assignmentId}}/accept`, or reject with `PATCH /api/v1/driver/trips/{{assignmentId}}/reject` and a JSON body containing `reason`.
9. For an accepted trip, call the progress endpoints in order:
   - `PATCH /api/v1/driver/trips/{{assignmentId}}/start`
   - `PATCH /api/v1/driver/trips/{{assignmentId}}/pickup-completed`
   - Upload pickup proof with `POST /api/v1/driver/trips/{{assignmentId}}/proofs/pickup` before in-transit.
   - `PATCH /api/v1/driver/trips/{{assignmentId}}/in-transit`
   - Optional ETA/delay update: `PATCH /api/v1/driver/trips/{{assignmentId}}/status-update`
   - Upload delivery proof with `POST /api/v1/driver/trips/{{assignmentId}}/proofs/delivery` before delivery-completed.
   - `PATCH /api/v1/driver/trips/{{assignmentId}}/delivery-completed`
   - `PATCH /api/v1/driver/trips/{{assignmentId}}/complete`
10. Fetch history with `GET /api/v1/driver/trips/history`.
11. Try skipping a step, for example call `in-transit` immediately after `start`, to verify `409`.
12. Fetch details after each step and confirm `timeline.events` includes the new trip log.
13. Try calling `in-transit` before pickup proof or `delivery-completed` before delivery proof to verify `422`.
14. Try an assignment owned by another driver to verify it returns `404`.
