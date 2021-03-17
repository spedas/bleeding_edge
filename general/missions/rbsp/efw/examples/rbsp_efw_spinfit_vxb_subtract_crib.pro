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
; _extra --> possible useful keywords include:
;         no_spice_load
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
;$LastChangedBy: aaronbreneman $
;$LastChangedDate: 2020-10-15 10:55:25 -0700 (Thu, 15 Oct 2020) $
;$LastChangedRevision: 29256 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_efw_spinfit_vxb_subtract_crib.pro $
;-





;***********TESTING NOTES*****************

;LITERALLY JUST A - SIGN DIFFERENCE B/T SHENG AND MY RESULTS. 
;Esvy Aaron vs Esvy Sheng gives same result. 
;UVW to MGSE gives Sheng's result 
;Old vs new input to rbsp_spinfit gives same result. 
;Old vs new input to rbsp_efw_dsc_to_mgse gives same result.
;Online CDF files consistent with Sheng's results. 
;rbsp_uvw_to_dsc gives same result as spinfitting. 

;SUGGESTS THAT 
;1) SOMETHING INTERNAL TO RBSP_SPINFIT OR RBSP_EFW_DSC_TO_MGSE 
;HAS CHANGED AND IS GIVING THE PROBLEM. 
;2) THAT SOMETHING IS COMMON TO RBSP_SPINFIT AND RBSP_UVW_TO_DSC



;Could you also test for -B from 2014-06-14 through 2014-06-18? 
;My residue is small before and after the time range but is quite off from 06-15 through 06-17. 
;I suspect the UVW2MGSE rotation is problematic because the model and measured |E| are consistent all through but the 
;MGSE x and y components are off.

;RBSPa
;Tested days with sign flip 
;2013-03-20 (flip occurs during maneuver around 20 UT after a perigee pass)
;2013-03-21
;2013-03-25
;2013-04-01
;2013-05-01
;2013-06-11
;2013-06-13
;2013-08-01
;2013-08-24
;2013-09-01
;2013-09-15
;2013-09-24
;2013-09-25 (flip occurs during maneuver around 20 UT after a perigee pass)

;Tested days with no sign flip 
;2013-01-01
;2013-03-01
;2013-03-14 (MANEUVER FROM 15-18 UT; a bit messy at end of day)
;2013-03-15 (a bit messy)
;2013-03-19 
;2013-09-28
;2013-10-01
;2013-10-08
;2013-10-09

;RBSPb
;Tested days with sign flip 
;2014-06-13
;2014-06-14 
;2014-06-26

;Tested days with no sign flip 
;2015-06-13
;2016-06-13
;2017-06-13


