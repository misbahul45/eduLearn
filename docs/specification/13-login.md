# 13 — Halaman Login

## Tujuan

Memvalidasi identitas siswa/pengajar yang sudah terdaftar. Halaman ini sudah ada sebagai stub di Progress 2; dokumen ini menambahkan integrasi Riverpod ViewModel, AuthRepository, secure storage, dan error handling yang lengkap.

## Komponen / Isi Utama

**Route**: `/login` (nama: `login`).

**Widget tree**:
```
LoginPage (ConsumerStatefulWidget — perlu Form key & focus node)
└── Scaffold
    ├── backgroundColor: AppColors.background
    └── SafeArea
        └── SingleChildScrollView
            └── Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg))
                └── Column(crossAxisAlignment: stretch)
                    ├── SizedBox(height: AppSpacing.xxl)
                    ├── Icon(Icons.smart_toy_rounded, size: 64, color: AppColors.primary)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── Text("Selamat Datang Kembali", style: AppTextStyles.h1)
                    ├── SizedBox(height: AppSpacing.xs)
                    ├── Text("Masuk untuk melanjutkan belajar", style: AppTextStyles.body, color: AppColors.textSecondary)
                    ├── SizedBox(height: AppSpacing.xl)
                    ├── Form(key: _formKey)
                    │   ├── AppTextField(label: "Email", hint: "nama@email.com", keyboardType: email, validator: emailValidator)
                    │   ├── SizedBox(height: AppSpacing.md)
                    │   └── AppTextField(label: "Password", hint: "••••••••", obscure: true, suffixIcon: eye toggle, validator: passwordValidator)
                    ├── SizedBox(height: AppSpacing.sm)
                    ├── Align(alignment: Alignment.centerRight, child: TextButton(onPressed: → /forgot, child: Text("Lupa password?", style: AppTextStyles.link)))
                    ├── SizedBox(height: AppSpacing.md)
                    ├── AppButton(label: "Masuk", isLoading: state.isLoading, onPressed: _submit)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── Row(children: [Expanded(Divider), Padding(Text("atau")), Expanded(Divider)])
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── SocialButton(label: "Masuk dengan Google", onPressed: → snackbar "coming soon")
                    ├── SizedBox(height: AppSpacing.xl)
                    └── Row(mainAxisAlignment: center, children: [Text("Belum punya akun? "), TextButton(onPressed: → /register, child: Text("Daftar", style: AppTextStyles.link))])
```

**Riverpod providers**:
- `loginViewModelProvider` — `AsyncNotifier<LoginState>` dengan state `{idle, loading, success, error(String)}`.
- `authRepositoryProvider` — panggil REST `POST /api/v1/auth/login` → `{ access_token, refresh_token, user }`; simpan ke `FlutterSecureStorage`.

**Behavior flow**:
1. User isi email + password, tap "Masuk".
2. `_formKey.currentState!.validate()` — bila gagal, tampilkan error per field via `AppTextField` validator.
3. Disable keyboard, `ref.read(loginViewModelProvider.notifier).login(email, password)`.
4. ViewModel set `loading` → `AppButton` tampil spinner (loading state bawaan widget).
5. Bila sukses: simpan token ke secure storage, `context.go('/home')` (replace).
6. Bila gagal: tampilkan SnackBar dengan pesan dari server (mis. "Email atau password salah"), kembali ke `idle`.

## Data / Kontrak yang Terlibat

- Input DTO: `LoginRequest { email: str, password: str }`.
- Output DTO: `AuthResponse { access_token: str, refresh_token: str, user: User }`.
- REST: `POST /api/v1/auth/login`.
- Validasi client: email regex `^[^@]+@[^@]+\.[^@]+$`, password min 8 char.
- `User` model: `{ user_id: str, name: str, email: str, role: str }`.

## Wireframe

```
┌─────────────────────────┐
│         🤖              │
│ Selamat Datang Kembali  │
│ Masuk untuk melanjutkan │
│                         │
│ Email                   │
│ ┌─────────────────────┐ │
│ │ nama@email.com      │ │
│ └─────────────────────┘ │
│                         │
│ Password           👁   │
│ ┌─────────────────────┐ │
│ │ ••••••••            │ │
│ └─────────────────────┘ │
│                Lupa?    │
│                         │
│ ┌─────────────────────┐ │
│ │       Masuk         │ │
│ └─────────────────────┘ │
│                         │
│ ─────── atau ───────    │
│                         │
│ ┌─────────────────────┐ │
│ │  G  Masuk Google    │ │
│ └─────────────────────┘ │
│                         │
│  Belum punya akun? Daftar│
└─────────────────────────┘
```

## Catatan Interaksi

- Password field wajib ada toggle visibility (eye icon) — default `obscure: true`.
- Loading state di `AppButton` disable semua input (tidak bisa double-submit).
- Setelah sukses login, token disimpan di `FlutterSecureStorage` (bukan `SharedPreferences`) untuk security.
- Tidak ada fitur "remember me" eksplisit — refresh token 30 hari sudah cukup.
- Google sign-in masih placeholder sesuai Progress 2; implementasi asli di progress mendatang.
- Bila server 5xx, SnackBar tampilkan "Server sedang bermasalah, coba lagi" (bukan pesan teknis).
- Bila server 401, SnackBar tampilkan "Email atau password salah".
- Bila tidak ada koneksi internet, SnackBar tampilkan "Tidak ada koneksi internet" + tombol retry.
