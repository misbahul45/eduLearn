# Contract: Predictions

## `GET /api/v1/predictions/latest`

### Request

Header: `Authorization: Bearer <access_token>`

### Response 200

```json
{
  "label": "Lulus",
  "probability": 0.8732,
  "class_scores": {
    "Tidak Lulus": 0.1268,
    "Lulus": 0.8732
  }
}
```

---

## `GET /api/v1/predictions/history?days=30`

### Request

Header: `Authorization: Bearer <access_token>`

| Query | Type | Default | Deskripsi |
|-------|------|---------|-----------|
| days | int | 30 | Rentang hari ke belakang |

### Response 200

```json
{
  "predictions": [
    {
      "id": 1,
      "probability": 0.87,
      "label": "Lulus",
      "created_at": "2026-07-04T10:30:00Z"
    },
    {
      "id": 2,
      "probability": 0.32,
      "label": "Tidak Lulus",
      "created_at": "2026-07-03T14:15:00Z"
    }
  ]
}
```

---

## `GET /api/v1/predictions/analysis`

### Request

Header: `Authorization: Bearer <access_token>`

### Response 200

```json
{
  "total_predictions": 15,
  "passed_count": 11,
  "failed_count": 4,
  "pass_rate": 0.73,
  "avg_probability": 0.78
}
```
