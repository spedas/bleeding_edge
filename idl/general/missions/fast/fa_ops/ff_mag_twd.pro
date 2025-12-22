;+
; FUNCTION: FF_MAG_TWD, mag, fit, n_sm=n_sm,max_sig=max_sig,talk=talk,plot=plot 
;       
; PURPOSE: Routine calculates a dynamic tweak matrix
;          IDL VER 5 AND GREATER!
;          NOT FOR GENERAL USE!
;
; INPUT: 
;       mag -         REQUIRED. 'MagDC' data structure.
;      	fit -	      REQUIRED. Fits from ff_magfit.
;
;
; KEYWORDS: 
;      	max_sig -     OPTIONAL. Maximum allowed sigma in fit. DFLT=10 nT.
;      	n_sm -        OPTIONAL. Smooting cof.
;       talk -        OPTIONAL. Give informational message.
;       plot -        OPTIONAL. Plots Results.
;
; CALLING: 
;       twd = ff_mag_twd(mag, fit)
;
; OUTPUT: pfit.
;
; INITIAL VERSION: REE/RJS/KRB 97-10-20 - see UCLA_MAG_DESPIN, FF_XYMAGFIX
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_mag_twd.pro	1.2     

function ff_mag_twd, mag, fit, n_sm=n_sm, max_sig=max_sig, talk=talk, plot=plot

IF keyword_set(talk) then BEGIN
    tstrt   = systime(1)
    print, ' -----'
    print, 'FF_MAG_TWD: Calculating dynamic calibration matrix ...'
ENDIF

; START BY CHECKING INPUTS.
if not keyword_set(n_sm)    then n_sm    = 41   ; Points
if not keyword_set(max_sig) then max_sig = 10.0 ; nT
if fit.valid NE 1 then return,0
if mag.valid NE 1 then return,0

; LOCATE VALID FITS
good  = fit.good
index = where(good, npts)
if npts LT 1 then return, 0

; BREAKUP MAG INTO CONTINUOUS BUFFERS WITH SAME SAMPLE SPEED
ff_mag_bufs,mag, 40, buf_starts=b_strt, buf_ends=b_stop, fit=fit
first_good = 1
delt_z0    = dblarr(n_elements(b_strt))
t_z0       = dblarr(n_elements(b_strt))
after_z0   = intarr(n_elements(b_strt))

