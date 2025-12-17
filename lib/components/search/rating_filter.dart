/// RatingFilter widget for Phase 5
///
/// Displays star rating selection buttons for minimum rating filter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/search_provider.dart';

/// Widget for filtering by minimum star rating
class RatingFilter extends ConsumerWidget {
  final EdgeInsets padding;
  final double starSize;

  const RatingFilter({
    Key? key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.starSize = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedRating = ref.watch(selectedMinRatingProvider);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minimum Rating',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Clear/Reset button
              TextButton.icon(
                onPressed: () {
                  ref.read(setMinRatingProvider)(null);
                },
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Any'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(
                      color: selectedRating == null
                          ? theme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Star rating buttons
              ...List.generate(5, (index) {
                final rating = (index + 1).toDouble();
                final isSelected = selectedRating == rating;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(setMinRatingProvider)(rating);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? theme.primaryColor
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        color: isSelected
                            ? theme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(
                            rating.toInt(),
                            (i) => Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${rating.toInt()}+',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? theme.primaryColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
