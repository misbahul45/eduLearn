sealed class AgentEvent {
  final DateTime timestamp;
  const AgentEvent(this.timestamp);

  String get summary;
  String get detail;
}

class StateUpdateEvent extends AgentEvent {
  final String node;
  final String status;
  final int iteration;

  const StateUpdateEvent(
    this.node,
    this.status,
    this.iteration,
    super.timestamp,
  );

  @override
  String get summary => 'Node: $node → $status';

  @override
  String get detail => 'Iterasi ke-$iteration';
}

class ToolCallEvent extends AgentEvent {
  final String toolName;
  final Map<String, dynamic> input;
  final String callId;

  const ToolCallEvent(
    this.toolName,
    this.input,
    this.callId,
    super.timestamp,
  );

  @override
  String get summary => 'Tool dipanggil: $toolName';

  @override
  String get detail => 'Call ID: $callId';
}

class ToolResultEvent extends AgentEvent {
  final String toolName;
  final String callId;
  final String outputSummary;
  final int durationMs;

  const ToolResultEvent(
    this.toolName,
    this.callId,
    this.outputSummary,
    this.durationMs,
    super.timestamp,
  );

  @override
  String get summary => 'Tool selesai: $toolName';

  @override
  String get detail => '${durationMs}ms · $outputSummary';
}

class TokenEvent extends AgentEvent {
  final String content;
  final int index;

  const TokenEvent(this.content, this.index, super.timestamp);

  @override
  String get summary => 'Token ke-${index + 1}';

  @override
  String get detail => '';
}

class PredictionResultEvent extends AgentEvent {
  final PredictionResult data;

  const PredictionResultEvent(this.data, super.timestamp);

  @override
  String get summary => 'Prediksi: ${data.predictedLabel}';

  @override
  String get detail =>
      'Confidence: ${(data.confidence * 100).toStringAsFixed(1)}%';
}

class CitationEvent extends AgentEvent {
  final String sourceId;
  final String snippet;
  final double score;
  final CitationMeta metadata;

  const CitationEvent(
    this.sourceId,
    this.snippet,
    this.score,
    this.metadata,
    super.timestamp,
  );

  @override
  String get summary => 'Sumber ditemukan';

  @override
  String get detail => 'Score: ${(score * 100).toStringAsFixed(0)}%';
}

class WebSearchResultEvent extends AgentEvent {
  final String resultId;
  final String url;
  final String title;
  final String snippet;
  final String markdownExcerpt;
  final String source;
  final double relevanceScore;

  const WebSearchResultEvent(
    this.resultId,
    this.url,
    this.title,
    this.snippet,
    this.markdownExcerpt,
    this.source,
    this.relevanceScore,
    super.timestamp,
  );

  @override
  String get summary => 'Web search: $title';

  @override
  String get detail => source;
}

class FinalEvent extends AgentEvent {
  final String message;
  final String conversationId;
  final List<String> citations;
  final List<String> webResults;
  final bool predictionPresent;
  final String? predictionLabel;

  const FinalEvent(
    this.message,
    this.conversationId,
    this.citations,
    this.webResults,
    this.predictionPresent,
    this.predictionLabel,
    super.timestamp,
  );

  @override
  String get summary => 'Respon final diterima';

  @override
  String get detail => predictionPresent ? 'Mengandung prediksi' : '';
}

class AgentErrorEvent extends AgentEvent {
  final String? node;
  final String message;
  final bool fatal;

  const AgentErrorEvent(
    this.node,
    this.message,
    this.fatal,
    super.timestamp,
  );

  @override
  String get summary => 'Error: ${fatal ? "Fatal" : "Non-fatal"}';

  @override
  String get detail => message;
}

class CitationMeta {
  final String? title;
  final String? author;
  final int? page;
  final String? url;
  final String? documentId;
  final String? fileName;

  const CitationMeta({
    this.title,
    this.author,
    this.page,
    this.url,
    this.documentId,
    this.fileName,
  });

  factory CitationMeta.fromJson(Map<String, dynamic> json) {
    return CitationMeta(
      title: json['title'] as String?,
      author: json['author'] as String?,
      page: json['page'] as int?,
      url: json['url'] as String?,
      documentId: json['document_id'] as String?,
      fileName: json['file_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (author != null) 'author': author,
        if (page != null) 'page': page,
        if (url != null) 'url': url,
        if (documentId != null) 'document_id': documentId,
        if (fileName != null) 'file_name': fileName,
      };
}

class WebSearchResult {
  final String resultId;
  final String url;
  final String title;
  final String snippet;
  final String markdownExcerpt;
  final String source;
  final double relevanceScore;

  const WebSearchResult({
    required this.resultId,
    required this.url,
    required this.title,
    required this.snippet,
    required this.markdownExcerpt,
    required this.source,
    required this.relevanceScore,
  });

  factory WebSearchResult.fromJson(Map<String, dynamic> json) {
    return WebSearchResult(
      resultId: json['result_id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      markdownExcerpt: json['markdown_excerpt'] as String? ?? '',
      source: json['source'] as String? ?? '',
      relevanceScore:
          (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'result_id': resultId,
        'url': url,
        'title': title,
        'snippet': snippet,
        'markdown_excerpt': markdownExcerpt,
        'source': source,
        'relevance_score': relevanceScore,
      };
}

class Citation {
  final String sourceId;
  final String snippet;
  final double score;
  final CitationMeta metadata;

  const Citation(this.sourceId, this.snippet, this.score, this.metadata);

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      json['source_id'] as String? ?? '',
      json['snippet'] as String? ?? '',
      (json['score'] as num?)?.toDouble() ?? 0.0,
      json['metadata'] != null
          ? CitationMeta.fromJson(json['metadata'] as Map<String, dynamic>)
          : const CitationMeta(),
    );
  }

  Map<String, dynamic> toJson() => {
        'source_id': sourceId,
        'snippet': snippet,
        'score': score,
        'metadata': metadata.toJson(),
      };
}

class PredictionResult {
  final String predictedLabel;
  final double confidence;
  final List<ClassScore> classScores;
  final String modelName;
  final String modelVersion;
  final List<String> inputFeaturesUsed;
  final DateTime generatedAt;

  const PredictionResult({
    required this.predictedLabel,
    required this.confidence,
    required this.classScores,
    required this.modelName,
    required this.modelVersion,
    required this.inputFeaturesUsed,
    required this.generatedAt,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      predictedLabel: json['predicted_label'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      classScores: (json['class_scores'] as List<dynamic>?)
              ?.map((e) => ClassScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      modelName: json['model_name'] as String? ?? '',
      modelVersion: json['model_version'] as String? ?? '',
      inputFeaturesUsed: (json['input_features_used'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'predicted_label': predictedLabel,
        'confidence': confidence,
        'class_scores': classScores.map((e) => e.toJson()).toList(),
        'model_name': modelName,
        'model_version': modelVersion,
        'input_features_used': inputFeaturesUsed,
        'generated_at': generatedAt.toIso8601String(),
      };
}

class ClassScore {
  final String label;
  final double score;

  const ClassScore({required this.label, required this.score});

  factory ClassScore.fromJson(Map<String, dynamic> json) {
    return ClassScore(
      label: json['label'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'score': score,
      };
}
