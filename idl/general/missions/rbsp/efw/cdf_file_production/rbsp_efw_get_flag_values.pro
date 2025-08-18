;+
; NAME: rbsp_efw_get_flag_values
; SYNTAX:
; PURPOSE: Returns a structure with flag values at "times" that is
; used to create CDF files
; INPUT:  sc ->  'a' or 'b'
;         times -> an array of unix times
;         bp -> boom pair. Any combination of two booms. Defaults to '12'
; OUTPUT:
;
;         flag_names -> returned array with the names of the flags. Useful for
;                       adding suffixes to "split_vec"
;
; HISTORY: Created by Aaron W Breneman, Jan 8, 2015
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2020-09-11 13:31:02 -0700 (Fri, 11 Sep 2020) $
;   $LastChangedRevision: 29133 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/cdf_file_production/rbsp_efw_get_flag_values.pro $
;-


function rbsp_efw_get_flag_values,sc,times,$
  density_min=dmin,$
  boom_pair=bp,$
  _extra=extra,$
  flag_names=flag_names



  ;Fill values for flag
  na_val = -2                   ;not applicable value
  fill_val = -1                 ;value in flag array that indicates "dunno"
  maxvolts = 195.               ;Max antenna voltage above which the saturation flag is thrown
  offset = 5                    ;position in flag_arr of "v1_saturation"



  if ~keyword_set(dmin) then dmin = 10.
  date = strmid(time_string(timerange()),0,10)
  date = date[0]

  tr = timerange()

  rbx = 'rbsp'+sc

  if ~KEYWORD_SET(bp) then bp = '12'




;  ;Possibly load the HSK data (to flag the bias sweeps)
;  if ~tdexists(rbx+'_efw_hsk_idpu_analog_P15IMON',tr[0],tr[1]) then $
;    rbsp_load_efw_hsk,probe=sc,/get_support_data


;  ;Possibly load the ephemeris data
;  if ~tdexists(rbx+'_state_mlat',tr[0],tr[1]) then $
;    rbsp_efw_position_velocity_crib,probe=sc,_extra=extra



  ;Possibly load the ephemeris data
  if ~tdexists(rbx+'_q_uvw2gse',tr[0],tr[1]) then $
    rbsp_load_spice_cdf_file,sc

  ;Possibly load waveform data
  if ~tdexists(rbx+'_efw_vsvy',tr[0],tr[1]) then $
    rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype='vsvy',/noclean

  ;Possibly load the wake flag
  if ~tdexists(rbx+'_eu_wake_flag',tr[0],tr[1]) then $
    rbsp_load_wake_effect_cdf_file,sc

  ;Possibly load the autobias times
  if ~tdexists(rbx+'_ab_flag',tr[0],tr[1]) then $
    rbsp_load_autobias_cdf_file,sc


  ;Interpolate data to times. This gives nearly the same result as downsampling to spinperiod
  if ~tdexists(rbx+'_efw_vsvy_DS',tr[0],tr[1]) then tinterpol_mxn,rbx+'_efw_vsvy',times,newname=rbx+'_efw_vsvy_DS',/spline
  get_data,rbx+'_efw_vsvy_DS',data=vsvy
;  if ~tdexists(rbx+'_efw_vsvy_DS_1',tr[0],tr[1]) then split_vec, rbx+'_efw_vsvy_DS', suffix='_'+['1','2','3','4','5','6']




  if bp eq '12' then sumpair = (vsvy.y[*,0] + vsvy.y[*,1])/2.
  if bp eq '13' then sumpair = (vsvy.y[*,0] + vsvy.y[*,2])/2.
  if bp eq '14' then sumpair = (vsvy.y[*,0] + vsvy.y[*,3])/2.
  if bp eq '23' then sumpair = (vsvy.y[*,1] + vsvy.y[*,2])/2.
  if bp eq '24' then sumpair = (vsvy.y[*,1] + vsvy.y[*,3])/2.
  if bp eq '34' then sumpair = (vsvy.y[*,2] + vsvy.y[*,3])/2.






;Calculate density and remove bad values
;Determine density from sc potential.
;Remove values when dens < 10 and dens > 3000 cm-3


  store_data,'sc_potential',data={x:times,y:sumpair}
  rbsp_efw_density_fit_from_uh_line,'sc_potential',sc,$
                                    newname=rbx+'_density'+bp,$
                                    dmin=dmin,$
                                    dmax=3000.,$
                                    setval=-1.e31



