# 17 — Halaman Analysis (Visualisasi Prediksi Binary)

## Tujuan

Menampilkan analisis mendalam prediksi `course_completed` siswa: distribusi binary (Lulus/Tidak Lulus via donut chart), kekuatan & area perbaikan, rekomendasi aksi, dan perbandingan progress. Halaman ini membedah hasil prediksi yang ditampilkan ringkas di Home.

> Prediksi adalah **BINARY** (Lulus/Tidak Lulus). Jangan tampilkan 3 kelas.

## Komponen / Isi Utama

**Route**: `/home/analysis` (nama: `analysisTab`, tab ke-3 bottom nav).

**Widget tree**:
```
AnalysisPage (ConsumerWidget)
├── appBar: AppBar(title: Text("Analisis"))
└── SingleChildScrollView
    └── Column
        ├── DistributionCard (fl_chart PieChart donut, 2 segmen: success/error)
        ├── StrengthCard (success bg light)
        ├── ImprovementCard (warning bg light)
        ├── RecommendedActionsList (3 action items with navigation)
        ├── ProgressComparisonCard (yesterday vs today probability)
        └── PredictionHistoryList (max 30 items, visual threshold 0.5)
```

**Donut chart**: 2 segmen (Lulus success, Tidak Lulus error). Center text stack: "87%" + "Lulus".

**Strength card**: dynamic content based on feature importance (e.g., high video completion rate → "Ritme belajar konsisten...").

**Improvement card**: dynamic content for weak areas (e.g., low forum_posts → "Forum participation masih rendah...").

**Recommendations**: 3 items that navigate to chat with preset query, read materials, or placeholder for quiz.

**Progress comparison**: yesterday vs today probability with icon (trending_up/trending_down).

**History list**: per-item with date, label (Lulus/Tidak Lulus), probability. Items with prob < 0.5 → "Tidak Lulus" error color.

**Empty state** (no predictions yet): illustration + "Belum ada data analisis" + CTA "Tanya AI".

## Catatan Interaksi

- Donut: `centerSpaceRadius: 50`, Stack for center text.
- Warna: success (Lulus), error (Tidak Lulus) — 2 segment saja.
- Strength bg: `success.withOpacity(0.1)`, Improvement bg: `warning.withOpacity(0.1)`.
- Rekomendasi "Tanya AI" → navigate to chat with preset query auto-sent.
- Progress naik → success + trending_up; turun → error + trending_down; sama → "Tidak ada perubahan".
- History: visual threshold 0.5, items below → "Tidak Lulus" error.
