;+
;FUNCTION: 
;	mvn_swe_sc_pospot
;
;PURPOSE:
;	Estimates the spacecraft potential from SWEA energy spectra.  The basic
;   idea is to look for a break in the energy spectrum (sharp change in flux
;   level and slope).  Works for one or more spectra.
; 
;AUTHOR: 
;	David L. Mitchell
;
;CALLING SEQUENCE: 
;	scpot = mvn_swe_sc_pospot(engy, eflux)
;
;INPUTS: 
;   engy:      Energy array with dimensions of [n_e] or [n_e, n_t].
;
;   eflux:     Energy flux, with dimensions of [n_e, n_t].
;
;KEYWORDS:
;   DIAG:      A structure of diagnostic information that provides the quality
;              of the potential estimates.
;
;OUTPUTS:
;   scpot:     An array of n_t spacecraft potentials.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-07-26 13:45:34 -0700 (Fri, 26 Jul 2024) $
; $LastChangedRevision: 32769 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_pospot.pro $
;
;-

function mvn_swe_sc_pospot, engy, eflux, diag=diag

  compile_opt idl2

  @mvn_scpot_com
  
  if (size(Espan,/type) eq 0) then mvn_scpot_defaults

  badphi = !values.f_nan

; Make sure engy and eflux arrays are compatible, get dimensions

  sz_f = size(eflux)
  n_e = sz_f[1]
  case (sz_f[0]) of
     1   : n_t = 1L
     2   : n_t = sz_f[2]
    else : begin
             print,"Dimensions of eflux must be [n_e,n_t]."
             return, badphi
           end
  endcase

  sz_e = size(engy)
  case (sz_e[0]) of
     1   : if (sz_e[1] ne n_e) then begin
             print,"Dimensions of energy and flux arrays are incompatible!"
             return, badphi
           endif else e = engy # replicate(1., n_t)
     2   : if (max(abs(sz_e - sz_f)) gt 0) then begin
             print,"Dimensions of energy and flux arrays are incompatible!"
             return, badphi
           endif else e = engy
    else : begin
             print,"Dimensions of energy and flux arrays are incompatible!"
             return, badphi
           end
  endcase

; Trim input arrays to energy < 60 eV

  indx = where(e[*,0] lt 60., n_e)
  e = e[indx,*]
  f = alog10(eflux[indx,*])
  phi = replicate(badphi, n_t)

; Filter out bad spectra

  n_f = round(total(finite(f),1))
  gndx = where(n_f eq n_e, ngud, complement=bad, ncomplement=nbad)

  if (ngud eq 0L) then begin
    print,"No good spectra!"
    return, phi
  endif

  if (nbad gt 0L) then f[*,bad] = !values.f_nan

; Take first and second derivatives of log(eflux) w.r.t. log(E)

  df = f
  d2f = f
     
  for i=0L,(n_t-1L) do df[*,i] = deriv(f[*,i])
  for i=0L,(n_t-1L) do d2f[*,i] = deriv(df[*,i])

; Oversample (4 sub-bins per bin) and interpolate

  n_es = 4*n_e
  emax = max(e, dim=1, min=emin)
  dloge = (alog10(emax) - alog10(emin))/float(n_es - 1)
  ee = 10.^((replicate(1.,n_es) # alog10(emax)) - (findgen(n_es) # dloge))
  
  dfs = fltarr(n_es,n_t)
  for i=0L,(n_t-1L) do dfs[*,i] = interpol(df[*,i],n_es)
     
  d2fs = fltarr(n_es,n_t)
  for i=0L,(n_t-1L) do d2fs[*,i] = interpol(d2f[*,i],n_es)

; Trim to the desired energy search range

  indx = where((ee[*,0] gt Espan[0]) and (ee[*,0] lt Espan[1]), n_e)
  ee = ee[indx,*]
  dfs = dfs[indx,*]
  d2fs = d2fs[indx,*]

; The spacecraft potential is determined based on the slope of d(logF)/d(logE)
; and the width of the feature (the number of energy bins over which the slope
; is observed).  A figure of merit is empirically determined that rewards steep
; slopes and narrow features.

  zcross = d2fs*shift(d2fs,1,0)
  zcross[0,*] = 1.

  diag = {fom:0., slope:0., fwhm:0., dE:0., phi:0.}
  diag = replicate(diag, n_t)

  for i=0L,(n_t-1L) do begin
    indx = where((dfs[*,i] gt thresh) and (zcross[*,i] lt 0.), ncross) ; local maxima in slope
    if (ncross eq 0) then begin
      fom = 0.
      Ep = 0.
      slope = 0.
      fwhm = 0.
      dE = 2.*dEmax
    endif else begin
      fom = fltarr(ncross)
      Ep = fom
      slope = fom
      fwhm = fom
      dE = replicate(2.*dEmax, ncross)
    endelse

    for j=0L,(ncross-1L) do begin
;      k = max(indx)        ; lowest energy slope feature above threshold
;      k = max(dfs[indx,i]) ; maximum slope feature above threshold

      k = indx[j]
      dfsmax = dfs[k,i]   ; peak
      dfsmin = dfsmax/2.  ; half maximum

      while ((dfs[k,i] gt dfsmin) and (k lt n_e-1)) do k++
      kmax = k
      k = indx[j]
      while ((dfs[k,i] gt dfsmin) and (k gt 0)) do k--
      kmin = k
      k = indx[j]

      dE[j] = ee[kmin,i] - ee[kmax,i]        ; FWHM, eV
      if (kmin eq 0) then dE[j] = 2.*dEmax   ; suppress features outside search window

; Slope features near the low-energy edge of the search window will be suppressed if
; there is no zero crossing -- that is, if there is no local maximum associated with the
; feature.

      fom[j] = (dfsmax^1.5)*(ee[k,i]/dE[j])  ; figure of merit for each feature (empirical)
      Ep[j] = ee[k,i]                        ; peak energy of each feature
      slope[j] = dfsmax                      ; slope of each feature
      fwhm[j] = float(kmax - kmin)/4.        ; feature widths (number of energy channels)
    endfor

    jndx = where((fom gt 0.) and (dE lt dEmax), count)
    if (count gt 0L) then begin
      fom = fom[jndx]
      Ep = Ep[jndx]
      slope = slope[jndx]
      fwhm = fwhm[jndx]
      dE = dE[jndx]
      indx = indx[jndx]

      k = where(Ep lt 10., nk)  ; Look for multiple features below 10 eV.  If more than one, 
      if (nk gt 1) then begin   ; drop lowest energy feature.  This accounts for structure
        k = count - 2           ; in the s/c photoelectron spectrum.
        fom = fom[0:k]
        Ep = Ep[0:k]
        slope = slope[0:k]
        fwhm = fwhm[0:k]
        dE = dE[0:k]
        indx = indx[0:k]
      endif

      fmax = max(fom,j)
      k = indx[j]
      phi[i] = ee[k,i]*(1. + (bias*0.1236))

      diag[i].fom = fmax
      diag[i].slope = slope[j]
      diag[i].fwhm = fwhm[j]
      diag[i].dE = dE[j]
      diag[i].phi = phi[i]
    endif

  endfor

  return, phi

end
