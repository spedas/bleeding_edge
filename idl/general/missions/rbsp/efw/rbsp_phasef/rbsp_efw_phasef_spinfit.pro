;+
; Adopted from rbsp_efw_phasef_spinfit, but changed the part to get sunpulse_times.
;
; NAME:
;   rbsp_efw_phasef_spinfit (procedure)
;
; PURPOSE:
;   Derive spin-fit E-field from instantaneous E-field measurements. The
;   spin-fit model is as such:
;           fit = A + B * cos(phi) + C * sin(phi)
;   where B and C are E-fields in the DSC X and Y dimensions, and angle is the
;   angle between the DSC X direction and the EFW spin plane boom used in the
;   spin-fit derivation, as demonstrated below.
;
;       DSC Y
;            |       / EFW spin plane boom
;            |      /
;            |     /
;            |    /
;            |   /
;            |  /
;            | /
;            |/)angle________ DSC X
;
;   NOTES: 1. Similar to thm_spinfit.pro, this routine is a wrapper of
;             spinfit.pro for RBSP. Unlike thm_spinfit, this routine only works
;             on one tplot variable at a time.
;          2. Normally, this routine saves four tplot variables, such as
;                  'rbspa_efw_esvy_spinfit_a'
;                  'rbspa_efw_esvy_spinfit_b'
;                  'rbspa_efw_esvy_spinfit_c'
;                  'rbspa_efw_esvy_spinfit'
;             where the first three are the three cooefficients from the fit and
;             the last one is like a normal EFW data type in DSC.
;          3. This routine passes a [n,3] waveform to spinfit.pro for spinfitting.
;             spinfit.pro does stuff with all three components, but since we're only
;             interested in getting the RBSP spinplane spinfit field, the only
;             component that matters is the one you're interested in using to do
;             the spinfit.
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_efw_phasef_spinfit ,var_name_in, $
;             sigma=sigma, npoints=npoints, spinaxis=spinaxis, median=median, $
;             plane_dim=plane_dim, axis_dim=axis_dim,  $
;             min_points=min_points,alpha=alpha,beta=beta, $
;             phase_mask_starts=phase_mask_starts, $
;             phase_mask_ends=phase_mask_ends, $
;             sc = sc, force = force, tper = tper, tphase = tphase
;
; ARGUMENTS:
;   var_name_in: IN, REQUIRED
;         EFW tplot data used for the spin-fit derivation. Must be in UVW.
;
; KEYWORDS:
;   sc: IN, OPTIONAL
;         Spacecraft name. Must be 'a' or 'b'.
;   /force: IN, OPTIONAL
;         If set, force to do the derivation. Useful when the input tplot data
;         do not have coord_sys information.
;   tper: IN, OPTIONAL
;         Spin-period tplot name.
;   tphase: IN, OPTIONAL
;         Spin-phase tplot name.
;
;     See spinfit.pro and thm_spinfit.pro for usage of other keywords.
;     Exception:
;     AXIS_DIM defaults to 2 instead of 0 in this routine.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2013-01-22: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2018-12-21 13:30:03 -0600 (Fri, 21 Dec 2018) $
; $LastChangedRevision: 26393 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_phasef_spinfit.pro $
;
;-

pro rbsp_efw_phasef_spinfit, var_name_in, $
  sigma=sigma, npoints=npoints, spinaxis=spinaxis, median=median, $
  plane_dim=plane_dim, axis_dim=axis_dim,  $
  min_points=min_points,alpha=alpha,beta=beta, $
  phase_mask_starts=phase_mask_starts, $
  phase_mask_ends=phase_mask_ends, $
  sc = sc, force = force, tper = tper, tphase = tphase,$
  sun2sensor=sun2sensor, sheng_test=sheng_test



  compile_opt idl2

  tvar = var_name_in
  if n_elements(sc) eq 0 then sc = strlowcase(strmid(tvar, 4, 1))
  rbx = 'rbsp' + sc + '_'

  ;Check coordinate system
  if cotrans_get_coord(tvar) ne 'uvw' and ~keyword_set(force) then begin
    dprint, tvar, ' is not in UVW coordinate system. Abort.'
    return
  endif

  if n_elements(plane_dim) eq 0 then plane_dim = 0 ;(set to E12 pair by default)


  ;If sun2sensor isn't manually set, set it here
  if ~KEYWORD_SET(sun2sensor) then begin
;    if plane_dim eq 0 then sun2sensor = -10d  ;(for E12 pair)
;    if plane_dim eq 1 then sun2sensor = -100d ;(for E34 pair)
    if plane_dim eq 0 then sun2sensor = -0d
    if plane_dim eq 1 then sun2sensor = -90d   ; Sheng: 10 deg is accounted for in dsc_to_mgse?
  endif





;---Load data from new algorithm.
    sunpulse_var = rbx+'sunpulse_times'
    if tnames(sunpulse_var) eq '' then message, $
        'Load sun pulse time first, using rbsp_efw_phasef_read_sunpulse_time'
    get_data, sunpulse_var, data=thx_sunpulse_times


