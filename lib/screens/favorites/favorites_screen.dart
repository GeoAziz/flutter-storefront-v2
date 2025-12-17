import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: favs.isEmpty
            ? const Center(child: Text('No favorites yet'))
            : ListView(
                children: favs.map((id) => ListTile(title: Text(id))).toList(),
              ),
      ),
    );
  }
}
