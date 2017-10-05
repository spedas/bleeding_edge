pro mvn_lpw_cdf_write, varlist=varlist, dir=dir, cdf_filename=cdf_filename

;+
;pro mvn_lpw_cdf_write, varlist, dir=dir
;
;Program written by Chris Fowler on Oct 15th 2013 to create a CDF file from one tplot variable.
;The required tplot variables must be read into IDL (using for example the r_header software) before 
;running this routine. 
;
;NOTE: caps are important in tplot names and must be included when present!
;
; INPUTS:
; - varlist is a string, or string array, from tplot_names, of tplot variables which have been loaded into IDL memory. 
; - dir is a string and is the base directory where the CDF files will be saved. The individual file names
;   are written within the routine and are the tplot variable names. 
; - cdf_filename is an optional string. If set, the CDF filename will have the name 'cdf_filename'. If not set, the saved cdf file will
;   be named using the tplot variable name only. The extension '.cdf' does not need to be included - it will be added automatically (the routine
;   will still work even if it is included).
;   
; OUTPUTS:
; - One CDF file per input tplot variable specified in varlist, containing the corresponding data, limit and dlimit information
;   for each tplot variable. Save diretory is either the default or can be user specified in the keyword dir. 
;   
; KEYWORDS:
; - See INPUTS.
;   
; EXAMPLES:
; - mvn_lpw_cdf_write, varlist='mvn_lpw_pas_V1', dir='/Users/MAVEN_example/' => produces the file /Users/MAVEN_example/mvn_lpw_pas_V1.cdf
; 
; - mvn_lpw_cdf_write, varlist=['mvn_lpw_pas_V1', 'mvn_lpw_pas_V2'], dir='/Users/MAVEN_example/'  => produces the files 
;   /Users/MAVEN_example/mvn_lpw_pas_V1.cdf and /Users/MAVEN_example/mvn_lpw_pas_V1.cdf.
;   
; - mvn_lpw_cdf_write, dir='/Users/MAVEN_example/', varlist='mvn_lpw_euv', cdf_filename='<yr><month><day><time>' => produces the file:
;   /Users/MAVEN_example/mvn_lpw_euv_<yr><month><day><time>.cdf
; 
;   Version 1.0
; 
; UPDATES:
; - Through till Jan 7th 2014.
; - May 1, 2014, CF: removed ability for varlist to accept numbers, must enter strings now. Added mvn_lpw_cdf_check_vars to ensure there are
;   no blank '' fields in dlimit or limit, which causes mvn_lpw_cdf_save_vars to crash.
; ;140718 clean up for check out L. Andersson
;-
sl = path_sep() 

;Check to see if varlist is a string, or string array:
IF keyword_set(varlist) THEN BEGIN
    IF (size(varlist, /type) NE 7.) THEN BEGIN  ;2 = integer, 4 = float, 7 = string
        print, "Warning: varlist must be a string or string array of tplot variables to store."
        return 
    ENDIF
ENDIF ELSE BEGIN
      print, "#### Warning ####: varlist not set. Enter a string, or string array, of tplot variables in IDL memory to save."
      return
ENDELSE

;Check dir is set:
IF keyword_set(dir) THEN BEGIN
    IF size(dir, /type) NE 7 THEN BEGIN
        print, "#### Warning ####: Directory must be a string; dir='"+sl+"Path"+sl+"to"+sl+"save"+sl+"'."
        return
    ENDIF 
       ;Make sure last symbol is / so that files go into that folder:
       slen = strlen(dir)  ;number of characters in the CDF directory
       extract = strmid(dir, slen-1,1)  ;extract the last character
       IF extract NE sl THEN dir = dir+sl  ;add / to end so new folder is not created.       
    fbase = dir  ;rename 
ENDIF ELSE BEGIN
    print, "#### WARNING ####: dir not set. Must be a string: '"+sl+"Path"+sl+"to"+sl+"save"+sl+"'."
ENDELSE


;Check cdf_filename is a string if set:
IF keyword_set(cdf_filename) THEN BEGIN
    IF size(cdf_filename, /type) NE 7. THEN BEGIN
        print, "#### Warning ####: cdf_filename must be a string."
        return
    ENDIF
ENDIF

;Must do this one cdf file at a time:
nele = n_elements(varlist)
IF nele EQ 1 THEN BEGIN
      var = varlist
      varlist=[var]  ;make a one element array if we only have one string entered.
ENDIF

names=tnames()  ;names is a string array containing all tplot names in IDL memory.
IF n_elements(names) EQ 0. THEN BEGIN
      print, "Warning: No tplot variables saved in IDL memory."
      return
ENDIF

file_saved = fltarr(nele) ;array to check all files are saved
for ii = 0, nele-1 do begin

    ;Check that the dlimit or limit fields of each tplot variable do not contain empty strings ' ' as this will cause cdf_save_vars to crash:
    mvn_lpw_cdf_check_vars, varlist[ii]

    fname = varlist[ii]+'.cdf'  ;file name - needs to meet proper format
    tplotname = file_basename(fname, '.cdf')  ;save the tplot variable name, and remove ".cdf" from it.
    
    sttr = mvn_lpw_cdf_dummy_struct(varlist[ii])  ;this routine is an SSL one
    
    ;fill filename attributes:
    ;Replace fname with the correct naming system if cdf_filename is set:
    IF keyword_set(cdf_filename) THEN BEGIN
        fname=cdf_filename
    ENDIF
  
    sttr.filename = fname
    fname0 = file_basename(fbase+fname, '.cdf')  ;takes just the filename, removes directory and '.cdf'

    ;save the file
    dummy = mvn_lpw_cdf_save_vars(sttr, fbase+fname)  ;An SSL routine which creates the CDF file.

    
    ;Check the '.cdf' extension is present, add if not:
    rlen = strlen(fbase+fname)
    endr = strmid(fbase+fname, rlen-4,4)
    if endr ne '.cdf' then fname = fname+'.cdf'
 
    r = file_test(fbase+fname) 
    
    IF r EQ 1 THEN BEGIN
        print, "File saved:", fbase+fname 
        file_saved[ii] = 1.
    ENDIF ELSE print, "SAVE UNSUCCESSFUL - check previous error messages: ", fbase+fname  ;leave file_saved[ii] as 0.
    
endfor  ;over ii

;Check save files exist before confirming successful save:
;tot_saved = total(file_saved, /nan)  ;total number of files saved
;print, "#####################################"
;print, uint(tot_saved), " out of ", nele, " file(s) saved."
;print, "#####################################"



;stop
end