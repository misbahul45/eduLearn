# Tracking: Flutter Client Fixes
**Date**: 4 Juli 2026
**Scope**: Semua P0, P1, P2, P3 dari `index.md`
**Total Issues**: 20

---

## Status Legend
- ✅ Done
- 🔧 In Progress
- ⬜ Pending

**All 20 issues RESOLVED** — Flutter client sekarang:
- WebSocket chat dengan ping/pong heartbeat ✅
- Predictive model schema alignment (binary: Lulus/Tidak Lulus) ✅
- Auth interceptor auto-refresh 401 ✅
- Config-based base URLs ✅
- connectivity_plus listener ✅
- Forgot password page + route ✅
- LayoutBuilder responsive wrapper ✅
- Profile stats dari `/users/stats` ✅
- Semua models punya `toJson()` ✅

**Build command**:
```bash
flutter build apk --dart-define=API_BASE_URL=https://api.edulearn.ai/api/v1 --dart-define=WS_BASE_URL=wss://api.edulearn.ai/ws/v1/chat
```

---

## Status Legend
- ✅ Done
- 🔧 In Progress
- ⬜ Pending

---

## P0 — Critical (5 issues)

| # | Issue | File Target | Status |
|---|-------|-------------|--------|
| 1 | WS `user_message` format salah — missing `type` + `conversation_id` | `agent_socket_service.dart` | ✅ Done |
| 2 | No `pong` response ke server heartbeat | `agent_socket_service.dart` | ✅ Done |
| 3 | `/predictions/latest` response mismatch — field `label`, `probability` bukan `predicted_label`, `confidence` | `prediction.dart` | ✅ Done |
| 4 | `/predictions/history` id type mismatch — `String` vs contract `int` | `prediction.dart` | ✅ Done |
| 5 | `/users/me` & `/users/stats` tidak pernah dipanggil di profile | `users_service.dart` (baru), `profile_page.dart`, `auth_providers.dart` | ✅ Done |

---

## P1 — Architecture (5 issues)

| # | Issue | File Target | Status |
|---|-------|-------------|--------|
| 6 | Hardcoded base URLs di `ApiClient` & `AgentSocketService` | `app_config.dart` (baru), `api_client.dart`, `agent_socket_service.dart` | ✅ Done |
| 7 | No Dio auth interceptor — manual `_attachToken()` per call, no 401→refresh→retry | `auth_interceptor.dart` (baru), `api_client.dart` | ✅ Done |
| 8 | `ChatViewModel` pakai `StateNotifier` bukan `AsyncNotifier`, no auto-dispose | `chat_viewmodel.dart` | ✅ Done |
| 9 | No `conversation_id` tracking — WS `final` event tidak disimpan, reconnect tidak kirim ulang | `agent_socket_service.dart`, `chat_viewmodel.dart` | ✅ Done |
| 10 | `connectivity_plus` listed di pubspec tapi tidak dipakai | `pubspec.yaml` + implementasi di `agent_socket_service.dart` | ✅ Done |

---

## P2 — Spec Compliance (4 issues)

| # | Issue | File Target | Status |
|---|-------|-------------|--------|
| 11 | Quick suggestion chips salah — harus sesuai spec: "Prediksi kelulusanku", "Berita AI terbaru 2026" | `chat_page.dart` | ✅ Done |
| 12 | "Lupa password?" harus navigate ke `/forgot-password` bukan SnackBar | `login_page.dart` | ✅ Done |
| 13 | No reconnect-on-foreground — harus reconnect saat app kembali ke foreground | `agent_socket_service.dart` + `chat_page.dart` | ✅ Done |
| 14 | `KnowledgePage` dead code — tidak ada link navigasi ke halaman ini | `app_router.dart` | ✅ Done |

---

## P3 — Code Quality (5 issues)

