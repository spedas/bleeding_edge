;+
;PROCEDURE:   mvn_swe_secondary
;PURPOSE:
;  Estimates contamination caused by secondary electrons emitted from interior
;  surfaces of the instrument.  Most secondaries that make it to the MCP are
;  likely emitted from surfaces near the entrance to the hemispheres, which are
;  coated with Cu2S.  Some fraction may come from the deflectors, which are 
;  coated with black nickel.
;
;  Method adapted from Andreone et al., JGR Space Phys. 127, e2121JA029404 (2022).
;
;  Primary electron weighting function (secondary yield per primary):
;    Emax = 300.
;    s = 1.6                       ; from experiment (Schultz et al. 1996)
;    s = 1.9 - 1.05*alog10(e)/3.   ; tuned to be close to Andreone et al. 2022
;
;    d(E) = exp(-(alog(E/Emax)^2.)/(2.*s*s))
;
;
;    <Fp> = total(Fp(E) * d(E) * dE)  ; summed above s/c potential
;
;  Secondary electron population has a Maxwell-Boltzmann distribution with a
;  temperature that is independent of primary energy:
;    E0 = 3.
;    Smax = 0.1225
;    S(E) = Smax * exp(1.) * (E/E0) * exp(-(E/E0))
;
;  Secondary electron differential flux:
;    Fs = eps * <Fp> * S(E)
;
;  The scale factor eps is of order unity.  It is used to tune the secondary
;  yield to match observations.  Andreone allowed eps to be tuned separately
;  for each spectrum; however, here I am taking eps to be a constant, which
;  is tuned by looking a many spectra in different plasma regions.  Also, I
;  am tuning E0 to match observations of the secondary electron peak.
;
;  Filters are used to avoid over- and under- correction.
;
;  Primaries impact interior surfaces to produce secondaries, so energy for
;  both populations is measured in the instrument frame.
;
;USAGE:
;  mvn_swe_secondary, data [, /tplot]   ; normal usage
;
;  mvn_swe_secondary, config=value      ; initialize with custom parameters
;
;INPUTS:
;       data:         Array of SPEC, PAD or 3D data structures.
;
;KEYWORDS:
;       CONFIG:       A structure containing parameters for the yield and
;                     secondary distribution functions.  This can have one
;                     or more of the following tags:
;
;                       e0 : temperature (eV) of the M-B secondary electron
;                            distribution (default = 3.5 eV)
;
;                       s0 : peak value of the M-B secondary electron
;                            distribution function (default = 0.1225)
;
;                       e1 : peak (eV) of the secondary yield function
;                            (default = 300 eV)
;
;                       s1 : scale factor for the secondary yield
;                            (default = 0.7)
;
;                     These values are persistent for subsequent calls.
;
;       PARAM:        Returns the CONFIG parameter structure.
;
;       DEFAULT:      Sets CONFIG to defaults.
;
;       TPLOT:        Create a tplot variable.  (Only works for SPEC data.)
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-05-05 13:10:05 -0700 (Thu, 05 May 2022) $
; $LastChangedRevision: 30808 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_secondary.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_swe_secondary.pro
;-
pro mvn_swe_secondary, data, config=config, param=param, default=default, tplot=tplot

  @mvn_swe_com
  common sweseccom, e0, s0, e1, s1

; Set parameters for secondary and yield functions

  if ((size(e0,/type) eq 0) or keyword_set(default)) then begin
    e0 = 3.5             ; temperature of the M-B secondary distribution (eV)
    s0 = 0.1225*exp(1.)  ; scale factor for the M-B secondary distribution
    e1 = 300.            ; peak of the secondary yield function (eV)
    s1 = 0.7             ; scale factor for secondary yield
  endif

  if (size(config,/type) eq 8) then begin
    str_element, config, 'E0', value, success=ok
    if (ok) then e0 = float(value)
    str_element, config, 'S0', value, success=ok
    if (ok) then s0 = float(value)*exp(1.)
    str_element, config, 'E1', value, success=ok
    if (ok) then e1 = float(value)
    str_element, config, 'S1', value, success=ok
    if (ok) then s1 = float(value)
  endif

  param = {E0:E0, S0:S0/exp(1.), E1:E1, S1:S1}

  tiny = 1.e-31  ; prevent underflow
  maxarg = 80.   ; prevent underflow

