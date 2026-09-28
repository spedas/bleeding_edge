---
related_files:
  - idl/projects/themis/AGENTS.md
  - README.md
  - LICENSE.txt
  - .gitattributes
  - .gitignore
  - .github/workflows/mirror_bleeding_edge.yml
  - idl/general/tplot/tplot_com.pro
  - idl/general/tplot/tplot_quant__define.pro
  - idl/general/tplot/store_data.pro
  - idl/general/tplot/get_data.pro
  - idl/general/misc/file_dailynames.pro
  - idl/general/spedas_tools/spd_download/spd_download.pro
  - idl/general/CDF/spd_cdf2tplot.pro
  - idl/general/misc/file_retrieve.pro
  - idl/projects/themis/examples/basic/thm_crib_fgm.pro
  - idl/_spd_doc.html
  - .github/workflows/agents_md.yml
  - .github/scripts/check_agents_md.py
  - .github/scripts/build_agents_map.py
  - .agents/skills/agents-map/SKILL.md
  - .agents/map/MAP.md
  - .agents/map/graph.json
maintenance: |
  Update when the top-level layout under idl/, tplot storage, the shared download
  and CDF routines, or the mirror workflow change, and list any new AGENTS.md
  whose nearest parent is this file.
---

# IDL SPEDAS (bleeding edge mirror)

IDL Space Physics Environment Data Analysis Software. Mission loaders download
data files and store them as tplot variables; the rest of the code analyzes,
transforms and plots those variables, and there is a GUI. All code is in `idl/`.

**This repository is a mirror of the upstream SVN repository.** Every week
`.github/workflows/mirror_bleeding_edge.yml` replaces the whole tree with the
upstream snapshot, keeping only `.github/`, `README.md`, `LICENSE.txt`,
`.gitattributes`, `.gitignore` and `AGENTS.md` files. Code changes made here are
overwritten; report them upstream instead (see `README.md`).

## Layout

- `idl/projects/<mission>/`: most missions (MAVEN, THEMIS, MMS, PSP as `SPP`,
  ELFIN, ERG, ...).
- `idl/general/`: shared libraries: `tplot/`, `misc/`, `cotrans/`, `CDF/`,
  `spedas_tools/`, `science/`, `spice/`.
- `idl/general/missions/`: older missions kept outside `projects/` (RBSP, STEREO,
  LANL, NOAA, Kyoto, ISTP). ACE, FAST, GOES and Wind have code in both
  `idl/general/missions/` and `idl/projects/`, so check both.
- `idl/spedas_gui/`: the SPEDAS GUI. `idl/external/`: third-party code (CDAWlib,
  IDL_GEOPACK, ICY, AACGM, das2).

## Finding a routine

IDL has no imports. Calling `foo` runs the first `foo.pro` found on `!PATH`.

- Find a definition with `find idl -name foo.pro`. If that finds nothing, grep
  for `pro foo` or `function foo`: helper routines are often defined in the same
  file as the routine that uses them, above it.
- 76 file names exist in more than one folder (mostly under
  `idl/general/missions/rbsp/`). Which copy runs depends on `!PATH` order.
- Routines are also called by name from strings (`call_procedure`,
  `call_function`, `execute`; about 750 calls). Grep for the name in quotes too,
  e.g. `'thm_load_fgm_relpath'`.
- `f(x)` can be a function call or array indexing; the syntax alone doesn't say.
- Most files open with a `;+` ... `;-` comment header describing usage and
  keywords. `idl/_spd_doc.html` indexes these headers.
- Crib sheets (about 400 `*crib*.pro` files) show intended usage, e.g.
  `idl/projects/themis/examples/basic/thm_crib_fgm.pro`.

## tplot variables

`store_data` (`idl/general/tplot/store_data.pro`) and `get_data`
(`idl/general/tplot/get_data.pro`) share the common block `tplot_com1`, which
`idl/general/tplot/tplot_com.pro` declares. Routines include it with
`@tplot_com`, so grep for that rather than `common tplot_com1`. `data_quants` is
an array of `{tplot_quant}` records (`idl/general/tplot/tplot_quant__define.pro`):
a name plus pointers to the data, limits and dlimits.

## Loaders

- Shared building blocks: `file_dailynames` (`idl/general/misc/file_dailynames.pro`)
  builds per-day file paths, `spd_download`
  (`idl/general/spedas_tools/spd_download/spd_download.pro`) fetches them, and
  `spd_cdf2tplot` (`idl/general/CDF/spd_cdf2tplot.pro`) stores CDF contents as
  tplot variables.
- Mission settings such as the data server live in system variables set by an
  init routine (for example `!themis`, set by `thm_init`), not in arguments.
- Conventions differ by mission. THEMIS uses one shared load engine (see
  `idl/projects/themis/AGENTS.md`); some older code still downloads with
  `file_retrieve` (`idl/general/misc/file_retrieve.pro`).

## Skip when searching

- Legacy folders: `obsolete/`, `deprecated/`, `old/`, `BACKUP/`,
  `L3_DO_NOT_USE/` (25 in total).
- Generated documentation: `*_spd_doc_list.html` files and `idl/_spd_doc.html`.
- Data: calibration tables (`.txt`, `.dat`, `.sav`) and SPICE kernels.

## AGENTS.md files

Any folder may have an AGENTS.md; none is required. Each one starts with a YAML
header with exactly two fields:

- `related_files`: metadata about that AGENTS.md. List every file its text
  describes and every related AGENTS.md (the nearest parent, the children, and
  any other it points to), as repo-relative paths.
- `maintenance`: when and how to update that AGENTS.md.

CI (`.github/workflows/agents_md.yml`) runs `.github/scripts/check_agents_md.py`
on every push and pull request, and weekly after the mirror sync. A missing or
malformed header fails the build. Listed paths that don't exist, described files
that aren't listed, and one-way parent/child links are warnings. Locally, run
`python .github/scripts/check_agents_md.py --strict` (needs PyYAML).

### The AGENTS.md map

`.agents/map/` holds a map of every AGENTS.md and its related files
(`.agents/map/MAP.md` for people, `.agents/map/graph.json` for tools), generated
by `.github/scripts/build_agents_map.py`. It is opt-in: after you add, remove or
revise an AGENTS.md, ask the human whether to rebuild the map, and rebuild it
only after an explicit yes, following `.agents/skills/agents-map/SKILL.md`.
