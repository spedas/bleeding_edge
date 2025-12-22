;+
; PROCEEDURE: FF_MAG_TWKDAT, mag, tw, talk=talk, plot=plot
;       
; PURPOSE: Applies the tweak matrix to the magnetic field data.
;          NOT FOR GENERAL USE! IDL >=5.0 COMPATABLE. ALLOWS POINTERS.
;
; INPUT: 
;      	mag -	      REQUIRED. Data structure.
;      	tw -	      REQUIRED. Static or dynamic tweak matrix.
;
;
; KEYWORDS: 
;       talk -        OPTIONAL. Give informational message.
;       plot -        OPTIONAL. Plots results.
;
; CALLING: 
;       ff_mag_twkdat,mag,twc
;
; OUTPUT: fit.
;
; INITIAL VERSION: REE/RJS/KRB 97-10-20 - see ff_magdc
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_mag_twkdat.pro	1.1     

pro ff_mag_twkdat, mag, tw, talk=talk, plot=plot

IF keyword_set(talk) then BEGIN
    tstrt   = systime(1)
    print, '-----'
    print, 'FF_MAG_TWKDAT: Applying new cal matrix to mag data ...'
ENDIF

; CHECK VALIDITY
if (mag.valid NE 1) then return
if data_type(tw) NE 8 then return

; SET UP SO THAT WE WORK FROM BOTH STANDARD DAT AND PTR STRUCTURES. 
IF ptr_valid(mag.time(0)) then BEGIN
    x = mag.comp1
    y = mag.comp2
    z = mag.comp3
    old_z = *z
    t = mag.time
ENDIF ELSE BEGIN   ; STANDARD DAT WASTES MEMORY!
    x = ptr_new(mag.comp1)
    y = ptr_new(mag.comp2)
    z = ptr_new(mag.comp3)
    t = ptr_new(mag.time) 
ENDELSE    
    
; DETERMINE IF STATIC OR DYNAMIC
IF n_elements(tw.x0) GT 1 THEN BEGIN

    ; DYNAMIC CASE
    x0 = ff_interp(*t,tw.time,tw.x0)
    y0 = ff_interp(*t,tw.time,tw.y0)
    z0 = ff_interp(*t,tw.time,tw.z0)

    xx = ff_interp(*t,tw.time,tw.xx)
    ;xy = ff_interp(*t,tw.time,tw.xy) ; DO NOT USE!
    ;xz = ff_interp(*t,tw.time,tw.xz) ; DO NOT USE!

    yx = ff_interp(*t,tw.time,tw.yx)
    yy = ff_interp(*t,tw.time,tw.yy)
    ;yz = ff_interp(*t,tw.time,tw.yz) ; DO NOT USE!

    zx = ff_interp(*t,tw.time,tw.zx)
    zy = ff_interp(*t,tw.time,tw.zy)
    ;zz = ff_interp(*t,tw.time,tw.zz) ; DO NOT USE!

    ; FIRST GET RID OF BASELINES
    *x = *x - x0
    *y = *y - y0

    ; NEXT FIX UP Z
    *z = *z - z0 + zx*(*x) + zy*(*y)

    ; NEXT FIX UP X AND Y FROM Z
    ;*x = *x + xz*(*z) ; DO NOT USE!
    ;*y = *y + yz*(*z) ; DO NOT USE!

    ; NEXT FIX UP Y FROM X
    *y = *y + yx*(*x)

    ; RENORMALIZE X, Y, AND Z including 2nd order on Z.
    *x = *x * xx
    *y = *y * yy
    ;*z = *z * (zz + xz*zx + yz*zy) ; 2nd order correction. ; DO NOT USE!

ENDIF ELSE BEGIN

    ; STATIC CASE
    ; FIRST GET RID OF BASELINES
    *x = *x - tw.x0
    *y = *y - tw.y0

    ; NEXT FIX UP Z
    *z = *z - tw.z0 + tw.zx*(*x) + tw.zy*(*y)

    ; NEXT FIX UP X AND Y FROM Z
    *x = *x + tw.xz*(*z)
    *y = *y + tw.yz*(*z)

    ; NEXT FIX UP Y FROM X
    *y = *y + tw.yx*(*x)

    ; RENORMALIZE X, Y, AND Z including 2nd order on Z.
    *x = *x * tw.xx
    *y = *y * tw.yy
    *z = *z * (tw.zz + tw.xz*tw.zx + tw.yz*tw.zy) ; 2nd order correction.

ENDELSE

; SET UP SO THAT WE WORK FROM BOTH STANDARD DAT AND PTR STRUCTURES. 
IF not ptr_valid(mag.time(0)) then BEGIN
    mag.comp1 = *x
    mag.comp2 = *y
    mag.comp3 = *z
    prt_free,x
    prt_free,y
    prt_free,z
    prt_free,t
ENDIF    
 
if keyword_set(talk) then $
    print, 'FF_MAG_TWKDAT: Done! Run time =', systime(1)-tstrt, ' seconds.'

IF keyword_set(plot) AND ptr_valid(mag.time(0)) then BEGIN
    wi, plot-1
    !p.multi=0
    !p.psym = 3
    ind = where( *mag.notch)
    plot, *mag.time-(*mag.time)(0), *mag.comp3+2000, yran=[-8000,8000], $
          charsize=2.0, xtitle='TIME', ytitle = 'nT', ystyle=1, $
          title='FA_FIELD_MAGDC RESULTS'
    oplot, (*mag.time)(ind)-(*mag.time)(0), (*mag.comp3)(ind)-2000, col=3
    oplot, *mag.time-(*mag.time)(0), old_z, col=1
    oplot, tw.time-(*mag.time)(0), tw.z0 - 2000.0, col=5
    xyouts, 3500, -5400,'WHITE    - MAG Z + 2000 (ALL)', charsize=1.5     
    xyouts, 3500, -6100,'MAGENTA - MAG Z UNFIXED', charsize=1.5
    xyouts, 3500, -6800,'YELLOW  - TWD_Z0', charsize=1.5
    xyouts, 3500, -7500,'LT BLUE - MAG Z - 2000 (GOOD)', charsize=1.5
    !p.psym = 0
    wshow, /icon
    wset,0
    plot=plot+1
ENDIF


return
END
