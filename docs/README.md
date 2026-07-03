# EduLearn AI — Dokumentasi

Struktur dokumentasi proyek EduLearn AI.

## Struktur Folder

| Folder | Isi | Untuk |
|--------|-----|-------|
| `specification/` | Spesifikasi sistem: arsitektur, desain, komponen backend & Flutter | Developer memahami **apa** yang dibangun dan **bagaimana** seharusnya bekerja |
| `contract/` | Kontrak API: REST endpoint, WebSocket event, request/response schema | Flutter & Backend developer sebagai **acuan binding** integrasi |
| `progress/` | Status implementasi: apa yang sudah jadi, apa yang pending | Semua anggota tim untuk **tracking** progress |

## Cara Membaca

1. **Baru mulai?** Baca `specification/01-overview.md` dulu → gambaran besar sistem.
2. **Mau lihat arsitektur?** `specification/03-architecture.md` → diagram + data flow.
3. **Butuh kontrak API?** `contract/00-index.md` → daftar semua endpoint & event.
4. **Cek progress?** `progress/00-index.md` → status terkini tiap area.
5. **Mau coding?** Baca `specification/` file yang relevan → lalu `contract/` untuk schema → lalu implementasi.

## Konvensi Penamaan

- `specification/*.md` — nomor urut berdasarkan urutan baca: 00 (index), 01 (overview), 02 (design system), dst.
- `contract/*.md` — nomor urut berdasarkan endpoint: 01 (health), 02 (auth), dst.
- `progress/*.md` — nomor urut berdasarkan area: 00 (index), 01 (spec), 02 (contract), 03 (backend), dst.
- Setiap file punya header `# <nama>` dan penjelasan tujuan di paragraf pertama.
