/// SearchInputField widget for Phase 5
///
/// Provides a debounced text input for search with real-time suggestions overlay.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/search_provider.dart';

/// A search input field with debounced text input and optional suggestions overlay
class SearchInputField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onClear;
  final InputDecoration? decoration;
  final TextStyle? style;
  final int minCharsForSuggestions;

  const SearchInputField({
    Key? key,
    this.controller,
    this.focusNode,
    this.onClear,
    this.decoration,
    this.style,
    this.minCharsForSuggestions = 2,
  }) : super(key: key);

  @override
  ConsumerState<SearchInputField> createState() => _SearchInputFieldState();
}

class _SearchInputFieldState extends ConsumerState<SearchInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    // Populate controller with any existing search text
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      ref.read(showSuggestionsProvider.notifier).state = true;
    }
  }

  void _onTextChanged(String value) {
    // Update search text through provider
    ref.read(setSearchTextProvider)(value);

    // Show/hide suggestions based on text length
    if (value.length >= widget.minCharsForSuggestions) {
      ref.read(showSuggestionsProvider.notifier).state = true;
    } else {
      ref.read(showSuggestionsProvider.notifier).state = false;
    }
  }

  void _onClear() {
    _controller.clear();
    ref.read(setSearchTextProvider)('');
    ref.read(showSuggestionsProvider.notifier).state = false;
    widget.onClear?.call();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = ref.watch(searchTextProvider);

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onTextChanged,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: 'Search products...',
            hintStyle: TextStyle(
              color: theme.hintColor,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: _onClear,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
      style: widget.style ??
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}
