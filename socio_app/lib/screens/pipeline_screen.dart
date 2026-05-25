import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PipelineScreen extends ConsumerStatefulWidget {
  const PipelineScreen({super.key});

  @override
  ConsumerState<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends ConsumerState<PipelineScreen> {
  // Mock list of investors
  final List<MockInvestor> _investors = [
    MockInvestor(
      name: 'Sarah Jenkins',
      firm: 'Apex Ventures',
      status: 'Meeting Scheduled',
      notes: 'Had a great demo. She was interested in the Groq response speeds. Suggested a follow-up in 3 days.',
      lastContact: DateTime.now().subtract(const Duration(days: 3)),
      traction: '30% growth',
    ),
    MockInvestor(
      name: 'Michael Chen',
      firm: 'Blue Horizon Capital',
      status: 'Warm Intro',
      notes: 'Introduced by advisors. Needs a pitch deck and a brief intro video.',
      lastContact: DateTime.now().subtract(const Duration(days: 5)),
      traction: '1200 active users',
    ),
    MockInvestor(
      name: 'Amanda Ross',
      firm: 'Pre-Seed Syndicate',
      status: 'Term Sheet',
      notes: 'Negotiating safe terms. Expressed excitement about the QuantCraft hackathon award.',
      lastContact: DateTime.now().subtract(const Duration(days: 1)),
      traction: 'Rs.1599/mo validation',
    ),
  ];

  void _showAddInvestorDialog() {
    final nameController = TextEditingController();
    final firmController = TextEditingController();
    final notesController = TextEditingController();
    String status = 'Warm Intro';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Investor', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Investor Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: firmController,
                  decoration: const InputDecoration(labelText: 'Venture Firm'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  items: ['Warm Intro', 'Meeting Scheduled', 'Term Sheet', 'Closed']
                      .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) status = val;
                  },
                  decoration: const InputDecoration(labelText: 'Pipeline Stage'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Meeting Notes / Summary'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _investors.add(MockInvestor(
                      name: nameController.text,
                      firm: firmController.text.isEmpty ? 'Angel' : firmController.text,
                      status: status,
                      notes: notesController.text,
                      lastContact: DateTime.now(),
                      traction: 'Standard context',
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9)),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _generateFollowup(MockInvestor investor) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: Future.delayed(const Duration(milliseconds: 1500)), // Mock generation
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6D28D9)),
                        SizedBox(height: 16),
                        Text(
                          'Socio AI is analyzing notes...\nDrafting follow-up email...',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final emailBody = """Subject: Re: Socio intro meeting followup / Apex Ventures

Hi ${investor.name},

It was great demoing Socio to you earlier. I really appreciated your feedback regarding our adaptive persona engine and the response latency optimizations using Groq.

Since we last spoke 3 days ago, we've successfully cleaned up our workspace issues and have pushed forward with our pre-seed milestone. 

Per your suggestion, I'd love to set up our follow-up chat. Are you available for a quick 10-minute check-in next Thursday at 3 PM?

Best regards,
[Your Name]
Founder, Socio""";

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6D28D9)),
                  const SizedBox(width: 8),
                  const Text('AI Follow-up Email', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generated by Socio AI (Ready to Send)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        emailBody,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied email to clipboard! 📬'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                  label: const Text('Copy Email', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: const Text('Investor Pipeline', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        actions: [
          IconButton(
            onPressed: _showAddInvestorDialog,
            icon: const Icon(Icons.add_rounded, color: Color(0xFF6D28D9), size: 28),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pipeline Summary Section
          Row(
            children: [
              _buildSummaryCard('Intros', '${_investors.where((i) => i.status == 'Warm Intro').length}', const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _buildSummaryCard('Meetings', '${_investors.where((i) => i.status == 'Meeting Scheduled').length}', const Color(0xFF6D28D9)),
              const SizedBox(width: 8),
              _buildSummaryCard('Term Sheets', '${_investors.where((i) => i.status == 'Term Sheet').length}', const Color(0xFFD97706)),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Active Leads & Pipeline',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          // Cards List
          ..._investors.map((investor) => _buildInvestorCard(investor)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestorCard(MockInvestor investor) {
    Color badgeColor = const Color(0xFF64748B);
    if (investor.status == 'Warm Intro') badgeColor = const Color(0xFF3B82F6);
    if (investor.status == 'Meeting Scheduled') badgeColor = const Color(0xFF6D28D9);
    if (investor.status == 'Term Sheet') badgeColor = const Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
                    Text(
                      investor.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      investor.firm,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: badgeColor.withOpacity(0.2)),
                ),
                child: Text(
                  investor.status,
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            investor.notes,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Contact: 3 days ago',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
              ElevatedButton.icon(
                onPressed: () => _generateFollowup(investor),
                icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
                label: const Text('Write Follow-up', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MockInvestor {
  final String name;
  final String firm;
  final String status;
  final String notes;
  final DateTime lastContact;
  final String traction;

  MockInvestor({
    required this.name,
    required this.firm,
    required this.status,
    required this.notes,
    required this.lastContact,
    required this.traction,
  });
}
