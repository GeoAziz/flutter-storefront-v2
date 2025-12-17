// This is a template showing how to initialize Firebase and all services
// Copy this into your main.dart file and adapt as needed

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'firebase_options.dart';
import 'services/offline_sync_service.dart';
import 'config/firebase_config.dart';

// ╔════════════════════════════════════════════════════════════════════════╗
// ║  MAIN APPLICATION ENTRY POINT                                          ║
// ║  Initializes Firebase, Offline Sync, and Analytics                     ║
// ╚════════════════════════════════════════════════════════════════════════╝

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry for error tracking (optional but recommended)
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN_HERE'; // Get from sentry.io
      options.tracesSampleRate = 1.0;
      options.environment = 'production'; // or 'development', 'staging'
    },
    appRunner: () => _initializeApp(),
  );
}

/// Initialize all services before running the app
Future<void> _initializeApp() async {
  try {
    // 1. Initialize Firebase with platform-specific options
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // 2. Initialize Firebase Config with multi-environment support
    print('⚙️  Initializing Firebase Config...');
    await FirebaseConfig.initialize();
    print('✅ Firebase Config initialized');

    // 3. Initialize Offline Sync Service for local queue management
    print('💾 Initializing Offline Sync Service...');
    await OfflineSyncService.instance.initialize();
    print('✅ Offline Sync Service initialized');

    // 4. Initialize Firebase Analytics
    print('📊 Initializing Firebase Analytics...');
    await FirebaseAnalytics.instance.logAppOpen();
    print('✅ Firebase Analytics initialized');

    // 5. Monitor connectivity for offline sync triggers
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print('📡 Connection restored, syncing offline operations...');
        OfflineSyncService.instance.syncAllOperations();
      } else {
        print('📡 Connection lost, queuing operations for later');
      }
    });

    // 6. Run the app
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('❌ Initialization Error: $e');
    print('Stack Trace: $stackTrace');

    // Show error UI or restart app
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize app:\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// ╔════════════════════════════════════════════════════════════════════════╗
// ║  MAIN APP WIDGET                                                       ║
// ║  Root widget with Riverpod integration                                 ║
// ╚════════════════════════════════════════════════════════════════════════╝

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Use your app configuration
      title: 'PoAFix E-Commerce',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,

      // Route configuration
      home: const HomePage(),
      // Add your routes here
    );
  }
}

// ╔════════════════════════════════════════════════════════════════════════╗
// ║  HOME PAGE - Replace with your actual home screen                      ║
// ║  This template shows how to access auth and product providers          ║
// ╚════════════════════════════════════════════════════════════════════════╝

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state - automatically rebuilds when auth changes
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Authentication Error: $error'),
        ),
      ),
      data: (user) {
        if (user == null) {
          // User not authenticated - show login screen
          return const LoginScreen();
        } else {
          // User authenticated - show main app
          return const MainApp();
        }
      },
    );
  }
}

// ╔════════════════════════════════════════════════════════════════════════╗
// ║  EXAMPLE: LOGIN SCREEN                                                 ║
// ║  Demonstrates auth_provider usage                                      ║
// ╚════════════════════════════════════════════════════════════════════════╝

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final user = await ref.read(
                    signInProvider(
                      SignInParams(
                        email: _emailController.text,
                        password: _passwordController.text,
                      ),
                    ).future,
                  );
                  // User successfully logged in
                  print('✅ Logged in as: ${user.email}');
                } catch (e) {
                  // Handle error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Login failed: $e')),
                  );
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ╔════════════════════════════════════════════════════════════════════════╗
// ║  EXAMPLE: MAIN APP                                                     ║
// ║  Demonstrates product_provider and other providers usage               ║
// ╚════════════════════════════════════════════════════════════════════════╝

class MainApp extends ConsumerWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch products stream
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PoAFix Shop'),
        actions: [
          // Watch cart count
          ref.watch(cartItemCountProvider).when(
            data: (count) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text('🛒 $count'),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('?'),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading products: $error'),
        ),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              trailing: IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () {
                  // Add to cart
                  ref.read(
                    addToCartProvider(
                      AddToCartParams(
                        productId: product.id,
                        quantity: 1,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ╔════════════════════════════════════════════════════════════════════════╗
// ║  INITIALIZATION NOTES                                                   ║
// ╚════════════════════════════════════════════════════════════════════════╝

/*
 * IMPORTANT SETUP STEPS:
 * 
 * 1. FIREBASE CREDENTIALS
 *    ✓ Already configured in lib/config/firebase_options.dart
 *    ✓ Android: google-services.json is in the project
 *    ✓ iOS: Download GoogleService-Info.plist from Firebase Console
 *           Add to Xcode: Runner → Runner → Build Phases → Copy Bundle Resources
 * 
 * 2. FIRESTORE SECURITY RULES
 *    ✓ Run: ./deploy-firebase.sh
 *    ✓ Or: firebase deploy --only firestore:rules
 * 
 * 3. DEPENDENCIES
 *    ✓ Run: flutter pub get
 * 
 * 4. ENVIRONMENT SETUP
 *    - Update FirebaseConfig.environment as needed
 *    - development: Full logging, 100MB cache
 *    - staging: Reduced logging, 50MB cache
 *    - production: Minimal logging, 10MB cache (Spark Plan)
 * 
 * 5. OFFLINE SYNC
 *    ✓ Automatically initialized in _initializeApp()
 *    ✓ Queues operations when offline
 *    ✓ Syncs automatically when connectivity restored
 * 
 * 6. ANALYTICS
 *    ✓ Firebase Analytics initialized
 *    ✓ Sentry for error tracking (optional)
 *    ✓ Connectivity monitoring for sync triggers
 * 
 * 7. ERROR HANDLING
 *    - All services have comprehensive error handling
 *    - Check AuthenticationException and FirestoreException classes
 *    - Sync errors stored in OfflineSyncService.getPendingConflicts()
 * 
 * 8. TESTING
 *    - Use Firebase Emulator for development
 *    - Enable offline mode for offline testing
 *    - Monitor Firestore in Firebase Console
 */
