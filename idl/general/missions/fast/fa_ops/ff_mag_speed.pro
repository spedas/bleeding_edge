;+
; PROCEEDURE: FF_MAG_SPEED, mag, fit=fit, ptr=ptr, min_streak=min_streak,
;                           plot=plot
;       
; PURPOSE: Routine determines sample speed in log2(smaples/s).
;          NOT FOR GENERAL USE! ACCEPTS PTR STRUCTURE.
;
;
; INPUT: 
;       mag -         REQUIRED. 'MagDC' data structure. MAY HAVE POINTERS!
;
; KEYWORDS: 
;      	fit -	      OPTIONAL. Fits from ff_magfit.
;      	ptr -	      OPTIONAL. DEFAULT = SAME. Adds a pointer to mag.
;      	min_streak -  OPTIONAL. DEFAULT = 40. Miniumun stretch of good
;                     data points in a valid buffer.
;      	plot -	      OPTIONAL. Plots the results.
;
; CALLING: 
;      ff_mag_speed, mag, fit=fit.
;
; OUTPUT: Adds structure elememt 'speed' to mag and fit.
;
; INITIAL VERSION: REE 97-10-20 - see UCLA_MAG_DESPIN, FF_XYMAGFIX
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
;       @(#)ff_mag_speed.pro	1.1     

pro ff_mag_speed, mag, fit=fit, ptr=ptr, min_streak=min_streak, talk=talk, $
                  plot=plot

; CHECK KEYWORDS
if ptr_valid(mag.time(0)) then is_ptr=1 else is_ptr=0
if not keyword_set(ptr) then ptr=is_ptr
if not keyword_set(min_streak) then min_streak=40
if mag.valid NE 1 then return

; BREAKUP MAG INTO CONTINUOUS BUFFERS WITH SAME SAMPLE SPEED
if ptr_valid(mag.time(0)) then $
     fa_fields_bufs, *mag.time, min_streak, buf_starts=b_strt, buf_ends=b_stop $
else fa_fields_bufs,  mag.time, min_streak, buf_starts=b_strt, buf_ends=b_stop

; SET UP FOR LOOP
speed = ptr_new(bytarr(mag.npts))
if keyword_set(fit) then if (fit.valid) then f_speed = bytarr(fit.npts)

; FROM HERE ON, EVERYTHING LOOPS THROUGH GOOD CONTINUOS STRETCHES
FOR i=0, n_elements(b_strt)-1 DO BEGIN

    ; DETERMINE SAMPLE TIME
    IF ptr_valid(mag.time(0)) then BEGIN
        dt = (*mag.time)(b_strt(i)+1) - (*mag.time)(b_strt(i))
    ENDIF ELSE BEGIN
        dt = mag.time(b_strt(i)+1) - mag.time(b_strt(i))
    ENDELSE
     
    smpl_per_s =  - alog(dt) / alog(2.0)
    smpl_per_s = byte(smpl_per_s + 0.5)

    (*speed)(b_strt(i):b_stop(i)) = smpl_per_s


    IF keyword_set(fit) then BEGIN
        if (fit.valid NE 1) then return
        ind = where(fit.buf EQ i, n_ind)
        if (n_ind GT 0) then f_speed(ind) =  smpl_per_s
    ENDIF

ENDFOR

if (is_ptr) then add_str_element, mag, 'speed', speed $
    else add_str_element, mag, 'speed', *speed
if keyword_set(fit) then if (fit.valid) then $
    add_str_element, fit, 'speed', f_speed

print, 'FF_MAG_SPEED: Sample speed added.'

IF keyword_set(plot) AND is_ptr then BEGIN
    wi, plot-1
    !p.multi=0
    !p.psym = 3
    plot, *mag.time-(*mag.time)(0), *mag.comp3, yran=[-8000,8000], $
          charsize=2.0, xtitle='TIME', ytitle = 'FITS', $
          title='FF_MAG_SPEED RESULTS'
    oplot, *mag.time-(*mag.time)(0), *mag.speed*1000.0 - 2000.0, col=1
    xyouts, 2000, -5000,'WHITE    - MAG Z', charsize=1.5     
    xyouts, 2000, -6000,'MAGENTA - LOG2 (MAG SPEED*1000 - 2000)', charsize=1.5
    xyouts, 2000, -7000,'MAGENTA/1000 - (FAST FIELDS SVY SPEED)', charsize=1.5
    !p.psym = 0
    wshow, /icon
    wset,0
    plot=plot+1
ENDIF



return
END

        
    
