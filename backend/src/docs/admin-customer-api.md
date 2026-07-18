# Admin Customer APIs

All routes require an admin JWT. These endpoints power the admin customer
management list, detail drawer/modal, and activate/deactivate actions.

## GET `/api/v1/admin/customers`

Lists customers with pagination and filters.

Query params:

```txt
page=1
limit=10
search=aarav
accountStatus=active
userStatus=active
city=Mumbai
state=Maharashtra
dateFrom=2026-04-01
dateTo=2026-04-30
```

Sample response:

```json
{
  "success": true,
  "message": "Admin customers fetched successfully.",
  "data": {
    "customers": [
      {
        "id": 1,
        "customerCode": "CUS-20260430-001",
        "name": "Aarav Mehta",
        "email": "aarav@example.com",
        "phone": "+919811110001",
        "accountStatus": "active",
        "userStatus": "active",
        "shipmentCount": 8,
        "totalPaidAmount": 24500,
        "registeredAt": "2026-04-30T10:00:00.000Z"
      }
    ],
    "meta": {
      "total": 1,
      "page": 1,
      "limit": 10,
      "totalPages": 1,
      "hasMore": false
    }
  }
}
```

## GET `/api/v1/admin/customers/:customerId`

Returns profile details, account status, shipment metrics, payment total, and
the five most recent shipments.

## PATCH `/api/v1/admin/customers/:customerId/activate`

Sets `customers.account_status` and `users.status` to `active`.

Sample response:

```json
{
  "success": true,
  "message": "Customer activated successfully.",
  "data": {
    "status": "active",
    "message": "Customer account activated successfully."
  }
}
```

## PATCH `/api/v1/admin/customers/:customerId/deactivate`

Sets `customers.account_status` and `users.status` to `inactive`.

Sample request:

```json
{
  "reason": "Customer requested temporary account hold."
}
```

Sample response:

```json
{
  "success": true,
  "message": "Customer deactivated successfully.",
  "data": {
    "status": "inactive",
    "message": "Customer account deactivated successfully."
  }
}
```
