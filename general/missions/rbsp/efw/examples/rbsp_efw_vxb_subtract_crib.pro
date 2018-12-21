;+
;NAME: rbsp_efw_vxb_subtract_crib.pro
;PURPOSE:
; Creates vxB subtracted tplot variables for the 32 S/s EFW efield data
; ****NOTE: IF YOU DON'T NEED THE FULL 32 S/s RESOLUTION THEN CONSIDER USING
; ****rbsp_efw_spinfit_vxb_subtract_crib.pro
; ****THE DATA WILL BE AT SPINPERIOD CADENCE BUT WILL BE CLEANER
;
; WARNING!!! RESULTS ARE PRELIMINARY. DO NOT PUBLISH OR PRESENT THESE RESULTS
; WITHOUT FIRST CONSULTING THE EFW PI JOHN WYGANT <wygan001@umn.edu>
;
;CALLING SEQUENCE:
; timespan,'2014-01-01'
; rbsp_efw_vxb_subtract_crib,'a'
;
;INPUT: 'a' or 'b' for probe
;KEYWORDS:
; ql -> use EMFISIS quicklook UVW data instead of 4sec GSE L3. This will be
;       despun and spinfit. This has the advantage of not having to wait for
;       the EMFISIS L3 data set to be produced.
;       Note: Defaults to 4-sec EMFISIS data in GSE. This is actually superior
;       to the hires GSE data b/c it doesn't have spurious data spikes.
;       It works about the same as JBT's method of despinning and then
;       spinfitting the EMFISIS quicklook UVW data.
;
; hires -> use EMFISIS hires L3 GSE data instead of 4sec GSE L3.
; qa -> load the QA testing L1 EFW data instead of the usual L1 data
;OUTPUT:
;HISTORY:
; Created by Aaron Breneman, UMN, Dec 2012
;	email: awbrenem@gmail.com
;REQUIRES: THEMIS TDAS software
;			 http://themis.ssl.berkeley.edu/software.shtml
;		   as well as SPICE software
;
;$LastChangedBy: $
;$LastChangedDate: $
;$LastChangedRevision: $
;$URL: $
;-


