# 14 — Halaman Register

## Tujuan

Mendaftarkan akun baru siswa/pengajar. Halaman ini sudah ada sebagai stub di Progress 2; dokumen ini menambahkan integrasi Riverpod ViewModel, AuthRepository, secure storage, dan error handling yang lengkap.

## Komponen / Isi Utama

**Route**: `/register` (nama: `register`).

**Widget tree**:
```
RegisterPage (ConsumerStatefulWidget — perlu Form key & focus node)
└── Scaffold
    ├── backgroundColor: AppColors.background
    └── SafeArea
        └── SingleChildScrollView
            └── Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg))
                └── Column(crossAxisAlignment: stretch)
                    ├── SizedBox(height: AppSpacing.xxl)
                    ├── Icon(Icons.smart_toy_rounded, size: 64, color: AppColors.primary)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── Text("Buat Akun Baru", style: AppTextStyles.h1)
                    ├── SizedBox(height: AppSpacing.xs)
                    ├── Text("Mulai perjalanan belajarmu", style: AppTextStyles.body, color: AppColors.textSecondary)
                    ├── SizedBox(height: AppSpacing.xl)
                    ├── Form(key: _formKey)
                    │   ├── AppTextField(label: "Nama Lengkap", hint: "Budi Santoso", validator: nameValidator)
                    │   ├── SizedBox(height: AppSpacing.md)
                    │   ├── AppTextField(label: "Email", hint: "nama@email.com", keyboardType: email, validator: emailValidator)
                    │   ├── SizedBox(height: AppSpacing.md)
                    │   ├── AppTextField(label: "Password", hint: "••••••••", obscure: true, suffixIcon: eye toggle, validator: passwordValidator)
                    │   └── SizedBox(height: AppSpacing.md)
                    │   └── AppTextField(label: "Konfirmasi Password", hint: "••••••••", obscure: true, suffixIcon: eye toggle, validator: confirmValidator)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── AppButton(label: "Daftar", isLoading: state.isLoading, onPressed: _submit)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── Row(children: [Expanded(Divider), Padding(Text("atau")), Expanded(Divider)])
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── SocialButton(label: "Daftar dengan Google", onPressed: → snackbar "coming soon")
                    ├── SizedBox(height: AppSpacing.xl)
                    └── Row(mainAxisAlignment: center, children: [Text("Sudah punya akun? "), TextButton(onPressed: → /login, child: Text("Masuk", style: AppTextStyles.link))])
```

**Riverpod providers**:
- `registerViewModelProvider` — `AsyncNotifier<RegisterState>` dengan state `{idle, loading, success, error(String)}`.
- `authRepositoryProvider` — panggil REST `POST /api/v1/auth/register` → `{ access_token, refresh_token, user }`; simpan ke `FlutterSecureStorage`.

**Behavior flow**:
1. User isi nama, email, password, konfirmasi password, tap "Daftar".
2. `_formKey.currentState!.validate()` — bila gagal, tampilkan error per field via `AppTextField` validator.
3. Disable keyboard, `ref.read(registerViewModelProvider.notifier).register(name, email, password)`.
4. ViewModel set `loading` → `AppButton` tampil spinner.
5. Bila sukses: simpan token ke secure storage, `context.go('/home')` (replace).
6. Bila gagal: tampilkan SnackBar dengan pesan dari server, kembali ke `idle`.

## Data / Kontrak yang Terlibat

- Input DTO: `RegisterRequest { name: str, email: str, password: str }`.
- Output DTO: `AuthResponse { access_token: str, refresh_token: str, user: User }`.
- REST: `POST /api/v1/auth/register`.
- Validasi client: email regex `^[^@]+@[^@]+\.[^@]+$`, password min 8 char, confirm password harus sama.
- `User` model: `{ user_id: str, name: str, email: str, role: str }`.

## Wireframe

```
┌─────────────────────────┐
│         🤖              │
│     Buat Akun Baru      │
│ Mulai perjalanan belajar │
│                         │
│ Nama Lengkap            │
│ ┌─────────────────────┐ │
│ │ Budi Santoso        │ │
│ └─────────────────────┘ │
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
│                         │
│ Konfirmasi Password 👁  │
│ ┌─────────────────────┐ │
│ │ ••••••••            │ │
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │       Daftar        │ │
│ └─────────────────────┘ │
│                         │
│ ─────── atau ───────    │
│                         │
│ ┌─────────────────────┐ │
│ │  G  Daftar Google   │ │
│ └─────────────────────┘ │
│                         │
│   Sudah punya akun? Masuk│
└─────────────────────────┘
```

## Catatan Interaksi

- Setiap password field wajib ada toggle visibility (eye icon) independen — default `obscure: true`.
- Loading state di `AppButton` disable semua input (tidak bisa double-submit).
- Setelah sukses register, user langsung login (token disimpan) — tidak perlu verified email dulu di versi ini.
- Bila server 409, SnackBar tampilkan "Email sudah terdaftar".
- Bila server 5xx, SnackBar tampilkan "Server sedang bermasalah, coba lagi".
- Bila tidak ada koneksi internet, SnackBar tampilkan "Tidak ada koneksi internet" + tombol retry.
