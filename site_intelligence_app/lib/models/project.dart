enum ProjectStatus { onSchedule, delayed, atRisk, completed }

class Project {
  final String id;
  final String name;
  final String location;
  final double progressPercent; // 0.0 - 1.0
  final double totalBudget;
  final double totalSpent;
  final int activeLabourCount;
  final ProjectStatus status;
  final DateTime lastUpdateDate;
  final String currentPhase; // e.g. "Plinth", "Slab", "Masonry", "Finishing"

  Project({
    required this.id,
    required this.name,
    required this.location,
    required this.progressPercent,
    required this.totalBudget,
    required this.totalSpent,
    required this.activeLabourCount,
    required this.status,
    required this.lastUpdateDate,
    required this.currentPhase,
  });

  double get budgetUtilization =>
      totalBudget > 0 ? totalSpent / totalBudget : 0.0;

  String get statusLabel {
    switch (status) {
      case ProjectStatus.onSchedule:
        return 'On Schedule';
      case ProjectStatus.delayed:
        return 'Delayed';
      case ProjectStatus.atRisk:
        return 'At Risk';
      case ProjectStatus.completed:
        return 'Completed';
    }
  }

  Project copyWith({
    String? id,
    String? name,
    String? location,
    double? progressPercent,
    double? totalBudget,
    double? totalSpent,
    int? activeLabourCount,
    ProjectStatus? status,
    DateTime? lastUpdateDate,
    String? currentPhase,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      progressPercent: progressPercent ?? this.progressPercent,
      totalBudget: totalBudget ?? this.totalBudget,
      totalSpent: totalSpent ?? this.totalSpent,
      activeLabourCount: activeLabourCount ?? this.activeLabourCount,
      status: status ?? this.status,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      currentPhase: currentPhase ?? this.currentPhase,
    );
  }
}