; LOOP OVER BUFFERS
FOR i=0, n_elements(b_strt)-1 DO BEGIN
    ind = where(fit.buf EQ i, n_ind)

    ; GET START/STOP TIMES
    IF ptr_valid(mag.time(0)) THEN BEGIN
        t_strt = (*mag.time)(b_strt(i))
        t_stop = (*mag.time)(b_stop(i))
    ENDIF ELSE BEGIN
        t_strt = mag.time(b_strt(i))
        t_stop = mag.time(b_stop(i))
    ENDELSE
    
    ; ARE THERE ANY FITS IN THIS SEGMENT?
    IF n_ind GT 0 THEN BEGIN
        w   = double( exp(- fit.sig(ind) /max_sig  ) )
        t   = fit.time(ind)

        ; ARE THERE ANY GOOD FITS?
        IF (total(w)) GT 0.1 THEN BEGIN 

            ; CALCULATE BASELINES
            x0      = ff_smooth(fit.x0(ind), n_sm, w=w)
            y0      = ff_smooth(fit.y0(ind), n_sm, w=w)
            z0      = ff_smooth(fit.z0(ind), n_sm, w=w, /detrend)

            ; CACULATE ROTATION YX
            x_dot_y = fit.xc(ind)*fit.yc(ind) + fit.xs(ind)*fit.ys(ind)
            x_mag_2 = fit.xc(ind)*fit.xc(ind) + fit.xs(ind)*fit.xs(ind)
            yx      = -ff_smooth(x_dot_y / x_mag_2, n_sm, w=w)

            ; RENORMALIZE X and Y
            y_mag   = sqrt( fit.yc(ind)*fit.yc(ind) + fit.ys(ind)*fit.ys(ind) )
            x_mag   = sqrt(x_mag_2)
            norm    = ff_smooth( (x_mag-y_mag) / x_mag, n_sm, w=w)
            ff_mag_extend, norm, t, t_strt=t_strt, t_stop=t_stop
            xx      = 1.d - norm/2.d
            norm    = ff_smooth( (x_mag-y_mag) / y_mag, n_sm, w=w)
            ff_mag_extend, norm, t, t_strt=t_strt, t_stop=t_stop
            yy      = 1.d + norm/2.d

            ; REMOVE SPIN FROM Z
            zx      = -ff_smooth(fit.zc(ind)/fit.xc(ind), n_sm, w=w)
            zy      = -ff_smooth(fit.zs(ind)/fit.ys(ind), n_sm, w=w)
            time    = fit.time(ind)

            ; EXTEND POINTS TO BUFFER BOUNDARY (xx and yy extended above)
            ff_mag_extend, x0, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, y0, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, z0, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, yx, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, zx, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, zy, t, t_strt=t_strt, t_stop=t_stop
            t = [t_strt,t,t_stop]

            ; SPECIAL SECTION TO FIX Z0
            IF (first_good) then BEGIN
                delt_z0(i)   = 0.d
                after_z0(i)  = fit.torque(ind(0))
            ENDIF ELSE BEGIN
                delt_z0(i)   = z0(0) - big_z0( n_elements(big_z0) - 1l )
                after_z0(i)  = fit.torque(ind(0))
            ENDELSE
            t_z0(i) = time(0)

            IF (first_good) THEN BEGIN
                big_x0 = x0 & big_y0 = y0 & big_z0 = z0
                big_yx = yx & big_xx = xx & big_yy = yy
                big_zx = zx & big_zy = zy & big_t  = t
                first_good = 0
            ENDIF ELSE BEGIN
                big_x0=[big_x0,x0] & big_y0=[big_y0,y0] & big_z0=[big_z0,z0]
                big_yx=[big_yx,yx] & big_xx=[big_xx,xx] & big_yy=[big_yy,yy]
                big_zx=[big_zx,zx]
                big_zy=[big_zy,zy] & big_t =[big_t,t]
            ENDELSE
        ENDIF
    ENDIF
ENDFOR

; RECONSTRUCT Z0

intf_z0 = dblarr(n_elements(b_strt))
intb_z0 = dblarr(n_elements(b_strt))
int_z0  = dblarr(n_elements(b_strt))
found_0 = 0
ind     = where(t_z0 GT 1.d, n_ind)

; INTEGRATE FROM THE BEGINING
FOR i=0, n_ind-1 DO BEGIN
    IF (after_z0(ind(i))) EQ 0 then BEGIN
        intf_z0(ind(i)) = 0.d
        found_0         = 1
    ENDIF ELSE BEGIN
        IF (found_0) then BEGIN
            if after_z0(ind(i)) NE after_z0(ind(i-1)) then $
                intf_z0(ind(i))  = intf_z0(ind(i-1)) + delt_z0(ind(i)) $
            else intf_z0(ind(i)) = intf_z0(ind(i-1))
        ENDIF else intf_z0(ind(i)) = 0.d
    ENDELSE
ENDFOR

; INTEGRATE FROM THE END
found_0 = 0
FOR i=n_ind-1, 0, -1 DO BEGIN
    IF (after_z0(ind(i))) EQ 0 then BEGIN
        intb_z0(ind(i)) = 0.d
        found_0         = 1
    ENDIF ELSE BEGIN
        IF (found_0) then BEGIN
            if after_z0(ind(i)) NE after_z0(ind(i+1)) then $
                intb_z0(ind(i))  = intb_z0(ind(i+1)) - delt_z0(ind(i+1)) $
            else intb_z0(ind(i)) = intb_z0(ind(i+1))
        ENDIF else intb_z0(ind(i)) = 0.d
    ENDELSE
ENDFOR

; COMBINE FORWARD AND BACKWARD INTEGRATIONS
FOR i=n_elements(b_strt)-1, 0, -1 DO BEGIN
    if intf_z0(i) EQ 0.d then int_z0(i) = intb_z0(i)
    if intb_z0(i) EQ 0.d then int_z0(i) = intf_z0(i)
    if intf_z0(i) NE 0.d AND intb_z0(i) NE 0.d then $
        int_z0(i) = (intf_z0(i) + intb_z0(i)) /2.d
ENDFOR

