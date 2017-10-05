
pro spp_swp_spani_thresh_analysis,anode,trangefull=trangefull,data=data,plotname=plotname

  channel = anode and 'f'x
  stp  = (anode and '10'x) ne 0
  if not keyword_set(trangefull) then ctime,trangefull

  timebar,trangefull

  spp_apid_data,'3bb'x,apdata=rates
  rates = rates.data_array.array
  w = where((rates.time ge trangefull[0]) and (rates.time le trangefull[1]) )
  rates_w = rates[w]

  thresh = data_cut('spp_spani_hkp_MRAM_ADDR_LOW',rates_w.time)
  anodes = data_cut('spp_spani_hkp_MRAM_ADDR_HI',rates_w.time)
  mcpv = tsample('spp_spani_hkp_MON_MCP_V',minmax(rates_w.time),/aver)
  stops = rates_w.stops_cnts[channel]
  starts =   rates_w.starts_cnts[channel]
  if stp then begin
    cnts = stops
    other = starts
  endif  else begin
    cnts = starts
    other = stops
  endelse

  good = 1
  good = good and (anode eq anodes)
  good = good and (thresh lt 50) and (thresh gt 5)
  good = good and (thresh eq shift(thresh,1)) and (thresh eq shift(thresh,-1))
  good = good and (cnts lt 5e4)
  good = good and ( other lt 2)

  wgood = where(good)
  thresh = thresh[wgood]
  cnts  = cnts[wgood]
  timebar,minmax(rates_w[wgood].time)

  ;  timebar,rates_w[wgood].time
  ;  thresh[bad] = !values.f_nan
  wi,1
  !p.multi = [0,1,2]
  xrange = [0,50]
  anode_str = string(anode,format='("x",Z02)')
  plot,xrange=xrange,yrange=[1,50000.],thresh,cnts,psym=-1,/ylog,xtitle='Threshold',title = 'MCPV='+strtrim(mcpv,2)+'V  Anode = '+anode_str
  cntavg = average_hist(cnts,fix(thresh),binsize=1,xbins=tbins)
  oplot,tbins,cntavg,psym=-1,color=6
  dthavg = -deriv(tbins,cntavg)
  plot,xrange=xrange,yrange= yrange, tbins,dthavg,psym=-4,xtitle='Threshold'
  data = {anode:anode,  cntavg:cntavg,  tbins:tbins }
  if keyword_set(plotname) then makepng,plotname+'_'+anode_str
end
