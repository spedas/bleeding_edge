pro ta15b_crib

; Set time range

timespan,'2007-03-23',1,/day

; Load THEMIS positions

thm_load_state,probe='a',datatype='pos',coord='GSM'
get_data,'tha_state_pos',data=d
times=d.x

; Load OMNI data

omni_load_data,varformat='*BY_GSM *BZ_GSM *flow_speed *proton_density *Pressure',/res5min

tomni2bindex,yimf_tvar='OMNI_HRO_5min_BY_GSM',zimf_tvar='OMNI_HRO_5min_BZ_GSM',V_p_tvar='OMNI_HRO_5min_flow_speed', $
  N_p_tvar='OMNI_HRO_5min_proton_density',newname='b_index', times=times

tplot,'OMNI_HRO_5min_BY_GSM OMNI_HRO_5min_BZ_GSM OMNI_HRO_5min_flow_speed OMNI_HRO_5min_proton_density b_index OMNI_HRO_5min_Pressure'

stop

; Now calculate the field at the S/C positions

tta15b,'tha_state_pos',pdyn='OMNI_HRO_5min_Pressure',yimf='OMNI_HRO_5min_BY_GSM',zimf='OMNI_HRO_5min_BZ_GSM',xind='b_index'

tplot,'*bta15b'

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

; Trace to equator using the calculated Pdyn with f_alpha=0.04

ttrace2equator,'tha_state_pos',trace_var_name='tha_state_pos_ta15b_etrace', newname='tha_state_pos_ta15b_trace_efoot',external_model='ta15b', $
                        pdyn='Pdyn_4pct',yimf='OMNI_HRO_5min_BY_GSM',zimf='OMNI_HRO_5min_BZ_GSM', $
                        xind='b_index',/km, error=trace_to_eq_error

tplot,'tha_state_pos_ta15b_trace_efoot'

stop

; Trace to ionosphere using the calculated Pdyn with f_alpha=0.04, using the GEOPACK_2008 set of routines

ttrace2iono,'tha_state_pos',trace_var_name='tha_state_pos_ta15b_itrace', newname='tha_state_pos_ta15b_trace_ifoot',external_model='ta15b', $
  pdyn='Pdyn_4pct',yimf='OMNI_HRO_5min_BY_GSM',zimf='OMNI_HRO_5min_BZ_GSM', $
  xind='b_index',/km, error=trace_to_iono_error,/geopack_2008


tplot,'tha_state_pos_ta15b_trace_ifoot'


end