# 18 — Halaman Profile + Knowledge Upload

## Tujuan

Menampilkan informasi akun siswa/pengajar: biodata, statistik penggunaan, logout, dan (untuk pengajar) mengelola materi knowledge base via upload file.

## Komponen / Isi Utama

**Route**: `/home/profile` (nama: `profileTab`, tab ke-4 bottom nav).

**Widget tree**:
```
ProfilePage (ConsumerWidget)
├── appBar: AppBar(title: "Profil", settings → snackbar)
└── SingleChildScrollView
    └── Column
        ├── ProfileHeader (CircleAvatar initials, name, email, role badge)
        ├── BiodataCard (name, email, role, join date)
        ├── Stats Cards (conversations, predictions, avg lulus)
        ├── KnowledgeManagementSection (pengajar only)
        │   ├── Header + Upload button
        │   └── Document list (icon, title, chunks/size, status badge, popup delete)
        ├── SettingsCard (notifications, language, theme, help — placeholder)
        ├── LogoutButton (confirmation dialog)
        └── App version
```

**Sub-widgets** (Modular widgets are extracted under `client/lib/features/profile/widgets/`):
- `ProfileHeader` -> [profile_header.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/profile/widgets/profile_header.dart)
- `BiodataCard` -> [biodata_card.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/profile/widgets/biodata_card.dart)
- `StatsRow` -> [stats_row.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/profile/widgets/stats_row.dart)
- `KnowledgeManagementSection` -> [knowledge_management_section.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/profile/widgets/knowledge_management_section.dart)
- `SettingsCard` -> [settings_card.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/profile/widgets/settings_card.dart)
- `LogoutButton` -> [logout_button.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/profile/widgets/logout_button.dart)
- `ProfileShimmers` -> [profile_shimmers.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/profile/widgets/profile_shimmers.dart)


**KnowledgeUploadSheet** — modal bottom sheet with form (title, author, description, tags) + file picker (PDF/DOCX/TXT/MD) + upload via Dio multipart.

## Catatan Interaksi

- Role badge: siswa → primary bg light, pengajar → accentBlue bg light.
- Logout → confirmation dialog, clear tokens, invalidate providers, go to login.
- Knowledge upload → file picker, upload via multipart, refresh list.
- Delete document → confirmation dialog, DELETE call, invalidate list.
- Settings tiles → all show "Pengaturan ini akan tersedia segera" snackbar.
