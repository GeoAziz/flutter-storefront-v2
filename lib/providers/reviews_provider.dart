import 'package:flutter_riverpod/flutter_riverpod.dart';

class Review {
  final String userId;
  final String text;
  final int rating;

  Review({required this.userId, required this.text, this.rating = 5});
}

class ReviewsNotifier extends StateNotifier<Map<String, List<Review>>> {
  ReviewsNotifier() : super({});

  void addReview(String productId, Review review) {
    final existing = state[productId] ?? [];
    state = {
      ...state,
      productId: [...existing, review]
    };
  }

  List<Review> forProduct(String productId) => state[productId] ?? [];
}

final reviewsProvider =
    StateNotifierProvider<ReviewsNotifier, Map<String, List<Review>>>(
  (ref) => ReviewsNotifier(),
);
