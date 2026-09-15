import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../providers/app_state_provider.dart';
import '../../models/project.dart';
import '../../models/update.dart';

class IntakeScreen extends StatefulWidget {
  final Project project;
  const IntakeScreen({super.key, required this.project});

  @override
  State<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends State<IntakeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSuccessBottomSheet(String summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(ctx).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  );
                }
              ),
              const SizedBox(height: 24),
              const Text("Update Submitted", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(summary, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text("Dashboard"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: const Text("Submit Another"),
                    ),
                  )
                ],
              )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.text_snippet_outlined), text: "Text"),
            Tab(icon: Icon(Icons.mic_none_outlined), text: "Voice"),
            Tab(icon: Icon(Icons.camera_alt_outlined), text: "Photo"),
            Tab(icon: Icon(Icons.description_outlined), text: "Doc"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TextTab(projectId: widget.project.id, onSuccess: _showSuccessBottomSheet),
          _VoiceTab(projectId: widget.project.id, onSuccess: _showSuccessBottomSheet),
          _PhotoTab(projectId: widget.project.id, onSuccess: _showSuccessBottomSheet),
          _DocumentTab(projectId: widget.project.id, onSuccess: _showSuccessBottomSheet),
        ],
      ),
    );
  }
}

class _TextTab extends StatefulWidget {
  final String projectId;
  final Function(String) onSuccess;
  
  const _TextTab({required this.projectId, required this.onSuccess});

  @override
  State<_TextTab> createState() => _TextTabState();
}

class _TextTabState extends State<_TextTab> {
  String _category = 'Progress';
  final List<String> _categories = ['Progress', 'Material Delivery', 'Labour', 'Delay/Issue'];
  final _descController = TextEditingController();
  final _cementController = TextEditingController();
  final _steelController = TextEditingController();
  final _sandController = TextEditingController();

  void _submit() {
    if (_descController.text.isEmpty) return;

    final update = SiteUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: widget.projectId,
      type: UpdateType.text,
      summary: '$_category: ${_descController.text}',
      timestamp: DateTime.now(),
      workerName: "Worker",
      tags: [_category],
      extractedData: _category == 'Material Delivery' ? {
        'cement_bags': _cementController.text,
        'steel_kg': _steelController.text,
        'sand_units': _sandController.text,
      } : null,
    );

    context.read<AppStateProvider>().addUpdate(update);
    widget.onSuccess("Text update for $_category added successfully.");
    
    _descController.clear();
    _cementController.clear();
    _steelController.clear();
    _sandController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Category", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category,
                isExpanded: true,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_category == 'Material Delivery') ...[
            const Text("Quantities", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildNumberField("Cement (bags)", _cementController)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField("Steel (kg)", _steelController)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField("Sand (units)", _sandController)),
              ],
            ),
            const SizedBox(height: 24),
          ],
          const Text("Description", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Enter details here...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submit,
              child: const Text("Submit Update", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
    );
  }
}

class _VoiceTab extends StatefulWidget {
  final String projectId;
  final Function(String) onSuccess;

  const _VoiceTab({required this.projectId, required this.onSuccess});

  @override
  State<_VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<_VoiceTab> with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _wordsSpoken = "";
  final TextEditingController _transcriptionController = TextEditingController();

