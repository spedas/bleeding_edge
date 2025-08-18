;+
;mms_cdf2tplot ,files,varformat=varformat
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
; Forked for MMS, 10/22/2015, egrimes@igpp
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-01-05 17:08:07 -0800 (Thu, 05 Jan 2017) $
; $LastChangedRevision: 22512 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cdf/mms_cdf2tplot.pro $
;-

pro mms_cdf2tplot,files,files=files2,prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix ,newname=newname $
   ,varformat=varformat ,varnames=varnames2 $
   ,all=all,verbose=verbose, get_support_data=get_support_data, convert_int1_to_int2=convert_int1_to_int2 $
   ,record=record, tplotnames=tplotnames,load_labels=load_labels, loaded_versions=loaded_versions $
   ,min_version=min_version,version=version,latest_version=latest_version $
   ,number_records=number_records, center_measurement=center_measurement, major_version=major_version


dprint,dlevel=4,verbose=verbose,'$Id: mms_cdf2tplot.pro 22512 2017-01-06 01:08:07Z egrimes $'
vb = keyword_set(verbose) ? verbose : 0

if keyword_set(files2) then files=files2    ; added for backward compatibility  and to make it match the documentation

; Load data from file(s)
dprint,dlevel=4,verbose=verbose,'Starting CDF file load'

if not keyword_set(varformat) then var_type = 'data'
if keyword_set(get_support_data) then var_type = ['data','support_data']

;;;; the following is a filter for CDF file versions (specific to MMS)
files = unh_mms_file_filter(files, min_version=min_version, version=version, $
  latest_version=latest_version, loaded_versions = loaded_versions, major_version=major_version, /no_time)

cdfi = mms_cdf_load_vars(files,varformat=varformat,var_type=var_type,/spdf_depend, $
     varnames=varnames2,verbose=verbose,record=record, convert_int1_to_int2=convert_int1_to_int2, $
     number_records=number_records)

dprint,dlevel=4,verbose=verbose,'Starting load into tplot'
;  Insert into tplot format
mms_cdf_info_to_tplot,cdfi,varnames2,all=all,prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix,newname=newname, $  ;bpif keyword_set(all) eq 0
       verbose=verbose,  tplotnames=tplotnames,load_labels=load_labels, center_measurement=center_measurement

dprint,dlevel=4,verbose=verbose,'Starting Clean up' ;bpif keyword_set(all) eq 0
tplot_ptrs = ptr_extract(tnames(/dataquant))
unused_ptrs = ptr_extract(cdfi,except=tplot_ptrs)
ptr_free,unused_ptrs

end



