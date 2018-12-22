;+
; NAME:
;   rbsp_spinfit (procedure)
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
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_spinfit ,var_name_in, $
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
; $LastChangedDate: 2018-12-21 11:30:03 -0800 (Fri, 21 Dec 2018) $
; $LastChangedRevision: 26393 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_spinfit.pro $
;
;-

pro rbsp_spinfit ,var_name_in, $
  sigma=sigma, npoints=npoints, spinaxis=spinaxis, median=median, $
  plane_dim=plane_dim, axis_dim=axis_dim,  $
  min_points=min_points,alpha=alpha,beta=beta, $
  phase_mask_starts=phase_mask_starts, $
  phase_mask_ends=phase_mask_ends, $
  sc = sc, force = force, tper = tper, tphase = tphase



  compile_opt idl2

  tvar = var_name_in
  if n_elements(sc) eq 0 then sc = strlowcase(strmid(tvar, 4, 1))
  rbx = 'rbsp' + sc + '_'

  ;Check coordinate system
  if cotrans_get_coord(tvar) ne 'uvw' and ~keyword_set(force) then begin
    dprint, tvar, ' is not in UVW coordinate system. Abort.'
    return
  endif

  if n_elements(plane_dim) eq 0 then plane_dim = 0

  case plane_dim of
    0: begin
      sun2sensor = -10d ; in degree
      boomfix = '_e12'
      end
    1: begin
      sun2sensor = -100d ; in degree
      boomfix = '_e34'
      end
    else: begin
      dprint, 'Invalid plane_dim value. Abort.'
      return
      end
  endcase

  ;Get spinper and spinphase
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
   sunpulse="thx_sunpulse_times"



  ;get_data, 'thx_sunpulse_times',data=thx_sunpulse_times
  ;tt0 = time_double('2015-04-12/04:45:56')
  ;tt1 = time_double('2015-04-12/04:47:56')
  ;goo = where((thx_sunpulse_times.x ge tt0) and (thx_sunpulse_times.x le tt1))
  ;thx_sunpulse_times.y[goo] = !values.f_nan  ;10.81

  ;tt0 = time_double('2015-04-12/09:34:45')
  ;tt1 = time_double('2015-04-12/09:36:03')
  ;goo = where((thx_sunpulse_times.x ge tt0) and (thx_sunpulse_times.x le tt1))
  ;thx_sunpulse_times.y[goo] = !values.f_nan ;10.79

  ;tt0 = time_double('2015-04-12/19:10:35')
  ;tt1 = time_double('2015-04-12/19:13:35')
  ;goo = where((thx_sunpulse_times.x ge tt0) and (thx_sunpulse_times.x le tt1))
  ;thx_sunpulse_times.y[goo] = !values.f_nan ;10.81

  ;store_data,'thx_sunpulse_times',data=thx_sunpulse_times



  get_data, 'thx_sunpulse_times',data=thx_sunpulse_times
  del_data, 'thx_sunpulse_times' ;remove probe specific temp variable




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

  store_data, tvar +'_spinfit'+boomfix+'_a',data={x:sun_midpoint,y:a}, dl = dl
  store_data, tvar +'_spinfit'+boomfix+'_b',data={x:sun_midpoint,y:b}, dl = dl
  store_data, tvar +'_spinfit'+boomfix+'_c',data={x:sun_midpoint,y:c}, dl = dl


  ;**********TESTING

  ;The timetags shift by 0.3 sec during the spike.
  ;store_data,'timetest',sun_midpoint,sun_midpoint - shift(sun_midpoint,1) - 10.809
  ;store_data,'timetest2',thx_xxx_in.x,thx_xxx_in.x - shift(thx_xxx_in.x,1) - 0.03125

  ;tplot,[77,78,79,80,81]
  ;Sun midpoint seems to be developing a large (0.3 sec) error.

  ;******************

  ;Output sigma
  if keyword_set(sigma) then $
    store_data, tvar+'_spinfit'+boomfix+'_sig',data={x:sun_midpoint,y:s}, $
    dl = dl
  if keyword_set(Npoints) then $
    store_data, tvar+'_spinfit'+boomfix+'_npoints', $
    data={x:sun_midpoint,y:n}, dl = dl

  if keyword_set(spinaxis) then begin
    if keyword_set(median)then begin
      store_data, tvar+'_spinfit'+boomfix+'_med',$
        data={x:sun_midpoint,y:med_axis}, dl = dl
    endif else store_data, tvar+'_spinfit'+boomfix+'_avg',$
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
