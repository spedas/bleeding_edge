;+
; FUNCTION: FF_MAGFIT, mag, out=out, talk=talk, max_err=max_err, plot=plot
;       
; PURPOSE: Wrapper between ff_magdc to ff_qfit. 
;          NOT FOR GENERAL USE! 
;          IDL 5 OR HIGHER - USES POINTERS! 
;
; INPUT: 
;       mag -         REQUIRED. 'MagDC' data structure. MAY HAVE POINTERS!
;
;
; KEYWORDS: 
;       out -         OPTIONAL. Will locate bad points in mag.notch.
;       talk -        OPTIONAL. Give informational message.
;       plot -        OPTIONAL. Plots results.
;       max_err -     OPTIONAL. Maximun allowable error. DFLT = 25 nT
;
; CALLING: 
;       fit = ff_magfit(mag)
;
; OUTPUT: fit.
;
; INITIAL VERSION: REE/RJS/KRB 97-10-20 - see UCLA_MAG_DESPIN, FF_XYMAGFIX
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_magfit.pro	1.2     

function ff_magfit, mag, out=out, talk=talk, max_err=max_err, plot=plot

IF keyword_set(talk) then BEGIN
    tstrt   = systime(1)
    print, '-----'
    print, 'FF_MAGDC: Starting SIN fits ..."
ENDIF

; BREAKUP MAG INTO CONTINUOUS BUFFERS WITH SAME SAMPLE SPEED
if ptr_valid(mag.time(0)) then $
     fa_fields_bufs, *mag.time, 40, buf_starts=b_strt, buf_ends=b_stop $
else fa_fields_bufs,  mag.time, 40, buf_starts=b_strt, buf_ends=b_stop

; SET UP FOR LOOP
fvf = 1
IF keyword_set(out) then BEGIN
    if ptr_valid(mag.notch(0)) then (*mag.notch)(*) = 0 $
    else mag.notch(*) = 0
ENDIF

; FROM HERE ON, EVERYTHING LOOPS THROUGH GOOD CONTINUOS STRETCHES
FOR i=0, n_elements(b_strt)-1 DO BEGIN

    ; EXTRACT DATA
    IF ptr_valid(mag.time(0)) then BEGIN
        magx = double( (*mag.comp1)(b_strt(i):b_stop(i)) )
        magy = double( (*mag.comp2)(b_strt(i):b_stop(i)) )
        magz = double( (*mag.comp3)(b_strt(i):b_stop(i)) )
        time = (*mag.time)(b_strt(i):b_stop(i)) - (*mag.time)(b_strt(i))
    ENDIF ELSE BEGIN
        magx = double( mag.comp1(b_strt(i):b_stop(i)) )
        magy = double( mag.comp2(b_strt(i):b_stop(i)) )
        magz = double( mag.comp3(b_strt(i):b_stop(i)) )
        time = mag.time(b_strt(i):b_stop(i)) - mag.time(b_strt(i))
    ENDELSE
    if ptr_valid(mag.time(0)) then t_start = (*mag.time)(b_strt(i)) $
    else t_start = mag.time(b_strt(i))
    
    ; CALCULATE ZERO CROSSINGS
    phase = ff_phase_zc(time, magx, period=ave_per)

    IF (n_elements(phase) GT 40) THEN BEGIN
        ff_qfit,magx,phase, phsf=phsf, es=es,ec=ec,zero=zero, $
            /do_sigma, sigma=sigma, out=out, bad_pts=bad_x, max_err=max_err

        fit_valid = 1
        npts = n_elements(ec)
        IF n_elements(sigma) ne npts AND finite(ec(0)) then BEGIN
            print, "FF_QFIT: Trouble! Report to RJS/REE/KB: SIGMA ERROR."
            fit_valid = 0
        ENDIF

        IF finite(ec(0)) AND fit_valid THEN BEGIN
            if (fvf) then xs   = es    else xs   =[xs  ,es  ]
            if (fvf) then xc   = ec    else xc   =[xc  ,ec  ]
            if (fvf) then x0   = zero  else x0   =[x0  ,zero]
            if (fvf) then xsig = sigma else xsig =[xsig,sigma]

            ff_qfit,magy,phase, phsf=phsf, es=es,ec=ec,zero=zero, $
                /do_sigma, sigma=sigma, out=out, bad_pts=bad_y, max_err=max_err

            if (fvf) then ys   = es    else ys   =[ys  ,es  ]
            if (fvf) then yc   = ec    else yc   =[yc  ,ec  ]
            if (fvf) then y0   = zero  else y0   =[y0  ,zero]
            if (fvf) then ysig = sigma else ysig =[ysig,sigma]

            ff_qfit,magz,phase, phsf=phsf, es=es,ec=ec,zero=zero, $
                /do_sigma, sigma=sigma, out=out, bad_pts=bad_z, max_err=max_err

            if (fvf) then zs   = es    else zs   =[zs  ,es  ]
            if (fvf) then zc   = ec    else zc   =[zc  ,ec  ]
            if (fvf) then z0   = zero  else z0   =[z0  ,zero]
            if (fvf) then zsig = sigma else zsig =[zsig,sigma]

            if (fvf) then pfit = phsf  else pfit =[pfit ,phsf]
            if (fvf) then buf  = bytarr(npts)+i else buf =[buf,bytarr(npts)+i]
            temp = ff_interp(phsf, phase, time) + t_start
            if (fvf) then tfit = temp  else tfit =[tfit ,temp]

            fvf = 0

            IF keyword_set(out) then BEGIN
                notch = bytarr(n_elements(time)) + 1
                if(bad_x(0) GE 0) then notch(bad_x) = 0
                if(bad_y(0) GE 0) then notch(bad_y) = 0
                if(bad_z(0) GE 0) then notch(bad_z) = 0
                if ptr_valid(mag.notch(0)) then $
                    (*mag.notch)(b_strt(i):b_stop(i)) = notch $
                else  mag.notch (b_strt(i):b_stop(i)) = notch
            ENDIF ; KEYWORD_SET OUT

        ENDIF ELSE if keyword_Set(talk) then $ ; END FIT VALID
        print, "FF_QFIT: Cannot fit segment:",i, "out of", n_elements(b_strt)

    ENDIF ; N_ELEMENTS(PHASE) GT 40

