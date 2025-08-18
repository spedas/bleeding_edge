;+
;  poes_CDF2TPLOT ,files,varformat=varformat
;
;  Note: This file is a fork of the more general cdf2tplot, and is specific to POES CDF files. 
;        The fork was made so that we can rename the 'time' variable before passing 
;        the CDF structure to cdf_info_to_tplot
;
;Keywords:
; 
; VARFORMAT = PATTERN  ; PATTERN should be a string (wildcards accepted) that will match the CDF variable that should be made into tplot variables
; PREFIX = STRING      ; String that will be pre-pended to all tplot variable names. 
; SUFFIX = STRING      ; String appended to end of each tplot variable created.
; VARNAMES = named variable ; CDF variable names are returned in this variable
; /GET_SUPPORT_DATA    ; Often required to get support data if the CDF file does not have all the needed depend attributes
; 
; record=record if only one record and not full cdf-file is requested
;
;load_labels=load_labels ;copy labels from labl_ptr_1 in attributes into dlimits
;         resolve labels implemented as keyword to preserve backwards compatibility 
;
;Author: Davin Larson -  20th century
;  forked for POES data, Eric Grimes, 9/23/2014
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-09-23 14:56:22 -0700 (Tue, 23 Sep 2014) $
; $LastChangedRevision: 15845 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_cdf2tplot.pro $
;-

pro poes_cdf2tplot,files,files=files2,prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix ,newname=newname $
   ,varformat=varformat ,varnames=varnames2 $
   ,all=all,verbose=verbose, get_support_data=get_support_data, convert_int1_to_int2=convert_int1_to_int2 $
   ,record=record, tplotnames=tplotnames,load_labels=load_labels


dprint,dlevel=4,verbose=verbose,'$Id: poes_cdf2tplot.pro 15845 2014-09-23 21:56:22Z egrimes $'
vb = keyword_set(verbose) ? verbose : 0

if keyword_set(files2) then files=files2    ; added for backward compatibility  and to make it match the documentation

; Load data from file(s)
dprint,dlevel=4,verbose=verbose,'Starting CDF file load'

if not keyword_set(varformat) then var_type = 'data'
if keyword_set(get_support_data) then var_type = ['data','support_data']
cdfi = cdf_load_vars(files,varformat=varformat,var_type=var_type,/spdf_depend, $
     varnames=varnames2,verbose=verbose,record=record, convert_int1_to_int2=convert_int1_to_int2)

;;; kludge specific to POES CDF files
; need to rename the CDF_REAL4 variable 'time', so cdf_info_to_tplot doesn't use it
; as the time series variable. The time series should be the CDF_TIME_TT2000 variable, 'Epoch'
for j = 0, n_elements(cdfi.vars)-1 do if struct_value(cdfi.vars[j],'name') eq 'time' then cdfi.vars[j].name = 'NOTAREALTIME'
;;;

dprint,dlevel=4,verbose=verbose,'Starting load into tplot'
;  Insert into tplot format
cdf_info_to_tplot,cdfi,varnames2,all=all,prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix,newname=newname, $  ;bpif keyword_set(all) eq 0
       verbose=verbose,  tplotnames=tplotnames,load_labels=load_labels


dprint,dlevel=4,verbose=verbose,'Starting Clean up' ;bpif keyword_set(all) eq 0
tplot_ptrs = ptr_extract(tnames(/dataquant))
unused_ptrs = ptr_extract(cdfi,except=tplot_ptrs)
ptr_free,unused_ptrs

end



