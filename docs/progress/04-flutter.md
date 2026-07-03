# Progress — Flutter Implementation

## Status Per Area

| Area | Progress | Catatan |
|------|----------|---------|
| Design System | ✅ Done | Colors, spacing, typography, theme |
| Routing (GoRouter) | ✅ Done | splash, login, register, home, knowledge |
| Riverpod + Dio + SecureStorage | ✅ Done | ProviderScope, ApiClient, AuthRepository |
| Auth Providers (login/register/logout) | ✅ Done | `authNotifierProvider` — StateNotifier |
| Auth Models (User, AuthStatus) | ✅ Done | fromJson, AuthResult enum |
| Prediction Service + Provider | ✅ Done | latest, history, analysis via API |
| Chat Message Model | ✅ Done | ChatMessage fromJson |
| Splash Page | ✅ Done | Riverpod ViewModel, auto-routing (login/home) |
| Login Page | ✅ Done | Riverpod refactor — calls AuthRepository |
| Register Page | ✅ Done | Riverpod refactor — calls AuthRepository |
| Home Page | ✅ Done | 4 tabs: Chat, Analisis, Materi, Profil |
| Chat Page | ✅ Done | UI dengan empty state, bubble list, input |
| Analysis Page | ✅ Done | Stat cards, progress bar, latest prediction |
| Knowledge Page | ✅ Done | List dokumen, refresh, delete |
| Profile Page | ✅ Done | Avatar, stats, menu, logout |

## Yang Perlu Dikerjakan Nanti

- **WebSocket Chat** — integrasi WS nyata untuk streaming jawaban AI
- **Knowledge Upload** — form upload file (PDF/DOCX/TXT/MD) untuk pengajar
- **Image/File picker** di chat
- **Google Sign-In** — integrasi OAuth
- **Dark mode / Theme switching**
- **Offline mode** — local caching prediksi & materi
- **Push notifications**
