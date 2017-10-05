;+
;PROCEDURE: 
;	mvn_swe_shape_par
;PURPOSE:
;	Calculates SWEA energy shape parameter and stores it as a TPLOT variable.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_shape_par
;INPUTS: 
;
;KEYWORDS:
;   PANS:      Named variable to return tplot variable created.
;
;   VAR:       Get SPEC data from tplot instead of SWEA common block.
;              In this case, you are responsible for making sure the
;              data are in units of EFLUX.  Any other units will give
;              bogus results.
;              (Set this keyword to the variable name or index.)
;
;   KEEP_NAN:  If set, then include results for all input spectra, using
;              NaN for invalid results.  Otherwise, only valid results
;              are returned.
;
;   ERANGE:    If set, then calculate the shape parameter over this 
;              energy range.  Default is 0-100 eV.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-02 14:14:58 -0800 (Mon, 02 Nov 2015) $
; $LastChangedRevision: 19214 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_shape_par.pro $
;
;-

pro mvn_swe_shape_par, pans=pans, var=var, keep_nan=keep_nan, erange=erange

  compile_opt idl2

  @mvn_swe_com
  
  df_iono = [-0.2280,  0.3775,  0.4587,  0.0689, -0.0861, -0.0140,  0.0622,  0.0958, $
              0.1089,  0.1106,  0.0483,  0.0071,  0.0467,  0.0470,  0.0293,  0.0571, $
              0.0638,  0.0452,  0.0865,  0.1886,  0.3264,  0.2966,  0.1527,  0.0861, $
              0.0845,  0.1114,  0.1573,  0.1719,  0.1376,  0.0232, -0.0524,  0.0109, $
              0.0525,  0.0743,  0.1065,  0.1232,  0.0928,  0.0521,  0.0392,  0.0192, $
             -0.0191, -0.0712, -0.1264, -0.1769, -0.2073, -0.2146, -0.2251]
  
  if keyword_set(keep_nan) then dofilter = 0 else dofilter = 1
  
  if (n_elements(erange) lt 2) then begin
    emin = 0.
    emax = 100.
  endif else emin = min(float(erange), max=emax)

  if keyword_set(var) then begin
    get_data, var, data=spec, index=i
    if (i eq 0) then begin
      print,"Tplot variable not found: ", var
      pans = ''
      return
    endif

    print,"Warning: data are assumed to have units of EFLUX!"
    t = spec.x
    e = spec.v # replicate(1.,n_elements(t))
    f = transpose(spec.y)
  endif else begin
    npts = n_elements(mvn_swe_engy)

    if (npts eq 0L) then begin
      print,"No SWEA SPEC data."
      pans = ''
      return
    endif

    old_units = mvn_swe_engy[0].units_name
    mvn_swe_convert_units, mvn_swe_engy, 'eflux'

    t = mvn_swe_engy.time
    e = mvn_swe_engy.energy
    f = mvn_swe_engy.data
  endelse

; Select energy channels

  n_e = n_elements(df_iono)
  indx = indgen(n_e) + (64 - n_e)
  e = e[indx,*]
  f = alog10(f[indx,*])
  
  endx = where((e[*,0] ge emin) and (e[*,0] le emax), ecnt)
  if (ecnt eq 0L) then begin
    print,"No data within energy range: ",emin,emax
    return
  endif

; Filter out bad spectra (such as hot electron voids)

  npts = n_elements(t)
  gndx = round(total(finite(f[endx,*]),1))
  gndx = where(gndx eq ecnt, ngud)
  if (ngud eq 0L) then begin
    print,"No good spectra!"
    pans = ''
    return
  endif

; Take first derivative of log(eflux) w.r.t. log(E)

  df = f
  df[*,*] = !values.f_nan
  for i=0L,(ngud-1L) do df[*,gndx[i]] = deriv(f[*,gndx[i]])

; Calculate electron energy shape parameter over [emin, emax]

  par = df - (df_iono # replicate(1., npts))
  par = total(abs(par[endx,*]),1)

  if (dofilter) then begin
    t = t[gndx]
    par = par[gndx]
  endif

  store_data,'mvn_swe_shape_par',data={x:t, y:par}
  options,'mvn_swe_shape_par','ytitle','SWE Electron!CShape Param'
  pans = 'mvn_swe_shape_par'
  
  if (size(old_units,/type) eq 7) then mvn_swe_convert_units, mvn_swe_engy, old_units

  return

end
