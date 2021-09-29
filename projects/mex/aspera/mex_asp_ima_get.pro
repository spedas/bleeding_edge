;+
;
;FUNCTION:        MVN_ASP_IMA_GET
;
;PURPOSE:         
;                 Returns the MEX/ASPERA-3 (IMA) data structure.
;
;INPUTS:          Time for extracting from common blocks.
;       
;KEYWORDS:
;
;     UNITS:      Converts data to the specified unit.
;
;       DDD:      If set, returns a data as one 3D scan.
;
;CREATED BY:      Takuya Hara on 2018-01-31.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-04-04 16:17:13 -0700 (Wed, 04 Apr 2018) $
; $LastChangedRevision: 24998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_ima_get.pro $
;
;-
FUNCTION mex_asp_ima_get, time, verbose=verbose, units=units, ddd=ddd
  COMMON mex_asp_dat, mex_asp_ima, mex_asp_els
  c  = !const.c                                 ; light speed (km/s)
  mp = !const.mp * c * c / !const.e             ; proton mass (eV)
  
  IF KEYWORD_SET(ddd) THEN dflg = 1 ELSE dflg = 0

  IF SIZE(mex_asp_ima, /type) NE 8 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'Data has not been loaded yet.'
     RETURN, 0
  ENDIF 

  IF SIZE(time, /type) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'You must specify a time.'
     RETURN, 0
  ENDIF 

  mtime = 0.5 * (mex_asp_ima.time + mex_asp_ima.end_time)
  n = nn(mtime, time)
  uname = mex_asp_ima[n].units_name
  polar = mex_asp_ima[n].polar
  opidx = mex_asp_ima[n].opidx

  IF opidx GT 63 THEN BEGIN
     npolar = 6
     nenergy = 32 
  ENDIF ELSE BEGIN
     npolar = 16
     nenergy = 96
  ENDELSE 
  nmass   = 32  

  mex_asp_ima_sc_bins, fov

  IF (dflg) THEN n = INDGEN(npolar) + n - polar 
  IF MAX(n) GE N_ELEMENTS(mex_asp_ima) THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No 3D data loaded at the specified time.'
     RETURN, 0
  ENDIF 

  phi = [168.75, 191.25, 213.75, 236.25, 258.75, 281.25, 303.75, 326.25, $
         348.75,  11.25,  33.75,  56.25,  78.75, 101.25, 123.75, 146.25  ]
  phi *= -1.

  phi = REBIN(REBIN(phi, 16, nenergy, /sample), 16, nenergy, nmass, /sample)
  phi = TRANSPOSE(phi, [1, 0, 2])

  ndat = N_ELEMENTS(n)
  IF (dflg) THEN BEGIN
     nbins = 16 * npolar

     polar = mex_asp_ima[n].polar
     pacc  = mex_asp_ima[n[0]].pacc

     stime = mex_asp_ima[n[0]].time
     etime = mex_asp_ima[n[-1]].end_time

     data = list()
     bkg = list()
     energy = list()
     theta = list()
     angle = list()
     bins_sc = list()
     iaz = list()
     jel = list()
     FOR i=0, ndat-1 DO BEGIN
        ima = mex_asp_ima[n[i]]
        data.add, ima.data[0:nenergy-1, *, *]
        bkg.add, ima.bkg[0:nenergy-1, *, *]
        energy.add, ima.energy[0:nenergy-1, *, *]
        theta.add, ima.theta[0:nenergy-1, *, *]
        angle.add, phi
        bins_sc.add, TRANSPOSE(REBIN(fov[*, polar[i]], 16, nenergy, nmass, /sample), [1, 0, 2])
        iaz.add, INDGEN(16)
        jel.add, REPLICATE(polar[i], 16)
        undefine, ima
     ENDFOR 
     data = data.toarray(dim=2)
     bkg = bkg.toarray(dim=2)
     energy = energy.toarray(dim=2)
     theta = theta.toarray(dim=2)
     phi = angle.toarray(dim=2)
     bins_sc = bins_sc.toarray(dim=2)
     iaz = iaz.toarray(dim=1)
     jel = jel.toarray(dim=1)
     polar = -1 ; because it is no longer meaningful in case /ddd is turn on.  
  ENDIF ELSE BEGIN
     nbins = 16
     ima = mex_asp_ima[n]
     pacc = ima.pacc
     stime = ima.time
     etime = ima.end_time
     data = ima.data[0:nenergy-1, *, *]
     bkg = ima.bkg[0:nenergy-1, *, *]
     energy = ima.energy[0:nenergy-1, *, *]
     theta = ima.theta[0:nenergy-1, *, *]
     bins_sc = TRANSPOSE(REBIN(fov[*, polar], nbins, nenergy, nmass, /sample), [1, 0, 2])
     undefine, ima
  ENDELSE 
  bins = bins_sc
  bins[*] = 1
  
  dt = etime - stime
  mex_asp_ima_calib, calib, /verbose

  ima = {project_name: 'MEX', data_name: 'ASPERA3/IMA', units_name: uname, units_procedure: 'mex_asp_ima_convert_units'}
  extract_tags, ima, {time: stime, end_time: etime, delta_t: dt, integ_t: 0.1209d0, nenergy: nenergy, energy: energy}
  extract_tags, ima, {gf: calib.gf, nbins: nbins}

  dphi = phi
  dphi[*] = 22.5
  dtheta = theta
  dtheta[*] = (90./16.)

  extract_tags, ima, {phi: phi, dphi: dphi, theta: theta, dtheta: dtheta}

  ; iaz: azimuth (phi) sector number, jel: elevation (= polar; theta) angle index
  IF (dflg) THEN extract_tags, ima, {iaz: iaz, jel: jel}

  extract_tags, ima, {nmass: nmass, polar: polar, pacc: pacc, data: data, bkg: bkg}
  extract_tags, ima, {bins: bins, bins_sc: bins_sc, mass: mp / (c*c)}

  IF KEYWORD_SET(units) THEN mex_asp_ima_convert_units, ima, units
  RETURN, ima
END
