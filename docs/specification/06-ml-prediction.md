# ML Prediction (Binary Classification)

## Tujuan

Mendefinisikan spesifikasi ML model EduLearn AI **sesuai notebook asli** (`ml-prak-uas(1).ipynb`): task, dataset, pipeline, artifacts, inference flow, dan payload output. Halaman ini adalah rujukan untuk `app/machine_learning/predictor.py` & `app/agent/tools/predictive_tool.py`.

## Task ML

**Binary classification** `course_completed`:
- Label `0` → "Tidak Lulus"
- Label `1` → "Lulus"

> ⚠️ **Penting**: Ini BUKAN 3-class (Dikuasai/Perlu Latihan/Belum Dikuasai) seperti draft awal. Notebook asli jelas binary. UI & event schema wajib konsisten dengan ini.

## Dataset

- **Sumber**: `digital_learning_analytics_100k.csv` (100.000 baris, 43 kolom)
- **Target**: `course_completed` (int 0/1)
- **Drop kolom** (5 kolom: ID, tanggal, leakage):
  - `learner_id`
  - `enrollment_date`
  - `last_activity_date`
  - `human_grader_score` (data leakage)
  - `automated_score` (data leakage)

## Feature Engineering

### Numerik (median impute → StandardScaler)

Contoh (final list dari `pipeline.joblib` → `bundle['num_cols']`):
- `time_spent_minutes`
- `video_completion_rate`
- `video_watched_count`
- `quiz_attempts`
- `quiz_score_avg`
- `quiz_score_max`
- `forum_posts`
- `forum_replies`
- `assignment_submitted`
- `assignment_score_avg`
- `login_count`
- `days_active`
- `study_streak`
- ... (total ~30+ fitur numerik, sesuai notebook)

### Ordinal (mode impute → OrdinalEncoder → StandardScaler)

```python
ordinal_map = {
    'education_level': ['High School', 'Some College', "Bachelor's", 'Graduate', 'Doctoral'],
    'learning_path_type': ['Linear', 'Branched', 'Adaptive'],
}
```

### Nominal (mode impute → OneHotEncoder)

Kolom kategorikal lainnya (mis. `course_category`, `device_type`, `region`) — di-OneHot encode.

### Dimensionality Reduction

Benchmark 4 teknik di notebook:
1. **PCA** — 95% varians, dipilih sejumlah `n_pca` komponen
2. **LDA** — 1 komponen (binary class separability)
3. **PCA + LDA hybrid** — `n_pca + 1` komponen
4. **Autoencoder (PyTorch)** — `AE_LATENT` dimensi

Yang terbaik disimpan di `bundle['best_dr']` & objeknya di `bundle['pca']` / `bundle['lda']`.

### Imbalance Handling

`SMOTETomek` diterapkan di training set saja (anti data leakage). Disimpan di `bundle['smote']` (tidak dipakai saat inference, hanya metadata).

## Model Arsitektur

### Model terbaik: Deep MLP (TensorFlow/Keras)

```python
model_tf = models.Sequential([
    layers.Input(shape=(INPUT_DIM,)),
    # Hidden 1
    layers.Dense(128, kernel_regularizer=regularizers.l2(0.001)),
    layers.BatchNormalization(),
    layers.Activation('relu'),
    layers.Dropout(0.4),
    # Hidden 2
    layers.Dense(64, kernel_regularizer=regularizers.l2(0.001)),
    layers.BatchNormalization(),
    layers.Activation('relu'),
    layers.Dropout(0.3),
    # Hidden 3
    layers.Dense(32, kernel_regularizer=regularizers.l2(0.001)),
    layers.BatchNormalization(),
    layers.Activation('relu'),
    layers.Dropout(0.2),
    # Output (binary)
    layers.Dense(1, activation='sigmoid'),
], name='DeepMLP')

model_tf.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.001),
    loss='binary_crossentropy',
    metrics=['accuracy', tf.keras.metrics.AUC(name='auc')],
)
```

- Optimizer: Adam, lr=0.001
- Loss: binary_crossentropy
- Callbacks: EarlyStopping (patience=12, restore_best_weights), ReduceLROnPlateau (factor=0.5, patience=6)
- Class weight: balanced (`total / (2 * count)` per class)

### Model alternatif: RNN (PyTorch)

Tidak dipakai di production (lebih lambat), tapi disimpan untuk perbandingan. Tidak perlu di-serve.

## Artifacts di `server/models/`

Sesuai `ls models/`:

