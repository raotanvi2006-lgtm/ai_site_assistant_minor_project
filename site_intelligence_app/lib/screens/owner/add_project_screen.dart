import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../providers/app_state_provider.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _labourCtrl = TextEditingController();
  final _phaseCtrl = TextEditingController();
  
  ProjectStatus _status = ProjectStatus.onSchedule;

  final List<String> _phases = [
    'Site Preparation',
    'Foundation & Plinth',
    'Superstructure Phase',
    'Masonry & Slab',
    'Interior & Finishing',
  ];

  @override
  void initState() {
    super.initState();
    _phaseCtrl.text = _phases.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _budgetCtrl.dispose();
    _labourCtrl.dispose();
    _phaseCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final double budget = double.tryParse(_budgetCtrl.text.trim()) ?? 0.0;
    final int labour = int.tryParse(_labourCtrl.text.trim()) ?? 0;

    final newProject = Project(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      progressPercent: 0.0, // starts at 0%
      totalBudget: budget,
      totalSpent: 0.0, // starts at 0 spent
      activeLabourCount: labour,
      status: _status,
      lastUpdateDate: DateTime.now(),
      currentPhase: _phaseCtrl.text.trim(),
    );

    context.read<AppStateProvider>().addProject(newProject);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New project created successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text('Add New Project',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name ──────────────────────────────────────────────────
                _label('Project Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(hint: 'e.g. Hubli Office Block'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter project name' : null,
                ),
                const SizedBox(height: 20),

                // ── Location ──────────────────────────────────────────────
                _label('Location'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(hint: 'e.g. Hubli, Karnataka'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter project location' : null,
                ),
                const SizedBox(height: 20),

                // ── Budget ────────────────────────────────────────────────
                _label('Total Budget (in ₹)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _budgetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(hint: 'e.g. 5000000'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter project budget';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Labour Count ──────────────────────────────────────────
                _label('Initial Labour Count'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _labourCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(hint: 'e.g. 25'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter labour count';
                    if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Phase ─────────────────────────────────────────────────
                _label('Current Phase'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _phaseCtrl.text,
                  decoration: _inputDecoration(hint: ''),
                  items: _phases
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _phaseCtrl.text = val);
                  },
                ),
                const SizedBox(height: 20),

                // ── Status ────────────────────────────────────────────────
                _label('Project Status'),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProjectStatus>(
                  value: _status,
                  decoration: _inputDecoration(hint: ''),
                  items: const [
                    DropdownMenuItem(
                      value: ProjectStatus.onSchedule,
                      child: Text('On Schedule'),
                    ),
                    DropdownMenuItem(
                      value: ProjectStatus.delayed,
                      child: Text('Delayed'),
                    ),
                    DropdownMenuItem(
                      value: ProjectStatus.atRisk,
                      child: Text('At Risk'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 40),

                // ── Save Button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Add Project',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));

  InputDecoration _inputDecoration({required String hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}