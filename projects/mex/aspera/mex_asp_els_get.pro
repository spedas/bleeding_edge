;+
;
;FUNCTION:        MVN_ASP_ELS_GET
;
;PURPOSE:         
;                 Returns a MEX/ASPERA-3 (ELS) data structure.
;
;INPUTS:          Time for extracting from common blocks.
;       
;KEYWORDS:
;
;     UNITS:      Converts data to the specified unit.
;
;CREATED BY:      Takuya Hara on 2018-01-30.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-04-04 13:51:13 -0700 (Wed, 04 Apr 2018) $
; $LastChangedRevision: 24995 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_els_get.pro $
;
;-
FUNCTION mex_asp_els_get, time, verbose=verbose, units=units
  COMMON mex_asp_dat, mex_asp_ima, mex_asp_els
  c = 2.99792458d5              ; light speed (km/s)
  me = 5.110041d5               ; electron mass (eV)

  IF SIZE(mex_asp_els, /type) NE 8 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'Data has not been loaded yet.'
     RETURN, 0
  ENDIF 

  IF SIZE(time, /type) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'You must specify a time.'
     RETURN, 0
  ENDIF 

  mex_asp_els_calib, calib, /verbose
  
  mtime = [ [mex_asp_els.time], [mex_asp_els.end_time] ]
  mtime = MEAN(mtime, dim=2)
  n = nn(mtime, time)

  ;n = nn(mex_asp_els.time, time)
  ;midx = mex_asp_els.mode[n]
  ;IF midx EQ 1 THEN mode = 'fast' ELSE mode = 'survey'
  
  ;str_element, mex_asp_els, mode, els
  ;n = nn(0.5*(els.time + els.end_time), time)
  els = mex_asp_els[n]
  mode = els.mode
  ;IF mode EQ 'fast' THEN BEGIN
  IF (mode) THEN BEGIN 
     ;nenergy = 31
     dt = 1.d0
  ENDIF ELSE BEGIN
     ;nenergy = 127
     dt = 4.d0
  ENDELSE 
  nbins = 16
  nenergy = els.nenergy

  data = {project_name: 'MEX', data_name: 'ASPERA3/ELS', units_name: els.units_name, units_procedure: 'mex_asp_els_convert_units'}
  extract_tags, data, {time: els.time, end_time: els.end_time, delta_t: dt}
  extract_tags, data, {integ_t: calib.dt[0], nenergy: nenergy, energy: els.energy[0:nenergy-1, *]}
  extract_tags, data, {gf: els.gf[0:nenergy-1, *], nbins: nbins}

  phi = [258.75, 236.25, 213.75, 191.25, 168.75, 146.25, 123.75, 101.25, $
         78.75,  56.25,  33.75,  11.25, 348.75, 326.25, 303.75, 281.25  ]
  phi *= -1.
  phi = TRANSPOSE(REBIN(phi, nbins, nenergy, /sample))
  dphi = phi
  dphi[*] = 22.5

  theta = phi
  theta[*] = 0.
  dtheta = theta
  dtheta[*] = 4.

  extract_tags, data, {phi: phi, dphi: dphi, theta: theta, dtheta: dtheta, data: els.data[0:nenergy-1, *]}
  extract_tags, data, {mass: me / (c*c)}

  IF KEYWORD_SET(units) THEN mex_asp_els_convert_units, data, units
  RETURN, data
END
