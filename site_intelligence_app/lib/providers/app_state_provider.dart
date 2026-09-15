import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/update.dart';
import '../models/site_document.dart';
import '../models/chat_message.dart';
import '../models/ai_analysis_result.dart';
import '../services/openrouter_service.dart';

class AppStateProvider extends ChangeNotifier {
  final List<Project> _projects = [];
  final List<SiteUpdate> _updates = [];
  final List<SiteDocument> _documents = [];
  final List<ChatMessage> _chatMessages = [];

  List<Project> get projects => _projects;
  List<SiteUpdate> get updates => _updates;
  List<SiteDocument> get documents => _documents;
  List<ChatMessage> get chatMessages => _chatMessages;

  AppStateProvider() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock Projects
    _projects.addAll([
      Project(
        id: 'p1',
        name: 'KleTech Farm',
        location: 'Hubli, Karnataka',
        progressPercent: 0.45,
        totalBudget: 85000000.0,
        totalSpent: 38000000.0,
        activeLabourCount: 68,
        status: ProjectStatus.onSchedule,
        lastUpdateDate: DateTime.now().subtract(const Duration(hours: 3)),
        currentPhase: 'Foundation & Plinth',
      ),
      Project(
        id: 'p2',
        name: 'Indranagar',
        location: 'Bangalore, Karnataka',
        progressPercent: 0.72,
        totalBudget: 220000000.0,
        totalSpent: 158000000.0,
        activeLabourCount: 134,
        status: ProjectStatus.onSchedule,
        lastUpdateDate: DateTime.now().subtract(const Duration(hours: 1)),
        currentPhase: 'Superstructure Phase',
      ),
      Project(
        id: 'p3',
        name: 'Kelgeri Site',
        location: 'Hubli, Karnataka',
        progressPercent: 0.20,
        totalBudget: 45000000.0,
        totalSpent: 9000000.0,
        activeLabourCount: 32,
        status: ProjectStatus.delayed,
        lastUpdateDate: DateTime.now().subtract(const Duration(days: 2)),
        currentPhase: 'Site Preparation',
      ),
      Project(
        id: 'p4',
        name: 'Garag Farm',
        location: 'Gadag, Karnataka',
        progressPercent: 0.58,
        totalBudget: 60000000.0,
        totalSpent: 34000000.0,
        activeLabourCount: 45,
        status: ProjectStatus.atRisk,
        lastUpdateDate: DateTime.now().subtract(const Duration(hours: 5)),
        currentPhase: 'Masonry & Slab',
      ),
      Project(
        id: 'p5',
        name: 'Belur Site',
        location: 'Dharwad, Karnataka',
        progressPercent: 0.88,
        totalBudget: 110000000.0,
        totalSpent: 95000000.0,
        activeLabourCount: 89,
        status: ProjectStatus.onSchedule,
        lastUpdateDate: DateTime.now().subtract(const Duration(minutes: 45)),
        currentPhase: 'Interior & Finishing',
      ),
    ]);

