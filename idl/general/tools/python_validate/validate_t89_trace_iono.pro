pro circle_5re,start_time,suffix
  ; Generate a circle at 5 RE in the XZ plane
  angle = dindgen(361.0)*!dpi/180.0

  pos = dblarr(361,3)
  pos[*,0] = 5.0*sin(angle)
  pos[*,1] = 0.0
  pos[*,2] = 5.0*cos(angle)
  t = time_double(start_time) + dindgen(361.0)
  dl = {data_att:{units:'Re',coord_sys:'GSM'}}
  store_data,'circle_magpoles_5re'+suffix,data={x:t,y:pos},dl=dl
  tkm2re,'circle_magpoles_5re'+suffix,/km
  ;tplot,['circle_magpoles_5re','circle_magpoles_5re_km']
end

pro validate_t89_trace_iono
del_data,'*'

timespan,'2007-03-23',1,/day

thm_load_state,probe='a',coord='gsm'

ttrace2iono,'tha_state_pos',newname='ifoot_t89_n',/geopack_2008,/refine,external_model='t89',/km,kp=2.0,trace_var_name='tha_iono_t89_trace_n'
ttrace2iono,'tha_state_pos',newname='ifoot_t89_s',/geopack_2008,/refine,external_model='t89',/km,kp=2.0,trace_var_name='tha_iono_t89_trace_s',/south

ttrace2equator,'tha_state_pos',newname='eq_foot_t89',/geopack_2008,external_model='t89',/km,kp=2.0,trace_var_name='tha_eq_t89_trace'

; Test calculate_lshell
tkm2re, 'tha_state_pos'
get_data,'tha_state_pos_re',data=d
gsm_re = dblarr(n_elements(d.x),4)
gsm_re[*,0]=d.x
gsm_re[*,1:3] = d.y
gsm_re = transpose(gsm_re)
l = calculate_lshell(gsm_re, geopack_2008=1)
store_data,'tha_state_pos_lshell',data={x:d.x, y:l}
;tplot, 'tha_state_pos_lshell'

; Repeat with actual solar wind parameters

; Expand support timerange by 30 minutes each side

timespan,'2007-03-22/23:30',25,/hours

kyoto_load_dst
omni_load_data
noaa_load_kp

; Use Geopack routines to calculate g1, g2  and w1-w6 parameters for T01 and TS04 models

vsw_tvar = 'OMNI_HRO_1min_flow_speed'
yimf_tvar = 'OMNI_HRO_1min_BY_GSM'
zimf_tvar = 'OMNI_HRO_1min_BZ_GSM'
dens_tvar = 'OMNI_HRO_1min_proton_density'

get_data, 'OMNI_HRO_1min_flow_speed', data=vsw
trange = minmax(vsw.x)
n = fix(trange[1]-trange[0],type=3)/300 +1
;the geopack parameter generating functions only work on 5 minute intervals

;construct a time array
ntimes=dindgen(n)*300+trange[0]

; Interpolate input variables to 5-minute grid, ensuring no NaNs in output
tinterpol_mxn,yimf_tvar,ntimes,/ignore_nans,out=yimf_tvar+'_interp'
tinterpol_mxn,zimf_tvar,ntimes,/ignore_nans,out=zimf_tvar+'_interp'
tinterpol_mxn,vsw_tvar,ntimes,/ignore_nans,out=vsw_tvar + '_interp'
tinterpol_mxn,dens_tvar,ntimes,/ignore_nans,out=dens_tvar + '_interp'

get_data, 'OMNI_HRO_1min_flow_speed_interp', data=vsw
get_data, 'OMNI_HRO_1min_BY_GSM_interp', data=bygsm
get_data, 'OMNI_HRO_1min_BZ_GSM_interp', data=bzgsm
get_data, 'OMNI_HRO_1min_proton_density_interp', data=dens

geopack_getg, vsw.y, bygsm.y, bzgsm.y, g

g1=g[*,0]
g2=g[*,1]

store_data,'g1',data={x:vsw.x, y:g1}
store_data,'g2',data={x:vsw.x, y:g2}

;tplot,'OMNI_HRO_1min_BY_GSM OMNI_HRO_1min_BZ_GSM OMNI_HRO_1min_flow_speed g1 g2'
;stop

