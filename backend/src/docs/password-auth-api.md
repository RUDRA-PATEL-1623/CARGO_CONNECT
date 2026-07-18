# Password Recovery and Change APIs

These endpoints use bcrypt-hashed OTPs/reset tokens stored in `auth_otps` with
expiry checks. SMTP is optional; when SMTP is not configured, OTP content is
logged to the local backend console for development testing.

## POST `/api/v1/auth/forgot-password`

Generates a password reset OTP for an existing account. The response message is
standardized so clients can show the same text whether or not an account exists.

Sample request:

```json
{
  "identifier": "admin@cargoconnect.local"
}
```

## POST `/api/v1/auth/verify-reset-otp`

Consumes a valid reset OTP and returns a short-lived single-use reset token.

Sample request:

```json
{
  "identifier": "admin@cargoconnect.local",
  "otp": "123456"
}
```

Sample response:

```json
{
  "success": true,
  "message": "Password reset OTP verified successfully.",
  "data": {
    "verified": true,
    "resetToken": "64-character-token",
    "expiresInMinutes": 15,
    "expiresAt": "2026-04-30T12:15:00.000Z"
  }
}
```

## POST `/api/v1/auth/create-new-password`

Consumes the reset token and updates the password with a bcrypt hash.

Sample request:

```json
{
  "identifier": "admin@cargoconnect.local",
  "resetToken": "64-character-token",
  "newPassword": "NewCargo@12345",
  "confirmPassword": "NewCargo@12345"
}
```

## POST `/api/v1/auth/change-password`

Changes the authenticated user's password after verifying the current password.

Required header:

```http
Authorization: Bearer <jwt>
```

Sample request:

```json
{
  "currentPassword": "Password123!",
  "newPassword": "NewCargo@12345",
  "confirmPassword": "NewCargo@12345"
}
```
