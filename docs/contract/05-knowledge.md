# Contract: Knowledge (File Upload)

## `POST /api/v1/knowledge/upload`

### Request

Header: `Authorization: Bearer <access_token>`  
Content-Type: `multipart/form-data`

| Field | Type | Deskripsi |
|-------|------|-----------|
| file | File | File dokumen (PDF, DOCX, TXT, MD) |

### Response 201

```json
{
  "id": "uuid-doc-456",
  "filename": "bab1-neural-network.pdf",
  "chunks": 15,
  "status": "processed"
}
```

### Response 413

```json
{
  "detail": "File terlalu besar. Maksimal 10 MB"
}
```

### Response 415

```json
{
  "detail": "Tipe file tidak didukung. Gunakan: .pdf, .docx, .txt, .md"
}
```
