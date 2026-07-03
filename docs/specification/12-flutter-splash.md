# 12 — Halaman Splash

## Tujuan

Halaman pertama yang dilihat user saat app dibuka. Menampilkan branding, mengecek status autentikasi, dan memutuskan rute berikutnya (ke `/login` atau `/home`).

## Komponen

**Route**: `/` (name: `splash`)

**Widget tree**:
```
SplashPage (ConsumerStatefulWidget)
└── Scaffold
    ├── backgroundColor: AppColors.background
    └── SafeArea
        └── Center
            └── Column (mainAxisAlignment: center)
                ├── Icon(Icons.smart_toy_rounded, size: 96, color: AppColors.primary)
                ├── SizedBox(height: AppSpacing.lg)
                ├── Text("EduLearn AI", style: AppTextStyles.h1)
                ├── SizedBox(height: AppSpacing.xs)
                ├── Text("Smart Academic Learning Assistant", style: AppTextStyles.subtitle)
                ├── SizedBox(height: AppSpacing.xxl)
                └── CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)
```

**Riverpod providers**:
- `splashProvider` — `AsyncNotifier<SplashState>` dengan state `{initial, checking, authenticated, unauthenticated}`.
- `authRepositoryProvider` — instance `AuthRepository` (Dio + FlutterSecureStorage).

**Behavior flow**:
1. `initState` → `ref.read(splashProvider.notifier).check()`.
2. ViewModel baca token dari secure storage.
3. Bila token ada → panggil `/auth/me` (Dio, timeout 5s). 200 → `authenticated`; 401 → coba refresh; refresh gagal → `unauthenticated`.
4. Bila token tidak ada → langsung `unauthenticated`.
5. Setelah state final, tunggu minimal 2 detik, lalu `context.go('/login')` atau `context.go('/home')`.

## Data / Kontrak

- REST: `GET /api/v1/auth/me` → `{ id, name, email, role }`
- Lokal: `FlutterSecureStorage` key `access_token`, `refresh_token`

## Dependencies Baru

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.4
```
