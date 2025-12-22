;+
; FUNCTION: FF_SMOOTH, data, n_sm, w=w, detrend=detrend, sm_funct=sm_funct
;       
; PURPOSE: Smoothing routine which treats edges and allows
;          specification of weighting fuction.
;
; INPUT: 
;       data -        REQUIRED. Data to be smoothed. Must be evenly spaced.
;                     
;       n_sm -        REQUIRED. Number of pts in Gauss 3 sigma width. 
;                     MUST BE ODD!
;
; KEYWORDS: 
;       w -           OPTIONAL. Weighting function.
;       detrend -     OPTIONAL. Detrends data before smoothing.
;       sm_funct -    OPTIONAL. A smoothing function of n_sm length.
;
; CALLING: 
;      result = ff_smooth, data, n_sm, w=w 
;
; OUTPUT: array of smoothed data.
;
; INITIAL VERSION: REE 97-10-20 
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
function ff_smooth, data, n_sm, w=w, detrend=detrend, sm_funct=sm_funct

; CHECK IF DATA IS A DOUBLE ARRAY OR DOUBLE POINTER.
data_is_double = 0
IF ptr_valid(data(0)) then BEGIN
    if data_type(*data) EQ 5 then data_is_double=1 else ddat = double(*data)
    npts = n_elements(*data)
    result = ptr_new( dblarr(npts) + !values.d_nan )
ENDIF ELSE BEGIN
    if data_type(data) EQ 5 then data_is_double = 1  else ddat = double(data)
    npts = n_elements(data)
    result = dblarr(npts) + !values.d_nan
ENDELSE

; CHECK IF W IS A DOUBLE ARRAY OR DOUBLE POINTER.
w_is_double = 0
if not keyword_set(w) then w=dblarr(npts) + 1.d
IF ptr_valid(w(0)) then BEGIN
    if data_type(*w) EQ 5 then w_is_double=1 else dw = double(*w)
    IF n_elements(*w) NE npts then BEGIN
        message, /info, 'weighting function must be same size as data!'
        return, 0
    ENDIF
ENDIF ELSE BEGIN
    if data_type(w) EQ 5 then w_is_double = 1 else dw = double(w)
    IF n_elements(w) NE npts then BEGIN
        message, /info, 'weighting function must be same size as data!'
        return, 0
    ENDIF
ENDELSE

; CHECK SMOOTH FUNCTION. - MAKE GAUSIAN IF NOT SUPPLIED.
if keyword_set(sm_funct) then n_sm = n_elements(sm_funct) ELSE BEGIN
    if not keyword_set(n_sm) then n_sm = 41
    if (long(n_sm/2)) * 2 EQ n_sm then n_sm = n_sm + 1 ; MAKE n_sm ODD.
    start = n_sm/2 + 1
    indgauss = indgen(n_sm) - start + 1
    temp     = double(indgauss) * 2.15 / double(start-1) ; 2.15 = 1%
    sm_funct = exp(-temp*temp)
ENDELSE

; SET UP DETREND
if keyword_set(detrend) then detrend=1l else detrend = 0l

; CALL EXTERNAL SAVING MEMORY.
if (data_is_double AND w_is_double) then $
   status = call_external('libfastfieldscals.so','ff_smooth_ext', $
		data, $				; ARG 0
		w, $				; ARG 1
		result, $			; ARG 2
		long(npts), $			; ARG 3
		double(sm_funct), $		; ARG 4
		long(n_sm), $		        ; ARG 5
		long(detrend) )			; ARG 6

if (data_is_double AND w_is_double EQ 0) then $
   status = call_external('libfastfieldscals.so','ff_smooth_ext', $
		data, $				; ARG 0
		dw, $				; ARG 1
		result, $			; ARG 2
		long(npts), $			; ARG 3
		double(sm_funct), $		; ARG 4
		long(n_sm), $		        ; ARG 5
		long(detrend) )			; ARG 6

if (data_is_double EQ 0 AND w_is_double) then $
   status = call_external('libfastfieldscals.so','ff_smooth_ext', $
		ddat, $				; ARG 0
		w, $				; ARG 1
		result, $			; ARG 2
		long(npts), $			; ARG 3
		double(sm_funct), $		; ARG 4
		long(n_sm), $		        ; ARG 5
		long(detrend) )			; ARG 6

if (data_is_double EQ 0 AND w_is_double EQ 0) then $
   status = call_external('libfastfieldscals.so','ff_smooth_ext', $
		ddat, $				; ARG 0
		dw, $				; ARG 1
		result, $			; ARG 2
		long(npts), $			; ARG 3
		double(sm_funct), $		; ARG 4
		long(n_sm), $		        ; ARG 5
		long(detrend) )			; ARG 6

; THERE HAS GOT TO BE A BETTER WAY>

return, result

END
