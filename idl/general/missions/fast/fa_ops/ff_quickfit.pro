;+
; PROCEDURE: FF_QUICKFIT, dat, phs, es=es, ec=ec, phsf=phsf, zero=zero,
;                         period=period, n_fitpts=n_fitpts 
;       
; PURPOSE: Performs a crude, but very fast spin fit to the data.
;          Before calling this routine: 
;          (1) Notch the data with Bphase and/or Sphase.
;          (2) Reccommend filtering the data to 5 Hz at 2-poles.
;
; INPUT: 
;       dat -         REQUIRED. A DATA ARRAY -  NOT A STRUCTURE!
;                     RECOMMEND: dat_in does not have NANS. One nan
;                                may destroy entire period.
;       phs -         REQUIRED. A DATA ARRAY -  NOT A STRUCTURE!
;                     IMPORTANT! PHS CANNOT HAVE NAN'S!
;
;
; KEYWORDS: 
;       es   -        OUTPUT. Sin phase of fit.
;       es   -        OUTPUT. Cos phase of fit.
;       tf   -        OUTPUT. Time of fit.
;       zero -        OUTPUT. Zero level of fit.
;       period -      INPUT. Fit period. DEFAULT = 2pi
;       slide -       INPUT. Number of periods to slide. DEFAULT = 0.5.
;                     NOTE: Slide will be forced to be integer # of fit pnts.
;       n_fitpts -    INPUT. Number of points per fit. DEFAULT = 64.
;
; CALLING: 
;       index = where(finite(your_data) AND finite(your_phase), n_finite)
;       IF (nfinite GT 0) then BEGIN
;           dat = your_data(index)
;           phs = your_phase(index)
;           ff_quickfit,dat,phs,es=es, ec=ec, phsf=phsf, zero=zero
;       ENDIF
;
; ALTERNATE CALL: ff_quickfit, dat, time, period = 5.0d, $
;                               es=es, ec=ec, phsf=phsf, zero=zero
;
; OUTPUT: See KEYWORDS.
;
; INITIAL VERSION: REE 97-03-29
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
pro ff_quickfit, dat, phs, es=es, ec=ec, phsf=phsf, zero=zero, $
                 period=period, slide=slide, n_fitpts=n_fitpts

two_pi = 2.d*!dpi

; START BY CHECKING INPUTS.
; CHECK PHS.
npts = n_elements(phs)
IF npts LE 1 then BEGIN
    print, "FF_QUICKFIT: STOPPED!"
    print, "Need to give phase array."
    return
ENDIF
IF data_type(phs) NE 5 then BEGIN
    print, 'FF_QUICKFIT: STOPPED! '
    print, 'Phs must be double array.'
    return
ENDIF

; CHECK DAT.
dat_type = data_type(dat)
IF dat_type gt 5 or dat_type lt 1 then BEGIN
    print, 'FF_QUICKFIT: STOPPED! '
    print, 'Dat byte, int, long, float, or double array.'
    return
ENDIF
IF n_elements(dat) NE npts then BEGIN
    print, "FF_QUICKFIT: STOPPED!"
    print, "Data and phase must have the same number of points."
    return
ENDIF

; CHECK KEYWORDS
if not keyword_set(n_fitpts) then $
  n_fitpts = 64 else $
  n_fitpts = long(n_fitpts)
if not keyword_set(period) then $
  period = two_pi else $
  period = double(period)
if not keyword_set(slide) then $
  slide = 0.5d else $
  slide = double(slide)
n_slide = long(slide*n_fitpts+0.00001)
if n_slide LT 1 then n_slide = 1

; LOCATE GAPS LARGER THAN ONE PERIOD.
fa_fields_bufs, phs, delt=period, buf_starts=strt, buf_ends=stop
nbufs = n_elements(strt)

; CREATE OUTPUT ARRAYS.
max_nfit = long( (phs(npts-1) - phs(0))/period + nbufs + 1 )/slide
es   = fltarr(max_nfit)
ec   = fltarr(max_nfit)
phsf = dblarr(max_nfit)
zero = fltarr(max_nfit)
nfits = 0

; SET UP SIN AND COS ARRAYS.
fix_phs = dindgen(n_fitpts*2)*two_pi/n_fitpts
fix_sin = sin(fix_phs)
fix_cos = cos(fix_phs)

; LOOP THROUGH THE CONTINUOUS BUFFERS.
FOR i = 0, nbufs-1 DO BEGIN
    
    ; MAKE UP FIXED PHASE ARRAY
    phs_zero    = phs(strt(i)) - ( phs(strt(i)) mod period )
    phs_end     = phs(stop(i)) - ( phs(stop(i)) mod period ) + period
    phs_stretch = phs_end - phs_zero
    nsegs       = long( phs_stretch / period + 0.0001)
    fix_phs     = dindgen(nsegs*n_fitpts)*period/n_fitpts + phs_zero

    ; FORCE THE DATA TO MATCH THE FIXED PHASE ARRAY.
    fix_dat = ff_interp(fix_phs,phs,dat,delt=period/4.0)
    fix_strt = 0l
    fix_end  = long(n_fitpts-1)

    ; LOOP THROUGH THE BUFFER, INCREMENTING BY N_SLIDE.
    WHILE fix_end LT nsegs*n_fitpts DO BEGIN
        temp = fix_dat(fix_strt:fix_end) 
        ref_strt = fix_strt mod n_fitpts
        ref_end  = ref_strt + n_fitpts - 1
        
        ; DO THE QUICK FIT!
        es(nfits) = total ( temp * fix_sin(ref_strt:ref_end) ) $
          * 2.d / n_fitpts 
        ec(nfits) = total (temp * fix_cos(ref_strt:ref_end) ) $
          * 2.d / n_fitpts 
        zero(nfits) = total (temp) / n_fitpts 
        phsf(nfits)  = fix_phs(fix_strt) + period/2.0
        nfits = nfits + 1
  
        fix_strt = fix_strt + n_slide
        fix_end  = fix_end  + n_slide

    ENDWHILE
ENDFOR

es   = float( es(0:nfits-1) )
ec   = float( ec(0:nfits-1) )
zero = float ( zero(0:nfits-1) )
phsf = phsf(0:nfits-1) 

return
END



     

