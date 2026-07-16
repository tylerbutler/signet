---
title: signet/jwt
description: HS256 signing and verification plus the Fluid claim validators — connection, read, write, and summary access — with their error types and HTTP mappings.
---

`signet/jwt` is two halves that stay deliberately separate: **crypto** (verify an
HS256 signature, mint a token, pull a JWT off an `Authorization` header) and
**claim validation** (does this token match the request, and is it still valid).
Verify first, then validate.

Built on `gleam_crypto` — HMAC-SHA256 and constant-time comparison, no FFI.

## Crypto

### `verify_signature`

```gleam
pub fn verify_signature(
  token: String,
  secret: String,
) -> Result(TokenClaims, JwtCryptoError)
```

Verify an HS256 signature and parse the payload into `TokenClaims`. The
comparison is constant-time. An empty secret is rejected outright. On success
you get parsed claims — but **not** a validated token; tenant, document, and
expiry are still unchecked. Parsing is strict: the header `alg` must be `HS256`,
the claim `ver` must be `"1.0"`, and `user.id` must be non-empty.

### `mint_token`

```gleam
pub fn mint_token(
  tenant: String,
  document_id: String,
  scopes: List(Scope),
  user_id: String,
  secret: String,
  now: Int,
  expires_in: Int,
) -> String
```

Mint a strict HS256 document token (version `"1.0"`). Sets `iat` to `now`, `exp`
to `now + expires_in`, and a random 16-byte `jti`.

### `extract_token`

```gleam
pub fn extract_token(authorization: String) -> Result(String, JwtCryptoError)
```

Extract a bare JWT from an `Authorization` header value. Accepts Routerlicious's
`Basic <base64(user:jwt)>` scheme, a `Basic <jwt>` shorthand when the value is
already a dotted JWT, and the conventional `Bearer <jwt>` scheme.

### `JwtCryptoError`

```gleam
pub type JwtCryptoError {
  BadFormat    // malformed token, header, or Authorization value
  BadSignature // signature mismatch (or an empty secret)
}
```

## Validation

Each validator returns `Result(Nil, JwtValidationError)`. They compose, so the
higher-level ones run the lower-level checks first.

### Individual checks

```gleam
pub fn validate_expiration(claims: TokenClaims, current_time_seconds: Int) -> JwtValidationResult(Nil)
pub fn validate_tenant(claims: TokenClaims, request_tenant_id: String) -> JwtValidationResult(Nil)
pub fn validate_document(claims: TokenClaims, request_document_id: String) -> JwtValidationResult(Nil)
pub fn validate_scope(claims: TokenClaims, required_scope: Scope) -> JwtValidationResult(Nil)
```

`validate_expiration` passes only while `expiration > current_time_seconds`.
`validate_scope` checks membership in the token's `scopes`.

### Scope predicates

Boolean checks that never error — handy for branching.

```gleam
pub fn has_scope(claims: TokenClaims, scope: Scope) -> Bool
pub fn has_read_scope(claims: TokenClaims) -> Bool          // DocRead
pub fn has_write_scope(claims: TokenClaims) -> Bool         // DocWrite
pub fn has_summary_write_scope(claims: TokenClaims) -> Bool // SummaryWrite
```

### Composed access checks

```gleam
pub fn validate_connection_claims(claims, tenant_id, document_id, current_time_seconds)
pub fn validate_read_access(claims, tenant_id, document_id, current_time_seconds)
pub fn validate_write_access(claims, tenant_id, document_id, current_time_seconds)
pub fn validate_summary_access(claims, tenant_id, document_id, current_time_seconds)
```

The order is the spec's (Fluid protocol section 3.3):

1. `validate_connection_claims` — expiry, then tenant, then document.
2. `validate_read_access` — connection checks, then `DocRead`.
3. `validate_write_access` — read access, then `DocWrite`.
4. `validate_summary_access` — read access, then `SummaryWrite`.

### `JwtValidationError`

```gleam
pub type JwtValidationError {
  TokenExpired(expired_at: Int, current_time: Int)
  TenantMismatch(token_tenant: String, request_tenant: String)
  DocumentMismatch(token_document: String, request_document: String)
  MissingScope(required: Scope, available: List(Scope))
  MissingClaim(claim_name: String)
  InvalidClaim(claim_name: String, reason: String)
}
```

### `format_error` and `error_to_http_code`

```gleam
pub fn format_error(error: JwtValidationError) -> String
pub fn error_to_http_code(error: JwtValidationError) -> Int
```

`format_error` renders a human-readable message. `error_to_http_code` maps each
error to a status:

| Error              | Status |
| ------------------ | ------ |
| `TokenExpired`     | `401`  |
| `TenantMismatch`   | `403`  |
| `DocumentMismatch` | `403`  |
| `MissingScope`     | `403`  |
| `MissingClaim`     | `401`  |
| `InvalidClaim`     | `401`  |

## Convenience re-exports

The top-level `signet` module re-exports the most-used API — `verify_signature`,
`extract_token`, `mint_token`, and the `TokenClaims` / `User` / `Scope` types —
so common code can `import signet` and skip the submodule paths.
