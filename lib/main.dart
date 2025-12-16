import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/route/route_names.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/theme/app_theme.dart';
import 'services/service_locator.dart';
import 'repositories/wishlist_repository.dart';
import 'repositories/comparison_repository.dart';
import 'services/firebase_service.dart';

// Initialize services (cache + telemetry) before running the app. This is done
// behind feature flags set in `lib/constants.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (local emulator or real project can be configured later)
  await FirebaseService.initialize();

  // Initialize repositories for Wishlist and Comparison features
  final wishlistRepo = WishlistRepository();
  await wishlistRepo.init();
  
  final comparisonRepo = ComparisonRepository();
  await comparisonRepo.init();
  
  await initServices();
  // Use ProviderScope to enable Riverpod providers across the app.
  runApp(const ProviderScope(child: MyApp()));
}

// Thanks for using our template. You are using the free version of the template.
// 🔗 Full template: https://theflutterway.gumroad.com/l/fluttershop

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shop Template by The Flutter Way',
      theme: AppTheme.lightTheme(context),
      // Dark theme is inclided in the Full template
      themeMode: ThemeMode.light,
      onGenerateRoute: router.generateRoute,
      initialRoute: RouteNames.onboarding,
    );
  }
}