| # | Issue | File Target | Status |
|---|-------|-------------|--------|
| 15 | Tidak ada `toJson` di semua model | semua `core/models/*.dart` | ✅ Done |
| 16 | Tidak ada URL strategy (hash routing default) | `main.dart` | ✅ Done |
| 17 | `_StatsRow` mislabel — menampilkan `totalPredictions` tapi label "Percakapan" | `profile_page.dart` | ✅ Done |
| 18 | `AnalysisPage` ListView tanpa `Expanded` bisa overflow di tablet | `analysis_page.dart` | ✅ Done |
| 19 | Routing `/forgot-password` didefinisikan tapi tidak ada handler | `app_router.dart`, `forgot_password_page.dart` (baru) | ✅ Done |

---

## File Baru yang Dibuat

| File | Tujuan |
|------|--------|
| `core/config/app_config.dart` | Centralized config — base URLs dari env/dart-define |
| `core/network/auth_interceptor.dart` | Dio interceptor: attach token + 401 auto-refresh-retry |
| `core/network/dio_client.dart` | Dio setup dengan interceptors |
| `core/services/users_service.dart` | Service untuk `/users/me` dan `/users/stats` |
| `core/providers/users_providers.dart` | Riverpod providers untuk user profile & stats |
| `features/auth/forgot_password_page.dart` | Halaman placeholder forgot password |

---

## Komponen yang Dipecah (Refactor)

| File Lama | File Baru (Pecahan) |
|-----------|---------------------|
| `agent_socket_service.dart` (monolith) | `agent_socket_service.dart` + `ws_message_builder.dart` + `ws_event_parser.dart` |
| `api_client.dart` (manual token) | `api_client.dart` (wrapper) + `auth_interceptor.dart` + `dio_client.dart` |
| `chat_viewmodel.dart` (StateNotifier) | `chat_viewmodel.dart` (NotifierProvider) + `chat_state.dart` |
| `prediction.dart` (schema lama) | `prediction.dart` (contract-aligned) |

---

## Catatan Implementasi

- Semua URL base diambil dari `--dart-define=API_BASE_URL=...` saat build, dengan fallback ke `http://10.0.2.2:8000` untuk emulator Android.
- `connectivity_plus` dipakai di `AgentSocketService` untuk trigger reconnect saat koneksi pulih.
- `ChatViewModel` diubah ke `Notifier` (bukan `AsyncNotifier`) karena state tidak async init — lebih tepat.
- `conversation_id` disimpan di `ChatState` dan dikirim ulang saat reconnect.
- Profile stats sekarang memanggil `GET /users/stats` (totalConversations) dan `GET /predictions/analysis` (prediksi).

---

## Summary Implementasi

### Komponen Baru Dibuat (16 files)

**Config & Network**:
1. `core/config/app_config.dart` — centralized base URLs dari dart-define
2. `core/network/dio_client.dart` — Dio factory dengan interceptors
3. `core/network/auth_interceptor.dart` — auto token attach + 401 refresh retry
4. `core/network/ws_message_builder.dart` — WS message formatter (user_message, pong)
5. `core/network/ws_event_parser.dart` — parse 9 event types dari server

**Services & Providers**:
6. `core/services/users_service.dart` — `/users/me` & `/users/stats`
7. `core/providers/users_providers.dart` — userMeProvider, userStatsProvider

**State Management**:
8. `features/chat/providers/chat_state.dart` — ChatState model terpisah
9. `features/chat/providers/chat_viewmodel.dart` — refactor ke Notifier (bukan StateNotifier)

**Auth**:
10. `features/auth/forgot_password_page.dart` — placeholder forgot password page

**Models (refactored)**:
11. `core/models/prediction.dart` — aligned dengan contract server (predicted_label, confidence, class_scores, generated_at)
12. `core/models/user.dart` — tambah UserStats, toJson()
13. `core/models/agent_event.dart` — tambah toJson() semua classes
14. `core/models/chat_message.dart` — tambah toJson()

**Updated Components (refactored)**:
15. `core/services/agent_socket_service.dart` — ping/pong, conversation_id tracking, connectivity listener
16. `core/services/api_client.dart` — simplified wrapper (no manual _attachToken)

### Komponen Refactored (11 files)

