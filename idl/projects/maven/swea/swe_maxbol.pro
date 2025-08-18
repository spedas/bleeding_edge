;+
;PROCEDURE:   swe_maxbol
;PURPOSE:
;  Maxwell-Boltzmann distribution for fitting SWEA electron energy spectra.
;  The reference frame is at the instrument aperture, after the electrons
;  have been accelerated by the spacecraft potential.
;
;  Correction for spacecraft potential, but no correction for bulk flow.
;
;  Units are energy flux [eV/cm2-sec-ster-eV].
;
;USAGE:
;    eflux = swe_maxbol(E, par=p)
;
;INPUTS:
;
;    E:             Measured energy [eV].
;
;KEYWORDS:
;
;    PARAM:         Parameter structure.
;
;                   p = {n    :    1.0d  , $   ; core density [cm-3]
;                        T    :   10.0d  , $   ; core temperature [eV]
;                        k_n  :    0.0d  , $   ; halo density [cm-3]
;                        k_vh : 4000.0d  , $
;                        k_k  :    5.0d  , $
;                        pot  :    0.0d     }  ; spacecraft potential [V]
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-09-22 09:25:06 -0700 (Mon, 22 Sep 2014) $
; $LastChangedRevision: 15831 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_maxbol.pro $
;
;CREATED BY:    David L. Mitchell  03-29-13
;FILE: swe_maxbol.pro
;-
function swe_maxbol, E, parameters=p

  if not keyword_set(p) then begin
     p = {n    :    4.0d  , $   ; core density (cm-3)
          T    :   10.0d  , $   ; core temperature (eV)
          k_n  :    0.0d  , $   ; halo density (cm-3)
          k_vh : 4000.0d  , $
          k_k  :    5.0d  , $
          pot  :    0.0d     }  ; spacecraft potential (V)
    return, p
  endif

  mass = 5.6856297d-06          ; electron rest mass [eV/(km/s)^2]
  c1 = (mass/(2D*!dpi))^1.5
  c2 = (2d5/(mass*mass))

; Core distribution (Maxwell Boltzmann) [eV/cm2-sec-ster-eV]

  eflux = p.n * c1 * (E*E*c2) * exp(-(E - p.pot)/p.T) / (p.T^1.5)

; Halo distribution (kappa)

  if (p.k_n gt 0.) then begin
    vtot2 = 2D*(E - p.pot)/mass
    vh2 = (p.k_k-1.5)*p.k_vh^2
    kc = (!dpi*vh2)^(-1.5) * factorial(p.k_k)/gamma(p.k_k-.5)
    kf = p.k_n * kc * (E*E*c2) * (1+(vtot2/vh2))^(-p.k_k-1) 
    eflux = eflux + kf
  endif

  return, eflux

end