; PUT TORQUER SHIFT INTO BIG_Z0
big_z0(*) = 0.d
FOR i=0, n_ind-1 DO BEGIN
    ind_t = where(big_t GE t_z0(ind(i)), n_ind_t)
    if (n_ind_t GT 0) then big_z0(ind_t) = int_z0(ind(i))
ENDFOR

npts = n_elements(big_t)



; ALL DONE! CONSTRUCT STRUCTURE AND RETURN

twd   = {x0: big_x0, xx: big_xx, xy : dblarr(npts), xz: dblarr(npts), $
         y0: big_y0, yx: big_yx, yy : big_yy,       yz: dblarr(npts), $
         z0: big_z0, zx: big_zx, zy : big_zy,       zz: dblarr(npts) + 1.d, $
         time: big_t }


; ADD STREAK LOCATIONS TO MAG
IF ptr_valid(mag.streak_starts(0)) then BEGIN
    streak_starts  = ptr_new(b_strt)
    streak_ends    = ptr_new(b_stop)
    streak_lengths = ptr_new(b_stop-b_strt+1)
    ptr_free, mag.streak_starts, mag.streak_ends, mag.streak_lengths
    mag.streak_starts  = streak_starts
    mag.streak_ends    = streak_ends
    mag.streak_lengths = streak_lengths
ENDIF

if keyword_set(talk) then $
    print, 'FF_MAG_TWD: Done. Run time =', systime(1)-tstrt, ' seconds.'

IF keyword_set(plot) then BEGIN
    wi, plot-1
    !p.multi = [0,1,3,0,0]
    !p.psym = 3
    plot, fit.time-fit.time(0), fit.x0, yran=[-200,200], charsize=1.5, $
         xran=[0,8000]
    oplot, twd.time-fit.time(0), twd.x0, col=1
    oplot, twd.time-fit.time(0), (twd.xx-1.d)*1.e5, col=5
    xyouts, 5000, -100,'WHITE    - FIT X ZERO', charsize=1.25     
    xyouts, 5000, -140,'MAGENTA - TWEAK X ZERO', charsize=1.25     
    xyouts, 5000, -180,'YELLOW  - (XX-1)*10^5', charsize=1.25     
    xyouts, 2250, 212,'FF_MAG_TWD (DYNAMIC TWEAK) RESULTS', charsize=1.25     
    xyouts, 6500, 150,'X TWEAKS', charsize=1.50, col=4     

    plot, fit.time-fit.time(0), fit.y0, yran=[-100,100], charsize=1.5, $
         xran=[0,8000]
    oplot, twd.time-fit.time(0), twd.y0, col=1
    oplot, twd.time-fit.time(0), twd.yx*100000, col=3
    oplot, twd.time-fit.time(0), (twd.yy-1.d)*1.e5, col=5
    xyouts, 5000, -30,'WHITE    - FIT Y ZERO', charsize=1.25     
    xyouts, 5000, -50,'MAGENTA - TWEAK Y ZERO', charsize=1.25     
    xyouts, 5000, -70,'LT BLUE  - TWD_YX*10^5', charsize=1.25     
    xyouts, 5000, -90,'YELLOW  - (YY-1)*10^5', charsize=1.25     
    xyouts, 6500, 75,'Y TWEAKS', charsize=1.50, col=4     

    plot, fit.time-fit.time(0), fit.z0, yran=[-6000,6000], charsize=1.5, $
         xran=[0,8000]
    oplot, twd.time-fit.time(0), twd.zx*1.e7, col=3
    oplot, twd.time-fit.time(0), twd.zy*1.e7, col=5
    oplot, twd.time-fit.time(0), twd.z0, col=1
    xyouts, 5000, -1800,'WHITE    - FIT Z ZERO', charsize=1.25     
    xyouts, 5000, -3000,'MAGENTA - TWEAK Z ZERO', charsize=1.25     
    xyouts, 5000, -4200,'LT BLUE - TWD_ZX*10^7', charsize=1.25     
    xyouts, 5000, -5400,'YELLOW  - TWD_ZY*10^7', charsize=1.25     
    xyouts, 6500, 4500,'Z TWEAKS', charsize=1.50, col=4     

    !p.multi = 0
    !p.psym = 0
    wshow, /icon
    wset,0
    plot=plot+1
ENDIF



return, twd
END
