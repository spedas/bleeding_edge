;+
; Plot Ey and Ez in MGSE.
; Compare E_measure-E_coro and E_vxb
;-

pro perigee_correction_plot1, time_range, probe=probe, plot_file=plot_file, test=test

    if n_elements(plot_file) eq 0 then plot_file = 0
    if keyword_set(test) then plot_file = test
    if n_elements(time_range) ne 2 then stop

;---Load data.
    prefix = 'rbsp'+probe+'_'
    evxb = get_var_data(prefix+'evxb_mgse', in=time_range, times=times)
    e0 = get_var_data(prefix+'e_mgse', in=time_range)
    ecoro = get_var_data(prefix+'ecoro_mgse', in=time_range)
    e1 = e0-ecoro
    de = e1-evxb
    r_gsm = get_var_data(prefix+'r_gsm', at=time_range[0])
    perigee_shell = round(snorm(r_gsm))


;---Figure size.
    sgopen, 0, xsize=1,ysize=1, xchsz=abs_xchsz, ychsz=abs_ychsz
    sgclose, /wdelete
    panel_ysize = 2    ; inch.
    panel_xsize = panel_ysize
    xpans = [2.5,1]
    nxpan = n_elements(xpans)
    xpads = [10.]
    ypans = [0.5,1,0.5,1]
    nypan = n_elements(ypans)
    ypads = [0.5,5,0.5]
    margins = [10.,5,5,2]
    fig_xsize = total(xpans)*panel_xsize+$
        total(xpads)*abs_xchsz+total(margins[[0,2]])*abs_xchsz
    fig_ysize = total(ypans)*panel_ysize+$
        total(ypads)*abs_ychsz+total(margins[[1,3]])*abs_ychsz
    sgopen, plot_file, xsize=fig_xsize, ysize=fig_ysize, /inch, xchsz=xchsz, ychsz=ychsz
    poss = sgcalcpos(nypan, nxpan, ypans=ypans, xpans=xpans, $
        xpad=xpads, ypad=ypads, margins=margins)


;---Other settings.
    xticklen_chsz = -0.2
    yticklen_chsz = xticklen_chsz*ychsz/xchsz
    e0_range = minmax(make_bins(minmax([e1,evxb]),50))
    e1_range = [-1,1]*15

    ; Common x-axis.
    txs = times
    xstep = 30*60.
    xminor = 6
    xtickv = make_bins(txs,xstep,/inner)
    xticks = n_elements(xtickv)-1
    xtickn = time_string(xtickv,tformat='hh:mm')
    xrange = minmax(txs)


;---Time series of dEy.
    tpos = poss[*,0,0]
    ytitle = '(mV/m)'
    yrange = e1_range
    xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
    yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])
    plot, txs, de[*,1], position=tpos, $
        xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xminor=xminor, xtickname=xtickn, xticklen=xticklen, xtickformat='(A1)', $
        ystyle=1, yrange=yrange, ytitle=ytitle, yticklen=yticklen, yticks=2, yminor=3, $
        /noerase
    foreach val, make_bins(yrange,5,/inner) do plots, xrange, val+[0,0], linestyle=1
    plots, mean(xrange)+[0,0], yrange, linestyle=1
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1.2
    xyouts, tx,ty,/normal, 'MGSE Ey'

    tx = tpos[0]
    ty = tpos[3]+ychsz*0.5
    xyouts, tx,ty,/normal, 'RBSP-'+strupcase(probe)+$
        ' perigee (L<'+string(perigee_shell,format='(I0)')+'): '+$
        strjoin(time_string(time_range,tformat='YYYY-MM-DD/hh:mm'),' to ')


