;FUNCTION: THM_LSP_FIX_AXIAL, t, Ez, Eder, AxPoly=AxPoly, fmerge=fmerge, talk=talk
;
;           NOT FOR GENERAL USE. CALLED BY THM_EFI...
;           ONLY FOR ISOLATED PARTICLE OR WAVE BURSTS
;           NOT FOR ENTIRE ORBIT.
;
;PURPOSE:
;    Remove SC potential from axial signal.
;
;INPUT:
;    t              -NEEDED. Time array for Ez
;    Ez             -NEEDED. Axial electric field
;    Eder           -NEEDED. Derived axial electric field
;
;KEYWORDS:
;    AxPoly        -OPTIONAL. Forces polynomial fit of order AxPoly. Default=0
;    fmerge        -OPTIONAL. Crossover frequency for merging Ez with Eder
;    talk          -OPTIONAL. Provides diagnostic plots.
;
;HISTORY:
;   2009-03-30: REE. 
;   2009-05-01: REE. Added merge option.
;   2009-05-04: REE. Added soft merge option.
;-

function thm_lsp_fix_axial, t, Ez, Eder, talk=talk, AxPoly=AxPoly, soft=soft, $
                            fmerge=fmerge, MergeRatio=MergeRatio, ratio=ratio


; FIND GOOD VALUES
ind = where(finite(Eder), nind)
IF nind EQ 0 then BEGIN
  print, 'THM_LSP_FIX_AXIAL: NO VALID ELEMENTS IN E_DERIVED.'
  print, 'THM_LSP_FIX_AXIAL: AXIAL FIX NOT POSSIBLE. Exiting...'
  return, Ez
ENDIF

tt  = t - t(0)
IF keyword_set(talk) then BEGIN
  !p.multi=[0,1,3]
  plot, tt, Ez, title= 'Ez AND Ederived', charsize=2, $
                     xtit = 'time(s)', ytit = 'Amplitude (mV/m)'
  oplot, tt, Eder, col=2
  plot, tt, Ez-Eder, title= 'Ez-Ederived AND Fit', charsize=2, $
                     xtit = 'time(s)', ytit = 'Amplitude (mV/m)'
ENDIF

; FIT DIFFERENCE BETWEEN EZ AND EDER
IF not keyword_set(AxPoly) then BEGIN
  A = ladfit(tt(ind), Ez(ind)-Eder(ind))
  Ezf  = Ez - A(0) - A(1)*tt
ENDIF ELSE BEGIN
  if AxPoly LT 0 then AxPoly=0
  if AxPoly GT 14 then AxPoly=14
  if AxPoly gt nind then AxPoly = nind
  A = poly_fit(tt(ind), Ez(ind)-Eder(ind), AxPoly)
  Ezf = Ez - poly(tt,A)
ENDELSE

IF keyword_set(talk) then BEGIN
  oplot, tt, poly(tt, A), col=4
  plot, tt, Ezf, title= 'Fixed Ez AND Ederived (AND Merged)', charsize=2, $
                  xtit = 'time(s)', ytit = 'Amplitude (mV/m)'
  oplot, tt, Eder, col=2
ENDIF

; # MERGE OPTION
IF keyword_set(fmerge) then BEGIN
  IF keyword_set(soft) then BEGIN
    if keyword_set(MergeRatio) then maxrat = MergeRatio else maxrat = 0.2d
    dt          = median(tt(1:*) - tt(0:*))
    Edum        = thm_lsp_filter(Eder, dt, 0.d, fmerge, /gaussian)
    Ezlow       = thm_lsp_filter(Ezf,  dt, 0.d, fmerge, /gaussian)
    Ezf         = Ezf - Ezlow                ; Ezf CONTAINS HIGH FREQUENCY
    ind         = where(finite(Edum))
    minrat      = min(ratio(ind))
    IF minrat GT maxrat then BEGIN
      print, 'THM_LSP_FIX_AXIAL: Soft merging ratios not correct. Using abrupt merge.'
      Ezlow(ind)  = Edum(ind)                  ; MERGE IN LOWPASS EDER
      Ezf         = Ezlow + Ezf                ; COMBINE LOW + HIGH
    ENDIF ELSE BEGIN
      Edum(ind) = 0
      alpha = ( ( (ratio < maxrat) - minrat) / (maxrat - minrat) ) > 0.d 
      Ezlow = Edum * alpha + Ezlow * (1.0d - alpha)   ; MERGE IN LOWPASS EDER
      Ezf         = Ezlow + Ezf                       ; COMBINE LOW + HIGH
    ENDELSE
  ENDIF ELSE BEGIN  ; ABRUPT MERGE
    dt          = median(tt(1:*) - tt(0:*))
    Edum        = thm_lsp_filter(Eder, dt, 0.d, fmerge, /gaussian)
    ind         = where(finite(Edum))
    Ezlow       = thm_lsp_filter(Ezf, dt, 0.d, fmerge, /gaussian)
    Ezf         = Ezf - Ezlow                ; Ezf CONTAINS HIGH FREQUENCY
    Ezlow(ind)  = Edum(ind)                  ; MERGE IN LOWPASS EDER
    Ezf         = Ezlow + Ezf                ; COMBINE LOW + HIGH
  ENDELSE
ENDIF

if keyword_set(talk) then oplot, tt, Ezf, col=6
if keyword_set(talk) then !p.multi=0

return, Ezf
end

