import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/project.dart';
import '../../models/chat_message.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import 'project_detail_screen.dart';
import 'add_project_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final TextEditingController _chatController = TextEditingController();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

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
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'AI Chat'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProjectScreen()),
                );
              },
              backgroundColor: const Color(0xFF1565C0),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildOverviewTab(),
          _buildAnalyticsTab(),
          _buildAiChatTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final projects = provider.projects;
        double totalBudget = projects.fold(0, (sum, p) => sum + p.totalBudget);
        double totalSpent = projects.fold(0, (sum, p) => sum + p.totalSpent);
        int totalWorkers = projects.fold(0, (sum, p) => sum + p.activeLabourCount);
        int alerts = projects.where((p) => p.status == ProjectStatus.delayed || p.status == ProjectStatus.atRisk).length;
        double utilPercent = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_getGreeting()},', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Here is your site overview for today', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildKpiCard('Budget Utilized', '${utilPercent.toStringAsFixed(1)}%', Icons.account_balance_wallet, Colors.blue),
                            _buildKpiCard('Active Sites', '${projects.length}', Icons.location_city, Colors.orange),
                            _buildKpiCard('Active Workers', '$totalWorkers', Icons.engineering, Colors.purple),
                            _buildKpiCard('Alerts', '$alerts', Icons.warning_amber_rounded, AppTheme.alert, isAlert: alerts > 0),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Your Projects', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = projects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p))),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Expanded(child: Text(p.location, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(p.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(p.statusLabel, style: TextStyle(color: _getStatusColor(p.status), fontSize: 12, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Progress', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                              Text('${(p.progressPercent * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: p.progressPercent,
                                            backgroundColor: Colors.grey[200],
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(4),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Spent: ${_formatCurrency(p.totalSpent)} / ${_formatCurrency(p.totalBudget)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                    Text('Updated ${_getRelativeTime(p.lastUpdateDate)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: projects.length,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final projects = provider.projects;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Analytics Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildChartCard(
                'Expenditure by Site',
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: projects.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.totalBudget,
                              color: Colors.grey[300],
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: e.value.totalSpent,
                              color: Theme.of(context).primaryColor,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < projects.length) {
                                String name = projects[value.toInt()].name;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(name.length > 5 ? name.substring(0, 5) : name, style: const TextStyle(fontSize: 10)),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildChartCard(
                'Material Allocation',
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(color: Colors.blueGrey, value: 35, title: 'Cement\n35%', radius: 60, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                        PieChartSectionData(color: Colors.brown, value: 25, title: 'Steel\n25%', radius: 55, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                        PieChartSectionData(color: Colors.orange, value: 15, title: 'Sand\n15%', radius: 50, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                        PieChartSectionData(color: Colors.green, value: 20, title: 'Labour\n20%', radius: 50, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                        PieChartSectionData(color: Colors.grey, value: 5, title: 'Other\n5%', radius: 45, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiChatTab() {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text('Site Intelligence AI v2.0 (Active)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1565C0))),
          ),
          Expanded(
            child: Consumer<AppStateProvider>(
              builder: (context, provider, child) {
                final messages = provider.chatMessages;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildChatMessage(msg);
                  },
                );
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSuggestionChip('Give me a summary of updates'),
                _buildSuggestionChip('Show delayed projects'),
                _buildSuggestionChip('Compare site budgets'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your sites...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (val) => _sendMessage(val),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_chatController.text),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<AppStateProvider>().sendChatMessage(text.trim());
    _chatController.clear();
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () => _sendMessage(text),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && msg.confidenceScore != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('AI Confidence: ${(msg.confidenceScore! * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            Text(
              msg.text,
              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
            if (!isUser && msg.citedSources.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ExpansionTile(
                  title: const Text('Sources', style: TextStyle(fontSize: 12)),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  children: msg.citedSources.map((s) => Align(alignment: Alignment.centerLeft, child: Text('- $s', style: const TextStyle(fontSize: 11)))).toList(),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {bool isAlert = false}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAlert ? color : color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            chart,
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.onSchedule:
        return AppTheme.success;
      case ProjectStatus.delayed:
        return Colors.orange;
      case ProjectStatus.atRisk:
        return AppTheme.alert;
      case ProjectStatus.completed:
        return AppTheme.info;
    }
  }
}
