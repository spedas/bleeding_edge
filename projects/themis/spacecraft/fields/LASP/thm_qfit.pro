;+
; FUNCTION: THM_QFIT,  data, phs, phsf=phsf, es=es, ec=ec, zero=zero,
;                  do_sigma=do_sigma, sigma=sigma,
;                  period=period, slide=slide, n_fitpts=n_fitpts, 
;                  out=out, max_err=max_err, bad_pts=bad_pts                 
;       
; PURPOSE: User unfriendly fit routine. 
;          NOTE: REQUIRES CONTINUOUS BUFFERS!
;          NOT FOR GENERAL USE. 
;
; INPUT: 
;       data -        REQUIRED. A DATA ARRAY -  NOT A STRUCTURE!
;                     RECOMMEND: dat_in does not have NANS. One nan
;                                may destroy entire period.
;       phs -         REQUIRED. An array of phases.
;                     IMPORTANT! All phases must be valid! No NANs!
;
; KEYWORDS: 
;       period   -    INPUT. Fit period. DEFAULT = 4pi
;       slide    -    NO LONGER AN OPTION!
;                     NOTE: Slide will be forced to be pi/2.
;       n_fitpts -    INPUT. Number of points per fit. DEFAULT = 64.
;       do_sigma -    OPTION. /do_sigma fills sigma.
;       out      -    OPTION. /out fills bad_pts.
;                     NOTE: FOR OUTLYER REJECTION, SEE BELOW!
;       max_err  -    INPUT. Maximum allowable error of bad_pts. DEFAULT=25 nT
;
; OUTPUT: 
;       phsf    -     OUTPUT. Phase of fit -> Time of fit.
;       es      -     OUTPUT. Sin phase of fit.
;       ec      -     OUTPUT. Cos phase of fit.
;       zero    -     OUTPUT. Zero level of fit.
;       sigma   -     OUTPUT. Deviation in nT. Only filled if /do_sigma
;       bad_pts -     OUTPUT. Deviation in nT. Only filled if /out
;
; CALLING: 
;       SEE ff_magdc for an example. MUST USE fa_fields_bufs, and 
;       ff_zero_crossing first.
;
; OUT-LYING POINTS REJECTION: 
;       The program must be iterated. For example, below shows one interation:
;
;       ff_qfit,data,phs,phsf=phsf,es=es,ec=ec,zero=zero,/out, bad_pts=bad_pts
;       data(bad_pts) = !values.f_nan
;       index = where(finite(data), n_index)
;       IF n_index GT 0 then BEGIN
;           data = data(index)
;           phs  = phs(index)
;           ff_qfit,data,phs,phsf=phsf,es=es,ec=ec,zero=zero
;       ENDIF ELSE print, "Big trouble! No valid points."
;
; HISTORY: 
;   INITIAL VERSION: REE 97-10-05
;   Space Sciences Lab, UCBerkeley
;   2011-05-20: Added the keyword FAIL. 
;         Jianbao Tao (JBT), CU/LASP.
; 
;
; 
;-
pro thm_qfit, data, phs, phsf=phsf, es=es, ec=ec, zero=zero, $
             do_sigma=do_sigma, sigma=sigma, $
             period=period, slide=slide, n_fitpts=n_fitpts, $
             out=out, max_err=max_err, bad_pts=bad_pts, $
             fail = fail

fail = 0

two_pi    = 2.d*!dpi
pi_over_2 = !dpi/2.d
ec        = !values.d_nan  ; ERROR MARKER

; CHECK KEYWORDS
if not keyword_set(period) then period = 2.d*two_pi $
ELSE BEGIN 
    period = double(long(period/two_pi + 0.0001)) * two_pi
    if period LT two_pi then period = two_pi
ENDELSE
n_per =  long(period/two_pi + 0.0001)
if not keyword_set(n_fitpts) then n_fitpts = 64 
n_fitpts = long( n_fitpts/(n_per*4) ) * n_per*4
if (n_fitpts LT n_per*4) then n_fitpts = n_per*4
n_slide = n_fitpts/(n_per*4)


