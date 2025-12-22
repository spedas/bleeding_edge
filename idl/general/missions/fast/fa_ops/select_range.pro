;+
; NAME: SELECT_RANGE
;
; PURPOSE: to obtain the indices where an array's values lie in a
;          specified range. 
;
; CALLING SEQUENCE: indices = select_range(array, range_min,
;                                          range_max, n_in_range)
; 
; INPUTS: ARRAY - any type but structure, string, or complex. 
;         RANGE_MIN - the minimum value of the desired range. 
;         RANGE_MAX - the maximum value of the desired range. 
;
; OUTPUTS: INDICES - a longword array of the indices, if any are in
;          range, or -1L if not. 
;
; OPTIONAL OUTPUTS: N_IN_RANGE - the number of points found in the
;                   range. 
;
; EXAMPLE: comfortable = select_range(temperatures,60,70,ncomf)
;
; MODIFICATION HISTORY: written summer 1996 by Bill Peria UCB/SSL
;
;-
;	@(#)select_range.pro	1.5	
function select_range,xc,x0,x1,nrange

nrange = 0
pick = -1L
bad_types = ['string','structure','complex','double complex']
type = [idl_type(xc),idl_type(x0), idl_type(x1)]

for i=0,n_elements(type)-1l do begin
    if (where(type(i) eq bad_types))(0) ge 0 then begin
        message,'Improper input type!',/continue
        return,-1L
    endif 
endfor

if x0 gt x1 then begin
    message,'OOPS! min is greater than max!',/continue
    return,pick
endif

not_nan = where(xc eq xc,nnn)
if nnn eq 0 then begin
    message,'Input is all NaN''s',/continue
    return,pick
endif

nxc = n_elements(xc)
orig_indices = (lindgen(nxc))(not_nan)

pp = where((xc(not_nan) ge x0) and (xc(not_nan) le x1),npp)
if npp eq 0 then begin
    return,pick
endif
pick = orig_indices(pp)

if pick(0) ge 0 then nrange = n_elements(pick)

return,pick
end
