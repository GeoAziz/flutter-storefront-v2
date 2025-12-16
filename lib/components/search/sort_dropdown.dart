/// SortDropdown widget for Phase 5
///
/// Provides dropdown for selecting search result sort order.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/search_models.dart';
import 'package:shop/providers/search_provider.dart';

/// Map of SearchSortBy enum to user-friendly labels
const Map<SearchSortBy, String> _sortLabels = {
  SearchSortBy.relevance: 'Most Relevant',
  SearchSortBy.popularity: 'Most Popular',
  SearchSortBy.priceAsc: 'Price: Low to High',
  SearchSortBy.priceDesc: 'Price: High to Low',
  SearchSortBy.ratingDesc: 'Highest Rated',
  SearchSortBy.newest: 'Newest First',
};

/// Widget for selecting search result sort order
class SortDropdown extends ConsumerWidget {
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const SortDropdown({
    Key? key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedSort = ref.watch(searchSortByProvider);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE8E8E8)),
              borderRadius: borderRadius,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SearchSortBy>(
                value: selectedSort,
                items: SearchSortBy.values.map((sort) {
                  return DropdownMenuItem(
                    value: sort,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _sortLabels[sort] ?? sort.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (sort) {
                  if (sort != null) {
                    ref.read(setSortByProvider)(sort);
                  }
                },
                isExpanded: true,
                icon: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.unfold_more,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
