import gleam/list
import signet
import signet/jwt
import signet/types.{DocRead, DocWrite, SummaryRead, SummaryWrite}
import startest
import startest/expect

pub fn main() -> Nil {
  startest.run(startest.default_config())
}

// ─────────────────────────────────────────────────────────────────────────────
// Scope conversions
// ─────────────────────────────────────────────────────────────────────────────

pub fn scope_string_roundtrip_test() {
  [DocRead, DocWrite, SummaryRead, SummaryWrite]
  |> list.each(fn(scope) {
    types.scope_to_string(scope)
    |> types.scope_from_string
    |> expect.to_equal(Ok(scope))
  })
}

pub fn scopes_from_strings_drops_unknown_test() {
  types.scopes_from_strings(["doc:read", "bogus", "summary:write"])
  |> expect.to_equal([DocRead, SummaryWrite])
}

// ─────────────────────────────────────────────────────────────────────────────
// JWT crypto (mint / verify)
// ─────────────────────────────────────────────────────────────────────────────

pub fn mint_and_verify_signature_roundtrip_test() {
  let token =
    signet.mint_token(
      "tenant-1",
      "doc-1",
      types.scopes_to_strings([DocRead, DocWrite]),
      "user-1",
      "secret",
      1000,
      3600,
    )
  case signet.verify_signature(token, "secret") {
    Ok(claims) -> {
      claims.tenant_id |> expect.to_equal("tenant-1")
      claims.document_id |> expect.to_equal("doc-1")
      claims.user.id |> expect.to_equal("user-1")
      claims.expiration |> expect.to_equal(4600)
      claims.scopes |> expect.to_equal(["doc:read", "doc:write"])
    }
    Error(_) -> expect.to_be_true(False)
  }
}

pub fn verify_signature_rejects_wrong_secret_test() {
  let token =
    signet.mint_token("t", "d", ["doc:read"], "u", "right", 1000, 3600)
  let rejected = case signet.verify_signature(token, "wrong") {
    Error(jwt.BadSignature) -> True
    _ -> False
  }
  rejected |> expect.to_be_true()
}

pub fn verify_signature_rejects_malformed_token_test() {
  let rejected = case signet.verify_signature("not-a-jwt", "secret") {
    Error(jwt.BadFormat) -> True
    _ -> False
  }
  rejected |> expect.to_be_true()
}

pub fn extract_token_parses_bearer_and_basic_schemes_test() {
  signet.extract_token("Bearer abc.def.ghi")
  |> expect.to_equal(Ok("abc.def.ghi"))
  signet.extract_token("Basic abc.def.ghi")
  |> expect.to_equal(Ok("abc.def.ghi"))
  let rejected = case signet.extract_token("Nonsense") {
    Error(jwt.BadFormat) -> True
    _ -> False
  }
  rejected |> expect.to_be_true()
}

// ─────────────────────────────────────────────────────────────────────────────
// Claim validation (integration with crypto)
// ─────────────────────────────────────────────────────────────────────────────

pub fn validate_write_access_end_to_end_test() {
  let token =
    signet.mint_token(
      "tenant-1",
      "doc-1",
      types.scopes_to_strings([DocRead, DocWrite]),
      "user-1",
      "secret",
      1000,
      3600,
    )
  case signet.verify_signature(token, "secret") {
    Ok(claims) -> {
      // valid write access within the token window
      jwt.validate_write_access(claims, "tenant-1", "doc-1", 2000)
      |> expect.to_equal(Ok(Nil))
      // wrong tenant is rejected
      let tenant_ok = case
        jwt.validate_write_access(claims, "other", "doc-1", 2000)
      {
        Error(_) -> True
        Ok(_) -> False
      }
      tenant_ok |> expect.to_be_true()
    }
    Error(_) -> expect.to_be_true(False)
  }
}
