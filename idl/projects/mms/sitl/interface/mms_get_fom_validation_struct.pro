; Routine to fetch latest MMS SITL FOM Validation Parameters
; 

; PROCEDURE: mms_get_fom_validation_struct
;
; PURPOSE: Load the FOM validation structure for EVA from the SDC.
;
; INPUT:
;   validation_file  - REQUIRED. (String) Name of validation file to be loaded.
;
;   pw_flag          - REQUIRED. (Integer) 0 if successful download of file,
;                      1 if failure.
;
;   pw_message       - REQUIRED. (String) Error message if failure.

; MODIFICATION HISTORY:
;
;-

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2015-05-08 11:42:31 -0700 (Fri, 08 May 2015) $
;  $LastChangedRevision: 17527 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/interface/mms_get_fom_validation_struct.pro $


pro mms_get_fom_validation_struct, validation_file, pw_flag, pw_message
  
  pw_flag = 0
  pw_message = 'ERROR: Unable to access the FOM validation parameters from the SDC.
  
  
  temp_dir = !MMS.LOCAL_DATA_DIR
  spawnstring = 'echo ' + temp_dir
  spawn, spawnstring, data_dir
  
  dir_path = filepath('',root_dir=data_dir, $
    subdirectory=['sitl', 'validation'])
  
  file_mkdir, dir_path
    
  status=get_mms_selections_file('fom_validation',local_dir=dir_path)
  
  if status eq 0 then begin
    validation_file = dir_path + 'fom_validation.sav'
  endif else begin
    pw_flag = 1
    validation_file = ''
  endelse




end