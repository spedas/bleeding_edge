;+
;  PRO rbsp_emfisis_config
;
;  This procedure serves as the RBSP EMFISIS configuration file.  It sets global (system)
;  variables and initializes devices
;
;  This procedure will define the location of data files and the data server.
;  This procedure is intended to be called from within the "RBSP_EMFISIS_INIT" procedure.
;
;  This should be the only RBSP EMFISIS file that requires modification for use in different
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
;  Author:  Peter Schroeder May 2012
;
; $LastChangedBy: peters $
; $LastChangedDate: 2012-05-15 11:57:32 -0700 (Tue, 15 May 2012) $
; $LastChangedRevision: 10429 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/emfisis/rbsp_emfisis_config.pro $
;
;-
pro rbsp_emfisis_config,caching=caching,colortable=colortable,$
           no_color_setup=no_color_setup,no_download=no_download


;                        RBSP EMFISIS SPECIFIC INITIALIZATION
;====================================================================================


; Location of the data Server:

;!rbsp_emfisis.use_wget=1   ; uncomment to use experimental wget routine instead of file_http_copy (not recommended)

;Pick your favorite RBSP EMFISIS data server:  (Comment out the others)
; !rbsp_emfisis.remote_data_dir = 'http://cdpp.cesr.fr/themisdata/'             ; In France
; !rbsp_emfisis.remote_data_dir = 'http://rhea.iwf.oeaw.ac.at/themisdata/'      ; In Austria, Does not include ground data!
;!rbsp_emfisis.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/themis/'   ; use as backup web server
;!rbsp_emfisis.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/rbsp/'
!rbsp_emfisis.remote_data_dir = 'http://emfisis.physics.uiowa.edu/'

;!rbsp_emfisis.use_wget=1   ; uncomment to use experimental wget routine
;instead of file_http_copy (not recommended)
;temporarily removing 'davin' block for 4_00 release
if strlowcase(getenv('USERNAME')) eq 'davin' then begin
;    !themis.remote_data_dir = 'http://boreas.ssl.berkeley.edu/data/themis/'   ;uncomment to test code with an offline server
;    !themis.use_wget=1
;    !themis.no_update = 1
;    !themis.no_clobber = 1
    !rbsp_emfisis.verbose=2
    tplot_options,'datagap',1000.
endif

;;;;;;;;;;;
; SECTION 1
;;;;;;;;;;;

!rbsp_emfisis.local_data_dir = root_data_dir() + 'rbsp/emfisis/'

;settings in your local rbsp_emfisis_config.txt file will override the
;defaults
ftest = rbsp_emfisis_read_config()
If(size(ftest, /type) Eq 8) Then Begin
  !rbsp_emfisis.local_data_dir = ftest.local_data_dir
  !rbsp_emfisis.remote_data_dir = ftest.remote_data_dir
  !rbsp_emfisis.no_download = ftest.no_download
  !rbsp_emfisis.no_update = ftest.no_update
  !rbsp_emfisis.downloadonly = ftest.downloadonly
  !rbsp_emfisis.verbose = ftest.verbose
Endif

; Settings of environment variables can override thm_config
if getenv('rbsp_emfisis_DATA_DIR') ne '' then $
   !rbsp_emfisis.local_data_dir = getenv('rbsp_emfisis_DATA_DIR')

if file_test(!rbsp_emfisis.local_data_dir + '.rbsp_emfisis_master',/regular) then !rbsp_emfisis.no_download = 1

if getenv('rbsp_emfisis_REMOTE_DATA_DIR') ne '' then $
   !rbsp_emfisis.remote_data_dir = getenv('rbsp_emfisis_REMOTE_DATA_DIR')

;check for slashes, add if necessary, jmm, 2-jul-2007
temp_string = strtrim(!rbsp_emfisis.local_data_dir, 2)
ll = strmid(temp_string, strlen(temp_string)-1, 1)
If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
!rbsp_emfisis.local_data_dir = temporary(temp_string)
temp_string = strtrim(!rbsp_emfisis.remote_data_dir, 2)
ll = strmid(temp_string, strlen(temp_string)-1, 1)
If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
!rbsp_emfisis.remote_data_dir = temporary(temp_string)