pro rbsp_efw_spinfit_vxb_subtract_crib,probe,$
  noplot=noplot,$
  ql=ql,$
  qa=qa,$
  hiresl3=hiresl3,$
  level=level,$
  boom_pair=pair,$
  no_reload=no_reload,$
  _extra=extra



  ;Determine whether to download EFW waveform and EMFISIS data from the extra structure
  if tag_exist(extra,'no_waveform_load') then no_download_waveform = extra.no_waveform_load else no_download_waveform = 0
  if tag_exist(extra,'no_emfisis_load') then no_download_emfisis = extra.no_emfisis_load else no_download_emfisis = 0




  if ~keyword_set(pair) then pair = '12'
  if ~keyword_set(level) and ~keyword_set(ql) then level = 'l3'
  if ~keyword_set(ql) then quickl = 0 else quickl = 1
  if keyword_set(ql) then level = 'ql'
  if level eq 'l3' or level eq 'l2' then quickl = 0
  if keyword_set(hiresl3) then type = 'hires' else type = '1sec'
  if ~keyword_set(level) or keyword_set(hiresl3) then level = 'l3'



  ;Get the time range
  tr = timerange()
  date = strmid(time_string(tr[0]),0,10)

  rbspx = 'rbsp'+probe



  ;--------------------------------------------------------------------------------------
  ;Load all necessary data if required
  if ~keyword_set(no_reload) then begin


    ;Load SPICE CDF files (this replaces rbsp_load_state and rbsp_efw_position_velocity_crib)
    ;Gives same result as rbsp_load_state and rbsp_efw_position_velocity_crib.pro
    rbsp_load_spice_cdf_file,probe


    ;Load Sheng's residual removal file
    ;rbsp_load_perigee_correction_cdf_file,probe

    ;Load Sheng's emodel file
    rbsp_load_emodel_cdf_file,probe


    ;Download EMFISIS data, if required
    case level of
      'ql': begin
          if not no_download_emfisis then rbsp_load_emfisis,probe=probe,/quicklook
          if ~tdexists(rbspx+'_emfisis_quicklook_Mag',tr[0],tr[1]) then begin
            print,'******NO QL MAG DATA TO LOAD.....rbsp_efw_spinfit_vxb_subtract_crib.pro*******'
            return
          endif
          magstr = 'quicklook'
      end
      'l2': begin
          if not no_download_emfisis then rbsp_load_emfisis,probe=probe,coord='uvw',level='l2'
          if ~tdexists(rbspx+'_emfisis_l2_uvw_Mag',tr[0],tr[1]) then begin
            print,'******NO L2 MAG DATA TO LOAD.....rbsp_efw_spinfit_vxb_subtract_crib.pro*******'
            return
          endif
          magstr = 'l2_uvw'
      end
      'l3': begin
          if not no_download_emfisis then rbsp_load_emfisis,probe=probe,coord='gse',cadence=type,level='l3'
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
    if cnt eq 1 then time_clip,rbspx+'_emfisis_'+magstr+'_Mag',tr[0],tr[1],replace=1,error=error
    ttst = tnames(rbspx+'_emfisis_'+magstr+'_Magnitude',cnt)
    if cnt eq 1 then time_clip,rbspx+'_emfisis_'+magstr+'_Magnitude',tr[0],tr[1],replace=1,error=error




    ;Create the dlimits structure for the EMFISIS quantity. Spinfit program
    ;needs to see that the coords are 'uvw'
    get_data,rbspx+'_emfisis_'+magstr+'_Mag',data=datt
    data_att = {coord_sys:'uvw'}
    dlim = {data_att:data_att}
    store_data,rbspx+'_'+magstr+'_Mag',data=datt,dlimits=dlim



    ;if EMFISIS data are in UVW coord then spinfit them and transform to MGSE
    if tdexists(rbspx+'_emfisis_'+magstr+'_Mag',tr[0],tr[1]) and magstr eq 'l2_uvw' then begin
      rbsp_decimate,rbspx+'_emfisis_'+magstr+'_Mag', upper = 2
      rbsp_spinfit,rbspx+'_emfisis_'+magstr+'_Mag', plane_dim = 0;
      message,"Rotating emfisis data...",/continue
      rbsp_cotrans,rbspx+'_emfisis_'+magstr+'_Mag_spinfit', rbspx + '_mag_mgse', /dsc2mgse
    endif else begin
      ;transform the EMFISIS values from GSE to MGSE
      ;**new method avoids cotrans. I've tested both and they compare very closely
      tinterpol_mxn,rbspx+'_spinaxis_direction_gse',rbspx+'_emfisis_'+magstr+'_Mag'
      get_data,rbspx+'_spinaxis_direction_gse_interp',tt,wgse
      rbsp_gse2mgse,rbspx+'_emfisis_'+magstr+'_Mag',wgse,newname=rbspx + '_mag_mgse'
    endelse





    ;Load esvy and vsvy data if they've not already been loaded
    if not no_download_waveform then begin

      ;esvy data we'll get from Sheng's wake effect removed files.
      ;This is only valid if we are getting esvy from [[12],[34],[56]]

      if pair eq '12' or pair eq '34' then begin

