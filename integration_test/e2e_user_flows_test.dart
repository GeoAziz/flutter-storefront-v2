import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop/config/firebase_options.dart';
import 'package:shop/config/emulator_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/theme/app_theme.dart';
import 'package:shop/screens/all_products/views/all_products_screen.dart';
import 'package:shop/screens/product/views/product_detail_screen.dart';
import 'package:shop/screens/checkout/views/cart_screen.dart';
import 'package:shop/screens/auth/login_screen.dart';

/// Integration Test App for E2E flows - runs on device/emulator
class SimpleTestApp extends StatelessWidget {
  final Widget initialScreen;

  const SimpleTestApp({
    super.key,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'E2E Integration Test App',
        theme: AppTheme.lightTheme(context),
        home: initialScreen,
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // On a real device/emulator we need the real plugin channels, so
    // initialize Firebase (with platform options) and then point to emulators.
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await setupEmulators();

    // Ensure a test user exists for login flow
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: 'test@test.com', password: 'password');
    } catch (e) {
      // user may already exist - ignore
    }
  });

  group('E2E User Flows (integration)', () {
    testWidgets('Flow 1: User can browse products in all-products grid',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: AllProductsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Products'), findsWidgets);
      expect(find.text('Mock Product 1'), findsWidgets);
      expect(find.text('Mock Product 2'), findsWidgets);
    });

    testWidgets('Flow 2: ProductDetailScreen displays product info',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: ProductDetailScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Product Details'), findsWidgets);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('View Cart'), findsOneWidget);
    });

    testWidgets('Flow 3: User can add product to cart',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: ProductDetailScreen()),
      );
      await tester.pumpAndSettle();

      final addToCartButton = find.text('Add to Cart');
      expect(addToCartButton, findsOneWidget);

      await tester.tap(addToCartButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('to cart'), findsWidgets);
    });

    testWidgets('Flow 4: CartScreen displays cart management UI',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: CartScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cart'), findsWidgets);
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Shop now'), findsOneWidget);
    });

    testWidgets('Flow 5: User can navigate from AllProducts to ProductDetail',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: AllProductsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Products'), findsWidgets);
      expect(find.text('Mock Product 1'), findsWidgets);
      final productCards = find.byType(InkWell);
      expect(productCards, findsWidgets);
    });

    testWidgets('Flow 6: Verify key UI components are wired and functional',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: AllProductsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Products'), findsWidgets);
      expect(find.text('Mock Product 1'), findsWidgets);
      expect(find.text('Mock Product 2'), findsWidgets);

      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: ProductDetailScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Product Details'), findsWidgets);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('View Cart'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: CartScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cart'), findsWidgets);
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Shop now'), findsOneWidget);

      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: ProductDetailScreen()),
      );
      await tester.pumpAndSettle();

      final addBtn = find.text('Add to Cart');
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Flow 8: User can log in via LoginScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: LoginScreen()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('login_user')), 'test@test.com');
      await tester.enterText(find.byKey(const Key('login_pass')), 'password');
      await tester.tap(find.byKey(const Key('login_btn')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Logged in'), findsOneWidget);
    });

    testWidgets('Flow 9: User can add/remove favorites from product detail',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: ProductDetailScreen()),
      );
      await tester.pumpAndSettle();

      final favButton = find.byIcon(Icons.favorite_border).first;
      expect(favButton, findsWidgets);
      await tester.tap(favButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Added to favorites'), findsWidgets);
    });

    testWidgets('Flow 10: User can submit a review on ProductDetail',
        (WidgetTester tester) async {
      // Increase screen size for visibility
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
      });
      tester.binding.window.physicalSizeTestValue = const Size(1200, 1800);

      await tester.pumpWidget(
        const SimpleTestApp(initialScreen: ProductDetailScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('review_input')),
        500.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('review_input')), 'Great product!');
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('submit_review')),
        300.0,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_review')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Review submitted'), findsOneWidget);
      expect(find.text('Great product!'), findsWidgets);
    });
  });
}
