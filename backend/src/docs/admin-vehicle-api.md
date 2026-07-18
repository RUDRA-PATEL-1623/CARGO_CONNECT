# Admin Vehicle APIs

All routes require an admin JWT. These endpoints power the admin vehicle
management list, detail drawer/modal, and activate/deactivate actions.

## GET `/api/v1/admin/vehicles`

Lists vehicles with pagination and filters.

Query params:

```txt
page=1
limit=10
search=MH12
vehicleType=mini_truck
fuelType=diesel
availabilityStatus=available
assignedDriverId=1
insuranceExpiryFrom=2026-05-01
insuranceExpiryTo=2028-12-31
serviceDueFrom=2026-05-01
serviceDueTo=2026-12-31
```

## POST `/api/v1/admin/vehicles`

Creates a vehicle. `vehicleNumber` is optional; if omitted, the API generates
one from the registration number.

Sample request:

```json
{
  "registrationNumber": "MH12AB1234",
  "vehicleType": "mini_truck",
  "model": "Tata Ace Gold",
  "capacityKg": 750,
  "fuelType": "diesel",
  "insuranceExpiryDate": "2027-04-30",
  "serviceDueDate": "2026-08-15",
  "availabilityStatus": "available",
  "assignedDriverId": 1,
  "notes": "Primary city parcel vehicle."
}
```

Sample response:

```json
{
  "success": true,
  "message": "Vehicle created successfully.",
  "data": {
    "vehicle": {
      "id": 4,
      "vehicleNumber": "CC-MH12AB1234",
      "registrationNumber": "MH12AB1234",
      "vehicleType": "mini_truck",
      "capacityKg": 750,
      "fuelType": "diesel",
      "insuranceExpiryDate": "2027-04-30T00:00:00.000Z",
      "serviceDueDate": "2026-08-15T00:00:00.000Z",
      "availabilityStatus": "available"
    }
  }
}
```

## GET `/api/v1/admin/vehicles/:vehicleId`

Returns vehicle details, assigned driver summary, assignment counts, and recent
assignments.

## PATCH `/api/v1/admin/vehicles/:vehicleId`

Updates vehicle registration, capacity, type, fuel, insurance expiry, service
due, availability, assigned driver, model, and notes.

## PATCH `/api/v1/admin/vehicles/:vehicleId/activate`

Activates a vehicle for dispatch. If the vehicle still has an assigned driver,
availability becomes `assigned`; otherwise it becomes `available`.

## PATCH `/api/v1/admin/vehicles/:vehicleId/deactivate`

Sets availability to `inactive` and clears the assigned driver.
