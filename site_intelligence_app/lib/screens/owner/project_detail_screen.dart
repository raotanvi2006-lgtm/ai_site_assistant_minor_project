import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/project.dart';
import '../../models/update.dart';
import '../../models/site_document.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import 'ai_chat_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _getRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // ── Fixed AppBar (no collapsing) ──────────────────────────────────
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          title: Text(project.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Updates'),
              Tab(text: 'Documents'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AiChatScreen(project: project)));
          },
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
        body: Column(
          children: [
            // ── Fixed project stats header ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.75)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(project.statusLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Text('Phase: ${project.currentPhase}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                      const SizedBox(height: 10),
                      Text('Spent: ${_formatCurrency(project.totalSpent)}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Budget: ${_formatCurrency(project.totalBudget)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.engineering, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text('${project.activeLabourCount} Active Workers',
                            style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ]),
                    ],
                  ),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: project.progressPercent,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        Center(
                          child: Text(
                            '${(project.progressPercent * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Tab content fills remaining space ─────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  _buildUpdatesTab(context),
                  _buildDocumentsTab(context),
                  _buildAnalyticsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatesTab(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final updates = provider.getUpdatesForProject(project.id).take(5).toList();
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: const Row(
                children: [
                  Icon(Icons.history, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    'Latest 5 Updates',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ChoiceChip(label: const Text('All'), selected: true, onSelected: (_) {}),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Text'), selected: false, onSelected: (_) {}),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Voice'), selected: false, onSelected: (_) {}),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Photo'), selected: false, onSelected: (_) {}),
                ],
              ),
            ),
            Expanded(
              child: updates.isEmpty
                  ? const Center(
                      child: Text(
                        'No updates submitted yet.\nUpdates from workers will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: updates.length,
                      itemBuilder: (context, index) {
                        final update = updates[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(update.typeIcon, size: 20, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    Text(update.typeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const Spacer(),
                                    Text(_getRelativeTime(update.timestamp), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (update.isProcessing)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                    ),
                                    child: const Row(children: [
                                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                      SizedBox(width: 10),
                                      Text('AI is analyzing...', style: TextStyle(color: Colors.blue, fontSize: 13)),
                                    ]),
                                  )
                                else if (update.aiAnalysis != null) ...[
                                  if (update.aiAnalysis!.hasIssue)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(update.aiAnalysis!.issueFlagLabel,
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12)),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.15)),
                                    ),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [
                                        Icon(Icons.auto_awesome, size: 12, color: Theme.of(context).primaryColor),
                                        const SizedBox(width: 4),
                                        Text('AI Summary', style: TextStyle(
                                            fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
                                      ]),
                                      const SizedBox(height: 6),
                                      Text(update.aiAnalysis!.summary, style: const TextStyle(fontSize: 13, height: 1.4)),
                                    ]),
                                  ),
                                  if (update.type == UpdateType.voice) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Transcribed Audio:\n"${update.summary}"',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ] else
                                  Text(update.summary, style: const TextStyle(fontSize: 15)),
                                const SizedBox(height: 10),
                                if (update.type == UpdateType.voice && update.audioDuration != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.play_circle_fill, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text('${update.audioDuration!.inSeconds}s'),
                                    ]),
                                  ),
                                if (update.tags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: update.tags.map((t) => Chip(
                                      label: Text(t, style: const TextStyle(fontSize: 10)),
                                      padding: EdgeInsets.zero,
                                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    )).toList(),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.person, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(update.workerName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ])
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocumentsTab(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final docs = provider.getDocumentsForProject(project.id);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            Color statusColor;
            switch (doc.ragStatus) {
              case IndexingStatus.indexed:
                statusColor = AppTheme.success;
                break;
              case IndexingStatus.indexing:
                statusColor = Colors.amber;
                break;
              case IndexingStatus.failed:
                statusColor = AppTheme.alert;
                break;
              case IndexingStatus.pending:
                statusColor = Colors.grey;
                break;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.description, color: Theme.of(context).primaryColor),
                ),
                title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${doc.categoryLabel} • ${doc.fileSize}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                        ),
                        const SizedBox(width: 4),
                        Text('AI ${doc.ragStatusLabel}', style: TextStyle(fontSize: 12, color: statusColor)),
                      ],
                    )
                  ],
                ),
                trailing: Text(_getRelativeTime(doc.uploadDate), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly Cost Trend (Last 6 Weeks)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) => Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('W${val.toInt()}', style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(1, 2),
                            FlSpot(2, 2.5),
                            FlSpot(3, 3),
                            FlSpot(4, 2.8),
                            FlSpot(5, 4),
                            FlSpot(6, 4.2),
                          ],
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progress Milestones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildMilestone('Excavation & Foundation', true),
                _buildMilestone('Structural Framework', true),
                _buildMilestone('Masonry & Roofing', false),
                _buildMilestone('Electrical & Plumbing', false),
                _buildMilestone('Finishing & Handover', false, isLast: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestone(String title, bool isCompleted, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppTheme.success : Colors.grey[300],
              ),
              child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppTheme.success : Colors.grey[300],
              )
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
        )
      ],
    );
  }
}
