;+
; FUNCTION: FF_INTERP, time1, time2, data2, delt_t=delt_t, spline=spline, 
;                      nearest=nearest, ptr=ptr
;
; PURPOSE: A utility routine which that interpolates through notched 
;          dc fields data. Called by ff_notch. User hostile.
;
; INPUT: 
;       time1 -       REQUIRED. Double array of time to interpolate to.
;       time2 -       REQUIRED. Double array of time must match data2.
;       data2 -       REQUIRED. Data will be expanded or reduced to meet time1
;                     may be double, float, long, int, or byte array
; any of inputs time1, time2 or data2 may be pointers.
;
;  NOTE: the values of TIME2 must all be finite, i.e. no NaN's!!! 
;
; KEYWORDS: 
;       delt_t -      Largest delta t interpret across. DEFAULT = 1.0d
;       spline -      Use cubic spline interpolation instead of linear.
;       nearest -     Choose nearest point in time2 for each point in time1.
;	ptr -	      Return a pointer to an array of same type as data2.
;                     DEFAULT = ptr is time1 is ptr, otherwise not prt.
;
; CALLING: data1 = ff_interp(time1, time2, data2)
;
; OUTPUT: data1 is superset of data2, interpolated from time2 to time1.
;         If data2 is a pointer, then data1 will be a pointer.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: KRB 97-06-17. add cubic spline interpolation.
; 			REE 97-11-17. Change ptr call.
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_interp.pro	1.12     05/19/99

function ff_interp, time1, time2, data2, delt_t=delt_t, spline=spline, $
                    nearest=nearest, ptr=ptr, quiet=quiet

; Do some checking just in case. and Determine the length of the arrays.
; allocate temporary pointer heap variables for all static inputs
; to be passed to the call external:  these will be freed later.


IF ptr_valid(time1(0)) THEN BEGIN
    time1_type = (data_type(*time1))
    npts1 = long( n_elements(*time1) )
    t1ptr = time1
    t1_is_ptr = 1
    ret_ptr = 1
    nt1 = n_elements(*time1)
ENDIF ELSE BEGIN
    time1_type = (data_type(time1))
    npts1 = long( n_elements(time1) )
    t1_is_ptr = 0
    ret_ptr = 0
    nt1 = n_elements(time1)
ENDELSE
IF time1_type ne 5 then BEGIN
    print, 'FF_INTERP: STOPPED! Time1 must be double array.'
    return, junk
ENDIF
if nt1 eq 0 then junk = !values.f_nan else junk = replicate(!values.f_nan, nt1)

IF ptr_valid(time2(0)) THEN BEGIN
    time2_type = (data_type(*time2))
    npts2 = long( n_elements(*time2) )
    t2ptr = time2
    t2_is_ptr = 1
END ELSE BEGIN
    time2_type = (data_type(time2))
    npts2 = long( n_elements(time2) )
    t2_is_ptr = 0
ENDELSE
IF time2_type ne 5 then BEGIN
    print, 'FF_INTERP: STOPPED! Time2 must be double array.'
    return, junk
ENDIF

if ptr_valid(data2(0)) THEN BEGIN
    data2_type = data_type(*data2) 
    IF data2_type gt 5 or data2_type lt 1 then BEGIN
      print, 'FF_INTERP: STOPPED! '
      print, 'Data2 must be byte, int, long, float, or double array.'
      return, junk
    ENDIF
    n_data2 = n_elements(*data2)
    if data2_type eq 5 then d2ptr = data2 else $
	                    d2ptr = ptr_new(double(*data2))
end else begin
    data2_type = data_type(data2) 
    IF data2_type gt 5 or data2_type lt 1 then BEGIN
      print, 'FF_INTERP: STOPPED! '
      print, 'Data2 must be byte, int, long, float, or double array.'
      return, junk
    ENDIF
    n_data2 = n_elements(data2)
    d2ptr = ptr_new(double(data2))
end


if keyword_set(ptr) then ret_ptr = 1

; Set the needed variables in the call.
result_ptr = ptr_new(dblarr(npts1))
(*result_ptr)(*) = !values.d_nan

