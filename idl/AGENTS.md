---
related_files:
  - projects/AGENTS.md
  - general/AGENTS.md
  - spedas_gui/AGENTS.md
  - external/AGENTS.md
  - projects/themis/AGENTS.md
  - general/tplot/tplot_com.pro
  - general/tplot/tplot_quant__define.pro
  - general/tplot/store_data.pro
  - general/tplot/get_data.pro
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/CDF/spd_cdf2tplot.pro
  - general/misc/file_retrieve.pro
  - projects/themis/examples/basic/thm_crib_fgm.pro
  - agents/scripts/check_agents_md.py
  - agents/scripts/build_agents_map.py
  - agents/skills/agents-map/SKILL.md
  - agents/map/MAP.md
  - agents/map/graph.json
maintenance: |
  Update when the top-level layout, tplot storage, the shared download and CDF
  routines, or the AGENTS.md tools in agents/ change, and list any new
  AGENTS.md whose nearest parent is this file.
---

# IDL SPEDAS

IDL Space Physics Environment Data Analysis Software. Mission loaders download
data files and store them as tplot variables; the rest of the code analyzes,
transforms and plots those variables, and there is a GUI.

This folder is the top of the source tree (the SVN trunk). Every path in an
AGENTS.md header is relative to it. A path in AGENTS.md text is relative to that
AGENTS.md's folder, or else to this folder, so `general/tplot/store_data.pro`
means the same file wherever it appears.

## Layout

Each of these folders has its own AGENTS.md, and so do most larger missions and
instruments below them.

- `projects/<mission>/`: most missions (MAVEN, THEMIS, MMS, PSP as `SPP`,
  ELFIN, ERG, ...).
- `general/`: shared libraries: `tplot/`, `misc/`, `cotrans/`, `CDF/`,
  `spedas_tools/`, `science/`, `spice/`.
- `general/missions/`: older missions kept outside `projects/` (RBSP, STEREO,
  LANL, NOAA, Kyoto, ISTP). ACE, FAST, GOES and Wind have code in both
  `general/missions/` and `projects/`, so check both.
- `spedas_gui/`: the SPEDAS GUI. `external/`: third-party code (CDAWlib in
  `external/spdfcdas/`, IDL_GEOPACK, ICY, AACGM, das2).
- `agents/`: tools for these AGENTS.md files (see below); no IDL code.

## Finding a routine

IDL has no imports. Calling `foo` runs the first `foo.pro` found on `!PATH`.

- Find a definition with `find . -name foo.pro` from this folder. If that finds
  nothing, grep for `pro foo` or `function foo`: helper routines are often
  defined in the same file as the routine that uses them, above it.
- 76 file names exist in more than one folder (mostly under
  `general/missions/rbsp/`). Which copy runs depends on `!PATH` order.
- Routines are also called by name from strings (`call_procedure`,
  `call_function`, `execute`; about 750 calls). Grep for the name in quotes too,
  e.g. `'thm_load_fgm_relpath'`.
- `f(x)` can be a function call or array indexing; the syntax alone doesn't say.
- Most files open with a `;+` ... `;-` comment header describing usage and
  keywords. The build of the bleeding-edge zip turns these headers into HTML
  pages (_spd_doc.html here, `*_spd_doc_list.html` beside the folders); an SVN
  working copy may not have them.
- Crib sheets (about 400 `*crib*.pro` files) show intended usage, e.g.
  `projects/themis/examples/basic/thm_crib_fgm.pro`.

## tplot variables

`store_data` (`general/tplot/store_data.pro`) and `get_data`
(`general/tplot/get_data.pro`) share the common block `tplot_com1`, which
`general/tplot/tplot_com.pro` declares. Routines include it with
`@tplot_com`, so grep for that rather than `common tplot_com1`. `data_quants` is
an array of `{tplot_quant}` records (`general/tplot/tplot_quant__define.pro`):
a name plus pointers to the data, limits and dlimits.

## Loaders

- Shared building blocks: `file_dailynames` (`general/misc/file_dailynames.pro`)
  builds per-day file paths, `spd_download`
  (`general/spedas_tools/spd_download/spd_download.pro`) fetches them, and
  `spd_cdf2tplot` (`general/CDF/spd_cdf2tplot.pro`) stores CDF contents as
  tplot variables.
- Mission settings such as the data server live in system variables set by an
  init routine (for example `!themis`, set by `thm_init`), not in arguments.
- Conventions differ by mission. THEMIS uses one shared load engine (see
  `projects/themis/AGENTS.md`); some older code still downloads with
  `file_retrieve` (`general/misc/file_retrieve.pro`).

## Skip when searching

- Legacy folders: `obsolete/`, `deprecated/`, `old/`, `BACKUP/`,
  `L3_DO_NOT_USE/` (25 in total).
- Generated documentation: the `*_spd_doc*.html` pages.
- Data: calibration tables (`.txt`, `.dat`, `.sav`) and SPICE kernels.

## AGENTS.md files

Any folder may have an AGENTS.md; none is required. Each one starts with a YAML
header with exactly two fields:

- `related_files`: metadata about that AGENTS.md. List every file its text
  describes and every related AGENTS.md (the nearest parent, the children, and
  any other it points to), as paths relative to this folder.
- `maintenance`: when and how to update that AGENTS.md.

List only files that are in the source tree. Name files that only a build
creates, such as the zip's svn_version_info.txt, in plain text rather than as
code, so the check below gives the same result in an SVN working copy and in an
unpacked zip.

To check the headers, run `python agents/scripts/check_agents_md.py --strict`
from this folder (needs PyYAML). The script finds this folder from its own
location, not from the current directory; `--root` points it elsewhere, and
naming AGENTS.md files after the options checks only those. A missing or
malformed header is an error. Listed paths that don't exist, described files
that aren't listed, and one-way parent/child links are warnings, which
`--strict` turns into failures.

### The AGENTS.md map

`agents/map/` holds a map of every AGENTS.md and its related files
(`agents/map/MAP.md` for people, `agents/map/graph.json` for tools), generated
by `agents/scripts/build_agents_map.py`. It is opt-in: after you add, remove or
revise an AGENTS.md, ask the human whether to rebuild the map, and rebuild it
only after an explicit yes, following `agents/skills/agents-map/SKILL.md`.
