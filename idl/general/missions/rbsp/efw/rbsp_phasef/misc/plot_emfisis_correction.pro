;+
; Show B GSE before and after UVW2GSE is fixed.
;-

pro plot_emfisis_correction, time_range, probe=probe, plot_time=plot_time, test=test

    prefix = 'rbsp'+probe+'_'

    r_gse_var = prefix+'r_gse'
    if check_if_update(r_gse_var, time_range) then rbsp_read_orbit, time_range, probe=probe
    r_gse = get_var_data(r_gse_var, times=orbit_times)
    store_data, prefix+'dis', orbit_times, snorm(r_gse), limits={ytitle:'(Re)', labels:'|R|'}


;---Load B UVW.
    b_uvw_var = prefix+'b_uvw'
    if check_if_update(b_uvw_var, time_range) then rbsp_read_emfisis, time_range, probe=probe, id='l2%magnetometer'
    b_uvw = get_var_data(b_uvw_var, times=times)

    xyz = constant('xyz')
    ndim = n_elements(xyz)
    common_time_step = 1d/16
    common_times = make_bins(time_range, common_time_step)


;---Before fix.
    rbsp_read_emfisis, time_range, probe=probe, id='l3%magnetometer', coord='gse', resolution='hires'
    interp_time, prefix+'b_gse', common_times
    b_gse_var = prefix+'b_gse_old'
    tplot_rename, prefix+'b_gse', b_gse_var
    add_setting, b_gse_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'B', $
        'unit', 'nT', $
        'coord', 'GSE', $
        'coord_labels', xyz)


;---After fix.
    ;rbsp_fix_b_uvw, time_range, probe=probe
    pflux_grant_fix_b_uvw, time_range, probe=probe
    b_uvw = get_var_data(prefix+'b_uvw', times=times)
    b_gse = cotran(b_uvw, times, 'uvw2gse', probe=probe)
    b_gse_var = prefix+'b_gse_new'
    store_data, b_gse_var, times, b_gse
    add_setting, b_gse_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'B', $
        'unit', 'nT', $
        'coord', 'GSE', $
        'coord_labels', xyz)

;---Compare the components.
    b_gse_old = get_var_data(prefix+'b_gse_old')
    b_gse_new = get_var_data(prefix+'b_gse_new')
    two_colors = sgcolor(['blue','red'])
    two_labels = ['Old','New']
    foreach comp, xyz, ii do begin
        store_data, prefix+comp+'_gse', times, [[b_gse_old[*,ii]],[b_gse_new[*,ii]]], limits={$
            ytitle: '(nT)', $
            colors: two_colors, $
            labels: 'GSE B'+strupcase(comp)+' '+two_labels }
    endforeach


;---Plot.
    tplot_options, 'labflag', -1
    tplot_options, 'ynozero', 1
    tplot_options, 'yticklen', -0.015
    tplot_options, 'xticklen', -0.03


    plot_dir = join_path([googledir(),'works','works','rbsp_phase_f','plot','plot_emfisis_correction'])
    plot_file = join_path([plot_dir,'plot_emfisis_correction_'+prefix+strjoin(time_string(plot_time,tformat='YYYY_MMDD_hhmm_ss'),'_')+'_v01.pdf'])
    if keyword_set(test) then plot_file = 0

    sgopen, plot_file, xsize=6, ysize=8, xchsz=xchsz, ychsz=ychsz
    vars = prefix+[xyz+'_gse','dis']
    tplot, vars, trange=plot_time, get_plot_position=poss
    tpos = poss[*,0]
    tx = tpos[0]
    ty = tpos[3]+ychsz*0.5
    xyouts, tx,ty,/normal, 'RBSP-'+strupcase(probe)+'    Test to remove spin tone in EMFISIS magnetic field'
    

    if keyword_set(test) then stop
    sgclose

end

test_list = list()

test_list.add, dictionary($
    'time_range', time_double(['2014-08-28','2014-08-29']), $
    'plot_time', time_double('2014-08-28/'+['10:00','12:00']), $
    'probe', 'b' )
test_list.add, dictionary($
    'time_range', time_double(['2014-08-28','2014-08-29']), $
    'plot_time', time_double('2014-08-28/'+['10:30','10:32']), $
    'probe', 'b' )
test_list.add, dictionary($
    'time_range', time_double(['2014-08-28','2014-08-29']), $
    'plot_time', time_double('2014-08-28/'+['05:50','05:52']), $
    'probe', 'b' )

foreach test, test_list do begin
    time_range = test.time_range
    probe = test.probe
    plot_time = test.plot_time
    plot_emfisis_correction, time_range, probe=probe, plot_time=plot_time, test=0
endforeach

end
