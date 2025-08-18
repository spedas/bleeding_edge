pro box,limits,x,y,data=d

  compile_opt idl2 ;forces array indexing with brackets.  integer constants without type labels default to 32 bit int
  ;note that array indexing with brackets should be considered mandatory for all future code,
  ;as IDL 8+ implements parenthetical array indexes very very inefficiently



  str_element,limits,'overplot',value=overplot

  if keyword_set(overplot) then return

  xlog=0
  ylog=0
  xr = !x.range
  yr = !y.range
  xmargin = !x.margin
  ymargin = !y.margin

  str_element,limits,'xlog',value=xlog
  str_element,limits,'ylog',value=ylog
  str_element,limits,'xrange',value=xr
  str_element,limits,'yrange',value=yr
  str_element,limits,'xmargin',xmargin
  str_element,limits,'ymargin',ymargin
  str_element,limits,'asp_ratio',value=asp_ratio
  str_element,limits,'aspect',value=aspect
  str_element,limits,'top',value=top
  str_element,limits,'metric',value=metric
  str_element,limits,'noerase',value=noerase

  if (n_elements(x) ne 0) and (xr[0] eq xr[1]) then xr = minmax(x,pos=xlog)
  if (n_elements(y) ne 0) and (yr[0] eq yr[1]) then yr = minmax(y,pos=ylog)

  extract_tags,plotstuff,limits,/plot

  region = !p.region
  str_element,limits,'region',region

  pos = !p.position
  str_element,limits,'position',pos

  if region[0] eq region[2] then region=[0.,0.,1.,1.]


  if  (pos[0] eq pos[2]) then begin
    ; printdat,region
    ; printdat,limits
    if !p.multi[1] ne 0 then begin
      xsize=replicate(1,!p.multi[1])
      xgap = total(xmargin)
    endif
    if !p.multi[2] ne 0 then begin
      ysize=replicate(1,!p.multi[2])
      ygap = total(ymargin)
    endif
    p = !p.multi[0]
    np = !p.multi[1]*!p.multi[2] > 1
    if !p.multi[0] ne 0 then str_element,/add,plotstuff,'noerase',1
    pos = plot_positions(option=plotstuff,region=region, $
      xsize=xsize,ysize=ysize,xgap=xgap,ygap=ygap)
    if !p.multi[4] ne 0 then begin
      pos=reform(pos,4,!p.multi[1],!p.multi[2])
      pos= transpose(pos,[0,2,1])
      pos=reform(pos,4,!p.multi[2]*!p.multi[1])
    endif
    str_element,/add,plotstuff,'position',pos[*,(np-p) mod np]
    if !p.multi[0] ne 0 then !p.multi[0] = !p.multi[0] -1
    ; if keyword_set(noerase) then !p.multi[0] = !p.multi[0] +1
    ; printdat,plotstuff
  endif

  if keyword_set(aspect) then begin
    dx = abs(xr[1]-xr[0])
    dy = abs(yr[1]-yr[0])
    if dx ne 0 and dy ne 0 then  asp_ratio = dy/dx else asp_ratio = 1.
    p_size = [!d.x_size,!d.y_size]
    tpos = pos * [p_size,p_size]
    dtpos = [tpos[2]-tpos[0],tpos[3]-tpos[1]]
    dtpos2 = [1.,asp_ratio] * (dtpos[0] < dtpos[1]/asp_ratio)
    dts = dtpos-dtpos2
    if keyword_set(top) then r =1. else r = .5
    ds = [r*dts,(r-1)*dts]
    tpos2 = tpos + ds
    pos = tpos2 / [p_size,p_size]
    str_element,/add,plotstuff,'position',pos
  endif


  ;if keyword_set(aspect) or keyword_set(asp_ratio) then begin
  ;   charsize = !p.charsize
  ;   str_element,plotstuff,'charsize',value=charsize
  ;   if charsize le 0 then charsize=1.
  ;   str_element,lim,'xmargin',value=xmargin
  ;   str_element,lim,'ymargin',value=ymargin
  ;   if not keyword_set(xmargin) then xmargin = !x.margin
  ;   if not keyword_set(ymargin) then ymargin = !y.margin
  ;   if not keyword_set(asp_ratio) then begin
  ;      dx = abs(xr(1)-xr(0))
  ;      dy = abs(yr(1)-yr(0))
  ;      if dx ne 0 and dy ne 0 then  asp_ratio = dy/dx else asp_ratio = 1.
  ;   endif
  ;   xm = !x.margin * !d.x_ch_size * charsize
  ;   ym = !y.margin * !d.y_ch_size * charsize
  ;   p_size = [!d.x_size,!d.y_size]
  ;   m0 = [xm(0),ym(0)]
  ;   m1 = [xm(1),ym(1)]
  ;   bs = p_size-(m0+m1)
  ;   s = [1.,asp_ratio] * (bs(0) < bs(1)/asp_ratio)
  ;   bsp = m0 + (bs-s)/2
  ;   if keyword_set(top) then bsp(1) = m0(1) - s(1) + bs(1)
  ;   pos = [bsp,bsp+s] / [p_size,p_size]
  ;   str_element,/add,plotstuff,'position',pos
  ;   str_element,/add,plotstuff,'normal',1
  ;endif


  if keyword_set(metric) then begin
    dprint,'obsolete keyword'
    pos = plotstuff.position
    arat = (pos[3]-pos[1])/(pos[2]-pos[0])*!d.y_size/!d.x_size
    dxr = abs(xr[1]-xr[0]) * 1.1
    mxr = (xr[1]+xr[0])/2
    dyr = abs(yr[1]-yr[0]) * 1.1
    myr = (yr[1]+yr[0])/2
    if arat gt dyr/dxr then dyr = dxr*arat else dxr = dyr/arat
    xr = mxr + dxr * [-.5,.5]
    yr = myr + dyr * [-.5,.5]
    xlim,plotstuff,xr[0],xr[1]
    ylim,plotstuff,yr[0],yr[1]
  endif


  ;printdat,!p.multi
  if isa(limits,'dictionary') then begin
    limits.pos = position
    plot,xr,yr,/nodata,_extra = limits.tostruct()
  endif else begin
    plot,xr,yr,/nodata,_extra=plotstuff
  endelse
  ;printdat,!p.multi

end
