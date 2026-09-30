---
related_files:
  - idl/AGENTS.md
  - README.md
  - LICENSE.txt
  - .gitattributes
  - .gitignore
  - .github/workflows/mirror_bleeding_edge.yml
  - .github/workflows/agents_md.yml
  - idl/agents/scripts/check_agents_md.py
maintenance: |
  Update when the mirror or agents_md workflow changes, when a file is added
  outside idl/, or once upstream snapshots ship the AGENTS.md files and
  idl/agents/ (then drop the transition paragraph under "The mirror").
---

# IDL SPEDAS (GitHub mirror)

This repository mirrors the upstream IDL SPEDAS SVN repository: the `idl/`
folder is SVN trunk. Everything about the code, and the AGENTS.md convention,
is in `idl/AGENTS.md`; read it first. Paths in the AGENTS.md files under `idl/`
are relative to `idl/`, not to this repository's root. This file covers only
what exists on GitHub, and its own paths start at the repository root.

## The mirror

Every week `.github/workflows/mirror_bleeding_edge.yml` replaces the tree with
the upstream bleeding-edge snapshot, keeping only `.github/`, `README.md`,
`LICENSE.txt`, `.gitattributes`, `.gitignore` and this file. Code changes made
here are overwritten; report them upstream instead (see `README.md`).

The AGENTS.md files under `idl/` and the `idl/agents/` folder are meant for SVN
trunk, and upstream doesn't ship them yet. Until a snapshot contains
`idl/AGENTS.md`, the sync keeps this repository's AGENTS.md files under `idl/`;
until one contains `idl/agents/`, it keeps that folder. From then on each is
mirrored from upstream like code, and changes to it go upstream too.

Nothing under `idl/` may depend on files outside it: an SVN working copy has
only trunk.

## Checks

`.github/workflows/agents_md.yml` runs `idl/agents/scripts/check_agents_md.py`
on every push and pull request, and weekly after the mirror sync. It checks the
AGENTS.md files under `idl/` with `idl/` as the root, as in a trunk working
copy, then checks this file alone with the repository root as the root, since
its paths start there. To run both locally from the repository root:

    python idl/agents/scripts/check_agents_md.py --strict --root idl
    python idl/agents/scripts/check_agents_md.py --strict --root . AGENTS.md
