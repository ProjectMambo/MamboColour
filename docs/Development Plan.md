---
description: Maintenance stages and exit gates for MamboColour correctness, adaptability, compatibility, and consumer delivery.
title: Development plan
order: 20
---

::page{layout="docs" width="normal" sidebar=true}

# Development plan

MamboColour is a small released provider, so its plan is a maintenance contract rather than a feature roadmap. Work starts from a real defect, portability problem, accessibility finding, or consumer need and changes the smallest shared boundary that solves it.

The plan is not a calendar promise or issue list. Update it when evidence changes the public API, palette contract, compatibility rules, consumer migration order, validation gate, or retirement conditions.

## Current state

Version `0.3.0` provides one MamboOrche family through four authoritative CSV files: ordered UI roles and general accent colours for light and dark schemes. Matching zero-third-party-dependency Rust and Lua APIs expose semantic roles, hexadecimal and RGB values, zero-based `get(index)`, `len()`, visual `random()`, and reproducible `random_seeded(seed)` over the shared unsigned 32-bit seed domain.

Both implementations validate the exact UI-role sequence and matching light/dark accent keys and order. Rust embeds the CSV files and caches both themes on first use. Lua eagerly reads and caches all four files from the documented repository-relative layout. Descriptive accent names remain private, while accent position is public because direct and seeded selection depend on it.

MamboSite pins the Rust crate at an exact commit. MamboDot vendors the Lua module, four CSV files, licence, and exact revision. MamboWiki receives synchronized documentation and MamboSite-rendered output but does not call MamboColour directly. The current evidence is the `0.3.0` source, Rust and Lua/LuaJIT contract tests, contrast checks, consumer pins, migration documentation, and local repository gate. There is no registry package, release artifact, CI workflow, network service, or stored user data.

## Target maintenance state

Rust and Lua continue to describe one reviewed colour model with the same roles, positions, seed behavior, validation, and failure rules. Defects are reproduced once at the provider boundary, general adaptability is added only when a real consumer cannot express its need through the current API, palette changes retain paired accessibility, and affected consumers migrate through explicit immutable pins.

MamboColour remains application-neutral. It owns palette data, parsing, validation, generic colour access, selection behavior, and compatibility documentation. Consumers own CSS variables, Hyprland rules, terminal styles, widget mappings, generated adapters, build-time shuffles, and product-specific state names.

## Scope and deferrals

Maintenance includes parser and validation correctness, Rust/Lua parity, supported-runtime portability, palette contrast and pairing, generic API adaptation, dependency and licence review, consumer migration, documentation, and release gates.

Do not add a new family, scheme, role, language port, lookup mode, or distribution channel merely to make the project appear active. The plan excludes application-format generators, CSS or Hyprland formatters, lookup by private accent name, a command-line tool, plugin or configuration frameworks, a remote palette service, cryptographic randomness, and automatic consumer rewriting. Registry publication requires a demonstrated distribution problem that exact Git pins cannot reasonably serve.

## Compatibility, data, and trust boundaries

| Surface | Maintenance rule |
|---|---|
| Scheme names, UI role methods, return forms, CSV paths and schema | Public contract; removal or incompatible change requires a breaking version and migration. |
| Accent order and seeded mapping | Public contract because `get()` and `random_seeded()` expose positions; reorder only with explicit compatibility review. |
| Descriptive accent keys | Authoring detail; consumers must not depend on them by name. |
| Concrete colour values | User-visible but intentionally evolvable; require contrast, pairing, and affected-consumer review. |
| Rust and Lua implementations | One behavioral contract with language-native errors and distribution; public additions normally land in both together. |
| Consumer adapters and pins | Consumer-owned; provider changes do not silently modify them. |

CSV content, vendored file layout, seed values, and runtime facilities are trust boundaries. Malformed data must fail during paired initialization rather than produce a partial theme. The library handles no credentials, personal data, authorization, or network input. `random()` is decorative only and must never be represented as cryptographic, secret, unique, or guaranteed full-palette sampling.

MamboColour has no migration store or mutable user state. Recovery means returning a consumer to its previous reviewed commit or vendor snapshot. Keep the last compatible source and migration notes available; never move an existing tag or revision in place.

## Stage 1: Preserve and automate the baseline

Keep the `0.3.0` schemes, roles, CSV grammar, paired ordering, zero-based positions, 32-bit seeded mapping, and eager paired validation as the maintenance baseline. Run the existing Rust and Lua contract suite from a clean checkout, then add repository automation only for the same documented gate: formatting, tests, strict Clippy, supported Lua and LuaJIT where available, strict MamboDocs validation, and diff checks.