; START BY CHECKING INPUTS.
; CHECK PHS.
npts = n_elements(phs)
IF npts LT 4 then BEGIN
    dprint, "STOPPED!"
    dprint, "Need to give phase array."
    fail = 1
    return
ENDIF

IF size(/type,phs) NE 5 then BEGIN
    dprint, 'STOPPED! '
    dprint, 'Phs must be double array.'
    fail = 1
    return
ENDIF

IF phs(0) LT 0 THEN BEGIN
    n_skip = long( abs(phs(0)) / two_pi ) + 1l
    phs  = phs + n_skip*two_pi
    phs0 = n_skip*two_pi
ENDIF ELSE phs0 = 0

; CHECK DAT.
dat_type = size(/type,data)
IF dat_type gt 5 or dat_type lt 1 then BEGIN
    dprint, 'STOPPED! '
    dprint, 'Dat byte, int, long, float, or double array.'
    fail = 1
    return
ENDIF
IF n_elements(data) NE npts then BEGIN
    dprint, "STOPPED!"
    dprint, "Data and phase must have the same number of points."
    fail = 1
    return
ENDIF

; CREATE TEMPORARY FIT ARRAY.
max_nfit = long( (phs(npts-1) - phs(0))/pi_over_2 + 9 )
qfit = dblarr(max_nfit)*!values.d_nan
base = dblarr(max_nfit)*!values.d_nan
phsf = dblarr(max_nfit)

; SET UP BASIS FUNCTION MATRIX A
;fix_phs = dindgen(n_fitpts)*n_per*two_pi/n_fitpts $
;    - n_per*two_pi/2.d + n_per*!dpi/n_fitpts
d_phs      = period/(n_fitpts*2)                  ; d_phs needed to detrend!
fix_phs_sm = dindgen(n_fitpts)*period/n_fitpts + d_phs
fix_cos    = cos(fix_phs_sm)


; MAKE UP FIXED PHASE ARRAY
phs_zero    = phs(0) - ( phs(0) mod pi_over_2 ) + pi_over_2 + d_phs
phs_end     = phs(npts-1) - ( phs(npts-1) mod pi_over_2 ) + d_phs
n_phases    = long( (phs_end - phs_zero) * n_fitpts / period + 0.0001)
fix_phs     = dindgen(n_phases)*period/n_fitpts + phs_zero

; DETERMINE WHICH PHASE QUADRANT WE ARE IN
phs_quad    = ( phs(0) / pi_over_2 ) + 1.001
n_quad      = (long(phs_quad) mod 4)

; FORCE THE DATA TO MATCH THE FIXED PHASE ARRAY.
fix_dat  = interpol(data,phs,fix_phs, /spline)
fix_strt = 0l
fix_end  = long(n_fitpts-1)
nfits       = 0l

; LOOP THROUGH THE BUFFER
WHILE fix_end LT n_phases DO BEGIN

    ; DO THE QUICK FIT!
    qfit(nfits) = total( fix_dat(fix_strt:fix_end) * fix_cos ) * 2.d / n_fitpts 
    base(nfits) = total( fix_dat(fix_strt:fix_end) ) / n_fitpts
    phsf(nfits) = fix_phs(fix_strt) + period/2.0
    nfits       = nfits + 1
    fix_strt    = fix_strt + n_slide
    fix_end     = fix_end  + n_slide

ENDWHILE

; STOP HERE IF THERE ARE NOT ENOUGH FITS
if nfits LT 5 then begin
   dprint, 'nfits = ', nfits
   dprint, 'Not enough fits. Exiting...'
    fail = 1
   return
endif

; EXTRACT THE DATA - THIS IS A TRUE BRAIN TWISTER - TALK TO REE TO MODIFY
kerz  = [0.125d, 0.25d, 0.25d, 0.25d, 0.125d]
kers  = [0.5d, 0.5d]

