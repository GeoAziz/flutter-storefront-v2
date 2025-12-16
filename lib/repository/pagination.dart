/// Base class for pagination requests. Supports both page-based and cursor-based pagination.
abstract class PaginationRequest {
  /// Get the desired page size / limit for this request.
  int get pageSize;
}

/// Page-based pagination request (offset = (page - 1) * pageSize).
class PageRequest implements PaginationRequest {
  /// 1-indexed page number
  final int page;

  /// Number of items per page
  @override
  final int pageSize;

  PageRequest({
    required this.page,
    required this.pageSize,
  });
}

/// Cursor-based pagination request (opaque token for the next batch).
class CursorRequest implements PaginationRequest {
  /// Opaque cursor token (e.g. base64-encoded JSON with offset)
  final String? cursor;

  /// Maximum number of items to fetch
  final int limit;

  CursorRequest({
    this.cursor,
    required this.limit,
  });

  @override
  int get pageSize => limit;
}

/// Result of a paginated product fetch.
class PaginationResult<T> {
  /// The items returned in this batch
  final List<T> items;

  /// Opaque cursor for fetching the next batch (null if no more items)
  final String? nextCursor;

  /// Whether more items are available after this batch
  final bool hasMore;

  /// 1-indexed page number (for page-based requests)
  final int? page;

  /// Page size used (items per page)
  final int? pageSize;

  PaginationResult({
    required this.items,
    this.nextCursor,
    required this.hasMore,
    this.page,
    this.pageSize,
  });

  /// Factory constructor for empty results.
  factory PaginationResult.empty() {
    return PaginationResult(
      items: [],
      nextCursor: null,
      hasMore: false,
    );
  }
}
