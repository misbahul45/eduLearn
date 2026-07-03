# 15 — Halaman Home (Dashboard)

## Tujuan

Menjadi landing page setelah login. Memberikan ringkasan status belajar siswa: greeting personal, prediksi `course_completed` terbaru, insight singkat, dan riwayat aktivitas. Halaman ini juga menjadi **shell** untuk bottom navigation 4 tab (Home, Chat, Analysis, Profile).

## Komponen / Isi Utama

**Route**: `/home` (nama: `home`). Route `home` menjadi parent `StatefulShellRoute.indexedStack` dengan 4 branch (tabs):

```
/home            → HomeTab (dashboard)
/home/chat       → ChatTab
/home/analysis   → AnalysisTab
/home/profile    → ProfileTab
```

Bottom nav menggunakan `NavigationBar` (Material 3) dengan 4 `NavigationDestination`: Home (`Icons.home_rounded`), Chat (`Icons.chat_bubble_rounded`), Analysis (`Icons.insights_rounded`), Profile (`Icons.person_rounded`). Active state memakai `AppColors.primary`; inactive `AppColors.textSecondary`.

**Widget tree (HomeTab)**:
```
HomePage (ConsumerWidget)
└── Scaffold
    ├── backgroundColor: AppColors.background
    ├── appBar: AppBar(
    │     title: Text("EduLearn AI", style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
    │     backgroundColor: AppColors.surface,
    │     elevation: 0,
    │     actions: [IconButton(icon: Icons.notifications_outlined, → /notifications)]
    │   )
    └── body: SafeArea
        └── SingleChildScrollView
            └── Padding(padding: EdgeInsets.all(AppSpacing.lg))
                └── Column(crossAxisAlignment: stretch)
                    ├── GreetingCard (Card, surface, radius lg)
                    │   └── Row
                    │       ├── CircleAvatar (radius 24, primary bg, initial huruf nama)
                    │       ├── SizedBox(width: AppSpacing.md)
                    │       └── Column(crossAxisAlignment: start)
                    │           ├── Text("Halo, Budi! 👋", style: AppTextStyles.h2)
                    │           └── Text("Yuk lanjut belajar hari ini", style: AppTextStyles.body, color: textSecondary)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── PredictionSummaryCard (Card, primary bg, textOnPrimary)
                    │   └── Padding(AppSpacing.lg)
                    │       └── Row
                    │           ├── Column(crossAxisAlignment: start)
                    │           │   ├── Text("Prediksi Kelulusan", style: AppTextStyles.label, color: textOnPrimary 0.8 opacity)
                    │           │   ├── SizedBox(height: AppSpacing.xs)
                    │           │   ├── Text("Lulus", style: h1.copyWith(fontSize: 36, color: textOnPrimary))
                    │           │   └── Text("Confidence 87% · Model: Deep MLP", style: AppTextStyles.body, color: textOnPrimary 0.9)
                    │           └── Spacer
                    │           └── Icon(Icons.trending_up_rounded, size: 48, color: textOnPrimary)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── InsightCard (Card, success bg light, success text)
                    │   └── Padding(AppSpacing.lg)
                    │       └── Row
                    │           ├── Icon(Icons.lightbulb_rounded, color: success)
                    │           ├── SizedBox(width: AppSpacing.md)
                    │           └── Expanded
                    │               └── Text(Insight dinamis, style: AppTextStyles.body)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── Text("Riwayat Aktivitas", style: AppTextStyles.h2)
                    ├── SizedBox(height: AppSpacing.md)
                    ├── HistoryChartCard (Card, surface)
                    │   └── Padding(AppSpacing.lg)
                    │       └── Column
                    │           ├── SizedBox(height: 180, child: fl_chart LineChart probabilitas 7 hari terakhir)
                    │           ├── SizedBox(height: AppSpacing.md)
                    │           └── Row(mainAxisAlignment: spaceBetween)
                    │               ├── LegendItem(color: primary, label: "Probabilitas Lulus")
                    │               └── LegendItem(color: textHint, label: "Threshold (0.5)")
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── QuickActionsRow
                    │   └── Row(mainAxisAlignment: spaceBetween)
                    │       ├── QuickAction(icon: chat, label: "Tanya AI", → /home/chat)
                    │       ├── QuickAction(icon: insights, label: "Analisis", → /home/analysis)
                    │       └── QuickAction(icon: quiz, label: "Latihan", → snackbar "coming soon")
                    └── SizedBox(height: AppSpacing.xl)
```

**Behavior flow**: fetch paralel latest prediction + 7-day history + user; loading → skeleton; pull-to-refresh; null prediction → empty state with CTA.

## Catatan Interaksi

- `StatefulShellRoute.indexedStack` preserve state tiap tab saat pindah.
- Greeting pakai `CircleAvatar` inisial nama.
- Kartu prediksi: bg `AppColors.primary` saat "Lulus", tetap primary saat "Tidak Lulus" dengan ikon `trending_down_rounded`.
- Insight: bg `AppColors.success` (hijau muda) saat "Lulus" → teks motivasi; `AppColors.warning` (oranye muda) saat "Tidak Lulus" → teks saran perbaikan.
- Chart riwayat pakai `fl_chart` `LineChart` 1 series + threshold line di y=0.5.
- Quick action "Latihan" placeholder.
