# Customer Registration API

These endpoints implement customer registration with email OTP verification.

## POST `/api/v1/auth/customer/register`

Creates an inactive customer user/profile and sends an email OTP. The OTP is
stored as a bcrypt hash in `auth_otps` with an expiry timestamp.

Sample request:

```json
{
  "name": "Aarav Mehta",
  "email": "aarav.mehta@example.com",
  "phone": "+919900000101",
  "password": "Password123!",
  "confirmPassword": "Password123!",
  "acceptTerms": true,
  "address": {
    "addressLine1": "Bandra Kurla Complex",
    "city": "Mumbai",
    "state": "Maharashtra",
    "postalCode": "400051",
    "country": "India"
  }
}
```

## POST `/api/v1/auth/customer/verify-otp`

Activates the user and customer profile after a valid email OTP.

Sample request:

```json
{
  "email": "aarav.mehta@example.com",
  "otp": "123456"
}
```

## POST `/api/v1/auth/customer/resend-otp`

Invalidates prior active registration OTPs and sends a new one.

Sample request:

```json
{
  "email": "aarav.mehta@example.com"
}
```

## Local Email

Set SMTP values in `.env` to send with Nodemailer. If `SMTP_HOST` is not set,
the OTP email is logged to the console for local testing.
