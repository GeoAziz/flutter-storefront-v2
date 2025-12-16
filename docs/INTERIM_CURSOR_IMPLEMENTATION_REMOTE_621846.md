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