;********************
;NOT YET SURE HOW TO INCORPORATE THE WAKE REMOVED DATA
;        rbsp_load_wake_effect_cdf_file,probe
;        get_data,'rbsp'+probe+'_eu_fixed',data=eu
;        get_data,'rbsp'+probe+'_ev_fixed',data=ev
;        get_data,'rbsp'+probe+'_ew',data=ew
;        store_data,'rbsp'+probe+'_efw_esvy',eu.x,[[eu.y],[ev.y],[ew.y]],dlim=dlim
;********************
        rbsp_load_efw_waveform, probe=probe, datatype = ['esvy'], coord = 'uvw',/noclean



      endif else begin
        ;if we're not spinfitting from 12 or 34 then we need to load vsvy to create
        ;odd antenna combinations
        rbsp_load_efw_waveform, probe=probe, datatype = ['vsvy'], coord = 'uvw',/noclean
        split_vec,rbspx+'_efw_vsvy',suffix='_'+['1','2','3','4','5','6']


      endelse

    endif
  endif  ;For loading the data
  ;--------------------------------------------------------------------------------------



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



;****
;copy_data,rbspx+'_efw_esvy',rbspx+'_efw_esvy_backup'



  ;Implement the time correction, if necessary

  rbsp_efw_read_l1_time_tag_correction, probe=probe


  get_data, 'rbsp'+probe+'_l1_time_tag_correction', start_times, time_ranges, corrections
  nsection = n_elements(corrections)
  
  foo_l1_efw_data = 'rbsp'+probe+'_efw_esvy'
  get_data, foo_l1_efw_data, times, e_uvw
  for ii=0, nsection-1 do begin
      tmp = where(times ge time_ranges[ii,0] and times le time_ranges[ii,1], count)
      if count eq 0 then continue
      ; Have to find the closest time, otherwise the index can be 1 record off.
      if min(times) ge time_ranges[ii,0] then i0 = 0 else begin
          index = min(times-time_ranges[ii,0], /absolute, i0)
      endelse
      if max(times) le time_ranges[ii,1] then i1 = n_elements(times) else begin
          index = min(times-time_ranges[ii,1], /absolute, i1)
      endelse
      times[i0:i1-1] += corrections[ii]
  endfor


;split_vec,'rbspa_efw_esvy'
;split_vec,'rbspa_efw_esvy_backup'
;tplot,['rbspa_efw_esvy_x','rbspa_efw_esvy_backup_x']
;tplot,['rbspa_efw_esvy_y','rbspa_efw_esvy_backup_y']
;stop



  ;------------------------------------------------------
  ;Remove DC offset (Sheng email 8/26/2020)

    spin_period = 11d   ; the rough number works fine, no need to get the accurate number
    tmpp = times - shift(times,1)
    dt = median(tmpp)
    width = spin_period/dt
    for ii=0,1 do begin $
        offset1 = smooth(e_uvw[*,ii], width, /nan, /edge_zero) & $
        offset2 = smooth(offset1, width, /nan, /edge_zero) & $
        e_uvw[*,ii] -= offset2
    endfor

  store_data, foo_l1_efw_data+'_tst', times, e_uvw
stop
  store_data, foo_l1_efw_data, times, e_uvw

stop
  ;------------------------------------------------------







  options,rbspx+'_efw_esvy','ysubtitle',''
  options,rbspx+'_efw_esvy','ytitle',rbspx+'_efw_esvy'+'!C[mV/m]!Cfrom antenna pair '+pair






  ;Get rid of non-monotonic times, which sometimes show up
  get_data,rbspx+'_efw_esvy',data=d,dlim=dlim,lim=lim
  index = uniq(d.x, sort(d.x))
  newtimes = d.x[index]
  newdata = d.y[index,*]

  ;dt = total(d.x - newtimes)
  store_data,rbspx+'_efw_esvy',newtimes,newdata,dlim=dlim,lim=lim




  ;Construct Emodel = ecoro + evxb + efit
