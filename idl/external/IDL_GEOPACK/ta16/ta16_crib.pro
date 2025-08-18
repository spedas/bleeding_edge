;+
;Procedure: ta16_crib
;
;Purpose: A crib for the TA16 geopack model. 
;         Similar to ta15n_crib.pro.
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2022-09-22 15:30:50 -0700 (Thu, 22 Sep 2022) $
; $LastChangedRevision: 31125 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta16/ta16_crib.pro $
;-

pro ta16_crib

  ; Set time range

  timespan,'2007-03-23',1,/day

  ; Load THEMIS positions

  thm_load_state,probe='a',datatype='pos',coord='GSM'
  get_data,'tha_state_pos',data=d
  times=d.x

  ; Load OMNI data

  ; The N-index parameter must be seeded with 30 minutes of solar wind data prior to the first time of interest.
  timespan,'2007-03-22/23:30',24.5,/hours
  omni_load_data,varformat='*BY_GSM *BZ_GSM *flow_speed *proton_density *Pressure *SYM_H',/res5min

  ;  If no trange parameter is passed, tomni2nindex uses the timerange() command to get start/stop times for the
  ;  grid of 5-minute timestamps used internally and for the n_index output.  It doesn't look at the timestamps of
  ;  the solar wind variables, so beware of any intervening timespan calls between loading the OMNI data and
  ;  calling tomni2nindex.

  tomni2nindex,yimf_tvar='OMNI_HRO_5min_BY_GSM',zimf_tvar='OMNI_HRO_5min_BZ_GSM',V_p_tvar='OMNI_HRO_5min_flow_speed', $
    newname='n_index'

  tplot,'OMNI_HRO_5min_BY_GSM OMNI_HRO_5min_BZ_GSM OMNI_HRO_5min_flow_speed n_index OMNI_HRO_5min_Pressure'

  stop

  ; Now calculate the field at the S/C positions, using the OMNI pressure data.

  tta16,'tha_state_pos',pdyn='OMNI_HRO_5min_Pressure',yimf='OMNI_HRO_5min_BY_GSM',xind='n_index',symh='OMNI_HRO_5min_SYM_H'

  tplot,'*bta16'

  stop

  ; The OMNI dynamic pressure calculation might slightly overestimate the contribution of alpha particles.  tcalc_pdyn will
  ; calculate the pressure from the speed and density variables, with the option of supplying a custom f_alpha value (ratio of alphas
  ; to protons).  If not provided, f_alpha defaults to 0.04.

  tcalc_pdyn,V_p_tvar='OMNI_HRO_5min_flow_speed', N_p_tvar='OMNI_HRO_5min_proton_density',times=times,/speed,newname='Pdyn_4pct'
  tcalc_pdyn,V_p_tvar='OMNI_HRO_5min_flow_speed', N_p_tvar='OMNI_HRO_5min_proton_density',times=times,/speed,f_alpha=0.06,newname='Pdyn_6pct'

  store_data,'pdyn_comparison',data=['OMNI_HRO_5min_Pressure','Pdyn_4pct','Pdyn_6pct']
  options,'pdyn_comparison',colors=[0,4,6]
  tplot,'pdyn_comparison'

  stop

  ; The get_ta16_params routine can also be used to generate the TA16 model parameters with the required cadence, interpolation, and
  ; smoothing.  Interface is similar to get_tsy_params, except all input arguments are keywords.

  ; Set the model
  model='ta16'

  ; Combine the IMF Y and Z components into a single tplot variable.
  store_data,'omni_imf',data=['OMNI_HRO_5min_BY_GSM','OMNI_HRO_5min_BZ_GSM']

  ; Calculate parameters, output tplot variable defaults to 'ta15n_par'
  ; If n_index and pressure are supplied as tplot variables via xind_tvar and pressure_tvar keywords,
  ; the density and solar wind speed parameters are not needed.  Here, we let get_ta15_params recalculate the n_index and pressure.
  ; Internal pressure calculation uses the default f_alpha of 0.04,
  ; get_tsy_params calls this routine internally if the 'ta15n' or 'ta15b' models are specified.

  get_ta16_params,symh_tvar='OMNI_HRO_5min_SYM_H',symc_tvar=symc,imf_tvar='omni_imf',/imf_yz,Np_tvar= 'OMNI_HRO_5min_proton_density',Vp_tvar='OMNI_HRO_5min_flow_speed',/speed


  ; Trace to equator
  
  ; The previous call to tta16 has already set the internal path to the GEOPACK TA16 parameter file.   The
  ; skip_ta16_load=1 parameter avoids loading it again redundantly (although this is harmless).

  ttrace2equator,'tha_state_pos',trace_var_name='tha_state_pos_ta16_etrace', newname='tha_state_pos_ta16_trace_efoot',external_model=model, $
    par='ta16_par',/km, error=trace_to_eq_error, skip_ta16_load=1

  tplot,'tha_state_pos_ta16_trace_efoot'

  stop

  ; Trace to ionosphere using the calculated Pdyn with f_alpha=0.04, using the GEOPACK_2008 set of routines
  ; Here we pass the previously calculated model parameters by keyword.  We use skip_ta16_load=1 again because the
  ; internal path to the parameter file is still correct.

  ttrace2iono,'tha_state_pos',trace_var_name='tha_state_pos_ta16_itrace', newname='tha_state_pos_ta16_trace_ifoot',external_model=model, $
    pdyn='Pdyn_4pct',yimf='OMNI_HRO_5min_BY_GSM',zimf='OMNI_HRO_5min_BZ_GSM', symc=symc, xind='n_index',/km, error=trace_to_iono_error,$
    skip_ta16_load=1,/geopack_2008

  tplot,'tha_state_pos_ta16_trace_ifoot'

  print, 'END ta16_crib'
end