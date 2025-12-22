;+
; PROCEDURE: FF_PDQFIT, dat, phs, coeff, phsf, m=m, funct=funct
;                         period=period, slide=slide,
;                         n_fitpts=n_fitpts, out=out
;       
; PURPOSE: Performs a crude, but very fast spin fit to the data.
;          Before calling this routine: 
;          (1) Notch the data with Bphase and/or Sphase.
;          (2) Recommend filtering the data to 5 Hz at 2-poles.
;
; INPUT: 
;       dat -         REQUIRED. A DATA ARRAY -  NOT A STRUCTURE!
;                     RECOMMEND: dat_in does not have NANS. One nan
;                                may destroy entire period.
;       phs -         REQUIRED. A DATA ARRAY -  NOT A STRUCTURE!
;                     IMPORTANT! PHS CANNOT HAVE NAN'S!
;
; OUTPUT: 
;	coeff  -        fltarr(N, M) for the N spin fits.
;       phsf   -        fltarr(N) Phase of fit.
;       See Also: KEYWORDS.
;
; KEYWORDS: 
;	M -	      INPUT. number of basis functions.  DEFAULT = 4
;	Funct -	      INPUT. Function which given array of phase returns vectors
;                     corresponding to the basis functions evaluated at each
;                     input phase.  Must accept input values of X (an array
;                     of phases) and M (the number of basis functions)
;                     and output an (nelements(X), M) element
;		      matrix containing the basis functions.  
;		      for M = 4, DEFAULT = ONE_PHI_COS_SIN
;		      for M = 6, DEFAULT = ONE_PHI_COS_SIN_PHICOS_PHISIN
;       period -      INPUT. Fit period. DEFAULT = 2pi
;       slide -       INPUT. Number of periods to slide. DEFAULT = 0.5.
;                     NOTE: Slide will be forced to be interger # of fit pnts.
;       n_fitpts -    INPUT. Number of points per fit. DEFAULT = 64.
;       out -         INPUT. outlier rejection mode. reject points with
;                     deviation greater than 1.2 + i*0.4 and iterate.
;                     NOT IMPLEMENTED YET
;       sigma -       OUTPUT. the sigma for each fit.
;
;
; CALLING: 
;       index = where(finite(your_data) AND finite(your_phase), n_finite)
;       IF (nfinite GT 0) then BEGIN
;           dat = your_data(index)
;           phs = your_phase(index)
;           ff_pdqfit,dat,phs,es=es, ec=ec, phsf=phsf, zero=zero
;       ENDIF
;
; ALTERNATIVE CALL: ff_pdqfit, dat, time, period = 5.0d, $
;                               es=es, ec=ec, phsf=phsf, zero=zero
;
;
; INITIAL VERSION: KRB 07-01-97
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
pro ff_pdqfit, dat, phs, coeff, phsf, m=m, funct=funct, $
      period=period, slide=slide, n_fitpts=n_fitpts, out=out, sigma=sigma

two_pi = 2.d*!dpi

; START BY CHECKING INPUTS.
; CHECK PHS.
npts = n_elements(phs)
IF npts LE 1 then BEGIN
    print, "FF_PDQFIT: STOPPED!"
    print, "Need to give phase array."
    return
ENDIF
IF data_type(phs) NE 5 then BEGIN
    print, 'FF_PDQFIT: STOPPED! '
    print, 'Phs must be double array.'
    return
ENDIF

; CHECK DAT.
dat_type = data_type(dat)
IF dat_type gt 5 or dat_type lt 1 then BEGIN
    print, 'FF_PDQFIT: STOPPED! '
    print, 'Dat byte, int, long, float, or double array.'
    return
ENDIF
IF n_elements(dat) NE npts then BEGIN
    print, "FF_PDQFIT: STOPPED!"
    print, "Data and phase must have the same number of points."
    return
ENDIF

; CHECK KEYWORDS
if not keyword_set(n_fitpts) then n_fitpts = 64 else n_fitpts = long(n_fitpts)
if not keyword_set(period) then period = two_pi else period = double(period)
if not keyword_set(slide) then slide = 0.5d else slide = double(slide)
n_slide = long(slide*n_fitpts+0.00001)
if n_slide LT 1 then n_slide = 1
if not keyword_set(M) then M = 4
if not keyword_set(funct) then BEGIN
    IF M EQ 4 then funct='ONE_PHI_COS_SIN' $
    ELSE IF M EQ 6 then funct='ONE_PHI_COS_SIN_PHICOS_PHISIN' $
    ELSE BEGIN
        print, 'FF_PDQFIT: STOPPED! '
        print, 'no default funct for given M'
        return
    ENDELSE
