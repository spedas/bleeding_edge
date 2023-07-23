;+
; Draw an example of SDT.
;-

    probe = 'a'
    mission_time_range = rbsp_efw_phasef_get_valid_range('vsvy_hires', probe=probe)
    timespan, mission_time_range[0], total(mission_time_range*[-1,1]), /seconds
    
    sdt = rbsp_load_sdt_times(probe)
    dt = sdt.sdtend-sdt.sdtstart
    prefix = 'rbsp'+probe+'_'
    store_data, prefix+'sdt_duration', sdt.sdtstart, dt/3600, limits={$
        ytitle: 'Duration!C(hr)', labels: 'RBSP-'+strupcase(probe)+'!C  SDT dT'}
    tplot, prefix+'sdt_duration', trange=mission_time_range
    
    tmp = max(dt, index)
    sdt_time_range = [sdt.sdtstart[index],sdt.sdtend[index]]
    the_time_range = sdt_time_range+[-1,1]*1800
    the_time_range = time_double(['2018-10-08/02:10','2018-10-08/03:30'])
    phasef_read_efw_hsk, the_time_range, probe=probe
    
    
    vars = prefix+['ibias','usher','guard']
    foreach var, vars do begin
        get_data, var, times, data
        store_data, var+'1', times, data[*,0]
    endforeach
    store_data, prefix+'ibias1', limits={$
        ytitle: '(nA)', labels: 'ibias', yticks:3}
    store_data, prefix+'usher1', limits={$
        ytitle: '(V)', labels: 'usher', yrange:[-20,5], yticks:3}
    store_data, prefix+'guard1', limits={$
        ytitle: '(V)', labels: 'guard', yrange:[-20,5], yticks:3}

    tplot_options, 'labflag', 1
    tplot_options, 'xticklen', -0.04
    tplot_options, 'yticklen', -0.01
    ofn = join_path([srootdir(),'final_paper_sdt_plot.pdf'])
;ofn = 0
    sgopen, ofn, xsize=5, ysize=3
    margins = [10,4,5,1]
    nvar = n_elements(vars)
    tpos = sgcalcpos(nvar, margins=margins, xchsz=xchsz, ychsz=ychsz)
    tplot, vars+'1', trange=the_time_range, position=tpos
    
    figlabs = letters(nvar)+'.'
    for ii=0,nvar-1 do begin
        tx = tpos[0,ii]-xchsz*8
        ty = tpos[3,ii]-ychsz*0.8
        xyouts, tx,ty,/normal, figlabs[ii]
    endfor
    sgclose
end