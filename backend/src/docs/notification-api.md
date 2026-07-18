# CargoConnect Notification API

All notification endpoints use the standard response envelope and require a
Bearer JWT for the matching role.

## Role Inboxes

### Customer

- `GET /api/v1/customer/notifications`
- `PATCH /api/v1/customer/notifications/:notificationId/read`
- `PATCH /api/v1/customer/notifications/read-all`
- `DELETE /api/v1/customer/notifications/clear`

### Driver

- `GET /api/v1/driver/notifications`
- `PATCH /api/v1/driver/notifications/:notificationId/read`
- `PATCH /api/v1/driver/notifications/read-all`
- `DELETE /api/v1/driver/notifications/clear`

### Admin

- `GET /api/v1/admin/notifications`
- `POST /api/v1/admin/notifications`
- `PATCH /api/v1/admin/notifications/:notificationId/read`
- `PATCH /api/v1/admin/notifications/read-all`
- `DELETE /api/v1/admin/notifications/clear`

## Query Filters

`GET` inbox endpoints accept:

- `page`
- `limit`
- `notificationType`
- `unreadOnly`
- `shipmentId`

## Admin Create Notification

Request:

```json
{
  "targetRole": "driver",
  "notificationType": "system",
  "title": "Dispatch update",
  "message": "Please check your assigned route before leaving the yard.",
  "channel": "in_app",
  "metadata": {
    "source": "admin_panel"
  }
}
```

Use `userId` instead of `targetRole` to send to one account.

Response:

```json
{
  "success": true,
  "message": "Notification created successfully.",
  "data": {
    "notifications": [
      {
        "id": 12,
        "userId": 8,
        "notificationType": "system",
        "title": "Dispatch update",
        "message": "Please check your assigned route before leaving the yard.",
        "channel": "in_app",
        "isRead": false
      }
    ]
  }
}
```

## Automatic Event Notifications

- Booking/payment confirmation: customer and admins.
- Admin approval: customer.
- Driver/vehicle assignment or replacement: customer and assigned driver.
- Driver accept: customer.
- Driver reject: customer and admins.
- Trip started: customer.
- Pickup completed: customer.
- In transit: customer.
- Delivered: customer.
- Completed: customer.
- Rejected/cancelled shipment: customer and any active assigned drivers.
- Emergency or breakdown report: admins.

Notification types:

`booking_confirmed`, `shipment_approved`, `driver_assigned`,
`driver_accepted`, `driver_rejected`, `shipment_started`, `pickup_completed`,
`in_transit`, `delivered`, `completed`, `cancelled`,
`emergency_reported`, `support_reply`, `system`.
