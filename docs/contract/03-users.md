# Contract: Users

## `GET /api/v1/users/me`

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

---

## `GET /api/v1/users/stats`

### Request

Header: `Authorization: Bearer <access_token>`

### Response 200

```json
{
  "total_conversations": 42,
  "total_predictions": 15,
  "average_prediction_score": 0.78,
  "passed_count": 11,
  "failed_count": 4,
  "pass_rate": 0.73
}
```
