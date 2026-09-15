import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ai_analysis_result.dart';

class OpenRouterService {
  static final OpenRouterService _instance = OpenRouterService._internal();
  factory OpenRouterService() => _instance;
  OpenRouterService._internal();

  final Map<String, String> _headers = {
    'Authorization': 'Bearer ${AppConfig.openRouterApiKey}',
    'Content-Type': 'application/json',
    'HTTP-Referer': AppConfig.appUrl,
    'X-Title': AppConfig.appName,
  };

  // --- Analyze a text update -------------------------------------------------
  Future<AiAnalysisResult> analyzeTextUpdate({
    required String text,
    required String projectName,
  }) async {
    const systemPrompt = '''You are an AI assistant for a construction site management app.
Analyze the worker update and respond ONLY with a JSON object in this exact format:
{
  "summary": "1-2 sentence professional summary of what happened",
  "tags": ["Tag1", "Tag2"],
  "issue_flag": null,
  "spent_delta": null,
  "worker_count": null,
  "progress_percent": null
}
For issue_flag, use one of: "DELAY", "SAFETY", "MATERIAL_SHORTAGE", or null.
For spent_delta: if money/spent is mentioned (e.g. "1 crore spent" -> 10000000, "50 lakh" -> 5000000, "50000" -> 50000), extract total in Rupees as a number, otherwise null.
For worker_count: if worker/labour count is mentioned (e.g. "15 workers"), extract integer, otherwise null.
For progress_percent: if progress percentage is mentioned (e.g. "75% completed" -> 0.75), extract decimal 0.0-1.0, otherwise null.
Tags should be short (1-3 words) relevant keywords like material names, locations, activities.
Respond ONLY with the JSON. No extra text.''';

    final userPrompt = 'Project: $projectName\nWorker Update: $text';

    return _callApi(
      model: AppConfig.textModel,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      fallbackText: text,
    );
  }

  // --- AI Chat about a specific project --------------------------------------
  Future<String> chatAboutProject({
    required String prompt,
    required String projectName,
    required String projectContext,
  }) async {
    final systemPrompt = '''You are an AI Site Intelligence Assistant for the project "$projectName".
Use the following real-time project statistics and worker updates to answer the user's question accurately:

$projectContext

Be concise, accurate, professional, and directly answer based on the real-time project updates provided.''';

    final modelsToTry = [
      AppConfig.textModel,
      'google/gemini-2.5-flash:free',
      'qwen/qwen-2.5-7b-instruct:free',
      'meta-llama/llama-3.3-70b-instruct:free',
    ];

    for (final model in modelsToTry) {
      try {
        final body = jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 300,
          'temperature': 0.3,
        });

        final response = await http
            .post(Uri.parse(AppConfig.openRouterBaseUrl), headers: _headers, body: body)
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final content = decoded['choices'][0]['message']['content'] as String;
          if (content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      } catch (e) {
        // Try next model on timeout/error
        continue;
      }
    }

    return "";
  }

  // --- Analyze an image update -----------------------------------------------
  Future<AiAnalysisResult> analyzeImageUpdate({
    required String base64Image,
    required String projectName,
  }) async {
    const systemPrompt = '''You are an AI assistant for a construction site management app.
Analyze this construction site image and respond ONLY with a JSON object:
{
  "summary": "1-2 sentence description of what is visible in the image and site conditions",
  "tags": ["Tag1", "Tag2", "Tag3"],
  "issue_flag": null,
  "spent_delta": null,
  "worker_count": null,
  "progress_percent": null
}
For issue_flag: "DELAY" if work appears stopped, "SAFETY" if safety hazards visible, "MATERIAL_SHORTAGE" if shortages visible, or null.
Respond ONLY with the JSON. No extra text.''';

    try {
      final body = jsonEncode({
        'model': AppConfig.visionModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Project: $projectName\nAnalyze this site image:'},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          },
        ],
        'max_tokens': 256,
      });

      final response = await http
          .post(Uri.parse(AppConfig.openRouterBaseUrl), headers: _headers, body: body)
          .timeout(const Duration(seconds: 30));

      return _parseResponse(response, 'Image from $projectName site');
    } catch (e) {
      return AiAnalysisResult.fallback('Photo captured from $projectName site');
    }
  }

  // --- Analyze audio metadata -------------------------------------------------
  Future<AiAnalysisResult> analyzeAudioUpdate({
    required int durationSeconds,
    required String projectName,
    required String workerName,
  }) async {
    final userPrompt =
        'Project: $projectName\nWorker $workerName recorded a $durationSeconds-second voice note on site.';

    return _callApi(
      model: AppConfig.textModel,
      systemPrompt: '''You are an AI assistant for a construction site management app.
Respond ONLY with JSON:
{
  "summary": "1-2 sentence summary of voice update",
  "tags": ["Voice"],
  "issue_flag": null,
  "spent_delta": null,
  "worker_count": null,
  "progress_percent": null
}''',
      userPrompt: userPrompt,
      fallbackText: 'Voice note recorded ($durationSeconds seconds)',
    );
  }

  // --- Analyze document upload ------------------------------------------------
  Future<AiAnalysisResult> analyzeDocumentUpdate({
    required String documentCategory,
    required String projectName,
    required String workerName,
  }) async {
    final userPrompt =
        'Project: $projectName\nWorker $workerName uploaded a "$documentCategory" document.';

    return _callApi(
      model: AppConfig.textModel,
      systemPrompt: '''You are an AI assistant for a construction site management app.
Respond ONLY with JSON:
{
  "summary": "1-2 sentence summary of the document upload",
  "tags": ["$documentCategory"],
  "issue_flag": null,
  "spent_delta": null,
  "worker_count": null,
  "progress_percent": null
}''',
      userPrompt: userPrompt,
      fallbackText: '$documentCategory document uploaded',
    );
  }

  // --- Internal: call OpenRouter API -----------------------------------------
  Future<AiAnalysisResult> _callApi({
    required String model,
    required String systemPrompt,
    required String userPrompt,
    required String fallbackText,
  }) async {
    try {
      final body = jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'max_tokens': 256,
        'temperature': 0.3,
      });

      final response = await http
          .post(Uri.parse(AppConfig.openRouterBaseUrl), headers: _headers, body: body)
          .timeout(const Duration(seconds: 20));

      return _parseResponse(response, fallbackText);
    } catch (e) {
      return AiAnalysisResult.fallback(fallbackText);
    }
  }

  // --- Internal: parse LLM JSON response -------------------------------------
  AiAnalysisResult _parseResponse(http.Response response, String fallbackText) {
    try {
      if (response.statusCode != 200) {
        return AiAnalysisResult.fallback(fallbackText);
      }

      final decoded = jsonDecode(response.body);
      final content = decoded['choices'][0]['message']['content'] as String;

      String jsonStr = content.trim();
      if (jsonStr.contains('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'```json|```'), '').trim();
      }

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      return AiAnalysisResult(
        summary: parsed['summary'] as String? ?? fallbackText,
        tags: List<String>.from(parsed['tags'] as List? ?? []),
        issueFlag: parsed['issue_flag'] as String?,
        spentDelta: (parsed['spent_delta'] as num?)?.toDouble(),
        workerCount: (parsed['worker_count'] as num?)?.toInt(),
        progressPercent: (parsed['progress_percent'] as num?)?.toDouble(),
        confidence: 0.9,
        rawResponse: content,
      );
    } catch (e) {
      return AiAnalysisResult.fallback(fallbackText);
    }
  }
}
