;+
;PROCEDURE: TDOTP
;Purpose:
;  Vectorized routine to calculate the dot product of two tplot
;  variables containing arrays of vectors and storing the results
;  in a tplot variable
;
;Arguments: 
; v1: The name of the tplot variable storing the first vector in the dot product
; v2: The name of the tplot variable storing the second vector in the
; dot product
; 
; newname(optional): the name of the output tplot variable
;
; error(optional): named variable in which to return the error state
; of the computation.  1 = success 0 = failure
;
;NOTES: 
;---> its not really clear how the dlimits should be set in the
;output from this function...at the moment the output variable just
;inherits from v1
;---> Time data from v1 will also be inherited for the output variable
;
;---> The dimensions of v1 and v2 must match or an error will be thrown
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2009-06-18 17:17:02 -0700 (Thu, 18 Jun 2009) $
; $LastChangedRevision: 6272 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/tdotp.pro $
;-
;

pro tdotp,v1,v2, newname = newname,error=error

if(keyword_set(error)) then error = 0

;input checks
if(not keyword_set(v1)) then begin 

  dprint, 'tdotp: argument v1 must be set'

  return

endif

if(tnames(v1) eq '') then begin 

  dprint, 'tdotp: argument v1 must be set'

  return

endif

if(not keyword_set(v2)) then begin 

  dprint, 'tdotp: argument v2 must be set'

  return

endif

if(tnames(v2) eq '') then begin 

  dprint, 'tdotp: argument v2 must be set'

  return

endif

if not keyword_set(newname) then newname = v1+'_dot_'+v2

get_data, v1, data = v1_d, dlimits = v1_dl

get_data, v2, data = v2_d, dlimits = v2_dl

v1_s = size(v1_d.y,/dimension)

v2_s = size(v2_d.y,/dimension)

;make sure the number of dimensions in input arrays is correct
if(n_elements(v1_s) ne 2 || n_elements(v2_s) ne 2) then begin

  dprint, 'tcrossp: V1 and V2 may contain only 2-d data arrays'
 
  return
endif

;make sure the dimensions match
if(not array_equal(v1_s,v2_s)) then begin 

  dprint, 'tdotp: Dimensions of v1 must match dimensions of v2'

  return

endif

if is_struct(v1_d) && is_struct(v2_d) && ~array_equal(v1_d.x,v2_d.x) then begin
  dprint,'WARNING: time arrays do not match'
endif

;the calculation

out_d = total(v1_d.y * v2_d.y, 2)

str_element,v1_d,'v',success=s

if s then begin

   out = {x:v1_d.x, y:out_d, v:v1_d.v}

endif else begin

   out = {x:v1_d.x, y:out_d}

endelse

store_data, newname, data = out, dlimits = v1_dl

error = 1

return

end
