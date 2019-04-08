;+
; NAME: rbsp_efw_get_flag_values
; SYNTAX:
; PURPOSE: Returns a structure with flag values at "times" that is
; used to create CDF files
; INPUT:  sc ->  'a' or 'b'
;         times -> an array of unix times
;         bp -> boom pair. '12' or '34'
; OUTPUT:
;
; HISTORY: Created by Aaron W Breneman, Jan 8, 2015
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2019-03-14 08:20:24 -0700 (Thu, 14 Mar 2019) $
;   $LastChangedRevision: 26791 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_get_flag_values.pro $
;-


function rbsp_efw_get_flag_values,sc,times,density_min=dmin,boom_pair=bp

  if ~keyword_set(dmin) then dmin = 10.
  date = strmid(time_string(timerange()),0,10)
  date = date[0]


;Load the HSK data to flag the bias sweeps
  rbsp_load_efw_hsk,probe=sc,/get_support_data


;Possibly load state data
  get_data,'rbsp'+sc+'_state_lshell',data=test
  if ~is_struct(test) then rbsp_efw_position_velocity_crib



;Load other crap
  rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype='vsvy',/noclean

;Interpolate data to times. This gives nearly the same result as
;downsampling to spinperiod
  tinterpol_mxn,'rbsp'+sc+'_efw_vsvy',times,newname='rbsp'+sc+'_efw_vsvy'
  split_vec, 'rbsp'+sc+'_efw_vsvy', suffix='_V'+['1','2','3','4','5','6']
  get_data,'rbsp'+sc+'_efw_vsvy',data=vsvy




;load eclipse times
  rbsp_load_eclipse_predict,sc,date,$
                            local_data_dir='~/data/rbsp/',$
                            remote_data_dir='http://themis.ssl.berkeley.edu/data/rbsp/'
  get_data,'rbsp'+sc + '_umbra',data=eu
  get_data,'rbsp'+sc + '_penumbra',data=ep



;Calculate (V1+V2)/2
  get_data,'rbsp'+sc +'_efw_vsvy_V1',data=v1
  get_data,'rbsp'+sc +'_efw_vsvy_V2',data=v2
  get_data,'rbsp'+sc +'_efw_vsvy_V3',data=v3
  get_data,'rbsp'+sc +'_efw_vsvy_V4',data=v4
  get_data,'rbsp'+sc +'_efw_vsvy_V5',data=v5
  get_data,'rbsp'+sc +'_efw_vsvy_V6',data=v6

  sum12 = (v1.y + v2.y)/2.
  sum34 = (v3.y + v4.y)/2.
  sum56 = (v5.y + v6.y)/2.

  sum56[*] = -1.0E31



;Calculate density and remove bad values
;Determine density from sc potential.
;Remove values when dens < 10 and dens > 3000 cm-3
  store_data,'sc_potential',data={x:times,y:sum12}
  rbsp_efw_density_fit_from_uh_line,'sc_potential',sc,$
                                    newname='rbsp'+sc+'_density12',$
                                    dmin=dmin,$
                                    dmax=3000.,$
                                    setval=-1.e31

  store_data,'sc_potential',data={x:times,y:sum34}
  rbsp_efw_density_fit_from_uh_line,'sc_potential',sc,$
                                    newname='rbsp'+sc+'_density34',$
                                    dmin=dmin,$
                                    dmax=3000.,$
                                    setval=-1.e31


;For density we have a special requirement
;.....Remove when (V1+V2)/2 > 0 (CHANGED FROM -1) AND
;.....Lshell > 4  (avoids hot plasma sheet)
;.....AND remove when (V1+V2)/2 < -10

  tinterpol_mxn,'rbsp'+sc+'_state_lshell',times
  get_data,'rbsp'+sc+'_state_lshell_interp',data=lshell

  ;;Find charging times
  charging_flag = replicate(0.,n_elements(times))
  charging_flag_extreme = charging_flag

  if bp eq '12' then begin
    ;mild charging
    goo = where((lshell.y gt 4) and (sum12 gt 0),/null) & charging_flag[goo] = 1B
    goo = where(sum12 lt -20,/null) & charging_flag[goo] = 1B
    ;extreme charging
    goo = where((lshell.y gt 4) and (sum12 gt 20),/null) & charging_flag_extreme[goo] = 1B
    goo = where(sum12 lt -20,/null) & charging_flag_extreme[goo] = 1B
  endif
  if bp eq '34' then begin
    ;mild charging
    goo = where((lshell.y gt 4) and (sum34 gt 0),/null) & charging_flag[goo] = 1B
    goo = where(sum34 lt -20,/null) & charging_flag[goo] = 1B
    ;extreme charging
    goo = where((lshell.y gt 4) and (sum34 gt 20),/null) & charging_flag_extreme[goo] = 1B
    goo = where(sum34 lt -20,/null) & charging_flag_extreme[goo] = 1B
  endif


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



  get_data,'rbsp'+sc+'_density12',data=dens
  goo = where(charging_flag eq 1)
  if goo[0] ne -1 then dens.y[goo] = -1.e31
  store_data,'rbsp'+sc+'_density12',data=dens

  get_data,'rbsp'+sc+'_density34',data=dens
  goo = where(charging_flag eq 1)
  if goo[0] ne -1 then dens.y[goo] = -1.e31
  store_data,'rbsp'+sc+'_density34',data=dens



