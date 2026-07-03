# Firecrawl Web Search Tool

## Tujuan

Mendefinisikan tool ketiga di LangGraph supervisor: **Firecrawl web search**. Tool ini dipakai saat RAG lokal tidak punya jawaban atau siswa butuh info terkini. Halaman ini juga mendefinisikan event `web_search_result` di WebSocket (lihat `contract/07-events.md` §7.7).

## Kapan Firecrawl Dipakai?

Supervisor system prompt wajib menyertakan heuristik berikut:

| Skenario pertanyaan | Tool yang dipakai |
|---|---|
| Konsep akademis dasar (mis. "apa itu neural network") | `rag_tool` dulu |
| Materi yang sudah ada di knowledge base lokal | `rag_tool` |
| Info terkini / 2026 (mis. "model AI terbaru 2026") | `firecrawl_tool` |
| Berita / event terkini | `firecrawl_tool` |
| Topik yang kemungkinan tidak di-upload di lokal (mis. "review paper arxiv kemarin") | `firecrawl_tool` |
| Pertanyaan tentang progress/kelulusan siswa | `predictive_tool` |
| Kombinasi (mis. "apa itu transformer dan siapa penemunya terkini") | `rag_tool` + `firecrawl_tool` |

## Firecrawl API

**Endpoint**: `https://api.firecrawl.dev/v1/search`  
**Auth**: Bearer token di header `Authorization: Bearer $FIRECRAWL_API_KEY`  
**API key**: dari env `FIRECRAWL_API_KEY` (wajib di `infra/.env`)

### Request

```bash
curl -X POST https://api.firecrawl.dev/v1/search \
  -H "Authorization: Bearer $FIRECRAWL_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "neural network 2026 latest",
    "limit": 3,
    "scrapeOptions": {
      "formats": ["markdown"],
      "onlyMainContent": true,
      "maxTokens": 1000
    }
  }'
```

### Response

```json
{
  "success": true,
  "data": [
    {
      "url": "https://example.com/article",
      "title": "Neural Networks in 2026: A Comprehensive Guide",
      "description": "Recent advances in...",
      "markdown": "## Introduction\nNeural networks are computational models..."
    }
  ]
}
```

## Tool Wrapper

`app/agent/tools/firecrawl_tool.py`:

```python
from langchain_core.tools import tool
import httpx
from app.core.config import settings
from app.schemas.knowledge import WebSearchResult


@tool
async def firecrawl_tool(query: str, max_results: int = 3) -> list[WebSearchResult]:
    """
    Cari informasi terkini di web via Firecrawl API. Pakai untuk topik
    yang belum ada di knowledge base lokal atau butuh info 2026.

    Args:
        query: Query pencarian (max 200 char).
        max_results: Maksimum hasil (default 3, max 5).

    Returns:
        List[WebSearchResult] — url, title, snippet, markdown_excerpt.
    """
    if not settings.FIRECRAWL_API_KEY:
        raise RuntimeError("FIRECRAWL_API_KEY belum di-set")

    query = query[:200]  # truncate safety
    max_results = min(max(max_results, 1), 5)

    async with httpx.AsyncClient(timeout=15.0) as client:
        resp = await client.post(
            "https://api.firecrawl.dev/v1/search",
            headers={
                "Authorization": f"Bearer {settings.FIRECRAWL_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "query": query,
                "limit": max_results,
                "scrapeOptions": {
                    "formats": ["markdown"],
                    "onlyMainContent": True,
                    "maxTokens": 1000,
                },
            },
        )
        resp.raise_for_status()
        data = resp.json()

    results = []
    for i, item in enumerate(data.get("data", [])):
        results.append(WebSearchResult(
            result_id=f"ws_{i:03d}",
            url=item.get("url", ""),
            title=item.get("title", "Tanpa judul"),
            snippet=(item.get("description") or "")[:300],
            markdown_excerpt=(item.get("markdown") or "")[:800],
            source="firecrawl",
            relevance_score=0.0,
        ))
    return results
```