;  add_data,rbspx+'_ecoro_mgse',rbspx+'_evxb_mgse',newname='tmpp'
;  add_data,'tmpp',rbspx+'_efit_mgse',newname=rbspx+'_Emodel_mgse'
  copy_data,rbspx+'_emod_mgse',rbspx+'_Emodel_mgse'
  tinterpol_mxn,rbspx+'_Emodel_mgse',rbspx+'_efw_esvy',/overwrite,/quadratic






  ;Rotate Emodel data to UVW
  rbsp_uvw_to_mgse_quaternion,rbspx+'_Emodel_mgse',probe,/inverse,newname=rbspx+'_Emodel_uvw'



;  split_vec,'rbsp'+probe+'_efw_esvy'
;  split_vec,rbspx+'_Emodel_uvw'
;  ylim,['rbsp'+probe+'_efw_esvy_?',rbspx+'_Emodel_uvw_?'],0,0



  ;Subtract Emodel data from Esvy UVW 
  dif_data,'rbsp'+probe+'_efw_esvy',rbspx+'_Emodel_uvw',newname='rbsp'+probe+'_efw_esvy_noresidual'


  ;Add in dlim, lim structures
  get_data,'rbsp'+probe+'_efw_esvy_noresidual',data=dd 
  store_data,'rbsp'+probe+'_efw_esvy_noresidual',data=dd,dlim=dlim,lim=lim



;  split_vec,'rbsp'+probe+'_efw_esvy_noresidual'
;  ylim,'rbsp'+probe+'_efw_esvy_noresidual_?',0,0
;  tplot,'rbsp'+probe+'_efw_esvy_noresidual_?'




  ;Spinfit data and transform to MGSE coordinates
  ;...plane_dim is used to define which element of the [n,3] array is focused
  ;...on in spinfit.pro. 0=e12; 1=e34; 2=e56
  ;I'll also set the force keyword for pairs other than E12 and E34 so that the
  ;code doesn't crash b/c it doesn't know which coord system has been input.
  if pair eq '12' then rbsp_spinfit, rbspx + '_efw_esvy_noresidual', plane_dim = 0
  if pair eq '34' then rbsp_spinfit, rbspx + '_efw_esvy_noresidual', plane_dim = 1
  if pair eq '13' then rbsp_spinfit, rbspx + '_efw_esvy_noresidual', plane_dim = 0, sun2sensor=35d, /force
  if pair eq '14' then rbsp_spinfit, rbspx + '_efw_esvy_noresidual', plane_dim = 0, sun2sensor=-55d, /force
  if pair eq '23' then rbsp_spinfit, rbspx + '_efw_esvy_noresidual', plane_dim = 0, sun2sensor=125d, /force
  if pair eq '24' then rbsp_spinfit, rbspx + '_efw_esvy_noresidual', plane_dim = 0, sun2sensor=-145d, /force


  if ~tdexists(rbspx + '_efw_esvy_noresidual_spinfit',tr[0],tr[1]) then begin
     print,"CAN'T SPINFIT THE DATA....RETURNING"
     return
  endif


  ;Transform the spinfit data from DSC to MGSE (AARON'S UPDATED VERSION which is very fast and 
  ;gives same result as old method)
  tinterpol_mxn,rbspx+'_spinaxis_direction_gse',rbspx+'_efw_esvy_noresidual_spinfit',/quadratic
  rbsp_efw_dsc_to_mgse,probe,rbspx+'_efw_esvy_noresidual_spinfit',rbspx+'_spinaxis_direction_gse_interp',_extra=extra



;-----------------------------
;Now subtract Sheng's "fit" value to remove the remaining residual 
;Use dey[*,2] and dez[*,2]

rbsp_load_efit_cdf_file,probe


tinterpol_mxn,rbspx+'_dey',rbspx+'_efw_esvy_noresidual_spinfit_mgse',/overwrite,/quadratic
tinterpol_mxn,rbspx+'_dez',rbspx+'_efw_esvy_noresidual_spinfit_mgse',/overwrite,/quadratic

split_vec,rbspx+'_dey',suffix='_'+['old','fit','new']
split_vec,rbspx+'_dez',suffix='_'+['old','fit','new']
split_vec,rbspx+'_efw_esvy_noresidual_spinfit_mgse'

tplot,rbspx+'_dey_'+['old','fit','new']

