---
title: Quickstart
description: Add signet by pinning a commit, then mint, verify, and validate a Fluid document token in a few lines of Gleam.
---

signet gives you three things for Fluid Framework document tokens: the **claim
types**, **HS256** signing and verification, and a set of **claim validators**.
This page takes you from zero to a verified, validated token.

## Install

signet is not published to Hex. You depend on it by **pinning a commit** in your
`gleam.toml` — so every build resolves the exact same token code, byte for byte.

```toml title="gleam.toml"
[dependencies]
signet = { git = "https://github.com/tylerbutler/signet.git", ref = "6ea697d3d1d6c5ab60e214414fbfbb134b355a8c" }
```

Then fetch it:

```sh title="Terminal"
gleam deps download
```

:::note
Pin a full commit SHA, not a branch. A branch ref would let the token
implementation move underneath you between builds; a commit keeps mint and
verify reproducible across every stack that depends on signet.
:::

## Mint a token

`mint_token` builds a strict HS256 token (version `"1.0"`) with a random `jti`.
Scopes are typed — import the ones you need from `signet/types`.

```gleam title="mint.gleam"
import signet/jwt
import signet/types.{DocRead, DocWrite}

pub fn issue(secret: String, now: Int) -> String {
  jwt.mint_token(
    "tenant-1",           // tenant
    "doc-1",              // document id
    [DocRead, DocWrite],  // scopes
    "user-1",             // user id
    secret,
    now,
    3600,                 // expires in (seconds)
  )
}
```

## Verify a signature

`verify_signature` checks the HS256 signature with a constant-time comparison
and parses the payload into `TokenClaims`. It does **not** check tenant,
document, or expiry — that is the validators' job, kept deliberately separate.

```gleam title="verify.gleam"
import signet/jwt
import signet/types.{type TokenClaims}

pub fn read_claims(token: String, secret: String) -> Result(TokenClaims, Nil) {
  case jwt.verify_signature(token, secret) {
    Ok(claims) -> Ok(claims)
    Error(jwt.BadSignature) -> Error(Nil)
    Error(jwt.BadFormat) -> Error(Nil)
  }
}
```

Reading a token straight off an incoming request? `extract_token` pulls the JWT
out of an `Authorization` header — both the Routerlicious `Basic` scheme and a
conventional `Bearer` scheme.

```gleam
import signet/jwt

let assert Ok(token) = jwt.extract_token("Bearer " <> raw_jwt)
```

## Validate the claims

Once you trust the signature, check the claims against the request. The
validators compose: `validate_write_access` runs the connection checks
(expiry → tenant → document), then read scope, then write scope — in that order.

```gleam title="authorize.gleam"
import gleam/result
import signet/jwt

pub fn authorize_write(
  token: String,
  secret: String,
  tenant: String,
  document: String,
  now: Int,
) -> Result(Nil, jwt.JwtValidationError) {
  use claims <- result.try(
    jwt.verify_signature(token, secret)
    |> result.replace_error(jwt.MissingClaim("signature")),
  )
  jwt.validate_write_access(claims, tenant, document, now)
}
```

When validation fails, the error carries what to say and how to answer:

```gleam
case jwt.validate_write_access(claims, tenant, document, now) {
  Ok(Nil) -> serve()
  Error(err) -> {
    let status = jwt.error_to_http_code(err) // 401 or 403
    let message = jwt.format_error(err)       // human-readable reason
    reject(status, message)
  }
}
```

## Try it live

Want to see the bytes? The [token playground](/#playground) mints and verifies
real signet tokens in your browser — paste a secret, watch the
`header.payload.signature` take shape, then tamper with it and watch validation
catch it.

## Next

- **[signet/types](/reference/types/)** — the claim, user, and scope types.
- **[signet/jwt](/reference/jwt/)** — every crypto and validation function, with signatures.
