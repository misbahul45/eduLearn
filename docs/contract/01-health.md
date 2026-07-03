# Contract: Health Check

## `GET /health`

### Request

Tidak ada. Tidak perlu autentikasi.

### Response 200

```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_directory": "/app/models",
  "version": "1.0.0",
  "uptime": "123.45s",
  "python": "3.14.5",
  "tensorflow": "2.18.0",
  "environment": "production"
}
```

### Response 503

```json
{
  "detail": {
    "status": "unhealthy",
    "error": "Model not loaded"
  }
}
```
