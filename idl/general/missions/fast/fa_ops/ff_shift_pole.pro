;+
; FUNCTION: FF_SHIFT_POLE, data, new_pole, sample_time, oldpole=oldpole
;
; PURPOSE: A utility routine which integrates the one-pole high-pass
;          on HSBM or HG fields data to a new pole value. NOT GENERAL - 
;          USER HOSTILE.
;
; INPUT: 
;       data -        REQUIRED. Data to be shifted.
;       sample_time - REQUIRED. Sample time.
;       new_pole -    REQUIRED. New high-pass pole in Hz.
;
; KEYWORDS: 
;       old_pole -    Unless you know what you're doing, do not
;                     change. DEFAULT = 3386.275d (HG high-pass pole, Hz).
;
; CALLING: data = ff_shift_pole(data, new_pole, sample_time)
;
; OUTPUT: data is integrated and refiltered.
;
; INITIAL VERSION: REE 97-06-12
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
function ff_shift_pole, data, new_pole, sample_time, old_pole=old_pole

; CHECK KEYWORDS
if not keyword_set(old_pole) then old_pole = 3386.275d
if not keyword_set(sample_time) then sample_time = 3.0517578e-5
if not keyword_set(new_pole) then new_pole = old_pole/10.

; SET UP FOR CALL_EXTERNAL
npts=long(n_elements(data))
result = double(data)

; CALL EXTERNAL
    status = call_external('libfastfieldscals.so','ff_pole', $
		result, $			; ARG 0
		npts, $				; ARG 1
		double(sample_time), $		; ARG 2
		double(old_pole), $		; ARG 3
		double(new_pole) )		; ARG 4
return, result
end

