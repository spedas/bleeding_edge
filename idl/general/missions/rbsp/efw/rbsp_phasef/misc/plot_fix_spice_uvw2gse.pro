;+
; Plot spin-axis in GSE before and after correcting for spin tone.
;-


pro plot_fix_spice_uvw2gse, day, probe=probe, test=test

;---Settings.
    secofday = constant('secofday')
    time_range = day+[0,secofday]
    prefix = 'rbsp'+probe+'_'
    common_time_step = 1d/16
    common_times = make_bins(time_range, common_time_step)
    xyz = constant('xyz')
    uvw = constant('uvw')
    ndim = 3
    plot_dir = join_path([googledir(),'works','works','rbsp_phase_f','plot','test_fix_spice_uvw2gse'])


;---Load quaternion and spin phase.
    if check_if_update(prefix+'q_uvw2gse', time_range) then begin
        rbsp_read_quaternion, time_range, probe=probe
        rbsp_fix_q_uvw2gse, time_range, probe=probe
    endif

    if check_if_update(prefix+'r_gse', time_range) then begin
        rbsp_read_orbit, time_range, probe=probe
        dis = snorm(get_var_data(prefix+'r_gse',times=times))
        store_data, prefix+'dis', times, dis, limits={labels:'|R|', ytitle:'(Re)'}
    endif

    rbsp_read_eclipse_flag, time_range, probe=probe
    flag_var = prefix+'eclipse_flag'
    options, flag_var, 'yrange', [0,1]+[-1,1]*0.2
    options, flag_var, 'ytitle', '(#)'
    options, flag_var, 'ytickv', [0,1]
    options, flag_var, 'yminor', 0
    options, flag_var, 'yticks', 1
    options, flag_var, 'labels', 'Eclipse'
    

    tplot_options, 'ynozero', 1
    tplot_options, 'xticklen', -0.03
    tplot_options, 'yticklen', -0.01
    tplot_options, 'labflag', -1
    vars = prefix+'w'+xyz+'_gse'
    options, vars, 'ytitle', '(#)'
    foreach var, vars do begin
        options, var, 'labels', ['Spice','New']
        vec = get_var_data(var)
        yrange = minmax(vec)*100
        yrange = [floor(yrange[0]), ceil(yrange[1])]/100.
        yrange[0] = yrange[1]-0.03
        options, var, 'yrange', yrange
        options, var, 'yticks', 3
        options, var, 'yminor', 10
        options, var, 'ystyle', 1
    endforeach

;test = 0
    plot_file = join_path([plot_dir,prefix+time_string(time_range[0],tformat='YYYY_MMDD')+'_v03.pdf'])
    if keyword_set(test) then plot_file = 0
    sgopen, plot_file, xsize=8, ysize=8, xchsz=xchsz, ychsz=ychsz
    margins = [15,4,6,3]

    vars = prefix+['w'+xyz+'_gse','eclipse_flag','dis']
    nvar = n_elements(vars)
    poss = sgcalcpos(nvar, margins=margins, ypans=[intarr(nvar-2)+1,0.3,1])
    
    flags = get_var_data(flag_var, times=times)
    index = where(flags eq 1, count)
    if count ne 0 then begin
        the_time_step = total(times[0:1]*[-1,1])
        time_ranges = time_to_range(times[index], time_step=the_time_step, pad_time=the_time_step)
        the_color = sgcolor('silver')
        tpos = poss[*,0]
        tpos[1] = poss[1,-1]
        plot, time_range, [0,1], /nodata, /noerase, $
            xstyle=5, ystyle=5, $
            position=tpos
        foreach the_time, time_ranges[*] do begin
            if product(the_time-time_range) ge 0 then continue
            plots, the_time+[0,0], [0,1], color=the_color
        endforeach
    endif
    
    tplot, vars, trange=time_range, position=poss, /noerase
    letters = letters(nvar)
    for ii=0,ndim-1 do begin
        tpos = poss[*,ii]
        tx = xchsz*2
        ty = tpos[3]-ychsz*0.8
        xyouts, tx,ty,/normal, letters[ii]+'. GSE '+strupcase(xyz[ii])
    endfor
    
    ii = ndim+1
    tpos = poss[*,ii]
    tx = xchsz*2
    ty = tpos[3]-ychsz*0.8
    xyouts, tx,ty,/normal, letters[ii]+'. |R|'
    
    ii = ndim
    tpos = poss[*,ii]
    tx = xchsz*2
    ty = tpos[3]-ychsz*0.8
    xyouts, tx,ty,/normal, letters[ii]+'. Flag'


    tpos = poss[*,0]
    tx = tpos[0]
    ty = tpos[3]+ychsz*0.5
    xyouts, tx,ty,/normal, 'Spin-axis direction in GSE, RBSP-'+strupcase(probe)+' '+time_string(time_range[0],tformat='YYYY-MM-DD')
    if keyword_set(test) then stop
    sgclose

end


;probe = 'b'
;day = time_double('2013-01-18')
;day = time_double('2013-01-13')
;;probe = 'a'
;day = time_double('2013-07-16')
;day = time_double('2013-07-19')
;day = time_double('2013-07-20')
;day = time_double('2013-06-07')
;;day = time_double('2012-10-02')

day = time_double('2014-12-01')
probe = 'b'
plot_fix_spice_uvw2gse, day, probe=probe, test=1
stop

years = string(make_bins([2013,2015],1),format='(I04)')
months = string([3,6,9,12],format='(I02)')
days = list()
foreach year, years do foreach month, months do days.add, time_double(year+month+'01',tformat='YYYYMM01')
foreach probe, ['a','b'] do begin
    foreach day, days do begin
        plot_fix_spice_uvw2gse, day, probe=probe, test=0
    endforeach
endforeach
end
