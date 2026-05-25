import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  // Mock startup metrics
  int userCount = 1200;
  int mrr = 15990; // Rs.15990
  String stage = 'Pre-Seed';

  // Checklist items
  final List<Map<String, dynamic>> _todoItems = [
    {'task': 'Follow up with Apex Ventures re: demo', 'done': false},
    {'task': 'Set up Firestore Security Rules in Console', 'done': true},
    {'task': 'Deploy FastAPI backend to Render', 'done': true},
    {'task': 'Draft cold outreach sequence for 20 leads', 'done': false},
    {'task': 'Complete daily wellness standup check-in', 'done': false},
  ];

  void _showMetricsEditDialog() {
    final userController = TextEditingController(text: userCount.toString());
    final mrrController = TextEditingController(text: mrr.toString());
    String selectedStage = stage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Update Startup Metrics', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Active Users'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: mrrController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly Recurring Revenue (Rs.)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStage,
                items: ['Idea', 'MVP', 'Pre-Seed', 'Seed', 'Series A']
                    .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedStage = val;
                },
                decoration: const InputDecoration(labelText: 'Startup Stage'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  userCount = int.tryParse(userController.text) ?? userCount;
                  mrr = int.tryParse(mrrController.text) ?? mrr;
                  stage = selectedStage;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Metrics updated! Socio AI is calibrating... 📊'),
                    backgroundColor: Color(0xFF6D28D9),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9)),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: const Text('Startup Metrics & Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics Panel Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Core Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                TextButton.icon(
                  onPressed: _showMetricsEditDialog,
                  icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF6D28D9)),
                  label: const Text('Edit Metrics', style: TextStyle(color: Color(0xFF6D28D9), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Metrics Cards Row
            Row(
              children: [
                _buildMetricCard('Total Users', userCount.toString(), Icons.people_outline_rounded, const Color(0xFF6D28D9)),
                const SizedBox(width: 12),
                _buildMetricCard('MRR', 'Rs.$mrr', Icons.payments_outlined, const Color(0xFF059669)),
              ],
            ),
            const SizedBox(height: 12),
            _buildStageCard(),
            
            const SizedBox(height: 24),
            // Tasks Title
            const Text(
              'Co-Founder TODO List',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            // Todo List items
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todoItems.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                itemBuilder: (context, index) {
                  final item = _todoItems[index];
                  return CheckboxListTile(
                    value: item['done'],
                    activeColor: const Color(0xFF6D28D9),
                    title: Text(
                      item['task'],
                      style: TextStyle(
                        fontSize: 14,
                        color: item['done'] ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                        decoration: item['done'] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        item['done'] = val;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color themeColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: themeColor.withOpacity(0.08),
              child: Icon(icon, color: themeColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.rocket_rounded, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Stage',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              Text(
                stage,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
            ),
            child: const Text(
              'Calibrated Engine',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }
}
