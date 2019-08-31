;+
;NAME:    mms_init
;
;PURPOSE: 
;   Initializes system variables for MMS. Can be called from idl_startup to set
;   custom locations.
;
;NOTE:
;   The system variable !MMS is defined here, just like !THEMIS.  
;   The elements of this structure are explained below:
;
;   !MMS.LOCAL_DATA_DIR    This is the root location for all MMS data files.
;                  The MMS software expects all data files to reside in specific subdirectories relative
;                  to this root directory.;
;
;   !MMS.REMOTE_DATA_DIR   (warning: SPDF ONLY) - This is the URL of the server that can provide the data files.
;                  (default is: "https://spdf.sci.gsfc.nasa.gov/pub/data/mms/")
;                  if the software does not find a needed file in LOCAL_DATA_DIR,
;                  then it will attempt to download the data from the URL and REMOTE_DATA_DIR is defined,
;                  the software will attempt to download the file from REMOTE_DATA_DIR, place it in LOCAL_DATA_DIR
;                  with the same relative pathname, and then continue processing.
;
;   !MMS.MIRROR_DATA_DIR  - this is a mirror directory (typically over the local network); setting this
;                 will cause the load routines to check this for files after checking your local data directory. 
;                 If files are found here, they're copied to your local data directory, and the copied files
;                 are loaded
;   
;   Regarding data directory environment variables: it is highly advised to use the mission specific environment variables
;                  (e.g., MMS_DATA_DIR) rather than ROOT_DATA_DIR to avoid conflicts with other missions/projects
;  
;   *** please note that setting REMOTE_DATA_DIR will have no effect when loading data from the LASP SDC, due to the 
;       custom web services at the SDC; this still allows you override the remote path to the data at SPDF, though ***
;   
;KEYWORDS:
;   RESET:           Reset !mms to values in environment (or values in keywords).
;   LOCAL_DATA_DIR:  use given value for local_data_dir, rather than environment. Only works on
;                    initial call or reset.
;   REMOTE_DATA_DIR: Use given value for remote_data_dir, rather than env.  Only works on inital
;                    call or reset.
;   MIRROR_DATA_DIR:  network mirror directory - for loading data from the local network; note that this 
;                    will copy files to your local data directory if they're found on the mirror, and this is
;                    only checked if the files do not currently exist in the LOCAL_DATA_DIR. Only works on inital
;                    call or reset.
;   NO_COLOR_SETUP   do not set colors if already taken care of
;   DEBUGGING_GUI:   set this keyword if you intend to put 'stop's in any GUI widget code, i.e., if you're debugging
;                    any code that involves widget events (EVA or the SPEDAS GUI)
;   
;
;
;HISTORY:
; 2015-04-10, moka, Created based on 'thm_init'
; 2015-02-15, egrimes, commented out dialog_message in CDF version error due to a bug on MacOS X 10.11.6/IDL 8.5
; 2018-04-05, egrimes, added MIRROR_DATA_DIR functionality
; 2019-08-28, egrimes, made debugging fix (!debug_process_events=0) dependent on a keyword (DEBUGGING_GUI)
;                      this debugging fix is known to cause problems with widgets on some machines
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-08-30 10:24:21 -0700 (Fri, 30 Aug 2019) $
; $LastChangedRevision: 27702 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_init.pro $
;-

pro mms_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir,$
  no_color_setup=no_color_setup, mirror_data_dir=mirror_data_dir, debugging_gui=debugging_gui
  
  def_struct = file_retrieve(/structure_format)
  str_element, def_struct, 'mirror_data_dir', '', /add
  
  defsysv,'!mms',exists=exists
  if not keyword_set(exists) then begin; if !mms does not exist
    defsysv,'!mms', def_struct
  endif

  if keyword_set(reset) then !mms.init=0

  if !mms.init ne 0 then begin
    ;Assure that trailing slashes exist on data directories
    !mms.local_data_dir = spd_addslash(!mms.local_data_dir)
    !mms.remote_data_dir = spd_addslash(!mms.remote_data_dir)
    
    str_element, !mms, 'mirror_data_dir', success=mirror_available
    if mirror_available && !mms.mirror_data_dir ne '' then !mms.mirror_data_dir = spd_addslash(!mms.mirror_data_dir)
    return
  endif

  ;#######################################################
  ; On initial call or reset
  ;#######################################################
  
  !mms = def_struct; force setting of all elements to default values.
  !mms.preserve_mtime = 0
  
  mms_config,no_color_setup=no_color_setup; override the defaults by local config file

  mms_set_verbose ;propagate verbose setting into tplot_vars
  
  ; keywords on first call to mms_init (or /reset) override environment and
  ; mms_config
  if keyword_set(local_data_dir) then begin 
    !mms.local_data_dir = spd_addslash(local_data_dir)
  endif
  if keyword_set(remote_data_dir) then begin
    !mms.remote_data_dir = spd_addslash(remote_data_dir)
  endif
  if keyword_set(mirror_data_dir) then begin
    !mms.mirror_data_dir = spd_addslash(mirror_data_dir)
  endif
  
  cdf_lib_info,version=v,subincrement=si,release=r,increment=i,copyright=c
  cdf_version = string(format="(i0,'.',i0,'.',i0,a)",v,r,i,si)
  printdat,cdf_version

  cdf_version_readmin = '3.1.0'
  cdf_version_writemin = '3.1.1'
  cdf_version_mms = '3.6.30';'3.6'
  
  if cdf_version lt cdf_version_readmin then begin
    print,'Your version of the CDF library ('+cdf_version+') is unable to read THEMIS and MMS data files.'
    print,'Please go to the following url to learn how to patch your system:'
    print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
    message,"You can have your data. You just can't read it! Sorry!"
  endif
  if cdf_version lt cdf_version_writemin then begin
    print,ptrace()
    print,'Your version of the CDF library ('+cdf_version+') is unable to correctly write THEMIS/MMS CDF data files.'
    print,'If you ever need to create CDF files then go to the following URL to learn how to patch your system:'
    print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
  endif
  if cdf_version lt cdf_version_mms then begin
    msg = ['A leap second was inserted on December 31, 2016.']
    msg = [msg,' ']
    msg = [msg,'For correct interpretation of time tags for MMS data taken after this date,']
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
    stop
  endif
  
  cdf_leap_second_init
  
  ;----------------
  !mms.init = 1
  ;----------------
  
  dt = - (time_double('2015-3-12/22:44') - systime(1)) / 3600/24
  days = floor(dt)
  dt = (dt - days) * 24
  hours = floor(dt)
  dt = (dt - hours) * 60
  mins = floor(dt)
  dt = (dt - mins)  * 60
  secs = floor(dt)
  print,ptrace()
  print,days,hours,mins,secs,format= '("MMS countdown:",i4," Days, ",i02," Hours, ",i02," Minutes, ",i02," Seconds since launch")'

  ;debugging fix?
  if keyword_set(debugging_gui) && !version.release ge '8.3' then begin
    !debug_process_events = 0
  endif
  return
END

