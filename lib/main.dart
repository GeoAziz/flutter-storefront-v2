import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/config/firebase_options.dart';
import 'package:shop/config/emulator_config.dart';
import 'package:shop/route/route_names.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/theme/app_theme.dart';
import 'services/service_locator.dart';
import 'repositories/wishlist_repository.dart';
import 'repositories/comparison_repository.dart';
import 'services/firebase_service.dart';
import 'utils/device_cache_config.dart';
import 'utils/image_cache_manager.dart';

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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Log initial auth state after first frame so Firebase has a chance to restore.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      try {
        // ignore: avoid_print
        print('[app] init: currentUser=${user?.uid}');
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // On resume, log current Firebase user and refresh auth provider to
      // ensure UI waits for restored auth state rather than treating a
      // transient null as signed-out.
      final user = FirebaseAuth.instance.currentUser;
      try {
        // ignore: avoid_print
        print('[app] resumed: currentUser=${user?.uid}');
      } catch (_) {}
      // Refresh the provider so listeners re-evaluate quickly.
      try {
        // trigger a refresh and ignore returned value
        final _ = ref.refresh(firebaseAuthStateProvider);
      } catch (_) {}
    }
  }

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
