;+
; PROCEEDURE: FF_FIXTIME, time, kept=kept, fix=fix
;
; PURPOSE: Identifies stretches of data that are time reversed. Throws 
;          away the fewest number of points. Used a C-call. 
;
; INPUT:   
;	time   - Time array.
;
; KEYWORDS: 
;	kept   - Where the good points are.
;	fix    - Fixes the time array for you. DEFAULT = 1
;
; CALLING: fix_time, time              
;
; OUTPUT: None.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
pro ff_fixtime, time, kept=kept, fix=fix

; Handle case where time is not double.
IF data_type(time) ne 5 then BEGIN
    IF data_type(time) GE 1 and data_type(time) LE 4 then BEGIN
        t = double(time)
        npts = long(n_elements(t))
        status = call_external('libfastfieldscals.so','ff_fix_time', $
		t, $				; ARG 0
		npts) 				; ARG 1
        kept = where(t GE 0, nkept)
    ENDIF ELSE BEGIN
        print, "FIX_TIME: STOPPED!" 
        print, "Time array not valid" 
        return
    ENDELSE

; Handle case where time is double.
ENDIF ELSE BEGIN
    npts = long(n_elements(time))

    status = call_external('libfastfieldscals.so','ff_fix_time', $
		time, $				; ARG 0
		npts) 				; ARG 1
    kept = where(time GE 0, nkept)
ENDELSE

if keyword_set(fix) then time = time(kept)

return

END
