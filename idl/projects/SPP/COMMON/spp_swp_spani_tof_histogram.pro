

pro spp_swp_spani_tof_histogram,trange=trange,xrange=xrange,ylog=ylog,binsize=binsize,noerase=noerase,channels=channels,xlog=xlog,yrange=yrange

  if ~keyword_set(trange) then ctime,trange,npoints=2
  csize = 2
  ;spp_apid_data,'3B9'x,apdata=ap
  ;print_struct,ap
  ap = spp_apdat('3B9'x)
  events = ap.data.array
  if not keyword_set(trange) then ctime,trange

  if keyword_set(trange) then begin
    w = where(events.time ge trange[0] and events.time le trange[1],nw)
    if nw ne 0 then events = events[w] else dprint,'No points selected - using all'
  endif

  col = bytescale(indgen(16))
  nc = n_elements(col)
  ;if ~keyword_set(xrange) then xrange=[450,600]
  if ~keyword_set(binsize) then binsize = 1
  h = histbins(events.tof,xb,binsize=binsize,shift=0,/extend_range)

  if keyword_set(ylog) then begin
    mx = max(h)
    yrange = [mx/10^(ylog+3),mx]
    yrange  = [.5,mx*2]
  endif

  if keyword_set(xlog) then begin
    xrange = minmax(/pos,xb) > 10
  endif


  plot,/nodata,xb,h * 1.1,xrange=xrange,$
    charsize=csize,$
    yrange=yrange,$
    ylog=ylog,$
    ystyle=3,$
    noerase=noerase,$
    xtitle='Time of Flight channel',$
    ytitle='Counts',xlog=xlog
  mxt = max(h)
  if ~keyword_set(channels) then channels = reverse(indgen(16))
  for i=0,n_elements(channels)-1 do begin
    ch = channels[i]
    c=col[ch mod nc]
    w = where(events.channel eq ch, nw)
    if nw eq 0 then continue
    h = histbins(events[w].tof,xb,binsize=binsize,shift=0)
    oplot,xb,h,color=c,psym=10
    oplot,xb,h,color=c,psym=1
    mx = max(h,b)
    xyouts,xb[b],h[b]+mxt*.03,strtrim(ch,2),color=c,align=.5,charsize=2
    if keyword_set(dt)  then begin
      ;dt = findgen(44)+7
      ;pks = find_peaks(
      ;[replicate(0,round(xb[0])),h],roiw=5)
      plot,dt,pks.x0,/psym,yrange=[-100,500],xrange=[0,55],/ystyle,/xstyle,xtitle='Delay (ns)',ytitle='TOF value',title='Fit to response'
      par = polycurve()
      fit,dt[1:*],pks[1:*].x0,param=par,names='a0 a1'
      oplot,dt,(pks.x0-func(dt,param=pc)) * 10,psym=4,color=6
      oplot,xv,func(xv,param=pc)
      xv=dgen()
      oplot,xv,func(xv,param=pc)
      oplot,[0,60],[0,0],color=5,linestyle=2
      oplot,[0,60],[0,0],color=2,linestyle=2
    endif
  endfor


end


