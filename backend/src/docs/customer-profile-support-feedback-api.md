# Customer Profile, Support, And Feedback APIs

All endpoints require:

```txt
Authorization: Bearer <customerToken>
```

Customers can access only their own profile, shipments, support issues, and feedback.

## GET `/api/v1/customer/profile`

Fetches the authenticated customer's profile.

Sample response:

```json
{
  "success": true,
  "message": "Customer profile fetched successfully.",
  "data": {
    "profile": {
      "customerCode": "CUST-TEST",
      "name": "CargoConnect Customer",
      "email": "customer@cargoconnect.local",
      "phone": "+919900000100",
      "accountStatus": "active",
      "address": {
        "addressLine1": "CargoConnect Test Customer Address",
        "city": "Mumbai",
        "state": "Maharashtra",
        "postalCode": "400001",
        "country": "India"
      }
    }
  }
}
```

## PATCH `/api/v1/customer/profile`

Updates editable customer profile fields. Email is intentionally read-only in this endpoint.

Sample request:

```json
{
  "name": "CargoConnect Customer",
  "phone": "+919900000100",
  "addressLine1": "CargoConnect Test Customer Address",
  "addressLine2": "Local Test Area",
  "city": "Mumbai",
  "state": "Maharashtra",
  "postalCode": "400001",
  "country": "India"
}
```

## GET `/api/v1/customer/support/issues`

Lists support issues created by the authenticated customer.

Supported query parameters:

```txt
page, limit, search, status, priority, issueType, shipmentId
```

## POST `/api/v1/customer/support/issues`

Creates a support issue. `shipmentId` is optional, but if supplied it must belong to the authenticated customer.

Sample request:

```json
{
  "shipmentId": 1,
  "issueType": "delay",
  "priority": "medium",
  "subject": "Need delivery update",
  "description": "Please confirm the latest delivery ETA for this shipment."
}
```

## GET `/api/v1/customer/feedback`

Lists feedback submitted by the authenticated customer.

Supported query parameters:

```txt
page, limit, shipmentId, rating
```

## POST `/api/v1/customer/feedback`

Submits feedback for a customer-owned shipment. One feedback record is allowed per customer shipment.

Sample request:

```json
{
  "shipmentId": 1,
  "rating": 5,
  "experienceTags": ["clear_updates", "professional_driver"],
  "comments": "Smooth booking and delivery experience.",
  "wouldRecommend": true
}
```
