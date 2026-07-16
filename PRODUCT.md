# Product

## Register

brand

## Platform

web

## Users

The primary reader is a **Fluid Framework developer** — someone building on Fluid / Routerlicious who cares about how document tokens are minted, verified, and validated, and wants to get it right. They arrive evaluation-minded: is this handling correct, and can I trust my auth to it? They are not assumed to be Gleam experts. signet's concepts (the claim shape, the scopes, the validation order, HS256 signing) are portable across languages, even though the shipped artifact is Gleam.

A secondary reader is the **internal Fluid-stack engineer** adopting signet as the one shared token codebase. They already know the domain; the site is their reference and their justification for the migration.

The site is not published for a package-registry audience. signet is consumed as a **git-commit dependency** (a pinned `ref` in `gleam.toml`), never from Hex, so the docs teach installation by commit pin, not by registry install.

## Product Purpose

signet's website is the authoritative **reference documentation** for the library, plus a landing surface that frames why the library exists. signet is the single, shared implementation of Fluid document-token handling — one codebase every stack mints and verifies against, instead of duplicate copies drifting apart. The site exists so a developer can understand the Fluid document-token model precisely, trust that signet implements it correctly, and find the exact API — claims, HS256 mint/verify, and the `validate_*` claim validators — they need. Success is a reader who leaves with a correct mental model and the precise reference call they came for; the docs are the product, not a brochure wrapped around it.

## Positioning

The single, shared, correct implementation of Fluid document-token handling — one place to mint, verify, and validate the same tokens across every stack, instead of duplicate copies drifting apart.

## Conversion & proof

- Primary CTA: **Read the reference docs.** The destination is the API/type/validator reference, not a signup or an install button.
- Secondary CTA: **See the source** (the repository) — for a visitor not yet ready to dive into the API but weighing whether to trust and adopt it.
- The line a visitor remembers after 10 seconds: *"One shared, correct implementation of Fluid document tokens."*
- Belief ladder: (1) there should be exactly one implementation of Fluid document tokens — duplicate drifting copies are a real problem; (2) signet is that implementation, and it is correct — it mirrors the wire shape, verifies with constant-time HMAC-SHA256, and validates strictly; (3) it is well-made and maintained — the care shows; (4) I can drop it into my stack by pinning a commit.
- Proof on hand: pure Gleam with no FFI; `gleam_crypto` constant-time comparison and HMAC-SHA256; strict version/user validation on parse. No testimonials or logos exist yet; proof is the code itself.

## Brand Personality

Exacting, crafted, quietly confident. The voice is that of an engineer with taste: precise about correctness without lecturing, and clearly made by someone who cares how things are built. Confident enough to be distinctive and typographically bold, never loud for its own sake. A reader should come away thinking these people care about getting the crypto right *and* about the quality of everything around it — the site's own craft is the argument that the library is well-made.

## Anti-references

Not a generic SaaS-minimal landing page (monochrome, safe gradients, feature-card grids, Stripe/Linear/Vercel clone) — that reads as invisible and AI-default. Not corporate security theater (navy-and-gold, shield and padlock iconography, "enterprise-grade" trust props) — trust here is earned by precision and transparency, not costume. Not an untouched default-docs look (HexDocs / Sphinx / ReadTheDocs blandness) — if the docs looked like every other generated doc site there'd be no reason to build this. Avoid terminal/hacker cliche (matrix-green monospace, fake CRT) as shorthand for "technical."

## Design Principles

Correctness is the pitch. Show the token model exactly — the claim shape, scope strings, validation order, HS256 signing — and never hand-wave the crypto. Precision is the product's value proposition and must be visible.

Docs are the product. Every screen serves comprehension. Ornament that doesn't help a reader understand or find something is working against the one job the site has.

Practice what you preach. The site's own build quality is evidence the library is well-made. Craft is not decoration here; it is proof.

Portable model, Gleam artifact. Teach the token concepts so a non-Gleam Fluid developer can follow them, then show the Gleam API as the concrete surface. Don't gate understanding of the model behind Gleam fluency.

Trust without theater. Earn belief through the real code, the constant-time verification, and the strict validation rules — never through padlock imagery or trust badges.

## Accessibility & Inclusion

Target WCAG 2.1 AA: AA contrast on all text (including code and muted metadata), full keyboard navigation, semantic structure and landmarks, visible focus states, and a `prefers-reduced-motion` alternative for every animation. Code samples must remain legible and copyable, and syntax highlighting must not be the only carrier of meaning.
