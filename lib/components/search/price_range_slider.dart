/// PriceRangeSlider widget for Phase 5
///
/// Provides dual-thumb slider for selecting min/max price range.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/search_models.dart';
import 'package:shop/providers/search_provider.dart';

/// Widget for filtering by price range using a dual-thumb slider
class PriceRangeSlider extends ConsumerStatefulWidget {
  final PriceRange availableRange;
  final EdgeInsets padding;
  final String? currencySymbol;

  const PriceRangeSlider({
    Key? key,
    required this.availableRange,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.currencySymbol = '\$',
  }) : super(key: key);

  @override
  ConsumerState<PriceRangeSlider> createState() => _PriceRangeSliderState();
}

class _PriceRangeSliderState extends ConsumerState<PriceRangeSlider> {
  late double _minPrice;
  late double _maxPrice;

  @override
  void initState() {
    super.initState();
    _minPrice = widget.availableRange.min;
    _maxPrice = widget.availableRange.max;
  }

  void _onRangeChanged(RangeValues values) {
    setState(() {
      _minPrice = values.start;
      _maxPrice = values.end;
    });

    ref.read(setPriceRangeProvider)(
      PriceRange(min: _minPrice, max: _maxPrice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedRange = ref.watch(selectedPriceRangeProvider);

    // Use selected range if available, otherwise use available range
    final currentMin = selectedRange?.min ?? _minPrice;
    final currentMax = selectedRange?.max ?? _maxPrice;

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Range',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.currencySymbol}${currentMin.toStringAsFixed(2)} - ${widget.currencySymbol}${currentMax.toStringAsFixed(2)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RangeSlider(
            values: RangeValues(currentMin, currentMax),
            min: widget.availableRange.min,
            max: widget.availableRange.max,
            divisions:
                ((widget.availableRange.max - widget.availableRange.min) * 2)
                    .toInt(), // 0.50 increments
            activeColor: theme.primaryColor,
            inactiveColor: Colors.grey[300],
            labels: RangeLabels(
              '${widget.currencySymbol}${currentMin.toStringAsFixed(0)}',
              '${widget.currencySymbol}${currentMax.toStringAsFixed(0)}',
            ),
            onChanged: _onRangeChanged,
          ),
        ],
      ),
    );
  }
}
