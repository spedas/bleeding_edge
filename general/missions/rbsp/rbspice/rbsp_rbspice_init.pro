;+
;
; PROCEDURE:  rbsp_rbspice_init
;
; PURPOSE:    Initializes system variables for RBSP RBSPICE.  Can be called from idl_startup to set custom locations.
;
;             The system variable !RBSP_RBSPICE is defined here.  The elements of this structure are explained below:
;
;             !RBSP_RBSPICE.LOCAL_DATA_DIR    This is the root location for all RBSP RBSPICE data files.
;                  The RBSP RBSPICE software expects all data files to reside in specific subdirectories relative
;                  to this root directory.;
;
;             !RBSP_RBSPICE.REMOTE_DATA_DIR   This is the URL of the server that can provide the data files.
;                  (default is: "http://themis.ssl.berkeley.edu/data/themis/")
;                  if the software does not find a needed file in LOCAL_DATA_DIR,
;                  then it will attempt to download the data from the URL and REMOTE_DATA_DIR is defined,
;                  the software will attempt to download the file from REMOTE_DATA_DIR, place it in LOCAL_DATA_DIR
;                  with the same relative pathname, and then continue processing.
;
; KEYWORDS:
;   reset:           Reset !rbsp_rbspice to values in environment (or values in keywords).
;   local_data_dir:  use given value for local_data_dir, rather than environment. Only works on
;                    initial call or reset.
;   remote_data_dir: Use given value for remote_data_dir, rather than environment.  Only works on inital
;                    call or reset.
;   no_color_setup:  do not set colors if already taken care of
;
;
; REVISION HISTORY:
;     + ?, ?                          : created from rbsp_emfisis_init.pro
;     + Mar 2013,   K. Min            : ?
;     + 2016-12-08, I. Cohen          : updated mission start time
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-03 08:08:58 -0800 (Fri, 03 Mar 2017) $
;$LastChangedRevision: 22902 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/rbspice/rbsp_rbspice_init.pro $
;-
pro rbsp_rbspice_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, $
    no_color_setup=no_color_setup,no_download=no_download

  ; CDF TT2000 leap second
  cdf_leap_second_init
  
  ; Create !rbsp_rbspice system variable
  defsysv,'!rbsp_rbspice',exists=exists
  if not keyword_set(exists) then begin
      defsysv,'!rbsp_rbspice', file_retrieve(/structure_format)
  endif
  
  if keyword_set(reset) then !rbsp_rbspice.init=0
  
  if !rbsp_rbspice.init ne 0 then return
  
  !rbsp_rbspice = file_retrieve(/structure_format)    ; force setting of all elements to default values.
  
  ; Populate the empty !rbsp_rbspice
  rbsp_rbspice_config,no_color_setup=no_color_setup,no_download=no_download
  
  ; keywords on first call rbsp_rbspice_init (or /reset) override environment and
  ;rbsp_rbspice_config
  if keyword_set(local_data_dir) then begin
      temp_string = strtrim(local_data_dir, 2)
      ll = strmid(temp_string, strlen(temp_string)-1, 1)
      If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
      !rbsp_rbspice.local_data_dir = temporary(temp_string)
  endif
  
  if keyword_set(remote_data_dir) then begin
      temp_string = strtrim(remote_data_dir, 2)
      ll = strmid(temp_string, strlen(temp_string)-1, 1)
      If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
      !rbsp_rbspice.remote_data_dir = temporary(temp_string)
  endif
  
  ;
  servertestfile = '.rbsp_rbspice_master'     ;  This file should only be found on the server. (Do not download this file!)
  if file_test(!rbsp_rbspice.local_data_dir+servertestfile) then !rbsp_rbspice.no_download = 1
  
  ; Check for CDF varsion. Note that RBSP uses TT2000 Epoch!
  cdf_lib_info,version=v,subincrement=si,release=r,increment=i,copyright=c
  cdf_version = string(format="(i0,'.',i0,'.',i0,a)",v,r,i,si)
  printdat,cdf_version
  
  cdf_version_readmin = '3.4.0' ;***THIS MAY NEED TO CHANGE
  cdf_version_writemin = '3.4.0'
  
  if cdf_version lt cdf_version_readmin then begin
      print,ptrace()
      print,'Your version of the CDF library ('+cdf_version+') is unable to read RBSP RBSPICE data files.'
      print,'Please go to the following url to learn how to patch your system:'
      print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
      message,"You can have your data. You just can't read it! Sorry!"
  endif
  
  ; Init done
  !rbsp_rbspice.init = 1
  
  ; Print out !rbsp_rbspice
  ;printdat,/values,!rbsp_rbspice,varname='!rbsp_rbspice'   ;,/pgmtrace
  
  ; RBSP mission elapsed time
  dt = - (time_double('2012-8-30/8:05') - systime(1)) / 3600/24 ;***Needs update
  days = floor(dt)
  dt = (dt - days) * 24
  hours = floor(dt)
  dt = (dt - hours) * 60
  mins = floor(dt)
  dt = (dt - mins)  * 60
  secs = floor(dt)
  
  print,ptrace()
  print,days,hours,mins,secs,format= '("RBSP countdown: ",i4," Days, ",i02," Hours, ",i02," Minutes, ",i02," Seconds since launch")'

end

