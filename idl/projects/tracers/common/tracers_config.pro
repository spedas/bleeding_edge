;+
;  PRO tracers_config
;
;  This procedure serves as the TRACERS configuration file.  It sets global (system)
;  variables and initializes devices
;
;  This procedure will define the location of data files and the data server.
;  This procedure is intended to be called from within the "TRACERS_INIT" procedure.
;
;  This should be the only TRACERS file that requires modification for use in different
;  locations.
;
;  There is no need to modify this file if:
;     - Your computer is an SSL UNIX machine that mounts "/disks/data/"   (i.e. ALL Linux and Solaris machines at SSL)
;     - You use a portable computer that will be caching files on a local hard drive.
;
;
;  Settings  in this file will be overridden by settings in the environment.
;
;  KEYWORDS
;     colortable  - sets the color table for spd_graphics_config. this is not
;                   set if the no_color_setup keyword is used
;     no_color_setup   added to prevent cronjob to crash, hfrey, 2007-02-10
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-07-31 17:36:13 -0700 (Thu, 31 Jul 2025) $
; $LastChangedRevision: 33518 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/tracers/common/tracers_config.pro $
;
;-
pro tracers_config, colortable=colortable, no_color_setup=no_color_setup

  ;--------------------
  ; LOCAL_DATA_DIR
  ;--------------------
  !tracers.local_data_dir = spd_default_local_data_dir() + 'tracers/'

  ;--------------------
  ; Local Config File
  ;--------------------
  cfg = tracers_config_read(); read config file

  if (size(cfg,/type) eq 8)then begin; if config file exists, update !tracers from the file
    !TRACERS.LOCAL_DATA_DIR = cfg.local_data_dir
  endif else begin; if cfg not found,
    dir = tracers_config_filedir(); create config directory
    !TRACERS.LOCAL_DATA_DIR = spd_default_local_data_dir() + 'tracers/'
    pref = {LOCAL_DATA_DIR: !TRACERS.LOCAL_DATA_DIR}
    tracers_config_write, pref
  endelse

  ; Settings of environment variables can override tracers_config
  if getenv('TRACERS_REMOTE_DATA_DIR') ne '' then $
    !tracers.remote_data_dir = getenv('TRACERS_REMOTE_DATA_DIR') else $
    !tracers.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/tracers/'
  !tracers.remote_data_dir = spd_addslash(!tracers.remote_data_dir)

  ; Settings of environment variables can override tracers_config
  if getenv('TRACERS_DATA_DIR') ne '' then $
    !tracers.local_data_dir = getenv('TRACERS_DATA_DIR')
  !tracers.local_data_dir = spd_addslash(!tracers.local_data_dir)

  ;------------------------
  ; Global Sytem Variables
  ;------------------------
  ; Please note: These settings will affect all IDL routines, NOT JUST tracers routines!

  ;====
  ;===== COLOR SETUP
  ;
  ; Do not do color setup if taken care for already
  if not keyword_set(no_color_setup) then begin
    spd_graphics_config,colortable=colortable
  endif ; no_color_setup

  ;===========  DEBUGGING OPTIONS
  if !prompt ne 'TRACERS> ' then !prompt = 'TRACERS> '

  ; The following calls set persistent flags in dprint that change subsequent output
  ;dprint,setdebug=3       ; set default debug level to value of 3
  ;dprint,/print_dlevel    ; uncomment to display dlevel/verbose at each dprint statement
  ;dprint,/print_dtime     ; uncomment to display time interval between dprint statements.
  dprint,print_trace=1    ; uncomment to display current procedure and line number on each line. (recommended)
  ;dprint,print_trace=3    ; uncomment to display entire program stack on each line.

  ;  !quiet=1            ; if !quiet ==1 then  error messages are suppressed

  ;============= USEFUL TPLOT OPTIONS
  ;
  ; Most standard plotting keywords can be included in the global tplot_options routine
  ; or individually in each tplot variable using the procedure: "options"
  ; for example:
  ; tplot_options,'title','Themis Event #1'
  ; tplot_options,'charsize',1.2   ; set default character size.

  ; Some other useful options:
  tplot_options,window=0            ; Forces tplot to use only window 0 for all time plots
  tplot_options,'wshow',1           ; Raises tplot window when tplot is called
  tplot_options,'ygap',.5           ; Set gap distance between tplot panels.
  tplot_options,'lazy_ytitle',1     ; breaks "_" into carriage returns on ytitles
  tplot_options,'no_interp',1       ; prevents interpolation in spectrograms (recommended)

end
