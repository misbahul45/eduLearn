# Konvensi & Token Desain (Acuan Bersama)

> File ini **wajib dibaca pertama** untuk developer Flutter. Semua halaman Flutter & kontrak backend memakai token di sini. Dilarang hardcode warna, spacing, text style, atau nilai konfigurasi di file lain.

## Palet Warna (`lib/core/theme/app_colors.dart`)

| Token | Hex | Penggunaan utama |
|---|---|---|
| `AppColors.primary` | teal-green gradient | CTA, brand, active state, ikon tab aktif |
| `AppColors.accentBlue` | biru aksen | Highlight sekunder, link alternatif |
| `AppColors.textPrimary` | #111827 | Judul & teks utama |
| `AppColors.textSecondary` | #6B7280 | Subtitle, deskripsi |
| `AppColors.textHint` | #9CA3AF | Placeholder input |
| `AppColors.textOnPrimary` | #FFFFFF | Teks di atas `primary` |
| `AppColors.background` | #F9FAFB | Background layar |
| `AppColors.surface` | #FFFFFF | Card, sheet, bubble |
| `AppColors.border` | #E5E7EB | Border input, divider |
| `AppColors.success` | hijau | Indikator "Lulus" / state sukses |
| `AppColors.error` | merah | Indikator "Tidak Lulus" / error |
| `AppColors.warning` | oranye | Indikator "Perlu Perhatian" / partial |

> Catatan: Karena ML EduLearn adalah **binary classification** (`course_completed` 0/1), hanya `success` (Lulus) dan `error` (Tidak Lulus) yang dipakai untuk label prediksi. Token `warning` hanya untuk state peringatan non-prediksi (mis. REST fallback mode, confidence rendah).

## Spacing & Radius (`lib/core/theme/app_spacing.dart`)

```
AppSpacing.xs=4  sm=8  md=16  lg=24  xl=32  xxl=48
AppRadius.sm=4   md=8   lg=16  full=9999
```

## Tipografi (`lib/core/theme/app_text_styles.dart`)

| Token | Spesifikasi | Penggunaan |
|---|---|---|
| `h1` | 24/bold | Judul halaman utama, angka besar di kartu prediksi |
| `h2` | 20/w600 | Section header |
| `subtitle` | 16/w500 | Subjudul kartu |
| `label` | 14/w500 | Label field, teks tab, judul item |
| `body` | 16/w400 | Teks body, isi bubble chat |
| `button` | 16/w600 | Teks tombol |
| `link` | 14/w600/primary | Teks link (Daftar, Masuk, Lupa password) |
| `caption` | 12/w400 | Teks kecil, timestamp, hint |

## Tema (`lib/core/theme/app_theme.dart`)

`ThemeData.light` dengan `colorScheme`, `textTheme`, `inputDecorationTheme`, `elevatedButtonTheme`, `textButtonTheme`, `dividerTheme` — semua merujuk token di atas. Tidak ada warna literal di luar file ini.

## Routing (`lib/core/routing/`)

`GoRouter` dengan konstanta route di `app_routes.dart`. Route yang ada:

| Nama | Path | File |
|---|---|---|
| `splash` | `/` | `12-flutter-splash.md` |
| `login` | `/login` | `13-flutter-login.md` |
| `register` | `/register` | `14-flutter-register.md` |
| `home` | `/home` (parent) | `15-flutter-home.md` |
| `home` (tab Home) | `/home` | `15-flutter-home.md` |
| `chat` (tab) | `/home/chat` | `16-flutter-chat.md` |
| `analysis` (tab) | `/home/analysis` | `17-flutter-analysis.md` |
| `profile` (tab) | `/home/profile` | `18-flutter-profile.md` |

`home` menjadi parent `StatefulShellRoute.indexedStack` dengan 4 branch tabs. State tiap tab di-preserve saat pindah tab.

## State Management — Riverpod

**Wajib** `flutter_riverpod` di seluruh halaman. Konvensi penamaan provider:

| Suffix | Tipe | Contoh |
|---|---|---|
| `*ViewModelProvider` | `AsyncNotifierProvider` untuk logika halaman | `loginViewModelProvider`, `chatViewModelProvider` |
| `*RepositoryProvider` | `Provider` untuk repository (REST call) | `authRepositoryProvider`, `predictionRepositoryProvider` |
| `*ServiceProvider` | `Provider` untuk service cross-cutting | `agentSocketServiceProvider`, `dioClientProvider` |
| `*StateProvider` | `StateProvider` untuk flag UI sederhana | `agentTraceSheetOpenProvider`, `connectionModeProvider` |

Tidak ada `setState` untuk state lintas-widget. `setState` hanya untuk animasi lokal atau controller UI murni (mis. `DraggableScrollableController`).

Untuk re-render granular (performa), gunakan `ref.watch(provider.select((s) => s.field))` supaya hanya field yang berubah yang trigger rebuild.

## Struktur Folder Flutter

```
lib/
├── main.dart
├── core/
│   ├── theme/           # app_colors, app_spacing, app_text_styles, app_theme
│   ├── routing/         # app_routes, app_router
│   ├── widgets/         # app_text_field, app_button, social_button, status_badge, ...
│   ├── network/         # dio_client, agent_socket_service, ws_reconnect
│   └── constants/       # app_constants (base url, timeout, retry policy)
├── features/
│   ├── splash/
│   ├── auth/            # login_page, register_page, auth_view_model, auth_repository
│   ├── home/            # home_page, home_view_model, prediction_repository
│   ├── chat/            # chat_page, agent_trace_sheet, status_badge, prediction_chart_card, citation_expansion_tile, web_search_tile, chat_bubble, chat_view_model, agent_socket_service
│   ├── analysis/        # analysis_page, analysis_view_model
│   └── profile/         # profile_page, profile_view_model, knowledge_upload_sheet
└── shared/              # model freezed AgentEvent, dto, Failure
```

## Konvensi Backend

- **Type hint penuh** di semua file Python.
- **Pydantic v2** untuk semua schema (request, response, event WS).
- **Async I/O** kecuali ML inference (CPU-bound, jalan di thread pool).
- **Tidak ada `global`** — semua via `pydantic-settings` & `infra/.env`.
- **Clean Architecture**: ML layer (`app/machine_learning/`) & RAG layer (`app/rag/`) **tidak boleh tahu** soal LangGraph. Mereka hanya expose fungsi `predict()` / `search()` / `ingest()`. Tool wrapper di `app/agent/tools/` yang memanggil mereka.
- **Singleton Predictor**: model dimuat sekali saat startup via `lifespan`. Bila gagal load, app crash (fail-fast).
- **Zero hardcoded config**: semua nilai (URL, max iter, heartbeat, rate limit) lewat `infra/.env` via `pydantic-settings`.

## Package Flutter Wajib

| Kebutuhan | Package |
|---|---|
| Routing | `go_router: ^14.2.7` |
| State management | `flutter_riverpod: ^2.5.1` |
| WebSocket | `web_socket_channel: ^3.0.0` |
| REST fallback | `dio: ^5.7.0` |
| Chart prediksi | `fl_chart: ^0.69.0` |
| JSON serialization | `freezed_annotation: ^2.4.4` + `json_serializable: ^6.8.0` (codegen via `build_runner`) |
| Secure storage (JWT) | `flutter_secure_storage: ^9.2.2` |
| File picker (upload) | `file_picker: ^8.1.2` |
| Connectivity check | `connectivity_plus: ^6.0.5` |

## Bahasa UI

Semua teks UI berbahasa Indonesia. Istilah teknis (WebSocket, ReAct, LangGraph, ReAct loop) tetap Inggris. Pesan error dari server wajib human-readable Indonesia (bukan exception class).

## Konsistensi Visual

- Border radius default: `AppRadius.md` (8) untuk input/button, `AppRadius.lg` (16) untuk card.
- Shadow: subtle (`elevation: 1-2` di Material 3), bukan drop shadow dramatis.
- Ikon: `Material Icons` rounded variant (mis. `Icons.home_rounded`, `Icons.chat_bubble_rounded`).
- Emoji: dipakai sparingly untuk tone (👋 halo, 🤖 assistant, 📊 prediksi), bukan untuk fitur inti.