;For density we have a special requirement
;.....Remove when (V1+V2)/2 > 0 (for bp='12') (CHANGED FROM -1) AND
;.....Lshell > 4  (avoids hot plasma sheet)
;.....AND remove when (V1+V2)/2 < -20

  if ~tdexists(rbx+'_state_lshell_interp',tr[0],tr[1]) then tinterpol_mxn,rbx+'_state_lshell',times,/spline
  get_data,rbx+'_state_lshell_interp',data=lshell

  ;;Find charging times
  charging_flag = replicate(0,n_elements(times))
  charging_flag_extreme = charging_flag



  ;mild charging (also thrown when extreme_charging flag is thrown)
  goo = where((lshell.y gt 4) and (sumpair gt 0),/null) & charging_flag[goo] = 1B
  goo = where(sumpair lt -20,/null) & charging_flag[goo] = 1B
  ;extreme charging
  goo = where((lshell.y gt 4) and (sumpair gt 20),/null) & charging_flag_extreme[goo] = 1B
  goo = where(sumpair lt -20,/null) & charging_flag_extreme[goo] = 1B





  ;PAD THE CHARGING FLAG....
  ;But, we'll also remove values +/- 10 minutes at start and
  ;finish of charging times (Scott indicates that this is a good thing
  ;to do)
  padch = 10.*60.


  ;force first and last elements to be zero. This guarantees that we have
  ;charging start times before end times.
  charging_flag[0] = 0. & charging_flag[-1] = 0.


  ;Determine start and end times of charging
  chdiff = charging_flag - shift(charging_flag,1)
  chstart_i = where(chdiff eq 1,/null)
  chend_i = where(chdiff eq -1,/null)


  chunksz_sec = ceil((times[-1] - times[0])/n_elements(times))
  chunksz_i = ceil(padch/chunksz_sec) ;number of data chunks in "padch"


  if n_elements(chstart_i) ge 1 then begin
    for i=0,n_elements(chstart_i)-1 do begin
      ;Pad charging times at beginning of charging
      if chstart_i[i]-chunksz_i lt 0 then charging_flag[0:chstart_i[i]] = 1 else $
      charging_flag[chstart_i[i]-chunksz_i:chstart_i[i]] = 1
      ;Pad charging times at end of charging
      if chend_i[i]+chunksz_i ge n_elements(times) then charging_flag[chend_i[i]:-1] = 1 else $
      charging_flag[chend_i[i]:chend_i[i]+chunksz_i] = 1
    endfor
  endif





    get_data,rbx+'_density'+bp,data=dens
    goo = where(charging_flag eq 1)
    if goo[0] ne -1 then dens.y[goo] = -1.e31
    store_data,rbx+'_density'+bp,data=dens



    tinterpol_mxn,rbx+'_e?_wake_flag',times,/spline






;----------------------------------------------------------------------------------------------------
;FIND AND SET ALL FLAG VALUES
;----------------------------------------------------------------------------------------------------

names = ['global_flag',$
         'eclipse',$
         'maneuver',$
         'efw_sweep',$
         'efw_deploy',$
         'v1_saturation',$
         'v2_saturation',$
         'v3_saturation',$
         'v4_saturation',$
         'v5_saturation',$
         'v6_saturation',$
         'Espb_magnitude',$
         'Eparallel_magnitude',$
         'magnetic_wake',$
         'autobias',$
         'charging',$
         'charging_extreme',$
         'density',$
         'undefined',$
         'undefined']


  flag_names = names

  tmp = replicate(0,n_elements(times),6)
  flag_arr = replicate(0.,n_elements(times),20)


;Some values we can set right away
  flag_arr[*,9] = 1             ;V5 flag always set
  flag_arr[*,10] = 1            ;V6 flag always set
  flag_arr[*,11] = na_val       ;Espb_magnitude
  flag_arr[*,12] = na_val       ;Eparallel_magnitude
  flag_arr[*,17:19] = na_val    ;undefined values



;Set magnetic wake flag
  get_data,rbx+'_eu_wake_flag_interp',data=eu
  get_data,rbx+'_ev_wake_flag_interp',data=ev
  wakeflag = eu.y or ev.y
  flag_arr[*,13] = wakeflag       ;magnetic_wake