;---Time series of Ey.
    tpos = poss[*,0,1]
    ytitle = '(mV/m)'
    xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
    yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])
    yrange = e0_range
    plot, txs, e1[*,1], position=tpos, $
        xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xminor=xminor, xtickname=xtickn, xticklen=xticklen, $
        ystyle=1, yrange=yrange, ytitle=ytitle, yticklen=yticklen, $
        /noerase
    oplot, txs, evxb[*,1], color=sgcolor('red')
    plots, xrange, [0,0], linestyle=1
    plots, mean(xrange)+[0,0], yrange, linestyle=1
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1.2
    xyouts, tx,ty,/normal, 'MGSE Ey'

    ty = tpos[1]+ychsz*0.5
    xyouts, tx,ty,/normal, 'E_measure-E_coro'
    ty = tpos[1]+ychsz*1.5
    xyouts, tx,ty,/normal, 'E_vxb', color=sgcolor('red')


;---Time series of dEz.
    tpos = poss[*,0,2]
    ytitle = '(mV/m)'
    xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
    yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])
    yrange = e1_range
    plot, txs, de[*,2], position=tpos, $
        xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xminor=xminor, xtickname=xtickn, xticklen=xticklen, xtickformat='(A1)', $
        ystyle=1, yrange=yrange, ytitle=ytitle, yticklen=yticklen, yticks=2, yminor=3, $
        /noerase
    foreach val, make_bins(yrange,5,/inner) do plots, xrange, val+[0,0], linestyle=1
    plots, mean(xrange)+[0,0], yrange, linestyle=1
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1.2
    xyouts, tx,ty,/normal, 'MGSE Ez'


;---Time series of Ez.
    tpos = poss[*,0,3]
    ytitle = '(mV/m)'
    xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
    yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])
    yrange = e0_range
    plot, txs, e1[*,2], position=tpos, $
        xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xminor=xminor, xtickname=xtickn, xticklen=xticklen, $
        ystyle=1, yrange=yrange, ytitle=ytitle, yticklen=yticklen, $
        /noerase
    oplot, txs, evxb[*,2], color=sgcolor('red')
    plots, xrange, [0,0], linestyle=1
    plots, mean(xrange)+[0,0], yrange, linestyle=1
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1.2
    xyouts, tx,ty,/normal, 'MGSE Ez'

    ty = tpos[1]+ychsz*0.5
    xyouts, tx,ty,/normal, 'E_measure-E_coro'
    ty = tpos[1]+ychsz*1.5
    xyouts, tx,ty,/normal, 'E_vxb', color=sgcolor('red')



;---Ey comparisons.
    tpos = poss[*,1,1]
    xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
    yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])
    xtitle = 'E_measure-E_coro (mV/m)'
    ytitle = 'E_vxb (mV/m)'
    plot, e1[*,1], evxb[*,1], psym=3, /iso, position=tpos, $
        xstyle=1, xrange=e0_range, xtitle=xtitle, xticklen=xticklen, $
        ystyle=1, yrange=e0_range, ytitle=ytitle, yticklen=yticklen, $
        /noerase
    oplot, e0_range, e0_range, linestyle=1
    oplot, e0_range, [0,0], linestyle=1
    oplot, [0,0], e0_range, linestyle=1
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1.2
    xyouts, tx,ty,/normal, 'MGSE Ey'


;---Ez comparisons.
    tpos = poss[*,1,3]
    xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
    yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])
    xtitle = 'E_measure-E_coro (mV/m)'
    ytitle = 'E_vxb (mV/m)'
    plot, e1[*,2], evxb[*,2], psym=3, /iso, position=tpos, $
        xstyle=1, xrange=e0_range, xtitle=xtitle, xticklen=xticklen, $
        ystyle=1, yrange=e0_range, ytitle=ytitle, yticklen=yticklen, $
        /noerase
    oplot, e0_range, e0_range, linestyle=1
    oplot, e0_range, [0,0], linestyle=1
    oplot, [0,0], e0_range, linestyle=1
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1.2
    xyouts, tx,ty,/normal, 'MGSE Ez'

    if keyword_set(test) then stop
    sgclose

end

probe = 'a'
time_range = time_double(['2013-03-01/06:29','2013-03-01/09:46'])
perigee_correction_plot1, time_range, probe=probe;, plot_file=plot_file
end