tplot,[rbspx+'_dey_new',rbspx+'_efw_esvy_noresidual_spinfit_mgse_y']


;Simply replace the residual field with Sheng's fit-subtracted version. 
get_data,rbspx+'_efw_esvy_noresidual_spinfit_mgse_y',data=tmpy
get_data,rbspx+'_dey_new',data=tmpynew
goo = where(finite(tmpynew.y) ne 0.)
if goo[0] ne -1 then tmpy.y[goo] = tmpynew.y[goo]
store_data,'tst',data=tmpy

ylim,['tst',rbspx+'_efw_esvy_noresidual_spinfit_mgse_y',rbspx+'_dey_new'],-4,4
tplot,['tst',rbspx+'_efw_esvy_noresidual_spinfit_mgse_y',rbspx+'_dey_new']


dif_data,rbspx+'_efw_esvy_noresidual_spinfit_mgse_y',rbspx+'_dey_fit',newname='fittsty'

tplot,[rbspx+'_dey_new','fittsty']

tplot,['rbspb_efw_esvy_noresidual_spinfit_mgse','rbspb_dey','rbspb_dez']


tplot,['rbspb_efw_esvy_noresidual_spinfit_mgse_y','rbspb_dey']
tplot,['rbspb_efw_esvy_noresidual_spinfit_mgse_z','rbspb_dez']


stop



;-----------------------------

  ;-----------
  ;TESTING
