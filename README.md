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
| `signet/jwt` | HS256 `verify_signature` / `mint_token` / `extract_token`, and the `validate_*` claim validators |
| `signet` | Convenience re-exports of the most-used API |

## Example

```gleam
import signet/jwt
import signet/types.{DocRead, DocWrite}

let token =
  jwt.mint_token(
    "tenant-1",
    "doc-1",
    types.scopes_to_strings([DocRead, DocWrite]),
    "user-1",
    secret,
    now,
    3600,
  )

case jwt.verify_signature(token, secret) {
  Ok(claims) -> jwt.validate_write_access(claims, "tenant-1", "doc-1", now)
  Error(_) -> Error(Nil)
}
```