Automation must not invent a second build system, generator, release service, or dependency solely for CI. Record the tested Rust minimum/current versions and Lua runtimes truthfully; unsupported runtimes remain unsupported rather than receiving untested compatibility claims.

Exit gate: a clean checkout runs the complete documented gate locally and in repository automation, both implementations exercise the same bundled data, and a failing Rust, Lua, palette, or documentation check blocks delivery.

## Stage 2: Fix incidents at the owning boundary

For each real parser, path, entropy, runtime, contrast, or cross-language failure, first add the smallest regression that reproduces it. Fix shared data when the defect is a value or pairing problem, the parser when malformed input is accepted, and the language implementation when only that runtime is affected. Do not compensate inside MamboSite, MamboDot, or another consumer for a provider defect.

Maintain rejection coverage for missing, extra, reordered, duplicate, malformed, and mismatched rows; boundary coverage for zero and maximum seeds and direct indexes; Rust/Lua seeded parity; eager load behavior; working-directory independence after Lua load; global-random-state isolation; and semantic contrast against both background surfaces.

Exit gate: the regression fails before the fix and passes afterward, both language gates and all bundled palette checks pass, failure messages identify the invalid boundary, and unaffected consumers require no code change.

## Stage 3: Add only consumer-proven adaptability

Begin with the requesting consumer's concrete limitation. Prefer an existing semantic role for interface state, `get()` with `len()` for ordered access, `random()` for decorative variety, and `random_seeded()` for repeatability. Add a role or generic operation only when those contracts cannot express a product-neutral need shared or plausibly shareable beyond one application.

Implement an accepted public addition in Rust and Lua together, define its error and compatibility behavior, update focused tests and API documentation, and decide the version impact before consumer migration. Keep application terms such as window states, card CSS, widget categories, or framework formats in the consumer.

Palette refinements require paired light/dark review, text and non-text contrast checks appropriate to the role, and representative inspection in affected consumers. Changing an accent value may be compatible but still needs visual review; changing order, a role, or seeded mapping is a compatibility change.

Exit gate: the requesting consumer can remove its workaround through the generic contract, both APIs and docs agree, palette and parity checks pass, and no consumer-specific formatter, name lookup, or abstraction enters MamboColour.

## Stage 4: Coordinate compatibility and release

Classify the change before publication. Fixes preserve the documented contract; additive API changes advance the compatible pre-1.0 minor version; removals, renamed roles, schema changes, order changes, seed changes, and incompatible runtime requirements need an explicit breaking migration. Publish the provider commit first and never ask a consumer to pin an unavailable revision.

For an affected Rust API or palette change, update MamboSite's exact `Cargo.toml` and lockfile pin and run its complete theme and workspace gates. For an affected Lua API or palette change, replace MamboDot's module, four CSV files, licence, and revision from the same provider commit, regenerate its consumer-owned adapters, inspect the visual diff, and run its complete gate. Synchronize documentation and publish MamboWiki after provider and consumer revisions are final.

Rollback is consumer repinning or revendoring to the previous immutable provider commit. Do not force-push, retag, partially copy a snapshot, or claim that separate repositories update atomically.

Exit gate: provider checks pass at the published commit, every affected consumer records one available revision and passes its own gate, migration notes cover any compatibility change, the Wiki contains the final documentation, and rollback has been identified before delivery.

## Validation, milestones, and retirement

The narrow gate is the focused Rust or Lua regression plus palette validation. The provider gate is formatting, locked Rust tests, strict Clippy, documentation tests where applicable, Lua and LuaJIT contract tests, strict MamboDocs validation, and diff checks. Palette changes add contrast and paired visual review. Public-contract changes add the complete gates of affected consumers in provider-before-consumer order.

| Milestone | Outcome |
|---|---|
| Maintained baseline | The current Rust/Lua and four-file contracts remain reproducible and automatically checked. |
| Correctness release | An observed failure is fixed once at the provider boundary with regression evidence. |
| Adaptability release | A demonstrated generic consumer need is served without exposing private names or application formats. |
| Coordinated compatibility release | Provider, affected consumers, canonical documentation, and Wiki agree on one available revision and migration. |

The main risks are Rust/Lua drift, palette edits that pass schema checks but reduce readability, order changes that silently alter direct or seeded assignments, Lua layout or runtime assumptions hidden from vendors, and consumers pinning different source snapshots. Paired initialization, parity and contrast tests, immutable revisions, and consumer-owned adapters contain those risks.

Retire a language API only after every consumer has migrated away from it. Archive MamboColour only when no supported consumer needs either API and a final source snapshot, licence, compatibility record, and migration or replacement path have been preserved.
