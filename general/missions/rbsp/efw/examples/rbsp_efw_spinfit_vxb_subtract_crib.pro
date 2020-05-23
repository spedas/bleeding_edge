;+
;NAME: rbsp_efw_spinfit_vxb_subtract_crib.pro
;PURPOSE: Create the vxb subtracted spinfit data product for EFW
;CALLING SEQUENCE:
; timespan,'2014-01-01'
; rbsp_efw_spinfit_vxb_crib,'a'
;INPUT: probe --> 'a' or 'b'
;KEYWORDS:
; ql -> select to load EMFISIS quicklook data. Defaults to hires L3 data but
;				quicklook data are available sooner.
;	qa -> select to load QA waveform data. Don't want to use this route for normal
;				  data processing.
;	hiresl3 -> loads the EMFISIS high resolution 64 S/s L3 GSE data
; level -> Level of EMFISIS data. Options are:
;   'ql', 'l2', 'l3'. Defaults to EMFISIS L3 data
; boom_pair -> select the boom pair for the spinfitting. Any pair is acceptable
; no_reload -> use to not reload any of the base data. Useful if you want to run this
;         crib sheet multiple times for different boom pairs.
;
;OUTPUT: tplot variables of spinfit, vxb subtracted electric field
;
;NOTES: If doing spinfit on pairs 12, 34, we load the "esvy" waveform. This gives us the Efield array
;(rbsp?_efw_esvy) as [[E12],[E34],[E56]].
;This array is inputted into rbsp_spinfit.pro and the plane_dim is set to 0,1
;depending on which component (E12 or E34) you want to spinfit off of.
;**
;For pairs other than 12, 34, 56, we have to load "vsvy" waveform and construct the components
;manually. The first element of this array (normally E12) will be replaced with the new component.
;For ex, for pair=24, the array (rbsp?_efw_esvy) will be [[E24],[E34],[E56]]. We'll then set plane_dim
;to zero to use this component.
;
;HISTORY: Written by Aaron W Breneman
;         University of Minnesota
;         2013-04-16
;$LastChangedBy: nikos $
;$LastChangedDate: 2020-05-21 20:36:46 -0700 (Thu, 21 May 2020) $
;$LastChangedRevision: 28720 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_efw_spinfit_vxb_subtract_crib.pro $
;-

pro rbsp_efw_spinfit_vxb_subtract_crib,probe,no_spice_load=no_spice_load,$
  noplot=noplot,ql=ql,qa=qa,hiresl3=hiresl3,level=level,$
  boom_pair=pair,no_reload=no_reload




  if ~keyword_set(pair) then pair = '12'
  if ~keyword_set(level) and ~keyword_set(ql) then level = 'l3'
  if ~keyword_set(ql) then quickl = 0 else quickl = 1
  if keyword_set(ql) then level = 'ql'
  if level eq 'l3' or level eq 'l2' then quickl = 0

  type = ''
  if keyword_set(hiresl3) then type = 'hires' else type = '1sec'
  if ~keyword_set(level) or keyword_set(hiresl3) then level = 'l3'



  ;Get the time range if it hasn't already been set
  tr = timerange()
  date = strmid(time_string(tr[0]),0,10)


  rbspx = 'rbsp'+probe



  ;--------------------------------------------------------------------------------------
  ;Load all necessary data if required
  if ~keyword_set(no_reload) then begin

    ;Load spice stuff
    if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels

    ;Get antenna pointing direction and ephemeris
    rbsp_load_state,probe=probe,/no_spice_load,$
    datatype=['spinper','spinphase','mat_dsc','Lvec']

    rbsp_efw_position_velocity_crib,/no_spice_load,/noplot


    ;Load eclipse times
    if ~keyword_set(noplot) then rbsp_load_eclipse_predict,probe,date


    ;Load esvy and vsvy data
    if ~keyword_set(qa) then rbsp_load_efw_waveform, probe=probe, datatype = ['esvy','vsvy'], coord = 'uvw',/noclean
    if keyword_set(qa)  then rbsp_load_efw_waveform, probe=probe, datatype = ['esvy','vsvy'], coord = 'uvw',/noclean,/qa

    split_vec,rbspx+'_efw_vsvy',suffix='_'+['1','2','3','4','5','6']

    ;Load the mag data
