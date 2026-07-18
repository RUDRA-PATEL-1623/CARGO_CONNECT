# Auth Model and Service Layer

This layer provides reusable database models, service methods, and request
validators for future auth controllers. It does not add public auth endpoints.

## Supported Roles

- `admin`
- `dispatcher`
- `customer`
- `driver`

## Service Methods

- `authService.register(payload)`
- `authService.login({ identifier, password, role })`
- `authService.verifyOtp({ identifier, otp, purpose })`
- `authService.requestPasswordReset({ identifier })`
- `authService.resetPassword({ identifier, otp, newPassword })`
- `authService.changePassword({ userId, currentPassword, newPassword })`

## Validator Exports

- `registerValidator`
- `loginValidator`
- `otpVerifyValidator`
- `forgotPasswordValidator`
- `resetPasswordValidator`
- `changePasswordValidator`

## Sample Register Payload

```json
{
  "name": "Aarav Mehta",
  "role": "customer",
  "email": "aarav.mehta@example.com",
  "phone": "+919900000101",
  "password": "Password123!",
  "confirmPassword": "Password123!"
}
```

## Sample Login Payload

```json
{
  "identifier": "admin@cargoconnect.local",
  "password": "Password123!",
  "role": "admin"
}
```

## Notes

Development OTP values are returned by the service only when
`NODE_ENV !== 'production'`. Production integrations should send OTPs through a
provider and never expose generated codes in API responses.
