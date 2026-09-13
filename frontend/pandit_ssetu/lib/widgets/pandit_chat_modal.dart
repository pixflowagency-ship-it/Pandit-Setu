import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PanditChatMessage {
  final String text;
  final bool isUser;
  final String time;

  PanditChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class PanditChatModal extends StatefulWidget {
  const PanditChatModal({super.key});

  @override
  State<PanditChatModal> createState() => _PanditChatModalState();
}

class _PanditChatModalState extends State<PanditChatModal> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<PanditChatMessage> _messages = [
    PanditChatMessage(
      text: 'Hari Om 🙏 I am Acharya Pandit Shastri. What life problems or spiritual questions are troubling you today?',
      isUser: false,
      time: 'Just now',
    ),
  ];

  final List<String> _quickTopics = [
    '💍 Marriage & Kundli Dosha',
    '💼 Career & Job Remedies',
    '❤️ Health & Peace at Home',
    '💰 Finance & Wealth Guidance',
    '🔱 Rahu/Ketu Shanti Muhurat',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(PanditChatMessage(
        text: text.trim(),
        isUser: true,
        time: 'Just now',
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate Pandit response after 1.2s
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(PanditChatMessage(
          text: _generatePanditResponse(text),
          isUser: false,
          time: 'Just now',
        ));
      });
      _scrollToBottom();
    });
  }

  String _generatePanditResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('marriage') || q.contains('kundli') || q.contains('dosha')) {
      return 'For Marriage & Relationship peace, analyzing your Manglik Dosh & 7th house chart is essential. Performing a Navagraha Shanti Puja or Gauri Shankar Stotram yields rapid blessings. Would you like a detailed Kundli match?';
    } else if (q.contains('career') || q.contains('job') || q.contains('work')) {
      return 'For Career growth & removing obstacles, chanting Aditya Hrudayam daily and offering Arghya to Surya Dev every morning brings great prosperity. We can also schedule a specific Lakshmi-Kuber Havan Muhurat.';
    } else if (q.contains('health') || q.contains('peace')) {
      return 'For health and mental peace, Mahamrityunjaya Mantra Jaap (108 times daily) creates a divine protective shield. I recommend keeping a consecrated Sphatik Shivling at your altar.';
    } else if (q.contains('finance') || q.contains('wealth') || q.contains('money')) {
      return 'For financial stability, performing Kanakdhara Stotram and Sri Sukta Havan on Fridays generates divine abundance. Let us review your 2nd and 11th planetary houses.';
    } else {
      return 'Thank you for sharing your concern. In Vedic astrology, every obstacle can be mitigated through pure Vedic rituals, Gayatri Mantra chanting, and proper Muhurat remedies. Feel free to ask more details or request a private 1-on-1 session.';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8EE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle bar
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD4C2AA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // Header with Pandit Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3E7D3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE8920A), width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&q=80',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person_pin,
                              color: Color(0xFFE8920A),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Acharya Pandit Shastri',
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3D2200),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFFE8920A),
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Senior Vedic Astrologer • 15+ Yrs Exp',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: const Color(0xFF8A7060),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Text(
                      'FREE CHAT',
                      style: GoogleFonts.lato(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Quick Topic Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickTopics.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final topic = _quickTopics[index];
                return ActionChip(
                  label: Text(
                    topic,
                    style: GoogleFonts.lato(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5C3B1E),
                    ),
                  ),
                  backgroundColor: const Color(0xFFFFF3E0),
                  side: const BorderSide(color: Color(0xFFFFD199)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () => _sendMessage(topic),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF3E7D3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE8920A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pandit Ji is analyzing...',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF8A7060),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color(0xFFE8920A) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                        bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                      ),
                      border: msg.isUser ? null : Border.all(color: const Color(0xFFF3E7D3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: GoogleFonts.lato(
                            fontSize: 13.5,
                            color: msg.isUser ? Colors.white : const Color(0xFF3D2200),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            msg.time,
                            style: GoogleFonts.lato(
                              fontSize: 9.5,
                              color: msg.isUser
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : const Color(0xFFA38C7A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your life problem or query...',
                      hintStyle: GoogleFonts.lato(
                        fontSize: 13,
                        color: const Color(0xFFA38C7A),
                      ),
                      fillColor: const Color(0xFFFFF8EE),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8000), Color(0xFFFF3D00)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
