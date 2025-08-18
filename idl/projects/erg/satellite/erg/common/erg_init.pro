;+
; PRO  erg_init
;
; :Description:
;    Initialize the system variable, directory path, etc. for ERG data
;
; :Params:
;
; :Keywords:
;   reset: Set to initialize !erg environmental variable and the graphic settings 
;   local_data_dir: If set, !erg.local_data_dir is overwritten with this
;   remote_data_dir: If set, !erg.remote_data_dir is overwritten with this 
;   no_color_setup: Set to avoid doing the default graphic settings by erg_graphics_config 
;   no_download: If set, !erg.no_download is set to "1" (NOT downloading data files from the remote data server)
;   silent: If set, this routine tries to suppress as many messages as possbile except warnings and errors
;   
; :Examples:
;   IDL> erg_init
;   IDL> erg_init, /reset 
;   
; :History:
; 2017/07/02: major changes to work with erg_graphics_config 
; 2016/02/01: first protetype
;
; :Author:
;   Tomo Hori, ERG Science Center, ISEE, Nagoya Univ. (tomo.hori at nagoya-u.jp)
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
pro erg_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, $
  no_color_setup=no_color_setup,no_download=no_download, silent=silent
  
  if undefined(silent) then silent = 0 
  

  defsysv,'!erg',exists=exists
  if not keyword_set(exists) then begin
    defsysv,'!erg', file_retrieve(/structure_format)
  endif

  if keyword_set(reset) then !erg.init=0

  if !erg.init ne 0 then begin
    ;Assure that trailing slashes exist on data directories
    !erg.local_data_dir = spd_addslash(!erg.local_data_dir)
    !erg.remote_data_dir = spd_addslash(!erg.remote_data_dir)
    return
  endif
  
  
  
  ;If it comes over here, that measns !erg is going to be initialized in the following block
   
  !erg = file_retrieve(/structure_format)    ; force setting of all elements to default values.
  
  ;;;;; Default settings for ERG ;;;;;
  !erg.init = 1 
  !erg.local_data_dir = root_data_dir() + 'ergsc/'
  !erg.remote_data_dir = 'https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/'
  !erg.preserve_mtime = 0 ;To avoid potential conflict with touch command on windows 
  
  !prompt = 'ERG> ' ;Prompt changed for ERG
  
  
  ;Settings of environment variables can override thm_config
  if getenv('ERG_DATA_DIR') ne '' then $
    !erg.local_data_dir = spd_addslash( getenv('ERG_DATA_DIR') )

  if getenv('ERG_REMOTE_DATA_DIR') ne '' then $
    !ERG.remote_data_dir = spd_addslash( getenv('ERG_REMOTE_DATA_DIR') )

  ;If local_data_dir and/or remote_data_dir is given as a keyword, override the above
  if keyword_set(local_data_dir) then !erg.local_data_dir = spd_addslash(local_data_dir)
  if keyword_set(remote_data_dir) then !erg.remote_data_dir = spd_addslash(remote_data_dir)


  ;No_download keyword is set if no_download/update is on
  if keyword_set(no_download) then !erg.no_download = 1
  if keyword_set(no_download) then !erg.no_update = 1
  
  ; The following calls set persistent flags in dprint that change subsequent output
  ;dprint,setdebug=3       ; set default debug level to value of 3
  ;dprint,/print_dlevel    ; uncomment to display dlevel/verbose at each dprint statement
  ;dprint,/print_dtime     ; uncomment to display time interval between dprint statements.
  dprint,print_trace=1    ; uncomment to display current procedure and line number on each line. (recommended)
  ;dprint,print_trace=3    ; uncomment to display entire program stack on each line.

  ; Some other useful options:
  tplot_options,window=0            ; Forces tplot to use only window 0 for all time plots
  tplot_options,'wshow',1           ; Raises tplot window when tplot is called
  tplot_options,'lazy_ytitle',1     ; breaks "_" into carriage returns on ytitles
  tplot_options,'no_interp',1       ; prevents interpolation in spectrograms (recommended)
  
  ; Check the version of CDF DLM 
  cdf_lib_info,version=v,subincrement=si,release=r,increment=i,copyright=c
  cdf_version = string(format="(i0,'.',i0,'.',i0,a)",v,r,i,si)
  if ~silent then printdat,cdf_version

  cdf_version_readmin = '3.6.3.1'
  cdf_version_writemin = '3.6.3.1'
  if ~silent then print, 'The version of the CDF library should be '+cdf_version_readmin+' or newer'
  if ~silent then print, 'to read a CDF file after the recent leap second time (2017.1.1).'

;  if cdf_version lt cdf_version_readmin then begin
;    print,'Your version of the CDF library ('+cdf_version+') may be unable to correctly read ERG data.'
;    print,'Please go to the following URL to learn how to patch your system:'
;    print,'https://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html'
;    message,"You can have your data. You just can't read it or would read with wrong time labels! Sorry!"
;  endif
  
  ; Set up the leap second table 
  cdf_leap_second_init


  !erg.init = 1

  if ~silent then printdat,/values,!erg,varname='!erg'   ;,/pgmtrace

;  if cdf_version lt cdf_version_writemin then begin
;    print,ptrace()
;    print,'Your version of the CDF library ('+cdf_version+') is unable to correctly write ERG CDF data files.'
;    print,'If you ever need to create CDF files then go to the following URL to learn how to patch your system:'
;    print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
;  endif


  ;Set the defalut color table
  if ~keyword_set(no_color_setup) then erg_graphics_config, colortable=colortable, silent=silent
  
  
  dt = - (time_double('2016-12-20/11:00') - systime(1)) / 3600/24
  days = floor(dt)
  dt = (dt - days) * 24
  hours = floor(dt)
  dt = (dt - hours) * 60
  mins = floor(dt)
  dt = (dt - mins)  * 60
  secs = floor(dt)

  if ~silent then print,ptrace()
  if ~silent then print,days,hours,mins,secs,format= '("ERG(Arase) in orbit for ",i4," Days, ",i02," Hours, ",i02," Minutes, ",i02," Seconds since launch")'

  
  return
end

