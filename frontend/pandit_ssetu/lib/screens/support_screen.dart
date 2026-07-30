import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How to prepare samagri?',
      'answer': 'If you selected the Vedic Samagri Kit add-on during booking, the Pandit Ji will bring everything needed. If not, we will email you a complete list of flowers, leaves, and fruits that you should procure before the Muhurat.',
      'expanded': false,
    },
    {
      'question': 'Can I reschedule a Pandit?',
      'answer': 'Yes, you can reschedule your booking up to 12 hours before the scheduled Muhurat time slot directly via the Order details screen without any additional charges.',
      'expanded': false,
    },
    {
      'question': 'Refund policy for canceled Poojas?',
      'answer': 'Cancellations made 24 hours prior receive a 100% refund. Within 12-24 hours, a 50% cancellation fee applies. No refunds are available for cancellations made within 12 hours of the ritual.',
      'expanded': false,
    },
    {
      'question': 'How are Pandits allocated?',
      'answer': 'If you choose Automatic Allocation, our system allocates a nearby certified Vedic pandit who has the highest ratings and matches the required language. Alternatively, you can pick a Pandit manually.',
      'expanded': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      final question = faq['question'].toString().toLowerCase();
      final answer = faq['answer'].toString().toLowerCase();
      return question.contains(_searchQuery) || answer.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Vedic Helpline & Support',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            _buildSearchBar(),

            const SizedBox(height: 16),

            _buildSupportChannelsCard(),

            const SizedBox(height: 20),

            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),

            if (filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No matching FAQ topics found.',
                    style: GoogleFonts.lato(color: const Color(0xFF6B5B52)),
                  ),
                ),
              )
            else
              ...filteredFaqs.map((faq) {
                final idx = _faqs.indexOf(faq);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            _faqs[idx]['expanded'] = !_faqs[idx]['expanded'];
                          });
                        },
                        title: Text(
                          faq['question']!,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        trailing: Icon(
                          faq['expanded'] ? Icons.expand_less : Icons.expand_more,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      if (faq['expanded'])
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: Text(
                            faq['answer']!,
                            style: GoogleFonts.lato(
                              fontSize: 12.5,
                              color: const Color(0xFF6B5B52),
                              height: 1.45,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1F2937)),
        decoration: InputDecoration(
          hintText: 'Search help topics & guides...',
          hintStyle: GoogleFonts.lato(fontSize: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFD97706)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSupportChannelsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Direct Assistance?',
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Our Vedic support team is available 24/7 for you.',
            style: GoogleFonts.lato(
              fontSize: 12,
              color: const Color(0xFF6B5B52),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Opening WhatsApp Devotee Support...',
                          style: GoogleFonts.lato(),
                        ),
                        backgroundColor: const Color(0xFFD97706),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                  label: Text(
                    'WhatsApp Devotee Support',
                    style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Calling Vedic Helpline...',
                          style: GoogleFonts.lato(),
                        ),
                        backgroundColor: const Color(0xFFD97706),
                      ),
                    );
                  },
                  icon: const Icon(Icons.call, size: 16, color: Colors.white),
                  label: Text(
                    'Call Vedic Helpline',
                    style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
