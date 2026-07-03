# Overview & Tujuan Sistem

## Tujuan Sistem

EduLearn AI adalah backend edukasi + aplikasi mobile "Smart Academic Learning Assistant" yang memadukan empat lapis kecerdasan:

1. **Retrieval-Augmented Generation (RAG)** — mengambil referensi akademis dari basis pengetahuan berbasis **pgvector (PostgreSQL)** untuk menjawab pertanyaan konsep. Basis pengetahuan diisi via **API upload file** (lihat `11-file-upload.md`).
2. **Predictive ML inference** — model **Deep MLP (TensorFlow)** yang memprediksi `course_completed` (binary: Lulus/Tidak Lulus) berdasarkan data analytics pembelajaran siswa (time_spent, video_completion_rate, quiz_attempts, dll.). Detail di `06-ml-prediction.md`.
3. **Web Search (Firecrawl)** — tool tambahan untuk mencari informasi terkini di web saat RAG lokal tidak punya jawaban. Detail di `07-firecrawl-tool.md`.
4. **LLM reasoning (LangGraph ReAct)** — supervisor yang menalar pertanyaan siswa, memutuskan tool mana yang dipakai (RAG, prediksi, Firecrawl, atau langsung jawab), boleh berulang, lalu menyusun jawaban akademis.

## Pengguna Utama

- **Siswa** — bertanya konsep, menerima prediksi kelulusan, melihat referensi lokal & web.
- **Pengajar** — (perluasan masa depan) melihat trace reasoning agent untuk audit jawaban, upload materi ke knowledge base.

## Value Proposition Agentic Chatbot untuk Edukasi

- **Transparansi proses**: siswa tidak hanya menerima jawaban final, tetapi juga melihat langkah reasoning agent (`Menganalisis pertanyaan… → Mengambil referensi lokal… → Mencari di web… → Menjalankan model prediksi… → Menyusun jawaban…`). Ini penting untuk edukasi karena proses berpikir sama pentingnya dengan jawaban.
- **Personalisasi melalui ML**: jawaban akhir dipersonalisasi berdasarkan prediksi `course_completed` siswa. Bila prediksi "Tidak Lulus", jawaban LLM diberi penjelasan lebih dasar & saran latihan tambahan.
- **Hybrid knowledge**: kombinasi RAG lokal (materi yang diupload pengajar) + Firecrawl web search (info terkini) memastikan jawaban selalu relevan.
- **Realtime**: jawaban di-stream token-per-token, trace agent juga stream live. Siswa tidak menunggu 5–10 detik seperti REST klasik.

## Komponen Sistem Tingkat Tinggi

| Entitas | Deskripsi |
|---|---|
| `User` | Siswa/pengajar, autentikasi via JWT |
| `Conversation` | Sesi chat, punya `conversation_id` UUID, state disimpan di Redis lintas koneksi |
| `Prediction` | Output binary classifier (Lulus/Tidak Lulus) + probability + class_scores |
| `Citation` | Referensi RAG lokal (dari dokumen yang diupload) |
| `WebSearchResult` | Hasil Firecrawl web search (URL + judul + snippet markdown) |
| `KnowledgeDocument` | File yang diupload pengajar/siswa, di-chunk + embed, disimpan di pgvector |

## Wireframe Alur Penggunaan Tipikal

```
┌───────────────────────────────────────────────┐
│  EduLearn AI                                  │
│  Smart Academic Learning Assistant            │
├───────────────────────────────────────────────┤
│  USER STORY                                   │
│  Siswa bertanya "Apa itu neural network?"     │
│         │                                     │
│         ▼                                     │
│  Agent menganalisis → perlu RAG lokal         │
│         │                                     │
│         ▼                                     │
│  RAG menemukan 2 referensi di materi upload   │
│         │                                     │
│         ▼                                     │
│  Agent butuh info terkini → Firecrawl search  │
│         │                                     │
│         ▼                                     │
│  Firecrawl menemukan 1 artikel web terkini    │
│         │                                     │
│         ▼                                     │
│  Agent cek riwayat siswa → predictive tool    │
│         │                                     │
│         ▼                                     │
│  Prediksi: "Lulus" (prob 0.87)                │
│         │                                     │
│         ▼                                     │
│  LLM menyusun jawaban + sitasi lokal + web    │
│  → stream token ke siswa                      │
└───────────────────────────────────────────────┘
```

## Catatan

- Prioritas pengembangan: pengalaman siswa dulu (chat realtime + prediksi + RAG), pengajar (upload knowledge + audit) kemudian.
- Semua fitur "masa depan" (mis. multi-language, voice input, moodle integration) **tidak** masuk scope dokumen ini.
- Audit log sebagai pondasi fitur pengajar ada di `10-security.md` §10.6.