ENDFOR ; END LOOP THROUGH BUFFERS

if (fvf) then fit = {valid:0, npts:0} else $

    fit = {valid:1, npts: n_elements(xc), $
           xs: xs, xc: xc, x0: x0, xsig: xsig, $
           ys: ys, yc: yc, y0: y0, ysig: ysig, $
           zs: zs, zc: zc, z0: z0, zsig: zsig, $
           phs: pfit, time: tfit, buf: buf}

if keyword_set(talk) then $
print, 'FF_MAGDC: SIN fits complete. Run time =', systime(1)-tstrt, ' seconds.'

IF keyword_set(plot) then BEGIN
    wi, plot-1
    !p.multi = [0,1,3,0,0]
    !p.psym = 3
    plot, fit.time-fit.time(0), fit.xsig, yran=[-50,50], charsize=1.5, $
         xran=[0,8000]
    oplot, fit.time-fit.time(0), fit.x0/4.0, col=1
    oplot, fit.time-fit.time(0), fit.xc/1000.0, col=5
    oplot, fit.time-fit.time(0), fit.xs/4.0, col=3
    xyouts, 500, -35,'WHITE    - X SIGMA', charsize=1.25     
    xyouts, 500, -50,'MAGENTA - X ZERO LEVEL / 4', charsize=1.25     
    xyouts, 4000, -35,'LT BLUE  - X SIN / 4', charsize=1.25     
    xyouts, 4000, -50,'YELLOW  - X COS / 1000', charsize=1.25     
    xyouts, 3250, 63,'FF_MAGFIT RESULTS', charsize=1.25     
    xyouts, 7000, 40,'X FITS', charsize=1.50, col=4     

    plot, fit.time-fit.time(0), fit.ysig, yran=[-50,50], charsize=1.5, $
         xran=[0,8000]
    oplot, fit.time-fit.time(0), fit.y0/4.0, col=1
    oplot, fit.time-fit.time(0), fit.yc/4.0, col=5
    oplot, fit.time-fit.time(0), -fit.ys/1000.0, col=3
    xyouts, 500, -35,'WHITE    - Y SIGMA', charsize=1.25     
    xyouts, 500, -50,'MAGENTA - Y ZERO LEVEL / 4', charsize=1.25     
    xyouts, 4000, -35,'LT BLUE  - -Y SIN / 1000', charsize=1.25     
    xyouts, 4000, -50,'YELLOW  - Y COS / 4', charsize=1.25     
    xyouts, 7000, 40,'Y FITS', charsize=1.50, col=4    

    plot, fit.time-fit.time(0), fit.zsig, yran=[-50,50], charsize=1.5, $
         xran=[0,8000]
    oplot, fit.time-fit.time(0), fit.z0/100, col=1
    oplot, fit.time-fit.time(0), fit.zc/2.0, col=5
    oplot, fit.time-fit.time(0), fit.zs/2.0, col=3
    xyouts, 500, -35,'WHITE    - Z SIGMA', charsize=1.25     
    xyouts, 500, -50,'MAGENTA - Z ZERO LEVEL / 100', charsize=1.25     
    xyouts, 4000, -35,'LT BLUE  - Z SIN / 2', charsize=1.25     
    xyouts, 4000, -50,'YELLOW  - Z COS / 2', charsize=1.25     
    xyouts, 7000, 40,'Z FITS', charsize=1.50, col=4     

    !p.multi = 0
    !p.psym = 0
    wshow, /icon
    wset,0
    plot=plot+1
ENDIF



return, fit

END
