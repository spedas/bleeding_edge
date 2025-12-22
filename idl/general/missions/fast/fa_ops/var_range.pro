;+
; NAME: VAR_RANGE
;
; PURPOSE: To obtain the max and min values of an array, ignoring
;          NaN's. Useful for passing to [XYZ]RANGE keywords. 
;
; CALLING SEQUENCE: yrange = var_range(y)
; 
; INPUTS: Y - the array whose range is sought.  
;
; OUTPUTS: YRANGE - a two element array of the same type as Y. 
;
; RESTRICTIONS: If Y is of an improper type, then a message is
;               displayed and NaN's are returned. The improper types
;               are UNDEFINED, COMPLEX, DOUBLE COMPLEX, STRUCTURE, and
;               STRING. 
;
; EXAMPLE: plot,x,y,xrange=var_range(x),yrange=var_range(y). 
;
; MODIFICATION HISTORY: Written summer 1996 by Bill Peria, UCB/SSL. 
;
;-
;	@(#)var_range.pro	1.4	
function var_range,x

nan = !values.f_nan

bad_types=['undefined','complex','double ' + $
           'complex','structure','string']
type = idl_type(x) 

if type eq 'double' then nan = !values.d_nan

if (where(type eq bad_types))(0) ge 0 then begin
    message,'improper type...',/continue
    return,[nan,nan]
endif

check = where(finite(x),nc)
if nc gt 0 then begin
    return,[min(x(check)),max(x(check))]
endif else begin
    return,[nan,nan]
endelse
    
end
