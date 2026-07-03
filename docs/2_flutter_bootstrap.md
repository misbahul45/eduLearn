# Progress 2: Flutter App Bootstrap — Design System & Routing

## Tracking Progress

| Progress | File | Status |
|----------|------|--------|
| 1 | `docs/1_setup_requirement.md` | Infrastructure & Docker setup |
| **2** | **`docs/2_flutter_bootstrap.md`** | **Flutter design system & routing (done)** |
| 3 | `docs/3_server_backend_setup.md` | Server AI backend architecture |

---

## Summary

Initial bootstrap of the **EduLearn AI** Flutter project — a mobile "Smart Academic Learning Assistant" app. Focused on the foundation that all screens will use:

### 1. Design Token System (`lib/core/theme/`)

| File | Contents |
|------|----------|
| `app_colors.dart` | 15 `Color` constants: primary (teal-green gradient), accentBlue, textPrimary, textSecondary, textHint, textOnPrimary, background, surface, border, success, error, warning |
| `app_spacing.dart` | `AppSpacing` (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48) + `AppRadius` (sm=4, md=8, lg=16, full=9999) |
| `app_text_styles.dart` | 8 `TextStyle` (h1, h2, subtitle, label, body, button, link, caption) — all using `AppColors`, zero hardcoded hex |
| `app_theme.dart` | `ThemeData.light` assembling tokens into: `colorScheme`, `textTheme`, `inputDecorationTheme`, `elevatedButtonTheme`, `textButtonTheme`, `dividerTheme` |

### 2. Routing Config (`lib/core/routing/`)

| File | Contents |
|------|----------|
| `app_routes.dart` | 4 route name + path string constants (`splash`, `login`, `register`, `home`) |
| `app_router.dart` | `GoRouter` with `initialLocation: '/'`, mapping each route to pages via `builder` |

### 3. Shared Widgets (`lib/core/widgets/`)

| File | Contents |
|------|----------|
| `app_text_field.dart` | Reusable `TextFormField` with label, hint, validator |
| `app_button.dart` | Reusable `ElevatedButton` with loading state (spinner) |
| `social_button.dart` | `OutlinedButton` with Google icon for future OAuth |

### 4. Stub Pages (`lib/features/`)

| Page | File | Features |
|------|------|----------|
| Splash | `splash/splash_page.dart` | Logo + auto-navigate to login (2s) |
| Login | `auth/login_page.dart` | Email/password form + validation, Google button placeholder, register link |
| Register | `auth/register_page.dart` | Name/email/password/confirm form + validation, Google button placeholder, login link |
| Home | `home/home_page.dart` | Simple welcome heading |

### 5. Entry Point (`lib/main.dart`)

`MaterialApp.router` with `theme: AppTheme.light` and `routerConfig: appRouter`.

### 6. Dependency

`go_router: ^14.2.7` added to `pubspec.yaml`.

---

## Verification

- `flutter pub get` — success, all dependencies resolved
- `flutter analyze` — **No issues found**
- Navigation: Splash → Login ↔ Register → Home (each form submit succeeds)

---

## Notes

- All colors are visual estimates. Verify actual hex values from Figma when available.
- Google sign-in is still a placeholder (snackbar "coming soon") — OAuth implementation to follow.
- No state management or network layer — pure UI + routing foundation.
