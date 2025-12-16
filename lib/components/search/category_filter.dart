/// CategoryFilter widget for Phase 5
/// 
/// Displays selectable category filter chips with item counts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/search_models.dart';
import 'package:shop/providers/search_provider.dart';

/// Widget for filtering by category using multi-select chips
class CategoryFilter extends ConsumerWidget {
  final List<CategoryOption> categories;
  final EdgeInsets padding;
  final Axis scrollDirection;

  const CategoryFilter({
    Key? key,
    required this.categories,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.scrollDirection = Axis.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategories = ref.watch(selectedCategoriesProvider);
    final theme = Theme.of(context);

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: scrollDirection,
      child: Padding(
        padding: padding,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          direction: scrollDirection,
          children: categories.map((category) {
            final isSelected = selectedCategories.contains(category.id);

            return FilterChip(
              selected: isSelected,
              label: Text(
                '${category.name} (${category.count})',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.grey[100],
              selectedColor: theme.primaryColor,
              side: BorderSide(
                color: isSelected ? theme.primaryColor : Colors.grey[300]!,
                width: 1,
              ),
              onSelected: (_) {
                ref.read(toggleCategoryProvider)(category.id);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
