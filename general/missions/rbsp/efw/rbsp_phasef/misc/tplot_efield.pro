;+
; Specially designed to plot E field, with 3 dyanmic ranges:
;   [-1,1]*5 mV/m to show small field.
;   [-1,1]*50 mV/m to show large field.
;   [-1,1]*500 mV/m to show very large and invalid field.
;-

pro tplot_efield, var, trange=time_range, position=pos, add_xtick=add_xtick


    if tnames(var) eq '' then message, 'Does not find input var ...'
    if n_elements(pos) ne 4 then pos = sgcalcpos(1)
    
    section_ranges = list()
    limits = [5,500]
    constants = [50]
    foreach limit, limits do section_ranges.add, [-1,1]*limit, /extract
    section_ranges = reverse(sort_uniq(section_ranges.toarray()))
    nsection = n_elements(section_ranges)-1
    poss = sgcalcpos(nsection, position=pos, ypad=0, xchsz=xchsz, ychsz=ychsz)
    

;---Get the plot settings.    
    @tplot_com.pro
    ; Set up tplot_vars.
    tplot_options,title=title,var_label=var_label,refdate=refdate, wind=wind, options = opts

    chsize = !p.charsize
    def_opts= {ymargin:[4.,2.],xmargin:[12.,12.],position:fltarr(4), $
        title:'',ytitle:'',xtitle:'', $
        xrange:dblarr(2),xstyle:1,    $
        version:3, window:-1, wshow:0,  $
        charsize:chsize,noerase:0,overplot:0,spec:0}
    extract_tags, def_opts, tplot_vars.options    
    tplot_var_labels, def_opts, time_range, var_label, local_time, pos, chsize, $
        vtitle=vtitle, vlab=vlab, time_offset=time_offset, time_scale=time_scale
    xtickformat = (keyword_set(add_xtick))? '': '(A1)'
    str_element, def_opts, 'xtickformat', xtickformat, /add_replace
    str_element, def_opts, 'position', pos, /add_replace
    str_element, def_opts, 'ytickformat', '(A1)', /add_replace
    str_element, def_opts, 'ystyle', 5, /add_replace
    
    yys = get_var_data(var, times=xxs, in=time_range, limits=lim)
    str_element, lim, 'xticklen', xticklen
    str_element, def_opts, 'xticklen', xticklen, /add_replace
    str_element, def_opts, 'yrange', minmax(section_ranges), /add_replace
    str_element, def_opts, 'noerase', 1, /add_replace


    ndim = n_elements(yys[0,*])
    str_element, lim, 'colors', colors
    if n_elements(colors) ne ndim then begin
        case ndim of
            1: colors = ['black']
            2: colors = ['blue','red']
            3: colors = ['red','green','blue']
        endcase
        colors = sgcolor(colors)
    endif
    str_element, lim, 'labels', labels
    if n_elements(labels) ne ndim then begin
        case ndim of
            1: labels = ['x']
            2: labels = ['x','y']
            3: labels = ['x','y','z']
        endcase
    endif
    xrange = time_range
    xlog = 0
    str_element, lim, 'ytitle', the_ytitle
    if n_elements(ytitle) eq 0 then the_ytitle = '(mV/m)'
    str_element, lim, 'yticklen', yticklen
    if n_elements(yticklen) eq 0 then yticklen = 0
    yticklen /= nsection
    for ii=0, nsection-1 do begin
        tpos = poss[*,ii]
        tyy = yys
        yrange = minmax(section_ranges[ii:ii+1])
        is_neg = total(yrange) lt 0 
        ylog = (product(yrange) gt 0)? 1: 0
        if ylog eq 1 then begin
            if is_neg then begin
                tyy = -yys
                yrange = -yrange
            endif
            ytickv = 10.^make_bins(alog10(yrange/min(yrange)),1,/inner)*min(yrange)
            yminor = 10
            ytitle = ''
            ytickn = string(ytickv,format='(I0)')
            if is_neg then ytickn = '-'+ytickn
        endif else begin
            ytickv = sort_uniq([0,yrange])
            yminor = 5
            ytitle = the_ytitle
            ytickn = string(ytickv,format='(I0)')
            ytickn[0] = ' '
            ytickn[-1] = ' '
        endelse
        yticks = n_elements(ytickv)-1
        
        plot, xrange, yrange, $
            xlog=xlog, xstyle=5, xrange=xrange, $
            ylog=ylog, ystyle=1, yrange=yrange, $
            ytickv=ytickv, yticks=yticks, yminor=yminor, ytitle=ytitle, $
            yticklen=yticklen, ytickname=ytickn, $
            position=tpos, /nodata, /noerase
        for jj=0,ndim-1 do oplot, xxs, tyy[*,jj], color=colors[jj]
        foreach ty, constants do oplot, xrange, ty+[0,0], linestyle=1
        foreach ty, yrange do oplot, xrange, ty+[0,0], linestyle=1
    endfor
    

;---Add overall box and labels.
    box, def_opts
    tx = pos[2]
    dy = (pos[3]-pos[1])/(ndim+1)
    tys = pos[3]-dy*findgen(ndim)-dy
    for ii=0,ndim-1 do begin
        xyouts, tx,tys[ii],/normal, '  '+labels[ii], color=colors[ii]
    endfor

end

time_range = time_double(['2016-11-01','2016-11-02'])
probe = 'a'

prefix = 'rbsp'+probe+'_'
var = prefix+'e_wake_spinfit_v12'
if check_if_update(var, time_range) then begin
    root_dir = '/Volumes/Research/data/rbsp/prelim_yearly_files/'
    years = sort_uniq(time_string(time_range,tformat='YYYY'))
    base_names = 'rbsp'+probe+'_preliminary_e_spinfit_mgse_'+years+'_v01.cdf'
    files = root_dir+base_names
    cdf2tplot, files
endif


options, var, 'colors', constant('rgb')
options, var, 'labels', 'E'+constant('xyz')
options, var, 'ytitle', '(mV/m)'
options, var, 'xticklen', -0.02
options, var, 'yticklen', -0.02

sgopen
pos = sgcalcpos(1)
tplot_efield, var, trange=time_range, position=pos, add_xtick=1
end