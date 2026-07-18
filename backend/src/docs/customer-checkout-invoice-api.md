# Customer Checkout, Payment, and Invoice APIs

These customer routes are protected with a customer JWT. They use the existing
mock payment flow only: no external gateway is called.

## GET `/api/v1/customer/shipments/:shipmentId/checkout`

Returns shipment details, recalculated price breakdown, accepted mock payment
methods, and any existing paid payment/invoice for the customer-owned shipment.

Sample response:

```json
{
  "success": true,
  "message": "Checkout details fetched successfully.",
  "data": {
    "paymentMethods": ["upi", "card", "cash", "wallet"],
    "termsRequired": true,
    "priceEstimate": {
      "currency": "INR",
      "breakdown": {
        "subtotalAmount": 550,
        "feeAmount": 25,
        "taxAmount": 103.5,
        "totalAmount": 678.5
      }
    },
    "payment": null,
    "invoice": null
  }
}
```

## POST `/api/v1/customer/shipments/:shipmentId/checkout/mock-payment`

Creates a mock paid payment, marks the shipment as paid/pending, creates an
invoice record automatically, and returns the generated invoice download URL.

Sample request:

```json
{
  "paymentMethod": "upi",
  "couponCode": "WELCOME10",
  "acceptTerms": true
}
```

Sample response:

```json
{
  "success": true,
  "message": "Mock payment confirmed and invoice generated successfully.",
  "data": {
    "bookingId": "SHP-20260430-1234567890",
    "status": "pending",
    "message": "Mock payment captured and invoice generated.",
    "payment": {
      "paymentCode": "PAY-20260430-1234567890",
      "paymentMethod": "upi",
      "paymentStatus": "paid",
      "totalAmount": 678.5
    },
    "invoice": {
      "invoiceNumber": "INV-20260430-1234567890",
      "paymentStatus": "paid",
      "downloadUrl": "/api/v1/customer/invoices/1/download"
    }
  }
}
```

## GET `/api/v1/customer/invoices/:invoiceId`

Returns invoice preview data for the customer, including company, billing,
shipment, charge breakdown, taxes, total, and payment status.

## GET `/api/v1/customer/invoices/:invoiceId/download`

Generates the invoice PDF locally with `pdfkit` and streams it as
`application/pdf`.

Postman tip: use **Send and Download** for this endpoint, or verify that the
response headers include `Content-Type: application/pdf`.
