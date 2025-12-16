# Interim cursor implementation (confirmed)

Backend confirmed the interim cursor contract used by this client during development and testing.

Cursor format (confirmed):
- Cursor Encoding: Base64-encoded JSON object containing the offset. Example: `base64(jsonEncode({ "offset": 10 }))`.

Response shape (confirmed):

{
  "items": [ ... ],
  "nextCursor": "base64encodedstring" | null,
  "hasMore": true | false
}

Error handling:
- If the backend returns an error for an invalid/expired cursor, the client will surface a `FormatException` when attempting to decode/validate the cursor. Higher-level code (providers/UI) should catch this and either restart pagination from the beginning or surface an appropriate message to the user.

Notes:
- The `RealProductRepository.fetchProductsPaginated` implementation decodes/encodes the cursor using base64(jsonEncode({"offset": <int>})). When `hasMore` is true the client will synthesize the next cursor using the offset-based scheme.
- This is still an opaque token from the client's perspective; the server is the source of truth for validity and expiry.

If the backend changes the cursor format later (e.g., signs the token or changes the encoded fields), update `lib/repository/real_product_repository.dart` accordingly and run the pagination tests located at `test/real_network_product_repository_pagination_test.dart`.
