# Flutter Client — Comprehensive Analysis Report

**Generated**: 4 Juli 2026
**Scope**: Seluruh Flutter client (`client/lib/`) vs 18 spec docs, 7 contract docs, 10 Flutter skill guidelines
**Method**: docs → code → skills → kontrak server → lint analysis

---

## Ringkasan

| Kategori | Jumlah Temuan | P0 | P1 | P2 | P3 |
|----------|:------------:|:--:|:--:|:--:|:--:|
| WS/Realtime | 2 | 2 | — | — | — |
| REST/API Contract | 4 | 3 | — | 1 | — |
| Architecture | 5 | — | 5 | — | — |
| Spec Compliance | 4 | — | — | 4 | — |
| Code Quality | 5 | — | — | — | 5 |
| **Total** | **20** | **5** | **5** | **5** | **5** |

---

## 1. Architecture Compliance

| Criteria | Status | Evidence |
|----------|--------|----------|
| Layered architecture (UI/Logic/Data) | ✅ Mostly | Pages in `features/*/`, ViewModels in `features/*/providers/`, Services in `core/services/` |
| Views lean (no business logic) | ✅ | Pages only handle UI + `ref.watch`/`ref.listen` |
| ViewModels separate from Views | ✅ | Dedicated providers for all pages |
| Repositories separate from Services | ✅ | `auth_repository.dart`, `chat_repository.dart` vs `prediction_service.dart`, `knowledge_service.dart` |
| Project structure matches spec | ⚠️ Partial | Missing `core/network/` (WS & Dio files are in `core/services/`). Missing `core/constants/`. No `shared/` folder |

**Issues**:

1. **P1 — Hardcoded base URLs** (`client/lib/core/services/api_client.dart:11`, `agent_socket_service.dart:26`):
   - `ApiClient` baseUrl: `'https://api.edulearn.ai/api/v1'`
   - `AgentSocketService` baseUrl: `'wss://api.edulearn.ai/ws/v1/chat'`
   - Harus dari env/config, bukan hardcode.

2. **P1 — No Dio interceptor for auth** (`client/lib/core/services/api_client.dart`):
   - `_attachToken()` membaca dari storage setiap request — harusnya `InterceptorsWrapper`.
   - Tidak ada 401 → refresh → retry otomatis. `_tryRefresh` hanya di `auth_repository.dart:48`.

3. **P1 — ChatViewModel pakai StateNotifier, bukan AsyncNotifier** (`client/lib/features/chat/providers/chat_viewmodel.dart`):
   - Spec `02-design-system.md:71` mandate `AsyncNotifierProvider`.
   - State tidak auto-dispose.

4. **P1 — No conversation_id tracking**:
   - Setelah WS menerima `final` event dengan `conversation_id`, client tidak menyimpannya.
   - Per spec `03-architecture.md:129`, reconnection harus kirim ulang `conversation_id` untuk resume dari Redis.

5. **P1 — connectivity_plus tidak pernah dipakai** (`client/pubspec.yaml:42`):
   - Package di dependensi tapi tidak diimport di mana pun.

---

## 2. HTTP/Networking (Dio)

| Check | Status | Details |
|-------|--------|---------|
| Dio used | ✅ | `pubspec.yaml:37` — `dio: ^5.7.0` |
| Error handling | ✅ | `_mapError` handles SocketException, 401, 409, 5xx |
| Service classes stateless | ✅ | All services are stateless classes |
| Interceptors for auth/refresh | ❌ | Manual `_attachToken()` on every call |
| Base URL configurable | ❌ | Hardcoded |
| `connectivity_plus` used | ❌ | Listed in `pubspec.yaml` but never used |

---

## 3. Routing (go_router)

| Check | Status | Details |
|-------|--------|---------|
| go_router used | ✅ | `pubspec.yaml` |
| StatefulShellRoute for bottom nav | ✅ | `app_router.dart:32` |
| Routes match spec | ✅ | Semua route sesuai spec 12-18 |
| Path URL strategy | ❌ | Tidak dikonfigurasi — pakai hash routing default |

