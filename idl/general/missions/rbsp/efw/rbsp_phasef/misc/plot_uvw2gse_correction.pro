;+
; Show R MGSE before and after UVW2GSE is fixed.
;-

pro plot_uvw2gse_correction, time_range, probe=probe, plot_time=plot_time

    prefix = 'rbsp'+probe+'_'
    r_gse_var = prefix+'r_gse'
    if check_if_update(r_gse_var, time_range) then rbsp_read_orbit, time_range, probe=probe
    r_gse = get_var_data(r_gse_var, times=times)

    xyz = constant('xyz')
    ndim = n_elements(xyz)

    store_data, prefix+'dis', times, snorm(r_gse), limits={ytitle:'(Re)', labels:'|R|'}


;---Before fix.
    rbsp_read_quaternion, time_range, probe=probe
    r_mgse = cotran(r_gse, times, 'gse2mgse', probe=probe)
    r_mgse_var = prefix+'r_mgse_old'
    store_data, r_mgse_var, times, r_mgse
    add_setting, r_mgse_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'R', $
        'unit', 'Re', $
        'coord', 'MGSE', $
        'coord_labels', xyz)


;---After fix.
    rbsp_read_quaternion, time_range, probe=probe
    rbsp_fix_q_uvw2gse, time_range, probe=probe
    r_mgse = cotran(r_gse, times, 'gse2mgse', probe=probe)
    r_mgse_var = prefix+'r_mgse_new'
    store_data, r_mgse_var, times, r_mgse
    add_setting, r_mgse_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'R', $
        'unit', 'Re', $
        'coord', 'MGSE', $
        'coord_labels', xyz)

;---Compare the components.
    r_mgse_old = get_var_data(prefix+'r_mgse_old')
    r_mgse_new = get_var_data(prefix+'r_mgse_new')
    two_colors = sgcolor(['blue','red'])
    two_labels = ['Old','New']
    foreach comp, xyz, ii do begin
        store_data, prefix+comp+'_mgse', times, [[r_mgse_old[*,ii]],[r_mgse_new[*,ii]]], limits={$
            ytitle: '(Re)', $
            colors: two_colors, $
            labels: 'MGSE '+strupcase(comp)+' '+two_labels }
    endforeach


;---Plot.
    tplot_options, 'labflag', -1
    tplot_options, 'ynozero', 1

    plot_dir = join_path([googledir(),'works','works','rbsp_phase_f','plot','plot_uvw2gse_correction'])
    plot_file = join_path([plot_dir,'plot_uvw2gse_correction_'+prefix+strjoin(time_string(plot_time,tformat='YYYY_MMDD_hhmm_ss'),'_')+'_v01.pdf'])
    if keyword_set(test) then plot_file = 0

    sgopen, plot_file, xsize=6, ysize=8
    vars = prefix+[xyz+'_mgse','dis']
    tplot, vars, trange=plot_time

    if keyword_set(test) then stop
    sgclose

end

test_list = list()

test_list.add, dictionary($
    'time_range', time_double(['2013-07-21','2013-07-22']), $
    'plot_time', time_double('2013-07-21/'+['12:24','12:25']), $
    'probe', 'a' )
test_list.add, dictionary($
    'time_range', time_double(['2013-07-21','2013-07-22']), $
    'plot_time', time_double('2013-07-21/'+['06:20','07:00']), $
    'probe', 'a' )

foreach test, test_list do begin
    time_range = test.time_range
    probe = test.probe
    plot_time = test.plot_time
    plot_uvw2gse_correction, time_range, probe=probe, plot_time=plot_time
endforeach

end