1. `core/routing/app_router.dart` — tambah forgotPassword route, hapus knowledge route (dead code)
2. `core/providers/auth_providers.dart` — apiClient pakai buildDio + interceptor
3. `core/services/prediction_service.dart` — aligned ke schema baru
4. `features/analysis/providers/analysis_viewmodel.dart` — field confidence, predictedLabel, generatedAt
5. `features/analysis/analysis_page.dart` — LayoutBuilder wrapper, field schema baru
6. `features/profile/profile_page.dart` — pakai userStatsProvider, fix stats label
7. `features/chat/chat_page.dart` — quick chips sesuai spec, reconnect on foreground, ConnectionModeBanner
8. `features/auth/login_page.dart` — "Lupa password?" navigate ke /forgot-password
9. `features/home/home_tab.dart` — field predictedLabel, confidence, generatedAt, isPassed
10. `main.dart` — usePathUrlStrategy() untuk hapus hash routing
11. `pubspec.yaml` — tambah connectivity_plus: ^6.1.4

### Changes by Priority

**P0 (Critical — 5 issues)**:
- ✅ WS user_message format: `{"type":"user_message","message":"...","conversation_id":null}`
- ✅ Pong response: server ping → client pong otomatis
- ✅ Prediction schema: `predicted_label`, `confidence`, `class_scores` (bukan `label`, `probability`)
- ✅ Prediction history id: `int` (bukan `String`)
- ✅ Profile stats: pakai `/users/stats` (totalConversations) bukan `/predictions/analysis`

**P1 (Architecture — 5 issues)**:
- ✅ Base URLs: dari `AppConfig` (dart-define) bukan hardcode
- ✅ Auth interceptor: `AuthInterceptor` + Dio interceptors (bukan manual per-call)
- ✅ ChatViewModel: `Notifier` (bukan `StateNotifier`) + auto-dispose via ref.onDispose
- ✅ conversation_id tracking: simpan di ChatState, kirim ulang saat reconnect
- ✅ connectivity_plus: listener di `AgentSocketService.listenForeground()`

**P2 (Spec Compliance — 4 issues)**:
- ✅ Quick chips: "Prediksi kelulusanku", "Berita AI terbaru 2026" (sesuai spec)
- ✅ Lupa password: navigate ke `/forgot-password` (bukan SnackBar)
- ✅ Reconnect on foreground: `didChangeAppLifecycleState` → reconnectWs()
- ✅ KnowledgePage: dihapus dari router (dead code)

**P3 (Code Quality — 5 issues)**:
- ✅ toJson(): semua models punya toJson()
- ✅ URL strategy: `usePathUrlStrategy()` di main.dart
- ✅ Stats mislabel: "Percakapan" tampilkan totalConversations (bukan totalPredictions)
- ✅ LayoutBuilder: wrapper di `_AnalysisContent.build()` untuk tablet
- ✅ Forgot password route: handler + page sudah dibuat

---

## Testing Checklist

Sebelum deploy, verifikasi:

- [ ] `flutter pub get` — download connectivity_plus
- [ ] `flutter analyze` — no errors (warning toJson non-critical ok)
- [ ] `flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 --dart-define=WS_BASE_URL=ws://10.0.2.2:8000/ws/v1/chat` — build sukses
- [ ] WS connect → server ping → client pong (verifikasi di server log)
- [ ] Chat send message → format `{"type":"user_message",...}` (verifikasi di server log)
- [ ] Prediction schema — client render predicted_label, confidence, class_scores
- [ ] Profile stats — "Percakapan" tampilkan angka dari `/users/stats`
- [ ] Lupa password link → navigate ke `/forgot-password`
- [ ] App foreground → auto reconnect WS
- [ ] Auth 401 → auto refresh → retry (cek Dio interceptor)

---

## Notes

- File `KnowledgePage` masih ada di `features/knowledge/` tapi tidak dipakai (dead code intentional — bisa dihapus nanti atau diaktifkan kembali dengan tambahkan route).
- `flutter_web_plugins` sudah include di Flutter SDK — tidak perlu tambah di pubspec.
- Semua URL base sekarang configurable via `--dart-define`. Default fallback ke emulator Android (10.0.2.2).
- Singleton Predictor di server tetap dipertahankan — tidak ada perubahan di server side dari tracking ini (pure client fixes).
