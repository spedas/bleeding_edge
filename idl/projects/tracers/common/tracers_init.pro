;+
;NAME:    tracers_init
;
;PURPOSE:
;   Initializes system variables for tracers.
;   
;NOTE:
;   The system variable !tracers is defined here, just like !THEMIS.
;   The elements of this structure are explained below:
;
;   !TRACERS.LOCAL_DATA_DIR    This is the root location for all tracers data files.
;                  The TRACERS software expects all data files to reside in specific subdirectories relative
;                  to this root directory.;
;
;   !TRACERS.REMOTE_DATA_DIR   This is not implemented yet because there is no server at this point in time.
;                  A URL will most likely be available after launch.
;
;   *******
;   WARNING: This version of tracers_init uses the remote data dir in the PUBLIC AREA
;   *******
;
;KEYWORDS:
;   RESET:           Reset !tracers to values in environment (or values in keywords).
;   LOCAL_DATA_DIR:  use given value for local_data_dir, rather than environment. Only works on
;                    initial call or reset.
;   REMOTE_DATA_DIR: Not yet implemented.
;   NO_COLOR_SETUP   do not set colors if already taken care of
;
;
;HISTORY:
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-07-31 17:36:13 -0700 (Thu, 31 Jul 2025) $
; $LastChangedRevision: 33518 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/tracers/common/tracers_init.pro $
;-

pro tracers_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir,$
  no_color_setup=no_color_setup

  def_struct = file_retrieve(/structure_format)

  defsysv,'!tracers',exists=exists
  if not keyword_set(exists) then begin; if !tracers does not exist
    defsysv,'!tracers', def_struct
  endif

  if keyword_set(reset) then !tracers.init=0

  if !tracers.init ne 0 then begin
    ;Assure that trailing slashes exist on data directories
    ; *********** ADD remote_data_dir from new machine **************
    !tracers.remote_data_dir = ''
    ;!tracers.remote_data_dir = spd_addslash(!tracers.remote_data_dir)
    !tracers.local_data_dir = spd_default_local_data_dir() + 'tracers/'
    !tracers.local_data_dir = spd_addslash(!tracers.local_data_dir)
    return
  endif

  ;#######################################################
  ; On initial call or reset
  ;#######################################################

  !tracers = def_struct; force setting of all elements to default values.
  !tracers.preserve_mtime = 0

  tracers_config,no_color_setup=no_color_setup; override the defaults by local config file
  ; temporarily override the private are and point to tracersindata
  ; *********** ADD remote_data_dir from new machine **************
  !tracers.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/tracers/'
  !tracers.remote_data_dir = spd_addslash(!tracers.remote_data_dir)
  !tracers.local_data_dir = spd_default_local_data_dir() + 'tracers/'
  !tracers.local_data_dir = spd_addslash(!tracers.local_data_dir)

  tracers_set_verbose ;propagate verbose setting into tplot_vars

  cdf_lib_info,version=v,subincrement=si,release=r,increment=i,copyright=c
  cdf_version = string(format="(i0,'.',i0,'.',i0,a)",v,r,i,si)
  printdat,cdf_version

  cdf_version_readmin = '3.1.0'
  cdf_version_writemin = '3.1.1'
  cdf_version_tracers = '3.6.30';'3.6'

  if cdf_version lt cdf_version_readmin then begin
    print,'Your version of the CDF library ('+cdf_version+') is unable to read TRACERS data files.'
    print,'Please go to the following url to learn how to patch your system:'
    print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
    message,"You can have your data. You just can't read it! Sorry!"
  endif
  if cdf_version lt cdf_version_writemin then begin
    print,ptrace()
    print,'Your version of the CDF library ('+cdf_version+') is unable to correctly write TRACERS CDF data files.'
    print,'If you ever need to create CDF files then go to the following URL to learn how to patch your system:'
    print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
  endif
  if cdf_version lt cdf_version_tracers then begin
    msg = ['A leap second was inserted on December 31, 2016.']
    msg = [msg,' ']
    msg = [msg,'For correct interpretation of time tags for TRACERS data taken after this date,']
    msg = [msg,'please upgrade your CDF software to its latest version at']
    msg = [msg,' ']
    msg = [msg,'http://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html']
    ; dialog_message commented out, 2/15/17, due to a bug on MacOS X 10.11.6/IDL 8.5
    ; -> this call was causing the IDL session to close unexpectedly
    ;result = dialog_message(msg,/center)
    print,'##########################'
    print,'     WARNING     '
    print,'##########################'
    print,' '
    print, msg
    print,' '
    print,'##########################'
  endif

  cdf_leap_second_init

  ;----------------
  !tracers.init = 1
  ;----------------

  dt = - (time_double('2025-07-23/11:13') - systime(1)) / 3600/24
  days = floor(dt)
  dt = (dt - days) * 24
  hours = floor(dt)
  dt = (dt - hours) * 60
  mins = floor(dt)
  dt = (dt - mins)  * 60
  secs = floor(dt)
  print,ptrace()
  print,days,hours,mins,secs,format= '("TRACERS countdown:",i4," Days, ",i02," Hours, ",i02," Minutes, ",i02," Seconds since launch")'

  return

END
