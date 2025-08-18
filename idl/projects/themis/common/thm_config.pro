;+
;  PRO themis_config
;
;  This procedure serves as the themis configuration file.  It sets global (system)
;  variables and initializes devices
;
;  This procedure will define the location of data files and the data server.
;  This procedure is intended to be called from within the "THM_INIT" procedure.
;
;  This should be the only THEMIS file that requires modification for use in different
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
;     no_color_setup   added to prevent cronjob to crash, hfrey, 2007-02-10
;
;  Author:  Davin Larson Nov 2006
;           jmm, 2007-05-17, Altered to read thm_comfig text file,
;           this removes the need for someone to alter this program
;           jmm, 2007-07-02, applies slashes to remote and local
;           directories, if they are not there
;           cg, 2008-5-6, reset default default directory
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2024-11-13 13:45:30 -0800 (Wed, 13 Nov 2024) $
; $LastChangedRevision: 32962 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_config.pro $
;
;-
pro thm_config,caching=caching,colortable=colortable,$
           no_color_setup=no_color_setup,no_download=no_download


;                        THEMIS SPECIFIC INITIALIZATION
;====================================================================================


; Location of the data Server:

;!themis.use_wget=1   ; uncomment to use experimental wget routine instead of file_http_copy (not recommended)

;Pick your favorite THEMIS data server:  (Comment out the others)
; !themis.remote_data_dir = 'http://cdpp.cesr.fr/themisdata/'             ; In France
; !themis.remote_data_dir = 'http://rhea.iwf.oeaw.ac.at/themisdata/'      ; In Austria, Does not include ground data!
;!themis.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/themis/'   ; use as backup web server
!themis.remote_data_dir = 'https://themis.ssl.berkeley.edu/data/themis/'

;!themis.use_wget=1   ; uncomment to use experimental wget routine
;instead of file_http_copy (not recommended)
;temporarily removing 'davin' block for 4_00 release
if strlowcase(getenv('USERNAME')) eq 'davin' then begin
;    !themis.remote_data_dir = 'http://boreas.ssl.berkeley.edu/data/themis/'   ;uncomment to test code with an offline server
;    !themis.use_wget=1
;    !themis.no_update = 1
;    !themis.no_clobber = 1
    !themis.verbose=2
    tplot_options,'datagap',1000.
endif

;;;;;;;;;;;
; SECTION 1
;;;;;;;;;;;

!themis.local_data_dir = root_data_dir() + 'themis/'

;settings in your local thm_config.txt file will override the
;defaults, jmm, 17-may-2007
ftest = thm_read_config()
If(size(ftest, /type) Eq 8) Then Begin
  !themis.local_data_dir = ftest.local_data_dir
  !themis.remote_data_dir = ftest.remote_data_dir
  !themis.no_download = ftest.no_download
  !themis.no_update = ftest.no_update
  !themis.downloadonly = ftest.downloadonly
  !themis.verbose = ftest.verbose
Endif

; Settings of environment variables can override thm_config

if getenv('SPEDAS_DATA_DIR') ne '' then $
   !themis.local_data_dir =  spd_addslash(getenv('SPEDAS_DATA_DIR'))+'themis/'
  
if getenv('THEMIS_DATA_DIR') ne '' then $
   !themis.local_data_dir = getenv('THEMIS_DATA_DIR')

if file_test(!themis.local_data_dir + '.themis_master',/regular) then !themis.no_server = 1

if getenv('THEMIS_REMOTE_DATA_DIR') ne '' then $
   !themis.remote_data_dir = getenv('THEMIS_REMOTE_DATA_DIR')

;check for slashes, add if necessary, jmm, 2-jul-2007
temp_string = strtrim(!themis.local_data_dir, 2)
ll = strmid(temp_string, strlen(temp_string)-1, 1)
If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
!themis.local_data_dir = temporary(temp_string)
temp_string = strtrim(!themis.remote_data_dir, 2)
ll = strmid(temp_string, strlen(temp_string)-1, 1)
If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
!themis.remote_data_dir = temporary(temp_string)


;                        GLOBAL SYSTEM VARIABLES and CONFIGURATIONS  (NON-THEMIS)
;====================================================================================
; Set global system variables:
; Please note: These settings will affect all IDL routines, NOT JUST THEMIS routines!

; ============ install custom color tables.
; Check for color table with additional tables (download if necessary)
; and set it as default for loadct2
; Defines 3 new tables:
; 41 wind3dp
; 42 B-W reversed
; 43 FAST-Special
;ctable_relpath = 'idl_ctables/colors1.tbl'

if keyword_set(no_download) then !themis.no_download=1

; ============ color setup

; Do not do color setup if taken care for already
if not keyword_set(no_color_setup) then begin

  spd_graphics_config,colortable=colortable
  
endif	; no_color_setup

;===========  debugging options

if !prompt eq 'IDL> ' then !prompt = 'THEMIS> '

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
;If(!themis.verbose Eq 0) Then tplot_options, 'verbose', 0 $ ;turn off default to verbose if !themis.verbose is zero, jmm, 30-sep-2009
;Else tplot_options,'verbose',1         ; Displays some extra messages in tplot (e.g. When variables get created/altered)
;tplot_options,'psym_lim',100      ; Displays symbols if less than 100 point in panel
tplot_options,'ygap',.5           ; Set gap distance between tplot panels.
tplot_options,'lazy_ytitle',1     ; breaks "_" into carriage returns on ytitles
tplot_options,'no_interp',1       ; prevents interpolation in spectrograms (recommended)



;!warn.obs_routines = 1
;!warn.OBS_SYSVARS = 1
;!warn.PARENS = 1
;!warn.TRUNCATED_FILENAME = 1



end
