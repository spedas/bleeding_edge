pro mvn_lpw_cal_read_stub,stub_arr,stub_file

;-----------------------
;Chris added this Sep 16th 2014, to remove hardcoded directory when looking for the cal file:
name = 'mvn_lpw_cal_read_stub'
folder = 'mvn_lpw_cal_files'  ;name of the sub folder containing luts
sl = path_sep()  ;'/' or '\' depending on linux or windows


;Check that we have an environment variable telling IDL where to get the luts:
if getenv('mvn_lpw_software') eq '' then begin
  print, name, ": #### WARNING ####: environment variable 'mvn_lpw_software' not set. LUT not found. No shadow or wake data used."
  print, "Use: setenv,'mvn_lpw_software=/path/to/software/on/your/machine/' to set this variable and locate requested LUTs."
  lut = !values.f_nan ;return nan
endif else fbase = getenv('mvn_lpw_software')
;-----------------------


filename='mvn_lpw_cal_stub_v01_r01.txt'    ; could be set to firn the newest 
dir0name = fbase+folder+sl+filename
;dir0name='/Users/andersson/Idl/2014_maven/scr_lpw/mvn_lpw_cal_files/mvn_lpw_cal_bias_r01_v01.txt'   ;old version, hard coded


;the header is 2 lines
; the text file is 4096 long and 3 columns

    OPENR, Unit, dir0name, /GET_LUN
 
   aa=' d' 
  READF, unit, aa
   READF, unit, aa
 
  stub_arr=dblarr(4096,3) 
  tmp=dblarr(3)
  for i=0,4096-1 do begin
    READF, unit, tmp
    stub_arr[i,*]=tmp
  endfor
free_lun,unit

stub_file=filename

end
