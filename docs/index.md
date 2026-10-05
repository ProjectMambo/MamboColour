---
description: One shared MamboOrche palette family with stable Rust and Lua access APIs.
title: MamboColour
order: 10
---

::page{layout="project" width="normal" sidebar=true}

# MamboColour

MamboColour is Project Mambo's shared theme boundary. Four CSV files define MamboOrche's UI roles and general colours for light and dark schemes; zero-third-party-dependency Rust and Lua APIs provide consistent access without generated application files.

::button{label="Source code" href="https://github.com/ProjectMambo/MamboColour" variant="secondary" external=true}

## What it provides

- One MamboOrche family with UI and general-colour layers in light and dark schemes.
- Stable semantic role methods such as `fg()`, `bg_surface()`, and `error()`.
- Zero-based `get(index)` for direct value access and complete ordered enumeration without exposing descriptive CSV names.
- `random()` for visual accent variety and `random_seeded()` for repeatable cross-language assignment.
- `Colour.hex()` and `Colour.rgb()` values through matching Rust and Lua models.
- A documented `key,hex` file contract validated by both implementations.

Accent names remain an authoring detail rather than a consumer dependency. Each application maps MamboColour results into its own CSS, terminal, desktop, or widget interface.

## Documentation

::children{view="list" sort="order" direction="asc" show=["title","description"]}

## Current status

The source API transition is active and currently tested on Linux. The Rust crate is at `0.3.0` but is not published, the Lua module is distributed with the source tree, and consumers should pin a reviewed repository commit. Both APIs share zero-based positional lookup, an explicit 32-bit seeded-selection domain, and validation of both schemes as one paired contract. The former `mbcolor`/`mbcolour` command, format generator, and separate MamboOutback family are no longer part of the interface.
