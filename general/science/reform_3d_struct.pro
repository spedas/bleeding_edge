;+
;NAME:
;reform_3d_struct
;CALLING SEQUENCE:
;dat1 = reform_3d_struct(dat, reverse=reverse, nphi=nphi, ntheta=ntheta)
;PURPOSE:
;If a 3-d data structure has fromat (nenergy, nphi, ntheta) reform into (nenergy, nbins)
;For testing with older plot3d_new, edit3dbins code.
;Note that the input structure data, theta, phi have to be dimensioned nenergy,
;nphi, ntheta (as for MMS FPI data distributions), nenergy, ntheta, nphi give unpredictable
;results.
;INPUT:
;dat = a 3d structure, with data, etc, dimensions (nenrgy, nphi, ntheta)
;OUTPUT:
;dat1 = a new 3d structure, with data, etc, reformed to dimensions (nenrgy, nbins = nphi*ntheta), 
;       provided that ntheta*nphi = nbins.
;KEYWORDS: 
;reverse=if set, reverse the process, this allows you to call edit3dbins to get bin flags,
;        and then recover the original structure, But ntheta and nphi keywords must be set.
;        Do not call this on structures for which ntheta is not the same for all phi (e.g., 
;        THEMIS ESA data).
;nphi = the number of phi angles
;ntheta = the number of theta angles
;HISTORY:
;2018-01-08, jmm, jimm@ssl.berkeley.edu
;-
Function reform_3d_struct, dat0, reverse=reverse, nphi=nphi, ntheta=ntheta

dat = dat0
dtags = tag_names(dat)
ntags = n_elements(dtags)
If(keyword_set(reverse)) Then Begin
  If(~keyword_set(nphi) || ~keyword_set(ntheta)) Then Begin
    dprint, 'Both ntheta and nphi must be set for reverse option'
    return, dat
  Endif
  If(nphi*ntheta Ne dat.nbins)  Then Begin
    dprint, 'ntheta*nphi does not equal nbins for reverse option'
    return, dat
  Endif
  For j = 0, ntags-1 Do Begin
    temp = dat.(j)
    If(size(temp, /n_dimen) Eq 2) Then Begin
      szt = size(temp)
      nenergy = szt[1]
      temp = reform(temp, nenergy, nphi, ntheta)
      str_element, dat, dtags[j], temp, /add_replace
    Endif
  Endfor
Endif Else Begin
  For j = 0, ntags-1 Do Begin
    temp = dat.(j)
    If(size(temp, /n_dimen) Eq 3) Then Begin
      szt = size(temp)
      nenergy0 = szt[1]
      nphi0 = szt[2] & ntheta0 = szt[3]
      If(ntheta0*nphi0 Eq dat.nbins) Then Begin
        temp = reform(temp, nenergy0, dat.nbins)
        str_element, dat, dtags[j], temp, /add_replace
      Endif
    Endif
  Endfor
Endelse
Return, dat
End
    
    