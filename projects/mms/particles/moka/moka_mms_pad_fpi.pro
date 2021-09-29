;+
;Procedure:
;  moka_mms_pad_fpi
;
;Purpose:
;  To process MMS FPI data and return
;  (1) pitch-angle-distribution (angle vs energy plot)
;  (2) energy spectrum in the omni, para, perp and anti-para directions.
;  (3) One-count-level is also returned.
;
;Calling Sequence: 
;  
;  (Similar to spd_slice2d. See also moka_mms_pad_fpi_crib.pro)
;    
;  structure = moka_mms_pad_fpi(dist [,disterr] $
;                       [,time=time [,window=window | samples=samples]]
;                       [trange=trange] ... )
;
; INPUT:
;   DIST   : A pointer to 3D data structure.
;   DISTERR: A pointer to 3D data error structure
;   TRANGE : Two-element time range over which data will be averaged. (string or double)
;   TIME   : Time at which the pad will be computed. (string or double)
;    SAMPLES: Number of nearest samples to TIME to average. (int/double)
;             If neither SAMPLES nor WINDOW are specified then default=1.
;    WINDOW: Length in seconds from TIME over which data will be averaged. (int/double)
;      CENTER_TIME: Flag denoting that TIME should be midpoint for window instead of beginning.
;
;   MAG_DATA: Name of tplot variable containing magnetic field data or 3-vector.
;            This will be used for pitch-angle calculation and must be in the
;            same coordinates as the particle data.
;   VEL_DATA: Name of tplot variable containing the bulk velocity data or 3-vector.
;            This will be used for pitch-angle calculation and must be in the
;            same coordinates as the particle data.
;
;   nbin: number of bins in the pitch-angle direction
;   
;   norm: Set this keyword for normalizing the data at each energy bin
;   units: units for both the pitch-angle-distribution (pad) and energy spectrum.
;          Options are 'eflux' [eV/(cm!U2!N s sr eV)] or
;                      'df_km'    [s!U3!N / km!U6!N']
;          The default is 'eflux'. The return structure contains a tag "UNITS".
;   pr___0: pitch angle range for the "para" spectrum, default = [0,45]
;   pr__90: pitch angle range for the "perp" spectrum, default = [45,135]
;   pr_180: pitch angle range for the "anti-para" spectrum, default = [135,180]
;
;Output:
;   a structure containing the results
;
;History:
;  2016-05-15 Created by Mitsuo Oka
;  2017-01-28 Fixed energy bin mistake 
;  2017-03-14 Fixed para and anti-para mistake (thanks to R. Mistry) 
;  2017-05-12 Fixed eflux calculation 
;  2017-10-17 Added SUBTRACT_ERROR keyword 
;  2017-10-17 Changed the interface so that it works like spd_slice2d  
;
;$LastChangedBy: moka $
;$LastChangedDate: 2017-09-30 11:03:14 -0700 (Sat, 30 Sep 2017) $
;$LastChangedRevision: 24073 $
;$URL: svn+ssh://ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/moka/moka_mms_pad.pro $
;-
FUNCTION moka_mms_pad_fpi, input, input_err, $
  ;------ Time options ---------
  time=time_in, $
  window=window, $
  center_time=center_time, $
  trange=trange_in, $
  samples=samples, $
  ;----- Support Data -----
  mag_data=mag_data, $
  vel_data=vel_data, $
  ;------ Output options ----------
  nbin=nbin, $; Number of pitch-angle bins
  da=da, da2=da2, $
  pr___0=pr___0, pr__90=pr__90, pr_180=pr_180, $
  units=units,$
  norm=norm, $
  subtract_bulk=subtract_bulk, $
  oclreal=oclreal, $
  _extra = _extra
  compile_opt idl2

  if undefined(nbin) then nbin = 18 ; Number of pitch-angle bins
  if undefined(da)    then da = 45.
  if undefined(da2)   then da2= 45.
  if undefined(pr___0) then pr___0 = [0., da]; para pitch-angle range
  if undefined(pr__90) then pr__90 = [90.-da2, 90.+da2]; perp pitch-angle range
  if undefined(pr_180) then pr_180 = [180.-da, 180.]; anti-para pitch-angle range
  if undefined(subtract_bulk) then subtract_bulk = 0

  
  ;-----------------
  ; Constant
  ;-----------------
  invalid = 0b
  fail = ''
  dr = !dpi/180.d0
  rd = 1.d0/dr

  ;-----------------
  ; CHECK
  ;-----------------
  if ~ptr_valid(input[0]) and ~is_struct(input[0]) then begin
    fail = 'Invalid data.  Input must be pointer or structure array.'
    dprint, dlevel=1, fail
    return, invalid
  endif

  ;--------------------------------
  ; Aggregate inputs
  ;  -multiple inputs are allowed to make things easier on the user
  ;  -pointer arrays are used as a way of supporting dissimilar
  ;   structures, which cannot be concatenated
  ;------------------------------------------------------------

  ;copy any structs to new pointer var, other inputs are copied and checked next
  switch n_params() of
    2: if is_struct(input_err) then pDerr = ptr_new(input_err) else pDerr = input_err
    1: if is_struct(input)     then pD    = ptr_new(input)     else pD = input
  endswitch
  USEERR = ptr_valid(pDerr)
  nmax = n_elements(*pD)
  
  ;---------------------
  ; Time range
  ;---------------------
  ; CASE A: time and window
  ; CASE B: time and samples
  ; CASE C: trange
  
  ; if not Case C, make sure we have time and window/samples
  if undefined(trange_in) then begin
    if undefined(time_in) then begin
      fail = 'Please specifiy a time or time range over which to compute the pad.  For example: '+ $
        ssl_newline()+'  "TIME=t, WINDOW=w" or "TRANGE=tr" or "TIME=t, SAMPLES=n"'
      dprint, dlevel=1, fail
      return, invalid
    endif else begin
      if undefined(window) && undefined(samples) then begin
        samples = 1 ;use single closest distribution by default
      endif
    endelse
  endif
  ; get the time range if one was specified
  if ~undefined(time_in) then time = time_double(time_in[0])

  ; [CASE C]
  ; time range already provided
  if ~undefined(trange_in) then trange = minmax(time_double(trange_in))

  ; [CASE A]
  ; get the time range if a time & window were specified instead
  if undefined(trange) && keyword_set(window) then begin
    if keyword_set(center_time) then begin
      trange = [time - window/2d, time + window/2d  ]
    endif else begin
      trange = [time, time + window ]
    endelse
  endif

  ; [CASE B]
  ; if no time range or window was specified then get a time range
  ; from the N closest samples to the specied time
  ;   (defaults to 1 if SAMPLES is not defined)
  if undefined(trange) then begin
    trange = spd_slice2d_nearest(pD, time, samples)
  endif
  
  ;--------------------------------------
  ; get 'n_samples'
  ;--------------------------------------
  ; While the user may specify 'samples, 'n_samples' here is the actual number of
  ; samples to be used.
  ; 
  ; check that there is data in range before proceeding
  for i=0, n_elements(pD)-1 do begin
    times_ind = spd_slice2d_intrange(pD[i], trange, n=ndat); the indices of all samples in the specified trange
    n_samples = array_concat(ndat,n_samples)
  endfor
  n_samples = total(n_samples)
  if n_samples lt 1 then begin
    fail = 'No particle data in the time window: '+strjoin(time_string(trange),', ')+ $
      '. Time samples may be at low cadence; try adjusting the time window.'
    dprint, dlevel=1, fail
    return, invalid
  endif
  dprint, dlevel=3, strtrim(n_samples,2) + ' samples in time window'
  if keyword_set(fail) then return, invalid
  nns = min(times_ind,/nan)
  nne = max(times_ind,/nan)
  
  ;------------------------------------------------------------
  ; Check Support data
  ; 
  ; Just to check if mag_data and vel_data exist or not. 
  ; The values 'bfield' and 'vbulk' will not be used in the main loop because 
  ; they are taken from the specified trange Instead, we use the values at each sample.
  ; Thus, the pitch angles are calculated at each sample.  
  ;------------------------------------------------------------
  spd_slice2d_get_support, mag_data, trange, output=bfield
  spd_slice2d_get_support, vel_data, trange, output=vbulk
  if undefined(bfield) then begin
    fail = 'Magnetic field data needed to calculate pitch-angles'
    dprint, dlevel=1, fail
    return, invalid
  endif
  if undefined(vbulk) then begin
    if keyword_set(subtract_bulk) then begin
      fail = 'Velocity data needed to subtract bulk velocity.'
      dprint, dlevel=1, fail
      return, invalid
    endif
  endif else begin
    get_data,vel_data,data=DV
  endelse
  
  ;------------------------------------------------------------
  ; Unit
  ;---------------------------------------------
  units_lc = undefined(units) ? 'eflux' : strlowcase(units)
  units_gl = strmatch(units_lc,'eflux') ? 'eV/(cm!U2!N s sr eV)' : 's!U3!N / km!U6!N'
  species_lc = strlowcase((*pD)[0].species)
  if strmatch(units_lc,'eflux') then begin
    ;get mass of species
    case species_lc of
      'i': A=1;H+
      'hplus': A=1;H+
      'heplus': A=4;He+
      'heplusplus': A=4;He++
      'oplus': A=16;O+
      'oplusplus': A=16;O++
      'e': A=1d/1836;e-
      else: message, 'Unknown species: '+species_lc
    endcase
    ;scaling factor between df and flux units
    flux_to_df = A^2 * 0.5447d * 1d6
    ;convert between km^6 and cm^6 for df_km
    cm_to_km = 1d30

    ; See 'mms_convert_flux_units'
    in = [2,-1,0]; units_in = 'df_km'
    out = [0,0,0]; units_out = 'eflux'
    exp = in + out
  endif

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
  ; Azimuthal Bins
  ;-----------------------------
  amax  = 16
  azmin = 0.
  azmax = 180.
  daz   = (azmax-azmin)/double(amax); bin size
  waz   = azmin + findgen(amax)*daz + 0.5*daz; bin center values
  az_bin = [azmin + findgen(amax)*daz, azmax]
  
  ;-----------------------------
  ; Polar Bins
  ;-----------------------------
  pmax  = 16
  polmin = 0.
  polmax = 360.
  dpol   = (polmax-polmin)/double(pmax); bin size
  wpol   = polmin + findgen(pmax)*dpol + 0.5*dpol; bin center values
  pol_bin = [polmin + findgen(pmax)*dpol, polmax]

  ;-----------------------------
  ; PA (az x pol)
  ;-----------------------------
  pa_azpol = dblarr(amax, pmax)
  pa_azpol[*, *] = !values.d_nan
  
  ;-----------------------------
  ; Energy Bins
  ;-----------------------------
  wegy  = (*pD)[0].ENERGY[*,0,0]
  if keyword_set(subtract_bulk) then begin
    wegy = [2*wegy[0]- wegy[1], wegy]
  endif
  jmax  = n_elements(wegy)
  egy_bin = 0.5*(wegy + shift(wegy,-1))
  egy_bin[jmax-1] = 2.*wegy[jmax-1]-egy_bin[jmax-2]
  egy_bin0        = 2.*wegy[     0]-egy_bin[     0] > 0
  egy_bin = [egy_bin0, egy_bin]

  ;----------------
  ; Prep
  ;----------------
  pad = fltarr(jmax, kmax)
  mmax  = 4
  f_dat = fltarr(jmax,mmax); Four elements for para, perp, anti-para and omni directions
  f_psd = fltarr(jmax,mmax)
  f_err = fltarr(jmax,mmax)
  f_cnt = fltarr(jmax,mmax)
  count_pad   = lonarr(jmax, kmax); number of events in each bin
  count_dat = lonarr(jmax, mmax)

  ;------------------------------------
  ; Magnetic field & Bulk Velocity
  ;------------------------------------
  bnrm_avg = [0., 0., 0.]
  babs_avg = 0.
  Vbulk_avg = [0.d0,0.d0,0.d0]
  Vbulk_para = 0.d0
  Vbulk_perp = 0.d0
  Vbulk_vxb  = 0.d0
  Vbulk_exb  = 0.d0


  ;----------------
  ; Main Loop
  ;----------------
  iecl = 0L
  iecm = 0L
  
  for n=nns,nne do begin

    ;----------------
    ;Sanitize Data.
    ;----------------
    if USEERR then begin
      moka_mms_clean_data,(*pD)[n],output=data,units=units_lc,disterr=(*pDerr)[n]
    endif else begin
      moka_mms_clean_data,(*pD)[n],output=data,units=units_lc
    endelse

    ;------------------------
    ; Magnetic field direction
    ;------------------------
    tr = [(*pD)[n].TIME, (*pD)[n].END_TIME]
    bfield = spd_tplot_average(mag_data, tr)
    babs = sqrt(bfield[0]^2+bfield[1]^2+bfield[2]^2)
    bnrm = bfield/babs
    bnrm_avg += bnrm
    babs_avg += babs
 
    ;------------------------
    ; Bulk Velocity
    ;------------------------
    if keyword_set(subtract_bulk) then begin
      result = min(DV.x-data.TIME,m,/nan,/abs)
      Vbulk = double(reform(DV.y[m,*]))
    endif else begin
      Vbulk = [0., 0., 0.]
    endelse
    vbpara =  bnrm[0]*Vbulk[0]+bnrm[1]*Vbulk[1]+bnrm[2]*Vbulk[2]
    vbperp = Vbulk - vbpara
    vbperp_abs = sqrt(vbperp[0]^2+vbperp[1]^2+vbperp[2]^2)
    vxb = [-Vbulk[1]*bnrm[2]+Vbulk[2]*bnrm[1],-Vbulk[2]*bnrm[0]+Vbulk[0]*bnrm[2],-Vbulk[0]*bnrm[1]+Vbulk[1]*bnrm[0]]
    vxbabs = sqrt(vxb[0]^2+vxb[1]^2+vxb[2]^2)
    vxbnrm = vxb/vxbabs
    exb = [vxb[1]*bnrm[2]-vxb[2]*bnrm[1],vxb[2]*bnrm[0]-vxb[0]*bnrm[2],vxb[0]*bnrm[1]-vxb[1]*bnrm[0]]
    exbabs = sqrt(exb[0]^2+exb[1]^2+exb[2]^2)
    exbnrm = exb/exbabs
    Vbulk_para += vbpara
    Vbulk_perp += vbperp_abs
    Vbulk_vxb  += vxbnrm[0]*Vbulk[0]+vxbnrm[1]*Vbulk[1]+vxbnrm[2]*Vbulk[2]
    Vbulk_exb  += exbnrm[0]*Vbulk[0]+exbnrm[1]*Vbulk[1]+exbnrm[2]*Vbulk[2]
    Vbulk_avg += Vbulk
    
    ;------------------------------------
    ; Particle Velocities & Pitch Angles
    ;------------------------------------

    ; Spherical to Cartesian
    erest = data.mass * !const.c^2 / 1e6; convert mass from eV/(km/s)^2 to eV
    vabs = !const.c * sqrt( 1 - 1/((data.ENERGY/erest + 1)^2) )  /  1000.;velocity in km/s
    sphere_to_cart, vabs, data.theta, data.phi, vx, vy, vz

    ; Frame transformation
    ;    if undefined(vlmpot) then begin
    if keyword_set(subtract_bulk) then begin; Plasma rest-frame
      vx -= Vbulk[0]
      vy -= Vbulk[1]
      vz -= Vbulk[2]
    endif
    ;    endif else begin; Another frame (under development)
    ;      bvec = double(moka_tplot_average(bname, tr,norm=0))
    ;      moka_mms_vlm, vx, vy, vz, Vbulk, bvec, vlm
    ;    endelse

    ; Pitch angles
    dp  = (bnrm[0]*vx + bnrm[1]*vy + bnrm[2]*vz)/sqrt(vx^2+vy^2+vz^2)
    idx = where(dp gt  1.d0, ct) & if ct gt 0 then dp[idx] =  1.d0
    idx = where(dp lt -1.d0, ct) & if ct gt 0 then dp[idx] = -1.d0
    pa  = rd*acos(dp)

    ; Cartesian to Spherical
    cart_to_sphere, vx, vy, vz, vnew, theta, phi, /ph_0_360
    data.energy = erest*(1.d0/sqrt(1.d0-(vnew*1000.d0/!const.c)^2)-1.d0); eV
    data.phi    = phi
    data.theta  = theta
    data.pa     = pa



    azang = 90.-data.theta
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
      
      ; Find azimuthal bin
      result = min(az_bin-azang[i],a,/abs)
      if az_bin[a] gt azang[i] then a -= 1
      if a eq amax then a -= 1
      
      ; Find polar bin
      result = min(pol_bin-data.phi[i],p,/abs)
      if pol_bin[p] gt data.phi[i] then p -= 1
      if p eq pmax then p -= 1


      if j ge 0 then begin
        pa_azpol[a, p] = data.pa[i]

        ;-----------------------
        ; Find new eflux
        ;-----------------------
        ; If shifted to plasma rest-frame, 'eflux' should be re-evaluated
        ; from 'psd' because 'eflux' depends on the particle energy. We don't need to
        ; worry about this if we want the output in 'psd'.
        newenergy = wegy[j]
        if strmatch(units_lc,'eflux') then begin; If plasma rest-frame AND efluxs
          ; See 'mms_convert_flux_units'
          newdat = double(data.data_psd[i]) * double(newenergy)^exp[0] * (flux_to_df^exp[1] * cm_to_km^exp[2])
          newpsd = newdat
          newerr = double(data.data_err[i]) * double(newenergy)^exp[0] * (flux_to_df^exp[1] * cm_to_km^exp[2])
        endif else begin
          newdat = data.data_dat[i]
          newpsd = data.data_psd[i]
          newerr = data.data_err[i]
        endelse

        ; pitch-angle distribution
        pad[j,k] += newdat
        count_pad[j,k] += 1L

        ; energy spectrum (para, perp, anti-para)
        m = -1
        if (pr__90[0] le data.pa[i]) and (data.pa[i] le pr__90[1]) then begin
          m = 1
        endif else begin
          if (pr___0[0] le data.pa[i]) and (data.pa[i] le pr___0[1]) then m=0
          if (pr_180[0] le data.pa[i]) and (data.pa[i] le pr_180[1]) then m=2
        endelse
        if (m ge 0) and (m le 2) then begin
          f_dat[j,m] += newdat
          f_psd[j,m] += newpsd
          f_err[j,m] += newerr
          f_cnt[j,m] += data.data_cnt[i]
          count_dat[j,m] += 1L
        endif

        ; energy spectrum (omni-direction)
        m = 3
        f_dat[j,m] += newdat
        f_psd[j,m] += newpsd
        f_err[j,m] += newerr
        f_cnt[j,m] += data.data_cnt[i]
        count_dat[j,m] += 1L

      endif else begin; if j ge 0
        iecl += 1L
      endelse
    endfor; for each particle
    iecm += imax
  endfor; for n=nns, nne
  
  if iecl gt 0 then begin
    dprint,dlevel=1, '---'
    dprint,dlevel=1,strtrim(string(iecl),2)+' out of '+strtrim(string(iecm),2)+' particles were not'
    dprint,dlevel=1,'used in the result because of the bulk-speed subtraction'
    dprint,dlevel=1,'and their energies have moved outside the defined energy bins.'
    dprint,dlevel=1,'---'
  endif

  pad /= float(count_pad)
  f_dat /= float(count_dat)
  f_psd /= float(count_dat)
  f_err /= float(count_dat)
  f_cnt /= float(count_dat)

  vbulk_para /= float(n_samples)
  vbulk_perp /= float(n_samples)
  vbulk_vxb  /= float(n_samples)
  vbulk_exb  /= float(n_samples)
  Vbulk_avg /= float(n_samples)
  
  bnrm_avg  /= float(n_samples)
  babs_avg /= float(n_samples)
  
  idx = where(~finite(pad),ct)
  if ct gt 0 then pad[idx] = 0.

  ;---------------
  ; ANGLE PADDING
  ;---------------
  padnew = fltarr(jmax, kmax+2)
  padnew[0:jmax-1,1:kmax] = pad
  padnew[0:jmax-1,     0] = padnew[0:jmax-1,   1]
  padnew[0:jmax-1,kmax+1] = padnew[0:jmax-1,kmax]
  pad = padnew
  wpa_new = [wpa[0]-dpa,wpa,wpa[kmax-1]+dpa]
  wpa = wpa_new

  ;---------------
  ; NORMALIZE
  ;---------------
  padnorm = pad
  for j=0,jmax-1 do begin; for each energy
    peak = max(pad[j,0:kmax+1],/nan); find the peak
    if peak eq 0 then begin
      padnorm[j,0:kmax+1] = 0.
    endif else begin
      padnorm[j,0:kmax+1] /= peak
    endelse
  endfor
  if keyword_set(norm) then pad = padnorm

  ;----------------------------
  ; Effective one-count-level
  ;----------------------------
  ; 'f_psd' is the PSD    averaged over time and angular ranges.
  ; 'f_cnt' is the counts averaged over time and angular ranges.
  ; 'count_dat is the total number of time and angular bins.
  if keyword_set(oclreal) then begin
    f_ocl = f_psd/f_cnt
  endif else begin
    f_ocl = f_psd/(f_cnt*float(count_dat))
  endelse
    

  ;---------------
  ; OUTPUT
  ;---------------

  return, {trange:trange,$
    egy:wegy, pa:wpa, data:pad, datanorm:padnorm, $
    numSlices: n_samples, nbin:kmax, units:units_gl,subtract_bulk:subtract_bulk,$
    egyrange:[min(wegy),max(wegy)], parange:[min(wpa),max(wpa)], $
    spec___0:f_psd[*,0], spec__90:f_psd[*,1], spec_180:f_psd[*,2], spec_omn:f_psd[*,3], $
    cnts___0:f_cnt[*,0], cnts__90:f_cnt[*,1], cnts_180:f_cnt[*,2], cnts_omn:f_cnt[*,3], $
    oclv___0:f_ocl[*,0], oclv__90:f_ocl[*,1], oclv_180:f_ocl[*,2], oclv_omn:f_ocl[*,3], $
    eror___0:f_err[*,0], eror__90:f_err[*,1], eror_180:f_err[*,2], eror_omn:f_err[*,3], $
    vbulk_para:vbulk_para, vbulk_perp_abs:vbulk_perp, vbulk_vxb:vbulk_vxb, $
    vbulk_exb:vbulk_exb, bnrm:bnrm_avg, Vbulk:Vbulk_avg, bfield:bnrm_avg*babs_avg,$
    species:species_lc, pa_azpol:pa_azpol, wpol: wpol, waz: waz}
END
