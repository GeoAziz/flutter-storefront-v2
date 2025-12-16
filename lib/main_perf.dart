import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/constants.dart';
import 'package:shop/services/service_locator.dart';
import 'package:shop/theme/theme_data.dart';
import 'package:shop/repository/search_repository.dart';
import 'package:shop/providers/search_repository_provider.dart';
import 'package:shop/screens/search/views/search_screen.dart';

/// Minimal profiling app that directly launches SearchScreen with seeded 500-product repo.
/// This bypasses full app initialization and focuses only on search performance.
Future<void> main() async {
  // Initialize minimal services (cache, telemetry)
  await initServices();

  runApp(const PerfApp());
}

class PerfApp extends ConsumerWidget {
  const PerfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Override searchRepositoryProvider to use seeded repo with 500 products
    return ProviderScope(
      overrides: [
        searchRepositoryProvider
            .overrideWithValue(MockSearchRepository.seeded(500)),
      ],
      child: MaterialApp(
        title: 'Search Profiling (500 products)',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.light,
        home: const SearchScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