;    t0 = time_double(date)
;    t1 = t0 + 86400.

    t0 = tr[0]
    t1 = tr[1]


    case level of
      'ql': begin
          rbsp_load_emfisis,probe=probe,/quicklook
          if ~tdexists(rbspx+'_emfisis_quicklook_Mag',tr[0],tr[1]) then begin
            print,'******NO QL MAG DATA TO LOAD.....rbsp_efw_spinfit_vxb_subtract_crib.pro*******'
            return
          endif
          magstr = 'quicklook'
      end
      'l2': begin
          rbsp_load_emfisis,probe=probe,coord='uvw',level='l2'
          if ~tdexists(rbspx+'_emfisis_l2_uvw_Mag',tr[0],tr[1]) then begin
            print,'******NO L2 MAG DATA TO LOAD.....rbsp_efw_spinfit_vxb_subtract_crib.pro*******'
            return
          endif
          magstr = 'l2_uvw'
      end
      'l3': begin
          rbsp_load_emfisis,probe=probe,coord='gse',cadence=type,level='l3'
          if ~tdexists(rbspx+'_emfisis_l3_'+type+'_gse_Mag',tr[0],tr[1]) then begin
            print,'******NO L3 MAG DATA TO LOAD.....rbsp_efw_spinfit_vxb_subtract_crib.pro*******'
            return
          endif
          magstr = 'l3_'+type+'_gse'
      end
    endcase ;For loading EMFISIS data

    message,"Done rotating emfisis data...",/continue

    ;Some of the EMFISIS quicklook data extend beyond the day loaded.
    ;This messes things up later. Remove these data points now.
    ttst = tnames(rbspx+'_emfisis_'+magstr+'_Mag',cnt)
    if cnt eq 1 then time_clip,rbspx+'_emfisis_'+magstr+'_Mag',t0,t1,replace=1,error=error
    ttst = tnames(rbspx+'_emfisis_'+magstr+'_Magnitude',cnt)
    if cnt eq 1 then time_clip,rbspx+'_emfisis_'+magstr+'_Magnitude',t0,t1,replace=1,error=error

    ;Create the dlimits structure for the EMFISIS quantity. Spinfit program
    ;needs to see that the coords are 'uvw'
    get_data,rbspx+'_emfisis_'+magstr+'_Mag',data=datt
    data_att = {coord_sys:'uvw'}
    dlim = {data_att:data_att}
    store_data,rbspx+'_'+magstr+'_Mag',data=datt,dlimits=dlim


    ;if EMFISIS data are in UVW coord then spinfit them and transform to MGSE
    if tdexists(rbspx+'_emfisis_'+magstr+'_Mag',tr[0],tr[1]) and $
       magstr eq 'l2_uvw' then begin
      rbsp_decimate,rbspx+'_emfisis_'+magstr+'_Mag', upper = 2
      rbsp_spinfit,rbspx+'_emfisis_'+magstr+'_Mag', plane_dim = 0;
      message,"Rotating emfisis data...",/continue
      rbsp_cotrans,rbspx+'_emfisis_'+magstr+'_Mag_spinfit', rbspx + '_mag_mgse', /dsc2mgse
    endif else begin
      rbsp_cotrans,rbspx+'_emfisis_'+magstr+'_Mag', rbspx + '_mag_mgse', /gse2mgse
    endelse


    ;Find the co-rotation Efield
    rbsp_corotation_efield,probe,date,/no_spice_load,level=level


  endif  ;For loading the data
  ;--------------------------------------------------------------------------------------




  ;grab eclipse times
  get_data,rbspx+'_umbra',data=eu
  get_data,rbspx+'_penumbra',data=ep



  ;get boom lengths
  cp0 = rbsp_efw_get_cal_params(tr[0])
  cp = cp0.a
  boom_length = cp.boom_length
  boom_shorting_factor = cp.boom_shorting_factor


