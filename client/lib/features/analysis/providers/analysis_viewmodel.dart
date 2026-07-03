import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/prediction.dart';
import '../../../core/providers/prediction_providers.dart';

class Recommendation {
  final String id;
  final IconType icon;
  final String title;
  final String subtitle;
  final String actionType;
  final String actionPayload;

  const Recommendation({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionType,
    required this.actionPayload,
  });
}

enum IconType { chat, book, quiz }

class ProgressComparison {
  final double yesterdayProbability;
  final double todayProbability;

  const ProgressComparison({
    required this.yesterdayProbability,
    required this.todayProbability,
  });

  double get delta => todayProbability - yesterdayProbability;
}

class PredictionHistoryItem {
  final DateTime date;
  final String label;
  final double probability;

  const PredictionHistoryItem({
    required this.date,
    required this.label,
    required this.probability,
  });
}

class AnalysisData {
  final Prediction? latest;
  final PredictionAnalysis? analysis;
  final List<Prediction> history;

  const AnalysisData({
    this.latest,
    this.analysis,
    this.history = const [],
  });

  bool get hasData =>
      latest != null && latest!.predictedLabel.isNotEmpty;

  String get strength {
    if (!hasData) return 'Belum ada data untuk dianalisis.';
    final prob = latest!.confidence;
    if (prob >= 0.7) {
      return 'Ritme belajar konsisten. Probabilitas kelulusan di atas 70% menunjukkan performa yang baik.';
    } else if (prob >= 0.5) {
      return 'Kamu sudah berada di jalur yang tepat. Tingkatkan sedikit lagi untuk mencapai probabilitas yang lebih tinggi.';
    }
    return 'Kamu masih memiliki waktu untuk meningkatkan performa. Fokus pada penyelesaian video dan quiz secara konsisten.';
  }

  String get improvement {
    if (!hasData) {
      return 'Gunakan fitur chat dengan AI untuk mendapatkan saran belajar.';
    }
    final prob = latest!.confidence;
    if (prob < 0.7) {
      return 'Forum participation masih rendah. Disarankan aktif di diskusi forum untuk meningkatkan engagement.';
    }
    return 'Tingkatkan interaksi di forum diskusi untuk memperdalam pemahaman materi.';
  }

  List<Recommendation> get recommendations => [
        const Recommendation(
          id: 'chat_quiz',
          icon: IconType.chat,
          title: 'Tanya AI cara meningkatkan quiz score',
          subtitle: 'Chat dengan AI · 2 menit',
          actionType: 'chat',
          actionPayload: 'Cara meningkatkan quiz score',
        ),
        const Recommendation(
          id: 'read_material',
          icon: IconType.book,
          title: 'Baca materi yang relevan',
          subtitle: 'Modul 4 · 15 menit',
          actionType: 'chat',
          actionPayload: 'Materi apa saja yang perlu saya pelajari ulang?',
        ),
        const Recommendation(
          id: 'quiz_practice',
          icon: IconType.quiz,
          title: 'Latihan 5 soal',
          subtitle: 'Estimasi 20 menit',
          actionType: 'quiz',
          actionPayload: '',
        ),
      ];

  ProgressComparison? get progressComparison {
    if (history.length < 2) return null;
    return ProgressComparison(
      yesterdayProbability: history[history.length - 2].confidence,
      todayProbability: history.last.confidence,
    );
  }

  List<PredictionHistoryItem> get historyItems {
    return history.reversed
        .map(
          (p) => PredictionHistoryItem(
            date: p.generatedAt,
            label: p.predictedLabel,
            probability: p.confidence,
          ),
        )
        .toList();
  }
}

class AnalysisViewModel extends AsyncNotifier<AnalysisData> {
  @override
  Future<AnalysisData> build() async {
    final latest = await ref.watch(latestPredictionProvider.future);
    final analysis = await ref.watch(predictionAnalysisProvider.future);
    final history = await ref.watch(predictionHistoryProvider.future);
    return AnalysisData(latest: latest, analysis: analysis, history: history);
  }
}

final analysisViewModelProvider =
    AsyncNotifierProvider<AnalysisViewModel, AnalysisData>(
  AnalysisViewModel.new,
);
