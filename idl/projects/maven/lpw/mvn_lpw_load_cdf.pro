;+
;
;Program written by Chris Fowler on May 23rd 2014 as a wrapper for loading cdf files using mvn-lpw-load. Most users should use the routine mvn_lpw_cdf_read.pro to load LPW data. This routine
;cannot be used as a stand alone routine - it is called upon by mvn_lpw_load.pro.
;
; INPUTS:
; - cdf_files: a string or string array of full directory cdf files to load.
; 
; OUTPUTS:
; - Loads the corresponding tplot variables into IDL memory.
;  
; KEYWORDS:
; - NONE
;  
; NOTE: tplot is required to run this routine.
;       only one file directory can be specified - all cdf files to be loaded must be within the same folder and directory.
;
; Version 1.0
; 
; EXAMPLE: 
; mvn_lpw_cdf_load, ['/Path/to/CDF/file.cdf']
; 
; EDITS:
;
;;140718 clean up for check out L. Andersson
;-


pro mvn_lpw_load_cdf, cdf_files

;cdf_files has already been checked to make sure it's a string array:

sl = path_sep()

nele = n_elements(cdf_files) ;number of files.
varlist = strarr(nele)  ;store variable names
dir_list = strarr(nele)  ;store dirs

;Separate directory and filenames:
for aa = 0, nele-1 do begin
    slen = strlen(cdf_files[aa])
    fileind = strpos(cdf_files[aa], sl, /reverse_search)
    filename = strmid(cdf_files[aa], fileind+1, slen-fileind)  ;extract the filename
    dir = strmid(cdf_files[aa], 0, fileind+1)  ;get dir, should be the same for all files
    varlist[aa] = filename
    dir_list[aa] = dir
endfor  ;over aa 


print, "Loading ", nele, " tplot variables into IDL memory..."

mvn_lpw_cdf_read, varlist=varlist, dir=dir_list


end