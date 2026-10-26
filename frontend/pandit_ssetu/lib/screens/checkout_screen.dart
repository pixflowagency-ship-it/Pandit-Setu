import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../user_data.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _notesController;

  late Razorpay _razorpay;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _activeOrderId;
  String? _activeRazorpayOrderId;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: UserData.name.isNotEmpty ? UserData.name : '');
    _phoneController = TextEditingController(text: UserData.phone.isNotEmpty ? UserData.phone : '');
    _addressLine1Controller = TextEditingController();
    _addressLine2Controller = TextEditingController();
    _cityController = TextEditingController(text: UserData.city.isNotEmpty ? UserData.city : 'Varanasi');
    _stateController = TextEditingController(text: 'Uttar Pradesh');
    _pincodeController = TextEditingController();
    _notesController = TextEditingController();

    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initiateCheckout() async {
    final cart = CartService.instance;
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty. Please add items to checkout.')),
      );
      context.pop();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the shipping form.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    // Check Authentication
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        _showAuthRequiredDialog();
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      String orderId = _activeOrderId ?? '';

      // 1. Create Product Order on backend if not already created for retry
      if (orderId.isEmpty) {
        final shippingAddress = {
          'fullName': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'addressLine1': _addressLine1Controller.text.trim(),
          if (_addressLine2Controller.text.trim().isNotEmpty)
            'addressLine2': _addressLine2Controller.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
        };

        final orderResult = await ApiService.createProductOrder(
          items: cart.toBackendItems(),
          shippingAddress: shippingAddress,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );

        orderId = orderResult['id']?.toString() ?? '';
        if (orderId.isEmpty) {
          throw Exception('Failed to receive order ID from server.');
        }
        _activeOrderId = orderId;
      }

      // 2. Initialize Razorpay Payment Order on backend
      final paymentResult = await ApiService.createProductOrderPayment(orderId);
      final razorpayOrderId = paymentResult['razorpayOrderId']?.toString();
      final amount = paymentResult['amount'];
      final keyId = paymentResult['keyId']?.toString() ??
          const String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: 'rzp_test_placeholder');

      if (razorpayOrderId == null || amount == null) {
        throw Exception('Server failed to initialize Razorpay payment order.');
      }

      _activeRazorpayOrderId = razorpayOrderId;

      // 3. Launch Razorpay Checkout
      final options = {
        'key': keyId,
        'amount': amount,
        'name': 'SARV MANGAL Store',
        'description': 'Sacred Pooja Samagri Order #$orderId',
        'order_id': razorpayOrderId,
        'timeout': 180,
        'prefill': {
          'contact': _phoneController.text.trim(),
          'name': _fullNameController.text.trim(),
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'An error occurred during checkout.'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // CRITICAL: Razorpay callback is NOT proof of payment. Verify signature on backend.
    try {
      if (mounted) setState(() => _isSubmitting = true);

      final verified = await ApiService.verifyProductOrderPayment(
        orderId: _activeOrderId ?? '',
        razorpayOrderId: response.orderId ?? _activeRazorpayOrderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      final paymentStatus = verified['paymentStatus']?.toString().toUpperCase();

      if (paymentStatus == 'PAID') {
        // Authoritative verification succeeded -> CLEAR CART NOW
        await CartService.instance.clearCart();

        if (mounted) {
          setState(() => _isSubmitting = false);
          _showOrderSuccessDialog(verified);
        }
      } else {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showPendingWarningDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment verification failed: ${e.toString().replaceAll('Exception: ', '')}. Please contact support with Payment ID: ${response.paymentId}',
            ),
            backgroundColor: const Color(0xFFC62828),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isSubmitting = false);
      final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
      final msg = isCancelled
          ? 'Payment cancelled. Your cart and order remain preserved.'
          : 'Payment failed (${response.code}): ${response.message ?? 'Transaction could not be completed'}. You can retry safely.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isCancelled ? const Color(0xFFE65100) : const Color(0xFFC62828),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External wallet chosen: ${response.walletName}')),
      );
    }
  }

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
          'Checkout & Delivery',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    _buildCartReviewSection(cart),
                    const SizedBox(height: 16),
                    _buildAddressFormSection(),
                    const SizedBox(height: 16),
                    _buildDeliveryNotesSection(),
                    const SizedBox(height: 16),
                    _buildPricingReviewCard(cart),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.lato(color: const Color(0xFFC62828), fontSize: 13),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              _buildBottomPaymentBar(cart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartReviewSection(CartService cart) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2E6D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items in Order (${cart.totalItemCount})',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3D2200),
                ),
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Edit Cart',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF18C16),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF2E6D0)),
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} × ${item.quantity}',
                      style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF5A4A3A)),
                    ),
                  ),
                  Text(
                    '₹${item.lineTotal.toInt()}',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3D2200),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressFormSection() {
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
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFF18C16), size: 20),
              const SizedBox(width: 8),
              Text(
                'Sacred Shipping Address',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3D2200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Name *',
            hint: 'Recipient name',
            validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter a valid full name' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            label: 'Mobile Number *',
            hint: '10-digit mobile number',
            keyboardType: TextInputType.phone,
            validator: (v) {
              final clean = (v ?? '').replaceAll(RegExp(r'\s+'), '');
              if (clean.length < 10) return 'Please enter a valid 10-digit mobile number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine1Controller,
            label: 'Address Line 1 (House / Street) *',
            hint: 'House/Flat No., Building name, Street',
            validator: (v) => (v == null || v.trim().length < 3) ? 'Address Line 1 is required' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine2Controller,
            label: 'Address Line 2 / Landmark (Optional)',
            hint: 'Near temple, landmark, area',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City *',
                  hint: 'City',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'City required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _stateController,
                  label: 'State *',
                  hint: 'State',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'State required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _pincodeController,
            label: 'PIN Code *',
            hint: '6-digit PIN code',
            keyboardType: TextInputType.number,
            validator: (v) {
              final clean = (v ?? '').replaceAll(RegExp(r'\s+'), '');
              if (!RegExp(r'^\d{6}$').hasMatch(clean)) return 'Enter valid 6-digit PIN code';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryNotesSection() {
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
            'Special Pooja / Delivery Instructions',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D2200),
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _notesController,
            label: 'Instructions (Optional)',
            hint: 'E.g., Please deliver before morning Brahma Muhurat',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingReviewCard(CartService cart) {
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
            'Payment Summary',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D2200),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Provisional Subtotal', '₹${cart.subtotal.toInt()}'),
          const SizedBox(height: 6),
          _buildSummaryRow(
            'Delivery Charge',
            cart.deliveryCharge == 0 ? 'FREE' : '₹${cart.deliveryCharge.toInt()}',
            isFree: cart.deliveryCharge == 0,
          ),
          const Divider(height: 20, color: Color(0xFFE8D5A3)),
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
            'Secured with 256-bit SSL encrypted Razorpay payment gateway.',
            style: GoogleFonts.lato(fontSize: 11, color: const Color(0xFF8A7060)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF7A6251))),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isFree ? const Color(0xFF2E7D32) : const Color(0xFF3D2200),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF3D2200)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF8A7060)),
        hintText: hint,
        hintStyle: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFFFFDF8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8D5A3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8D5A3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF18C16), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildBottomPaymentBar(CartService cart) {
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
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Final Amount',
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
              onPressed: _isSubmitting ? null : _initiateCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF18C16),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Place Order & Pay',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccessDialog(Map<String, dynamic> verifiedOrder) {
    final orderId = verifiedOrder['id']?.toString() ?? _activeOrderId ?? '';
    final finalAmount = verifiedOrder['finalAmount']?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Color(0xFF2E7D32), size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'Har Har Mahadev!',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D2200),
              ),
            ),
            Text(
              'Order Placed Successfully',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your sacred pooja samagri order has been confirmed and paid.',
              style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF7A6251)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF0DC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order ID:', style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8A7060))),
                      Text(
                        orderId.length > 12 ? '${orderId.substring(0, 12)}...' : orderId,
                        style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (finalAmount.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid Amount:', style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8A7060))),
                        Text('₹$finalAmount', style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
  }

  void _showPendingWarningDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Under Verification'),
        content: const Text(
          'Your payment was recorded but is awaiting final verification from the bank. '
          'Your items remain saved in the cart until confirmation is received.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please log in with your phone number to complete your order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/yajman-register');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
            ),
            child: const Text('Log In / Register'),
          ),
        ],
      ),
    );
  }
}
