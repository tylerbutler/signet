//// signet — Fluid Framework token primitives.
////
//// Convenience re-exports of the most-used token API. The full surface lives in
//// `signet/jwt` (HS256 crypto + claim validation) and `signet/types` (claims,
//// user, scopes).

import signet/jwt
import signet/types

pub type TokenClaims =
  types.TokenClaims

pub type User =
  types.User

pub type Scope =
  types.Scope

/// Verify an HS256 signature and parse the payload into `TokenClaims`. Does not
/// validate tenant/document/expiry — pair with the `signet/jwt` validators.
pub fn verify_signature(
  token: String,
  secret: String,
) -> Result(TokenClaims, jwt.JwtCryptoError) {
  jwt.verify_signature(token, secret)
}

/// Extract a bare JWT from an `Authorization` header value (Basic / Bearer).
pub fn extract_token(
  authorization: String,
) -> Result(String, jwt.JwtCryptoError) {
  jwt.extract_token(authorization)
}

/// Mint a strict HS256 document token (version "1.0").
pub fn mint_token(
  tenant: String,
  document_id: String,
  scopes: List(types.Scope),
  user_id: String,
  secret: String,
  now: Int,
  expires_in: Int,
) -> String {
  jwt.mint_token(tenant, document_id, scopes, user_id, secret, now, expires_in)
}
