# CargoConnect Backend Foundation

This foundation creates the Express application shell only. It does not include
customer, driver, admin, shipment, payment, invoice, or report business APIs.

## Endpoints

### GET `/api/v1`

Returns the route registry.

Sample response:

```json
{
  "success": true,
  "message": "CargoConnect API route registry",
  "data": {
    "version": "v1",
    "environment": "development",
    "endpoints": [
      {
        "method": "GET",
        "path": "/api/v1",
        "description": "Route registry and API foundation status."
      }
    ]
  },
  "meta": null,
  "timestamp": "2026-04-30T00:00:00.000Z"
}
```

### GET `/api/v1/health`

Returns API process health.

### GET `/api/v1/health/db`

Checks MySQL connectivity using `mysql2/promise`.

## Postman Smoke Test

1. Copy `.env.example` to `.env` and set MySQL credentials.
2. Run `npm install`.
3. Run `npm run dev`.
4. Send `GET http://localhost:5000/api/v1`.
5. Send `GET http://localhost:5000/api/v1/health`.
6. Send `GET http://localhost:5000/api/v1/health/db` after MySQL is running.
