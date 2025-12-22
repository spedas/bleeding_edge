;+
; PROCEEDURE: FA_FIELDS_BUFS, dat, n, delta_t=delta_t,
;                           buf_starts=buf_starts, buf_ends=buf_ends
;
; PURPOSE: Shows stretches of data with n or more points in a 
;          row with no change in dt.
;
; INPUT:   
;	dat  -     Fast fields data structure or data.
;	     -     Or the time array
;       n    -     OPTIONAL: Minimum number of points to make a buffer.
;	     -     Default = 1024.
;
; KEYWORDS: 
;	delta_t    - Allowable error in time steps. Default = 1.0e-6 s.
;	buf_starts - OUTPUT. A list of starting indecies of good streaks.
;	buf_ends   - OUTPUT. A list of ending indecies of good streaks.
;
; CALLING: fa_fields_bufs,dat               ; Survey data.
;
; OUTPUT: 
;	buf_starts - A list of starting indecies of good streaks.
;	buf_ends   - A list of ending indecies of good streaks.
;
; SEE: fa_fields_filter, etc.
;
; INITIAL VERSION: REE 97-03-17
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
pro fa_fields_bufs, dat, n, delta_t=delta_t, $
               buf_starts=buf_starts, buf_ends=buf_ends


; Set up for external call.
result = lonarr(10000)
nbufs = 0l
if n_elements(n) ne 1 then n = 1024l
n = long(n)
if n_elements(delta_t) ne 1 then delta_t = double(1.0e-6)
delta_t = double(delta_t)
buf_starts = [0l]
buf_ends   = [0l]

;  Below stolen from find_gaps written by Bill Peria.
intype = idl_type(dat)

; Handle non-structure case first.
IF intype ne 'structure' then BEGIN
    ; Handle case where dat is not double.
    IF data_type(dat) ne 5 then BEGIN
        IF data_type(time) GE 1 and data_type(dat) LE 4 then BEGIN
            t = double(dat)
            npts = long(n_elements(t))
            status = call_external('libfastfieldscals.so','ff_find_bufs', $
		t, $				; ARG 0
		npts, $ 			; ARG 1
		n, $				; ARG 2
		result, $ 			; ARG 3
		delta_t) 			; ARG 4

        ENDIF ELSE BEGIN
            print, "FIX_TIME: STOPPED!" 
            print, "Time array not valid" 
            return
        ENDELSE

    ; Handle case where dat is double.
    ENDIF ELSE BEGIN
        npts = long(n_elements(dat))
        status = call_external('libfastfieldscals.so','ff_find_bufs', $
		dat, $				; ARG 0
		npts, $ 			; ARG 1
		n, $				; ARG 2
		result, $ 			; ARG 3
		delta_t) 			; ARG 4
    ENDELSE

; Handle case where dat is a structure.
ENDIF ELSE BEGIN
    IF (missing_tags(dat,'time',absent=absent) gt 0) then BEGIN
        message,'Required tag TIME is missing!',/continue
        return
    ENDIF
    npts = long( n_elements(dat.time) )

    status = call_external('libfastfieldscals.so','ff_find_bufs', $
		double(dat.time), $		; ARG 0
		npts, $				; ARG 1
		n, $				; ARG 2
		result, $ 			; ARG 3
		delta_t) 			; ARG 4

ENDELSE

; Set up the output.
IF status gt 0 then BEGIN
    buf_starts  = lonarr(status)
    buf_ends    = lonarr(status)
    start_index = lindgen(status)*2
    buf_starts  = result(start_index)
    buf_ends    = result(start_index + 1l)
ENDIF

if status gt 4997 then print, 'FA_FIELDS_BUFS: TROUBLE! Too many segments.'
    
END
