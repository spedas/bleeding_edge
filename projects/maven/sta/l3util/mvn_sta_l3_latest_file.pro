;+
;Input list of either STATIC L3 density or temperature filenames. This routine will output the latest version. The filename
;format is hard coded here, so any changes to file name must be updated here. 
;
;INPUTS:
;filesin: string array: the filenames found by pfp-fileretrieve for a specific date, containing the version numbers.
;
;
;KEYWORDS:
; Set /denf (density-file) if the files entered are density files.
; Set /tempf (temperature-file) if the files entered are temperature files.
;   NOTE: only one can be set - the routine will bail if both are set.
;
;OUTPUTS:
;If successful, routine returns the full path and file name of the file that has the largest version number (success=1). If success=0,
;return returns 'na'.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/L3/mvn_sta_l3_latest_file.pro
;-
;

function mvn_sta_l3_latest_file, filesin, denf=denf, tempf=tempf, success=success

success=0

if keyword_set(denf) then denf = 1 else denf = 0
if keyword_set(tempf) then tempf = 1 else tempf = 0

if denf eq 1 and tempf eq 1 then return, 'na'

;Two file formats to pick from:
;mvn_sta_l3_den_'+dateTMP1+'_v??.tplot'
;mvn_sta_l3_temp_'+dateTMP1+'_v??.tplot'


if denf eq 1 then begin
    files1 = file_basename(filesin)
    vnums1 = strmid(files1, 25, 2)  ;just version numbers
    vnums2 = float(vnums1) ;convert string to float
    maxv = max(vnums2, imax, /nan)
    fileout = filesin[imax] ;send out the file with highest V number
    success=1
endif

if tempf eq 1 then begin
  files1 = file_basename(filesin)
  vnums1 = strmid(files1, 26, 2)  ;just version numbers
  vnums2 = float(vnums1) ;convert string to float
  maxv = max(vnums2, imax, /nan)
  fileout = filesin[imax] ;send out the file with highest V number
  success=1
endif

return, fileout

end


