enum DocumentCategory { contract, landRecord, invoice, blueprint, permit, other }

enum IndexingStatus { pending, indexing, indexed, failed }

class SiteDocument {
  final String id;
  final String projectId;
  final String title;
  final DocumentCategory category;
  final DateTime uploadDate;
  final String fileSize; // e.g. "2.4 MB"
  final IndexingStatus ragStatus;
  final String? notes;

  SiteDocument({
    required this.id,
    required this.projectId,
    required this.title,
    required this.category,
    required this.uploadDate,
    required this.fileSize,
    this.ragStatus = IndexingStatus.pending,
    this.notes,
  });

  String get categoryLabel {
    switch (category) {
      case DocumentCategory.contract:
        return 'Contract';
      case DocumentCategory.landRecord:
        return 'Land Record';
      case DocumentCategory.invoice:
        return 'Invoice';
      case DocumentCategory.blueprint:
        return 'Blueprint';
      case DocumentCategory.permit:
        return 'Permit';
      case DocumentCategory.other:
        return 'Other';
    }
  }

  String get ragStatusLabel {
    switch (ragStatus) {
      case IndexingStatus.pending:
        return 'Pending';
      case IndexingStatus.indexing:
        return 'Indexing…';
      case IndexingStatus.indexed:
        return 'Indexed';
      case IndexingStatus.failed:
        return 'Failed';
    }
  }
}
