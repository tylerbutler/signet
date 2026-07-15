//// Fluid Framework token types: user identity, authorization scopes, and the
//// decoded document-token claims.
////
//// `TokenClaims` mirrors the Fluid/Routerlicious wire shape (scopes kept as
//// strings for forward-compatibility); use the `Scope` helpers for typed
//// access. Consolidated from `spillway/types`, `floodgate/auth`, and
//// `levee_auth/token` — see ADR-007.

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option.{type Option}

/// A Fluid user identity as carried in a token's `user` claim.
pub type User {
  User(id: String, properties: Dict(String, Dynamic))
}

/// Authorization scopes for a Fluid document token. The union of every scope
/// used across the stacks (levee_auth carried `SummaryRead`, which Floodgate's
/// token-mint also issues).
pub type Scope {
  DocRead
  DocWrite
  SummaryRead
  SummaryWrite
}

/// Decoded Fluid document-token claims.
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

/// Encode a scope to its Fluid wire string.
pub fn scope_to_string(scope: Scope) -> String {
  case scope {
    DocRead -> "doc:read"
    DocWrite -> "doc:write"
    SummaryRead -> "summary:read"
    SummaryWrite -> "summary:write"
  }
}

/// Decode a Fluid wire scope string.
pub fn scope_from_string(value: String) -> Result(Scope, Nil) {
  case value {
    "doc:read" -> Ok(DocRead)
    "doc:write" -> Ok(DocWrite)
    "summary:read" -> Ok(SummaryRead)
    "summary:write" -> Ok(SummaryWrite)
    _ -> Error(Nil)
  }
}

/// Encode typed scopes to their wire strings (for constructing claims).
pub fn scopes_to_strings(scopes: List(Scope)) -> List(String) {
  list.map(scopes, scope_to_string)
}

/// Decode wire scope strings to typed scopes, dropping any unrecognized ones.
pub fn scopes_from_strings(scopes: List(String)) -> List(Scope) {
  list.filter_map(scopes, scope_from_string)
}
