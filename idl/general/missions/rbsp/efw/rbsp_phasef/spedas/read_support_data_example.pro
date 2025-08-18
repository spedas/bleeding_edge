; Set the time and probe for loading data.
;time_range = ['2018-10-08/02:00','2018-10-08/03:30']
time_range = ['2013-03-17/09:55','2013-03-17/10:05']
probe = 'b'

; Other settings.
uvw = ['u','v','w']
xyz = ['x','y','z']
rgb = [6,4,2]
tplot_options, 'labflag', -1
prefix = 'rbsp'+probe+'_efw_'

; Rotate E field from mGSE to GSE.
rbsp_efw_read_l3, time_range, probe=probe
e_mgse_var = prefix+'efield_in_corotation_frame_spinfit_mgse'
get_data, e_mgse_var, times, e_mgse
store_data, e_mgse_var, limits={ytitle:'[mV/m]', labels:'mGSE E'+xyz, colors:rgb}
; Require to set probe when the rotation involves mgse and uvw.
e_gse = cotran(e_mgse, times, 'mgse2gse', probe=probe)
store_data, prefix+'e_gse', times, e_gse, limits={ytitle:'[mV/m]', labels:'GSE E'+xyz, colors:rgb}

; Rotate E field from UVW to GSE.
rbsp_efw_read_l2, time_range, probe=probe, datatype='e-hires-uvw'
e_uvw_var = prefix+'e_hires_uvw'
get_data, e_uvw_var, times, e_uvw
e_uvw[*,2] = 0
store_data, e_uvw_var, limits={labels: 'E'+uvw, colors:rgb}
; Require to set probe when the rotation involves mgse and uvw.
e_gse = cotran(e_uvw, times, 'uvw2gse', probe=probe)
store_data, prefix+'e_gse2', times, e_gse, limits={ytitle:'[mV/m]', labels:'GSE E'+xyz, colors:rgb}


; Plot data.
options, prefix+'bias_current', 'labels', string(findgen(6)+1,format='(I0)')

vars = prefix+[$

    ; The bias current.
    'bias_current', $

    ; E fields in various coords.
    'efield_in_corotation_frame_spinfit_mgse', $
    'e_hires_uvw', 'e_gse', 'e_gse2' ]

; Plot the variables.
tplot, vars, trange=time_range
end
