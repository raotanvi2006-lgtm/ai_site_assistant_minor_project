class AiAnalysisResult {
  final String summary;         // 1-2 sentence AI summary
  final List<String> tags;      // Auto-extracted tags e.g. ["Cement", "Block C"]
  final String? issueFlag;      // "DELAY" | "SAFETY" | "MATERIAL_SHORTAGE" | null
  final double confidence;      // 0.0 - 1.0
  final String? rawResponse;    // Full LLM response for debugging
  final double? spentDelta;     // Extracted spend change (e.g. 10000000.0 for 1 crore)
  final int? workerCount;       // Extracted worker count if mentioned
  final double? progressPercent;// Extracted progress percent if mentioned

  const AiAnalysisResult({
    required this.summary,
    required this.tags,
    this.issueFlag,
    this.confidence = 1.0,
    this.rawResponse,
    this.spentDelta,
    this.workerCount,
    this.progressPercent,
  });

  bool get hasIssue => issueFlag != null;

  String get issueFlagLabel {
    switch (issueFlag) {
      case 'DELAY':
        return '⏰ Delay Detected';
      case 'SAFETY':
        return '⚠️ Safety Concern';
      case 'MATERIAL_SHORTAGE':
        return '📦 Material Shortage';
      default:
        return '';
    }
  }

  // Fallback result when AI is unavailable
  factory AiAnalysisResult.fallback(String rawText) {
    return AiAnalysisResult(
      summary: rawText.length > 120 ? '${rawText.substring(0, 120)}...' : rawText,
      tags: [],
      confidence: 0.0,
    );
  }
}