| File | Asal dari notebook | Isi |
|---|---|---|
| `model.weights.h5` | `model_tf.save_weights(...)` (HDF5 format) | Hanya weights Deep MLP. Arsitektur direkonstruksi dari `config.json`. |
| `pipeline.joblib` | `joblib.dump(pipeline_bundle, ...)` (compress=3) | Bundle: `preprocessor`, `pca`, `lda`, `smote`, `best_dr`, `n_pca`, `ae_latent`, `input_features`, `target_col`, `num_cols`, `ordinal_cols`, `nominal_cols`, `ordinal_map`, `best_model_name`, `results`, `metadata` |
| `metadata.json` | Generated manual saat deploy | `{ "model_version": "1.0.0", "trained_at": "...", "metrics": { "accuracy": ..., "f1": ..., "auc": ... }, "input_features": [...] }` |
| `config.json` | `model_tf.get_config()` | Konfigurasi arsitektur Sequential untuk rekonstruksi via `keras.models.Sequential.from_config(config)` |

> Catatan: Notebook asli menyimpan `best_model.keras` (full model). Tapi user memilih format `model.weights.h5` (hanya weights) untuk ukuran file lebih kecil + rekonstruksi eksplisit via `config.json`. Predictor wajib reconstruct architecture dari `config.json` lalu `load_weights(model.weights.h5)`.

## Predictor Inference Flow

Lokasi: `app/machine_learning/predictor.py`

```python
class Predictor(metaclass=Singleton):
    """Singleton — load sekali saat startup, fail-fast bila gagal."""

    def __init__(self, model_dir: str):
        self.model_dir = Path(model_dir)
        self._load_artifacts()

    def _load_artifacts(self) -> None:
        # 1. Load pipeline bundle
        bundle_path = self.model_dir / "pipeline.joblib"
        self.bundle = joblib.load(bundle_path)

        # 2. Load metadata
        meta_path = self.model_dir / "metadata.json"
        self.metadata = json.loads(meta_path.read_text())

        # 3. Reconstruct model architecture dari config + load weights
        config_path = self.model_dir / "config.json"
        config = json.loads(config_path.read_text())
        self.model = keras.models.Sequential.from_config(config)
        weights_path = self.model_dir / "model.weights.h5"
        self.model.load_weights(weights_path)

        # 4. Extract pipeline components
        self.preprocessor = self.bundle["preprocessor"]
        self.pca = self.bundle.get("pca")
        self.lda = self.bundle.get("lda")
        self.best_dr = self.bundle["best_dr"]
        self.input_features = self.bundle["input_features"]
        self.num_cols = self.bundle["num_cols"]
        self.ordinal_cols = self.bundle["ordinal_cols"]
        self.nominal_cols = self.bundle["nominal_cols"]
        self.ordinal_map = self.bundle["ordinal_map"]

    def predict(self, student_signals: dict) -> PredictionResult:
        """
        student_signals: dict berisi raw features siswa.
                         Key wajib = self.input_features.
                         Missing key → NaN (imputer yang handle).
        """
        # 1. DataFrame dari dict (single row)
        df = pd.DataFrame([student_signals], columns=self.input_features)

        # 2. Preprocessor transform (impute + encode + scale)
        X_pre = self.preprocessor.transform(df)

        # 3. Dimensionality reduction
        if self.best_dr == "PCA":
            X_dr = self.pca.transform(X_pre)
        elif self.best_dr == "LDA":
            X_dr = self.lda.transform(X_pre)
        elif self.best_dr == "PCA+LDA":
            X_pca = self.pca.transform(X_pre)
            X_lda = self.lda.transform(X_pre)
            X_dr = np.hstack([X_pca, X_lda])
        else:
            X_dr = X_pre  # fallback (autoencoder tidak dipakai di inference default)

        # 4. Predict probability (sigmoid, single output)
        prob_lulus = float(self.model.predict(X_dr, verbose=0).ravel()[0])
        prob_tidak = 1.0 - prob_lulus

        # 5. Threshold 0.5 → label
        predicted_label = "Lulus" if prob_lulus >= 0.5 else "Tidak Lulus"
        confidence = prob_lulus if predicted_label == "Lulus" else prob_tidak

        return PredictionResult(
            predicted_label=predicted_label,
            confidence=round(confidence, 4),
            class_scores=[
                {"label": "Tidak Lulus", "score": round(prob_tidak, 4)},
                {"label": "Lulus", "score": round(prob_lulus, 4)},
            ],
            model_name=self.bundle["best_model_name"],
            model_version=self.metadata["model_version"],
            input_features_used=list(self.input_features),
            generated_at=datetime.now(timezone.utc),
        )
```

## Skema Output (Pydantic v2)

