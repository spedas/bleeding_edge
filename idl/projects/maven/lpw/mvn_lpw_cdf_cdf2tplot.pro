;+
;mvn_lpw_cdf_cdf2tplot, file, varnames=varnames, all=all
;
;Original file from SSL Berkeley, with original info below. Original file edited by Chris Fowler from Oct 2013 onwards for use
;with the MAVEN lpw software. Routine takes a single CDF file input and loads the data, limit and dlimit data into IDL memory as
;a tplot variable for plotting with the tplot software.
;
;Note: Capital letters are important for tplot variables and should be included in 'file'.
;      The varformat='*' needs to be included otherwise not all of the cdf variables are loaded.
;
;INPUTS:
; - file: the full string directory and filename of the CDF file to be loaded into IDL memory.
; 
;NOTE: I haven't used the other keywords, they're not needed for basic cdf file loading.
;
;OUTPUT:
; - a tplot variable in IDL memory containing the data, tplo limit and dlimit data for the specified CDF file. The tplot variable
;   will have the same name as that for the variable saved within the CDF file, NOT the file name.
;   
;EXAMPLE:
; mvn_lpw_cdf_cdf2tplot, '/Users/MAVEN_example/mvn_lpw_act_V1.cdf', varformat='*'  => produces a tplot variable with the name 'mvn_lpw_act_V1'
;
;EDITS:
; - Through till Jan 7 2014 (CF)
;
;###########
; Original routine notes:
; 
; Please note this routine is still in development
;CDF2TPLOT ,files,varnames=varnames,all=all
;
; record=record if only one record and not full cdf-file is requested
;
; $LastChangedBy: cfowler2 $
; $LastChangedDate: 2015-11-30 08:31:39 -0800 (Mon, 30 Nov 2015) $
; $LastChangedRevision: 19487 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/lpw/mvn_lpw_cdf_cdf2tplot.pro $
;##########
;
;Version 1.0
;;140718 clean up for check out L. Andersson
;151130: CMF: added cdf_filename keyword in sub routines to append cdf filename to dlimit.L0_datafile structure.
;-

pro mvn_lpw_cdf_cdf2tplot,file=file,prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix ,newname=newname $
   ,varformat=varformat ,varnames=varnames2 $
   ,all=all,verbose=verbose, get_support_data=get_support_data, convert_int1_to_int2=convert_int1_to_int2 $
   ,record=record, tplotnames=tplotnames

cdf_filename = file_basename(file)  ;take CDF file.

;Automatically use varformat='*' to load all variables:
IF varformat NE '*' THEN varformat = '*'

dprint,dlevel=4,verbose=verbose,'$Id: mvn_lpw_cdf_cdf2tplot.pro 19487 2015-11-30 16:31:39Z cfowler2 $'
vb = keyword_set(verbose) ? verbose : 0

; Load data from file(s)
dprint,dlevel=5,verbose=verbose,'Starting CDF file load'

if not keyword_set(varformat) then var_type = 'data'
if keyword_set(get_support_data) then var_type = ['data','support_data']
cdfi = mvn_lpw_cdf_load_vars(file,varformat=varformat,var_type=var_type,/spdf_depend, $
     varnames=varnames2,verbose=verbose,record=record, convert_int1_to_int2=convert_int1_to_int2)

dprint,dlevel=5,verbose=verbose,'Starting load into tplot'
;  Insert into tplot format
tn = mvn_lpw_cdf_info_to_tplot(cdfi,varnames2,all=all,prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix,newname=newname, $  ;bpif keyword_set(all) eq 0
       verbose=verbose,  tplotnames=tplotnames, get_support_data=get_support_data, cdf_filename=cdf_filename) ;added get_support_data, jmm, 2013-11-13

dprint,dlevel=5,verbose=verbose,'Starting Clean up' ;bpif keyword_set(all) eq 0
tplot_ptrs = ptr_extract(tnames(/dataquant))
unused_ptrs = ptr_extract(cdfi,except=tplot_ptrs)
ptr_free,unused_ptrs

;Check the variable was loaded into tplot memory:
names = tnames()  ;names is an array containing all tplot variable names, removed (s), 2013-11-13, jmm
nele_names = n_elements(names)
IF nele_names EQ 0. THEN BEGIN
    print, "#########################################################"
    print, "File load unsuccessful: no tplot variables in IDL memory."
    print, "Check file name and directory: ", file
    print, "#########################################################"
ENDIF

IF nele_names GT 0. THEN BEGIN
    ;str = file_basename(file, '.cdf')  ;remove directory and .cdf to give tplot variable name - only works if filename is same as tplot variable name
    str = tn  ;works regardless of what the filename is; tplot variable name taken from CDF file.
    r = strmatch(names, str)  ;does str occur in names array? 0 if not, 1 if yes. 
    w = where(r EQ 1, n_w)
    IF n_w gt 0 THEN BEGIN
        ;print, "###################################"
        print, "File loaded into tplot memory: ", file
        print, "Tplot name: ", tn
        ;print, "###################################"
    ENDIF ELSE BEGIN
        print, "######################################################"
        print, "FILE LOAD UNSUCCESSFUL: ", file, " not loaded into tplot memory"
        print, "Check file name and directory."
        print, "######################################################"
    ENDELSE
ENDIF

;stop
end



