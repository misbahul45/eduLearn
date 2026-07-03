# Contract: Authentication

## `POST /api/v1/auth/login`

### Request

```json
{
  "email": "student@example.com",
  "password": "securepassword123"
}
```

### Response 200

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJl...",
  "token_type": "bearer"
}
```

### Response 401

```json
{
  "detail": "Email atau password salah"
}
```

---

## `POST /api/v1/auth/register`

### Request

```json
{
  "name": "Budi Santoso",
  "email": "budi@example.com",
  "password": "securepassword123"
}
```

### Response 201

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJl...",
  "token_type": "bearer"
}
```

### Response 409

```json
{
  "detail": "Email sudah terdaftar"
}
```

---

## `POST /api/v1/auth/logout`

### Request

Header: `Authorization: Bearer <access_token>`

### Response 200

```json
{
  "detail": "Berhasil logout"
}
```

---

## `POST /api/v1/auth/refresh`

### Request

```json
{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJl..."
}
```

### Response 200

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "bmV3IHJlZnJlc2ggdG9r...",
  "token_type": "bearer"
}
```

---

## `GET /api/v1/auth/me`

### Request

Header: `Authorization: Bearer <access_token>`

### Response 200

```json
{
  "id": "uuid-user-123",
  "name": "Budi Santoso",
  "email": "budi@example.com"
}
```

### Response 401

```json
{
  "detail": "Token tidak valid atau sudah kedaluwarsa"
}
```
