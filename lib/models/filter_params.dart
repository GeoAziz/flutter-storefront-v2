// Simple immutable filter params object used as a key for provider.family
// Keeps a small contract for future expansion (category, query, brand, price-range, sort, ...)
class FilterParams {
  final String query;
  final String category;

  const FilterParams({this.query = '', this.category = ''});

  FilterParams copyWith({String? query, String? category}) => FilterParams(
      query: query ?? this.query, category: category ?? this.category);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterParams &&
        other.query == query &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(query, category);

  @override
  String toString() => 'FilterParams(query: $query, category: $category)';
}