## Skema Data

```python
# app/schemas/knowledge.py (tambahan)
from pydantic import BaseModel


class WebSearchResult(BaseModel):
    result_id: str          # "ws_000", "ws_001", ...
    url: str
    title: str
    snippet: str            # max 300 char
    markdown_excerpt: str   # max 800 char (untuk preview)
    source: str             # "firecrawl" (untuk ekstensi masa depan)
    relevance_score: float  # [0, 1], default 0 (Firecrawl tidak return score)
```

## Emit Event `web_search_result`

Saat tool dieksekusi, tool executor di LangGraph emit event untuk setiap result (lihat `contract/07-events.md` §7.7):

```python
# di app/agent/tools/firecrawl_tool.py wrapper (event emit via callback di supervisor)
async def firecrawl_tool_with_events(query: str, max_results: int = 3):
    results = await firecrawl_tool_fn(query, max_results)
    for r in results:
        await emit_event({
            "type": "web_search_result",
            "result_id": r.result_id,
            "url": r.url,
            "title": r.title,
            "snippet": r.snippet,
            "markdown_excerpt": r.markdown_excerpt,
            "source": r.source,
            "relevance_score": r.relevance_score,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
    return results
```

## Tampilan di Flutter

Lihat detail di `16-flutter-chat.md` (sub-widget `WebSearchTile`). Ringkasan:

- Di bawah bubble chat (atau sebagai bagian dari `CitationExpansionTile`), tampilkan section "Sumber web (N)":
  - Ikon 🌐 + URL domain.
  - Judul halaman (judul HTML).
  - Snippet ringkas.
  - Tap → buka URL di browser eksternal (`url_launcher`).
- Berbeda dari `CitationExpansionTile` (sumber lokal): `WebSearchTile` tidak punya nomor `[1]`, tapi pakai ikon 🌐 + domain.

## Wireframe

```
┌─────────────────────────────────────┐
│ 🤖 Assistant                        │
│ Berdasarkan artikel terkini [1],    │
│ transformer architecture...         │
│                                     │
│ ▼ Sumber referensi lokal (1)        │  ← CitationExpansionTile
│   ┌─────────────────────────────┐   │
│   │ [1] Pengantar Deep Learning │   │
│   └─────────────────────────────┘   │
│                                     │
│ ▼ Sumber web (2)                    │  ← WebSearchTile
│   ┌─────────────────────────────┐   │
│   │ 🌐 example.com              │   │
│   │ Neural Networks in 2026     │   │
│   │ "Recent advances in..."     │   │
│   └─────────────────────────────┘   │
│   ┌─────────────────────────────┐   │
│   │ 🌐 arxiv.org                │   │
│   │ ...                         │   │
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Catatan

- **Rate limit Firecrawl**: API key free tier ~500 requests/bulan. Implementasi caching di Redis: `ws:cache:{md5(query)}` TTL 1 jam. Bila cache hit, skip API call.
- **Timeout**: 15 detik per request. Bila timeout, tool throw exception → supervisor bisa skip tool & jawab dengan info lokal saja.
- **Sanitasi**: snippet & markdown_excerpt di-sanitize (strip HTML tags selain markdown dasar, escape `<script>`, strip PII pattern seperti email/phone).
- **Tidak menyimpan ke pgvector**: web search result bersifat transient per conversation, tidak di-embed ke knowledge base. Bila pengajar ingin simpan permanen, upload manual via API upload file (lihat `11-file-upload.md`).
- **Cost tracking**: setiap Firecrawl call di-log ke `audit_conversations` (kolom `tools_called` jsonb) untuk tracking biaya. Lihat `10-security.md` §10.6.
- **Fallback bila API key tidak ada**: tool throw `RuntimeError`, supervisor menangkap via tool exception, jawab "Saya tidak bisa mencari info web saat ini, hanya bisa pakai referensi lokal."
- **Maximum 5 results per call** untuk menghindari bubble chat overflow.
