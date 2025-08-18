;+
;PROCEDURE:  cdf_leap_second_init
;PURPOSE:    CDF library 3.4.0 and later supports time formats
;            the include leap seconds.  Specifically tt2000.
;            This routine maintains the calibration file that is required
;            by the CDF library and TDAS to perform the conversions.
;
;NOTES: #1 Missions that use tt2000 times in their CDFs should call this routine inside their mission init/
;       config routines. (e.g. thm_init/thm_config)
;       #2 Set !CDF_LEAP_SECOND.preserve_leap_seconds=1 if you want to keep leap seconds included in unix times after they're imported.
;       This may mean that the data set will have a time dependent time skew with other data sets by ~35 seconds.(or more as additional 
;       leap seconds are added.)
;       #3 This routine may modify the environment variable CDF_LEAPSECONDTABLE and update the CDF leap second table if a new version is found.
;        
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-03-11 09:25:23 -0700 (Mon, 11 Mar 2019) $
;$LastChangedRevision: 26778 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/TT2000/cdf_leap_second_init.pro $
;-
pro cdf_leap_second_init,reset=reset,no_download=no_download,no_update=no_update,no_clobber=no_clobber,force_download=force_download,local_data_dir=local_data_dir

  compile_opt idl2,hidden

  ; handle errors
  catch, errors 
  if errors ne 0 then begin
    dprint, dlevel=1, 'Error in cdf_leap_second_init: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

  defsysv,'!CDF_LEAP_SECONDS',exists=exists
  
  if ~keyword_set(exists) then begin
    tmp_struct=file_retrieve(/structure_format)
    str_element,tmp_struct,'preserve_tt2000',0,/add ;if set, leap seconds will be left in, as will the 32.184 second skew between TAI & TT
    defsysv,'!CDF_LEAP_SECONDS',tmp_struct
  endif
  
  if keyword_set(reset) then !cdf_leap_seconds.init=0

  if !cdf_leap_seconds.init ne 0 then return

  tmp_struct = file_retrieve(/structure_format)    ; force setting of all elements to default values.
  str_element,tmp_struct,'preserve_tt2000',0,/add  ;if set, leap seconds will be left in, as will the 32.184 second skew between TAI & TT

  !cdf_leap_seconds=tmp_struct

  ftest = tt2000_read_config()
  If(size(ftest, /type) Eq 8) Then Begin
    !cdf_leap_seconds.local_data_dir = ftest.local_data_dir
    !cdf_leap_seconds.remote_data_dir = ftest.remote_data_dir
    !cdf_leap_seconds.no_download = ftest.no_download
    !cdf_leap_seconds.no_update = ftest.no_update
    !cdf_leap_seconds.downloadonly = ftest.downloadonly
    !cdf_leap_seconds.verbose = ftest.verbose
    !cdf_leap_seconds.preserve_tt2000=!cdf_leap_seconds.preserve_tt2000
  Endif
  
  cdf_lib_info,version=v,subincrement=si,release=r,increment=i,copyright=c
  cdf_version = string(format="(i0,'.',i0,'.',i0,a)",v,r,i,si)

  cdf_version_min = '3.4.0'
 
  if cdf_version lt cdf_version_min then begin
     print,'Warning: Your version of the CDF library ('+cdf_version+') is unable to read TT2000 times.'
     print,'Please go to the following url to find how to update your system:'
     print,'https://cdf.gsfc.nasa.gov/html/sw_and_docs.html'
  endif   

  if ~keyword_set(exists) or keyword_set(reset) then begin
    !cdf_leap_seconds=tmp_struct
    ;SPDF maintains the master version of the leap second table here
    ;When a leap second occurs the table CDFLeapSeconds.txt, which is stored at this location will be updated
    !cdf_leap_seconds.remote_data_dir = 'https://cdf.gsfc.nasa.gov/html/'
    
    ;where the leap second table will be stored
    !cdf_leap_seconds.local_data_dir = root_data_dir() + 'misc/'
  endif
   
  if keyword_set(local_data_dir) then begin
    !cdf_leap_seconds.local_data_dir = spd_addslash(local_data_dir)
  endif
  
  if keyword_set(no_download) then begin
    !cdf_leap_seconds.no_download=1
  endif

  if keyword_set(no_update) then begin
    !cdf_leap_seconds.no_update=1
  endif

  if keyword_set(no_clobber) then begin
    !cdf_leap_seconds.no_clobber=1
  endif

  if keyword_set(force_download) then begin
    !cdf_leap_seconds.force_download=1
  endif
  
  ;make sure that the NASA CDF library knows where to find the leapsecond table
  SETENV,'CDF_LEAPSECONDSTABLE='+!cdf_leap_seconds.local_data_dir+'CDFLeapSeconds.txt'
  
  ;download the leapsecond table
  ;leapsecond_table = file_retrieve('CDFLeapSeconds.txt',_extra=!cdf_leap_seconds)
  leapsecond_table = spd_download(remote_file='CDFLeapSeconds.txt', remote_path=!cdf_leap_seconds.remote_data_dir, $
    local_path = !cdf_leap_seconds.local_data_dir, ssl_verify_peer=0, ssl_verify_host=0, $
    no_download=!cdf_leap_seconds.no_download, no_update=!cdf_leap_seconds.no_update, $
    force_download=!cdf_leap_seconds.force_download, no_clobber=!cdf_leap_seconds.no_clobber)
  
  ;set init state
  !cdf_leap_seconds.init=1
  
end