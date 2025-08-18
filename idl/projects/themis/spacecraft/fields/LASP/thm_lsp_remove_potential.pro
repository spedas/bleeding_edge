;FUNCTION: THM_LSP_REMOVE_POTENTIAL, te, Ez, tv, Vsc, Vpoly=Vpoly, $
;                                    peeb_t=peeb_t, talk=talk,, VscPole=VscPole
;
;           NOT FOR GENERAL USE. CALLED BY THM_EFI...
;           ONLY FOR ISOLATED PARTICLE OR WAVE BURSTS
;           NOT FOR ENTIRE ORBIT.
;
;PURPOSE:
;    Remove SC potential from axial signal.
;
;INPUT:
;    te             -NEEDED. Time array for Ex
;    Ez             -NEEDED. Axial electric field
;    tv             -NEEDED. Time array for Vsc
;    Vsc            -NEEDED. Spacecraft potential
;
;KEYWORDS:
;    Vsc            -NEEDED. Spacecraft potential
;
;HISTORY:
;   2009-03-30: REE. 
;   2009-05-01: REE. Added Vpoly and temeprature option.
;-

function thm_lsp_remove_potential, t, Ez, tv, Vsc, Vpoly=Vpoly, $
                                   peeb_t=peeb_t, talk=talk, VscPole=VscPole



; INTERPOLATE
vsci  = interpol(vsc, tv, t)

; SMOOTH
IF keyword_set(VscPole) then BEGIN
  dt = median(t(1:*) - t(0:*))
  nsVsc = round(1.0/(VscPole*dt))
  Vsci = thm_lsp_median_smooth(Vsci, nsVsc)
ENDIF

; GET ELECTRON TEMPERATURE IF SC IS SET
IF (size(/type,peeb_t) EQ 8) then BEGIN
  if not keyword_set(Vpoly) then Vpoly = 5
  eti = interpol(peeb_t.y, peeb_t.x, t)
  dum = vsci*sqrt(eti)
  A = poly_fit(dum, Ez, Vpoly)
  Ezf = Ez -  poly(dum, A)
  IF keyword_set(talk) then BEGIN
    plot, dum, Ez, psym=3, xtit = 'SC Potential * SQRT(Te)', ytit = 'Ez'
    oplot, dum, poly(dum, A), col = 2
  ENDIF
  return, Ezf
ENDIF
  
  
; DEFAULT - LINEAR FIT
; REMOVE VSC
if not keyword_set(Vpoly) then Vpoly = 2
A = poly_fit(vsci, Ez, Vpoly)
Ezf = Ez -  poly(vsci, A)

IF keyword_set(talk) then BEGIN
  plot, vsci, Ez, psym=3, xtit = 'Spacecraft Potential (V)', ytit = 'Ez'
  oplot, vsci, poly(vsci, A), col = 2
ENDIF  

return, Ezf
end


;OLD
;Eza  = Ez - average(Ez)
;Vsca = Vsc - average(Vsc)
;verr = total(Eza*Vsca)/total(Vsca*Vsca)
;Ezf = Eza - verr*Vsca



; DIAGNOSE
;tv = VscTemp.x
;vscF = interpol(vscF, tv, te)
;plot, vscf, Ez, psym=3
;A = poly_fit(vscf, Ez, 1)
;oplot, vscf, poly(vscf, A), col = 2
;Ezf = Ez -  poly(vscf, A)
;plot, vscf, Ezf, psym=3

;ind = where(eti GT 500)
;oplot, vsci(ind), Ez(ind), psym=3, col=6