;----------------------------------------------------------------------------------------------------
;FIND AND SET ALL FLAG VALUES
;----------------------------------------------------------------------------------------------------

  ;;    names = ['global_flag',$
  ;;             'eclipse',$
  ;;             'maneuver',$
  ;;             'efw_sweep',$
  ;;             'efw_deploy',$
  ;;             'v1_saturation',$
  ;;             'v2_saturation',$
  ;;             'v3_saturation',$
  ;;             'v4_saturation',$
  ;;             'v5_saturation',$
  ;;             'v6_saturation',$
  ;;             'Espb_magnitude',$
  ;;             'Eparallel_magnitude',$
  ;;             'magnetic_wake',$
  ;;             'autobias',$
  ;;             'charging',$
  ;;             'charging_extreme',$
  ;;             'density',$
  ;;             'undefined',$
  ;;             'undefined']




                                ;Get flag values
  na_val = -2                   ;not applicable value
  fill_val = -1                 ;value in flag array that indicates "dunno"
  maxvolts = 195.               ;Max antenna voltage above which the saturation flag is thrown
  offset = 5                    ;position in flag_arr of "v1_saturation"

  tmp = replicate(0,n_elements(times),6)
  flag_arr = replicate(fill_val,n_elements(times),20)


;Some values we can set right away
  flag_arr[*,9] = 1             ;V5 flag always set
  flag_arr[*,10] = 1            ;V6 flag always set
  flag_arr[*,11] = na_val       ;Espb_magnitude
  flag_arr[*,12] = na_val       ;Eparallel_magnitude
  flag_arr[*,13] = na_val       ;magnetic_wake
  flag_arr[*,17:19] = na_val    ;undefined values




;Set flag if antenna potential exceeds max value
  for i=0,5 do begin
     vbad = where(abs(vsvy.y[*,i]) ge maxvolts)
     if vbad[0] ne -1 then tmp[vbad,i] = 1
     flag_arr[*,i+offset] = tmp[*,i]
  endfor

;set the eclipse flag in this program
  padec = 5.*60. ;plus/minus value (sec) outside of the eclipse start and stop times for throwing the eclipse flag

;Umbra
  if is_struct(eu) then begin
     for bb=0,n_elements(eu.x)-1 do begin
        goo = where((times ge (eu.x[bb]-padec)) and (times le (eu.x[bb]+eu.y[bb]+padec)))
        if goo[0] ne -1 then flag_arr[goo,1] = 1
     endfor
  endif
;Penumbra
  if is_struct(ep) then begin
     for bb=0,n_elements(ep.x)-1 do begin
        goo = where((times ge (ep.x[bb]-padec)) and (times le (ep.x[bb]+ep.y[bb]+padec)))
        if goo[0] ne -1 then flag_arr[goo,1] = 1
     endfor
  endif





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

  m = rbsp_load_maneuver_file(sc,date)
  if is_struct(m) then begin
     for bb=0,n_elements(m.m0)-1 do begin
        goo = where((times ge m.m0[bb]) and (times le m.m1[bb]))
        if goo[0] ne -1 then flag_arr[goo,2] = 1
     endfor
  endif


;--------------------------------------------------
;Determine times of bias sweeps
;--------------------------------------------------


  get_data, 'rbsp'+sc+'_efw_hsk_beb_analog_CONFIG0', data = BEB_config
  if is_struct(BEB_config) then begin
     bias_sweep = intarr(n_elements(BEB_config.x))
     boo = where(BEB_config.y eq 64)
     if boo[0] ne -1 then bias_sweep[boo] = 1
     store_data,'bias_sweep',data={x:BEB_config.x,y:bias_sweep}
     tinterpol_mxn,'bias_sweep',times
     ;; ylim,['bias_sweep','bias_sweep_interp'],0,1.5
     ;; tplot,['bias_sweep','bias_sweep_interp']
     get_data,'bias_sweep_interp',data=bias_sweep
     bias_sweep_flag = bias_sweep.y
  endif else begin
     bias_sweep_flag = replicate(fill_val,n_elements(times))
  endelse


;------------------------------------------------
;ADD AUTO BIAS TO FLAG VALUES
;------------------------------------------------

