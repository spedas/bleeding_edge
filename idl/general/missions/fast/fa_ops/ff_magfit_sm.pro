;+
; FUNCTION: FF_MAGFIT_SM, mag, fit, n_sm=n_sm, max_sig=max_sig, talk=talk
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
;
; CALLING: 
;       fit_sm = ff_magfit_sm(mag, fit)
;
; OUTPUT: sm_fit.
;
; INITIAL VERSION: REE/RJS/KRB 97-10-20 - see UCLA_MAG_DESPIN, FF_XYMAGFIX
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_magfit_sm.pro	1.2     

function ff_magfit_sm, mag, fit, n_sm=n_sm, max_sig=max_sig, talk=talk

IF keyword_set(talk) then BEGIN
    tstrt   = systime(1)
    print, ' -----'
    print, 'FF_MAGFIT_SM: Smoothing fits ...'
ENDIF

; START BY CHECKING INPUTS.
if not keyword_set(n_sm)    then n_sm    = 41   ; Points
if not keyword_set(max_sig) then max_sig = 10.0 ; nT
if fit.valid NE 1 then return,0
if mag.valid NE 1 then return,0

; BREAKUP MAG INTO CONTINUOUS BUFFERS WITH SAME SAMPLE SPEED
ff_mag_bufs,mag, 40, buf_starts=b_strt, buf_ends=b_stop, fit=fit
first_good = 1

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

        ; ARE THERE ANY GOOD FITS?
        IF (total(w)) GT 0.1 THEN BEGIN 

            ; CALCULATE BASELINES
            xs      = ff_smooth(fit.xs(ind), n_sm, w=w)
            xc      = ff_smooth(fit.xc(ind), n_sm, w=w, /detrend)
            x0      = ff_smooth(fit.x0(ind), n_sm, w=w)
            ys      = ff_smooth(fit.ys(ind), n_sm, w=w, /detrend)
            yc      = ff_smooth(fit.yc(ind), n_sm, w=w)
            y0      = ff_smooth(fit.y0(ind), n_sm, w=w)
            zs      = ff_smooth(fit.zs(ind), n_sm, w=w)
            zc      = ff_smooth(fit.zc(ind), n_sm, w=w)
            z0      = ff_smooth(fit.z0(ind), 21, w=w, /detrend)
            buf     = fit.buf(ind)
            phs     = fit.phs(ind)
            t       = fit.time(ind)

        
            ; EXTEND POINTS TO BUFFER BOUNDARY (xx and yy extended above)
            ff_mag_extend, xs, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, xc, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, x0, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, ys, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, yc, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, y0, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, zs, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, zc, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, z0, t, t_strt=t_strt, t_stop=t_stop
            ff_mag_extend, phs, t, t_strt=t_strt, t_stop=t_stop
            buf      = [buf(0),buf,buf(0)]
            t      = [t_strt,t,t_stop]

            IF (first_good) THEN BEGIN
                big_xs  = xs  & big_xc  = xc  & big_x0  = x0
                big_ys  = ys  & big_yc  = yc  & big_y0  = y0
                big_zs  = zs  & big_zc  = zc  & big_z0  = z0
                big_phs = phs & big_t  = t    & big_buf = buf
                first_good = 0
            ENDIF ELSE BEGIN
                big_xs=[big_xs,xs] & big_xc=[big_xc,xc] & big_x0=[big_x0,x0]
                big_ys=[big_ys,ys] & big_yc=[big_yc,yc] & big_y0=[big_y0,y0]
                big_zs=[big_zs,zs] & big_zc=[big_zc,zc] & big_z0=[big_z0,z0]
                big_phs=[big_phs,phs] & big_t=[big_t,t] & big_buf=[big_buf,buf]
            ENDELSE
        ENDIF
    ENDIF
ENDFOR

; ALL DONE! CONSTRUCT STRUCTURE AND RETURN
npts =  n_elements(big_xc)
fit_sm  = {valid:1, npts: npts, $
           xs: big_xs, xc: big_xc, x0: big_x0, xsig: dblarr(npts), $
           ys: big_ys, yc: big_yc, y0: big_y0, ysig: dblarr(npts), $
           zs: big_zs, zc: big_zc, z0: big_z0, zsig: dblarr(npts), $
           phs: big_phs, time: big_t, buf:big_buf, good: bytarr(npts) + 1}

if keyword_set(talk) then $
    print, 'FF_MAGFIT_SM: Done. Run time =', systime(1)-tstrt, ' seconds.'

return, fit_sm
END
