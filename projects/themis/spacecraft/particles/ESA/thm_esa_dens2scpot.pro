;Helper function to calculate electron/ion density for bisection
Function Density_fraction, scp, _extra = _extra

  em0 = moments_3d(_extra.edat,sc_pot=scp,/dens_only)
  im0 = moments_3d(_extra.idat,sc_pot=scp,/dens_only)
  If(em0.density Gt 0 And im0.density Gt 0) Then Begin
     fraction = em0.density/im0.density
  Endif Else Begin
     fraction = 0.0
  Endelse
  Return, fraction-1.0          ;Zero is the good answer here
End
;Helper function to calculate electron/ion density for bisection
;Uses n_3d_new.pro for density calculations
Function Density_fraction_n3dnew, scp, _extra = _extra


;for using n_3d_new, the scpot value has to be set in the input
;structure
  ee = _extra.edat & ee.sc_pot = scp
  em0 = n_3d_new(ee)
  ie = _extra.idat & ie.sc_pot = scp
  im0 = n_3d_new(ie)

  If(em0 Gt 0 And im0 Gt 0) Then Begin
     fraction = em0/im0
  Endif Else Begin
     fraction = 0.0
  Endelse
  Return, fraction-1.0 ;Zero is the good answer here
End
  
;+
;NAME:
; rtbis
;PURPOSE:
; Simple bisection routine, 
;CALLING SEQUENCE:
; x = rtbis(func_in, x1, x2, xacc=xacc, jmax=jmax)
;INPUT:
; func_in = an input function -- the answer will give func_in(x) = 0.0
; x1 = a lower limit
; x2 = an upper limit
;KEYWORDS:
; xacc = the accuracy, default is 1.0e-6
; jmax = max. number of iterations, the default is 40
;HISTORY:
; Copied from Numerical Recipies, 12-feb-2015, jmm,
; jimm@ssl.berkeley.edu
;-
Function rtbis, func_in, x1, x2, xacc=xacc, jmax=jmax, _extra = _extra

  If(keyword_set(xacc)) Then xacc0 = xacc Else xacc0 = 1.0e-6
  If(keyword_set(jmax)) Then jmax0 = jmax Else jmax0 = 400

  fmid = call_function(func_in, x2, _extra=_extra)
  f = call_function(func_in, x1, _extra=_extra)

  If(f*fmid Gt 0) Then Begin
     message, /info, 'Zero Value not Bracketed'
     Return, !values.f_nan
  Endif

  If(f lt 0) Then Begin
     x = x1 & dx = x2-x1
  Endif Else Begin
     x = x2 & dx = x1-x2
  Endelse
  
  For j = 0, jmax0-1 Do Begin
     dx = dx*0.5
     xmid = x+dx
     fmid = call_function(func_in, xmid, _extra=_extra)
;     print, xmid, fmid
     If(fmid le 0) Then x = xmid
     If(abs(dx) lt xacc0 Or fmid Eq 0) Then Return, x
  Endfor

  message, /info, 'Used: '+string(jmax0)+' Bisections; DX='+string(dx)
  Return, x
End
;+
;NAME:
; thm_esa_dens2scpot
;CALLING SEQUENCE:
; scpot = thm_esa_dens2scpot(edat, idat)
;PURPOSE:
; Estimates the SC potential from electrona and ions, by choosing the
; potential that gives ion density = electron density
;INPUT:
; edat = 3d data electron structure filled by themis routines get_th?_p???
; idat = 3d data ion structure filled by themis routines get_th?_p???
; use_n3dnew = if set, use n_3d_new.pro to get densities
;KEYWORDS:
;HISTORY:
; 2023-02-01, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-02-06 15:08:13 -0800 (Mon, 06 Feb 2023) $
; $LastChangedRevision: 31478 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_dens2scpot.pro $
;
;-
Function thm_esa_dens2scpot, edat, idat, use_n3dnew = use_n3dnew, $
                             _extra = _extra

  If(~is_struct(edat) || edat.valid eq 0) Then Begin
     dprint, dlevel = 4, 'Invalid Electron Data'
     Return, -1
  Endif

  If(~is_struct(idat) || idat.valid eq 0) Then Begin
     dprint, dlevel = 4, 'Invalid Ion Data'
     Return, -1
  Endif

  scplo = min(edat.energy[where(edat.energy Gt 0)])
  scphi = 100.0
;If ion density is higher than electron density, then use the lower
;limit, or if we get a bad result
  If(keyword_set(use_n3dnew)) Then Begin
     tmp_dens_lo = density_fraction_n3dnew(scplo, _extra = {edat:edat, idat:idat})
     If(tmp_dens_lo Lt 0.0) Then Return, scplo
;If Electron density is higher even at 100 V, then return scphi
     tmp_dens_hi = density_fraction_n3dnew(scphi, _extra = {edat:edat, idat:idat})
     If(tmp_dens_hi Ge 0.0) Then Return, scphi
;Bisect for sc_potential 
     sc_pot_est = rtbis('density_fraction_n3dnew', scplo, scphi, _extra = {edat:edat, idat:idat})
  Endif Else Begin
     tmp_dens_lo = density_fraction(scplo, _extra = {edat:edat, idat:idat})
     If(tmp_dens_lo Lt 0.0) Then Return, scplo
;If Electron density is higher even at 100 V, then return scphi
     tmp_dens_hi = density_fraction(scphi, _extra = {edat:edat, idat:idat})
     If(tmp_dens_hi Ge 0.0) Then Return, scphi
;Bisect for sc_potential 
     sc_pot_est = rtbis('density_fraction', scplo, scphi, _extra = {edat:edat, idat:idat})
  Endelse
;A bad value will be NaN, return scplo
  If(~finite(sc_pot_est)) Then sc_pot_est = scplo
  
  Return, sc_pot_est

End
