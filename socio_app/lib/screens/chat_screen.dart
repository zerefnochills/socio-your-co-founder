import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Dummy messages for UI mock
  final List<MockMessage> _messages = [
    MockMessage(
      content: "Hey there! I'm Socio, your persistent AI co-founder. I read your communications and automatically adapt to help you build your startup. What are we brainstorming today?",
      isSocio: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  // Mock weights for the Persona Engine
  double skepticWeight = 0.33;
  double hustlerWeight = 0.33;
  double strategistWeight = 0.34;

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(MockMessage(
        content: text,
        isSocio: false,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      
      // Mock persona weights adjustment based on message content
      if (text.toLowerCase().contains("pitch") || text.toLowerCase().contains("sell")) {
        hustlerWeight = 0.70;
        skepticWeight = 0.10;
        strategistWeight = 0.20;
      } else if (text.toLowerCase().contains("risk") || text.toLowerCase().contains("fail")) {
        skepticWeight = 0.75;
        hustlerWeight = 0.10;
        strategistWeight = 0.15;
      } else if (text.toLowerCase().contains("plan") || text.toLowerCase().contains("scale")) {
        strategistWeight = 0.65;
        skepticWeight = 0.15;
        hustlerWeight = 0.20;
      }
    });

    _scrollToBottom();

    // Mock Socio response after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      String response = "That's an interesting point! Let's explore that further. If we look at this strategically, we should consider our core MRR and user traction.";
      if (hustlerWeight > 0.5) {
        response = "Let's push this live immediately! We can hack a quick landing page, start doing cold outreach to 100 targets, and get our first users by tomorrow. Speed is our superpower!";
      } else if (skepticWeight > 0.5) {
        response = "Wait, let's play devil's advocate. Is this really a burning problem for solo founders, or are they just telling you it's a 'nice-to-have'? How will you validate their willingness to pay before writing any code?";
      } else if (strategistWeight > 0.5) {
        response = "To scale this effectively, let's map out our long-term defensibility. We should focus on building a robust data flywheel and setting up a clear subscription tier (e.g., Pro at 1,599/mo).";
      }

      setState(() {
        _messages.add(MockMessage(
          content: response,
          isSocio: true,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: Column(
        children: [
          // Premium Persona Widget Header
          _buildPersonaHeader(),

          // Chat Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),

          // Message Input Field
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildPersonaHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF6D28D9),
                  child: Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Socio AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Persona Engine: Adaptive',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Dynamic Thinking Mix',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            // Thinking Style Progress Bars
            Row(
              children: [
                _buildPersonaPill('Hustler', hustlerWeight, const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _buildPersonaPill('Skeptic', skepticWeight, const Color(0xFFDC2626)),
                const SizedBox(width: 8),
                _buildPersonaPill('Strategist', strategistWeight, const Color(0xFF6D28D9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaPill(String name, double weight, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '${(weight * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: weight,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(MockMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment:
            message.isSocio ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isSocio) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFEDE9FE),
              child: Text(
                'S',
                style: TextStyle(
                  color: Color(0xFF6D28D9),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isSocio ? Colors.white : const Color(0xFF6D28D9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isSocio ? 4 : 16),
                  bottomRight: Radius.circular(message.isSocio ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: message.isSocio ? const Color(0xFF0F172A) : Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (!message.isSocio) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(Icons.person_rounded, size: 16, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
      child: Row(
        children: [
          // Audio STT Mock Icon
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Speech-to-Text active (Simulation Mode) 🎙️'),
                  backgroundColor: Color(0xFF6D28D9),
                ),
              );
            },
            icon: const Icon(Icons.mic_none_rounded, color: Color(0xFF64748B)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 8),
          
          // Text Input Field
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask Socio... (e.g. pitch, risk, scale)',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF6D28D9),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}

class MockMessage {
  final String content;
  final bool isSocio;
  final DateTime timestamp;

  MockMessage({
    required this.content,
    required this.isSocio,
    required this.timestamp,
  });
}