; EXTRACT COS FITS
di     = n_quad mod 2				; di = 1 is odd case.
n_ec   = (nfits+1-di)/2
index  = lindgen(n_ec)             		; INDEX IS UNIFORM
sgn    = (index mod 2) * 2 - 1 			; sgn is actually -sgn
if (n_quad EQ 0 OR n_quad EQ 3) then sgn = -sgn ; Flip if first COS is 0
ec     = double( qfit(index*2 + di) ) * sgn	; COS is even qfits
n_ec   = (nfits+1-di)/2

; EXTRACT OFFSETS - Keeps edges correct.
base   = [base(2), base(3), base(0:nfits-1), base(nfits-4), base(nfits-3)] 
base   = convol(base,kerz, /edge_t) 
zero   = base(index*2 + di + 2)			; See edge correction.

; EXTRACT PHASES
phsf   = phsf(index*2 + di) - d_phs  ; STILL NEED TO SUBTRACT phs0!

; EXTRACT SIN FITS
n_es   = (nfits+di)/2
index  = lindgen(n_es) 		               	; INDEX IS UNIFORM
sgn    = (index mod 2) * 2 - 1 			; sgn is actually -sgn
if (n_quad EQ 0 OR n_quad EQ 1) then sgn = -sgn ; Flip if first SIN is 1
es     = double( qfit(index*2 + 1 - di) ) * sgn  ; SIN is the odd qfits

; BELOW IS A BLOODY MESS TO AVERAGE SIN TO PROPER ARRAY SIZE
if (n_es LT n_ec) then es = [es,es(n_es-1)]
if (di EQ 1) AND (n_es EQ n_ec) then es = [es,es(n_es-1)]
es     = convol(es,kers, /edge_t)		; AVERAGE PAIRS
if (n_es GT n_ec) then es = es(1:n_es-1)
if (di EQ 1) AND (n_es EQ n_ec) then es = es(1:n_es)

; WE ARE DONE EXCEPT FOR OUT-LYING ERRORS AND SIGMA
if NOT keyword_set(max_error) then max_error=25.d ; nT 

; CHECK FOR do_sigma or out
IF keyword_set(do_sigma) or keyword_set(out) then BEGIN

    ; SET UP ARRAYS FOR SIGMA AND OUT
    z_big   = interpol(zero,phsf,fix_phs)
    c_big   = interpol(ec,phsf,fix_phs)
    s_big   = interpol(es,phsf,fix_phs)
    fit_big = z_big + c_big * cos(fix_phs) + s_big * sin(fix_phs)

    strt   = phsf(0) - period/2.0 + d_phs
    index  = where(abs(fix_phs-strt) LT d_phs, n_index)

    IF ( n_index EQ 1 AND keyword_set(do_sigma) ) then begin
        sigma  = dblarr(n_ec)
        strt   = index(0)
        stop   = strt + n_fitpts - 1
        FOR i    = 0L, n_ec-1 DO BEGIN
            dif      = fit_big(strt:stop)-fix_dat(strt:stop)
            sigma(i) = sqrt( total(dif*dif) / (n_fitpts-3) )
            strt     = strt + n_slide*2
            stop     = stop + n_slide*2
        ENDFOR
    ENDIF

    IF keyword_set(out) then BEGIN

        ; EXPAND FIX_PHS TO COVER ALL DATA
        append_low  = fix_phs(0:2*n_fitpts-1)                 - 2.d*period
        append_high = fix_phs(n_phases-2*n_fitpts:n_phases-1) + 2.d*period
        fix_phs     = [append_low,fix_phs,append_high]

        ; SET UP ARRAYS FOR SIGMA AND OUT
        z_big   = interpol(zero,phsf,fix_phs)
        c_big   = interpol(ec,phsf,fix_phs)
        s_big   = interpol(es,phsf,fix_phs)
        fit_big = z_big + c_big * cos(fix_phs) + s_big * sin(fix_phs)

        fit_big = interpol(fit_big,fix_phs, phs, /spline)
        bad_pts = where(abs(data-fit_big) GT max_error)

    ENDIF
ENDIF ; End of out and do_sigma options.

; FIX PHASES
phs  = phs  - phs0
phsf = phsf - phs0
return

END

