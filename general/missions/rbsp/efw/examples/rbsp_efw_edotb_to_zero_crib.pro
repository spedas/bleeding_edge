;Crib sheet to calculate the RBSP spin-axis Efield under the assumption that E*B=0.
;
;Bad E*B=0 data are removed
;
;
;
;
;Spin axis values calculated from E*B=0 as
;Ex = -1*(EyBy + EzBz)/Bx
;
;The ratios By/Bx and Bz/Bx can fluctuate wildly when Bx gets too small. Therefore we
;require that these ratios are less than a certain size (i.e. sufficiently big Bx).
;The standard (from Cluster) is to assume that the angle between any of the spinplane directions
;(MGSE y and z in this case) and Bo is greater than 15 degrees.
;	delta = angle(Bz, Bo) > 15
;	epsilon = angle(By, Bo) > 15
;	gamma = angle(Bx, Bo) < 75
;
;Writing out the dot products we get:
;	cos(delta) = Bz/Bo
;	cos(epsilon) = By/Bo
;	cos(gamma) = Bx/Bo
;
;We can rearrange these as:
;	By/Bx = cos(epsilon)/cos(gamma)
;	Bz/Bx = cos(delta)/cos(gamma)
;
;To find the max value of these ratios let epsilon = 15 deg, delta = 15, gamma = 75 deg.
;	By/Bx = 3.732
;	Bz/Bx = 3.732
;
;Keywords:
;   noremove - Don't remove ExMGSE (spinaxis) values when By/Bx>3.732 or Bz/Bx>3.732
;   anglemin --> change the minimum allowable angle to something other than 15 deg
;               Smaller angles will lead to less removed data, but are more risky.
;
;Written by Aaron W Breneman (UMN) - 2013-06-19
;