if keyword_set(nearest) then BEGIN
	if keyword_set(spline) then BEGIN
	    print, 'FF_INTERP: STOPPED! '
	    print, 'Make up your mind! Do you want /nearest or /spline?'
	    return, junk
	ENDIF
	if not keyword_set(delt_t) then delt_t = double(1000.)
	svy = 0l
	ratio = 1.0d
	interp = 0l
ENDIF else BEGIN
if not keyword_set(spline) then BEGIN
	if not keyword_set(delt_t) then delt_t = double(1000.)
	svy = 0l
	ratio = 1.0d
	interp = 1l
ENDIF else BEGIN
	if not keyword_set(delt_t) then delt_t = double(1.0)
	svy = 0l
	ratio = 1.0d
	interp = 2l
endelse
endelse

; Final check before C call.
IF n_data2 ne npts2 then BEGIN
    print, 'FF_INTERP: STOPPED! Time2 and data2 must be same size.'
    return, junk
ENDIF

; PAINFULLY GO THROUGH ALL CASES.

if (t1_is_ptr AND t2_is_ptr) then $
    status = call_external('libfastfieldscals.so','ff_time_align', $
		*t1ptr,  $			; ARG 0
		*result_ptr, $			; ARG 1
		npts1, $			; ARG 2
		*t2ptr, $			; ARG 3
		*d2ptr,$			; ARG 4
		npts2, $			; ARG 5
		double(delt_t), $		; ARG 6
		svy, $				; ARG 7
		ratio, $			; ARG 8
		long(interp) )			; ARG 9

if (t1_is_ptr AND (NOT t2_is_ptr) ) then $
    status = call_external('libfastfieldscals.so','ff_time_align', $
		*t1ptr,  $			; ARG 0
		*result_ptr, $			; ARG 1
		npts1, $			; ARG 2
		time2, $			; ARG 3
		*d2ptr,$			; ARG 4
		npts2, $			; ARG 5
		double(delt_t), $		; ARG 6
		svy, $				; ARG 7
		ratio, $			; ARG 8
		long(interp) )			; ARG 9

if ( (NOT t1_is_ptr) AND t2_is_ptr) then $
    status = call_external('libfastfieldscals.so','ff_time_align', $
		time1,  $			; ARG 0
		*result_ptr, $			; ARG 1
		npts1, $			; ARG 2
		*t2ptr, $			; ARG 3
		*d2ptr,$			; ARG 4
		npts2, $			; ARG 5
		double(delt_t), $		; ARG 6
		svy, $				; ARG 7
		ratio, $			; ARG 8
		long(interp) )			; ARG 9

if ( (NOT t1_is_ptr) AND (NOT t2_is_ptr) ) then $
    status = call_external('libfastfieldscals.so','ff_time_align', $
		time1,  $			; ARG 0
		*result_ptr, $			; ARG 1
		npts1, $			; ARG 2
		time2, $			; ARG 3
		*d2ptr,$			; ARG 4
		npts2, $			; ARG 5
		double(delt_t), $		; ARG 6
		svy, $				; ARG 7
		ratio, $			; ARG 8
		long(interp) )			; ARG 9


; Check if the call was successful, print info if there are unmatched points...
if status ne npts1 and  $
  not keyword_set(quiet) then begin
    print, "npts1 = ", npts1, " npts2 = ", npts2, " matched = ", $
      status
endif

if status le 0 then return, junk

; free temporary pointer heap variables
if not ptr_valid(data2(0)) then ptr_free, d2ptr

IF ret_ptr EQ 1 then BEGIN 
    if data2_type eq 1 then result = ptr_new(byte(round(*result_ptr))) else $
    if data2_type eq 2 then result = ptr_new(fix(round(*result_ptr))) else $
    if data2_type eq 3 then result = ptr_new(long(round(*result_ptr))) else $
    if data2_type eq 4 then result = ptr_new(float(*result_ptr))

    if data2_type eq 5 then result = result_ptr else ptr_free, result_ptr

ENDIF else BEGIN
    if data2_type eq 1 then result = byte(round(*result_ptr)) else $
    if data2_type eq 2 then result = fix(round(*result_ptr)) else $
    if data2_type eq 3 then result = long(round(*result_ptr)) else $
    if data2_type eq 4 then result = float(*result_ptr) else $
    if data2_type eq 5 then result = *result_ptr
    ptr_free, result_ptr
ENDELSE

return, result

END

