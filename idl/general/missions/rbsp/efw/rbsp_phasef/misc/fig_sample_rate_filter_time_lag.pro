;+
; Plot the sampling rate dependent time tag offset and the expected time lag due to the anti-aliasing filter
;-


;---Sampling invertals, in msec.
    sampling_periods = 1d/[16d,32,64,128,256,512,1024,2048,4096,8192,16384]
    sampling_periods = 1d3/2^make_bins([0,14],1)

;---Time lags due to the anti-aliasing filter, from documents shared by William Rachelson and David Malaspina.
    filter_time_lags = [6007.446d, 3007.446, 1507.446, 757.446, 382.446, 194.946, 101.196, 54.321, 30.884, 19.165, 13.306, 10.376, 8.911, 8.179, 7.813]

;---Offsets in time tag I found: equal to the sampling interval.
    time_tag_offsets = sampling_periods

    plot_file = 0
    margins = [10,4,2,2]
    poss = panel_pos(plot_file, nxpan=2, nypan=1, pansize=[1,1]*2.5, margins=margins, xpad=10, $
        fig_size=fig_size)
    sgopen, plot_file, xsize=fig_size[0], ysize=fig_size[1], xchsz=xchsz, ychsz=ychsz

    tpos = poss[*,0]
    xtitle = 'Sampling period (msec)'
    ytitle = 'Time lag (msec)'
    xrange = [0.01,1e4]
    yrange = [0.01,1e4]
    xtickv = 10^make_bins(alog10(xrange),1)
    ytickv = xtickv
    xtickn = string(xtickv,format='(I0)')
    xtickn[0] = '0.01'
    xtickn[1] = '0.1'
    ytickn = xtickn
    xticklen = -0.02
    yticklen = -0.02
    symsize = 0.8
    
    plot, sampling_periods, filter_time_lags, $
        psym=-1, symsize=symsize, position=tpos, $
        ylog=1, ytitle=ytitle, xrange=xrange, xtickname=xtickn, xticklen=xticklen, $
        xlog=1, xtitle=xtitle, yrange=yrange, ytickname=ytickn, yticklen=yticklen, $
        noerase=1, /iso

    color1 = sgcolor('black')
    oplot, sampling_periods, filter_time_lags, psym=-1, color=color1, symsize=symsize
    oplot, xrange, xrange*max(filter_time_lags)/max(sampling_periods), linestyle=1

    color2 = sgcolor('red')
    oplot, sampling_periods, time_tag_offsets, psym=-6, color=color2, symsize=symsize
    oplot, xrange, xrange*max(time_tag_offsets)/max(sampling_periods), linestyle=1

    alignment=0
    tx = tpos[0]+xchsz*1
    ty = tpos[3]-ychsz*1
    msg = 'Anti-aliasing filter'
    xyouts, tx,ty,/normal,alignment=alignment, msg

    tx = tpos[0]+xchsz*1
    ty = tpos[3]-ychsz*2
    msg = 'Time tag offset'
    xyouts, tx,ty,/normal,alignment=alignment, msg, color=color2
    
    tx = tpos[0]-xchsz*7
    ty = tpos[3]-ychsz*0.7
    xyouts, tx,ty,/normal, 'a.'
    
   
   
;---Linear scale.
    tpos = poss[*,1]
    xtitle = 'Sampling period (msec)'
    ytitle = 'Time lag (msec)'
    xrange = [0,1.2e3]
    yrange = [0,6.2e3]
    xticklen = -0.02
    yticklen = -0.02
    symsize = 0.8

    plot, xrange, yrange, $
        xtitle=xtitle, xrange=xrange, xticklen=xticklen, $
        ytitle=ytitle, yrange=yrange, yticklen=yticklen, $
        noerase=1, nodata=1, position=tpos

    color1 = sgcolor('black')
    oplot, sampling_periods, filter_time_lags, psym=-1, color=color1, symsize=symsize
    oplot, xrange, xrange*max(filter_time_lags)/max(sampling_periods), linestyle=1

    color2 = sgcolor('red')
    oplot, sampling_periods, time_tag_offsets, psym=-6, color=color2, symsize=symsize
    oplot, xrange, xrange*max(time_tag_offsets)/max(sampling_periods), linestyle=1

    alignment=0
    tx = tpos[0]+xchsz*1
    ty = tpos[3]-ychsz*1
    msg = 'Anti-aliasing filter'
    xyouts, tx,ty,/normal,alignment=alignment, msg

    tx = tpos[0]+xchsz*1
    ty = tpos[3]-ychsz*2
    msg = 'Time tag offset'
    xyouts, tx,ty,/normal,alignment=alignment, msg, color=color2
    
    tx = tpos[0]-xchsz*7
    ty = tpos[3]-ychsz*0.7
    xyouts, tx,ty,/normal, 'b.'

end
