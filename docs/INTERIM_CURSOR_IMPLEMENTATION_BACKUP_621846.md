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
# Interim cursor implementation note

This note documents the interim cursor format the client-side code assumes while waiting for backend confirmation.

Assumed response shape (interim):

```
{
  "items": [ ... ],
  "nextCursor": "<opaque-base64-json>", // or null
  "hasMore": true|false
}
```

Assumed cursor encoding (client-side, temporary):

- base64-encoded JSON with an `offset` integer, for example:

```
base64(jsonEncode({"offset":20}))
```

Why this choice?
- Simple, easy to parse in tests and local stubs.
- Conservative: the client will treat unknown/invalid cursors as start-of-list and fall back safely.

Notes:
- This is an interim assumption only. Once the backend confirms the canonical cursor format and semantics (e.g. signed tokens, opaque blobs, expiry rules), the client parser will be updated in a single small commit.
- Tests were added to validate this interim behavior so CI remains green while we wait for backend confirmation.
