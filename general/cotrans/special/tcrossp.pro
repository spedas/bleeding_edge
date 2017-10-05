;+
;PROCEDURE: TCROSSP
;Purpose:
;  Vectorized routine to calculate the cross product of two tplot
;  variables containing arrays of 3d vectors and storing the result
;  in a tplot variable.  Also, can perform vectorized cross product on
;  arrays.
;
;Arguments: 
; v1: The name of the tplot variable  or an Nx3 length array storing the first vector in the cross product
;    
; v2: The name of the tplot variable or an Nx3 length array storing the second vector in the
;     cross product 
; 
; newname(optional): the name of the output tplot variable
;
; error(optional): named variable in which to return error state of
; the computation.  1 = success 0 = failure
; 
; diff_tsize_ok = if set, allows the arrays to have a different number
;                 of elements in time, uses data_cut, which
;                 interpolates the data in v2 to the number of times
;                 given by v1
; Outputs(optional):
;   out:
;     Returns output in array format, if this argument is present, no tplot variable will be created
; 
; Example:
;   TPLOT;
;     tcrossp,'tvarname1','tvarname2'
;   Array:
;     tcrossp,array_2d_1,array_2d_2,out=array_output
; 
;NOTES: 
;---> its not really clear how the dlimits should be set in the
;output from this function...at the moment the output variable just
;inherits from v1
;---> Time data from v1 will also be inherited for the output variable, unless v1 is an array
;
;---> The dimensions of v1 and v2 must match or an error will be thrown
;
;---> Arguments can be mixed array/tplot type.(ie one array, one tplot variable)  If no argument is a tplot variable, no tplot variable can be created as an argument.
;
;---> Does not currently accept multiple inputs.  Can only cross two variables at a time.
; $LastChangedBy: pcruce $
; $LastChangedDate: 2012-07-20 11:39:26 -0700 (Fri, 20 Jul 2012) $
; $LastChangedRevision: 10727 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/tcrossp.pro $
;-
;

pro tcrossp, v1, v2, newname = newname, error = error, out = out_d, diff_tsize_ok = diff_tsize_ok


if arg_present(error) then error = 0

;input checks
if n_elements(v1) eq 0 then begin 

  dprint, 'tcrossp: argument v1 must be set'

  return

endif

if is_string(v1) || n_elements(v1) eq 1 then begin ;input v1 is a tplot variable

  v1_name = tnames(v1)
  
  if v1_name eq '' then begin 
  
    dprint, 'tcrossp: argument v1 tplot variable must be exist'
  
    return
  
  endif

  get_data, v1_name, data = v1_d, dlimits = v1_dl,limits=v1_l
  
  if ~is_struct(v1_d) || ~in_set(strlowcase(tag_names(v1_d)),'y') then begin
    dprint,v1_name + ' has bad data'
    return
  endif
  
  data1 = v1_d.y
  time1 = v1_d.x
endif else begin
  data1 = v1
  v1_name = 'var1'
endelse
  

if n_elements(v2) eq 0 then begin 

  dprint, 'tcrossp: argument v2 must be set'

  return

endif

if is_string(v2) || n_elements(v2) eq 1 then begin
  
  v2_name = tnames(v2)
  
  if v2_name eq '' then begin 

    dprint, 'tcrossp: argument v2 must be set'

    return

  endif

  get_data, v2_name, data = v2_d, dlimits = v2_dl,limits=v2_l
  
  if ~is_struct(v2_d) || ~in_set(strlowcase(tag_names(v2_d)),'y') then begin
    dprint,v2_name + ' has bad data'
    return
  endif
  
  data2 = v2_d.y
  time2 = v2_d.x
endif else begin
  v2_name = 'var2'
  data2 = v2
endelse

if ~keyword_set(newname) then newname = v1_name+'_cross_'+v2_name

v1_s = size(data1,/dimension)

v2_s = size(data2,/dimension)


;make sure the number of dimensions in input arrays is correct
if(n_elements(v1_s) ne 2 || n_elements(v2_s) ne 2) then begin

  dprint, 'tcrossp: V1 and V2 may contain only 2-d data arrays'
 
  return
endif

If(keyword_set(diff_tsize_ok)) Then Begin
  If(n_elements(time1) Eq 0 Or n_elements(time2) Eq 0) Then Begin
    dprint, 'Use of diff_tsize_ok keyword is only possible for input tplot variables'
    return
  Endif
  d2tmp = {x:time2, y:data2}
  data2 = data_cut(temporary(d2tmp), time1)
  v2_s = size(data2, /dimension)
  v2_d = {x:time1, y:data2}
Endif 

;make sure the dimensions match
if(not array_equal([v1_s[0],3],v2_s)) then begin 

  dprint, 'tcrossp: Dimensions of v2 incorrect'

  return

endif

if(not array_equal([v2_s[0],3],v1_s)) then begin

  dprint, 'tcrossp: Dimensions of v1 incorrect'

  return

endif

if is_struct(v1_d) && is_struct(v2_d) && ~array_equal(v1_d.x,v2_d.x) then begin
  dprint,'WARNING: time arrays do not match'
endif

;the calculation(delightfully symmetric)
x = data1[*,1] * data2[*,2] - data1[*,2] * data2[*,1]
y = data1[*,2] * data2[*,0] - data1[*,0] * data2[*,2]
z = data1[*,0] * data2[*,1] - data1[*,1] * data2[*,0]

;stick em together as a single array
out_d = [[x],[y],[z]] 

if ~arg_present(out_d) then begin

  if ~is_struct(v1_d) && ~is_struct(v2_d) then begin
    dprint, 'tcrossp: No tplot arguments are present, cannot construct output'
    return
  endif

  if is_struct(v1_d) then begin
    str_element,v1_d,'v',success=s
  
    if s then $
       out = {x:v1_d.x, y:out_d, v:v1_d.v} $
    else $
       out = {x:v1_d.x, y:out_d}
       
    dl = v1_dl
    l = v1_l
  endif else begin
    str_element,v2_d,'v',success=s
  
    if s then $
       out = {x:v2_d.x, y:out_d, v:v2_d.v} $
    else $
       out = {x:v2_d.x, y:out_d}
       
    dl = v2_dl
    l = v2_l
  
  endelse
 
  store_data, newname, data = out, dlimits = dl,limits=l
endif

error = 1

return

end
