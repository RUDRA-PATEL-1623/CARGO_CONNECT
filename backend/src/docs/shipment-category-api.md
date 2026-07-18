# Shipment Category API

Shipment category APIs support admin CRUD and customer-facing active category
lists. Admin routes require a Bearer JWT for an active admin user.

## GET `/api/v1/shipment-categories`

Returns active categories for customer shipment booking.

Required header:

```http
Authorization: Bearer <customer-or-admin-jwt>
```

## GET `/api/v1/admin/shipment-categories`

Returns all admin-visible categories. Query params:

- `includeInactive=true`
- `search=fragile`

## POST `/api/v1/admin/shipment-categories`

Sample request:

```json
{
  "name": "Express Documents",
  "description": "Priority document pickup and delivery.",
  "basePrice": 249,
  "vehicleSuggestion": "bike",
  "iconKey": "file-clock",
  "isActive": true
}
```

Sample response:

```json
{
  "success": true,
  "message": "Shipment category created successfully.",
  "data": {
    "id": 7,
    "code": "express_documents",
    "name": "Express Documents",
    "description": "Priority document pickup and delivery.",
    "vehicleSuggestion": "bike",
    "iconKey": "file-clock",
    "basePrice": 249,
    "isActive": true
  }
}
```

## PATCH `/api/v1/admin/shipment-categories/:categoryId`

Sample request:

```json
{
  "basePrice": 299,
  "isActive": true
}
```

## DELETE `/api/v1/admin/shipment-categories/:categoryId`

Soft deletes the category by setting `deleted_at` and `is_active = 0`.