  int _seconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _initSpeech();
  }

  /// Initialize speech recognition
  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) => print('SpeechToText Error: $val'),
        onStatus: (val) => print('SpeechToText Status: $val'),
      );
      setState(() {});
    } catch (e) {
      print('SpeechToText initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }

  /// Start a speech recognition session
  void _startListening() async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }

    _seconds = 0;
    _wordsSpoken = "";
    _transcriptionController.clear();
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _seconds++;
      });
    });

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 10),
        localeId: "en_US",
      ),
    );

    setState(() {
      _isListening = true;
    });
  }

  /// Stop the active speech recognition session
  void _stopListening() async {
    await _speechToText.stop();
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isListening = false;
    });
  }

  /// Callback when speech is transcribed
  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
      _transcriptionController.text = _wordsSpoken;
    });
  }

  void _submit() {
    final text = _transcriptionController.text.trim();
    if (text.isEmpty) return;

    final update = SiteUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: widget.projectId,
      type: UpdateType.voice,
      summary: text,
      timestamp: DateTime.now(),
      workerName: "Worker",
      audioDuration: Duration(seconds: _seconds),
      tags: ["Voice", "Audio Update"],
    );

    context.read<AppStateProvider>().addUpdate(update);
    widget.onSuccess("Voice update processed and transcribed successfully.");
    setState(() {
      _wordsSpoken = "";
      _transcriptionController.clear();
      _seconds = 0;
    });
  }

  String get _formattedTime {
    final m = (_seconds / 60).floor().toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final hasTranscription = _transcriptionController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          if (!_isListening && !hasTranscription) ...[
            Text(
              _speechEnabled ? "Tap to record English audio update" : "Initializing speech recognition...",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _speechEnabled ? _startListening : null,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _speechEnabled
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.grey.shade200,
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _speechEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ] else if (_isListening) ...[
            Text(
              "Listening...",
              style: TextStyle(fontSize: 18, color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _stopListening,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: EdgeInsets.all(20 + (_pulseController.value * 15)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _formattedTime,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _wordsSpoken.isEmpty ? "Start speaking..." : _wordsSpoken,
                style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ] else ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text("Review Audio Transcription", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        controller: _transcriptionController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: "Transcribed text...",
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _wordsSpoken = "";
                      _transcriptionController.clear();
                      _seconds = 0;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retake"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Submit Update", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _PhotoTab extends StatefulWidget {
  final String projectId;
  final Function(String) onSuccess;

  const _PhotoTab({required this.projectId, required this.onSuccess});

  @override
  State<_PhotoTab> createState() => _PhotoTabState();
}

class _PhotoTabState extends State<_PhotoTab> {
  bool _hasPhoto = false;
  String _stage = 'Plinth';
  final _captionController = TextEditingController();
  final List<String> _stages = ['Plinth', 'Slab', 'Masonry', 'Finishing', 'Roofing', 'Painting'];

  void _submit() {
    if (!_hasPhoto) return;

    final update = SiteUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: widget.projectId,
      type: UpdateType.photo,
      summary: _captionController.text.isNotEmpty ? _captionController.text : "Photo update for $_stage",
      timestamp: DateTime.now(),
      workerName: "Worker",
      photoPath: "simulated/path.jpg",
      tags: [_stage, "Photo"],
    );

    context.read<AppStateProvider>().addUpdate(update);
    widget.onSuccess("Photo uploaded successfully for $_stage.");
    setState(() {
      _hasPhoto = false;
      _captionController.clear();
      _stage = 'Plinth';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_hasPhoto)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _hasPhoto = true),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Camera"),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _hasPhoto = true),
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Gallery"),
                      )
                    ],
                  )
                ],
              ),
            )
          else
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 64, color: Colors.white54),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton.filled(
                    onPressed: () => setState(() => _hasPhoto = false),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  ),
                )
              ],
            ),
          const SizedBox(height: 24),
          const Text("Construction Stage", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _stages.map((stage) {
              final isSelected = _stage == stage;
              return ChoiceChip(
                label: Text(stage),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _stage = stage);
                },
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text("Caption", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _captionController,
            decoration: InputDecoration(
              hintText: "Add a description...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _hasPhoto ? _submit : null,
              child: const Text("Submit Photo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

class _DocumentTab extends StatefulWidget {
  final String projectId;
  final Function(String) onSuccess;

  const _DocumentTab({required this.projectId, required this.onSuccess});

  @override
  State<_DocumentTab> createState() => _DocumentTabState();
}

class _DocumentTabState extends State<_DocumentTab> {
  String _docType = 'Invoice';
  bool _hasDoc = false;
  final _notesController = TextEditingController();
  final List<String> _types = ['Contract', 'Land Record', 'Invoice', 'Blueprint', 'Permit'];

  void _submit() {
    if (!_hasDoc) return;

    final update = SiteUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: widget.projectId,
      type: UpdateType.document,
      summary: _notesController.text.isNotEmpty ? _notesController.text : "Document uploaded",
      timestamp: DateTime.now(),
      workerName: "Worker",
      documentCategory: _docType,
      tags: [_docType, "Document"],
    );

    context.read<AppStateProvider>().addUpdate(update);
    widget.onSuccess("$_docType document uploaded successfully.");
    setState(() {
      _hasDoc = false;
      _notesController.clear();
      _docType = 'Invoice';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Document Type", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _docType,
                isExpanded: true,
                items: _types.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _docType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => setState(() => _hasDoc = true),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _hasDoc ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasDoc ? Theme.of(context).colorScheme.primary : Colors.grey.shade400, 
                  style: BorderStyle.solid, 
                  width: 2
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _hasDoc ? Icons.check_circle : Icons.upload_file, 
                    size: 48, 
                    color: _hasDoc ? Theme.of(context).colorScheme.primary : Colors.grey.shade600
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _hasDoc ? "sample_document.pdf" : "Tap to upload document",
                    style: TextStyle(
                      color: _hasDoc ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
                      fontWeight: FontWeight.w500
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Notes", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Add any context...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _hasDoc ? _submit : null,
              child: const Text("Submit Document", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
