# Admin Dashboard APIs

All admin dashboard routes require an admin JWT.

## GET `/api/v1/admin/dashboard/metrics`

Returns the dashboard cards and summaries used by the admin web dashboard:
shipments, driver availability, vehicle utilization, revenue summary, payment
method breakdown, and recent activity.

Optional query params:

```txt
dateFrom=2026-04-01
dateTo=2026-04-30
activityLimit=10
```

`dateFrom` and `dateTo` apply to shipment and payment metrics. Driver and
vehicle metrics represent the current operational state.

Sample response:

```json
{
  "success": true,
  "message": "Admin dashboard metrics fetched successfully.",
  "data": {
    "cards": {
      "totalShipments": 120,
      "pendingShipments": 14,
      "activeDeliveries": 38,
      "deliveredShipments": 62,
      "cancelledShipments": 6,
      "availableDrivers": 11,
      "busyDrivers": 7
    },
    "vehicleUtilization": {
      "totalVehicles": 24,
      "availableVehicles": 10,
      "assignedVehicles": 11,
      "maintenanceVehicles": 2,
      "inactiveVehicles": 1,
      "utilizationPercent": 45.83
    },
    "revenueSummary": {
      "currency": "INR",
      "totalPayments": 86,
      "paidPayments": 72,
      "pendingPayments": 10,
      "refundedPayments": 4,
      "paidAmount": 245000,
      "pendingAmount": 22000,
      "refundedAmount": 7800,
      "averageOrderValue": 3402.78,
      "methodBreakdown": [
        {
          "paymentMethod": "upi",
          "paymentCount": 42,
          "paidAmount": 128000
        }
      ]
    },
    "recentActivity": [
      {
        "activityType": "payment_recorded",
        "resourceCode": "PAY-20260430-1234567890",
        "title": "Payment paid for SHP-20260430-1234567890",
        "actorName": "Aarav Mehta",
        "status": "paid",
        "occurredAt": "2026-04-30T10:00:00.000Z"
      }
    ]
  }
}
```

## GET `/api/v1/admin/dashboard/recent-activity`

Returns only the recent activity table. Optional query:

```txt
limit=10
```

Recent activity is composed from shipments, payments, assignments, and proof
uploads.
