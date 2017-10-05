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
;
;OUTPUTS:
;   scpot:     An array of n_t spacecraft potentials.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-07-31 15:24:02 -0700 (Mon, 31 Jul 2017) $
; $LastChangedRevision: 23737 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_pospot.pro $
;
;-

function mvn_swe_sc_pospot, engy, eflux

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

; Oversample and smooth

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

; The spacecraft potential is taken to be the maximum slope (dlogF/dlogE)
; within the search window.
  
  zcross = d2fs*shift(d2fs,1,0)
  zcross[0,*] = 1.

  for i=0L,(n_t-1L) do begin
    indx = where((dfs[*,i] gt thresh) and (zcross[*,i] lt 0.), ncross) ; local maxima in slope

    if (ncross gt 0) then begin
      k = max(indx)        ; lowest energy feature above threshold
      dfsmax = dfs[k,i]
      dfsmin = dfsmax/2.   ; half maximum

      while ((dfs[k,i] gt dfsmin) and (k lt n_e-1)) do k++
      kmax = k
      k = max(indx)
      while ((dfs[k,i] gt dfsmin) and (k gt 0)) do k--
      kmin = k
      
      dE = ee[kmin,i] - ee[kmax,i]  ; FWHM
;     if ((kmax eq (n_e-1)) or (kmin eq 0)) then dE = 2.*dEmax
      if (kmin eq 0) then dE = 2.*dEmax
      
      if (dE lt dEmax) then phi[i] = ee[max(indx),i] ; only accept narrow features
    endif
  endfor

  return, phi

end