    // Mock Updates (Cleared - starts empty)
    // Mock Documents (Cleared - starts empty)
  }

  Project getProjectById(String id) {
    return _projects.firstWhere((p) => p.id == id);
  }

  List<SiteUpdate> getUpdatesForProject(String projectId) {
    return _updates.where((u) => u.projectId == projectId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<SiteDocument> getDocumentsForProject(String projectId) {
    return _documents.where((d) => d.projectId == projectId).toList()
      ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
  }

  // Count of AI-flagged issues across all projects
  int get aiIssueCount =>
      _updates.where((u) => u.aiAnalysis?.hasIssue == true).length;

  // Count of updates still being processed by AI
  int get processingCount => _updates.where((u) => u.isProcessing).length;

  // ─── Add update and enrich with AI ─────────────────────────────────────────
  Future<void> addUpdate(SiteUpdate update) async {
    final project = _projects.firstWhere(
      (p) => p.id == update.projectId,
      orElse: () => _projects.first,
    );

    // 1. Add with isProcessing: true → dashboard shows spinner immediately
    final processingUpdate = update.copyWith(isProcessing: true);
    _updates.add(processingUpdate);
    notifyListeners();

    try {
      // 2. Call OpenRouter based on update type
      final ai = OpenRouterService();
      AiAnalysisResult? result;

      switch (update.type) {
        case UpdateType.text:
          result = await ai.analyzeTextUpdate(
            text: update.summary,
            projectName: project.name,
          );
          break;
        case UpdateType.voice:
          // Transcribed audio text is in update.summary - analyze it directly!
          result = await ai.analyzeTextUpdate(
            text: update.summary,
            projectName: project.name,
          );
          break;
        case UpdateType.photo:
          // For now use text analysis of context (real base64 image passed when camera integrated)
          result = await ai.analyzeTextUpdate(
            text: 'Photo taken at ${project.name} site by ${update.workerName}. '
                'Photo shows current site conditions.',
            projectName: project.name,
          );
          break;
        case UpdateType.document:
          result = await ai.analyzeDocumentUpdate(
            documentCategory: update.documentCategory ?? 'document',
            projectName: project.name,
            workerName: update.workerName,
          );
          break;
      }

      // 3. Replace with enriched update
      final idx = _updates.indexWhere((u) => u.id == update.id);
      if (idx != -1) {
        _updates[idx] = processingUpdate.copyWith(
          aiAnalysis: result,
          isProcessing: false,
          tags: result.tags,
        );
        notifyListeners();
      }

      // 4. Dynamically update project stats (spend, workers, progress, status)
      _applyExtractedMetrics(update.projectId, result, update.summary);
    } catch (e) {
      // On error, mark as done without AI
      final idx = _updates.indexWhere((u) => u.id == update.id);
      if (idx != -1) {
        _updates[idx] = processingUpdate.copyWith(isProcessing: false);
        notifyListeners();
      }
      _applyExtractedMetrics(update.projectId, null, update.summary);
    }
  }

  // ─── Mutate Project stats based on extracted AI metrics or local Regex ──────
  void _applyExtractedMetrics(String projectId, AiAnalysisResult? aiResult, String rawText) {
    final pIdx = _projects.indexWhere((p) => p.id == projectId);
    if (pIdx == -1) return;

    final targetProject = _projects[pIdx];
    double newSpent = targetProject.totalSpent;
    int newWorkers = targetProject.activeLabourCount;
    double newProgress = targetProject.progressPercent;
    ProjectStatus newStatus = targetProject.status;

    // 1. Spend delta
    double? spendDelta = aiResult?.spentDelta;
    if (spendDelta == null || spendDelta <= 0) {
      spendDelta = _parseLocalSpend(rawText);
    }
    if (spendDelta != null && spendDelta > 0) {
      newSpent += spendDelta;
    }

    // 2. Worker count
    int? workers = aiResult?.workerCount;
    if (workers == null || workers <= 0) {
      workers = _parseLocalWorkers(rawText);
    }
    if (workers != null && workers > 0) {
      newWorkers = workers;
    }

    // 3. Progress percent
    double? progress = aiResult?.progressPercent;
    if (progress != null && progress > 0) {
      newProgress = progress;
    }

    // 4. Status flags
    if (aiResult?.issueFlag == 'DELAY' || rawText.toLowerCase().contains('delay') || rawText.toLowerCase().contains('halted')) {
      newStatus = ProjectStatus.delayed;
    } else if (aiResult?.issueFlag == 'SAFETY' || aiResult?.issueFlag == 'MATERIAL_SHORTAGE') {
      newStatus = ProjectStatus.atRisk;
    }

    // Replace project with updated metrics
    _projects[pIdx] = targetProject.copyWith(
      totalSpent: newSpent,
      activeLabourCount: newWorkers,
      progressPercent: newProgress,
      status: newStatus,
      lastUpdateDate: DateTime.now(),
    );
    notifyListeners();
  }

  // Parse local Indian currency mentions e.g. "1 crore", "50 lakhs", "₹50000"
  double? _parseLocalSpend(String text) {
    final lower = text.toLowerCase();

    // Match e.g. "1.5 crore", "1 crore", "1 cr", "1.5cr"
    final croreMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:crore|cr\b)').firstMatch(lower);
    if (croreMatch != null) {
      final val = double.tryParse(croreMatch.group(1) ?? '');
      if (val != null) return val * 10000000.0;
    }

    // Match e.g. "50 lakh", "50 lakhs", "50 l", "50lakh"
    final lakhMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:lakh|lakhs|l\b)').firstMatch(lower);
    if (lakhMatch != null) {
      final val = double.tryParse(lakhMatch.group(1) ?? '');
      if (val != null) return val * 100000.0;
    }

    // Match e.g. "₹ 50000" or "spent 50000"
    final rawMatch = RegExp(r'(?:spent|cost|expense|₹)\s*(\d+(?:\.\d+)?)').firstMatch(lower);
    if (rawMatch != null) {
      final val = double.tryParse(rawMatch.group(1) ?? '');
      if (val != null && val > 0) return val;
    }

    return null;
  }

  // Parse worker count e.g. "15 workers", "8 labourers"
  int? _parseLocalWorkers(String text) {
    final lower = text.toLowerCase();
    final match = RegExp(r'(\d+)\s*(?:workers|labourers|labour|peoples|people)').firstMatch(lower);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  void addProject(Project project) {
    _projects.add(project);
    notifyListeners();
  }

  void addDocument(SiteDocument doc) {
    _documents.add(doc);
    notifyListeners();
  }

  // ─── AI Chat about a project using real-time site updates ──────────────────
  Future<void> sendChatMessage(String text, {Project? project}) async {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.user,
      text: text,
      timestamp: DateTime.now(),
      citedSources: [],
    );
    _chatMessages.add(userMessage);
    notifyListeners();

    String aiResponse = "";
    List<String> sources = [];
    final queryLower = text.toLowerCase().trim();

    // Target projects & updates list
    final List<Project> targetProjects = project != null ? [project] : _projects;
    final List<SiteUpdate> relevantUpdates = project != null
        ? getUpdatesForProject(project.id)
        : (List<SiteUpdate>.from(_updates)..sort((a, b) => b.timestamp.compareTo(a.timestamp)));

    // Fast local intent matching for structured site queries (latest update, budget, workers, delays)
    final isStructuredQuery = queryLower.contains('update') ||
        queryLower.contains('latest') ||
        queryLower.contains('recent') ||
        queryLower.contains('budget') ||
        queryLower.contains('spend') ||
        queryLower.contains('spent') ||
        queryLower.contains('worker') ||
        queryLower.contains('labour') ||
        queryLower.contains('delay') ||
        queryLower.contains('risk');

    if (isStructuredQuery) {
      aiResponse = _generateLocalSmartResponse(queryLower, project, targetProjects, relevantUpdates);
    } else {
      // 1. Build real-time context string
      final StringBuffer contextBuffer = StringBuffer();
      if (project != null) {
        contextBuffer.writeln("Target Site: ${project.name} (${project.location})");
        contextBuffer.writeln("Budget: ₹${(project.totalBudget / 10000000).toStringAsFixed(1)}Cr | Spent: ₹${(project.totalSpent / 10000000).toStringAsFixed(1)}Cr | Workers: ${project.activeLabourCount} | Progress: ${(project.progressPercent * 100).toInt()}% | Status: ${project.statusLabel}");
      } else {
        contextBuffer.writeln("All Sites Overview:");
        for (var p in _projects) {
          contextBuffer.writeln("- ${p.name}: Spent ₹${(p.totalSpent / 10000000).toStringAsFixed(1)}Cr / ₹${(p.totalBudget / 10000000).toStringAsFixed(1)}Cr, ${p.activeLabourCount} Workers, ${(p.progressPercent * 100).toInt()}% Progress, Status: ${p.statusLabel}");
        }
      }

      contextBuffer.writeln("\nRecent Worker Updates:");
      if (relevantUpdates.isEmpty) {
        contextBuffer.writeln("No worker updates recorded yet.");
      } else {
        for (var u in relevantUpdates.take(10)) {
          final p = _projects.firstWhere((proj) => proj.id == u.projectId, orElse: () => _projects.first);
          final sumText = u.aiAnalysis?.summary ?? u.summary;
          contextBuffer.writeln("- [${p.name}] ${u.typeLabel} by ${u.workerName} (${_getRelativeTime(u.timestamp)}): \"$sumText\"");
        }
      }

      // 2. Try OpenRouter multi-model fallback API
      try {
        final ai = OpenRouterService();
        aiResponse = await ai.chatAboutProject(
          prompt: text,
          projectName: project?.name ?? 'All Construction Sites',
          projectContext: contextBuffer.toString(),
        );
      } catch (e) {
        aiResponse = "";
      }

      // 3. Smart local fallback if OpenRouter returns empty/error
      if (aiResponse.trim().isEmpty || aiResponse.contains("couldn't retrieve") || aiResponse.contains("Unable to connect")) {
        aiResponse = _generateLocalSmartResponse(queryLower, project, targetProjects, relevantUpdates);
      }
    }

    sources = relevantUpdates.take(3).map((u) {
      final p = _projects.firstWhere((proj) => proj.id == u.projectId, orElse: () => _projects.first);
      return "${p.name} Update (${u.workerName})";
    }).toList();

    if (sources.isEmpty) {
      sources = targetProjects.map((p) => "${p.name} Site Record").toList();
    }

    final aiMessage = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      role: ChatRole.assistant,
      text: aiResponse,
      timestamp: DateTime.now(),
      citedSources: sources,
      confidenceScore: 0.95,
    );

    _chatMessages.add(aiMessage);
    notifyListeners();
  }

  // Local smart response builder when AI API is unavailable or rate-limited
  String _generateLocalSmartResponse(
    String query,
    Project? specificProject,
    List<Project> projects,
    List<SiteUpdate> updates,
  ) {
    if (query.contains('summary') || query.contains('latest update') || query.contains('recent update') || query.contains('last update') || query.contains('what happened') || query.contains('update')) {
      if (updates.isEmpty) {
        return specificProject != null
            ? "No updates have been recorded for ${specificProject.name} yet. Site is initialized and ready for worker updates."
            : "No worker updates recorded across your sites yet. All 5 construction projects are active and ready for entries.";
      }
      final latest = updates.first;
      final proj = _projects.firstWhere((p) => p.id == latest.projectId, orElse: () => projects.first);
      final text = latest.aiAnalysis?.summary ?? latest.summary;
      return "Summary of Site Activity:\n- Latest update on ${proj.name} by ${latest.workerName} (${_getRelativeTime(latest.timestamp)}): \"$text\"\n- Active Workforce: ${projects.fold(0, (s, p) => s + p.activeLabourCount)} workers\n- Total Spent: ₹${(projects.fold(0.0, (s, p) => s + p.totalSpent) / 10000000).toStringAsFixed(1)}Cr";
    }

    if (query.contains('budget') || query.contains('spend') || query.contains('cost') || query.contains('money')) {
      if (specificProject != null) {
        final spentCr = (specificProject.totalSpent / 10000000).toStringAsFixed(2);
        final budgetCr = (specificProject.totalBudget / 10000000).toStringAsFixed(2);
        final util = (specificProject.budgetUtilization * 100).toStringAsFixed(1);
        return "For ${specificProject.name}, total spent is ₹$spentCr Cr out of the total ₹$budgetCr Cr budget ($util% utilized).";
      } else {
        final totalBudget = projects.fold(0.0, (s, p) => s + p.totalBudget);
        final totalSpent = projects.fold(0.0, (s, p) => s + p.totalSpent);
        final spentCr = (totalSpent / 10000000).toStringAsFixed(2);
        final budgetCr = (totalBudget / 10000000).toStringAsFixed(2);
        return "Across all ${projects.length} sites, total spent is ₹$spentCr Cr against a total budget of ₹$budgetCr Cr.";
      }
    }

    if (query.contains('worker') || query.contains('labour') || query.contains('people') || query.contains('count')) {
      if (specificProject != null) {
        return "${specificProject.name} currently has ${specificProject.activeLabourCount} active workers on site.";
      } else {
        final totalWorkers = projects.fold(0, (s, p) => s + p.activeLabourCount);
        return "There are currently $totalWorkers active workers across all your sites.";
      }
    }

    if (query.contains('delay') || query.contains('delayed') || query.contains('behind') || query.contains('risk')) {
      final delayed = projects.where((p) => p.status == ProjectStatus.delayed || p.status == ProjectStatus.atRisk).toList();
      if (delayed.isEmpty) {
        return "All active sites are currently progressing on schedule without flagged delays.";
      } else {
        final names = delayed.map((p) => p.name).join(', ');
        return "The following site(s) are currently flagged for delays or risks: $names.";
      }
    }

    if (updates.isNotEmpty) {
      final latest = updates.first;
      final proj = _projects.firstWhere((p) => p.id == latest.projectId, orElse: () => projects.first);
      final text = latest.aiAnalysis?.summary ?? latest.summary;
      return "Here is the current site status:\n- Latest update on ${proj.name}: \"$text\"\n- Active Workers: ${projects.fold(0, (s, p) => s + p.activeLabourCount)}\n- Total Spent: ₹${(projects.fold(0.0, (s, p) => s + p.totalSpent) / 10000000).toStringAsFixed(1)}Cr";
    }

    return "All sites are active. You can ask about latest updates, budget spent, worker counts, or delayed milestones.";
  }

  String _getRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
