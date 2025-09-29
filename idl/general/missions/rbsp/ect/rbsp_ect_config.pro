;+
;  PRO rbsp_ect_config
;
;  This procedure serves as the RBSP ECT configuration file.  It sets global (system)
;  variables and initializes devices
;
;  This procedure will define the location of data files and the data server.
;  This procedure is intended to be called from within the "RBSP_ECT_INIT" procedure.
;
;  This should be the only RBSP ECT file that requires modification for use in different
;  locations.
;
;  There is no need to modify this file if:
;     - Your computer is an SSL UNIX machine that mounts "/disks/data/"   (i.e. ALL Linux and Solaris machines at SSL)
;     - You use a portable computer that will be caching files on a local hard drive.
;
;
;  Settings  in this file will be overridden by settings in the environment.
;  (see setup_themis or setup_themis_bash for examples of setting environment
;  variables on UNIX-like systems.  The environment can also be set on Windows
;  systems.)
;
;  KEYWORDS
;     no_color_setup: do not set colors if already taken care of
;
;  CREATED: Jan 2013, based on rbsp_efw_config
;  AUTHOR: Kris Kersten, kris.kersten@gmail.com
;
; $LastChangedBy: dcarpenter $
; $LastChangedDate: 2025-09-23 08:17:08 -0700 (Tue, 23 Sep 2025) $
; $LastChangedRevision: 33651 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/ect/rbsp_ect_config.pro $
;
;-
pro rbsp_ect_config, caching = caching, colortable = colortable, $
  no_color_setup = no_color_setup, no_download = no_download
  ; RBSP ECT SPECIFIC INITIALIZATION
  ; ====================================================================================

  ; Location of the data Server:

  ; !rbsp_ect.use_wget=1   ; uncomment to use experimental wget routine instead of file_http_copy (not recommended)

  ; ECT data server:
  ; !rbsp_ect.remote_data_dir = 'http://www.rbsp-ect.lanl.gov/data_pub/'
  ; !rbsp_ect.remote_data_dir = 'https://rbsp-ect.lanl.gov/data_pub/'
  ; rbsp_ect.remote_data_dir = 'https://rbsp-ect.newmexicoconsortium.org/data_pub/'
  !rbsp_ect.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/rbsp/'

  ; ;;;;;;;;;;
  ; SECTION 1
  ; ;;;;;;;;;;

  !rbsp_ect.local_data_dir = root_data_dir() + 'rbsp/ect/'

  ; NOTE: local text configuration options have been removed in favor of env vars

  ; Settings of environment variables can override thm_config
  if getenv('RBSP_ECT_DATA_DIR') ne '' then $
    !rbsp_ect.local_data_dir = getenv('RBSP_ECT_DATA_DIR')

  if file_test(!rbsp_ect.local_data_dir + '.rbsp_ect_master', /regular) then !rbsp_ect.no_download = 1

  if getenv('RBSP_ECT_REMOTE_DATA_DIR') ne '' then $
    !rbsp_ect.remote_data_dir = getenv('RBSP_ECT_REMOTE_DATA_DIR')

  ; check for slashes, add if necessary, jmm, 2-jul-2007
  temp_string = strtrim(!rbsp_ect.local_data_dir, 2)
  ll = strmid(temp_string, strlen(temp_string) - 1, 1)
  if (ll ne '/' and ll ne '\') then temp_string = temp_string + '/'
  !rbsp_ect.local_data_dir = temporary(temp_string)
  temp_string = strtrim(!rbsp_ect.remote_data_dir, 2)
  ll = strmid(temp_string, strlen(temp_string) - 1, 1)
  if (ll ne '/' and ll ne '\') then temp_string = temp_string + '/'
  !rbsp_ect.remote_data_dir = temporary(temp_string)

  ; GLOBAL SYSTEM VARIABLES and CONFIGURATIONS  (NON-RBSP)
  ; ====================================================================================
  ; Set global system variables:
  ; Please note: These settings will affect all IDL routines, NOT JUST RBSP routines!

  ; ============ install custom color tables.
  ; Check for color table with additional tables (download if necessary)
  ; and set it as default for loadct2
  ; Defines 3 new tables:
  ; 41 wind3dp
  ; 42 B-W reversed
  ; 43 FAST-Special
  ; ctable_relpath = 'idl_ctables/colors1.tbl'

  if keyword_set(no_download) then !rbsp_ect.no_download = 1

  ; ============ color setup

  ; Do not do color setup if taken care for already
  if not keyword_set(no_color_setup) then begin
    ; ctable_file = file_retrieve(ctable_relpath, _extra=!themis)
    ; setenv,  'IDL_CT_FILE='+ctable_file

    ; This routine sets the IDL_CT_FILE env variable to a local file
    ; So that it doesn't need to be downloaded
    ; thmctpath

    if n_elements(colortable) eq 0 then colortable = 43 ; default color table

    ; Define POSTSCRIPT color table
    old_dev = !d.name ; save current device name
    set_plot, 'PS' ; change to PS so we can edit the font mapping
    loadct2, colortable
    device, /symbol, font_index = 19 ; set font !19 to Symbol
    set_plot, old_dev ; revert to old device

    ; Color table for ordinary windows
    loadct2, colortable

    ; Make black on white background
    !p.background = !d.table_size - 1 ; White background   (color table 34)
    !p.color = 0 ; Black Pen
    !p.font = -1 ; Use default fonts

    if !d.name eq 'WIN' then begin
      device, decompose = 0
    endif

    if !d.name eq 'X' then begin
      ; device,pseudo_color=8  ;fixes color table problem for machines with 24-bit color
      device, decompose = 0
      if !version.os_name eq 'linux' then device, retain = 2 ; Linux does not provide backing store by default
    endif
  endif ; no_color_setup

  ; ===========  debugging options

  if !prompt eq 'IDL> ' then !prompt = 'RBSP_ECT> '

  ; The following calls set persistent flags in dprint that change subsequent output
  ; dprint,setdebug=3       ; set default debug level to value of 3
  ; dprint,/print_dlevel    ; uncomment to display dlevel/verbose at each dprint statement
  ; dprint,/print_dtime     ; uncomment to display time interval between dprint statements.
  DPRINT, print_trace = 1 ; uncomment to display current procedure and line number on each line. (recommended)
  ; dprint,print_trace=3    ; uncomment to display entire program stack on each line.

  ; !quiet=1            ; if !quiet ==1 then  error messages are suppressed

  ; ============= Useful TPLOT options
  ; Most standard plotting keywords can be included in the global tplot_options routine
  ; or individually in each tplot variable using the procedure: "options"
  ; for example:
  ; tplot_options,'title','Themis Event #1'
  ; tplot_options,'charsize',1.2   ; set default character size.

  ; Some other useful options:
  tplot_options, window = 0 ; Forces tplot to use only window 0 for all time plots
  tplot_options, 'wshow', 1 ; Raises tplot window when tplot is called
  if (!rbsp_ect.verbose eq 0) then tplot_options, 'verbose', 0 $ ; turn off default to verbose if !themis.verbose is zero, jmm, 30-sep-2009
  else tplot_options, 'verbose', 1 ; Displays some extra messages in tplot (e.g. When variables get created/altered)
  ; tplot_options,'psym_lim',100      ; Displays symbols if less than 100 point in panel
  tplot_options, 'ygap', .5 ; Set gap distance between tplot panels.
  tplot_options, 'lazy_ytitle', 1 ; breaks "_" into carriage returns on ytitles
  tplot_options, 'no_interp', 1 ; prevents interpolation in spectrograms (recommended)

  ; !warn.obs_routines = 1
  ; !warn.OBS_SYSVARS = 1
  ; !warn.PARENS = 1
  ; !warn.TRUNCATED_FILENAME = 1
end
