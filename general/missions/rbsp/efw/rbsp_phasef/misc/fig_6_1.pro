;+
; Generate Fig 6.1 for Aaron for the instrument paper.
;-

test = 1

;---Settings.
    time_range = time_double(['2012-11-14/00:00','2012-11-14/18:00'])
    probe = 'b'

    prefix = 'rbsp'+probe+'_'

;---Load data.
    dst_var = 'dst'
    ae_var = 'ae'
    if check_if_update(dst_var, time_range) then begin
        omni_read_index, time_range
    endif
    ytitle = 'Dst [nT]'
    yrange = [-120,-20]
    ystep = 50
    yminor = 5
    ytickv = make_bins(yrange, ystep, /inner)
    yticks = n_elements(ytickv)-1
    options, dst_var, 'ytitle', ytitle
    options, dst_var, 'ystyle', 1
    options, dst_var, 'yrange', yrange
    options, dst_var, 'ytickv', ytickv
    options, dst_var, 'yticks', yticks
    options, dst_var, 'yminor', yminor

    ytitle = 'AE [nT]'
    yrange = [0,1500]
    ystep = 1000
    yminor = 5
    ytickv = make_bins(yrange, ystep, /inner)
    yticks = n_elements(ytickv)-1
    options, ae_var, 'ytitle', ytitle
    options, ae_var, 'ystyle', 1
    options, ae_var, 'yrange', yrange
    options, ae_var, 'ytickv', ytickv
    options, ae_var, 'yticks', yticks
    options, ae_var, 'yminor', yminor


    vsc_var = prefix+'v12'
    if check_if_update(vsc_var) then begin
        timespan, time_range[0], total(time_range*[-1,1]), /seconds
        rbsp_load_efw_waveform, probe=probe, datatype='vsvy', coord='uvw', noclean=1
        l1_efw_var = 'rbsp'+probe+'_efw_vsvy'
        get_data, l1_efw_var, times, vsvy
        store_data, vsc_var, times, total(vsvy[*,[0,1]],2)*0.5
    endif
    ytitle = 'EFW Vsc_12!C[V]'
    yrange = [-200,200]
    ystep = 100
    yminor = 5
    ytickv = make_bins(yrange, ystep, /inner)
    yticks = n_elements(ytickv)-1
    options, vsc_var, 'ytitle', ytitle
    options, vsc_var, 'ystyle', 1
    options, vsc_var, 'yrange', yrange
    options, vsc_var, 'ytickv', ytickv
    options, vsc_var, 'yticks', yticks
    options, vsc_var, 'yminor', yminor
    options, vsc_var, 'labels', 'Vsc'

    hope_var = prefix+'p_en_spec'
    if check_if_update(hope_var, time_range) then begin
        rbsp_read_en_spec, time_range, probe=probe
    endif
    ytitle = 'HOPE Proton!CEnergy [eV]'
    options, hope_var, 'ytitle', ytitle
    options, hope_var, 'zrange', [1e4,1e7]
    options, hope_var, 'ztitle', '[1/s-cm!U-2!N-sr-keV]'
    options, hope_var, 'zcharsize', 0.9
    options, hope_var, 'yrange', [30,1000]



    mlt_var = prefix+'state_mlt'
    lshell_var = prefix+'state_lshell'
    if check_if_update(mlt_var, time_range) then begin
        timespan, time_range[0], total(time_range*[-1,1]), /seconds
    	rbsp_read_spice_var, time_range, probe=probe
    endif

    ytitle = 'MLT [hr]'
    label = 'MLT'
    yrange = [0,24]
    ystep = 12
    yminor = 3
    ytickv = make_bins(yrange, ystep, /inner)
    yticks = n_elements(ytickv)-1
    options, mlt_var, 'ystyle', 1
    options, mlt_var, 'yrange', yrange
    options, mlt_var, 'ytickv', ytickv
    options, mlt_var, 'yticks', yticks
    options, mlt_var, 'yminor', yminor
    options, mlt_var, 'ytitle', ' '
    options, mlt_var, 'labels', label
    options, mlt_var, 'ysubtitle', ytitle
    options, mlt_var, 'constant', 12


    ytitle = 'L shell'
    label = 'L shell'
    yrange = [0,6]
    ystep = 3
    yminor = 3
    ytickv = make_bins(yrange, ystep, /inner)
    yticks = n_elements(ytickv)-1
    options, lshell_var, 'ystyle', 1
    options, lshell_var, 'yrange', yrange
    options, lshell_var, 'ytickv', ytickv
    options, lshell_var, 'yticks', yticks
    options, lshell_var, 'yminor', yminor
    options, lshell_var, 'ytitle', ' '
    options, lshell_var, 'labels', label
    options, lshell_var, 'ysubtitle', ytitle


;---Plot.
    plot_vars = [dst_var,ae_var, vsc_var, hope_var, mlt_var,lshell_var]
    nvar = n_elements(plot_vars)
    ypans = fltarr(nvar)+1
    ypans[where(plot_vars eq vsc_var)] = 2
    ypans[where(plot_vars eq hope_var)] = 2

    plot_file = join_path([homedir(),'aaron_fig_6_1.pdf'])
    if keyword_set(test) then plot_file = 0
    margins = [10,4,8,2]
    ;poss = fig_init_simple(plot_file, ypans=ypans, size=fig_size, xsize=6, ysize=6, margins=margins)
    poss = panel_pos(plot_file, 'resize', xsize=6, ysize=6, $
        ypans=ypans, fig_size=fig_size, margins=margins)

    xticklen_chsz = -0.15
    yticklen_chsz = -0.30
    for pan_id=0,nvar-1 do begin
        tpos = poss[*,pan_id]
        xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
        yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])
        options, plot_vars[pan_id], 'xticklen', xticklen
        options, plot_vars[pan_id], 'yticklen', yticklen
    endfor

    title = 'Van Allen Probe '+strupcase(probe)+' charging event'
    sgopen, plot_file, xsize=fig_size[0], ysize=fig_size[1], xchsz=xchsz, ychsz=ychsz

    tplot, plot_vars, trange=time_range, position=poss, title=title

    fig_labels = letters(nvar)+'.'
    for pan_id=0,nvar-1 do begin
        tpos = poss[*,pan_id]
        tx = xchsz*2.5
        ty = tpos[3]-ychsz*0.9
        xyouts, tx,ty,/normal, fig_labels[pan_id]
    endfor

    if keyword_set(test) then stop
    sgclose


end