;; AutoBias starts actively controlling the bias currents at V12 = -1.0 V,
;; ramping down the magnitude of the bias current so that when V12 = 0.0 V,
;; the bias current is very near to zero after starting out around -20
;; nA/sensor.

;; For V12 > 0.0 V, the bias current continues to increase (become more
;; positive), although at a slower rate, 0.2 nA/V or something like that.


;Auto Bias flag values. From 'rbsp?_efw_hsk_idpu_fast_TBD'
;Bit	Value	Meaning
;3	8	Toggles off and on every other cycle when AutoBias is;
;		active.
;2	4	One when AutoBias is controlling the bias, Zero when
;		AutoBias is not controlling the bias.
;1	2	One when BIAS3 and BIAS4 can be controlled by AUtoBias,
;		zero otherwise.
;0	1	One when BIAS1 and BIAS2 can be controlled by AUtoBias,
;		zero otherwise.



                                ;Find times when auto biasing is active
  get_data,'rbsp'+sc+'_efw_hsk_idpu_fast_TBD',data=tbd
  tbd.y = floor(tbd.y)
  ab_flag = intarr(n_elements(tbd.x))

                                ;Possible flag values for on and off
  ab_off = [1,2,3,8,10,11]
  ab_on = [4,5,6,7,12,13,14,15]

  goo = where((tbd.y eq 4) or (tbd.y eq 5) or (tbd.y eq 6) or (tbd.y eq 7) or (tbd.y eq 12) or (tbd.y eq 13) or (tbd.y eq 14) or (tbd.y eq 15))
  if goo[0] ne -1 then ab_flag[goo] = 1

  store_data,'ab_flag',data={x:tbd.x,y:ab_flag}
  ;; options,['rbsp'+sc+'_efw_hsk_idpu_fast_TBD','ab_flag'],'psym',4
  ;; tplot,['rbsp'+sc+'_efw_hsk_idpu_fast_TBD','ab_flag','rbsp'+sc+'_state_lshell']
  ;; timebar,eu.x
  ;; timebar,eu.x+eu.y


  tinterpol_mxn,'ab_flag',times
  ;; tplot,['ab_flag','ab_flag_interp']

  get_data,'ab_flag_interp',data=ab_flag
  ab_flag = ab_flag.y



;--------------------------------------------------
;ADD IN ACTUAL BIAS CURRENTS
;--------------------------------------------------

  tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS1',times
  tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS2',times
  tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS3',times
  tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS4',times
  tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS5',times
  tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS6',times
;tplot,['*IBIAS*','rbsp'+sc+'_efw_hsk_idpu_fast_TBD']

  get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS1_interp',data=ib1
  get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS2_interp',data=ib2
  get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS3_interp',data=ib3
  get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS4_interp',data=ib4
  get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS5_interp',data=ib5
  get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS6_interp',data=ib6

  if is_struct(ib1) and is_struct(ib2) and is_struct(ib3) and $
     is_struct(ib4) and is_struct(ib5) and is_struct(ib6) then $
        ibias = [[ib1.y],[ib2.y],[ib3.y],[ib4.y],[ib5.y],[ib6.y]] else ibias = 0.






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

  goo = where(flag_arr[*,3] eq fill_val) ;bias sweep
  if goo[0] ne -1 then flag_arr[goo,3] = 0

  goo = where(flag_arr[*,4] eq fill_val) ;antenna deploy
  if goo[0] ne -1 then flag_arr[goo,4] = 0

  goo = where(flag_arr[*,14] eq fill_val) ;autobias
  if goo[0] ne -1 then flag_arr[goo,14] = 0

  goo = where(flag_arr[*,15] eq fill_val) ;charging
  if goo[0] ne -1 then flag_arr[goo,15] = 0

  goo = where(flag_arr[*,1] eq fill_val) ;eclipse
  if goo[0] ne -1 then flag_arr[goo,1] = 0

  goo = where(flag_arr[*,2] eq fill_val) ;maneuver
  if goo[0] ne -1 then flag_arr[goo,2] = 0



;--------------------------------------------------
;SET GLOBAL FLAG
;--------------------------------------------------
;Conditions for throwing global flag
;..........any of the v1-v4 saturation flags are thrown
;..........the eclipse flag is thrown
;..........maneuver
;..........charging flag thrown
;..........antenna deploy
;..........bias sweep

  flag_arr[*,0] = 0

  goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,6] eq 1) or (flag_arr[*,7] eq 1) or (flag_arr[*,8] eq 1))
  if goo[0] ne -1 then flag_arr[goo,0] = 1 ;v1-v4 saturation

  goo = where(flag_arr[*,1] eq 1) ;eclipse
  if goo[0] ne -1 then flag_arr[goo,0] = 1

  goo = where(flag_arr[*,15] eq 1) ;charging
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
             charging_flag_extreme:charging_flag_extreme,$
             ibias:ibias}

  return,flagstr



end
