;+
;
;Procedure:
;  moka_pgs_make_pad
;
;Purpose:
;  Generate pitch angle distribution from the distribution data dumped by
;  'moka_mms_part_products' with out=['pad']
;
;History:
;  Created on 2017-01-01 by moka
;  
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-10-06 09:35:27 -0700 (Thu, 06 Oct 2016) $
;$LastChangedRevision: 22050 $
;$URL: svn+ssh://ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_products.pro $
;-

PRO moka_pgs_make_pad, data, spec=spec, xaxis=wpa, nbin=nbin,$
   mag_data=mag_data, vel_data=vel_data, wegy=wegy, subtract_bulk=subtract_bulk
  compile_opt idl2

  if ~is_struct(data) then return
  if undefined(nbin) then nbin=18
  if undefined(wegy) then begin
    message,'Set energy bins (1D arrray). e.g. wegy  = dist[0].ENERGY[*,0,0]'
  endif
  
  ;set magnetic field if available
  if ~undefined(mag_data) then data.magf = mag_data

  dr = !dpi/180.
  rd = 1/dr

  ;-----------------------------
  ; Pitch-angle Bins
  ;-----------------------------
  kmax  = nbin
  pamin = 0.
  pamax = 180.
  dpa   = (pamax-pamin)/double(kmax); bin size
  wpa   = pamin + findgen(kmax)*dpa + 0.5*dpa; bin center values
  pa_bin = [pamin + findgen(kmax)*dpa, pamax]

  ;-----------------------------
  ; Energy Bins
  ;-----------------------------  
  jmax  = n_elements(wegy)
  egy_bin = 0.5*(wegy + shift(wegy,-1))
  egy_bin[jmax-1] = 2.*wegy[jmax-1]-egy_bin[jmax-2]
  egy_bin0        = 2.*wegy[     0]-egy_bin[     0] > 0
  egy_bin = [egy_bin0, egy_bin]
  
  ;----------------
  ; Prep
  ;----------------
  pad = fltarr(1, jmax, kmax)
  count_pad = lonarr(1, jmax, kmax); number of events in each bin
  
  ;------------------------------------
  ; Magnetic field & Bulk Velocity
  ;------------------------------------
  btot = sqrt(data.magf[0]^2+data.magf[1]^2+data.magf[2]^2)
  bnrm = data.magf/btot
  Vbulk = [0., 0., 0.]
  if keyword_set(subtract_bulk) then Vbulk = vel_data

  ;------------------------------------
  ; Particle Velocities & Pitch Angles
  ;------------------------------------
  erest = data.mass * !const.c^2 / 1e6; convert mass from eV/(km/s)^2 to eV
  vabs = !const.c * sqrt( 1 - 1/((data.ENERGY/erest + 1)^2) )  /  1000.;velocity in km/s

  sphere_to_cart, vabs, data.theta, data.phi, vx, vy, vz
  
  if keyword_set(subtract_bulk) then begin
    vx -= Vbulk[0]
    vy -= Vbulk[1]
    vz -= Vbulk[2]
  endif
  dp  = (bnrm[0]*vx + bnrm[1]*vy + bnrm[2]*vz)/sqrt(vx^2+vy^2+vz^2)
  idx = where(dp gt  1.d0, ct) & if ct gt 0 then dp[idx] =  1.d0
  idx = where(dp lt -1.d0, ct) & if ct gt 0 then dp[idx] = -1.d0
  pa  = rd*acos(dp)
  
  cart_to_sphere, vx, vy, vz, vnew, theta, phi, /ph_0_360

  data.energy = erest*(1.d0/sqrt(1.d0-(vnew*1000.d0/!const.c)^2)-1.d0); eV
  data.phi    = phi
  data.theta  = theta
  data.pa     = pa
  
  ;------------------------
  ; DISTRIBUTE
  ;------------------------
  imax = n_elements(data.data_dat)

  for i=0,imax-1 do begin; for each particle

    ; Find energy bin
    result = min(egy_bin-data.energy[i],j,/abs)
    if egy_bin[j] gt data.energy[i] then j -= 1
    if j eq jmax then j -= 1

    ; Find pitch-angle bin
    result = min(pa_bin-data.pa[i],k,/abs)
    if pa_bin[k] gt data.pa[i] then k -= 1
    if k eq kmax then k -= 1

    ; pitch-angle distribution
    pad[0,j,k] += data.data_dat[i]
    count_pad[0,j,k] += 1L

  endfor; for each particle
  
  pad /= float(count_pad)
  
  ;---------------
  ; ANGLE PADDING
  ;---------------
  padnew = fltarr(1, jmax, kmax+2)
  padnew[0, 0:jmax-1,1:kmax] = pad
  padnew[0, 0:jmax-1,     0] = padnew[0, 0:jmax-1,   1]
  padnew[0, 0:jmax-1,kmax+1] = padnew[0, 0:jmax-1,kmax]
  pad = padnew
  wpa_new = [wpa[0]-dpa,wpa,wpa[kmax-1]+dpa]
  wpa = wpa_new

  ;-----------------------
  ;concatenate spectra
  ;-----------------------
  if ~undefined(spec) then begin
    spec = [spec,pad]
  endif else begin
    spec = temporary(pad)
  endelse

END
