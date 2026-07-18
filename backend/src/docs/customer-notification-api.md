# Customer Notification APIs

All routes require a customer JWT. Notifications are filtered by the
authenticated `users.id`, so customers can only read and mutate their own
notification records.

## GET `/api/v1/customer/notifications`

Query params:

```txt
page=1
limit=20
notificationType=driver_assigned
unreadOnly=true
shipmentId=1
```

Sample response:

```json
{
  "success": true,
  "message": "Customer notifications fetched successfully.",
  "data": {
    "notifications": [
      {
        "id": 7,
        "shipmentId": 1,
        "shipmentCode": "SHP-20260430-1234567890",
        "notificationType": "driver_assigned",
        "title": "Driver assigned",
        "message": "Your shipment has been assigned to a driver.",
        "isRead": false,
        "createdAt": "2026-04-30T10:00:00.000Z"
      }
    ],
    "unreadCount": 3,
    "meta": {
      "total": 1,
      "page": 1,
      "limit": 20,
      "totalPages": 1,
      "hasMore": false
    }
  }
}
```

## PATCH `/api/v1/customer/notifications/:notificationId/read`

Marks one notification as read for the authenticated customer.

## PATCH `/api/v1/customer/notifications/read-all`

Marks all unread notifications as read.

## DELETE `/api/v1/customer/notifications/clear`

Soft clears all customer notifications by setting `deleted_at`.
