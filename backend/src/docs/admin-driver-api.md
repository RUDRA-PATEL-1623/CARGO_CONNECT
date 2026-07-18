# Admin Driver APIs

All routes require an admin JWT. Creating a driver creates both a `users`
record with role `driver` and a linked `drivers` profile in one transaction.

## GET `/api/v1/admin/drivers`

Lists drivers with pagination and filters.

Query params:

```txt
page=1
limit=10
search=vikram
driverStatus=active
availabilityStatus=available
licenseExpiryFrom=2026-05-01
licenseExpiryTo=2028-12-31
city=Mumbai
state=Maharashtra
```

## POST `/api/v1/admin/drivers`

Creates driver login credentials and profile. If `password` is omitted, the API
generates a temporary password and returns it once in the response.

Sample request:

```json
{
  "name": "Rohan Sharma",
  "username": "rohan.driver",
  "email": "rohan.driver@cargoconnect.local",
  "phone": "+919811110010",
  "password": "Driver@12345",
  "licenseNumber": "MH12CC2026100",
  "licenseExpiryDate": "2028-07-15",
  "addressLine1": "Andheri East",
  "city": "Mumbai",
  "state": "Maharashtra",
  "postalCode": "400069",
  "availabilityStatus": "available",
  "driverStatus": "active",
  "emergencyContactName": "Priya Sharma",
  "emergencyContactPhone": "+919811110011"
}
```

Sample response:

```json
{
  "success": true,
  "message": "Driver created successfully.",
  "data": {
    "driver": {
      "id": 4,
      "driverCode": "DRV-0012",
      "name": "Rohan Sharma",
      "username": "rohan.driver",
      "licenseNumber": "MH12CC2026100",
      "availabilityStatus": "available",
      "driverStatus": "active"
    },
    "loginCredentials": {
      "username": "rohan.driver",
      "email": "rohan.driver@cargoconnect.local",
      "generatedPassword": false
    }
  }
}
```

## GET `/api/v1/admin/drivers/:driverId`

Returns driver details, login status, license info, availability, assigned
vehicle placeholder fields, performance summary, and recent assignments.

## PATCH `/api/v1/admin/drivers/:driverId`

Updates driver profile and login fields. Optional fields match the create body.
If `password` is supplied, the driver login password is replaced.

## PATCH `/api/v1/admin/drivers/:driverId/activate`

Sets `drivers.driver_status` to `active`, `users.status` to `active`, and
availability to `available` unless the driver is currently `busy`.

## PATCH `/api/v1/admin/drivers/:driverId/deactivate`

Sets `drivers.driver_status` to `inactive`, `users.status` to `inactive`, and
availability to `offline`.
