;+
;NAME:    cl_csa_init
;
;PURPOSE: 
;   Initializes system variables for Cluster. Can be called from idl_startup to set
;   custom locations.
;
;NOTE:
;   The system variable !cluster_csa is defined here, just like !THEMIS.  
;   The elements of this structure are explained below:
;
;   !cluster_csa.LOCAL_DATA_DIR    This is the root location for all cluster data files.
;                  The MMS software expects all data files to reside in specific subdirectories relative
;                  to this root directory.;
;
;   !cluster_csa.REMOTE_DATA_DIR  This is the URL of the server that can provide the data files.
;                  (default is: "https://spdf.gsfc.nasa.gov/pub/data/cluster/")
;                  if the software does not find a needed file in LOCAL_DATA_DIR,
;                  then it will attempt to download the data from the URL and REMOTE_DATA_DIR is defined,
;                  the software will attempt to download the file from REMOTE_DATA_DIR, place it in LOCAL_DATA_DIR
;                  with the same relative pathname, and then continue processing.
;
;   !cluster_csa.MIRROR_DATA_DIR  - this is a mirror directory (typically over the local network); setting this
;                 will cause the load routines to check this for files after checking your local data directory. 
;                 If files are found here, they're copied to your local data directory, and the copied files
;                 are loaded
;   
;   Regarding data directory environment variables: it is highly advised to use the mission specific environment variables
;                  (e.g., CLUSTER_CSA_DATA_DIR) rather than ROOT_DATA_DIR to avoid conflicts with other missions/projects
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
; 2019-12-23, egrimes, forked for Cluster
; 
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-05-20 17:50:46 -0700 (Thu, 20 May 2021) $
; $LastChangedRevision: 29980 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cluster/cluster_science_archive/cl_csa_init.pro $
;-

pro cl_csa_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir,$
  no_color_setup=no_color_setup, mirror_data_dir=mirror_data_dir, debugging_gui=debugging_gui
  
  def_struct = file_retrieve(/structure_format)
  str_element, def_struct, 'mirror_data_dir', '', /add
  
  defsysv,'!cluster_csa',exists=exists
  if not keyword_set(exists) then begin; if !cluster_csa does not exist
    defsysv,'!cluster_csa', def_struct
  endif

  if keyword_set(reset) then !cluster_csa.init=0

  if !cluster_csa.init ne 0 then begin
    ;Assure that trailing slashes exist on data directories
    !cluster_csa.local_data_dir = spd_addslash(!cluster_csa.local_data_dir)
    !cluster_csa.remote_data_dir = spd_addslash(!cluster_csa.remote_data_dir)
    
    str_element, !cluster_csa, 'mirror_data_dir', success=mirror_available
    if mirror_available && !cluster_csa.mirror_data_dir ne '' then !cluster_csa.mirror_data_dir = spd_addslash(!cluster_csa.mirror_data_dir)
    return
  endif

  ;#######################################################
  ; On initial call or reset
  ;#######################################################
  
  !cluster_csa = def_struct; force setting of all elements to default values.
  !cluster_csa.preserve_mtime = 0
  
  cl_csa_config,no_color_setup=no_color_setup; override the defaults by local config file

  cl_csa_set_verbose ;propagate verbose setting into tplot_vars
  
  ; keywords on first call to cl__csa_init (or /reset) override environment and
  ; cl_csa_config
  if keyword_set(local_data_dir) then begin 
    !cluster_csa.local_data_dir = spd_addslash(local_data_dir)
  endif
  if keyword_set(remote_data_dir) then begin
    !cluster_csa.remote_data_dir = spd_addslash(remote_data_dir)
  endif
  if keyword_set(mirror_data_dir) then begin
    !cluster_csa.mirror_data_dir = spd_addslash(mirror_data_dir)
  endif
  
  cdf_lib_info,version=v,subincrement=si,release=r,increment=i,copyright=c
  cdf_version = string(format="(i0,'.',i0,'.',i0,a)",v,r,i,si)
  printdat,cdf_version

  cdf_version_readmin = '3.1.0'
  cdf_version_writemin = '3.1.1'
  cdf_version_cluster = '3.6.30';'3.6'
  
  if cdf_version lt cdf_version_readmin then begin
    print,'Your version of the CDF library ('+cdf_version+') is unable to read THEMIS and cluster data files.'
    print,'Please go to the following url to learn how to patch your system:'
    print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
    message,"You can have your data. You just can't read it! Sorry!"
  endif
  if cdf_version lt cdf_version_writemin then begin
    print,ptrace()
    print,'Your version of the CDF library ('+cdf_version+') is unable to correctly write THEMIS/cluster CDF data files.'
    print,'If you ever need to create CDF files then go to the following URL to learn how to patch your system:'
    print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
  endif

  cdf_leap_second_init
  
  ;----------------
  !cluster_csa.init = 1
  ;----------------
  
  ;debugging fix?
  if keyword_set(debugging_gui) && !version.release ge '8.3' then begin
    !debug_process_events = 0
  endif
  return
END

