# Phase 5 RFC: Search & Filtering Enhancements

**Document Version**: 1.0  
**Date**: December 16, 2025  
**Phase**: 5 (Search & Filtering)  
**Status**: Ready for Implementation  

---

## Executive Summary

Phase 5 introduces intelligent search with real-time filtering, sorting, and caching. Users can now find products faster through debounced search input, category/price/rating filters, and multiple sort options. Search results are cached with TTL for improved performance. All features maintain 60 FPS performance and <50MB memory usage.

**Expected Timeline**: 2-3 weeks  
**Key Dependencies**: Phase 1-4 (completed)  
**High-Level Architecture**: See [Architecture Section](#architecture)

---

## 1. Objectives & Key Results

### Objectives
1. Enable users to find products quickly via intelligent search with auto-suggestions
2. Implement multi-dimensional filtering (category, price, rating) with pagination
3. Support sorting by popularity, price, and rating
4. Cache search results to reduce server load and improve performance
5. Maintain product discovery experience across all screen sizes

### Key Results
- ✅ Debounced search input (300ms) with real-time suggestions
- ✅ Category filter with multi-select support
- ✅ Price range filter (slider-based)
- ✅ Rating filter (5-star scale with step increments)
- ✅ Sorting options (relevance, popularity, price ASC/DESC, rating)
- ✅ Search result caching with 1-hour TTL
- ✅ 100% backward compatible
- ✅ 60 FPS performance maintained
- ✅ <50MB memory for typical usage
- ✅ >95% test coverage for new features

---

## 2. Current State Analysis

### What Exists
- ✅ Pagination foundation (cursor & page-based)
- ✅ PaginatedProductList component
- ✅ SearchScreen (static, no filters)
- ✅ OnSaleScreen (grid layout)
- ✅ Product model with price, rating data
- ✅ Cache architecture (Memory L1 + Hive L2)
- ✅ Telemetry system (Sentry + DevTelemetry)
- ✅ Service locator pattern

### What's Missing
- ❌ Debounced search input
- ❌ Real-time suggestions/auto-complete
- ❌ Category filter UI & logic
- ❌ Price range filter UI & logic
- ❌ Rating filter UI & logic
- ❌ Sorting options (UI + backend integration)
- ❌ Search result caching
- ❌ Search history (user interactions)
- ❌ Search telemetry (search queries, filter usage)

### Product Model Current State
```dart
class Product {
  final String id;
  final String title;
  final String image;
  final double price;
  final double? priceAfterDiscount;
  final int? discountPercent;
  
  // MISSING (need to add for Phase 5):
  // final String? category;
  // final double? rating;
  // final int? reviewCount;
  // final List<String>? tags;
}
```

---

## 3. Proposed Solution Architecture

### 3.1 High-Level Design

```
SearchScreen
├── SearchInputField (debounced)
│   └── SearchSuggestionsOverlay
├── FilterPanel (collapsible)
│   ├── CategoryFilter (multi-select)
│   ├── PriceRangeSlider
│   └── RatingFilter
├── SortDropdown
├── PaginatedProductList (filtered + sorted results)
└── SearchHistoryPanel (optional)
```

### 3.2 Data Flow

```
User Input
    ↓
SearchInputField (debounce 300ms)
    ↓
SearchQueryProvider (Riverpod state)
    ↓
SearchRepositoryProvider (fetch)
    ↓
SearchCache (check L1/L2)
    ↓
API (if miss)
    ↓
CacheResult (L1/L2)
    ↓
PaginatedProductList (filtered + sorted)
    ↓
UI (60 FPS)
```

### 3.3 New Abstractions & DTOs

#### SearchQuery
```dart
class SearchQuery {
  final String? text;                // "blue shirt" or null
  final Set<String>? categories;     // ['electronics', 'clothing']
  final PriceRange? priceRange;      // min: 10, max: 100
  final double? minRating;           // >= 4.0
  final SearchSortBy sortBy;         // relevance, popularity, price_asc, etc
  final int pageSize;
  final String? cursor;
  
  bool get isEmpty => text == null && categories == null && priceRange == null;
  String toCacheKey() => ...
}

class PriceRange {
  final double min;
  final double max;
}

enum SearchSortBy {
  relevance,
  popularity,
  priceAsc,
  priceDesc,
  ratingDesc,
  newest,
}
```

#### SearchResult
```dart
class SearchResult extends PaginationResult<Product> {
  final SearchQuery query;
  final int totalResults;
  final List<String> suggestedQueries; // ["blue shirt", "blue dress", ...]
  final Map<String, int> availableCategories; // {"electronics": 45, "clothing": 23}
  final PriceRange availablePriceRange; // actual min/max in filtered results
}
```

#### SearchFilter
```dart
class SearchFilter {
  final Set<String> selectedCategories;
  final PriceRange? priceRange;
  final double? minRating;
  
  bool get hasActiveFilters =>
    selectedCategories.isNotEmpty || 
    priceRange != null || 
    minRating != null;
}
```

### 3.4 New Services

#### SearchRepository
```dart
abstract class SearchRepository {
  /// Perform a search with filters and pagination
  Future<SearchResult> search(SearchQuery query);
  
  /// Get search suggestions for user input
  Future<List<String>> getSuggestions(String partial);
  
  /// Get available categories (for filter UI)
  Future<List<CategoryOption>> getCategories();
  
  /// Get price range bounds
  Future<PriceRange> getPriceRange();
}
```

**Implementation Strategy**:
- For MVP: Mock implementation that filters in-memory Product list
- Future: Real backend integration with Elasticsearch or similar
- Caching: L1 (Memory) + L2 (Hive) with 1-hour TTL

#### SearchCache
```dart
abstract class SearchCache {
  Future<SearchResult?> get(String cacheKey, {int maxAgeSeconds = 3600});
  Future<void> put(String cacheKey, SearchResult result);
  Future<void> clearOlderThan(Duration age);
}
```

**Extends existing cache architecture**:
- Uses HiveCache for persistence
- Falls back to MemoryCache if Hive unavailable
- Automatic TTL management

### 3.5 Providers (Riverpod)

```dart
// Current search text (controlled by SearchInputField)
final searchTextProvider = StateProvider<String>((ref) => '');

// Active filters
final searchFilterProvider = StateProvider<SearchFilter>((ref) => SearchFilter());

// Sort option
final searchSortProvider = StateProvider<SearchSortBy>((ref) => SearchSortBy.relevance);

// Combined search query (computed from text + filters + sort)
final searchQueryProvider = Provider<SearchQuery>((ref) {
  final text = ref.watch(searchTextProvider);
  final filter = ref.watch(searchFilterProvider);
  final sort = ref.watch(searchSortProvider);
  
  return SearchQuery(
    text: text.isEmpty ? null : text,
    categories: filter.selectedCategories.isEmpty ? null : filter.selectedCategories,
    priceRange: filter.priceRange,
    minRating: filter.minRating,
    sortBy: sort,
  );
});

// Search results (paginated)
final searchResultsProvider = StateNotifierProvider<
  SearchResultNotifier,
  SearchResultState
>((ref) {
  final repo = ref.read(searchRepositoryProvider);
  final cache = ref.read(searchCacheProvider);
  return SearchResultNotifier(repo, cache);
});

// Search suggestions
final searchSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final text = ref.watch(searchTextProvider);
  if (text.isEmpty) return [];
  
  final repo = ref.read(searchRepositoryProvider);
  return repo.getSuggestions(text);
});

// Available filters (categories, price range)
final availableFiltersProvider = FutureProvider<AvailableFilters>((ref) async {
  final repo = ref.read(searchRepositoryProvider);
  final categories = await repo.getCategories();
  final priceRange = await repo.getPriceRange();
  
  return AvailableFilters(categories, priceRange);
});
```

---

## 4. Implementation Plan

### Phase 5.1: Foundation (Week 1)
- ✅ Add to Product model: `category`, `rating`, `reviewCount`, `tags`
- ✅ Create SearchQuery, SearchFilter, SearchResult DTOs
- ✅ Create SearchRepository (mock implementation)
- ✅ Create SearchCache (wrapper around existing cache)
- ✅ Create Riverpod providers
- ✅ Unit tests for new DTOs and providers

### Phase 5.2: UI Components (Week 1-2)
- ✅ SearchInputField with debounced state management
- ✅ SearchSuggestionsOverlay (dropdown with suggestions)
- ✅ CategoryFilter widget (multi-select chips)
- ✅ PriceRangeSlider widget
- ✅ RatingFilter widget (star buttons)
- ✅ SortDropdown widget
- ✅ FilterPanel (collapsible container)
- ✅ Integration tests for UI components

### Phase 5.3: Screen Integration (Week 2)
- ✅ Update SearchScreen to use new components
- ✅ Wire providers to UI widgets
- ✅ Add filter persistence (optional for MVP)
- ✅ Update OnSaleScreen with filters/sorting (optional)
- ✅ E2E tests for search flow

### Phase 5.4: Optimization & Polish (Week 2-3)
- ✅ Performance profiling (60 FPS validation)
- ✅ Memory optimization (target <50MB)
- ✅ Debounce tuning (300ms optimal?)
- ✅ Cache TTL tuning (1-hour optimal?)
- ✅ Error handling & recovery
- ✅ Accessibility review
- ✅ Documentation & examples

### Phase 5.5: Testing & CI (Week 3)
- ✅ Unit test coverage (90%+)
- ✅ Integration test coverage
- ✅ CI/CD pipeline validation
- ✅ Code quality checks
- ✅ Final QA sign-off

---

## 5. Detailed Feature Specifications

### 5.1 Debounced Search Input

**User Flow**:
1. User taps SearchInputField
2. Types characters (e.g., "blue sh")
3. Debounce timer starts (300ms)
4. Suggestions appear in overlay (if text.length >= 2)
5. User selects suggestion or continues typing
6. Search executes when debounce timer completes

**Implementation**:
```dart
class SearchInputField extends ConsumerWidget {
  const SearchInputField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchText = ref.watch(searchTextProvider);
    final suggestions = ref.watch(searchSuggestionsProvider);
    
    return Column(
      children: [
        TextField(
          onChanged: (value) {
            // Debounce via ref.read(searchTextProvider.notifier).state = value
            _updateSearchWithDebounce(ref, value);
          },
          decoration: InputDecoration(
            hintText: 'Search products...',
            suffixIcon: searchText.isNotEmpty ? ClearButton() : SearchIcon(),
          ),
        ),
        // Suggestions overlay
        if (suggestions.when(
          data: (list) => list.isNotEmpty,
          loading: () => false,
          error: (_, __) => false,
        ))
          SearchSuggestionsOverlay(suggestions: suggestions),
      ],
    );
  }
}
```

**Telemetry Events**:
- `search_input_started` — when user starts typing
- `search_query_submitted` — when search executes
- `search_suggestion_selected` — when user taps suggestion

### 5.2 Category Filter

**Data**:
- Categories fetched from backend (or hardcoded for MVP)
- Multi-select (user can select multiple)
- Display as chips with count (e.g., "Electronics (45)")

**UI**:
```dart
class CategoryFilter extends ConsumerWidget {
  const CategoryFilter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(searchFilterProvider);
    final available = ref.watch(availableFiltersProvider);
    
    return Wrap(
      children: available.when(
        data: (f) => f.categories.map((cat) {
          final isSelected = filter.selectedCategories.contains(cat.id);
          return FilterChip(
            label: Text('${cat.name} (${cat.count})'),
            selected: isSelected,
            onSelected: (selected) {
              // Toggle category
              var updated = Set<String>.from(filter.selectedCategories);
              if (selected) {
                updated.add(cat.id);
              } else {
                updated.remove(cat.id);
              }
              ref.read(searchFilterProvider.notifier).state = 
                filter.copyWith(selectedCategories: updated);
            },
          );
        }).toList(),
        loading: () => [const ShimmerChip()],
        error: (_, __) => [],
      ),
    );
  }
}
```

**Telemetry Events**:
- `filter_category_selected` — {category: "electronics"}
- `filter_category_cleared` — {category: "electronics"}

### 5.3 Price Range Filter

**Data**:
- Min/max prices from available products
- Slider UI with dual thumbs (min & max)
- Display current range (e.g., "$10 - $100")

**UI**:
```dart
class PriceRangeSlider extends ConsumerWidget {
  const PriceRangeSlider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(searchFilterProvider);
    final available = ref.watch(availableFiltersProvider);
    
    return available.when(
      data: (f) {
        final currentMin = filter.priceRange?.min ?? f.priceRange.min;
        final currentMax = filter.priceRange?.max ?? f.priceRange.max;
        
        return Column(
          children: [
            Text('Price: \$$currentMin - \$$currentMax'),
            RangeSlider(
              min: f.priceRange.min,
              max: f.priceRange.max,
              start: currentMin,
              end: currentMax,
              onChanged: (range) {
                ref.read(searchFilterProvider.notifier).state = 
                  filter.copyWith(
                    priceRange: PriceRange(
                      min: range.start,
                      max: range.end,
                    ),
                  );
              },
            ),
          ],
        );
      },
      loading: () => const ShimmerSlider(),
      error: (_, __) => const SizedBox(),
    );
  }
}
```

**Telemetry Events**:
- `filter_price_changed` — {min: 10, max: 100}
- `filter_price_cleared`

### 5.4 Rating Filter

**Data**:
- 5 star rating options (1-5 stars, or 4+ stars, 3+ stars, etc.)
- Show filter count for each option

**UI**:
```dart
class RatingFilter extends ConsumerWidget {
  const RatingFilter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(searchFilterProvider);
    
    return Column(
      children: [1.0, 2.0, 3.0, 4.0, 5.0].map((rating) {
        final isSelected = filter.minRating == rating;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StarRating(rating: rating, size: 16),
              const SizedBox(width: 8),
              Text('& up'),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            ref.read(searchFilterProvider.notifier).state = 
              filter.copyWith(
                minRating: selected ? rating : null,
              );
          },
        );
      }).toList(),
    );
  }
}
```

**Telemetry Events**:
- `filter_rating_changed` — {min_rating: 4.0}
- `filter_rating_cleared`

### 5.5 Sorting Options

**Options**:
1. Relevance (default for text search)
2. Popularity (most viewed/sold)
3. Price: Low to High
4. Price: High to Low
5. Rating: Highest First
6. Newest First

**UI**:
```dart
class SortDropdown extends ConsumerWidget {
  const SortDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(searchSortProvider);
    
    return DropdownButton<SearchSortBy>(
      value: currentSort,
      items: SearchSortBy.values.map((sort) {
        return DropdownMenuItem(
          value: sort,
          child: Text(_sortLabel(sort)),
        );
      }).toList(),
      onChanged: (newSort) {
        if (newSort != null) {
          ref.read(searchSortProvider.notifier).state = newSort;
        }
      },
    );
  }

  String _sortLabel(SearchSortBy sort) {
    switch (sort) {
      case SearchSortBy.relevance: return 'Relevance';
      case SearchSortBy.popularity: return 'Popularity';
      case SearchSortBy.priceAsc: return 'Price: Low to High';
      case SearchSortBy.priceDesc: return 'Price: High to Low';
      case SearchSortBy.ratingDesc: return 'Rating: Highest First';
      case SearchSortBy.newest: return 'Newest First';
    }
  }
}
```

**Telemetry Events**:
- `sort_changed` — {sort_by: "price_asc"}

### 5.6 Search Result Caching

**Strategy**:
- Cache key: `search:{query_hash}:{sort}` (MD5 of search text, filters, sort)
- TTL: 1 hour (configurable)
- Storage: HiveCache (L2) + MemoryCache (L1)
- Eviction: LRU + age-based

**Implementation**:
```dart
class SearchCache implements SearchCache {
  final CacheProvider cache;
  
  static const String keyPrefix = 'search_result:';
  static const int defaultTtlSeconds = 3600; // 1 hour
  
  Future<SearchResult?> get(String queryHash, {int maxAgeSeconds = 3600}) async {
    final key = '$keyPrefix$queryHash';
    final cached = await cache.get(key);
    
    if (cached != null) {
      // Check age
      // if age > maxAgeSeconds, evict and return null
      // else return deserialized result
    }
    return null;
  }
  
  Future<void> put(String queryHash, SearchResult result) async {
    final key = '$keyPrefix$queryHash';
    final serialized = _serializeResult(result);
    await cache.set(key, serialized, ttl: Duration(seconds: defaultTtlSeconds));
  }
}
```

**Telemetry Events**:
- `search_cache_hit` — {query_hash: "abc123"}
- `search_cache_miss` — {query_hash: "abc123"}
- `search_cache_evicted` — {count: 5, reason: "age"}

---

## 6. Backward Compatibility

**What Stays the Same**:
- ✅ `ProductRepository.fetchProducts()` — unchanged
- ✅ `PaginatedProductList` — unchanged
- ✅ `Product` model — backward compatible (new fields optional)
- ✅ Existing screens (Home, OnSale) — can ignore new features

**What's New**:
- 🆕 `SearchRepository` — new abstraction
- 🆕 `SearchQuery`, `SearchFilter`, `SearchResult` — new DTOs
- 🆕 Riverpod providers for search
- 🆕 UI components for search/filters
- 🆕 Updated SearchScreen with new UI

**Migration Path**:
```dart
// Old SearchScreen (still works)
class SearchScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginatedProductList(...); // works as before
  }
}

// New SearchScreen (with filters & search)
class SearchScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SearchInputField(),
        FilterPanel(),
        SortDropdown(),
        PaginatedProductList(...), // now filtered + sorted
      ],
    );
  }
}
```

---

## 7. Testing Strategy

### Unit Tests (60% of coverage)
- SearchQuery immutability and serialization
- SearchFilter state transitions
- SearchRepository mock implementations
- Cache key generation and lookup
- Provider state management

### Integration Tests (30% of coverage)
- Search flow end-to-end
- Filter application + pagination interaction
- Cache hit/miss scenarios
- Debounce timing
- Error recovery

### UI Tests (10% of coverage)
- SearchInputField focus/blur
- Filter widget interactions
- Suggestion overlay display
- Loading/error states

### Performance Tests
- Debounce timing (target: 300ms)
- Search latency (target: <200ms for cached results)
- Memory usage (target: <50MB for 500+ filtered results)
- Frame rate (target: 60 FPS during scroll + filter changes)

---

## 8. Telemetry & Monitoring

### Events to Track

| Event | Properties | Purpose |
|-------|-----------|---------|
| `search_input_started` | query_length | Measure search adoption |
| `search_query_submitted` | query, filters_count, sort_by | Track query patterns |
| `search_suggestion_selected` | suggestion | Measure auto-complete effectiveness |
| `filter_category_selected` | category, count | Track filter usage |
| `filter_price_changed` | min, max | Measure price sensitivity |
| `filter_rating_changed` | min_rating | Measure quality preference |
| `sort_changed` | sort_by | Track sort preferences |
| `search_cache_hit` | query_hash, age_ms | Monitor cache effectiveness |
| `search_cache_miss` | query_hash | Diagnose cache issues |
| `search_results_empty` | query, filters | Identify search dead zones |
| `search_error` | error_type, query | Catch bugs early |

### Performance Metrics

- Search latency (cache vs. API)
- Filter response time
- Suggestion API time
- Cache hit rate (target: >70%)
- Memory usage during search
- Frame rate drops

### Dashboards (Future)
- Search query volume & trends
- Top searched terms
- Filter popularity (category vs. price vs. rating)
- Zero-result searches
- Performance analytics

---

## 9. Future Enhancements (Phase 6+)

### Search History
- Persist user's recent searches
- Display in suggestions dropdown
- Quick-tap to re-run previous search
- Clear history option

### Advanced Filters
- Brand filter (multi-select)
- Color filter (visual swatches)
- Size filter (for clothing)
- Availability filter (in stock)

### Search Analytics
- Popular search terms dashboard
- Trending products
- Search-to-purchase conversion rate

### Real Backend Integration
- Replace mock SearchRepository with API client
- Elasticsearch or similar for full-text search
- Faceted search (category counts, etc.)
- Real suggestion API

### Personalization
- Search history based on user ID
- Personalized suggestions
- Trending for user's region
- AI-powered recommendations

### Mobile-Specific
- Voice search (speech-to-text)
- Image search (visual search)
- Barcode scanner

---

## 10. Risk Analysis & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| Debounce timing too aggressive | Suggestions lag | Medium | Tuning + testing |
| Cache invalidation complexity | Stale results | Medium | Clear TTL strategy + monitoring |
| Filter performance on large datasets | Slow UI | Low | Lazy loading + virtualization |
| Memory bloat from cached results | OOM on low-end devices | Low | Memory limit + eviction policy |
| API overload from search queries | Server degradation | Low | Rate limiting + caching |

---

## 11. Success Criteria

- ✅ Debounced search working with <300ms latency
- ✅ All filter types (category, price, rating) functional
- ✅ Sorting working correctly for all options
- ✅ Cache hit rate >70%
- ✅ Performance: 60 FPS maintained
- ✅ Memory: <50MB for typical usage
- ✅ Test coverage: >90%
- ✅ Zero known bugs in core search flow
- ✅ Documentation complete
- ✅ Ready for staging deployment

---

## 12. Dependencies & Prerequisites

### External Dependencies
- `flutter_riverpod` (already included)
- `flutter` (already included)
- (Optional) `fuzzy` package for suggestion fuzzy matching

### Internal Dependencies
- Phase 1-4 completed ✅
- ProductRepository & pagination ✅
- Cache architecture ✅
- Telemetry system ✅
- Service locator ✅

### Blocked By
- None — ready to start

---

## 13. Rollout & Deployment

### Feature Flags
```dart
const bool enableSearchFilters = false;  // lib/constants.dart
const bool enableSearchCaching = false;
```

### Phased Rollout
1. **Week 3**: Internal testing (dev build)
2. **Week 4**: Beta testing (selected users)
3. **Week 5**: General availability (all users)

### Rollback Plan
- Feature flags allow instant disable
- Cache can be cleared server-side
- SearchScreen reverts to legacy UI if needed

---

## Appendix A: File Structure

```
lib/
├── repository/
│   ├── search_repository.dart (new)
│   └── search_cache.dart (new)
├── models/
│   ├── search_query.dart (new)
│   ├── search_filter.dart (new)
│   ├── search_result.dart (new)
│   └── category_option.dart (new)
├── providers/
│   └── search_provider.dart (new)
├── components/
│   ├── search/
│   │   ├── search_input_field.dart (new)
│   │   ├── search_suggestions_overlay.dart (new)
│   │   ├── category_filter.dart (new)
│   │   ├── price_range_slider.dart (new)
│   │   ├── rating_filter.dart (new)
│   │   ├── sort_dropdown.dart (new)
│   │   └── filter_panel.dart (new)
│   └── pagination/
│       └── paginated_product_list.dart (updated)
└── screens/
    └── search/
        └── views/
            └── search_screen.dart (updated)

test/
├── search_repository_test.dart (new)
├── search_cache_test.dart (new)
├── search_provider_test.dart (new)
├── search_input_field_test.dart (new)
├── category_filter_test.dart (new)
├── price_range_slider_test.dart (new)
├── rating_filter_test.dart (new)
├── sort_dropdown_test.dart (new)
└── search_screen_integration_test.dart (new)
```

---

## Appendix B: DTOs & Models

See [Section 3.3](#33-new-abstractions--dtos) for complete DTO definitions.

---

## Appendix C: Comparison with Alternatives

### Alternative 1: Server-Side Search Only
- Pro: Less client complexity
- Con: Higher latency, requires real backend

### Alternative 2: Full Elasticsearch Integration
- Pro: Powerful search, faceting
- Con: Overkill for MVP, requires backend infra

### Alternative 3: Local Search (Client-Side Only)
- Pro: Fast, works offline
- Con: Doesn't scale to large catalogs

**Recommendation**: Hybrid approach (mock for MVP, easy upgrade to backend later)

---

## Appendix D: Example Code Snippets

### Debounced Search Usage
```dart
final searchText = ref.watch(searchTextProvider);

ref.listen(searchTextProvider, (previous, next) {
  if (next.isEmpty) {
    // Clear suggestions
    return;
  }
  // Debounce is handled by the provider's internal timer
});
```

### Filter State Management
```dart
final filter = ref.watch(searchFilterProvider);

// Add a category
var updated = Set<String>.from(filter.selectedCategories);
updated.add('electronics');
ref.read(searchFilterProvider.notifier).state = 
  filter.copyWith(selectedCategories: updated);
```

### Cache Hit Example
```dart
final result = await searchCache.get(queryHash);
if (result != null) {
  telemetryService.logEvent('search_cache_hit', {'query': queryHash});
  return result;
} else {
  telemetryService.logEvent('search_cache_miss', {'query': queryHash});
  // Fetch from SearchRepository
}
```

---

**Document End**  
**Next: Phase 5 Implementation (see project schedule)**

---

**Approval Checklist**
- [ ] Architecture review (team lead)
- [ ] Design review (UX/design team)
- [ ] Scope verification (product manager)
- [ ] Timeline agreement (team)
- [ ] Resource allocation confirmed

**Approved By**: [Pending]  
**Approved Date**: [Pending]

