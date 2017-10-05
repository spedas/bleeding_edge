;+
; Broken out of thm_scm_gainant_vec.pro for VM purposes, jmm,
; 2013-04-23
;$LastChangedBy: jimm $
;$LastChangedDate: 2013-04-23 11:43:46 -0700 (Tue, 23 Apr 2013) $
;$LastChangedRevision: 12137 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_scm_modpha.pro $
;-


Pro thm_scm_modpha, s, rm, rp
  COMPILE_OPT HIDDEN
;; from utilitylib.f90
;     ------------------------------------------------------------------
; *   Purpose: calculate the modulus and phase (degrees) of a complex nb.
; *   Classe : depouillement specifique GEOS/UBF
; *   Auteur : P. Robert, CRPE, 1977-1984
;     ------------------------------------------------------------------
;
;      complex s
;
;                    *********************
;
;
  rm = abs(s)

  rp = atan(s, /phase)
  rp = rp*!radeg

  return
end
