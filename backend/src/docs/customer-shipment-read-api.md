# Customer Shipment Read APIs

All routes require a customer JWT. Shipment APIs resolve the active customer
profile from the token and only return shipments owned by that customer.

## GET `/api/v1/customer/shipments`

Lists shipment history with pagination, search, and filters.

Query params:

```txt
page=1
limit=10
search=SHP
status=in_transit
paymentStatus=paid
categoryId=1
categoryCode=small_parcel
dateFrom=2026-05-01
dateTo=2026-05-31
```

Sample response:

```json
{
  "success": true,
  "message": "Customer shipment history fetched successfully.",
  "data": {
    "shipments": [
      {
        "id": 1,
        "shipmentCode": "SHP-20260430-1234567890",
        "categoryName": "Small Parcel",
        "pickupAddress": "Bandra Kurla Complex, Mumbai",
        "deliveryAddress": "Lower Parel, Mumbai",
        "shipmentStatus": "in_transit",
        "paymentStatus": "paid",
        "estimatedPrice": 678.5
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

## GET `/api/v1/customer/shipments/:shipmentId`

Returns full shipment details, latest payment, invoice link, assignment
summary, proof uploads, and a timeline preview.

## GET `/api/v1/customer/shipments/:shipmentId/timeline`

Returns the full status flow:

```txt
Pending -> Approved -> Assigned -> Accepted -> Pickup Completed -> In Transit -> Delivered -> Completed
```

Each step includes `completed`, `current`, or `pending` state and timestamps
from shipment, assignment, or trip log data.

## GET `/api/v1/customer/shipments/:shipmentId/tracking`

Returns map placeholder data, current status, masked driver details, vehicle
details, ETA, route summary, support action metadata, and timeline preview.

## GET `/api/v1/customer/shipments/:shipmentId/proofs`

Lists customer-visible proof uploads. Optional query:

```txt
proofType=pickup
```

## GET `/api/v1/customer/shipments/:shipmentId/proofs/:proofId`

Returns one proof upload for a customer-owned shipment, including file URL,
driver uploader, timestamp, location, verification status, and placeholder
download/full-screen actions.

## Ownership

Every endpoint first resolves `customers.user_id` from the JWT and filters by
`shipments.customer_id`. A customer receives `404` for shipments/proofs outside
their account.
