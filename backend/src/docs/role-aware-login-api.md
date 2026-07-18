# Role-Aware Login API

These endpoints authenticate users against a required role and return a JWT
session object with user and profile data.

## POST `/api/v1/auth/customer/login`

Customer login requires:

- `users.role = customer`
- `users.status = active`
- verified email
- active customer profile

Sample request:

```json
{
  "identifier": "customer@cargoconnect.local",
  "password": "Password123!"
}
```

## POST `/api/v1/auth/driver/login`

Driver login requires:

- `users.role = driver`
- `users.status = active`
- existing driver profile
- `drivers.driver_status = active`

Sample request:

```json
{
  "identifier": "driver@cargoconnect.local",
  "password": "Password123!"
}
```

## POST `/api/v1/auth/admin/login`

Admin login accepts active `admin` and `dispatcher` users. Both roles can access admin-panel routes protected by `requireAdmin`.

- `users.role = admin` or `users.role = dispatcher`
- `users.status = active`

Sample request:

```json
{
  "identifier": "admin@cargoconnect.local",
  "password": "Password123!"
}
```

## Sample Success Response

```json
{
  "success": true,
  "message": "Customer login successful.",
  "data": {
    "auth": {
      "token": "jwt.token.value",
      "tokenType": "Bearer",
      "expiresIn": "1d",
      "expiresAt": "2026-05-01T12:00:00.000Z"
    },
    "role": "customer",
    "user": {
      "publicId": "00000000-0000-4000-8000-000000000100",
      "role": "customer",
      "name": "CargoConnect Customer",
      "email": "customer@cargoconnect.local",
      "status": "active"
    },
    "profile": {
      "type": "customer",
      "customerCode": "CUST-TEST",
      "accountStatus": "active"
    }
  }
}
```