pro rbsp_efw_vxb_subtract_crib,probe,no_spice_load=no_spice_load,$
  noplot=noplot,ql=ql,l2=l2,hires=hires,qa=qa,bad_probe=bad_probe


  if ~KEYWORD_SET(ql) and ~KEYWORD_SET(l2) then level = 'l3'
  if KEYWORD_SET(ql) then level = 'ql'
  if KEYWORD_SET(l2) then level = 'l2'

  ;Set timerange if it's not already set
  x = timerange()
  date = strmid(time_string(x[0]),0,10)


  ;initialize RBSP environment
  rbsp_efw_init

  ;set desired probe
  rbspx = 'rbsp'+probe

  ;Set other quantities
  suffix = ''


  ;Load definitive sc positions and velocities
  if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels
  ;Get antenna pointing direction and stuff
  rbsp_load_state,probe=probe,/no_spice_load,datatype=['spinper','spinphase','mat_dsc','Lvec']
  ;Load other state variables
  rbsp_efw_position_velocity_crib,/no_spice_load,/noplot



  ;Load Esvy data in MGSE
  if ~keyword_set(qa) then rbsp_load_efw_esvy_mgse,probe=probe,/no_spice_load,bad_probe=bad_probe
  if keyword_set(qa)  then rbsp_load_efw_esvy_mgse,probe=probe,/no_spice_load,/qa


  ;Load EMFISIS data
  if keyword_set(ql) then rbsp_load_emfisis,probe=probe,/quicklook
  if keyword_set(hires) and ~keyword_set(l2) then rbsp_load_emfisis,probe=probe,coord='gse',cadence='hires',level='l3'
  if keyword_set(l2) then   rbsp_load_emfisis,probe=probe,coord='uvw',level='l2'
  if ~keyword_set(hires) and ~keyword_set(ql) and ~keyword_set(l2) then rbsp_load_emfisis,probe=probe,coord='gse',cadence='1sec',level='l3'


  ;Check for data existence
  if keyword_set(ql) then get_data,rbspx+'_emfisis_quicklook_Mag',data=dd2
  if keyword_set(hires) and ~keyword_set(l2) then get_data,rbspx+'_emfisis_l3_hires_gse_Mag',data=dd2
  if keyword_set(l2) then get_data,rbspx+'_emfisis_l2_uvw_Mag',data=dd2
  if ~keyword_set(hires) and ~keyword_set(ql) and ~keyword_set(l2) then get_data,rbspx+'_emfisis_l3_1sec_gse_Mag',data=dd2

  if ~is_struct(dd2) then begin
     print,'******NO MAG DATA TO LOAD.....rbsp_efw_DCfield_removal_crib.pro*******'
     return
  endif



  ;Transform the Mag data to MGSE coordinates
  if ~keyword_set(ql) and ~keyword_set(l2) then begin

     if keyword_set(hires) then $
      get_data,rbspx+'_emfisis_l3_hires_gse_Mag',data=tmpp else $
      get_data,rbspx+'_emfisis_l3_1sec_gse_Mag',data=tmpp

     get_data,rbspx+'_spinaxis_direction_gse',data=wsc_GSE

     wsc_GSE_tmp = [[interpol(wsc_GSE.y[*,0],wsc_GSE.x,tmpp.x)],$
                    [interpol(wsc_GSE.y[*,1],wsc_GSE.x,tmpp.x)],$
                    [interpol(wsc_GSE.y[*,2],wsc_GSE.x,tmpp.x)]]

     if keyword_set(hires) then $
      rbsp_gse2mgse,rbspx+'_emfisis_l3_hires_gse_Mag',reform(wsc_GSE_tmp),$
      newname=rbspx+'_emfisis_l3_hires_mgse_Mag' else $
      rbsp_gse2mgse,rbspx+'_emfisis_l3_1sec_gse_Mag',reform(wsc_GSE_tmp),$
      newname=rbspx+'_emfisis_l3_1sec_mgse_Mag'

     if keyword_set(hires) then $
      copy_data,rbspx+'_emfisis_l3_hires_mgse_Mag',rbspx+'_mag_mgse' else $
      copy_data,rbspx+'_emfisis_l3_1sec_mgse_Mag',rbspx+'_mag_mgse'

  endif


  if keyword_set(ql) then begin

    ;Create the dlimits structure for the EMFISIS quantity. The spinfit
    ;program needs to see that the coords are 'uvw'
    data_att = {coord_sys:'uvw'}
    dlim = {data_att:data_att}
    store_data,rbspx +'_emfisis_quicklook_Mag',data=dd2,dlimits=dlim

    ;spinfit the mag data and transform to MGSE
    rbsp_decimate,rbspx +'_emfisis_quicklook_Mag', upper = 2
    rbsp_spinfit,rbspx +'_emfisis_quicklook_Mag', plane_dim = 0
    rbsp_cotrans,rbspx +'_emfisis_quicklook_Mag_spinfit',rbspx+'_mag_mgse', /dsc2mgse

  endif

  if keyword_set(l2) then begin

    ;Create the dlimits structure for the EMFISIS quantity. Jianbao's spinfit program needs
    ;to see that the coords are 'uvw'
    data_att = {coord_sys:'uvw'}
    dlim = {data_att:data_att}
    store_data,rbspx +'_emfisis_l2_uvw_Mag',data=dd2,dlimits=dlim


    ;spinfit the mag data and transform to MGSE
    rbsp_decimate,rbspx +'_emfisis_l2_uvw_Mag', upper = 2
    rbsp_spinfit,rbspx +'_emfisis_l2_uvw_Mag', plane_dim = 0
    rbsp_cotrans,rbspx +'_emfisis_l2_uvw_Mag_spinfit',rbspx+'_mag_mgse', /dsc2mgse

  endif


  ;Load eclipse times
  if ~keyword_set(noplot) then begin
     rbsp_load_eclipse_predict,probe,date
     get_data,rbspx+'_umbra',data=eu
     get_data,rbspx+'_penumbra',data=ep
  endif


  ;Determine corotation Efield
  rbsp_corotation_efield,probe,date,/no_spice_load,level=level



  ;Create the vxB subtracted variables   (E - (Vsc + Vcoro)xB)
  tinterpol_mxn,rbspx+'_state_vel_mgse',rbspx+'_efw_esvy_mgse',$
    newname=rbspx+'_state_vel_mgse'
  dif_data,rbspx+'_state_vel_mgse',rbspx+'_state_vel_coro_mgse',newname='vel_total'
  rbsp_vxb_subtract,'vel_total',rbspx+'_mag_mgse',rbspx+'_efw_esvy_mgse'
  copy_data,'Esvy_mgse_vxb_removed',rbspx+'_efw_esvy_mgse_vxb_removed'




  ;Apply crude antenna effective length correction to y and z MGSE values
  get_data,rbspx+'_efw_esvy_mgse_vxb_removed', data = d
  d.y[*, 1] *= 0.947d           ;found by S. Thaller
  d.y[*, 2] *= 0.947d
  store_data,rbspx+'_efw_esvy_mgse_vxb_removed', data = d


  ;add back in the corotation field
  add_data,rbspx+'_efw_esvy_mgse_vxb_removed',rbspx+'_E_coro_mgse',$
    newname=rbspx+'_efw_esvy_mgse_vxb_removed'


  options,rbspx+'_efw_esvy_mgse_vxb_removed','colors',[2,4,6]

  split_vec,rbspx+'_efw_esvy_mgse_vxb_removed'
  split_vec,rbspx+'_efw_esvy_mgse'


  options,rbspx+'_efw_esvy_mgse_vxb_removed_x','colors',4
  options,rbspx+'_efw_esvy_mgse_vxb_removed_y','colors',1
  options,rbspx+'_efw_esvy_mgse_vxb_removed_z','colors',2
  options,rbspx+'_efw_esvy_mgse_vxb_removed_?','ysubtitle',''
  options,rbspx+'_efw_esvy_mgse_vxb_removed','ysubtitle',''
  options,rbspx+'_efw_esvy_mgse_vxb_removed_x','ytitle','Ex!CMGSE!CInertial Frame!C(E-V!Dsc!NxB)!C[mV/m]'
  options,rbspx+'_efw_esvy_mgse_vxb_removed_y','ytitle','Ey!CMGSE!CInertial Frame!C(E-V!Dsc!NxB)!C[mV/m]'
  options,rbspx+'_efw_esvy_mgse_vxb_removed_z','ytitle','Ez!CMGSE!CInertial Frame!C(E-V!Dsc!NxB)!C[mV/m]'
  options,rbspx+'_efw_esvy_mgse_x','ytitle','Esvy!CX MGSE!C[mV/m]'
  options,rbspx+'_efw_esvy_mgse_y','ytitle','Esvy!CY MGSE!C[mV/m]'
  options,rbspx+'_efw_esvy_mgse_z','ytitle','Esvy!CZ MGSE!C[mV/m]'
  options,rbspx+'_mag_mgse','ytitle','Bfield MGSE!C[nT]'
  options,rbspx+'_mag_mgse','ysubtitle',''
  options,rbspx+'_efw_esvy_mgse_*','ztitle','RBSP'+probe+'!CEFW'
  options,rbspx + ['_efw_esvy_mgse_?',$
                   '_efw_esvy_mgse_vxb_removed_?'],'labflag',-1
  options,rbspx+'_efw_esvy_mgse_vxb_removed_x','labels','X MGSE'
  options,rbspx+'_efw_esvy_mgse_vxb_removed_y','labels','Y MGSE'
  options,rbspx+'_efw_esvy_mgse_vxb_removed_z','labels','Z MGSE'
  options,rbspx+'_efw_esvy_mgse_x','labels','X MGSE'
  options,rbspx+'_efw_esvy_mgse_y','labels','Y MGSE'
  options,rbspx+'_efw_esvy_mgse_z','labels','Z MGSE'
  options,[rbspx+'_efw_esvy_mgse',rbspx+'_efw_esvy_mgse_?'],'ysubtitle',''


  split_vec,rbspx+'_efw_esvy_mgse'
  options,rbspx+'_efw_esvy_mgse','colors',[0,1,2]
  ylim,rbspx+'_efw_esvy_mgse_?',-20,20


  options,rbspx+'_efw_esvy_mgse_x','ytitle','Ex MGSE!C[mV/m]'
  options,rbspx+'_efw_esvy_mgse_y','ytitle','Ey MGSE!C[mV/m]'
  options,rbspx+'_efw_esvy_mgse_z','ytitle','Ez MGSE!C[mV/m]'
  options,rbspx+'_efw_esvy_mgse_?','ztitle','32 S/s'
  options,rbspx+'_efw_esvy_mgse_?','labels','32 S/s'
  options,rbspx+'_efw_esvy_mgse','ysubtitle',''
  options,rbspx+'_efw_esvy_mgse_?','ysubtitle',''



  if ~keyword_set(noplot) then begin
    tplot_options,'xmargin',[20.,15.]
    tplot_options,'ymargin',[3,6]
    tplot_options,'xticklen',0.08
    tplot_options,'yticklen',0.02
    tplot_options,'xthick',2
    tplot_options,'ythick',2
    tplot_options,'labflag',-1

    ylim,[rbspx+'_efw_esvy_mgse_vxb_removed_?',$
         rbspx+'_efw_esvy_mgse_?'],-300,300


    tplot_options,'title','Esvy compared to!CEsvy with vxB removed'
    tplot,[rbspx+'_efw_esvy_mgse_vxb_removed_y',$
          rbspx+'_efw_esvy_mgse_vxb_removed_z',$
          rbspx+'_efw_esvy_mgse_y',$
          rbspx+'_efw_esvy_mgse_z']

    ;eclipse times
    if is_struct(eu) then timebar,eu.x,color=50
    if is_struct(eu) then timebar,eu.x + eu.y,color=50
    if is_struct(ep) then timebar,ep.x,color=80
    if is_struct(ep) then timebar,ep.x + ep.y,color=80


    ;zoomed-in plot
    ylim,[rbspx+'_efw_esvy_mgse_vxb_removed_y',$
         rbspx+'_efw_esvy_mgse_vxb_removed_z',$
         rbspx+'_efw_esvy_mgse_y',$
         rbspx+'_efw_esvy_mgse_z'],-30,30
    tplot_options,'title','Esvy compared to!CEsvy with vxB removed'
    tplot,[rbspx+'_efw_esvy_mgse_vxb_removed_y',$
          rbspx+'_efw_esvy_mgse_vxb_removed_z',$
          rbspx+'_efw_esvy_mgse_y',$
          rbspx+'_efw_esvy_mgse_z']


    ;eclipse times
    if is_struct(eu) then timebar,eu.x,color=50
    if is_struct(eu) then timebar,eu.x + eu.y,color=50
    if is_struct(ep) then timebar,ep.x,color=80
    if is_struct(ep) then timebar,ep.x + ep.y,color=80

  endif


end
