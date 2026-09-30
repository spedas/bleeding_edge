---
related_files:
  - AGENTS.md
  - spedas_gui/spd_gui.pro
  - spedas_gui/spedas_gui.pro
  - spedas_gui/tplot_gui.pro
  - spedas_gui/spedas_version.txt
  - spedas_gui/misc/spedas_init.pro
  - spedas_gui/misc/spedas_write_config.pro
  - spedas_gui/objects/spd_ui_plugin_manager__define.pro
  - spedas_gui/objects/spd_ui_loaded_data__define.pro
  - spedas_gui/objects/spd_ui_windows__define.pro
  - spedas_gui/objects/spd_ui_call_sequence__define.pro
  - spedas_gui/objects/spd_ui_document__define.pro
  - spedas_gui/display/spd_ui_draw_object__define.pro
  - spedas_gui/panels/spd_ui_init_load_window.pro
  - spedas_gui/panels/config_plugins/spd_ui_init_fileconfig.pro
  - spedas_gui/utilities/getpluginpath.pro
  - spedas_gui/utilities/spd_ui_call_plugin.pro
  - spedas_gui/utilities/spd_ui_dproc.pro
  - spedas_gui/utilities/save_document.pro
  - spedas_gui/utilities/open_spedas_document.pro
  - spedas_gui/plugins/themis_plugin.txt
  - spedas_gui/plugins/a_spedas_configsettings.txt
  - spedas_gui/api_examples/load_data_tab/yyy_ui_load_data.pro
  - spedas_gui/isee3d/isee_3d.pro
  - projects/themis/spedas_plugin/load_data/thm_ui_load_data_file.pro
maintenance: |
  Update when the plugin file format or the plugin manager changes, when the
  loadedData/windowStorage/callSequence objects or the document format change,
  or when a folder is added to or removed from spedas_gui/.
---

# SPEDAS GUI

The widget-based SPEDAS GUI: load data through mission plugins, process it, and
plot it with IDL object graphics. Mission-specific panels live in the mission
folders and are registered here through plugin text files.

## Layout

- `spd_gui.pro`: the main window, menus and the `spd_gui_event` handler.
  `spedas_gui.pro` is a one-line wrapper. `tplot_gui.pro` sends tplot variables
  from the command line into the GUI.
- `objects/`: the data and plot model (`spd_ui_*__define.pro` classes).
- `panels/`: dialogs (load window, data processing in `panels/dproc/`, axis,
  panel, line options, `spd_ui_mva`, field models, HAPI and CDAWeb choosers).
- `display/`: `spd_ui_draw_object__define.pro` turns the model into an IDLgr
  object tree; its methods are split across `display/draw_object/`.
- `utilities/`: menu actions (`utilities/spd_ui_main_funcs/`), markers, GUI
  coordinate transforms, and `utilities/test_support_routines/` (helpers such as
  `spd_init_tests` used by mission test suites).
- `plugins/`: one `*_plugin.txt` per mission or tool (see below).
- `misc/`: `spedas_init` and the SPEDAS configuration tab.
- `api_examples/`: template plugins named `yyy_*` for load tabs, config tabs,
  menus and data processing. Start here when writing a plugin.
- `isee3d/`: ISEE 3D particle-distribution viewer (`isee_3d.pro`, `stel3d`),
  called from THEMIS, MMS and ERG code; comments are partly in Japanese.
- `Resources/` (bitmaps, color table, text; found with `getresourcepath`),
  `help/` (help text). `deprecated/`: unused; skip it.

## How `spd_gui` starts and loads data

1. `spd_gui` returns if a GUI is already running, calls `spedas_init`
   (`misc/spedas_init.pro`, defines `!spedas`), then creates
   `spd_ui_plugin_manager` (`objects/spd_ui_plugin_manager__define.pro`).
2. The plugin manager finds `plugins/` with `utilities/getpluginpath.pro`,
   restores any `*.sav` there, and parses every `*.txt` there. Each line is
   `type: routine, extra`, with type `project`, `load_data`, `menu`, `config`,
   `data_processing` or `about`; see `plugins/themis_plugin.txt`.
3. Data > Load Data opens `panels/spd_ui_init_load_window.pro`, which builds one
   tab per `load_data` entry with `call_procedure` (for THEMIS,
   `projects/themis/spedas_plugin/load_data/thm_ui_load_data_file.pro`).
   Config tabs (`panels/config_plugins/spd_ui_init_fileconfig.pro`), Tools menu
   items (`utilities/spd_ui_call_plugin.pro`) and data processing plugins
   (`utilities/spd_ui_dproc.pro`, `call_function`) are called the same way.
4. A load tab loads tplot variables, copies them into the GUI with
   `loadedData->add` (`objects/spd_ui_loaded_data__define.pro`), and records the
   load in the call sequence with `addSt` and type `'loadapidata'`
   (`api_examples/load_data_tab/yyy_ui_load_data.pro` shows the pattern).
5. `drawObject->update, windowStorage, loadedData` redraws the pages.

## Things to know

- Plugin routine names exist only as strings in `plugins/*.txt`; grep there
  before renaming a mission `*_ui_*` routine. The mission side usually lives in
  `projects/<mission>/spedas_plugin/`, but not always (MMS uses
  `projects/mms/common/gui/`). Plugin files are read in sorted order, so
  `plugins/a_spedas_configsettings.txt` comes first.
- `!spedas` holds the live `loadedData`, `windowStorage`, `drawObject` and
  `historyWin` objects so command-line code (`tplot_gui`) can reach the GUI. Its
  settings are saved to `spedas_config.txt` by `misc/spedas_write_config.pro`.
- GUI variables are copies: `loadedData->add` stores pointers to a tplot
  variable's data, which must have double-precision times. Changing the tplot
  variable later does not change the GUI copy.
- Plot model: `spd_ui_windows` (`objects/spd_ui_windows__define.pro`) holds
  pages (`spd_ui_window`), which hold panels (`spd_ui_panel`) and their traces.
- GUI documents (`.tgd`) are XML written by `utilities/save_document.pro` from
  `spd_ui_document` (`objects/spd_ui_document__define.pro`). They store no data:
  `utilities/open_spedas_document.pro` replays the load and processing calls with
  `spd_ui_call_sequence::reCall` (`objects/spd_ui_call_sequence__define.pro`),
  which runs each `'loadapidata'` subtype routine with `call_procedure`. Plot
  option templates use `.tgt`. The GUI version string is in `spedas_version.txt`.
