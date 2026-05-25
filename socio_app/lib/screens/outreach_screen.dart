import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OutreachScreen extends ConsumerStatefulWidget {
  const OutreachScreen({super.key});

  @override
  ConsumerState<OutreachScreen> createState() => _OutreachScreenState();
}

class _OutreachScreenState extends ConsumerState<OutreachScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for form
  final TextEditingController _targetNameController = TextEditingController(text: 'Sarah Jenkins');
  final TextEditingController _targetCompanyController = TextEditingController(text: 'Apex Ventures');
  final TextEditingController _targetRoleController = TextEditingController(text: 'Managing Partner');
  final TextEditingController _startupIdeaController = TextEditingController(
    text: 'A persistent mobile AI co-founder for solo builders that dynamically adapts persona.',
  );
  final TextEditingController _tractionController = TextEditingController(text: '30% MoM growth, 1,200 active founders.');
  final TextEditingController _askController = TextEditingController(text: '15-minute introductory chat.');

  bool _isGenerating = false;
  bool _hasResult = false;

  // Results
  String _coldEmail = '';
  String _callScript = '';
  String _followups = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _targetNameController.dispose();
    _targetCompanyController.dispose();
    _targetRoleController.dispose();
    _startupIdeaController.dispose();
    _tractionController.dispose();
    _askController.dispose();
    super.dispose();
  }

  void _generateOutreach() {
    setState(() {
      _isGenerating = true;
    });

    // Mock API call delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _hasResult = true;
        
        _coldEmail = """Subject: Quick question re: Adaptive AI co-founder for solo builders

Hi ${_targetNameController.text},

I saw your investment in early-stage productivity and developer tools, particularly your thesis on agentic applications. 

I'm building Socio—a persistent mobile AI co-founder that helps solo builders manage mental health, write cold pitches, and brainstorm. Unlike standard LLMs, our backend uses a Groq + Gemini waterfall to dynamically weigh Skeptic, Hustler, and Strategist modes based on the founder's state.

We are seeing exciting early indicators:
🚀 ${_tractionController.text}

Given your focus on this space at ${_targetCompanyController.text}, I would love to get your advice. Do you have 15 minutes for a brief introductory call next Tuesday?

Best,
[Your Name]
Founder, Socio""";

        _callScript = """[Intro]
"Hi ${_targetNameController.text}, this is [Your Name] from Socio. I know you're busy, but I wanted to share a 30-second summary of what we are building. Do you have a moment?"

[Pitch]
"We are building Socio—a mobile AI co-founder specifically designed for the 50 million solo builders globally. We've developed an adaptive persona engine that handles outreach, fundraising prep, and mental wellness without mode switching."

[Traction & Hook]
"We are already growing at ${_tractionController.text}. I saw you leading early-stage developer tools investments, and I'd love to show you a quick demo."

[The Ask / Close]
"Would you be open to a quick 15-minute introductory chat next week to see if there's a fit?""";

        _followups = """[Follow-up 1: Day 3]
"Hi ${_targetNameController.text}, just following up on my note below. We just crossed another milestone with our adaptive persona engine, and I'd love to share the brief pitch deck with you. Let me know if next Tuesday works for a quick chat."

[Follow-up 2: Day 7]
"Hi ${_targetNameController.text}, hope you're having a great week! I know you are incredibly busy. I wanted to share a quick screenshot of our new dashboard. We are now at ${_tractionController.text}. Let me know if you have 10 minutes next week."

[Follow-up 3: Day 14 (The Break-up)]
"Hi ${_targetNameController.text}, I assume this isn't a priority for ${_targetCompanyController.text} right now, which is completely fine! I'll keep pushing forward. If you ever want to check in on our progress in developer tool AI, feel free to reach out. Wish you all the best!" """;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: const Text(
          'Outreach Generator',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_hasResult) _buildForm() else _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Investor / Contact',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(_targetNameController, 'Name', 'e.g. Sarah Jenkins'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(_targetCompanyController, 'Company/Firm', 'e.g. Apex Ventures'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(_targetRoleController, 'Role', 'e.g. Managing Partner'),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          const Text(
            'Startup Context',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          _buildTextField(_startupIdeaController, 'Startup Idea / One-Liner', 'What are you building?', maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_tractionController, 'Traction Highlights', 'e.g. 30% MoM growth, 1200 users'),
          const SizedBox(height: 12),
          _buildTextField(_askController, 'Your Call to Action / Ask', 'e.g. 15-minute introductory chat'),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateOutreach,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded),
                        SizedBox(width: 8),
                        Text(
                          'Generate Outreach Kit',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String placeholder, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6D28D9).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF6D28D9),
                child: Icon(Icons.person_outline_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _targetNameController.text,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    '${_targetRoleController.text} • ${_targetCompanyController.text}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6D28D9), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasResult = false;
                  });
                },
                child: const Text('Edit Form'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF6D28D9),
                labelColor: const Color(0xFF6D28D9),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Cold Email'),
                  Tab(text: 'Call Script'),
                  Tab(text: 'Follow-ups'),
                ],
              ),
              
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResultCard(_coldEmail, 'Cold Email Pitch'),
                    _buildResultCard(_callScript, 'Cold Call Script'),
                    _buildResultCard(_followups, '3-Part Follow-up Sequence'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(String content, String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B)),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Color(0xFF6D28D9), size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard! 📋'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
