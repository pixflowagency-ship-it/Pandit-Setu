import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandit_ssetu/services/cart_service.dart';
import 'package:pandit_ssetu/screens/cart_screen.dart';
import 'package:pandit_ssetu/screens/checkout_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SARV MANGAL Stage 3: CartService Unit & Persistence Tests', () {
    late CartService cart;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      cart = CartService.instance;
      await cart.clearCart();
    });

    test('1. Newly initialized cart is empty with zero subtotal and zero delivery charge', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.totalItemCount, equals(0));
      expect(cart.subtotal, equals(0.0));
      expect(cart.deliveryCharge, equals(0.0));
      expect(cart.finalAmount, equals(0.0));
    });

    test('2. addItem adds new item and computes lineTotal and provisional subtotal', () async {
      await cart.addItem(
        productId: 'item-101',
        name: 'Pure Gangajal 500ml',
        price: 120.0,
        quantity: 2,
      );

      expect(cart.isEmpty, isFalse);
      expect(cart.totalItemCount, equals(2));
      expect(cart.items.length, equals(1));
      expect(cart.items.first.lineTotal, equals(240.0));
      expect(cart.subtotal, equals(240.0));
    });

    test('3. Adding existing item increments quantity up to bounds', () async {
      await cart.addItem(
        productId: 'item-101',
        name: 'Pure Gangajal 500ml',
        price: 120.0,
        quantity: 2,
      );

      await cart.addItem(
        productId: 'item-101',
        name: 'Pure Gangajal 500ml',
        price: 120.0,
        quantity: 3,
      );

      expect(cart.items.length, equals(1));
      expect(cart.items.first.quantity, equals(5));
      expect(cart.subtotal, equals(600.0));
    });

    test('4. Free delivery applies when subtotal >= 500, flat 50 applies otherwise', () async {
      // Subtotal: 200 (< 500) -> Delivery: 50, Total: 250
      await cart.addItem(
        productId: 'item-low',
        name: 'Dhoop Batti',
        price: 100.0,
        quantity: 2,
      );
      expect(cart.subtotal, equals(200.0));
      expect(cart.deliveryCharge, equals(50.0));
      expect(cart.finalAmount, equals(250.0));

      // Add more items so subtotal: 600 (>= 500) -> Delivery: 0, Total: 600
      await cart.addItem(
        productId: 'item-high',
        name: 'Havan Kund Copper',
        price: 400.0,
        quantity: 1,
      );
      expect(cart.subtotal, equals(600.0));
      expect(cart.deliveryCharge, equals(0.0));
      expect(cart.finalAmount, equals(600.0));
    });

    test('5. updateQuantity modifies item count and removes item when set to 0', () async {
      await cart.addItem(
        productId: 'item-mod',
        name: 'Camphor Tablets',
        price: 50.0,
        quantity: 4,
      );

      await cart.updateQuantity('item-mod', 2);
      expect(cart.items.first.quantity, equals(2));
      expect(cart.subtotal, equals(100.0));

      // Set to 0 -> should remove item
      await cart.updateQuantity('item-mod', 0);
      expect(cart.isEmpty, isTrue);
      expect(cart.subtotal, equals(0.0));
    });

    test('6. removeItem deletes the specific product from cart', () async {
      await cart.addItem(productId: 'item-a', name: 'Item A', price: 100.0);
      await cart.addItem(productId: 'item-b', name: 'Item B', price: 200.0);
      expect(cart.items.length, equals(2));

      await cart.removeItem('item-a');
      expect(cart.items.length, equals(1));
      expect(cart.items.first.productId, equals('item-b'));
    });

    test('7. toBackendItems outputs valid format required by POST /api/v1/product-orders', () async {
      await cart.addItem(productId: 'uuid-1', name: 'Item 1', price: 100.0, quantity: 2);
      await cart.addItem(productId: 'uuid-2', name: 'Item 2', price: 250.0, quantity: 1);

      final backendPayload = cart.toBackendItems();
      expect(backendPayload.length, equals(2));
      expect(backendPayload[0], equals({'productId': 'uuid-1', 'quantity': 2}));
      expect(backendPayload[1], equals({'productId': 'uuid-2', 'quantity': 1}));
    });

    test('8. Cart persists across reloads via SharedPreferences', () async {
      await cart.addItem(
        productId: 'persisted-item',
        name: 'Chandan Tika',
        price: 80.0,
        quantity: 3,
      );

      // Trigger reload from storage
      await cart.loadCart();
      expect(cart.items.length, equals(1));
      expect(cart.items.first.productId, equals('persisted-item'));
      expect(cart.items.first.quantity, equals(3));
      expect(cart.subtotal, equals(240.0));
    });

    test('9. clearCart empties cart and removes storage entry', () async {
      await cart.addItem(productId: 'temp-1', name: 'Temp', price: 50.0);
      expect(cart.isEmpty, isFalse);

      await cart.clearCart();
      expect(cart.isEmpty, isTrue);
      expect(cart.totalItemCount, equals(0));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('sarvmangal_cart_items_v1'), isFalse);
    });
  });

  group('SARV MANGAL Stage 3: CartScreen Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CartService.instance.clearCart();
    });

    testWidgets('10. Renders empty cart state when no items are added', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CartScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pooja Samagri Cart'), findsOneWidget);
      expect(find.text('Your Sacred Cart is Empty'), findsOneWidget);
      expect(find.text('Explore Sacred Store'), findsOneWidget);
      expect(find.text('Proceed to Checkout'), findsNothing);
    });

    testWidgets('11. Renders items, steppers, and Proceed to Checkout when cart has items', (tester) async {
      await CartService.instance.addItem(
        productId: 'prod-kalash',
        name: 'Brass Pooja Kalash',
        price: 350.0,
        quantity: 1,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CartScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Brass Pooja Kalash'), findsOneWidget);
      expect(find.text('Proceed to Checkout'), findsOneWidget);
      expect(find.text('Total Payable'), findsWidgets);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('12. Quantity stepper increments item quantity dynamically', (tester) async {
      await CartService.instance.addItem(
        productId: 'prod-diya',
        name: 'Pure Brass Diya',
        price: 150.0,
        quantity: 1,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CartScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);

      // Tap '+' stepper button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(CartService.instance.items.first.quantity, equals(2));
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('SARV MANGAL Stage 3: CheckoutScreen Widget & Validation Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CartService.instance.clearCart();
      await CartService.instance.addItem(
        productId: 'prod-chk',
        name: 'Kumkum & Roli Set',
        price: 200.0,
        quantity: 1,
      );
    });

    testWidgets('13. CheckoutScreen renders shipping fields and payment CTA', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CheckoutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Checkout & Delivery'), findsOneWidget);
      expect(find.text('Sacred Shipping Address'), findsOneWidget);
      expect(find.text('Place Order & Pay'), findsOneWidget);
    });

    testWidgets('14. Submitting empty shipping form triggers validation errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CheckoutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Place Order & Pay without filling address
      await tester.tap(find.text('Place Order & Pay'));
      await tester.pumpAndSettle();

      // Form validation errors should be displayed
      expect(find.text('Address Line 1 is required'), findsOneWidget);
      expect(find.text('Enter valid 6-digit PIN code'), findsOneWidget);
    });
  });

  group('SARV MANGAL Stage 3: Product Pagination and Deduplication Tests', () {
    test('15. Deduplication preserves unique products across paginated responses', () {
      final List<Map<String, dynamic>> existing = [
        {'id': 'prod-1', 'name': 'Item 1'},
        {'id': 'prod-2', 'name': 'Item 2'},
      ];

      final List<Map<String, dynamic>> nextPage = [
        {'id': 'prod-2', 'name': 'Item 2 (Duplicate)'},
        {'id': 'prod-3', 'name': 'Item 3'},
      ];

      final Set<String> existingIds = existing.map((p) => p['id'].toString()).toSet();
      for (var item in nextPage) {
        if (!existingIds.contains(item['id'].toString())) {
          existing.add(item);
          existingIds.add(item['id'].toString());
        }
      }

      expect(existing.length, equals(3));
      expect(existing.map((e) => e['id']).toList(), equals(['prod-1', 'prod-2', 'prod-3']));
    });
  });
}
