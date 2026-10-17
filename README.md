# signet

Fluid Framework token primitives for Gleam: document-token **claims**, **HS256
JWT** signing/verification, and **claim validation** (tenant / document /
expiry / scope).

`signet` is the shared token domain consolidated out of three duplicate
implementations — `spillway/jwt`, `floodgate/auth`, and `levee_auth/token` —
so both the Levee and Floodgate server stacks (and Levee's general auth library)
verify and mint the same Fluid document tokens against one codebase. See
Levee ADR-007.

Pure Gleam (`gleam_stdlib`, `gleam_json`, `gleam_crypto`) — no FFI. Uses
`gleam_crypto` for HMAC-SHA256 and constant-time comparison.

## Modules

| Module | Contents |
|--------|----------|
| `signet/types` | `TokenClaims`, `User`, `Scope` + scope string conversions |
| `signet/claims` | Pure `validate_*` claim validators, scope predicates, validation errors, formatting, and HTTP status mapping |
| `signet/jwt` | HS256 `verify_signature` / `mint_token` / `extract_token`, plus compatibility forwards to `signet/claims` |
| `signet` | Convenience re-exports of the most-used API |

## Migration: validation error constructors moved

**Source change:** import validation error constructors from `signet/claims`,
not `signet/jwt`. Replace `jwt.TokenExpired`, `jwt.TenantMismatch`,
`jwt.DocumentMismatch`, `jwt.MissingScope`, `jwt.MissingClaim`, and
`jwt.InvalidClaim` with the corresponding `claims.*` constructors in both
expressions and patterns. Gleam cannot re-export constructors.

`jwt.JwtValidationError` and `jwt.JwtValidationResult(a)` remain type aliases,
and all existing `jwt` validation functions forward to `signet/claims`. There
is only one error union: both paths return the same constructors. The crypto
API, validation order, error messages, and HTTP status codes are unchanged.

## Runtime boundary

Browser claim-only code should import **`signet/claims` and `signet/types`**.
Their generated JavaScript import graph does not load `node:crypto`.
`signet/jwt` and the root `signet` module still load `gleam_crypto`; this change
does not add browser signing or signature verification.

Claim validation does **not** authenticate a token or verify its signature.
Validate already-trusted claims; do not treat decoding an untrusted JWT as
authentication.

## Example

```gleam
import signet/claims
import signet/jwt
import signet/types.{DocRead, DocWrite}

let token =
  jwt.mint_token("tenant-1", "doc-1", [DocRead, DocWrite], "user-1", secret, now, 3600)

case jwt.verify_signature(token, secret) {
  Ok(token_claims) ->
    claims.validate_write_access(token_claims, "tenant-1", "doc-1", now)
  Error(_) -> Error(claims.MissingClaim("signature"))
}
```