ENDIF

; LOCATE GAPS LARGER THAN ONE PERIOD.
fa_fields_bufs, phs, delt=period, buf_starts=strt, buf_ends=stop
nbufs = n_elements(strt)

; CREATE OUTPUT ARRAYS.
max_nfit = long( (phs(npts-1) - phs(0))/period + nbufs + 1 )/slide
coeff = dblarr(max_nfit, M)
phsf = dblarr(max_nfit)
nfits = 0

dosigma = 1
if not keyword_set(sigma) then dosigma = 0
sigma = dblarr(max_nfit)

; SET UP BASIS FUNCTION MATRIX A
fix_phs = dindgen(n_fitpts*2)*two_pi/n_fitpts
z = execute('a='+funct+'(fix_phs,m)')
if z ne 1 then begin
    message, 'Error calling user funct: ' + funct
endif

nfit = n_fitpts/n_slide
sw = fltarr(m,nfit)
su = fltarr(n_fitpts,m,nfit)
sv = fltarr(m,m,nfit)
; DO SVD DECOMP for each slide phase, NOW
for i = 0, nfit-1 DO BEGIN
    
    svd, a(i*n_slide:i*n_slide+n_fitpts-1, *), w, u, v
    sw(*,i) = w
    su(*,*,i) = u
    sv(*,*,i) = v
ENDFOR

; LOOP THROUGH THE CONTINUOUS BUFFERS.
FOR i = 0, nbufs-1 DO BEGIN
    
    ; MAKE UP FIXED PHASE ARRAY
    phs_zero    = phs(strt(i)) - ( phs(strt(i)) mod period )
    phs_end     = phs(stop(i)) - ( phs(stop(i)) mod period ) + period
    phs_stretch = phs_end - phs_zero
    nsegs       = long( phs_stretch / period + 0.0001)
    fix_phs     = dindgen(nsegs*n_fitpts)*period/n_fitpts + phs_zero

    ; FORCE THE DATA TO MATCH THE FIXED PHASE ARRAY.
    fix_dat = ff_interp(fix_phs,phs,dat,delt=period/4.0, /spline)
    fix_strt = 0l
    fix_end  = long(n_fitpts-1)

    ; LOOP THROUGH THE BUFFER, INCREMENTING BY N_SLIDE.
    WHILE fix_end LT nsegs*n_fitpts DO BEGIN
        temp = fix_dat(fix_strt:fix_end) 
        ref_strt = fix_strt mod n_fitpts
        ref_end  = ref_strt + n_fitpts - 1
        f = ref_strt/n_slide

                                ; DO THE QUICK FIT!
        svbksb,su(*,*,f), sw(*,f), sv(*,*,f), temp, cof
        coeff(nfits, *) = cof
        phsf(nfits)  = fix_phs(fix_strt) + period/2.0
        if dosigma then BEGIN
            dif = a(ref_strt:ref_end, *)#cof - temp
            sigma(nfits) = sqrt(total(dif*dif)/(n_elements(temp)-M))
        ENDIF
        
        nfits = nfits + 1
  
        fix_strt = fix_strt + n_slide
        fix_end  = fix_end  + n_slide

    ENDWHILE
ENDFOR

coeff = float(coeff(0:nfits,*))
phsf = phsf(0:nfits-1) 

return

END

FUNCTION ONE_PHI_COS_SIN,X,M   ; M IS IGNORED
a = dblarr(n_elements(x), 4)
a(*, 0) = 1
a(*, 1) = x
a(*, 2) = cos(x)
a(*, 3) = sin(x)
return, a

END

FUNCTION ONE_PHI_COS_SIN_PHICOS_PHISIN,X,M   ; M IS IGNORED
a = dblarr(n_elements(x), 6)
a(*, 0) = 1
a(*, 1) = x
a(*, 2) = cos(x)
a(*, 3) = sin(x)
a(*, 4) = x*cos(x)
a(*, 5) = x*sin(x)
return, a

END


