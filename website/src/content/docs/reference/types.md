---
title: signet/types
description: The Fluid document-token types — user identity, authorization scopes, and decoded claims — plus the scope string conversions.
---

The `signet/types` module holds the token domain: a user identity, the
authorization scopes, and the decoded claims. `TokenClaims` mirrors the
Fluid / Routerlicious wire shape, consolidated from `spillway/types`,
`floodgate/auth`, and `levee_auth/token` (see ADR-007).

## Types

### `User`

A Fluid user identity, as carried in a token's `user` claim.

```gleam
pub type User {
  User(id: String, properties: Dict(String, Dynamic))
}
```

`properties` is an open bag for extra fields on the user claim — for example, a
`name` parsed from the payload. Verification requires a non-empty `id`.

### `Scope`

Authorization scopes for a Fluid document token — the union of every scope used
across the stacks.

```gleam
pub type Scope {
  DocRead
  DocWrite
  SummaryRead
  SummaryWrite
}
```

| Scope          | Wire string      |
| -------------- | ---------------- |
| `DocRead`      | `doc:read`       |
| `DocWrite`     | `doc:write`      |
| `SummaryRead`  | `summary:read`   |
| `SummaryWrite` | `summary:write`  |

### `TokenClaims`

The decoded document-token claims.

```gleam
pub type TokenClaims {
  TokenClaims(
    document_id: String,
    scopes: List(Scope),
    tenant_id: String,
    user: User,
    issued_at: Int,
    expiration: Int,
    version: String,
    jti: Option(String),
  )
}
```

Scopes are decoded to the typed `Scope` union; unrecognized scope strings are
dropped on parse rather than failing the whole token. `jti` is optional.

## Scope conversions

Use these to move between the typed `Scope` union and the Fluid wire strings.

### `scope_to_string`

```gleam
pub fn scope_to_string(scope: Scope) -> String
```

Encode a single scope to its Fluid wire string (`DocRead` → `"doc:read"`).

### `scope_from_string`

```gleam
pub fn scope_from_string(value: String) -> Result(Scope, Nil)
```

Decode a single wire string. Returns `Error(Nil)` for anything unrecognized.

### `scopes_to_strings`

```gleam
pub fn scopes_to_strings(scopes: List(Scope)) -> List(String)
```

Encode typed scopes to wire strings — used when constructing claims.

### `scopes_from_strings`

```gleam
pub fn scopes_from_strings(scopes: List(String)) -> List(Scope)
```

Decode wire strings to typed scopes, **dropping** any unrecognized ones. This is
the forward-compatible path: a token carrying a scope signet doesn't know about
still parses; the unknown scope is simply ignored.
