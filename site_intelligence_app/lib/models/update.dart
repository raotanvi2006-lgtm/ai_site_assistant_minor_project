import 'package:flutter/material.dart';
import 'ai_analysis_result.dart';

enum UpdateType { text, voice, photo, document }

class SiteUpdate {
  final String id;
  final String projectId;
  final UpdateType type;
  final String summary;
  final DateTime timestamp;
  final String workerName;

  // Type-specific fields
  final Duration? audioDuration; // voice notes
  final String? photoPath; // photo updates
  final String? documentCategory; // document uploads

  // Extracted structured data
  final Map<String, dynamic>? extractedData;
  final List<String> tags; // e.g. ["+50 bags cement", "6 workers"]

  // AI enrichment
  final AiAnalysisResult? aiAnalysis;
  final bool isProcessing; // true while LLM is analyzing

  SiteUpdate({
    required this.id,
    required this.projectId,
    required this.type,
    required this.summary,
    required this.timestamp,
    required this.workerName,
    this.audioDuration,
    this.photoPath,
    this.documentCategory,
    this.extractedData,
    this.tags = const [],
    this.aiAnalysis,
    this.isProcessing = false,
  });

  // Creates a copy with updated fields (immutable pattern)
  SiteUpdate copyWith({
    AiAnalysisResult? aiAnalysis,
    bool? isProcessing,
    List<String>? tags,
  }) {
    return SiteUpdate(
      id: id,
      projectId: projectId,
      type: type,
      summary: summary,
      timestamp: timestamp,
      workerName: workerName,
      audioDuration: audioDuration,
      photoPath: photoPath,
      documentCategory: documentCategory,
      extractedData: extractedData,
      tags: tags ?? this.tags,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  String get typeLabel {
    switch (type) {
      case UpdateType.text:
        return 'Text';
      case UpdateType.voice:
        return 'Voice';
      case UpdateType.photo:
        return 'Photo';
      case UpdateType.document:
        return 'Document';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case UpdateType.text:
        return Icons.edit_note;
      case UpdateType.voice:
        return Icons.mic;
      case UpdateType.photo:
        return Icons.camera_alt;
      case UpdateType.document:
        return Icons.description;
    }
  }
}