;-------------------------------------------------------------------------------
;Extract data for each boom pair
;For boom pairs 12 or 34, we'll use the Esvy waveform data to input into rbsp_spinfit.pro
;For any other pair, we'll input waveform data constructed using the single-ended potentials (Vsvy)
;So, the following code constructs the "rbsp?_efw_esvy" tplot variable that is input into rbsp_spinfit.pro


    if pair ne '12' and pair ne '34' then begin
      rbv = rbspx + '_efw_vsvy_'

      ;Construct E34 and E56 to fill out waveform array sent into rbsp_spinfit.pro
      ;No need to do E12 since this will be overwritten by "pair"
      dif_data,rbv+'3',rbv+'4',newname='tmp'
      get_data,'tmp',data=dd
      E34 = dd.y * 1000./boom_length[1]

      dif_data,rbv+'5',rbv+'6',newname='tmp'
      get_data,'tmp',data=dd
      E56 = dd.y * 1000./boom_length[2]

      if pair eq '13' then begin
        boom_length_adj = sqrt(2)*boom_length[0]/2.
        dif_data,rbv+'1',rbv+'3',newname='tmp'
        get_data,'tmp',data=dd
        E13 = dd.y * 1000./boom_length_adj
        store_data,'rbsp'+probe+'_efw_esvy',dd.x,[[E13],[E34],[E56]],dlim=dlim
      endif
      if pair eq '14' then begin
        boom_length_adj = sqrt(2)*boom_length[0]/2.
        dif_data,rbv+'1',rbv+'4',newname='tmp'
        get_data,'tmp',data=dd
        E14 = dd.y * 1000./boom_length_adj
        store_data,'rbsp'+probe+'_efw_esvy',dd.x,[[E14],[E34],[E56]],dlim=dlim
      endif
      if pair eq '23' then begin
        boom_length_adj = sqrt(2)*boom_length[0]/2.
        dif_data,rbv+'2',rbv+'3',newname='tmp'
        get_data,'tmp',data=dd
        E23 = dd.y * 1000./boom_length_adj
        store_data,'rbsp'+probe+'_efw_esvy',dd.x,[[E23],[E34],[E56]],dlim=dlim
      endif
      if pair eq '24' then begin
        boom_length_adj = sqrt(2)*boom_length[0]/2.
        dif_data,rbv+'2',rbv+'4',newname='tmp'
        get_data,'tmp',data=dd
        E24 = dd.y * 1000./boom_length_adj
        store_data,'rbsp'+probe+'_efw_esvy',dd.x,[[E24],[E34],[E56]],dlim=dlim
      endif

    endif

  options,rbspx+'_efw_esvy','ysubtitle',''
  options,rbspx+'_efw_esvy','ytitle',rbspx+'_efw_esvy'+'!C[mV/m]!Cfrom antenna pair '+pair



  ;Spinfit data and transform to MGSE coordinates
  ;...plane_dim is used to define which element of the [n,3] array is focused
  ;...on in spinfit.pro. 0=e12; 1=e34; 2=e56
  ;I'll also set the force keyword for pairs other than E12 and E34 so that the
  ;code doesn't crash b/c it doesn't know which coord system has been input.

  if pair eq '12' then rbsp_spinfit, rbspx + '_efw_esvy', plane_dim = 0
  if pair eq '34' then rbsp_spinfit, rbspx + '_efw_esvy', plane_dim = 1
  if pair eq '13' then rbsp_spinfit, rbspx + '_efw_esvy', plane_dim = 0, sun2sensor=35d, /force
  if pair eq '14' then rbsp_spinfit, rbspx + '_efw_esvy', plane_dim = 0, sun2sensor=-55d, /force
  if pair eq '23' then rbsp_spinfit, rbspx + '_efw_esvy', plane_dim = 0, sun2sensor=125d, /force
  if pair eq '24' then rbsp_spinfit, rbspx + '_efw_esvy', plane_dim = 0, sun2sensor=-145d, /force



  ;Remove unnecessary tplot variables
  store_data,[rbspx+'_efw_esvy_spinfit_e'+pair+'_a',$
              rbspx+'_efw_esvy_spinfit_e'+pair+'_b',$
              rbspx+'_efw_esvy_spinfit_e'+pair+'_c'],/delete



  ;Interpolate the position data to spinfit cadence (it's at 1min by default)
  tinterpol_mxn,rbspx+'_state_vel_mgse',rbspx+'_efw_esvy_spinfit',newname=rbspx+'_state_vel_mgse'



  if ~tdexists(rbspx + '_efw_esvy_spinfit',tr[0],tr[1]) then begin
     print,"CAN'T SPINFIT THE DATA....RETURNING"
     return
  endif


  ;Transform to MGSE coordinates
  rbsp_cotrans,rbspx+'_efw_esvy_spinfit',rbspx+'_sfit'+pair+'_mgse',/dsc2mgse





  ;Find residual Efield (i.e. no Vsc x B and no Vcoro x B field)
  dif_data,rbspx+'_state_vel_mgse',rbspx+'_state_vel_coro_mgse',newname='vel_total'


  ;Subtract off VxB field. Creates tplot variable Esvy_mgse_vxb_removed...
  if tdexists('vel_total',tr[0],tr[1]) and $
  tdexists(rbspx + '_mag_mgse',tr[0],tr[1]) and $
  tdexists(rbspx+'_sfit'+pair+'_mgse',tr[0],tr[1]) then $
    rbsp_vxb_subtract,'vel_total',rbspx+'_mag_mgse',rbspx+'_sfit'+pair+'_mgse'


  store_data,'vel_total',/delete

  ;Contains both Vsc x B and Vcoro x B
  join_vec,['vxb_x','vxb_y','vxb_z'],rbspx+'_vxb'


  ;subtract off Vcoro x B
  dif_data,rbspx+'_vxb',rbspx+'_E_coro_mgse',newname=rbspx+'_vscxb'
  store_data,['vxb_x','vxb_y','vxb_z'],/delete
  copy_data,'Esvy_mgse_vxb_removed',rbspx+'_efw_esvy_mgse_vxb_removed_spinfit'


  ;Apply crude antenna effective length correction to minimize residual field
  get_data,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit', data = d
  if is_struct(d) then begin
     d.y[*, 1] *= 0.947d        ;found by S. Thaller
     d.y[*, 2] *= 0.947d
     store_data,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit', data = d
  endif


  ;add back in the corotation field
  add_data,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit',rbspx+'_E_coro_mgse',$
    newname=rbspx+'_efw_esvy_mgse_vxb_removed_spinfit'


  options,rbspx + '_mag_mgse','ytitle','Bfield MGSE!C[nT]'
  options,rbspx + '_mag_mgse','ysubtitle',''
  options,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit','colors',[4,1,2]



  if ~keyword_set(noplot) then begin
     tplot,[rbspx+'_efw_esvy_mgse_vxb_removed_spinfit']
     if is_struct(eu) then timebar,eu.x,color=50
     if is_struct(eu) then timebar,eu.x + eu.y,color=50
     if is_struct(ep) then timebar,ep.x,color=80
     if is_struct(ep) then timebar,ep.x + ep.y,color=80
  endif

  message,"Done with rbsp_efw_spinfit_vxb_crib...",/continue



  ;Delete unnecessary variables
  store_data,['*sfit'+pair+'*','bfield_data_gei',$
              '*esvy_spinfit_?',$
              rbspx+'_emfisis_l3_1sec_gse_Mag_spinfit_e'+pair+'_?',$
              rbspx+'_state_vel_coro_gei',rbspx+'_E_coro_gei',$
              rbspx+'_emfisis_l3_'+type+'_gse_delta',rbspx+'_emfisis_l3_'+type+'_gse_lambda',$
              rbspx+'_emfisis_l3_4sec_gse_rms',$
              rbspx+'_emfisis_l3_1sec_gse_rms',$
              rbspx+'_state_pos_gei',rbspx+'_efw_esvy_ccsds_data_BEB_config',$
              rbspx+'_efw_esvy_ccsds_data_DFB_config'],/delete

end
