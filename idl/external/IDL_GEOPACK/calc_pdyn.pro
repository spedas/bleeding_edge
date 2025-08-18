;+
; PROCEDURE: calc_pdyn
;
; PURPOSE: This procedure calculates the solar wind dynamic pressure from proton speed and proton density, accounting for contributions from both
;          protons and alpha particles.  Previous SPEDAS code only accounted for protons.  OMNIweb provides a "Pressure" data set that assumes
;          f_alpha = N_a/N_p = 0.05, which according to Vassilis may be a little high.   This routine accepts an f_alpha parameter, whicb defaults to 0.04.
;
; 
;
; INPUTS:   
;           N_p: Solar wind ion density (rho) cm^-3
;           V_p: proton velocity (km/sec)
;;           
; Returns:
;           Dynamic pressure in units of nPa, suitable for passing to GEOPACK field models
;
; KEYWORDS:
;
;           speed(optional): set this if Vp_tvar is stored as a speed
;           
; Notes:
; Derivation of Alpha particle pressure correction is here: https://omniweb.gsfc.nasa.gov/ftpbrowser/bow_derivation.html

;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-28 18:16:15 -0700 (Wed, 28 Jul 2021) $
; $LastChangedRevision: 30156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/calc_pdyn.pro $
;-
function calc_pdyn,N_p=N_p,V_p=V_p,f_alpha=f_alpha
COMPILE_OPT idl2

den = N_p
spd = V_p

; Solar wind dynamic pressure (Pdyn parameter for GEOPACK)
; Previous version only accounted for contribution by protons, not alphas, and were not consistent (off by a factor of 1.2) with 
; OMNI pressure data.  
;
; Derivation of Alpha particle pressure correction is here: https://omniweb.gsfc.nasa.gov/ftpbrowser/bow_derivation.html
;
; JWL 2021-06-09

if n_elements(f_alpha) eq 0 then f_alpha=0.04D     ; Ratio of alphas to protons. OMNI assumes 5%; we'll use a sligtly lower default of 4%

alpha_correction = 1 + 4.0D * f_alpha   ;  4.0 = mass of alpha particle in AMU.  Assumes V_alpha = V_proton.

pram = alpha_correction * 1.667e-6*den*spd^2 ; 1.667e-6 = proton mass times unit conversions to give result in nPa

return, pram
end
