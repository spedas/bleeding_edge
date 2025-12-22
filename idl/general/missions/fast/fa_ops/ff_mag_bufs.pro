;+
; PROCEEDURE: FF_MAG_BUFS, mag, n, delta_t=delta_t, fit=fit, 
;                           buf_starts=buf_starts, buf_ends=buf_ends
;
; PURPOSE: Shows stretches of data with n or more points in a 
;          row with no change in dt. 
;          ALSO LOCATES TORQUE AND /SUN SHADOW BOUNDARIES
;          MAG MUST HAVE 'SUN' AND 'TORQUE' ELEMENTS!
;          NOT FOR GENERAL USE.
;
; INPUT:   
;	mag  -     Fast fields data structure or data.
;	     -     Or the time array
;       n    -     OPTIONAL: Minimum number of points to make a buffer.
;	     -     Default = 1024.
;
; KEYWORDS: 
;	delta_t    - Allowable error in time steps. Default = 1.0e-6 s.
;	buf_starts - OUTPUT. A list of starting indecies of good streaks.
;	buf_ends   - OUTPUT. A list of ending indecies of good streaks.
;	fit        - OPTIONAL. IF included, fit.buf will be updated.
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
;       @(#)ff_mag_bufs.pro	1.2     

pro ff_mag_bufs, mag, n, delta_t=delta_t, fit=fit, $
               buf_starts=buf_starts, buf_ends=buf_ends

; BREAKUP MAG INTO CONTINUOUS BUFFERS WITH SAME SAMPLE SPEED
if ptr_valid(mag.time(0)) then $
     fa_fields_bufs, *mag.time, n, buf_starts=b_strt, buf_ends=b_stop $
else fa_fields_bufs,  mag.time, n, buf_starts=b_strt, buf_ends=b_stop

n_bufs = n_elements(b_strt)

; NOW LOOK FOR TORQUER BOUNDARIES
str_element, mag, 'torque',ind=ind
IF ind lt 0 THEN BEGIN
    print, 'FF_MAG_BUFS: NO TORQUER FOUND!'
ENDIF ELSE BEGIN

    ; FIND BOUNDARIES
    if ptr_valid(mag.time(0)) then $
         dtqr    = (*mag.torque)(1:*) - (*mag.torque)(0:*) $
    else dtqr    = mag.torque(1:*) - mag.torque(0:*)
    bounds  = where(dtqr NE 0, n_bounds)

    FOR i=0, n_bounds-1 DO BEGIN
        buf_inds = where(b_strt GE bounds(i), npts)
        if (npts) LT 1 then buf_inds=n_bufs
        buf_inde = where(b_stop GT bounds(i), npts)
        if (npts) LT 1 then buf_inde=n_bufs

        ; IF INDEX ARE IDENTICAL THEN TORQUE BOUNDARY IS ON 
        ; EXSISTING BOUNDARY - DO NOT ADD

        ; INSERT INTO BOUNDARIES

        IF (buf_inds(0) EQ (buf_inde(0) + 1) ) THEN BEGIN
            if (buf_inds(0) NE n_bufs) then b_strt = $
                [b_strt(0:buf_inde(0)), bounds(i)+1, b_strt(buf_inds)] $
            else b_strt = [b_strt(0:buf_inde(0)), bounds(i)+1]

            if (buf_inde(0) EQ 0) then $
                 b_stop = [bounds(i), b_stop(buf_inde)] else $
            b_stop = [b_stop(0:buf_inde(0)-1), bounds(i), b_stop(buf_inde)]  

            n_bufs = n_bufs+1
        ENDIF
    ENDFOR
ENDELSE

buf_starts = b_strt
buf_ends   = b_stop

; NOW LOOK FOR SUN/SHADOW BOUNDARIES
str_element, mag, 'sun',ind=ind
IF ind lt 0 THEN BEGIN
    print, 'FF_MAG_BUFS: NO SUN FOUND!'
ENDIF ELSE BEGIN

    ; FIND BOUNDARIES
    if ptr_valid(mag.time(0)) then $
         dsun    = (*mag.sun)(1:*) - (*mag.sun)(0:*) $
    else dsun    = mag.sun(1:*) - mag.sun(0:*)
    bounds  = where(dsun NE 0, n_bounds)

    FOR i=0, n_bounds-1 DO BEGIN
        buf_inds = where(b_strt GE bounds(i), npts)
        if (npts) LT 1 then buf_inds=n_bufs
        buf_inde = where(b_stop GT bounds(i), npts)
        if (npts) LT 1 then buf_inde=n_bufs

        ; IF INDEX ARE IDENTICAL THEN SUN BOUNDARY IS ON 
        ; EXSISTING BOUNDARY - DO NOT ADD

        ; INSERT INTO BOUNDARIES

        IF (buf_inds(0) EQ (buf_inde(0) + 1) ) THEN BEGIN
            if (buf_inds(0) NE n_bufs) then b_strt = $
                [b_strt(0:buf_inde(0)), bounds(i)+1, b_strt(buf_inds)] $
            else b_strt = [b_strt(0:buf_inde(0)), bounds(i)+1]

            if (buf_inde(0) EQ 0) then $
                 b_stop = [bounds(i), b_stop(buf_inde)] else $
            b_stop = [b_stop(0:buf_inde(0)-1), bounds(i), b_stop(buf_inde)]  

            n_bufs = n_bufs+1
        ENDIF
    ENDFOR
ENDELSE

buf_starts = b_strt
buf_ends   = b_stop

; Fix up fit.buf   
IF keyword_set(fit) then BEGIN
    fit.buf = -1

    FOR i=0, n_bufs-1 DO BEGIN
        if ptr_valid(mag.time(0)) then $
             index = where( ( fit.time GE (*mag.time)(b_strt(i)) ) AND $
                       ( fit.time LE (*mag.time)(b_stop(i)) ) , npts ) $
        else index = where( ( fit.time GE mag.time(b_strt(i)) ) AND $
                       ( fit.time LE mag.time(b_stop(i)) ) , npts )
        if (npts GE 1) then fit.buf(index) = i
    ENDFOR
ENDIF

return
END
