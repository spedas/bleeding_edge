
probes = ['a','b']
sampling_rates = 2^make_bins([9,14],1)
lshell_bins = make_bins([0,8],1)
nlshell_bin = n_elements(lshell_bins)-1
mlt_bins = make_bins([-12,12],1)
nmlt_bin = n_elements(mlt_bins)-1

time_step = 60d
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'

    ; Read B1 data info.
    rbsp_efw_phasef_read_b1_time_rate, probe=probe, datatype='vb1'
    get_data, prefix+'efw_vb1_time_rate', tmp, b1_trs, b1_srs

    ; Round to 1 min.
    b1_trs[*,0] = b1_trs[*,0]-(b1_trs[*,0] mod time_step)
    b1_trs[*,1] = b1_trs[*,1]-(b1_trs[*,1] mod time_step)+time_step


    foreach sampling_rate, sampling_rates do begin
        key = string(sampling_rate,format='(I0)')
        base = prefix+key+'_dial_plot.sav'
        file = join_path([srootdir(),base])
        if file_test(file) eq 1 then continue
        counts = fltarr(nmlt_bin,nlshell_bin)


        ; Select the time ranges for the wanted sampling rate.
        index = where(sampling_rate eq b1_srs, nsec)
        if nsec ne 0 then begin
            the_mlt = []
            the_lshell = []
            the_trs = b1_trs[index,*]
            for sec_id=0,nsec-1 do begin
                the_tr = reform(the_trs[sec_id,*])
                the_times = make_bins(the_tr,time_step)
                
                rbsp_read_spice, the_tr, probe=probe, id='mlt'
                the_mlt = [the_mlt,get_var_data(prefix+'mlt',at=the_times)]
                rbsp_read_spice, the_tr, probe=probe, id='lshell'
                the_lshell = [the_lshell,get_var_data(prefix+'lshell',at=the_times)]
            endfor
            
            ; Bin the mlt and lshell.
            for ii=0,nmlt_bin-1 do begin
                for jj=0,nlshell_bin-1 do begin
                    index = where(the_mlt ge mlt_bins[ii] and the_mlt le mlt_bins[ii+1] and the_lshell ge lshell_bins[jj] and the_lshell le lshell_bins[jj+1], count)
                    counts[ii,jj] = count
                endfor
            endfor
        endif

        save, counts, filename=file
    endforeach
endforeach


;---Plot.
plot_file = join_path([srootdir(),'fig_4_1_dial_plot.pdf'])
;plot_file = 0

margins = [6,4,1,1]
;fig = panel_init(plot_file, nxpan=nxpan,nypan=nypan, pansize=[1,1]*1, margins=margins, xpad=0.5, ypad=0.5)
nxpan = 4
nypan = 2
poss = panel_pos(plot_file, nxpan=nxpan,nypan=nypan, $
    pansize=[1,1]*1.5, margins=margins, xpad=0.5, ypad=0.5, fig_size=fig_size)
    
sgopen, plot_file, xsize=fig_size[0], ysize=fig_size[1], xchsz=xchsz, ychsz=ychsz


xrange = [-1,1]*max(lshell_bins)
yrange = xrange
zrange = [0,60]
top_color = 254
ct = 49
earth_color = sgcolor('black')

fig_labels = letters(nxpan*nypan)