;                        GLOBAL SYSTEM VARIABLES and CONFIGURATIONS  (NON-RBSP)
;====================================================================================
; Set global system variables:
; Please note: These settings will affect all IDL routines, NOT JUST RBSP routines!

; ============ install custom color tables.
; Check for color table with additional tables (download if necessary)
; and set it as default for loadct2
; Defines 3 new tables:
; 41 wind3dp
; 42 B-W reversed
; 43 FAST-Special
;ctable_relpath = 'idl_ctables/colors1.tbl'

if keyword_set(no_download) then !rbsp_emfisis.no_download=1

; ============ color setup

; Do not do color setup if taken care for already
if not keyword_set(no_color_setup) then begin

  ;ctable_file = file_retrieve(ctable_relpath, _extra=!themis)
  ;setenv,  'IDL_CT_FILE='+ctable_file

  ;This routine sets the IDL_CT_FILE env variable to a local file
  ;So that it doesn't need to be downloaded
 ; thmctpath

  if n_elements(colortable) eq 0 then colortable = 43     ; default color table

;                        Define POSTSCRIPT color table
  old_dev = !d.name             ;  save current device name
  set_plot,'PS'                 ;  change to PS so we can edit the font mapping
  loadct2,colortable
  device,/symbol,font_index=19  ;set font !19 to Symbol
  set_plot,old_dev              ;  revert to old device

;                        Color table for ordinary windows
  loadct2,colortable

;              Make black on white background
  !p.background = !d.table_size-1                   ; White background   (color table 34)
  !p.color=0                                        ; Black Pen
  !p.font = -1                                      ; Use default fonts


  if !d.name eq 'WIN' then begin
    device,decompose = 0
  endif

  if !d.name eq 'X' then begin
    ; device,pseudo_color=8  ;fixes color table problem for machines with 24-bit color
    device,decompose = 0
    if !version.os_name eq 'linux' then device,retain=2  ; Linux does not provide backing store by default
  endif

endif	; no_color_setup

;===========  debugging options

if !prompt eq 'IDL> ' then !prompt = 'rbsp_emfisis> '

; The following calls set persistent flags in dprint that change subsequent output
;dprint,setdebug=3       ; set default debug level to value of 3
;dprint,/print_dlevel    ; uncomment to display dlevel/verbose at each dprint statement
;dprint,/print_dtime     ; uncomment to display time interval between dprint statements.
dprint,print_trace=1    ; uncomment to display current procedure and line number on each line. (recommended)
;dprint,print_trace=3    ; uncomment to display entire program stack on each line.



;  !quiet=1            ; if !quiet ==1 then  error messages are suppressed


;============= Useful TPLOT options
; Most standard plotting keywords can be included in the global tplot_options routine
; or individually in each tplot variable using the procedure: "options"
; for example:
; tplot_options,'title','Themis Event #1'
; tplot_options,'charsize',1.2   ; set default character size.

; Some other useful options:
tplot_options,window=0            ; Forces tplot to use only window 0 for all time plots
tplot_options,'wshow',1           ; Raises tplot window when tplot is called
If(!rbsp_emfisis.verbose Eq 0) Then tplot_options, 'verbose', 0 $ ;turn off default to verbose if !themis.verbose is zero, jmm, 30-sep-2009
Else tplot_options,'verbose',1         ; Displays some extra messages in tplot (e.g. When variables get created/altered)
;tplot_options,'psym_lim',100      ; Displays symbols if less than 100 point in panel
tplot_options,'ygap',.5           ; Set gap distance between tplot panels.
tplot_options,'lazy_ytitle',1     ; breaks "_" into carriage returns on ytitles
tplot_options,'no_interp',1       ; prevents interpolation in spectrograms (recommended)



;!warn.obs_routines = 1
;!warn.OBS_SYSVARS = 1
;!warn.PARENS = 1
;!warn.TRUNCATED_FILENAME = 1



end