;Set flag if antenna potential exceeds max value
  for i=0,5 do begin
     vbad = where(abs(vsvy.y[*,i]) ge maxvolts)
     if vbad[0] ne -1 then tmp[vbad,i] = 1
     flag_arr[*,i+offset] = tmp[*,i]
  endfor




  ;-----------------------------------------------------------------------------
  ;Load eclipse times and set flag_arr[n,1]
  ;-----------------------------------------------------------------------------

  padec = 10.*60. ;plus/minus value (sec) outside of the eclipse start and stop times for throwing the eclipse flag

  etimes = rbsp_load_eclipse_times(sc)

  for bb=0,n_elements(etimes.estart)-1 do begin
    goo = where((times ge (etimes.estart[bb]-padec)) and (times le (etimes.eend[bb]+padec)))
    if goo[0] ne -1 then flag_arr[goo,1] = 1
  endfor


;--------------------------------------------------
;Determine times of antenna deployment
;--------------------------------------------------


  dep = rbsp_efw_boom_deploy_history(date,allvals=av)

  if sc eq 'a' then begin
     ds12 = strmid(av.deploystarta12,0,10)
     ds34 = strmid(av.deploystarta34,0,10)
     ds5 = strmid(av.deploystarta5,0,10)
     ds6 = strmid(av.deploystarta6,0,10)

     de12 = strmid(av.deployenda12,0,10)
     de34 = strmid(av.deployenda34,0,10)
     de5 = strmid(av.deployenda5,0,10)
     de6 = strmid(av.deployenda6,0,10)

     deps_alltimes = time_double([av.deploystarta12,av.deploystarta34,av.deploystarta5,av.deploystarta6])
     depe_alltimes = time_double([av.deployenda12,av.deployenda34,av.deployenda5,av.deployenda6])
  endif else begin
     ds12 = strmid(av.deploystartb12,0,10)
     ds34 = strmid(av.deploystartb34,0,10)
     ds5 = strmid(av.deploystartb5,0,10)
     ds6 = strmid(av.deploystartb6,0,10)

     de12 = strmid(av.deployendb12,0,10)
     de34 = strmid(av.deployendb34,0,10)
     de5 = strmid(av.deployendb5,0,10)
     de6 = strmid(av.deployendb6,0,10)

     deps_alltimes = time_double([av.deploystartb12,av.deploystartb34,av.deploystartb5,av.deploystartb6])
     depe_alltimes = time_double([av.deployendb12,av.deployendb34,av.deployendb5,av.deployendb6])
  endelse


;all the dates of deployment times (note: all deployments start and
;end on same date)
  dep_alldates = [ds12,ds34,ds5,ds6]

  goo = where(date eq dep_alldates)
  if goo[0] ne -1 then begin
     ;;for each deployment find timerange and flag
     for y=0,n_elements(goo)-1 do begin
        boo = where((times ge deps_alltimes[goo[y]]) and (times le depe_alltimes[goo[y]]))
        if boo[0] ne -1 then flag_arr[boo,4] = 1
     endfor
  endif

;--------------------------------------------------
;Determine maneuver times
;--------------------------------------------------

  m = rbsp_load_maneuver_times(sc)
  for bb=0,n_elements(m.estart)-1 do begin
    goo = where((times ge (m.estart[bb])) and (times le (m.eend[bb])))
    if goo[0] ne -1 then flag_arr[goo,2] = 1
  endfor


;--------------------------------------------------
;Determine times of bias sweeps
;--------------------------------------------------

  sdt = rbsp_load_sdt_times(sc)

  bias_sweep_flag = replicate(0,n_elements(times))
  for i=0,n_elements(sdt.sdtstart)-1 do begin $
    goo = where((times ge sdt.sdtstart[i]) and (times le sdt.sdtend[i])) & $
    if goo[0] ne -1 then bias_sweep_flag[goo] = 1
  endfor


