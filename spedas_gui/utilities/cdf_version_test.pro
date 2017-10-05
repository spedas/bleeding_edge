;+
; Procedure: 
;     cdf_version_test
; 
; Purpose:
;     Check that the patched version the CDF library (3.4+) is installed
;     
; Note: 
;     The crash due to an unpatched CDF library is usually due to a 
;     change in the number of arguments of the function CDF_EPOCH_COMPARE. 
;     The change was introduced in version 3.4 of the CDF library:
;        http://cdaweb.sci.gsfc.nasa.gov/pub/software/cdf/dist/cdf35_0_2/idl/CDF_EPOCH_COMPARE.txt
; 
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-10-31 09:11:43 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16091 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/cdf_version_test.pro $
;-
function cdf_version_test
    valid_version = [3, 4] ; 3.4+

    ; get the loaded CDF DLM
    help, /dlm, 'cdf', output = out
    
    ; find the CDF DLM
    cdf_filter = strfilter(out, '*CDF*',/index)
    
    ; there should be a CDF DLM installed, but just in case there isn't:
    if cdf_filter[0] eq -1 then begin
        message, /continue, 'The required CDF library was not found. To install it, see the page: http://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html'
        return, 0
    endif 
    
    installed_version = stregex(out[cdf_filter+1], '([0-9.]+[0-9]?), Build', /extract)

    version_num = (strsplit(installed_version[0], ', ', /extract))[0]
    version_num_pieces = strsplit(version_num, '.', /extract)
    
    ; check the major/minor version number
    if version_num_pieces[0] lt valid_version[0] || $ 
    (version_num_pieces[0] eq valid_version[0] && version_num_pieces[1] lt valid_version[1]) then begin 
        message, /continue, 'The CDF library is out-of-date. To install the required patch, see: http://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html'
        return, 0
    endif
    
    return, 1
    
end
 