```python
# app/schemas/prediction.py
from datetime import datetime
from pydantic import BaseModel, Field


class ClassScore(BaseModel):
    label: str           # "Lulus" atau "Tidak Lulus"
    score: float         # [0, 1]


class PredictionResult(BaseModel):
    predicted_label: str          # "Lulus" | "Tidak Lulus"
    confidence: float             # [0, 1] — prob label yang dipilih
    class_scores: list[ClassScore]  # 2 item: [Tidak Lulus, Lulus]
    model_name: str               # "Deep MLP (TensorFlow)"
    model_version: str            # "1.0.0"
    input_features_used: list[str]
    generated_at: datetime


class StudentSignals(BaseModel):
    """Input schema untuk predictive_tool. Field wajib = input_features dari bundle.
    Sebagian besar field optional — imputer yang handle missing."""
    time_spent_minutes: float | None = None
    video_completion_rate: float | None = None
    video_watched_count: int | None = None
    quiz_attempts: int | None = None
    quiz_score_avg: float | None = None
    quiz_score_max: float | None = None
    forum_posts: int | None = None
    forum_replies: int | None = None
    assignment_submitted: int | None = None
    assignment_score_avg: float | None = None
    login_count: int | None = None
    days_active: int | None = None
    study_streak: int | None = None
    education_level: str | None = None      # High School/Some College/Bachelor's/Graduate/Doctoral
    learning_path_type: str | None = None   # Linear/Branched/Adaptive
    # ... field nominal lainnya sesuai bundle
```

## Tool Integration

`app/agent/tools/predictive_tool.py`:

```python
from langchain_core.tools import tool
from app.machine_learning.singleton import Predictor
from app.schemas.prediction import StudentSignals, PredictionResult


@tool
def predictive_tool(student_signals: StudentSignals) -> PredictionResult:
    """
    Prediksi course_completed (Lulus/Tidak Lulus) berdasarkan data analytics
    pembelajaran siswa. Pakai model Deep MLP (TensorFlow) yang sudah dilatih.

    Args:
        student_signals: Data pembelajaran siswa (time_spent, quiz_attempts,
                         education_level, dll.). Field boleh kosong, imputer
                         yang handle.

    Returns:
        PredictionResult dengan predicted_label, confidence, class_scores.
    """
    predictor = Predictor()  # singleton
    return predictor.predict(student_signals.model_dump())
```

## Sumber `student_signals`

Bila siswa bertanya "Apakah saya akan lulus?", supervisor perlu data signals. Sumber:

1. **Eksplisit di pesan siswa** — siswa sebut "sudah nonton 80% video, quiz 75". LLM parse ke `StudentSignals` (parsial).
2. **Dari database** — bila siswa punya `student_signals` table yang diisi oleh LMS (learning management system) integration. Query `SELECT * FROM student_signals WHERE user_id = $1 ORDER BY recorded_at DESC LIMIT 1`.
3. **Default placeholder** — bila tidak ada data, supervisor bisa skip `predictive_tool` dan jawab "Saya butuh data belajarmu untuk prediksi. Berapa menit kamu belajar minggu ini?".

Implementasi: supervisor system prompt menjelaskan kapan & bagaimana isi `student_signals`. LLM cerdas enough untuk parse natural language ke field schema.

## Metrics (dari notebook, untuk transparansi)

Disimpan di `metadata.json["metrics"]`:

```json
{
  "accuracy": 0.92,
  "precision": 0.91,
  "recall": 0.93,
  "f1_score": 0.92,
  "auc_roc": 0.97,
  "training_time_sec": 45.2
}
```

## Catatan

- Singleton Predictor wajib dipertahankan — model dimuat **sekali** saat FastAPI startup via `lifespan`. Thread-safe via locking di metaclass.
- Bila load artifact gagal (file hilang, format rusak, TF version mismatch) → app crash di startup (fail-fast), tidak serve degraded response.
- ML layer **tidak tahu** soal LangGraph. `Predictor.predict()` adalah fungsi murni. Tool wrapper yang membungkusnya jadi LangChain tool.
- Inference di-run di thread pool (CPU-bound, blocking) — gunakan `await run_in_threadpool(predictor.predict, signals)`.
- Output probability dibulatkan ke 4 desimal untuk konsistensi. UI Flutter menampilkan sebagai persentase integer (`"${(prob*100).toInt()}%"`).
- Threshold 0.5 default. Bisa di-override via env `PREDICTION_THRESHOLD` (mis. 0.6 untuk lebih konservatif "Lulus").
- Tidak ada retraining di server. Update model = ganti artifact di `models/` + restart server.