; Make sure the input data is a MAVEN SWEA data structure

  npts = n_elements(data)
  if (npts gt 0L) then begin
    str_element, data[0], 'PROJECT_NAME', pname, success=ok
    if (ok) then if (pname ne 'MAVEN') then ok = 0
    if (ok) then str_element, data[0], 'APID', apid, success=ok
    if (not ok) then begin
      print,"Input data is not a MAVEN SWEA structure."
      return
    endif
    if ((apid lt 'A0'XB) and (apid gt 'A5'XB)) then begin
      print,"Input data must have an APID from A0 to A5."
      return
    endif
  endif else return

  str_element, data[0], 'NBINS', value, success=ok
  if (ok) then nbins = value else nbins = 1

  str_element, data[0], 'NENERGY', value, success=ok
  if (ok) then n_e = value else n_e = 64

  doplot = keyword_set(tplot) and (apid eq 'A4'XB)

; Convert data units to FLUX

  ounits = data[0].units_name
  mvn_swe_convert_units, data, 'flux'

; Calculate the secondary electron distribution for each spectrum
; Process angular bins individually

  data.bkg = 0.
  data.valid = 1B

  for i=0L,(npts-1L) do begin
    for j=0L,(nbins-1L) do begin

      f = data[i].data[*,j]
      df = sqrt(data[i].var[*,j])
      e = data[i].energy[*,j]
      de = data[i].denergy[*,j]

      s = s0*(e/e0)*exp(-((e/e0) < maxarg))   ; secondary distribution
      sig = 1.9 - 1.05*alog10(e)/3.           ; width of yield function
      d = exp(-(alog(e/e1)^2.)/(2.*sig*sig))  ; yield function

      fs = s1*s*total(f*d*de)                 ; secondaries
      fa = (f - fs) > tiny                    ; ambient

; Mask s/c photoelectrons, under- and over-correction

      indx = where(e le data[i].sc_pot, count)
      if (count gt 0L) then data[i].valid[indx,j] = 0B  ; s/c photoelectrons

      kscp = max(where(e gt data[i].sc_pot))
      fmax = max(e[0:kscp]*fa[0:kscp], kmax)
      fmin = min(e[kmax:kscp]*fa[kmax:kscp], kmin)
      kmin += kmax
      if ((fa[kmin] + 2.*df[kmin]) lt max(fa[(kmin-1):kscp])) then begin
        data[i].valid[(kmin+1 < kscp):*,j] = 0B         ; under-correction
      endif

      indx = where((e lt 100.) and (f/fa gt 10.), count)
      if (count gt 0L) then data[i].valid[indx,j] = 0B  ; over-correction

; Record the result

      data[i].bkg[*,j] = fs

    endfor
  endfor

; Convert back to the original units

  mvn_swe_convert_units, data, ounits

; Make a tplot variable for SPEC data

  if (doplot) then begin
    vname = 'ambient'
    amb = transpose(data.data - data.bkg)
    store_data,'ambient',data={x:data.time, y:amb, v:data[0].energy}
    ylim,vname,3,5000,1
    zlim,vname,0,0,1
    options,vname,'spec',1
    options,vname,'ytitle','Energy (eV)'
    options,vname,'ztitle',strupcase(data[0].units_name)
    options,vname,'no_interp',1

    get_data,'swe_pot_overlay',index=i
    if (i gt 0) then begin
      vname = 'ambient_pot'
      store_data,vname,data=['ambient','swe_pot_overlay']
      ylim,vname,3,5000,1
    endif
  endif

  return

end