**Unused route**: `/forgot-password` didefinisikan di `app_routes.dart:22` tapi tidak pernah dipakai.
**Dead code**: `KnowledgePage` adalah standalone route `/knowledge` tapi tidak ada link ke sana.

---

## 4. Models/Serialization

| Check | Status | Details |
|-------|--------|---------|
| `fromJson` exists | ✅ | Semua model |
| `toJson` exists | ❌ | **Tidak ada model yang punya `toJson`** |
| Type-safe | ⚠️ | Pattern `as String? ?? ''` — null-safe tapi tidak strict |
| freezed/codegen | ❌ | Spec 02 mandate `freezed_annotation + json_serializable` |
| Switch pattern matching | ❌ | Tidak dipakai |

**Field mismatches dengan contract API**:

| Endpoint | Contract Field | Client Expects | Issue |
|----------|---------------|----------------|-------|
| `GET /predictions/latest` | `label, probability, class_scores` | `id, label, probability, created_at` | `id` dan `created_at` tidak ada di contract |
| `GET /predictions/history` | `id: int` | `id: String` | Type mismatch |
| `GET /auth/me` | `id, name, email` | `id, name, email, role, created_at` | `role` default 'siswa', `created_at` null |

---

## 5. Testing Status

| Aspect | Status | Details |
|--------|--------|---------|
| Widget tests | 1 test | `test/widget_test.dart` — cek splash page render |
| ViewModel tests | ❌ | Tidak ada |
| Service tests | ❌ | Tidak ada |
| Model tests | ❌ | Tidak ada |
| Integration tests | ❌ | Tidak ada |
| WS parsing tests | ❌ | Tidak ada |

**Tests yang dibutuhkan (prioritas)**:
1. Model `fromJson` untuk semua model (contract compliance)
2. `AuthRepository.login/register/checkAuth/logout` (token + API)
3. `LoginViewModel` / `RegisterViewModel` (state transition)
4. `ChatViewModel._onEvent` (WS event → state)
5. `AgentSocketService._parseEvent` (9 event types)
6. `ApiClient._attachToken` (token injection)

---

## 6. Responsive Layout

| Check | Status | Details |
|-------|--------|---------|
| LayoutBuilder | ❌ | Tidak dipakai. Asumsi mobile-only |
| MediaQuery sizing | ⚠️ | Dipakai di `_ChatBubble` |
| SafeArea | ✅ | Semua halaman |
| ScrollView patterns | ⚠️ | `AnalysisPage` pakai `ListView` tanpa `Expanded` bisa overflow di tablet |

---

## 7. Localization (i18n)

| Check | Status |
|-------|--------|
| `flutter_localizations` | ❌ Tidak ada |
| `intl` package | ❌ Tidak ada |
| Semua teks Indonesia | ✅ Sesuai spec |
| ARB files | ❌ Tidak ada |

---

## 8. Spec-Code Alignment

### Spec 12 — Splash (`docs/specification/12-flutter-splash.md`)

| Requirement | Status | File:Line |
|-------------|--------|-----------|
| Icon + title + subtitle + loading | ✅ | `splash_page.dart:47-67` |
| Auth check logic | ✅ | `splash_provider.dart:24-36` |
| 2-second delay | ✅ | `splash_page.dart:27` |
| Route to login/home | ✅ | `splash_page.dart:31-34` |

### Spec 13 — Login (`docs/specification/13-login.md`)

| Requirement | Status | Detail |
|-------------|--------|--------|
| Form email/password | ✅ | |
| Email regex | ✅ | `_emailRegex` di line 29 |
| Password min 8 | ✅ | Validator line 150 |
| Eye toggle | ✅ | Line 137-146 |
| Error SnackBar | ✅ | 401/5xx/no-connection |
| Success → home | ✅ | `context.goNamed(AppRoutes.homeTab)` |
| Google sign-in placeholder | ✅ | SnackBar "coming soon" |

