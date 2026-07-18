# CargoConnect Admin Report API

All endpoints require an active admin JWT.

## Report Endpoints

- `GET /api/v1/admin/reports/shipments`
- `GET /api/v1/admin/reports/drivers`
- `GET /api/v1/admin/reports/vehicles`
- `GET /api/v1/admin/reports/payments`
- `GET /api/v1/admin/reports/invoices`

Each report returns:

- `summary.dateWise`
- `summary.statusWise`
- `summary.categoryWise`
- `rows`
- pagination `meta`
- `emptyState` when no rows match

## Filters

Common filters:

- `page`
- `limit`
- `dateFrom`
- `dateTo`
- `status`
- `categoryId`
- `categoryCode`
- `search`

Optional report-specific filters:

- `paymentStatus`
- `paymentMethod`
- `invoiceStatus`
- `driverStatus`
- `availabilityStatus`
- `vehicleType`

## Export Endpoints

- `GET /api/v1/admin/reports/shipments/export?format=csv`
- `GET /api/v1/admin/reports/shipments/export?format=pdf`
- `GET /api/v1/admin/reports/drivers/export?format=csv`
- `GET /api/v1/admin/reports/drivers/export?format=pdf`
- `GET /api/v1/admin/reports/vehicles/export?format=csv`
- `GET /api/v1/admin/reports/vehicles/export?format=pdf`
- `GET /api/v1/admin/reports/payments/export?format=csv`
- `GET /api/v1/admin/reports/payments/export?format=pdf`
- `GET /api/v1/admin/reports/invoices/export?format=csv`
- `GET /api/v1/admin/reports/invoices/export?format=pdf`

CSV and PDF files are generated locally in memory. CSV includes up to 5000
rows. PDF includes a printable summary and first 200 rows; CSV is preferred for
large raw exports.

## Sample Request

```http
GET /api/v1/admin/reports/shipments?dateFrom=2026-04-01&dateTo=2026-04-30&status=completed&categoryCode=heavy_cargo
Authorization: Bearer <admin-token>
```

## Sample Response

```json
{
  "success": true,
  "message": "Shipment Report fetched successfully.",
  "data": {
    "reportType": "shipments",
    "title": "Shipment Report",
    "filters": {
      "dateFrom": "2026-04-01",
      "dateTo": "2026-04-30",
      "status": "completed",
      "categoryId": null,
      "categoryCode": "heavy_cargo"
    },
    "summary": {
      "dateWise": [],
      "statusWise": [],
      "categoryWise": [],
      "methodWise": null
    },
    "rows": [],
    "meta": {
      "total": 0,
      "page": 1,
      "limit": 10,
      "totalPages": 0,
      "hasMore": false,
      "exportLimit": null
    },
    "emptyState": {
      "title": "No report data",
      "message": "Try changing the date, status, category, or search filters."
    }
  }
}
```

## Postman Notes

1. Login with `POST /api/v1/auth/admin/login`.
2. Add `Authorization: Bearer <admin-token>`.
3. Test a JSON report endpoint.
4. Test CSV export using `format=csv` and Postman's `Send and Download`.
5. Test PDF export using `format=pdf` and save the downloaded file.
