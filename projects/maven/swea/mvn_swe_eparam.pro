;+
;PROCEDURE:   mvn_swe_eparam
;PURPOSE:
;  Calculates the gyrofrequency, gyroradius and adiabatic condition
;  (1st adiabatic invariant) for electrons:
;
;    Fg = (28 Hz)*B           ; gyrofrequency, [B] = nT
;
;    Rg = (2.4 km)*sqrt(E)/B  ; gyroradius, [E] = eV, [B] = nT
;
;    (1/B)*(dB/dx)*Rg << 1    ; adiabatic condition
;
;  Collision frequencies (s-1) for electrons with neutrals ([Te] = K, [n] = cm-3)
;  (from Ionospheres by Schunk & Nagy, Table 4.6 on pg. 99):
;    N2    (2.33e-11) * n(N2)  * (1 - 1.21e-4*Te)*Te
;    O2    (1.82e-10) * n(O2)  * (1 + 3.60e-2*sqrt(Te))*sqrt(Te)
;    O     (8.90e-11) * n(O)   * (1 + 5.70e-4*Te)*sqrt(Te)
;    He    (4.60e-10) * n(He)  * sqrt(Te)
;    H     (4.50e-09) * n(H)   * (1 - 1.35e-4*Te)*sqrt(Te)
;    CO    (2.34e-11) * n(CO)  * (Te + 165)
;    CO2   (3.68e-08) * n(CO2) * (1 + 4.1e-11*abs(4500 - Te)^2.93)
;
;USAGE:
;  mvn_swe_eparam
;
;INPUTS:
;   None:      Mag data are obtained from tplot variable.  Spacecraft ephemeris
;              is obtained from common block.
;
;KEYWORDS:
;   MINALT:    Below this altitude, electrons are assumed to be non-adiabatic
;              because of collisions with atmospheric species.
;
;   ENERGY:    Electron energies (eV) for which to calculate parameters.
;              Default = [1000.,100.,10.]
;
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-04 17:36:55 -0800 (Wed, 04 Nov 2015) $
; $LastChangedRevision: 19246 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_eparam.pro $
;
;CREATED BY:    David L. Mitchell  09/18/15
;-
pro mvn_swe_eparam, minalt=minalt, energy=energy

  @maven_orbit_common
  
  if not keyword_set(minalt) then minalt = 200.
  if not keyword_set(energy) then energy = [1000.,100.,10.]
  n_e = n_elements(energy)
  elabs = strtrim(string(round(energy)),2) + ' eV'
  
  NaN = !values.f_nan

; Get the neutral atmosphere (maybe add this later)

;  path = '/Users/mitchell/Documents/Home/Mars/MAVEN/Pressure Constraints/MTGCM/'
;  fname = 'SMOD180.ATM.3am'
;  read_mtgcm, path+fname, result=atm
  
;  Te = (1.602e-12/1.38e-16) * 100.

;  nu_CO2 = (3.68e-08) * atm.n_CO2 * (1 + 4.1e-11*abs(4500 - Te)^2.93)

; Calculate (1/B)*(dB/dx)

  get_data,'mvn_B_1sec',data=mag,index=i
  if (i eq 0) then begin
    print,"Load MAG data first."
    return
  endif
  t = mag.x
  npts = n_elements(t)

  dB = mag.y - shift(mag.y,1,0)
  dB = sqrt(total(dB^2,2))
  dB[0] = dB[1]

  B = sqrt(total(mag.y^2,2))
  B = (B + shift(B,1))/2.
  B[0] = B[1]

  dBdt = dB/B                                ; dB/B per sec

  if (size(state,/type) ne 8) then maven_orbit_tplot,/load
  v = spline(time, sqrt(total(state.mso_v^2.,2)), t)  ; s/c velocity
  h = spline(time, hgt, t)                            ; s/c altitude
  
  dBdx = (abs(dBdt)/v) # replicate(1.,n_e)   ; dB/B per km

; Calculate e- gyrofrequency

  Fg = 28.*B                                 ; e- gyrofrequency (Hz)

; Calculate e- gyroradius

  B = B # replicate(1.,n_e)
  E = replicate(1.,npts) # energy

  Rg = 2.4*sqrt(E)/B                         ; e- gyroradius (km)

; Calculate adiabatic condition

  dBdRg = dBdx * Rg                          ; dB/B per gyroradius

; Collisional regime is not adiabatic either

  indx = where(h lt minalt, count)
  if (count gt 0L) then dBdRg[indx,*] = NaN  ; e- in collisional regime

; Store result in tplot variables

  vname = 'Fg_elec'
  store_data,vname,data={x:t, y:Fg}
  options,vname,'ytitle','Fg (elec)'
  ylim,vname,0,0,1

  vname = 'Rg_elec'
  store_data,vname,data={x:t, y:Rg, v:energy}
  options,vname,'ytitle','Rg (elec)'
  options,vname,'spec',0
  ylim,vname,0.003,300,1
  options,vname,'labels',elabs
  options,vname,'labflag',1

  vname = 'dBdRg'
  store_data,vname,data={x:t, y:smooth(dBdRg,[11,1],/nan), v:energy}
  options,vname,'ytitle','dB/dRg'
  options,vname,'spec',0
  ylim,vname,1e-4,1e1,1
  options,vname,'labels',elabs
  options,vname,'labflag',1
  options,vname,'constant',[0.01,1]

end