**Mismatch**: "Lupa password?" spec: navigate ke `/forgot` — implementasi: SnackBar placeholder.

### Spec 14 — Register (`docs/specification/14-register.md`)

| Requirement | Status |
|-------------|--------|
| Form name/email/password/confirm | ✅ |
| Password validation (letter + digit) | ✅ |
| Confirm matching | ✅ |
| Eye toggle per field | ✅ |
| Success → home | ✅ |
| 409 "Email sudah terdaftar" | ✅ |

### Spec 15 — Home (`docs/specification/15-home.md`)

| Requirement | Status |
|-------------|--------|
| StatefulShellRoute 4 tabs | ✅ |
| GreetingCard CircleAvatar | ✅ |
| PredictionSummaryCard | ✅ |
| InsightCard | ✅ |
| HistoryChart (fl_chart) | ✅ |
| QuickActionsRow | ✅ |
| Empty state | ✅ |
| Pull-to-refresh | ✅ |

### Spec 16 — Chat (`docs/specification/16-chat.md`)

| Requirement | Status | Detail |
|-------------|--------|--------|
| ListView reverse | ✅ | |
| Streaming cursor `┃` | ✅ | |
| PredictionChartCard | ✅ | BarChart 2 bar |
| CitationExpansionTile | ✅ | |
| WebSearchTile | ✅ | |
| AgentTraceSheet | ✅ | DraggableScrollableSheet |
| ConnectionModeBanner | ✅ | |
| StatusBadge | ✅ | |

**Mismatches**:
1. **P2 — Quick suggestion chips salah**: Code: "Jelaskan neural network", "Apa itu supervised learning?", "Bantu saya quiz". **Spec**: "Jelaskan neural network", "Prediksi kelulusanku", "Berita AI terbaru 2026"
2. **P0 — WS user_message format salah**: Client kirim `{'message': text}`. Contract minta `{"type": "user_message", "message": "...", "conversation_id": null}`
3. **P0 — No pong response**: Server kirim `ping` tiap 20s. Client tidak balas `pong`. Koneksi drop setelah `WS_HEARTBEAT_TIMEOUT` (30s).
4. **P2 — No reconnect-on-foreground**: Spec 16:35 — reconnect saat app foreground.

### Spec 17 — Analysis (`docs/specification/17-analysis.md`)

| Requirement | Status |
|-------------|--------|
| Donut chart 2 segmen | ✅ |
| StrengthCard success bg | ✅ |
| ImprovementCard warning bg | ✅ |
| 3 Recommendations | ✅ |
| Progress comparison | ✅ |
| History list | ✅ |
| Empty state | ✅ |

### Spec 18 — Profile (`docs/specification/18-profile.md`)

| Requirement | Status | Detail |
|-------------|--------|--------|
| ProfileHeader avatar | ✅ | |
| BiodataCard | ✅ | |
| Stats cards | ✅ | |
| Knowledge management (pengajar) | ✅ | |
| Upload sheet | ✅ | |
| Settings placeholder | ✅ | |
| Logout confirmation | ✅ | |

**Mismatch**:
1. **P3 — _StatsRow mislabel**: Label "Percakapan" tapi menampilkan `totalPredictions` dari endpoint analysis. Spec bilang stats harus dari endpoint terpisah (`GET /api/v1/users/stats`).

---

## 9. Client-Server Contract Alignment

### REST API Paths — All match ✅

