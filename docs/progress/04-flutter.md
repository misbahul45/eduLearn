# Progress — Flutter Implementation

## Status Per Area

| Area | Progress | Catatan |
|------|----------|---------|
| Design System | ✅ Done | Colors, spacing, typography, theme |
| Routing (GoRouter) | ✅ Done | `StatefulShellRoute.indexedStack`: Home, Chat, Analysis, Profile tabs |
| Riverpod + Dio + SecureStorage | ✅ Done | ProviderScope, ApiClient, AuthRepository |
| Auth Models (User, AuthStatus) | ✅ Done | fromJson, AuthResult enum |
| Prediction Service + Provider | ✅ Done | latest, 7d-history, analysis via API |
| Splash Page | ✅ Done | Riverpod ViewModel, auto-routing (homeTab/login) |
| Login Page | ✅ Done | SnackBar error, eye toggle, Lupa password, Indonesian |
| Register Page | ✅ Done | SnackBar error, eye toggle, password strength, 409 login button |
| Home Tab (Dashboard) | ✅ Done | Greeting, prediction summary, insight, fl_chart history, quick actions |
| Chat Page | ✅ Done | Empty state, bubble list, input field |
| Analysis Page | ✅ Done | Stat cards, progress bar, latest prediction |
| Knowledge Page | ✅ Done | List dokumen, refresh, delete (standalone route dari Profile) |
| Profile Page | ✅ Done | Avatar, stats, role badge, knowledge link, logout |
| fl_chart | ✅ Done | LineChart probabilitas 7 hari + threshold line 0.5 |

## Detail Halaman Home (Spec 15)

- `StatefulShellRoute.indexedStack` — preserve state tiap tab saat pindah
- Tab 1: Home (`Icons.home_rounded`) — dashboard
- Tab 2: Chat (`Icons.chat_bubble_rounded`)
- Tab 3: Analysis (`Icons.insights_rounded`)
- Tab 4: Profile (`Icons.person_rounded`)
- Home Tab: greeting card (initial avatar), prediction summary card (primary bg), insight card (success/warning), history chart (fl_chart LineChart with threshold), quick actions row

## Detail Halaman Chat (Spec 16)

- **Route**: `/home/chat` (tab ke-2 `StatefulShellRoute`)
- **ChatPage** — `ConsumerStatefulWidget` dengan AppBar + StatusBadge + AgentTraceSheet + input bar
- **StatusBadge** — spinner "Memproses..." saat thinking, check "Online" saat idle, warning "Offline" saat REST fallback
- **EmptyState** — icon smart_toy + 3 suggestion chips ("Jelaskan neural network", "Prediksi kelulusanku", "Berita AI terbaru 2026")
- **ChatBubble** — primary/surface, streaming cursor blink `┃`, prediction chart (fl_chart BarChart 2 bar), citation expansion, web search expansion, error chip
- **AgentTraceSheet** — DraggableScrollableSheet 0.3–0.7, live trace log dengan icon + timestamp
- **PredictionChartCard** — BarChart horizontal, 2 bar (Lulus success, Tidak Lulus error), binary
- **CitationExpansionTile** — numbered items dengan score badge, metadata (author/page/file)
- **WebSearchTile** — domain, title, snippet, "Lihat konten lengkap" sheet, open_in_new
- **ConnectionModeBanner** — chip oranye "Mode non-realtime" saat REST fallback
- **AgentSocketService** — WS connect dengan JWT, parse 9 event types, exponential backoff 1s–30s, fallback rest after 3 fails
- **ChatRepository** — POST `/api/v1/chat` REST fallback non-streaming
- **ChatViewModel** — StateNotifier dengan messages, currentStreamingMessage, traceLog, status, connectionMode, isSending
- **AgentEvent** — sealed class dengan 9 variants: StateUpdate, ToolCall, ToolResult, Token, PredictionResult, Citation, WebSearchResult, Final, Error

## Yang Perlu Dikerjakan Nanti

- **WebSocket Chat** — integrasi WS nyata untuk streaming jawaban AI (infra sudah siap, tinggal server side)
- **Forgot Password** — halaman lupa password
- **Knowledge Upload** — form upload file (PDF/DOCX/TXT/MD) untuk pengajar
- **Google Sign-In** — integrasi OAuth
- **Dark mode / Theme switching**
- **Offline mode**
- **Push notifications**
