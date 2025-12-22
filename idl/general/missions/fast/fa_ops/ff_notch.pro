;+
; FUNCTION: FF_NOTCH, dqd, data, Bphase=Bphase, Binterp=Binterp, Bnan=Bnan,
;                                  Sphase=Sphase, Sinterp=Sinterp, Snan=Snan
;
; PURPOSE: A utility routine which that notches dc fields data on
;          magphase or sunphase.
;
; INPUT: 
;       dqd -         REQUIRED. A string that starts with:
;                     'V5-V8', 'V1-V2', 'V1-V4', 'V5-V6','V7-V8', or 'V1-V58'
;       data -        OPTIONAL. An byte, int, long, float, or double arrray.
;
; KEYWORDS: 
;       Bphase        Magnetic field phase. One of Bphase or Sphase 
;                     is REQUIRED. This array
;                     must have the same number of points as data.
;                     See fa_fields_combine to form data.
;       Binterp -     If set, interpolates mag notched data.     DEFAULT = 0
;       Bnan -        If set, mag notched data is set to fnan.   DEFAULT = 0
;       Sphase        Sun spin phase. One of Bphase or Sphase 
;                     is REQUIRED. This array
;                     must have the same number of points as data.
;                     See fa_fields_combine to form data.
;       Sinterp -     If set, interpolates sun notched data.     DEFAULT = 0
;       Bnan -        If set, sun notched data is set to fnan.   DEFAULT = 0
;       Bnotch -      The byte flag value for Bnotch, zero value means
;                     'notch' and data has been altered
;       Snotch -      The byte flag value for shadow notch, zero value means
;                     'notch' and data has been altered
; CALLING: ff_notch(comp1, 'V5-V8', Bphase=Bphase, /Bint)
;
; OUTPUT: A byte array of the notched data. If Data is changed in place.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: 97-04-03. Ne added by REE.
; Space Scienes Lab, UCBerkeley
; 2024-05-21, Added separate bnotch and snotch outputs, jmm, jimm@ssl.berkeley.edu
; 
;-
function ff_notch, dqd, data, Bphase=Bphase, Binterp=Binterp, Bnan=Bnan, $
                   Sphase=Sphase, Sinterp=Sinterp, Snan=Snan, $
                   bnotch=bnotch, snotch=snotch

; Set up constants.
two_pi = 2.d*!dpi

notch_struct = ff_info(dqd, /notch)

IF data_type(notch_struct) ne 8 then BEGIN
    print, "FF_NOTCH: STOPPED!"
    print, "Dqd name not recognized."
    return, -1
ENDIF

;
; SET UP NOTCH ANGLES
;
mag_notch_ang_strt = double(notch_struct.mag_strt) * two_pi / 360.
mag_notch_ang_stop = double(notch_struct.mag_stop) * two_pi / 360.
mag_rot_ang        = double(notch_struct.mag_ang)  * two_pi / 360.
sun_notch_ang_strt = double(notch_struct.sun_strt) * two_pi / 360.
sun_notch_ang_stop = double(notch_struct.sun_stop) * two_pi / 360.
sun_rot_ang        = double(notch_struct.sun_ang)  * two_pi / 360.

;
; SET UP ARRAYS
npts = n_elements(Bphase) > n_elements(Sphase)
IF npts eq 0 then BEGIN
    message,'You must supply an array for sun or mag phase',/continue
    return,-1
ENDIF

notch = bytarr(npts) + 1b

; Do the mag notching first.
IF n_elements(Bphase) EQ npts then BEGIN
    n_notch = n_elements(mag_notch_ang_strt)
    FOR i=0, n_notch-1 do BEGIN
        phs = (Bphase + mag_rot_ang - mag_notch_ang_strt(i) + two_pi) $
                mod two_pi
        notch_width = mag_notch_ang_stop(i)- mag_notch_ang_strt(i)
        if notch_width lt 0 then notch_width = notch_width + two_pi
        notch = (phs GT notch_width) AND notch
     ENDFOR
ENDIF

IF keyword_set(Binterp) then BEGIN
    index = where(notch EQ 1, n_index)
    IF (n_index GT 0l) then BEGIN
        Bphase2 = Bphase(index)
        data2 = data(index)
        data  = ff_interp(Bphase,Bphase2,data2, delt_t=2.0)
    ENDIF
ENDIF

IF keyword_set(Bnan) then BEGIN
    index = where(notch EQ 0, n_index)
    if (n_index GT 0l) then data(index) = !values.d_nan
ENDIF

; Mag notching done. Now do sun notching.
Bnotch = notch
notch = bytarr(npts) + 1b


IF n_elements(Sphase) EQ npts then BEGIN
    n_notch = n_elements(sun_notch_ang_strt)
    FOR i=0, n_notch-1 do BEGIN
        phs = (Sphase + sun_rot_ang - sun_notch_ang_strt(i) + two_pi) $
                mod two_pi
        notch_width = sun_notch_ang_stop(i)- sun_notch_ang_strt(i)
        if notch_width lt 0 then notch_width = notch_width + two_pi
        notch = (phs GT notch_width) AND notch
     ENDFOR
ENDIF

IF keyword_set(Sinterp) then BEGIN
    index = where(notch EQ 1, n_index)
    IF (n_index GT 0l) then BEGIN
        Sphase2 = Sphase(index)
        data2 = data(index)
        data  = ff_interp(Sphase,Sphase2,data2, delt_t=2.0)
    ENDIF
ENDIF

IF keyword_set(Snan) then BEGIN
    index = where(notch EQ 0, n_index)
    if (n_index GT 0l) then data(index) = !values.d_nan
ENDIF

snotch = notch
notch = notch AND Bnotch

return, notch

END

