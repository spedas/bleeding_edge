;+
; FUNCTION: THM_LSP_REMOVE_SPINTONE, t, x, per, SpinPoly=SpinPoly, $
;                                    nsmooth=nsmooth, talk=talk
;
;           NOT FOR GENERAL USE. CALLED BY THM_EFI...
;           ONLY FOR ISOLATED PARTICLE OR WAVE BURSTS
;           NOT FOR ENTIRE ORBIT.
;
; PURPOSE: GETS RID OF SPIN TONE AND OFFSET ON MEDIUM SIZE STRETCHES
;
; INPUT: 
;    t             -NEEDED. Time array.
;    x             -NEEDED. Data array.
;    per           -NEEDED. Spin period. NOTE: input per/2 for 2nd harmonic, etc.
; 
; KEYWORDS: 
;                  -DEFAULT ACTION. If neither nsmooth or SpinPoly are set, sin  
;                                   and cos fits over entire period are used.
;    nsmooth       -OPTIONAL. If set, it takes precedence. It uses qfit 
;                             and "median smooth" sin and cos over
;                             nsmooth points.
;    SpinPoly      -OPTIONAL. If set (and nsmooth not set), it uses qfit         
;                             and polyfits sin and cos over nsmooth points.
;    
;    talk          -OPTIONAL. Plots diagnostics. 
;    fail          -OPTIONAL. If the removing fails, fail = 1. 
;                               Otherwise fail = 0. 
;
; OUTPUT: TPLOT STORE
;
; HISTORY: 
;   INITIAL VERSION: REE 99-03-25 (ff_remove_spintone)
;   Space Scienes Lab, UCBerkeley
;   MODIFICATION HISTORY: 
;   08-10-31 Modified for THEMIS by REE
;   University of Colorado
; 
;   2011-05-20: Added the keyword FAIL. 
;         Jianbao Tao (JBT), CU/LASP.
;
;-
function thm_lsp_remove_spintone, t, x, per, SpinPoly=SpinPoly, $
                                  nsmooth=nsmooth, talk=talk, fail = fail

fail = 0
tt = t - t(0)

; # DO MEDIAN SMOOTH FIT #
IF keyword_set(nsmooth) then BEGIN
  thm_qfit, x, tt * !dpi * 2.0 / per, phsf=phsf, ec=ec, es=es, $
    /do_sigma, sigma=sigma, fail = qfit_fail
  if qfit_fail gt 0 then begin
    dprint, 'THM_QFIT failed. NAN is returned.'
    fail = 1
    return, !values.d_nan
  endif
  tsc = phsf * per / (!dpi * 2.d)

  ; DIAGNOSTICS
  IF keyword_set(talk) then BEGIN
    ymax = max([es,ec,sigma])
    ymin = min([es,ec,sigma])
    plot, tsc, es, yran=[ymin, ymax], title='Spin Fits', xtit = 'Time (s)', $
      ytit = 'Amplitude'
    oplot, tsc, ec, col=2
  ENDIF  
  
  es = thm_lsp_median_smooth(es, nsmooth)
  ec = thm_lsp_median_smooth(ec, nsmooth)
  esi = interpol(es, tsc, tt)
  eci = interpol(ec, tsc, tt)
  xx = x - esi*sin(tt*2d*!dpi/per) - eci*cos(tt*2d*!dpi/per)

  ; DIAGNOSTICS
  IF keyword_set(talk) then BEGIN
    oplot, tsc, es, col = 6
    oplot, tsc, ec, col = 6
  ENDIF

  return, xx

ENDIF



; ## DO SIMPLE FIT ##
IF NOT keyword_set(SpinPoly) then BEGIN
  thm_efi_sin_fit, x, tt, es=es, ec=ec, per=per
  xx = x - es*sin(tt*2d*!dpi/per) - ec*cos(tt*2d*!dpi/per)
  return, xx
ENDIF



; ### DO HIGHER POLYFIT ###

; DO QUICK FIT
thm_qfit, x, tt * !dpi * 2.0 / per, phsf=phsf, ec=ec, es=es, $
  /do_sigma, sigma=sigma, fail = qfit_fail
if qfit_fail gt 0 then begin
  dprint, 'THM_QFIT failed. NAN is returned.'
  fail = 1
  return, !values.d_nan
endif

nfits = n_elements(es)

npoly = ((SpinPoly > 0) < 16)
;if npoly GT nfits then npoly=nfits
npoly <= nfits-1

; DO SIN
tsc = phsf * per / (!dpi * 2.d)
ind = findgen(nfits)  
As = poly_fit(tsc, es, npoly, measure=sigma)

; DO COS
nfits = n_elements(ec)
npoly <= nfits-1
ind = findgen(nfits)  
Ac = poly_fit(tsc, ec, npoly, measure=sigma)

;REMOVE SPINTONE
esi = interpol(poly(tsc, As), tsc, tt)
eci = interpol(poly(tsc, Ac), tsc, tt)
xx = x - esi*sin(tt*2d*!dpi/per) - eci*cos(tt*2d*!dpi/per)

; DIAGNOSTICS
IF keyword_set(talk) then BEGIN
  ymax = max([es,ec,sigma])
  ymin = min([es,ec,sigma])
  plot, tsc, es, yran=[ymin, ymax], title='Spin Fits', xtit = 'Time (s)', $
    ytit = 'Amplitude'
  oplot, tsc, ec, col=2
  oplot, tsc, sigma, col=4
  oplot, tsc, poly(tsc,As), col = 6
  oplot, tsc, poly(tsc,Ac), col = 6
ENDIF

return, xx

end




