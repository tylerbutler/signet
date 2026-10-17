import gleam/dict
import gleam/list
import gleam/option
import signet/claims
import signet/jwt
import signet/types.{
  type Scope, DocRead, DocWrite, SummaryWrite, TokenClaims, User,
}
import startest/expect

fn token(scopes: List(Scope)) -> types.TokenClaims {
  TokenClaims(
    "doc",
    scopes,
    "tenant",
    User("user", dict.new()),
    1000,
    2000,
    "1.0",
    option.None,
  )
}

pub fn expiration_boundary_test() {
  claims.validate_expiration(token([]), 1999) |> expect.to_equal(Ok(Nil))
  claims.validate_expiration(token([]), 2000)
  |> expect.to_equal(Error(claims.TokenExpired(2000, 2000)))
}

pub fn connection_validation_order_test() {
  claims.validate_connection_claims(token([]), "other", "other", 2000)
  |> expect.to_equal(Error(claims.TokenExpired(2000, 2000)))
  claims.validate_connection_claims(token([]), "other", "other", 1500)
  |> expect.to_equal(Error(claims.TenantMismatch("tenant", "other")))
  claims.validate_connection_claims(token([]), "tenant", "other", 1500)
  |> expect.to_equal(Error(claims.DocumentMismatch("doc", "other")))
  claims.validate_connection_claims(token([]), "tenant", "doc", 1500)
  |> expect.to_equal(Ok(Nil))
}

pub fn typed_scope_validation_and_predicates_test() {
  let fixture = token([DocRead, DocWrite])
  claims.validate_scope(fixture, DocWrite) |> expect.to_equal(Ok(Nil))
  claims.validate_scope(fixture, SummaryWrite)
  |> expect.to_equal(
    Error(claims.MissingScope(SummaryWrite, [DocRead, DocWrite])),
  )
  claims.has_scope(fixture, DocRead) |> expect.to_be_true()
  claims.has_scope(fixture, SummaryWrite) |> expect.to_be_false()
  claims.has_read_scope(fixture) |> expect.to_be_true()
  claims.has_write_scope(fixture) |> expect.to_be_true()
  claims.has_summary_write_scope(fixture) |> expect.to_be_false()
  claims.has_summary_write_scope(token([SummaryWrite])) |> expect.to_be_true()
}

pub fn composed_access_scope_order_test() {
  claims.validate_read_access(token([]), "tenant", "doc", 1500)
  |> expect.to_equal(Error(claims.MissingScope(DocRead, [])))
  claims.validate_write_access(token([DocWrite]), "tenant", "doc", 1500)
  |> expect.to_equal(Error(claims.MissingScope(DocRead, [DocWrite])))
  claims.validate_write_access(token([DocRead]), "tenant", "doc", 1500)
  |> expect.to_equal(Error(claims.MissingScope(DocWrite, [DocRead])))
  claims.validate_summary_access(token([SummaryWrite]), "tenant", "doc", 1500)
  |> expect.to_equal(Error(claims.MissingScope(DocRead, [SummaryWrite])))
  claims.validate_summary_access(token([DocRead]), "tenant", "doc", 1500)
  |> expect.to_equal(Error(claims.MissingScope(SummaryWrite, [DocRead])))
  claims.validate_read_access(token([DocRead]), "tenant", "doc", 1500)
  |> expect.to_equal(Ok(Nil))
  claims.validate_write_access(
    token([DocRead, DocWrite]),
    "tenant",
    "doc",
    1500,
  )
  |> expect.to_equal(Ok(Nil))
  claims.validate_summary_access(
    token([DocRead, SummaryWrite]),
    "tenant",
    "doc",
    1500,
  )
  |> expect.to_equal(Ok(Nil))
}

pub fn error_messages_statuses_and_compatibility_test() {
  [
    #(
      claims.TokenExpired(1000, 1500),
      "Token expired at 1000 (current time: 1500)",
      401,
    ),
    #(
      claims.TenantMismatch("a", "b"),
      "Token tenant 'a' does not match request tenant 'b'",
      403,
    ),
    #(
      claims.DocumentMismatch("a", "b"),
      "Token document 'a' does not match request document 'b'",
      403,
    ),
    #(
      claims.MissingScope(DocWrite, [DocRead]),
      "Missing required scope: doc:write",
      403,
    ),
    #(claims.MissingClaim("exp"), "Missing required claim: exp", 401),
    #(
      claims.InvalidClaim("exp", "not an integer"),
      "Invalid claim 'exp': not an integer",
      401,
    ),
  ]
  |> list.each(fn(entry) {
    let #(error, message, status) = entry
    let legacy_error: jwt.JwtValidationError = error
    claims.format_error(legacy_error) |> expect.to_equal(message)
    claims.error_to_http_code(legacy_error) |> expect.to_equal(status)
    jwt.format_error(error) |> expect.to_equal(message)
    jwt.error_to_http_code(error) |> expect.to_equal(status)
  })
}

pub fn compatibility_validators_share_error_constructors_test() {
  let result: jwt.JwtValidationResult(Nil) =
    claims.validate_expiration(token([]), 2000)
  result |> expect.to_equal(jwt.validate_expiration(token([]), 2000))
  let assert Error(claims.TokenExpired(2000, 2000)) =
    jwt.validate_expiration(token([]), 2000)
  jwt.validate_tenant(token([]), "other")
  |> expect.to_equal(claims.validate_tenant(token([]), "other"))
  jwt.validate_document(token([]), "other")
  |> expect.to_equal(claims.validate_document(token([]), "other"))
  jwt.validate_scope(token([]), DocRead)
  |> expect.to_equal(claims.validate_scope(token([]), DocRead))
}