pro rbsp_efw_edotb_to_zero_crib,date,probe,no_spice_load=no_spice_load,suffix=suffix,$
  noplot=noplot,nospinfit=nospinfit,ql=ql,boom_pair=bp,$
  rerun=rerun,noremove=noremove,anglemin=anglemin,bad_probe=bad_probe

  if ~KEYWORD_SET(anglemin) then anglemin = 15.

  limiting_ratio = cos(anglemin*!dtor)/cos((90-anglemin)*!dtor)


  rbspx = 'rbsp' + probe
  timespan,date


  if ~keyword_set(ql) then ql = 0
  if ~keyword_set(bp) then bp = '12'
  if ~keyword_set(rerun) then rerun = 0.

  ;Stuff to make plots pretty
  rbsp_efw_init
  !p.charsize = 1.2
  tplot_options,'xmargin',[20.,15.]
  tplot_options,'ymargin',[3,6]
  tplot_options,'xticklen',0.08
  tplot_options,'yticklen',0.02
  tplot_options,'xthick',2
  tplot_options,'ythick',2


  ;load eclipse times
  rbsp_load_eclipse_predict,probe,date
  get_data,'rbsp'+probe+'_umbra',data=eu
  get_data,'rbsp'+probe+'_penumbra',data=ep


  ;; ;Load spice
  ;; 	if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels
  ;; 	rbsp_load_spice_state,probe=probe,coord='gse',/no_spice_load
  ;; 	store_data,'rbsp'+probe+'_state_pos_gse',newname='rbsp'+probe+'_pos_gse'
  ;; 	store_data,'rbsp'+probe+'_state_vel_gse',newname='rbsp'+probe+'_vel_gse'


  ;Load spinfit MGSE Efield and Bfield
  if ~keyword_set(nospinfit) then begin
    rbsp_efw_spinfit_vxb_subtract_crib,probe,/noplot,ql=ql,boom_pair=bp;,bad_probe=bad_probe;,rerun=rerun
    evar = 'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit'
  endif else begin
    rbsp_efw_vxb_subtract_crib,probe,/noplot,ql=ql,bad_probe=bad_probe
    evar = 'rbsp'+probe+'_efw_esvy_mgse_vxb_removed'
  endelse


  ;tplot,'rbsp'+probe+'_' + ['vxb_mgse', 'sfit12_mgse']
  ;	if ~keyword_set(noplot) then tplot,'rbsp'+probe+'_' + ['vxb_mgse','rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit']
  if ~keyword_set(noplot) then tplot,'rbsp'+probe+'_' + ['vxb_mgse',evar]



  ;Grab the spinfit Ew and Bw data
  split_vec,'rbsp'+probe+'_mag_mgse'
  ;	get_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit',data=sfit
  get_data,evar,data=edata



  if is_struct(edata) then tinterpol_mxn,'rbsp'+probe+'_mag_mgse',edata.x,newname='rbsp'+probe+'_mag_mgse'


  ;smooth the background magnetic field
  ;over 30 min for the E*B=0 calculation
  rbsp_detrend,'rbsp'+probe+'_mag_mgse',60.*30.


  get_data,'rbsp'+probe+'_mag_mgse',data=magmgse
  get_data,'rbsp'+probe+'_mag_mgse_smoothed',data=magmgse_smoothed

  if ~is_struct(magmgse) then begin
    print,'NO MAG DATA FOR rbsp_efw_EdotB_to_zero_crib.pro TO USE...RETURNING'
    return
  endif


  bmag = sqrt(magmgse.y[*,0]^2 + magmgse.y[*,1]^2 + magmgse.y[*,2]^2)
  bmag_smoothed = sqrt(magmgse_smoothed.y[*,0]^2 + magmgse_smoothed.y[*,1]^2 + magmgse_smoothed.y[*,2]^2)


  ;Replace axial measurement with E*B=0 version
  edata.y[*,0] = -1*(edata.y[*,1]*magmgse_smoothed.y[*,1] + edata.y[*,2]*magmgse_smoothed.y[*,2])/magmgse_smoothed.y[*,0]
  ;; if ~keyword_set(suffix) then store_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit',data=edata
  ;; if keyword_set(suffix) then store_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit'+'_'+suffix,data=edata
  if ~keyword_set(suffix) then store_data,evar,data=edata
  if keyword_set(suffix) then store_data,evar+'_'+suffix,data=edata


  ;Find bad E*B=0 data (where the angle b/t spinplane MGSE and Bo is less than 15 deg)
  ;Good data has By/Bx < 3.732   and  Bz/Bx < 3.732

  By2Bx = abs(magmgse_smoothed.y[*,1]/magmgse_smoothed.y[*,0])
  Bz2Bx = abs(magmgse_smoothed.y[*,2]/magmgse_smoothed.y[*,0])
  store_data,'B2Bx_ratio',data={x:edata.x,y:[[By2Bx],[Bz2Bx]]}
  ylim,'B2Bx_ratio',0,40
  options,'B2Bx_ratio','ytitle','By/Bx (black)!CBz/Bx (red)'
  badyx = where(By2Bx gt limiting_ratio)
  badzx = where(Bz2Bx gt limiting_ratio)

  ;Calculate specific limiting angles
  angle_bybx = atan(1/By2Bx)/!dtor
  angle_bzbx = atan(1/Bz2Bx)/!dtor
  store_data,'angle_B2Bx',edata.x,[[angle_bzbx],[angle_bybx]]
  options,'angle_B2Bx','ytitle','Limiting angles!CAngle Bz/Bx(black)!CAngle ByBx(red)'
  options,'angle_B2Bx','colors',[0,250]
  options,'angle_B2Bx','constant',anglemin
  ylim,'angle_B2Bx',0.1,100,1


  ;calculate angles b/t despun spinplane antennas and Bo.
  n = n_elements(edata.x)
  ang_ey = fltarr(n)
  ang_ez = fltarr(n)


  ;Don't do this calculation for esvy-despun. Takes too long
  if n_elements(edata.x) le 86400. then begin
    for i=0L,n-1 do ang_ey[i] = acos(total([0,1,0]*magmgse_smoothed.y[i,*])/(bmag_smoothed[i]))/!dtor
    for i=0L,n-1 do ang_ez[i] = acos(total([0,0,1]*magmgse_smoothed.y[i,*])/(bmag_smoothed[i]))/!dtor
    store_data,'angles',data={x:edata.x,y:[[ang_ey],[ang_ez]]}
  endif


  ;Calculate ratio b/t spinaxis and spinplane components
  e_sp = sqrt(edata.y[*,1]^2 + edata.y[*,2]^2)
  rat = abs(edata.y[*,0])/e_sp
  store_data,'rat',data={x:edata.x,y:rat}
  store_data,'e_sp',data={x:edata.x,y:e_sp}
  store_data,'e_sa',data={x:edata.x,y:abs(edata.y[*,0])}
  options,'rat','constant',1

  ;Check for Spinfit saturation
  ;; get_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit',data=tmpp
  get_data,evar,data=tmpp
  badsatx = where(abs(tmpp.y[*,0]) ge 195.)
  badsaty = where(abs(tmpp.y[*,1]) ge 195.)
  badsatz = where(abs(tmpp.y[*,2]) ge 195.)



  ;Remove bad Efield data
  ;....saturated data from the rest of the tplot variables
  ;....saturated data from Ex
  ;....Ex data when the E*B=0 calculation is unreliable

  ;; if ~keyword_set(suffix) then get_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit',data=tmpp
  ;; if keyword_set(suffix) then  get_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit_'+suffix,data=tmpp
  if ~keyword_set(suffix) then get_data,evar,data=tmpp
  if keyword_set(suffix) then  get_data,evar+'_'+suffix,data=tmpp

  if ~keyword_set(noremove) then begin
    if badyx[0] ne -1 then tmpp.y[badyx,0] = !values.f_nan
    if badzx[0] ne -1 then tmpp.y[badzx,0] = !values.f_nan
    if badsatx[0] ne -1 then tmpp.y[badsatx,0] = !values.f_nan
    if badsaty[0] ne -1 then tmpp.y[badsaty,1] = !values.f_nan
    if badsatz[0] ne -1 then tmpp.y[badsatz,2] = !values.f_nan
  endif

  ;; if ~keyword_set(suffix) then store_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit',data=tmpp
  ;; if keyword_set(suffix) then  store_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit_'+suffix,data=tmpp
  if ~keyword_set(suffix) then store_data,evar,data=tmpp
  if keyword_set(suffix) then  store_data,evar+'_'+suffix,data=tmpp

  get_data,'rat',data=tmpp
  if badyx[0] ne -1 then tmpp.y[badyx] = !values.f_nan
  if badzx[0] ne -1 then tmpp.y[badzx] = !values.f_nan
  if badsatx[0] ne -1 then tmpp.y[badsatx] = !values.f_nan
  if badsaty[0] ne -1 then tmpp.y[badsaty] = !values.f_nan
  if badsatz[0] ne -1 then tmpp.y[badsatz] = !values.f_nan
  store_data,'rat',data=tmpp

  get_data,'e_sa',data=tmpp
  if badyx[0] ne -1 then tmpp.y[badyx] = !values.f_nan
  if badzx[0] ne -1 then tmpp.y[badzx] = !values.f_nan
  if badsatx[0] ne -1 then tmpp.y[badsatx] = !values.f_nan
  if badsaty[0] ne -1 then tmpp.y[badsaty] = !values.f_nan
  if badsatz[0] ne -1 then tmpp.y[badsatz] = !values.f_nan
  store_data,'e_sa',data=tmpp

  get_data,'e_sp',data=tmpp
  if badyx[0] ne -1 then tmpp.y[badyx] = !values.f_nan
  if badzx[0] ne -1 then tmpp.y[badzx] = !values.f_nan
  if badsatx[0] ne -1 then tmpp.y[badsatx] = !values.f_nan
  if badsaty[0] ne -1 then tmpp.y[badsaty] = !values.f_nan
  if badsatz[0] ne -1 then tmpp.y[badsatz] = !values.f_nan
  store_data,'e_sp',data=tmpp




  ;Remove corotation field
  ;; dif_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit','rbsp'+probe+'_E_coro_mgse',newname='rbsp'+probe+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit'
  ;; if keyword_set(suffix) then dif_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit_'+suffix,'rbsp'+probe+'_E_coro_mgse',newname='rbsp'+probe+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_'+suffix

  if ~keyword_set(nospinfit) then begin
    dif_data,evar,'rbsp'+probe+'_E_coro_mgse',newname='rbsp'+probe+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit'
    if keyword_set(suffix) then dif_data,evar+'_'+suffix,'rbsp'+probe+'_E_coro_mgse',newname='rbsp'+probe+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_'+suffix
  endif else begin
    dif_data,evar,'rbsp'+probe+'_E_coro_mgse',newname='rbsp'+probe+'_efw_esvy_mgse_vxb_removed_coro_removed'
    if keyword_set(suffix) then dif_data,evar+'_'+suffix,'rbsp'+probe+'_E_coro_mgse',newname='rbsp'+probe+'_efw_esvy_mgse_vxb_removed_coro_removed_'+suffix
  endelse

  ;Plot results

  options,'rat','ytitle','|Espinaxis|/!C|Espinplane|'
  options,'e_sp','ytitle','|Espinplane|'
  options,'e_sa','ytitle','|Espinaxis|'
  options,'angles','ytitle','angle b/t Ey & Bo!CEz & Bo (red)'
  ;	ylim,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit',-10,10
  ylim,evar,-10,10
  ylim,'rbsp'+probe+'_mag_mgse',-200,200
  ylim,['e_sa','e_sp','rat'],0,10
  ylim,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit',-20,20
  ylim,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit',-20,20

  ;	options,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit','labels',['xMGSE','yMGSE','zMGSE']
  options,evar,'labels',['xMGSE','yMGSE','zMGSE']

  ;Create Emag variable. The Efield magnitude shouldn't change as a function
  ;of the spinaxis angle to Bo if the calculated Ex component is accurate (assuming
  ;a steady background Efield)
  if ~KEYWORD_SET(nospinfit) then $
    get_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit',etimes,edata else $
    get_data,'rbsp'+probe+'_efw_esvy_mgse_vxb_removed',etimes,edata

  emag = sqrt(edata[*,0]^2 + edata[*,1]^2 + edata[*,2]^2)
  store_data,'emag',etimes,emag


  tplot_options,'title','RBSP-'+probe + ' ' + date
  if ~keyword_set(noplot) then begin
    if ~keyword_set(nospinfit) then begin
      tplot,['rbsp'+probe+'_mag_mgse',$
      'rbsp'+probe+'_mag_mgse_smoothed',$
;      'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_spinfit',$
      'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit',$
;      'rbsp'+probe+'_E_coro_mgse',$
      'emag',$
      'angle_B2Bx',$
      'rat',$
      'e_sa',$
      'e_sp']
    endif else begin
      tplot,['rbsp'+probe+'_mag_mgse',$
      'rbsp'+probe+'_mag_mgse_smoothed',$
      'rbsp'+probe+'_efw_esvy_mgse_vxb_removed',$
      'rbsp'+probe+'_efw_esvy_mgse_vxb_removed_coro_removed',$
;      'rbsp'+probe+'_E_coro_mgse',$
      'angle_B2Bx',$
      'emag',$
      'rat',$
      'e_sa',$
      'e_sp']

    endelse
    if keyword_set(eu) then timebar,eu.x
    if keyword_set(eu) then timebar,eu.x + eu.y
  endif



end