| Endpoint (Contract) | Client Path | Match |
|---------------------|-------------|-------|
| `POST /api/v1/auth/login` | `/auth/login` | ✅ |
| `POST /api/v1/auth/register` | `/auth/register` | ✅ |
| `POST /api/v1/auth/logout` | `/auth/logout` | ✅ |
| `POST /api/v1/auth/refresh` | `/auth/refresh` | ✅ |
| `GET /api/v1/auth/me` | `/auth/me` | ✅ |
| `GET /api/v1/users/me` | ❌ **Never called** | ❌ |
| `GET /api/v1/users/stats` | ❌ **Never called** | ❌ |
| `GET /api/v1/predictions/latest` | `/predictions/latest` | ✅ |
| `GET /api/v1/predictions/history` | `/predictions/history` | ✅ |
| `GET /api/v1/predictions/analysis` | `/predictions/analysis` | ✅ |
| `POST /api/v1/knowledge/upload` | `/knowledge/upload` | ✅ |
| `GET /api/v1/knowledge` | `/knowledge` | ✅ |
| `DELETE /api/v1/knowledge/{id}` | `/knowledge/$id` | ✅ |
| `POST /api/v1/chat` | `/chat` | ✅ |
| `WS /ws/v1/chat` | `wss://.../ws/v1/chat` | ✅ |

### Response Schema Mismatches

| Endpoint | Contract Response | Client Parsed | Issue |
|----------|-----------------|---------------|-------|
| `GET /api/v1/auth/me` | `{id, name, email}` | +`role`, +`created_at` | role default 'siswa' ⚠️ |
| `GET /api/v1/predictions/latest` | `{label, probability, class_scores}` | +`id`, +`created_at` | id='', createdAt=now() ❌ |
| `GET /api/v1/predictions/history` | `id: int` | `id: String` | Type mismatch ⚠️ |
| `POST /api/v1/knowledge/upload` | `{id, filename, chunks, status}` | Raw Map | id vs document_id 🤷 |

### WebSocket Event Mismatches

| Event | Contract | Client | Issue |
|-------|----------|--------|-------|
| `user_message` (C→S) | `{"type":"user_message","message":"...","conversation_id":null}` | `{'message': text}` | **Missing type + conversation_id** ❌ |
| `ping` (S→C) | `{"type":"ping"}` | Not handled | **No pong response** ❌ |
| `pong` (C→S) | `{"type":"pong"}` | Not sent | ❌ |
| All 9 S→C events | Contract schemas | `_parseEvent` handles all | ✅ |

---

## 10. Prioritized Recommendations

### P0 — Critical (functional bugs)

| # | Issue | File | Impact |
|---|-------|------|--------|
| 1 | WS user_message format wrong | `agent_socket_service.dart:62` | Server ignores message |
| 2 | No pong response | `agent_socket_service.dart` | Connection drops every 30s |
| 3 | `/predictions/latest` response mismatch | `prediction.dart:16-25` | id='', createdAt=now() |
| 4 | `/predictions/history` type mismatch | `prediction.dart:18` | id: String vs contract int |
| 5 | `/users/me` & `/users/stats` never called | `profile_page.dart` | Profile stats wrong |

### P1 — Architecture & Patterns

| # | Issue | File |
|---|-------|------|
| 6 | Hardcoded base URLs | `api_client.dart:11`, `agent_socket_service.dart:26` |
| 7 | No Dio auth interceptor | `api_client.dart` |
| 8 | ChatViewModel wrong pattern | `chat_viewmodel.dart` |
| 9 | No conversation_id tracking | `agent_socket_service.dart` |
| 10 | connectivity_plus unused | `pubspec.yaml` |

### P2 — Spec Compliance

| # | Issue | File |
|---|-------|------|
| 11 | Quick suggestion chips wrong | `chat_page.dart:210-212` |
| 12 | "Lupa password?" should navigate | `login_page.dart:161-167` |
| 13 | No reconnect-on-foreground | `agent_socket_service.dart` |
| 14 | KnowledgePage dead code | `knowledge_page.dart` |

### P3 — Code Quality

| # | Issue | File |
|---|-------|------|
| 15 | No `toJson` on any model | All `core/models/*` |
| 16 | No freezed/codegen | All models |
| 17 | No LayoutBuilder usage | All pages |
| 18 | No i18n infrastructure | — |
| 19 | Inadequate test coverage | `test/` |
| 20 | _StatsRow mislabel | `profile_page.dart` |

---

*Laporan ini digenerate otomatis dari analisis docs/specification/ (18 docs), docs/contract/ (7 docs), client/.agents/skills/ (10 skills), dan source code client/lib/.*