geopack_getw, dens.y, vsw.y, bzgsm.y, w

w1 = w[*,0]
w2 = w[*,1]
w3 = w[*,2]
w4 = w[*,3]
w5 = w[*,4]
w6 = w[*,5]
store_data,'w1',data={x:vsw.x, y:w1}
store_data,'w2',data={x:vsw.x, y:w2}
store_data,'w3',data={x:vsw.x, y:w3}
store_data,'w4',data={x:vsw.x, y:w4}
store_data,'w5',data={x:vsw.x, y:w5}
store_data,'w6',data={x:vsw.x, y:w6}
;tplot,'OMNI_HRO_1min_proton_density OMNI_HRO_1min_BZ_GSM OMNI_HRO_1min_flow_speed w1 w2 w3 w4 w5 w6'
;stop

; Trace to ionosphere with actual solar wind paramters
; The advanced models are quite a bit slower, so we'll thin the positions out by a factor of 10

idx_all = indgen(1440)
idx_mod10 = where(idx_all mod 10 eq 0)
get_data,'tha_state_pos',data=d,dl=dl
store_data,'tha_state_pos_reduced',data={x:d.x[idx_mod10], y:d.y[idx_mod10,*]},dl=dl


ttrace2iono,'tha_state_pos_reduced',newname='ifoot_t89_s_actual',/geopack_2008,/exact_tilt,/refine,external_model='t89',/km,kp='Kp',/south
ttrace2iono,'tha_state_pos_reduced',newname='ifoot_t96_s_actual',/geopack_2008,/exact_tilt,/refine,external_model='t96',/km,pdyn='OMNI_HRO_1min_Pressure',dsti='kyoto_dst',yimf='OMNI_HRO_1min_BY_GSM',zimf='OMNI_HRO_1min_BZ_GSM',/south
ttrace2iono,'tha_state_pos_reduced',newname='ifoot_t01_s_actual',/exact_tilt,external_model='t01',/km,pdyn='OMNI_HRO_1min_Pressure',dsti='kyoto_dst',yimf='OMNI_HRO_1min_BY_GSM',zimf='OMNI_HRO_1min_BZ_GSM',g1='g1',g2='g2',/south
ttrace2iono,'tha_state_pos_reduced',newname='ifoot_t04s_s_actual',/geopack_2008,/exact_tilt,/refine,external_model='t04s',/km,pdyn='OMNI_HRO_1min_Pressure',dsti='kyoto_dst',yimf='OMNI_HRO_1min_BY_GSM',zimf='OMNI_HRO_1min_BZ_GSM',w1='w1',w2='w2',w3='w3',w4='w4',w5='w5',w6='w6',/south

circle_5re, '2007-03-23', ''
ttrace2iono, 'circle_magpoles_5re_km', newname='ifoot_t89_5re_magpoles',trace_var_name='trace_t89_5re_magpoles',/geopack_2008, /exact_tilt, /refine, external_model='t89', /km, kp=2.0, /south
;tplotxy,'trace_t89_5re_magpoles'
;stop

reduced_vars = ['tha_state_pos', 'tha_state_pos_reduced','ifoot_t89_n','tha_iono_t89_trace_n','ifoot_t89_s','tha_iono_t89_trace_s', 'eq_foot_t89', 'tha_state_pos_lshell']
reduced_vars = [reduced_vars, 'kyoto_dst','OMNI_HRO_1min_BY_GSM','Kp', 'iopt_interp','OMNI_HRO_1min_Pressure', 'OMNI_HRO_1min_BZ_GSM']
reduced_vars = [reduced_vars, 'g1', 'g2','w1','w2','w3','w4','w5','w6']
reduced_vars = [reduced_vars, 'circle_magpoles_5re_km', 'ifoot_t89_5re_magpoles', 'trace_t89_5re_magpoles']
reduced_vars = [reduced_vars, 'ifoot_t89_s_actual','ifoot_t96_s_actual','ifoot_t01_s_actual','ifoot_t04s_s_actual']
tplot_save,reduced_vars,filename='/tmp/ttrace_validate_reduced'
jumbo_vars = [reduced_vars,'tha_iono_t89_trace_n','tha_iono_t89_trace_s', 'tha_eq_t89_trace']
tplot_save,jumbo_vars, filename='/tmp/ttrace_validate_jumbo'
end