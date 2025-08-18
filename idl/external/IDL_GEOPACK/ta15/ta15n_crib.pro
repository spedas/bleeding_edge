pro ta15n_crib

; Set time range

timespan,'2007-03-23',1,/day

; Load THEMIS positions

thm_load_state,probe='a',datatype='pos',coord='GSM'
get_data,'tha_state_pos',data=d
times=d.x

; Load OMNI data

; The N-index parameter must be seeded with 30 minutes of solar wind data prior to the first time of interest.
timespan,'2007-03-22/23:30',24.5,/hours
omni_load_data,varformat='*BY_GSM *BZ_GSM *flow_speed *proton_density *Pressure',/res5min

;  If no trange parameter is passed, tomni2nindex uses the timerange() command to get start/stop times for the 
;  grid of 5-minute timestamps used internally and for the n_index output.  It doesn't look at the timestamps of
;  the solar wind variables, so beware of any intervening timespan calls between loading the OMNI data and
;  calling tomni2nindex.

tomni2nindex,yimf_tvar='OMNI_HRO_5min_BY_GSM',zimf_tvar='OMNI_HRO_5min_BZ_GSM',V_p_tvar='OMNI_HRO_5min_flow_speed', $
  newname='n_index'

tplot,'OMNI_HRO_5min_BY_GSM OMNI_HRO_5min_BZ_GSM OMNI_HRO_5min_flow_speed n_index OMNI_HRO_5min_Pressure'

stop

; Now calculate the field at the S/C positions, using the OMNI pressure data.

tta15n,'tha_state_pos',pdyn='OMNI_HRO_5min_Pressure',yimf='OMNI_HRO_5min_BY_GSM',zimf='OMNI_HRO_5min_BZ_GSM',xind='n_index'

tplot,'*bta15n'

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

; The get_ta15_params routine can also be used to generate the TS04 model parameters with the required cadence, interpolation, and
; smoothing.  Interface is similar to get_tsy_params, except all input arguments are keywords.

; Set the model
model='ta15n'

; Combine the IMF Y and Z components into a single tplot variable.
store_data,'omni_imf',data=['OMNI_HRO_5min_BY_GSM','OMNI_HRO_5min_BZ_GSM']

; Calculate parameters, output tplot variable defaults to 'ta15n_par'
; If n_index and pressure are supplied as tplot variables via xind_tvar and pressure_tvar keywords, 
; the density and solar wind speed parameters are not needed.  Here, we let get_ta15_params recalculate the n_index and pressure.
; Internal pressure calculation uses the default f_alpha of 0.04,
; get_tsy_params calls this routine internally if the 'ta15n' or 'ta15b' models are specified.

get_ta15_params,imf_tvar='omni_imf',/imf_yz,Np_tvar= 'OMNI_HRO_5min_proton_density',Vp_tvar='OMNI_HRO_5min_flow_speed',/speed, $
   model=model


; Trace to equator 

ttrace2equator,'tha_state_pos',trace_var_name='tha_state_pos_ta15n_etrace', newname='tha_state_pos_ta15n_trace_efoot',external_model='ta15n', $
                        par='ta15n_par',/km, error=trace_to_eq_error

tplot,'tha_state_pos_ta15n_trace_efoot'

stop

; Trace to ionosphere using the calculated Pdyn with f_alpha=0.04, using the GEOPACK_2008 set of routines
; Here we pass the previously calculated model parameters by keyword.

ttrace2iono,'tha_state_pos',trace_var_name='tha_state_pos_ta15n_itrace', newname='tha_state_pos_ta15n_trace_ifoot',external_model='ta15n', $
  pdyn='Pdyn_4pct',yimf='OMNI_HRO_5min_BY_GSM',zimf='OMNI_HRO_5min_BZ_GSM', $
  xind='n_index',/km, error=trace_to_iono_error,/geopack_2008


tplot,'tha_state_pos_ta15n_trace_ifoot'


end