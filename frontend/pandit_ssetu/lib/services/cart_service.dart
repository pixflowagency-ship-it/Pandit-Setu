import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final String? unit;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl = '',
    this.unit,
    this.quantity = 1,
  });

  double get lineTotal => price * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'unit': unit,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Pooja Item',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        imageUrl: json['imageUrl']?.toString() ?? '',
        unit: json['unit']?.toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}

class CartService extends ChangeNotifier {
  static const String _storageKey = 'sarvmangal_cart_items_v1';
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  static CartService get instance => _instance;

  CartService._internal() {
    loadCart();
  }

  final List<CartItem> _items = [];
  bool _isLoaded = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _isLoaded;
  bool get isEmpty => _items.isEmpty;

  int get totalItemCount {
    int total = 0;
    for (var item in _items) {
      total += item.quantity;
    }
    return total;
  }

  /// Provisional subtotal calculated from local snapshot prices.
  /// Backend remains authoritative at checkout.
  double get subtotal {
    double sum = 0.0;
    for (var item in _items) {
      sum += item.lineTotal;
    }
    return sum;
  }

  /// Free delivery above Rs. 500, flat Rs. 50 otherwise.
  double get deliveryCharge {
    if (_items.isEmpty) return 0.0;
    return subtotal >= 500.0 ? 0.0 : 50.0;
  }

  double get finalAmount => subtotal + deliveryCharge;

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _items.clear();
        for (var e in list) {
          if (e is Map<String, dynamic>) {
            _items.add(CartItem.fromJson(e));
          }
        }
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('CartService: error loading cart: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((i) => i.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('CartService: error saving cart: $e');
    }
  }

  Future<void> addItem({
    required String productId,
    required String name,
    required double price,
    String imageUrl = '',
    String? unit,
    int quantity = 1,
  }) async {
    if (productId.isEmpty || quantity <= 0) return;

    final existingIndex = _items.indexWhere((i) => i.productId == productId);
    if (existingIndex >= 0) {
      final current = _items[existingIndex];
      current.quantity = (current.quantity + quantity).clamp(1, 99);
    } else {
      _items.add(CartItem(
        productId: productId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        unit: unit,
        quantity: quantity.clamp(1, 99),
      ));
    }

    notifyListeners();
    await _persist();
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    if (newQuantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = newQuantity.clamp(1, 99);
    }

    notifyListeners();
    await _persist();
  }

  Future<void> removeItem(String productId) async {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
    await _persist();
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('CartService: error clearing storage: $e');
    }
  }

  /// Prepare items payload for backend POST /api/v1/product-orders
  List<Map<String, dynamic>> toBackendItems() {
    return _items.map((item) => {
      'productId': item.productId,
      'quantity': item.quantity,
    }).toList();
  }
}
