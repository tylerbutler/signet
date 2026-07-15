import gleam/dict
import gleam/list
import gleam/option
import signet
import signet/jwt
import signet/types.{DocRead, DocWrite, SummaryRead, SummaryWrite}
import startest
import startest/expect

pub fn main() -> Nil {
  startest.run(startest.default_config())
}

fn make_test_claims(
  tenant_id: String,
  document_id: String,
  scopes: List(types.Scope),
  exp: Int,
) -> types.TokenClaims {
  types.TokenClaims(
    document_id: document_id,
    scopes: scopes,
    tenant_id: tenant_id,
    user: types.User(id: "test-user", properties: dict.new()),
    issued_at: 1000,
    expiration: exp,
    version: "1.0",
    jti: option.None,
  )
}

fn assert_error_variant(result: Result(a, e), check: fn(e) -> Nil) -> Nil {
  case result {
    Error(err) -> check(err)
    Ok(_) -> panic as "Expected Error, got Ok"
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JWT claim validation (ported from spillway; typed scopes)
// ─────────────────────────────────────────────────────────────────────────────

pub fn validate_expiration_valid_test() {
  let claims = make_test_claims("tenant", "doc", [DocRead], 2000)
  jwt.validate_expiration(claims, 1500) |> expect.to_be_ok()
}

pub fn validate_expiration_expired_test() {
  let claims = make_test_claims("tenant", "doc", [DocRead], 1000)
  jwt.validate_expiration(claims, 1500)
  |> assert_error_variant(fn(err) {
    let assert jwt.TokenExpired(exp, current) = err
    exp |> expect.to_equal(1000)
    current |> expect.to_equal(1500)
  })
}

pub fn validate_tenant_match_test() {
  let claims = make_test_claims("my-tenant", "doc", [DocRead], 2000)
  jwt.validate_tenant(claims, "my-tenant") |> expect.to_be_ok()
}

pub fn validate_tenant_mismatch_test() {
  let claims = make_test_claims("my-tenant", "doc", [DocRead], 2000)
  jwt.validate_tenant(claims, "other-tenant")
  |> assert_error_variant(fn(err) {
    let assert jwt.TenantMismatch(token, request) = err
    token |> expect.to_equal("my-tenant")
    request |> expect.to_equal("other-tenant")
  })
}

pub fn validate_document_match_test() {
  let claims = make_test_claims("tenant", "my-doc", [DocRead], 2000)
  jwt.validate_document(claims, "my-doc") |> expect.to_be_ok()
}

pub fn validate_document_mismatch_test() {
  let claims = make_test_claims("tenant", "my-doc", [DocRead], 2000)
  jwt.validate_document(claims, "other-doc")
  |> assert_error_variant(fn(err) {
    let assert jwt.DocumentMismatch(token, request) = err
    token |> expect.to_equal("my-doc")
    request |> expect.to_equal("other-doc")
  })
}

pub fn validate_scope_present_test() {
  let claims = make_test_claims("tenant", "doc", [DocRead, DocWrite], 2000)
  jwt.validate_scope(claims, DocRead) |> expect.to_be_ok()
  jwt.validate_scope(claims, DocWrite) |> expect.to_be_ok()
}

pub fn validate_scope_missing_test() {
  let claims = make_test_claims("tenant", "doc", [DocRead], 2000)
  jwt.validate_scope(claims, DocWrite)
  |> assert_error_variant(fn(err) {
    let assert jwt.MissingScope(required, _available) = err
    required |> expect.to_equal(DocWrite)
  })
}

pub fn has_scope_test() {
  let claims = make_test_claims("tenant", "doc", [DocRead, DocWrite], 2000)
  jwt.has_scope(claims, DocRead) |> expect.to_be_true()
  jwt.has_scope(claims, DocWrite) |> expect.to_be_true()
  jwt.has_scope(claims, SummaryWrite) |> expect.to_be_false()
}

pub fn has_read_scope_test() {
  make_test_claims("tenant", "doc", [DocRead], 2000)
  |> jwt.has_read_scope
  |> expect.to_be_true()
  make_test_claims("tenant", "doc", [DocWrite], 2000)
  |> jwt.has_read_scope
  |> expect.to_be_false()
}

pub fn has_write_scope_test() {
  make_test_claims("tenant", "doc", [DocWrite], 2000)
  |> jwt.has_write_scope
  |> expect.to_be_true()
  make_test_claims("tenant", "doc", [DocRead], 2000)
  |> jwt.has_write_scope
  |> expect.to_be_false()
}

pub fn has_summary_write_scope_test() {
  make_test_claims("tenant", "doc", [SummaryWrite], 2000)
  |> jwt.has_summary_write_scope
  |> expect.to_be_true()
  make_test_claims("tenant", "doc", [DocWrite], 2000)
  |> jwt.has_summary_write_scope
  |> expect.to_be_false()
}

pub fn validate_connection_claims_test() {
  let claims =
    make_test_claims("my-tenant", "my-doc", [DocRead, DocWrite], 2000)
  jwt.validate_connection_claims(claims, "my-tenant", "my-doc", 1500)
  |> expect.to_be_ok()
}

pub fn validate_connection_claims_expired_test() {
  let claims = make_test_claims("my-tenant", "my-doc", [DocRead], 1000)
  jwt.validate_connection_claims(claims, "my-tenant", "my-doc", 1500)
  |> assert_error_variant(fn(err) {
    let assert jwt.TokenExpired(_, _) = err
    Nil
  })
}

pub fn validate_connection_claims_tenant_mismatch_test() {
  let claims = make_test_claims("my-tenant", "my-doc", [DocRead], 2000)
  jwt.validate_connection_claims(claims, "other-tenant", "my-doc", 1500)
  |> assert_error_variant(fn(err) {
    let assert jwt.TenantMismatch(_, _) = err
    Nil
  })
}

pub fn validate_read_access_test() {
  let claims = make_test_claims("tenant", "doc", [DocRead], 2000)
  jwt.validate_read_access(claims, "tenant", "doc", 1500) |> expect.to_be_ok()
}

pub fn validate_read_access_missing_scope_test() {
  let claims = make_test_claims("tenant", "doc", [DocWrite], 2000)
  jwt.validate_read_access(claims, "tenant", "doc", 1500)
  |> assert_error_variant(fn(err) {
    let assert jwt.MissingScope(required, _) = err
    required |> expect.to_equal(DocRead)
  })
}

pub fn validate_write_access_test() {
  let claims = make_test_claims("tenant", "doc", [DocRead, DocWrite], 2000)
  jwt.validate_write_access(claims, "tenant", "doc", 1500) |> expect.to_be_ok()
}

pub fn validate_write_access_missing_write_scope_test() {
  let claims = make_test_claims("tenant", "doc", [DocRead], 2000)
  jwt.validate_write_access(claims, "tenant", "doc", 1500)
  |> assert_error_variant(fn(err) {
    let assert jwt.MissingScope(required, _) = err
    required |> expect.to_equal(DocWrite)
  })
}

pub fn validate_summary_access_test() {
  let claims =
    make_test_claims("tenant", "doc", [DocRead, SummaryWrite], 2000)
  jwt.validate_summary_access(claims, "tenant", "doc", 1500)
  |> expect.to_be_ok()
}

pub fn format_error_test() {
  jwt.format_error(jwt.TokenExpired(1000, 1500))
  |> expect.to_equal("Token expired at 1000 (current time: 1500)")
}

pub fn error_to_http_code_test() {
  jwt.error_to_http_code(jwt.TokenExpired(0, 0)) |> expect.to_equal(401)
  jwt.error_to_http_code(jwt.TenantMismatch("", "")) |> expect.to_equal(403)
  jwt.error_to_http_code(jwt.DocumentMismatch("", "")) |> expect.to_equal(403)
  jwt.error_to_http_code(jwt.MissingScope(DocRead, [])) |> expect.to_equal(403)
  jwt.error_to_http_code(jwt.MissingClaim("")) |> expect.to_equal(401)
  jwt.error_to_http_code(jwt.InvalidClaim("", "")) |> expect.to_equal(401)
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
      [DocRead, DocWrite],
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
      claims.scopes |> expect.to_equal([DocRead, DocWrite])
    }
    Error(_) -> expect.to_be_true(False)
  }
}

pub fn verify_signature_rejects_wrong_secret_test() {
  let token = signet.mint_token("t", "d", [DocRead], "u", "right", 1000, 3600)
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
      [DocRead, DocWrite],
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