total_counts = fltarr(nmlt_bin,nlshell_bin)
fig_label_count = 0
foreach sampling_rate, sampling_rates, rate_id do begin
    the_counts = fltarr(nmlt_bin,nlshell_bin)
    foreach probe, probes do begin
        key = string(sampling_rate,format='(I0)')
        base = prefix+key+'_dial_plot.sav'
        file = join_path([srootdir(),base])
        restore, filename=file
        the_counts += counts/60d
    endforeach
    total_counts += the_counts

    x_id = (rate_id mod (nxpan-1))
    y_id = floor(rate_id/(nxpan-1))
    tpos = poss[*,x_id,y_id]
    plot, xrange, yrange, $
        xstyle=5, xrange=xrange, $
        ystyle=5, yrange=yrange, $
        position=tpos, nodata=1, noerase=1

    ; Draw data.
    zzs = bytscl(the_counts, min=zrange[0], max=zrange[1], top=top_color)
    for ii=0,nmlt_bin-1 do begin
        for jj=0,nlshell_bin-1 do begin
            color = sgcolor(zzs[ii,jj],ct=ct)
            tts = (mlt_bins[ii:ii+1]+6)*15*constant('rad')
            rrs = lshell_bins[jj:jj+1]
            dts = smkarthm(tts[0],tts[1],10,'n')
            xxs = [$
                rrs[[0,1]]*cos(dts[0]), $
                rrs[1]*cos(dts), $
                rrs[[1,0]]*cos(dts[-1]), $
                rrs[0]*reverse(cos(dts))]
            yys = [$
                rrs[[0,1]]*sin(dts[0]), $
                rrs[1]*sin(dts), $
                rrs[[1,0]]*sin(dts[-1]), $
                rrs[0]*reverse(sin(dts))]
            polyfill, xxs,yys,/data, color=color, /fill
        endfor
    endfor

    ; Draw earth.
    tts = smkarthm(0,2*!dpi,20,'n')
    xxs = cos(tts)
    yys = sin(tts)
    polyfill, xxs,yys,/data, color=sgcolor('white'), /fill
    polyfill, xxs,yys<0,/data, color=sgcolor('black'), /fill
    plots, xxs,yys,/data, color=earth_color

    ; Add S/s.
    tx = tpos[0]+xchsz*0.7
    ty = tpos[3]-ychsz*1
    format = (sampling_rate lt 1000)? '(F3.1)': '(I0)'
    key = string(sampling_rate*1e-3,format=format)+'k'
    fig_label = fig_labels[fig_label_count]
    fig_label_count += 1
    msg = fig_label+'. '+key
    xyouts, tx,ty,/normal, msg
    
    ; Draw box.
    xtickformat = (y_id eq 1)? '': '(A1)'
    ytickformat = (x_id eq 0)? '': '(A1)'
    xtitle = (y_id eq 1)? 'L-shell': ' '
    ytitle = (x_id eq 0)? 'L-shell': ' '
    
    plot, xrange, yrange, $
        xstyle=1, xrange=xrange, xtickformat=xtickformat, xtitle=xtitle, $
        ystyle=1, yrange=yrange, ytickformat=ytickformat, ytitle=ytitle, $
        position=tpos, nodata=1, noerase=1
endforeach

; Add colorbar.
x_id = nxpan-1
y_id = nypan-1
tpos = poss[*,x_id,y_id]
cbpos = tpos
cbpos[[1,3]] = tpos[3]+ychsz*[0.5,1]
cbpos[[0,2]] = tpos[[0,2]]+[1,-1]*xchsz*1
ztitle = 'Burst hours (approx)'
sgcolorbar, ct=ct, position=cbpos, $
    zrange=zrange, ztitle=ztitle, horizontal=1

; Draw total count.
x_id = nxpan-1
y_id = nypan-1
tpos = poss[*,x_id,y_id]
plot, xrange, yrange, $
    xstyle=5, xrange=xrange, $
    ystyle=5, yrange=yrange, $
    position=tpos, nodata=1, noerase=1
    
; Draw data.
zzs = bytscl(total_counts, min=zrange[0], max=zrange[1], top=top_color)
for ii=0,nmlt_bin-1 do begin
    for jj=0,nlshell_bin-1 do begin
        color = sgcolor(zzs[ii,jj],ct=ct)
        tts = (mlt_bins[ii:ii+1]+6)*15*constant('rad')
        rrs = lshell_bins[jj:jj+1]
        dts = smkarthm(tts[0],tts[1],10,'n')
        xxs = [$
            rrs[[0,1]]*cos(dts[0]), $
            rrs[1]*cos(dts), $
            rrs[[1,0]]*cos(dts[-1]), $
            rrs[0]*reverse(cos(dts))]
        yys = [$
            rrs[[0,1]]*sin(dts[0]), $
            rrs[1]*sin(dts), $
            rrs[[1,0]]*sin(dts[-1]), $
            rrs[0]*reverse(sin(dts))]
        polyfill, xxs,yys,/data, color=color, /fill
    endfor
endfor

; Draw earth.
tts = smkarthm(0,2*!dpi,20,'n')
xxs = cos(tts)
yys = sin(tts)
polyfill, xxs,yys,/data, color=sgcolor('white'), /fill
polyfill, xxs,yys<0,/data, color=sgcolor('black'), /fill
plots, xxs,yys,/data, color=earth_color

; Add S/s.
tx = tpos[0]+xchsz*0.7
ty = tpos[3]-ychsz*1
key = 'Total'
fig_label = fig_labels[fig_label_count]
fig_label_count += 1
msg = fig_label+'. '+key
xyouts, tx,ty,/normal, msg

; Draw box.
xtickformat = (y_id eq 1)? '': '(A1)'
ytickformat = (x_id eq 0)? '': '(A1)'
xtitle = (y_id eq 1)? 'L-shell': ' '
ytitle = (x_id eq 0)? 'L-shell': ' '

plot, xrange, yrange, $
    xstyle=1, xrange=xrange, xtickformat=xtickformat, xtitle=xtitle, $
    ystyle=1, yrange=yrange, ytickformat=ytickformat, ytitle=ytitle, $
    position=tpos, nodata=1, noerase=1


sgclose

end
