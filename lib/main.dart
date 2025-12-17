import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/config/firebase_options.dart';
import 'package:shop/config/emulator_config.dart';
import 'package:shop/route/route_names.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable emulators for local development/testing (debug mode only)
  if (kDebugMode) {
    await setupEmulators();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
