import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/cart_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF3D2200), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Pooja Samagri Cart',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: cart,
            builder: (context, _) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _confirmClearCart(context),
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFC62828)),
                label: Text(
                  'Clear',
                  style: GoogleFonts.lato(
                    color: const Color(0xFFC62828),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (!cart.isLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF18C16)),
            );
          }

          if (cart.isEmpty) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    _buildFreeDeliveryBanner(cart.subtotal),
                    const SizedBox(height: 16),
                    ...cart.items.map((item) => _buildCartItemCard(context, item)),
                    const SizedBox(height: 16),
                    _buildOrderSummaryCard(cart),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              _buildBottomCheckoutBar(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF0DC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8D5A3), width: 2),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 52,
                color: Color(0xFFF18C16),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Sacred Cart is Empty',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D2200),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore 1,200+ pure samagri items, havan kits, and holy offerings for your auspicious rituals.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: const Color(0xFF8A7060),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/shop');
                }
              },
              icon: const Icon(Icons.storefront, color: Colors.white, size: 20),
              label: Text(
                'Explore Sacred Store',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF18C16),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeDeliveryBanner(double subtotal) {
    final qualifies = subtotal >= 500.0;
    final remaining = (500.0 - subtotal).clamp(0.0, 500.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: qualifies ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qualifies ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
        ),
      ),
      child: Row(
        children: [
          Icon(
            qualifies ? Icons.check_circle : Icons.local_shipping_outlined,
            color: qualifies ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              qualifies
                  ? 'Congratulations! You unlocked FREE sacred delivery.'
                  : 'Add ₹${remaining.toInt()} more for FREE sacred delivery (Order ₹500+)',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: qualifies ? const Color(0xFF1B5E20) : const Color(0xFFBF360C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2E6D0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 70,
              height: 70,
              color: const Color(0xFFFAF0DC),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        color: Color(0xFFD4A373),
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.spa,
                      color: Color(0xFFE8920A),
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Product Info & Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF9E9E9E)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => CartService.instance.removeItem(item.productId),
                    ),
                  ],
                ),
                if (item.unit != null && item.unit!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Unit: ${item.unit}',
                    style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8A7060)),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.price.toInt()} × ${item.quantity} = ₹${item.lineTotal.toInt()}',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF18C16),
                      ),
                    ),
                    // Quantity Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF0DC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE8D5A3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStepperButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (item.quantity > 1) {
                                CartService.instance.updateQuantity(item.productId, item.quantity - 1);
                              } else {
                                CartService.instance.removeItem(item.productId);
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3D2200),
                              ),
                            ),
                          ),
                          _buildStepperButton(
                            icon: Icons.add,
                            onTap: () {
                              CartService.instance.updateQuantity(item.productId, item.quantity + 1);
                            },
                          ),
                        ],
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

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: const Color(0xFF3D2200)),
      ),
    );
  }

  Widget _buildOrderSummaryCard(CartService cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2E6D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D2200),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Items Subtotal (${cart.totalItemCount} items)', '₹${cart.subtotal.toInt()}'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Sacred Delivery Fee',
            cart.deliveryCharge == 0 ? 'FREE' : '₹${cart.deliveryCharge.toInt()}',
            isFree: cart.deliveryCharge == 0,
          ),
          const Divider(height: 24, color: Color(0xFFE8D5A3)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3D2200),
                ),
              ),
              Text(
                '₹${cart.finalAmount.toInt()}',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF18C16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '* Final prices and delivery verified server-side at checkout.',
            style: GoogleFonts.lato(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF8A7060),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF7A6251)),
        ),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isFree ? const Color(0xFF2E7D32) : const Color(0xFF3D2200),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCheckoutBar(BuildContext context, CartService cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF2E6D0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Payable',
                  style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8A7060)),
                ),
                Text(
                  '₹${cart.finalAmount.toInt()}',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3D2200),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF18C16),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed to Checkout',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Clear Cart?',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        content: Text(
          'Are you sure you want to remove all items from your sacred cart?',
          style: GoogleFonts.lato(color: const Color(0xFF7A6251)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.lato(color: const Color(0xFF8A7060))),
          ),
          ElevatedButton(
            onPressed: () {
              CartService.instance.clearCart();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cart'),
          ),
        ],
      ),
    );
  }
}
