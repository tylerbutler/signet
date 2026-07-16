# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

signet is a pure-Gleam library of Fluid Framework token primitives — document-token claims, HS256 JWT signing/verification, and claim validation — consolidated into one shared codebase. Source in `src/signet/`, tests in `test/`. Consumed as a git-commit dependency (pinned `ref` in `gleam.toml`); **not published to Hex**.

## Design Context

The signet **website** (a reference-docs + landing site, built under `website/`) has captured design context:

- **[PRODUCT.md](PRODUCT.md)** — register (brand), platform (web), users, purpose, positioning, brand personality, anti-references, and the five design principles. Read it before any website/UI work.
- **DESIGN.md** (to be generated) — the visual system: color, typography, components. Once it exists, read it alongside PRODUCT.md.

Design and UI work uses the `impeccable` skill (`/impeccable`). Run `/impeccable init` to refresh context, `/impeccable document` to (re)generate DESIGN.md.
