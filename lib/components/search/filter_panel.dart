/// FilterPanel widget for Phase 5
///
/// Combines all search filters into a collapsible panel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/search/category_filter.dart';
import 'package:shop/components/search/price_range_slider.dart';
import 'package:shop/components/search/rating_filter.dart';
import 'package:shop/components/search/sort_dropdown.dart';
import 'package:shop/models/search_models.dart';
import 'package:shop/providers/search_provider.dart';

/// Collapsible panel containing all search filters
class FilterPanel extends ConsumerStatefulWidget {
  final EdgeInsets padding;
  final double minHeight;
  final bool initiallyExpanded;

  const FilterPanel({
    Key? key,
    this.padding = const EdgeInsets.all(16),
    this.minHeight = 56,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.initiallyExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilters = ref.watch(hasActiveFiltersProvider);
    final availableFiltersAsync = ref.watch(availableFiltersProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filter panel header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune,
                    size: 20,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  if (hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        // Call the reset action returned by the provider
                        ref.read(resetSearchProvider)();
                      },
                      child: const Text('Reset'),
                    ),
                  IconButton(
                    icon: AnimatedRotation(
                      turns: _animationController.value,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more,
                        color: theme.primaryColor,
                      ),
                    ),
                    onPressed: _togglePanel,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Expandable filter content
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _animationController.value,
                child: child,
              ),
            );
          },
          child: availableFiltersAsync.when(
            data: (filters) {
              return _FilterContent(filters: filters);
            },
            loading: () => Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor,
                ),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading filters',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Filter content widget
class _FilterContent extends StatelessWidget {
  final AvailableFilters filters;

  const _FilterContent({required this.filters});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Categories
          if (filters.categories.isNotEmpty) ...[
            CategoryFilter(categories: filters.categories),
            const Divider(height: 1),
          ],
          // Price range
          PriceRangeSlider(availableRange: filters.priceRange),
          const Divider(height: 1),
          // Rating
          const RatingFilter(),
          const Divider(height: 1),
          // Sort
          const SortDropdown(),
          // Apply button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                // Dismiss filter panel and apply
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Apply Filters'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