;;NOTE: UNDER CONSTRUCTION!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;
;  get_data, rbx+'_efw_hsk_beb_analog_CONFIG0', data = BEB_config
;  if is_struct(BEB_config) then begin
;
;    ;This variable may already exist from previous calls to this
;    ;routine using a different boom pair.
;    if ~tdexists('bias_sweep_interp',tr[0],tr[1]) then begin
;      bias_sweep = intarr(n_elements(BEB_config.x))
;      boo = where(BEB_config.y eq 64)
;      if boo[0] ne -1 then bias_sweep[boo] = 1
;      store_data,'bias_sweep',data={x:BEB_config.x,y:bias_sweep}
;      tinterpol_mxn,'bias_sweep',times,/spline
;    endif
;    get_data,'bias_sweep_interp',data=bias_sweep
;    bias_sweep_flag = bias_sweep.y
;
;  endif else begin
;     bias_sweep_flag = replicate(fill_val,n_elements(times))
;  endelse
;

;------------------------------------------------
;ADD AUTO BIAS TO FLAG VALUES
;------------------------------------------------


  tinterpol_mxn,'rbsp'+sc+'_ab_flag',times,/overwrite,/spline
  get_data,'rbsp'+sc+'_ab_flag',tt,ab_flag



;--------------------------------------------------
;Set individual flags based on above calculated values
;--------------------------------------------------

  flag_arr[*,3] = bias_sweep_flag
  flag_arr[*,14] = ab_flag       ;autobias
  flag_arr[*,15] = charging_flag ;charging
  flag_arr[*,16] = charging_flag_extreme ;extreme charging

;--------------------------------------------------
;Change values of certain arrays that are "fill_val" to 0
;--------------------------------------------------

;  goo = where(flag_arr[*,3] eq fill_val) ;bias sweep
;  if goo[0] ne -1 then flag_arr[goo,3] = 0
;
;  goo = where(flag_arr[*,4] eq fill_val) ;antenna deploy
;  if goo[0] ne -1 then flag_arr[goo,4] = 0
;
;  goo = where(flag_arr[*,14] eq fill_val) ;autobias
;  if goo[0] ne -1 then flag_arr[goo,14] = 0
;
;  goo = where(flag_arr[*,15] eq fill_val) ;charging
;  if goo[0] ne -1 then flag_arr[goo,15] = 0
;
;  goo = where(flag_arr[*,1] eq fill_val) ;eclipse
;  if goo[0] ne -1 then flag_arr[goo,1] = 0
;
;  goo = where(flag_arr[*,2] eq fill_val) ;maneuver
;  if goo[0] ne -1 then flag_arr[goo,2] = 0



;--------------------------------------------------
;SET GLOBAL FLAG
;--------------------------------------------------
;Conditions for throwing global flag
;..........Vx or Vy, corresponding to boom pair used (e.g. V12), saturation flags are thrown
;..........the eclipse flag is thrown
;..........maneuver
;..........charging flag thrown (normal or extreme charging)
;..........antenna deploy
;..........bias sweep

  flag_arr[*,0] = 0


  ;v1-v4 saturation
  if bp eq '12' then goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,6] eq 1))
  if bp eq '13' then goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,7] eq 1))
  if bp eq '14' then goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,8] eq 1))
  if bp eq '23' then goo = where((flag_arr[*,6] eq 1) or (flag_arr[*,7] eq 1))
  if bp eq '24' then goo = where((flag_arr[*,6] eq 1) or (flag_arr[*,8] eq 1))
  if bp eq '34' then goo = where((flag_arr[*,7] eq 1) or (flag_arr[*,8] eq 1))
;  goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,6] eq 1) or (flag_arr[*,7] eq 1) or (flag_arr[*,8] eq 1))
  if goo[0] ne -1 then flag_arr[goo,0] = 1

  goo = where(flag_arr[*,1] eq 1) ;eclipse
  if goo[0] ne -1 then flag_arr[goo,0] = 1

  goo = where(flag_arr[*,15] eq 1) ;charging or extreme charging
  if goo[0] ne -1 then flag_arr[goo,0] = 1

  goo = where(flag_arr[*,3] eq 1) ;bias sweep
  if goo[0] ne -1 then flag_arr[goo,0] = 1

  goo = where(flag_arr[*,4] eq 1) ;antenna deploy
  if goo[0] ne -1 then flag_arr[goo,0] = 1

  goo = where(flag_arr[*,2] eq 1) ;maneuver
  if goo[0] ne -1 then flag_arr[goo,0] = 1




;Create structure with various flag values
  flagstr = {flag_arr:flag_arr,$
             bias_sweep_flag:bias_sweep_flag,$
             ab_flag:ab_flag,$
             charging_flag:charging_flag,$
             charging_flag_extreme:charging_flag_extreme}


  return,flagstr



end