;  split_vec,rbspx+'_efw_esvy_noresidual_spinfit_mgse'
;  split_vec,rbspx+'_de_mgse'
;  ylim,rbspx+'_efw_esvy_noresidual_spinfit_mgse_?',-4,4
;  ylim,rbspx+'_de_mgse_?',-4,4
;  tplot,[rbspx+'_efw_esvy_noresidual_spinfit_mgse_y',rbspx+'_de_mgse_y',$
;        rbspx+'_efw_esvy_noresidual_spinfit_mgse_z',rbspx+'_de_mgse_z']
  ;-----------





  ;Remove unnecessary tplot variables
  store_data,[rbspx+'_efw_esvy_spinfit_e'+pair+'_a',$
              rbspx+'_efw_esvy_spinfit_e'+pair+'_b',$
              rbspx+'_efw_esvy_spinfit_e'+pair+'_c'],/delete



  ;Interpolate the position data to spinfit cadence (it's at 1min by default)
  tinterpol_mxn,rbspx+'_state_vel_mgse',rbspx+'_efw_esvy_spinfit',newname=rbspx+'_state_vel_mgse',/spline








;;***************
;;TESTING
;split_vec,rbspx+'_efw_esvy_noresidual_spinfit_mgse'
;split_vec,rbspx+'_de_mgse'
;ylim,[rbspx+'_efw_esvy_noresidual_spinfit_mgse*',rbspx+'_e_mgse*'],-10,10
;;tplot,[rbspx+'_efw_esvy_spinfit_mgse_y',rbspx+'_e_mgse_y']
;
;store_data,'comby',data=[rbspx+'_efw_esvy_noresidual_spinfit_mgse_y',rbspx+'_de_mgse_y']
;store_data,'combz',data=[rbspx+'_efw_esvy_noresidual_spinfit_mgse_z',rbspx+'_de_mgse_z']
;options,'comby','colors',[0,250]
;options,'combz','colors',[0,250];
;
;ylim,['comby','combz'],-4,4
;tplot,['comby','combz',rbspx+'_spinaxis_direction_gse']
;***************





;  ;Get Vsc x B (motional) and Vcoro x B (corotation) electric fields
;  get_data,rbspx+'_efw_esvy_spinfit_mgse',data=dtmp
;  rbsp_efw_vxb_create,rbspx+'_state_vel_mgse',rbspx+'_mag_mgse',dtmp.x,title = '(Vsc x B)!CmV/m!CMGSE'
;  copy_data,'vxb',rbspx+'_vscxb_mgse'
;  copy_data,rbspx+'_E_coro_mgse',rbspx+'_vcoroxb_mgse'


  ;Find total residual Efield. We need to subtract this off so that we can apply the effective
  ;antenna length to the Efield measured only by the probes, and not any motional or corotation
  ;field. This field consists of the Vsc x B field and the
  ;Vcoro x B field (NOTE: Vcoro is the minus Vcoro field)
;  add_data,rbspx+'_vscxb_mgse',rbspx+'_vcoroxb_mgse',newname='Einertial+coro_mgse'


  ;create the rbspx+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit' variable
  ;If Sheng's CDF files are loaded, then this is what we already have. Otherwise we need to subtract off
  ;Ecoro + Emotional
 ; if pair ne '12' and pair ne '34' then begin
 ;   dif_data,rbspx+'_efw_esvy_spinfit_mgse','Einertial+coro_mgse',newname=rbspx+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit'
 ; endif else copy_data,rbspx+'_efw_esvy_spinfit_mgse',rbspx+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit'


  copy_data,rbspx+'_efw_esvy_noresidual_spinfit_mgse',rbspx+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit'

  ;Apply crude antenna effective length correction to minimize residual field.
  ;Do this to the
;  get_data,rbspx+'_efw_esvy_noresidual_spinfit_mgse', data = d
  get_data,rbspx+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit', data = d
  if is_struct(d) then begin
     d.y[*, 1] *= 0.947d        ;found by S. Thaller
     d.y[*, 2] *= 0.947d
     store_data,rbspx+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit', data = d
  endif


;  14 rbspa_ecoro_mgse                         
;  15 rbspa_evxb_mgse 
  copy_data,rbspx+'_evxb_mgse',rbspx+'_vscxb_mgse'
  copy_data,rbspx+'_ecoro_mgse',rbspx+'_vcoroxb_mgse'

  ;Now that effective antenna length has been applied, add back in corotation field to get the inertial frame Efield. 
  ;*****NOTE: In old method (pre-Sheng) Vcoro has a negative sign, so we'll have to subtract here.
  ;*****I may have to look into this more for the final CDF files
  add_data,rbspx+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit',rbspx+'_vcoroxb_mgse',newname=rbspx+'_efw_esvy_mgse_vxb_removed_spinfit'


;********TEMPORARY FOR WYGANT
;ADD BACK IN VSC X B FIELD TO GET EFIELD IN SC FRAME
  add_data,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit',rbspx+'_vscxb_mgse',newname=rbspx+'_efield_sc_frame_wygant'

;tplot,[rbspx+'_vscxb_mgse',rbspx+'_efw_esvy_mgse_vxb_removed_spinfit',rbspx+'_efield_sc_frame_wygant']
;store_data,'t1',data=[rbspx+'_vscxb_mgse_y',rbspx+'_efield_sc_frame_wygant_y']
;store_data,'t2',data=[rbspx+'_vscxb_mgse_z',rbspx+'_efield_sc_frame_wygant_z']
;stop
;********TEMPORARY FOR WYGANT


  options,rbspx + '_mag_mgse','ytitle','Bfield MGSE!C[nT]'
  options,rbspx + '_mag_mgse','ysubtitle',''
  options,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit','colors',[4,1,2]



  message,"Done with rbsp_efw_spinfit_vxb_crib...",/continue


  ;Delete unnecessary variables
  store_data,['*sfit'+pair+'*','bfield_data_gei',$
              '*esvy_spinfit_?',$
              rbspx+'_emfisis_l3_1sec_gse_Mag_spinfit_e'+pair+'_?',$
              rbspx+'_state_vel_coro_gei',rbspx+'_E_coro_mgse',$
              rbspx+'_emfisis_l3_'+type+'_gse_delta',rbspx+'_emfisis_l3_'+type+'_gse_lambda',$
              rbspx+'_emfisis_l3_4sec_gse_rms',$
              rbspx+'_emfisis_l3_1sec_gse_rms',$
              rbspx+'_state_pos_gei',rbspx+'_efw_esvy_ccsds_data_BEB_config',$
              rbspx+'_efw_esvy_ccsds_data_DFB_config'],/delete



end
