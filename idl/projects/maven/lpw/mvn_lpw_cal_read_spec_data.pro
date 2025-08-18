;pro  mvn_lpw_cal_read_spec_data,type,subcycle,hfgain,calib_file_spec,filename,background,f_low,f_high,amp_resp
;  
;This script outputs waves frequency bin centers and edges 
;amplitude response and backgrounds (active or passive)
;
;;INPUTS:
; 
;   type:           'LF', 'MF' or 'HF' frequency range
;   subcycle:       'PAS' or 'ACT'
;   hfgain:         0 for no gain, 1 for high gain
;   calib_file_spec (array passed from instrument constants that contains a list of text cal files)
;   
;
;;;OUTPUTS:
;   filename:       name of the text calibration file used
;   f_low:          array of low frequency bin edges
;   f_high:         array of high frequency bin edges
;   background      background depending on what subcyle and type was input
;   amp_resp        amplitude response 
;   
;EXAMPLE:

;;
;CREATED BY:   Tess McEnulty  December 2014
;FILE:         mvn_lpw_cal_read_spec_data.pro
;VERSION:      1.0
;LAST MODIFICATION:
; 2014-12-12 L. Andersson - modified to input the type, subcycle, and array of calibration files
; 2014-12-17 T. McEnulty - modified to check of on lpw_proc and if so, use specific path to master folder for cal file 
; 2015-02-10 CF: removed hard coding to find file; environment variable 'mvn_lpw_software' is now used.

pro  mvn_lpw_cal_read_spec_data,type,subcycle,hfgain,calib_file_spec,filename,background,f_low,f_high,amp_resp

  name = 'mvn_lpw_cal_read_spec_data'
  folder = 'mvn_lpw_cal_files'  ;name of the sub folder containing text files
  sl = path_sep()  ;'/' or '\' depending on linux or windows
  
  
  ;Check that we have an environment variable telling IDL where to get the files, and if it is on the lpw_proc computer:
  if getenv('mvn_lpw_software') eq '' then begin
    print, name, ": #### WARNING ####: environment variable 'mvn_lpw_software' not set. File  not found."
    print, "Use: setenv,'mvn_lpw_software=/path/to/software/on/your/machine/' to set this variable and locate requested files."
  if getenv('mvn_lpw_software') eq '/Users/lpwproc/maven_idl/scr_lpw/' then $
    fbase = '/Users/lpwproc/maven_idl/MVN_SVN/LDS_MAVEN_LPW/master/'
  endif else fbase = getenv('mvn_lpw_software')
  
  print, 'using the cal field saved in '+fbase
  
  ;-----------------------
  ;here get the right calibration file, for now only one file exists
  
  filename=calib_file_spec[0]
  
  ;--------------------------
  
  ;dir0name = fbase+folder+sl+filename ;;txt file has to be in the master folder
  dir0name = fbase+'mvn_lpw_cal_files'+sl+filename ;hard coded to work on production computer
  
  OPENR, Unit, dir0name, /GET_LUN
  
  aa=' d'
  READF, unit, aa
  READF, unit, aa
  
  data=dblarr(184,6)
  tmp=dblarr(6)
  for i=0,184-1 do begin
    READF, unit, tmp
    data[i,*]=tmp
  endfor
  free_lun,unit
  
  
  ;need 6 more
  act_background=transpose(data(0:127,0))  * 8.1380211e-05  ;;includes correction for constant
  pas_background=transpose(data(0:127,1))  * 8.1380211e-05
  
  ;need 4 total
  amp_resp=transpose(data(0:127,2))
  
  f_low_hf=transpose(data(0:127,3))
  f_high_hf=transpose(data(0:127,4))
  center_freq_hf=transpose(data(0:127,5))
  
  f_low_lf=transpose(data(128:183,0))
  f_high_lf=transpose(data(128:183,1))
  center_freq_lf=transpose(data(128:183,2))
  
  f_low_mf=transpose(data(128:183,3))
  f_high_mf=transpose(data(128:183,4))
  center_freq_mf=transpose(data(128:183,5))
 
 
 ;------------- Use type,subcycle,hfgain -----------
 
 
amp_resp=  amp_resp
zzero=fltarr(n_elements(amp_resp)) 
 
 
If type EQ 'lf'  then begin 
    f_low=   f_low_lf
    f_high=  f_high_lf 
    IF subcycle EQ 'PAS' then background=zzero ELSE background=zzero   
endif
If type EQ 'mf'  then begin 
    f_low=   f_low_mf
    f_high=  f_high_mf 
    IF subcycle EQ 'PAS' then background=zzero ELSE background=zzero   
endif
 If type EQ 'hf'  then begin 
    f_low=   f_low_hf
    f_high=  f_high_hf 
   IF hfgain EQ 0 then $ 
         IF subcycle EQ 'PAS' then background=pas_background ELSE $
                                   background=act_background 
   IF hfgain EQ 1 then $ 
         IF subcycle EQ 'PAS' then background=zzero ELSE background=zzero

endif



end ;of routine
 
 
 
