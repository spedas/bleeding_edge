;+
;NAME:
; thm_sst_read_calibration_params
;PURPOSE:
;  This routine reads calibration parameters from a file.
;
;Inputs:
;  thx:  probe identifier string (e.g. 'tha','thb'...)
;  species: 'e' or 'i', to indicate ion or electron
;  dtype: distribution type 'f','b','r'
;
;Returns:
;  The parameter struct for the calibration file
;    
;NOTES:
;  #1 Reading and applying the calibration parameters is done separately, because reading later when 
;     they are applied leads to duplicated parameter reads. And because there is not enough information
;     to apply parameters at load time.
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-27 11:26:29 -0700 (Mon, 27 Apr 2015) $
;$LastChangedRevision: 17433 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_read_calib_params.pro $
;-


function thm_sst_read_calib_params,thx,species,dtype

  ;full distribution parameters used for all data types atm
  file = spd_download(remote_file=strlowcase(thx)+'/l1/sst/0000/'+strlowcase(thx)+'_ps'+strlowcase(species)+'f_calib_params_v02.txt',_extra=!themis)
 
  ;testing new set of parameters
  ;cal_file_root = '~/IDLWorkspace/themis/spacecraft/particles/SST/SST_cal_workdir/cal_files/'
  ;file = cal_file_root+strlowcase(thx)+'_ps'+strlowcase(species)+'f_calib_params_v02.txt'
;  
  dprint,'Reading cal file:', file,dlevel=2
  param_struct = read_asc(file)
  
  if ~is_struct(param_struct) then begin
    dprint,'Error reading calibration file: ' + file,dlevel=0
    return,0
  endif
  
  return,param_struct
end