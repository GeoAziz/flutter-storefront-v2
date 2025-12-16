/// SearchSuggestionsOverlay widget for Phase 5
///
/// Displays search suggestions in a dropdown overlay below the search input.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/search_provider.dart';

/// Widget for displaying search suggestions in an overlay
class SearchSuggestionsOverlay extends ConsumerWidget {
  final TextEditingController textController;
  final Offset position;
  final double width;
  final VoidCallback? onSuggestionSelected;

  const SearchSuggestionsOverlay({
    Key? key,
    required this.textController,
    required this.position,
    required this.width,
    this.onSuggestionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSuggestions = ref.watch(showSuggestionsProvider);
    final suggestionsAsync = ref.watch(searchSuggestionsProvider);
    final theme = Theme.of(context);

    if (!showSuggestions) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: position.dy,
      left: position.dx,
      width: width,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE8E8E8)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxHeight: 300),
          child: suggestionsAsync.when(
            data: (suggestions) {
              if (suggestions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Text(
                    'No suggestions found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return _SuggestionTile(
                    suggestion: suggestion,
                    onTap: () {
                      textController.text = suggestion;
                      ref.read(setSearchTextProvider)(suggestion);
                      ref.read(showSuggestionsProvider.notifier).state = false;
                      onSuggestionSelected?.call();
                    },
                  );
                },
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading suggestions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red[600],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual suggestion tile
class _SuggestionTile extends StatelessWidget {
  final String suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Icon(
        Icons.search,
        size: 18,
        color: Colors.grey[600],
      ),
      title: Text(
        suggestion,
        style: theme.textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.arrow_outward,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}
