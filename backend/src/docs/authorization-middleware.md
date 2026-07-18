# Authorization Middleware

These middleware helpers are reusable building blocks for protected business
routes. They do not add routes by themselves.

## JWT Authentication

Use `requireAuth` before role or resource guards.

```js
const { requireAuth } = require('../middleware/auth.middleware');

router.get('/profile', requireAuth, controller.showProfile);
```

Required request header:

```http
Authorization: Bearer <jwt>
```

Unauthorized response shape:

```json
{
  "success": false,
  "message": "Authentication token is required",
  "errors": null,
  "timestamp": "2026-04-30T12:00:00.000Z"
}
```

## Role Middleware

Use `requireRoles` for role gates. Admin-only routes can use `requireAdmin`.

```js
const { USER_ROLES } = require('../constants/auth.constants');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin, requireRoles } = require('../middleware/role.middleware');

router.get('/admin/reports', requireAuth, requireAdmin, reportsController.index);

router.get(
  '/dispatch/queue',
  requireAuth,
  requireRoles(USER_ROLES.ADMIN, USER_ROLES.DISPATCHER),
  dispatchController.queue,
);
```

Forbidden response shape:

```json
{
  "success": false,
  "message": "You do not have permission to access this resource",
  "errors": null,
  "timestamp": "2026-04-30T12:00:00.000Z"
}
```

## Customer Own Data

Customers can only access their own customer profile. Admin bypasses the guard.

```js
const { requireAuth } = require('../middleware/auth.middleware');
const { requireCustomerOwnData } = require('../middleware/access.middleware');

router.get(
  '/customers/:customerId',
  requireAuth,
  requireCustomerOwnData(),
  customersController.show,
);
```

The middleware reads `customerId` or `customerCode` from route params, query, or
body. Prefer route params for authorization checks.

## Shipment Access

Admin has full shipment access. Customers can access their own shipments.
Drivers can access shipments assigned to them.

```js
const { requireAuth } = require('../middleware/auth.middleware');
const { requireShipmentAccess } = require('../middleware/access.middleware');

router.get(
  '/shipments/:shipmentId',
  requireAuth,
  requireShipmentAccess(),
  shipmentsController.show,
);
```

## Driver Assigned Data

Drivers can only access assigned shipment or assignment records. Admin bypasses
the guard.

```js
const { requireAuth } = require('../middleware/auth.middleware');
const { requireDriverAssignedData } = require('../middleware/access.middleware');

router.patch(
  '/assignments/:assignmentId/status',
  requireAuth,
  requireDriverAssignedData(),
  driverTripsController.updateStatus,
);
```

The middleware reads `shipmentId`, `shipmentCode`, `assignmentId`, or
`assignmentCode` from route params, query, or body.
