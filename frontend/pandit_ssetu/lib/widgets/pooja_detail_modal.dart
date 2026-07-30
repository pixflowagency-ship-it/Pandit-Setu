import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class PoojaDetail {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final bool isPopular;
  final String duration;
  final String durationBreakdown;
  final String description;
  final String spiritualSignificance;
  final List<String> inclusions;
  final List<String> chantingDetails;
  final double standardPrice;
  final double samagriPrice;
  final double originalPrice;
  final String availability;

  const PoojaDetail({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    this.isPopular = false,
    required this.duration,
    required this.durationBreakdown,
    required this.description,
    required this.spiritualSignificance,
    required this.inclusions,
    required this.chantingDetails,
    required this.standardPrice,
    required this.samagriPrice,
    required this.originalPrice,
    this.availability = 'Available Today',
  });

  double get totalPrice => standardPrice + samagriPrice;
}

void showPoojaDetailBottomSheet(BuildContext context, PoojaDetail detail) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => PoojaDetailBottomSheet(detail: detail),
  );
}

class PoojaDetailBottomSheet extends StatelessWidget {
  final PoojaDetail detail;

  const PoojaDetailBottomSheet({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF6EE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [

              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFD97706).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            detail.category.toUpperCase(),
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD97706),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF3D2200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [

                    _buildHeaderImageCard(),

                    const SizedBox(height: 16),

                    _buildDurationBanner(),

                    const SizedBox(height: 16),

                    _buildDescriptionCard(),

                    const SizedBox(height: 16),

                    _buildInclusionsAndChantingCard(),

                    const SizedBox(height: 16),

                    _buildPriceBreakdownCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              _buildBottomAction(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderImageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  detail.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFFFF3E0),
                    child: const Center(
                      child: Icon(
                        Icons.temple_hindu,
                        size: 64,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              if (detail.isPopular)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'MOST POPULAR RITUAL',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D1A00),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_available, color: Color(0xFFD97706), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      detail.availability,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule,
              color: Color(0xFFD97706),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Estimated Duration: ${detail.duration}',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D1A00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail.durationBreakdown,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: const Color(0xFF8A7060),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Text(
                'Description & Overview',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1A00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detail.description,
            style: GoogleFonts.lato(
              fontSize: 13.5,
              height: 1.5,
              color: const Color(0xFF5A4A3A),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Spiritual Significance',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  detail.spiritualSignificance,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    height: 1.45,
                    color: const Color(0xFF3D2200),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionsAndChantingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Text(
                'Included Inclusions',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1A00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...detail.inclusions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: const Color(0xFF3D2200),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE8D5A3), height: 1),
          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.menu_book, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Text(
                'Vedic Chanting & Mantras',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1A00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detail.chantingDetails.map((chant) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF6EE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.music_note, color: Color(0xFFD97706), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      chant,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D1A00),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownCard() {
    final double discountAmount = detail.originalPrice - detail.totalPrice;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.payments_outlined, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Price Breakdown',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D1A00),
                    ),
                  ),
                ],
              ),
              if (discountAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Save ₹${discountAmount.toInt()}',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          _priceRow('Standard Pandit Dakshina', '₹${detail.standardPrice.toInt()}'),
          const SizedBox(height: 8),

          _priceRow('Vedic Samagri Kit & Setup', '₹${detail.samagriPrice.toInt()}'),
          const SizedBox(height: 12),

          const Divider(color: Color(0xFFE8D5A3), height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Package Price',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1A00),
                ),
              ),
              Row(
                children: [
                  if (detail.originalPrice > detail.totalPrice) ...[
                    Text(
                      '₹${detail.originalPrice.toInt()}',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '₹${detail.totalPrice.toInt()}',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String title, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 13.5,
            color: const Color(0xFF5A4A3A),
          ),
        ),
        Text(
          price,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D1A00),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {

              Navigator.of(context).pop();

              context.push('/book-flow', extra: detail);
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Proceed to Book',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
