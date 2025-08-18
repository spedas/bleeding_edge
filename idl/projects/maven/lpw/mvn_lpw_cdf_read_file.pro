
;+
;Most users should not use this routine; you should instead use mvn_lpw_cdf_read.pro:
;
;   mvn_lpw_cdf_read.pro:  Retrieves CDF files based on input date in format 'yyyy-mm-dd'. Routine finds latest version and revision from available files and calls upon mvn_lpw_cdf_read.pro to load them. Keywords available, see routine. 
;   
;   mvn_lpw_cdf_read_file.pro (this file): Retrieves exact CDF files. User must give exact path and filename(s) to load. Primary use is calibration / file checking by LPW team. 
;
;
;Routine renamed to mvn_lpw_cdf_read_file. This routine is given exact file names to load. mvn_lpw_cdf_read is given a date. That routine will call on this routine once it has figured out automatically which files to load, based on the date.
;
;Program written by Chris Fowler on Jan 6th 2014 as a wrapper for all the IDL routines needed to load cdf files into tplot memory
;for the lpw instrument.
;
; INPUTS:
; - dir: a string or string array containing the directory of the cdf files to be loaded into tplot memory (see example).
;        dir can be one element if all cdf files lie in the same path, or it must be the same length as varlist if 
;        cdf files lie in different paths. In this latter case, each element of dir maps to each element of varlist.
; - varlist: a string, or string array, of cdf filenames to be loaded into tplot memory. ".cdf" 
;            must be included in the filename (see example).
; 
; OUTPUTS:
; - the tplot variables and corresponding limit and dlimit data are loaded into IDL tplot memory.
; 
; KEYWORDS:
; - See INPUTS. These are required.
; 
; NOTE: tplot is required to run this routine.
;
; EXAMPLE: to load the following two CDF files:
; /Path1/test_file1.cdf
; /Path2/test_file2.cdf
; 
; Run: If Path1 == Path2:     mvn_lpw_cdf_read_file, dir='/Path1/', varlist=['test_file1.cdf','test_file2.cdf']
;      If Path1 =/= Path2:    mvn_lpw_cdf_read_file, dir=['/Path1/', '/Path2/'],  varlist=['test_file1.cdf','test_file2.cdf']
; 
; EDITS:
; - Througn till Jan 7 2014 (CF).
; - June 23 2014 CF: modified dir input to be either the same length as varlist (for multiple paths) or jsut one entry (the same path for
;                    each cdf file)
; -140718 clean up for check out L. Andersson
; - 2015-01-09: CF: changed routine to mvn_lpw_cdf_read_file. This is given file names manually. mvn_lpw_cdf_read is given a date, and calls upon this routine.
; - 2015-08-04: CMF: edited comments, cleaned up preamble.
;
; Version 2.0
;-

pro mvn_lpw_cdf_read_file, dir=dir, varlist=varlist

name = 'mvn_lpw_cdf_read_file:"
sl = path_sep()

;Check dir is set and a string:
IF keyword_set(dir) THEN BEGIN
    IF size(dir, /type) NE 7 THEN BEGIN
        print, "#### Warning ####: file directory must be a string."
        return
    ENDIF
ENDIF ELSE BEGIN
    print, "#### Warning ####: file directory needs to be set: dir='"+sl+"Path"+sl+"to"+sl+"save"+sl+"'."
    return
ENDELSE

nd = n_elements(dir)
for aa = 0, nd-1 do begin
   ;Make sure last symbol is / so that files go from that folder:
   slen = strlen(dir[aa])  ;number of characters in the CDF directory
   extract = strmid(dir[aa], slen-1,1)  ;extract the last character
   IF extract NE sl THEN dir[aa] = dir[aa]+sl  ;add / to end so new folder is not created. 
endfor  ;over aa

;Check varlist is set and a string or string array:
IF keyword_set(varlist) THEN BEGIN
    nv = n_elements(varlist)  ;number of strings to load
    IF size(varlist, /type) NE 7 THEN BEGIN
        print, "#### Warning ####: varlist must be a string or string array containing the file names to be loaded into tplot."
        return
    ENDIF
ENDIF ELSE BEGIN
    print, "#### Warning ####: file name(s) not set: must be a string or string array.
    return
ENDELSE

;If we only have one string, turn it into a one element string array:
IF nv EQ 1 THEN BEGIN
    var = varlist  ;save file name
    varlist = [var]  ;one element string array
ENDIF

;If we have multiple files but only one dir specified, make copies of dir:
if nv gt 1 and nd eq 1 then dir = replicate(dir, nv)

;Load each cdf file separately:
FOR ii = 0, nv -1 DO BEGIN
    if file_search(dir[ii]+varlist[ii]) ne '' then mvn_lpw_cdf_cdf2tplot, file = dir[ii]+varlist[ii], varformat='*' else begin  ;varformat must equal '*' otherwise not all variables will be loaded
        print, "#### WARNING ####: ", name, " File ", dir[ii]+varlist[ii], " could not be found. File skipped."
    endelse
ENDFOR

mvn_lpw_cdf_read_extras  ;extract Ne, Te, Vsc to separate tplot variables, if these are being loaded.

;stop
end