if keyword_set(sheng_test) then begin
;---Old algorithm.
    ;Get spinper and spinphase (these come from rbsp_read_spice_var.pro)
    if n_elements(tper) eq 0 then tper = rbx + 'spinper'
    if n_elements(tphase) eq 0 then tphase = rbx + 'spinphase'

    ;Downsample spin phase and spin period.
    trange = timerange()
    dt = 60d ; in seconds
    nt = round((trange[1] - trange[0]) / dt) + 1L
    tarr = trange[0] + dindgen(nt) * dt
    ind = where(tarr lt trange[1], nind)
    tarr = tarr[ind]

    phase = rbsp_interp_spin_phase(sc, tarr, tper = tper, tphase = tphase)
    get_data, tper, data=dat
    per_arr = interp(dat.y, dat.x, tarr, /ignore_nan)

    thx_spinphase = {x:tarr, y:phase}
    thx_spinper = {x:tarr, y:per_arr}


    thm_sunpulse,thx_spinphase.x,thx_spinphase.y,thx_spinper.y, $
        sunpulse="thx_sunpulse_times_old"

    vars = 'thx_sunpulse_times'+['','_old']
    options, vars, 'ynozero', 1
    tplot, vars
    stop
endif



  ;Get data
  get_data, tvar, data=thx_xxx_in, dl = dl



  ;Set default value of spin axis dimension.
  if n_elements(axis_dim) eq 0 then axis_dim = 2
  ;Do spin fit.
  t1 = systime(/sec)
  spinfit, thx_xxx_in.x, thx_xxx_in.y, $
    thx_sunpulse_times.x, thx_sunpulse_times.y, $
    a, b, c, spin_axis, med_axis, s, n, sun_data, $
    min_points = min_points, alpha = alpha, beta = beta, $
    plane_dim = plane_dim, axis_dim = axis_dim, $
    phase_mask_starts = phase_mask_starts, $
    phase_mask_ends=phase_mask_ends, $
    sun2sensor=sun2sensor



  t2 = systime(/sec)
  print, 'SPINFIT time: ', t2 - t1, ' seconds'

  sizesun=size(sun_data)
  sun_midpoint=fltarr(sizesun[1])
  ;for j=0,sizesun[1]-2 do sun_midpoint[j]=(sun_data[j]+sun_data[j+1])/2
  sun_midpoint=sun_data


  ;metadata:
  str_element, dl, 'data_att', data_att, success=has_data_att
  if has_data_att then str_element, data_att, 'boom', boomfix, /add  $
    else data_att = { data_type: boomfix }
  str_element, dl, 'data_att', data_att, /add
  str_element, dl,'labels',/delete


;  store_data, tvar +'_spinfit_'+bp+'_a',data={x:sun_midpoint,y:a}, dl = dl
;  store_data, tvar +'_spinfit_'+bp+'_b',data={x:sun_midpoint,y:b}, dl = dl
;  store_data, tvar +'_spinfit_'+bp+'_c',data={x:sun_midpoint,y:c}, dl = dl
  store_data, tvar +'_spinfit_a',data={x:sun_midpoint,y:a}, dl = dl
  store_data, tvar +'_spinfit_b',data={x:sun_midpoint,y:b}, dl = dl
  store_data, tvar +'_spinfit_c',data={x:sun_midpoint,y:c}, dl = dl


  ;**********TESTING

  ;The timetags shift by 0.3 sec during the spike.
  ;store_data,'timetest',sun_midpoint,sun_midpoint - shift(sun_midpoint,1) - 10.809
  ;store_data,'timetest2',thx_xxx_in.x,thx_xxx_in.x - shift(thx_xxx_in.x,1) - 0.03125

  ;tplot,[77,78,79,80,81]
  ;Sun midpoint seems to be developing a large (0.3 sec) error.

  ;******************

  ;Output sigma
  if keyword_set(sigma) then $
;    store_data, tvar+'_spinfit_'+bp+'_sig',data={x:sun_midpoint,y:s}, $
    store_data, tvar+'_spinfit_sig',data={x:sun_midpoint,y:s}, $
    dl = dl
  if keyword_set(Npoints) then $
    store_data, tvar+'_spinfit_npoints', $
    ;store_data, tvar+'_spinfit_'+bp+'_npoints', $
    data={x:sun_midpoint,y:n}, dl = dl

  if keyword_set(spinaxis) then begin
    if keyword_set(median)then begin
      store_data, tvar+'_spinfit_med',$
;      store_data, tvar+'_spinfit_'+bp+'_med',$
        data={x:sun_midpoint,y:med_axis}, dl = dl
    endif else store_data, tvar+'_spinfit_avg',$
;    endif else store_data, tvar+'_spinfit_'+bp+'_avg',$
      data={x:sun_midpoint,y:spin_axis}, dl = dl
  endif

  ;Create a tplot variable like a normal EFW data type.
  y = [[b], [c], [spin_axis]]
  x = sun_midpoint
  data = {x:x, y:y}
  str_element, data_att, 'coord_sys', 'dsc', /add
  str_element, dl, 'data_att', data_att, /add
  str_element, dl,'labels',['Ex DSC', 'Ey DSC', 'Ez DSC'], /add

  store_data, tvar + '_spinfit', data = data, dl = dl
  options, tvar + '_spinfit', colors = [2,4,6], labflag = 1





end


rbsp_efw_phasef_spinfit, 'rbspa_e_combo_13'
end
