import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/reviews_provider.dart';

class ReviewsSection extends ConsumerStatefulWidget {
  final String productId;
  const ReviewsSection({super.key, required this.productId});

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsMap = ref.watch(reviewsProvider);
    final reviews = reviewsMap[widget.productId] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final r in reviews)
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(r.userId),
              subtitle: Text(r.text),
              trailing: Text('${r.rating}/5'),
            ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('review_input'),
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Add a review',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('submit_review'),
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isEmpty) return;
              ref.read(reviewsProvider.notifier).addReview(
                    widget.productId,
                    Review(userId: 'test_user', text: text, rating: 5),
                  );
              _controller.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review submitted')));
            },
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }
}
