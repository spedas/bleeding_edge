;compile_opt idl2
;keep



function spp_swp_spani_secondturnon_files
  src = spp_file_source()
  pathnames = 'spp/sweap/prelaunch/gsedata/EM/spanai/2015012?_*/PTP_data.dat'
  printdat,src
  files=file_retrieve(pathnames,_extra=src)
  return,files
end


function spp_swp_spani_firstturnon_files
  src = spp_file_source()
  pathnames = 'spp/sweap/prelaunch/gsedata/EM/spanai/2015011?_*/PTP_data.dat'
  printdat,src
  files=file_retrieve(pathnames,_extra=src)
  return,files
end



;function spp_swp_spani_thermaltest1_files
;src = spp_file_source()
;pathnames = 'spp/sweap/prelaunch/gsedata/EM/spanai/201502??_*/PTP_data.dat'
;printdat,src
;files=file_retrieve(pathnames,_extra=src)
;return,files
;end

;function spp_swp_spane_functiontest1_files
;  src = spp_file_source()
;  pathnames = 'spp/sweap/prelaunch/gsedata/EM/spanbe/2015021[234]_*/GSE_all_msg.dat'
;  printdat,src
;  files=file_retrieve(pathnames,_extra=src)
;  return,files
;end




;pro poisson_plot,s,index=index
;  if not keyword_set(s) then s = tsample()
;  nd = size(/dimen,s)
;;avg = average(s,1)
;;tot = total(s,1)
;  par = poisson()
;  
;  if n_elements(index) eq 0  then index = 2
;  i=index
;  s_i = s[*,i]
;  cs_i = spp_sweap_log_decomp( s_i,/comp)
;  h = histbins(cs_i,xb,binsize=1)
;  
;  par.avg = average(s_i)
;  par.h   = nd[0]
;  printdat,par
;  xv=dindgen(10000)
;  pc =  poisson(xv,param=par) 
;  printdat,pc
;  cxv = spp_sweap_log_decomp( xv,/comp)
;  
;  cpc = average_hist(pc,cxv,xbins=ccxv,binsize=1,/ret_total)
;  
;  plot,xb,h, psym=4,xrange=minmax([ccxv,cxv,xb]),yrange=minmax([pc,h,cpc])
;  oplot,xb,h,psym=10
;  
;
;;oplot,xv,pc,color=6,psym=10
;  oplot,ccxv,cpc,color=6,psym=10
;end



;pro print_rates,t
;  if ~keyword_set(t) then ctime,t,npoint=2,/silent
;  
;  valids=tsample('spp_spanai_rates_VALID_CNTS',t,/average)
;  multis=tsample('spp_spanai_rates_MULTI_CNTS',t,/average)
;  ostarts=tsample('spp_spanai_rates_START_CNTS',t,/average)
;  ostops =tsample('spp_spanai_rates_STOP_CNTS',t,/average)
;  
;  print,findgen(16)
;  print
;  print,valids
;  print,multis
;  print,ostarts
;  print,ostops
;  
;  starts = ostarts+valids
;  stops = ostops+valids
;  print
;  print,valids/starts
;  print,valids/stops
;end




;pro spp_tof_histogram,trange=trange,xrange=xrange,ylog=ylog,binsize=binsize,noerase=noerase,channels=channels,xlog=xlog,hist=h
;  if ~keyword_set(trange) then ctime,trange,npoints=2
;  
;  csize = 2
;  spp_apid_data,'3B9'x,apdata=ap
;;print_struct,ap
;  events = *ap.dataptr
;  if not keyword_set(trange) then ctime,trange
;  
;  if keyword_set(trange) then begin
;     w = where(events.time ge trange[0] and events.time le trange[1],nw)
;     if nw ne 0 then events = events[w] else dprint,'No points selected - using all'
;  endif
;  
;  col = bytescale(indgen(16))
;  nc = n_elements(col)
;;if ~keyword_set(xrange) then xrange=[450,600]
;  if ~keyword_set(binsize) then binsize = 1
;  h = histbins(events.tof,xb,binsize=binsize,shift=0,/extend_range)
;  
;  if keyword_set(ylog) then begin
;     mx = max(h)
;     yrange = [mx/10^(ylog+3),mx]
;     yrange  = [.5,mx*2]
;  endif
;  
;  if keyword_set(xlog) && ~keyword_set(xrange) then begin
;     xrange = minmax(/pos,xb) > 10
;     xrange = [10,2500]
;  endif
;
;
;  plot,/nodata,xb,h * 1.1,xrange=xrange,/xstyle,charsize=csize,yrange=yrange,ylog=ylog,ystyle=3,noerase=noerase,xtitle='Time of Flight channel',ytitle='Counts',xlog=xlog
;  mxt = max(h)
;  
;  if n_elements(channels) eq 0 then channels = reverse(indgen(16))
;  
;  for i=0,n_elements(channels)-1 do begin
;     ch = channels[i]
;     c=col[ch mod nc]
;     w = where(events.channel eq ch, nw)
;     if nw eq 0 then continue
;     h = histbins(events[w].tof,xb,binsize=binsize,shift=0)
;     oplot,xb,h,color=c,psym=10
;     oplot,xb,h,color=c,psym=1
;     mx = max(h,b)
;     xyouts,xb[b],h[b]+mxt*.03,strtrim(ch,2),color=c,align=.5,charsize=2
;     if keyword_set(dt)  then begin
;     
; ;   dt = findgen(44)+7
;        
;        pks = find_peaks( [replicate(0,round(xb[0])),h],roiw=5 )    
;        
;        plot,dt,pks.x0,/psym,yrange=[-100,500],xrange=[0,55],/ystyle,/xstyle,xtitle='Delay (ns)',ytitle='TOF value',title='Fit to response'
;        par = polycurve()
;        fit,dt[1:*],pks[1:*].x0,param=par,names='a0 a1'
;        oplot,dt,(pks.x0-func(dt,param=pc)) * 10,psym=4,color=6
;        oplot,xv,func(xv,param=pc)
;        xv=dgen()
;        oplot,xv,func(xv,param=pc)
;        oplot,[0,60],[0,0],color=5,linestyle=2
;        oplot,[0,60],[0,0],color=2,linestyle=2
;        
;        
;     endif
;  endfor
;  
;  
;end


;pro spp_set_tplot_options
;
;  ylim,'*rate*CNTS',1,1,1
;  options,'*rates*CNTS',labels='CH'+strtrim(indgen(16),2),labflag=-1,yrange=[.5,1e3],/ylog,ystyle=3,psym=-1,symsize=.5
;  options,'*rates*CNTS_t',labels='CH'+strtrim(indgen(16),2),labflag=-1,yrange=[.01,100],/ylog,ystyle=3,psym=-1,symsize=.5
;  options,'*events*',psym=3,ystyle=3
;  store_data,'log_MSG',dlimit=struct(tplot_routine='strplot')
;  options,'*MON*',/ynozero
;  tplot_options,'local_time',1
;  tplot_options,'xtitle','Pacific Time'
;  store_data,'STOP_SPEC',data='spp_spanai_rates_STOP_CNTS',dlimit=struct(spec=1,yrange=[-1,16],zrange=[.5,500],/zlog,ylog=0,/no_interp)
;  store_data,'START_SPEC',data='spp_spanai_rates_START_CNTS',dlimit=struct(spec=1,yrange=[-1,16],zrange=[.5,500],/zlog,ylog=0,/no_interp)
;
;  tplot,' *CMD_REC *rate*CNTS *ACC *MCP *events* log_MSG'
;  
;  if 0 then begin
;    options,'spp_spane_spec_CNTS',spec=0,yrange=[1,1000],ylog=1,colors='mbcgdr'
;  endif else begin
;    options,'spp_spane_spec_CNTS',spec=1,yrange=[0,17],ylog=0,zrange=[1,500.],zlog=1
;  endelse
;  
;  
;
;
;end


;pro temp
;  if 1 then begin
;     spp_apid_data,959,apdata=fhkp
;     dat= *(fhkp.last_ccsds)
;     d=  swap_endian(/swap_if_little_endian,   uint(dat.data,20,512) )
;     plot,d,/ynozer,psym=-1
;     wshow
;  endif
;end


;pro temp2
;  tplot,'*spane_hkp*MON* *RIO*'
;  tplot,'*spanai_hkp *rate*'
;end



;pro spp_recorders,msg=msg
;  common spp_crib_com, recorder_base1, recorder_base2,exec_base
;  exec,exec_base,exec_text = 'tplot,verbose=0,trange=systime(1)+[-1,.05]*300'
;
;  host = 'ABIAD-SW'
;  ;host = 'localhost'
;  ;host = '128.32.98.101'  ;  room 160 Silver
;  ;host = '128.32.13.37'   ;  room 133 addition
;; recorder,title='GSEOS PTP room 320',port=2024,host='ABIAD-SW',exec_proc='spp_ptp_stream_read',destination='spp_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat';,/set_proc,/set_connect,get_filename=filename
;  recorder,title='GSEOS HUB PTP room 320',port=2028,host='ABIAD-SW',exec_proc='spp_ptp_stream_read',destination='spp_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat';,/set_proc,/set_connect,get_filename=filename
;  if keyword_set(msg) then $
;    recorder,title='GSEOS MSG room 320',port=2023,host='ABIAD-SW',exec_proc='spp_msg_stream_read',destination='spp_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat'
;  ;recorder,title='GSEOS MSG 133 addition',port=2023,host='128.32.13.37',exec_proc='spp_msg_stream_read',destination='spp_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat';,/set_proc,/set_connect,get_filename=filename
;; ; recorder,recorder_133,title='GSEOS PTP 133 addition',port=2024,host='128.32.13.37',exec_proc='spp_ptp_stream_read',destination='spp_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat';,/set_proc,/set_connect,get_filename=filename
;  ;recorder,recorder_hub_133,title='GSEOS HUB PTP 133 addition',port=2028,host='128.32.13.37',exec_proc='spp_ptp_stream_read',destination='spp_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat';,/set_proc,/set_connect,get_filename=filename
;  printdat,recorder_base,filename,exec_base,/value
;end



;pro spp_init_realtime,filename=filename,base=base
;dprint, 'hello'
;;spp_recorders
;spp_swp_apid_data_init,save=1
;spp_apid_data,'3b9'x,name='SWEAP SPAN-I Events',rt_tags='*'
;spp_apid_data,'3ba'x,name='SWEAP SPAN-I TOF',rt_tags='*'
;spp_apid_data,'3bb'x,name='SWEAP SPAN-I Rates',rt_tags='*CNTS *MODE'
;spp_apid_data,'3be'x,name='SWEAP SPAN-I HKP',rt_tags='*'
;spp_apid_data,'380'x,name='SWEAP SPAN-I Prod_x80',rt_tags='*'
;spp_apid_data,'381'x,name='SWEAP SPAN-I Prod_x81',rt_tags='*'
;spp_apid_data,'382'x,name='SWEAP SPAN-I Prod_x82',rt_tags='*'
;spp_apid_data,'383'x,name='SWEAP SPAN-I Prod_x83',rt_tags='*'
;spp_apid_data,'384'x,name='SWEAP SPAN-I Prod_x84',rt_tags='*'
;spp_apid_data,'385'x,name='SWEAP SPAN-I Prod_x85',rt_tags='*'
;spp_apid_data,'386'x,name='SWEAP SPAN-I Prod_x86',rt_tags='*'
;spp_apid_data,'387'x,name='SWEAP SPAN-I Prod_x87',rt_tags='*'
;spp_apid_data,'388'x,name='SWEAP SPAN-I Prod_x88',rt_tags='*'
;spp_apid_data,'389'x,name='SWEAP SPAN-I Prod_x89',rt_tags='*'
;spp_apid_data,'38a'x,name='SWEAP SPAN-I Prod_x8a',rt_tags='*'
;spp_apid_data,'38b'x,name='SWEAP SPAN-I Prod_x8b',rt_tags='*'
;spp_apid_data,'38c'x,name='SWEAP SPAN-I Prod_x8c',rt_tags='*'
;spp_apid_data,'38d'x,name='SWEAP SPAN-I Prod_x8d',rt_tags='*'
;spp_apid_data,'38e'x,name='SWEAP SPAN-I Prod_x8e',rt_tags='*'
;spp_apid_data,'38f'x,name='SWEAP SPAN-I Prod_x8f',rt_tags='*'
;spp_apid_data,'390'x,name='SWEAP SPAN-I Prod_x90',rt_tags='*'
;spp_apid_data,'391'x,name='SWEAP SPAN-I Prod_x91',rt_tags='*'
;spp_apid_data,'392'x,name='SWEAP SPAN-I Prod_x92',rt_tags='*'
;spp_apid_data,'393'x,name='SWEAP SPAN-I Prod_x93',rt_tags='*'
;spp_apid_data,'394'x,name='SWEAP SPAN-I Prod_x94',rt_tags='*'
;spp_apid_data,'395'x,name='SWEAP SPAN-I Prod_x95',rt_tags='*'
;spp_apid_data,'396'x,name='SWEAP SPAN-I Prod_x96',rt_tags='*'
;spp_apid_data,'397'x,name='SWEAP SPAN-I Prod_x97',rt_tags='*'
;spp_apid_data, rt_flag = 1
;
;wait,1
;spp_swp_manip_init
;spp_set_tplot_options
;
;spp_apid_data,apdata=ap
;print_struct,ap
;
;
;
;if 0 then begin
;  f1= file_search('spp*.ptp')
;  spp_apid_data,rt_flag=0
;  spp_ptp_file_read,f1[-1]
;  spp_apid_data,rt_flag=1
;endif
;end


;pro spp_message_to_value
;
;  spp_apid_data,'7C0'x,apdata=ap
;  print_struct,ap
;  dat = *ap.dataptr
;  w = where( strmid(dat.msg,0,4) eq 'set ')
; 
;
;
;end



;pro spp_swp_reduce,tof_range=tof_range,tof_name=tof_name
;
;res =5.
;
;if 0 then begin
;  reduce_timeres_data,'spp_spanai_rates_*CNTS',res ;,trange=tr
;  get_data,'spp_spanai_rates_VALID_CNTS_t',data=d1
;  get_data,'spp_spanai_rates_START_CNTS_t',data=d3
;  get_data,'spp_spanai_rates_STOP_CNTS_t',data=d4
;  dr =d1
;  dr.y = d1.y/(d1.y+d3.y)
;  store_data,'valid_start',data=dr
;  dr.y = d1.y/(d1.y+d4.y)
;  store_data,'valid_stop',data=dr
;  dr.y = (d1.y+d3.y)/(d1.y+d4.y)
;  store_data,'start_stop',data=dr
;  dr.y = (d1.y+d4.y)/(d1.y+d3.y)
;  store_data,'stop_start',data=dr
;endif
;
;if 1 then begin
;  spp_apid_data,'3b9'x,apdata=ap
;  a = *ap.dataptr
;  for ch = 0 ,15 do begin   
;    test = a.channel eq ch
;    if n_elements(tof_range) eq 2 then test = test and (a.tof le tof_range[1] and a.tof ge tof_range[0])
;    w = where(test,nw)
;    colors = bytescale(findgen(16))
;    ;dl = {psym:3, colors=0}
;    name =string(ch,format='("spanai_ch",i02,"_")')
;    if keyword_set(tof_name) then name += tof_name+'_'
;    if nw ne 0 then store_data,name,data=a[w],tagnames='*',dlim={TOF:{psym:3,symsize:.4,colors:colors[ch] }}
;    h=histbins(a[w].time,tb,binsize=double(res))
;    store_data,name+'TOT',tb,h,dlim={colors:colors[ch]}
;  endfor
;  store_data,'spanai_all_TOT',data='spanai_ch??_TOT'
;
;endif
;
;
;end


pro spp_swp_finish_rates
if 0 then  begin
  spp_apid_data,'3bb'x,apdata=rates  
  d = rates.data_array.array
endif  else begin
   rates = spp_apid_obj('3bb'x)
   d = rates.array
endelse
   store_data,'stops_with_starts',data={x:d.time, y: transpose(d.stops_cnts - d.stop_nostart_cnts )}
   store_data,'starts_with_stops',data={x:d.time, y: transpose(d.starts_cnts - d.start_nostop_cnts )}
   store_data,'start_eff',data={x:d.time, y: transpose(d.valid_cnts / d.stops_cnts ) }
   store_data,'stop_eff',data={x:d.time, y: transpose( d.valid_cnts / d.starts_cnts ) }
end


function  spp_swp_spani_thresh_tlimits,hkp,anode
  w = where(hkp.mram_addr_hi eq anode )
  tr = minmax(hkp[w].time)
end


pro spp_swp_spani_thresh_test,anode,trangefull=trangefull,data=data,plotname=plotname

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

pro spp_swp_spani_thresh_test_all 


end


if 1 then begin
  
  if not keyword_set(alldat) then begin
    alldat = ptrarr(32,/allocate_heap)
    for i=0,31 do spp_swp_spani_thresh_test,trangefu=trf,i,plotname='spani_thresh_scan',data=*alldat[i]
  endif
  
  
  wi,1
  !p.multi = [0,1,3]
  xrange = [0,50]
  yrange = [1,50000.]
  col = intarr(32)
  col[0:15] = 2
  col[16:25] = 4
  col[26:31] = 6
  
  plot,xrange=xrange,yrange=yrange,[1,1],/nodata,/ylog,xtitle='Threshold',title ='All anodes',ytitle='Counts'
  for i=0,31,1 do begin
    dat = *alldat[i]
;    col = (dat.anode and '10'x) ne 0 ? 6 : 2
    oplot,dat.tbins,dat.cntavg,color = col[dat.anode]
  endfor

  yrange=[0,500]
  plot,xrange=xrange,yrange=yrange,[1,1],/nodata,ylog=0,xtitle='Threshold',title ='All anodes',ytitle='d(cnt)/d(thresh)'

  for i=0,31,1 do begin
    dat = *alldat[i]
 ;   col = (dat.anode and '10'x) ne 0 ? 6 : 2
    oplot,dat.tbins,-deriv(dat.tbins,dat.cntavg),color = col[dat.anode]
  endfor

  yrange=[0,5000]
  plot,xrange=xrange,yrange=yrange,[1,1],/nodata,ylog=0,xtitle='Threshold',title ='All anodes',ytitle='d(cnt)/d(thresh)'

  for i=0,31,1 do begin
    dat = *alldat[i]
;    col = (dat.anode and '10'x) ne 0 ? 6 : 2
    oplot,dat.tbins,-deriv(dat.tbins,dat.cntavg),color = col[dat.anode]
  endfor


  
endif


if 0 then begin
    
  
  
  
  file = spp_file_retrieve('spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160912_190540_SPANI_EM3_SNOUT2_cold_thresh_scan/PTP_data.dat.gz')
  
  
  
  
  
endif





if 0 then begin

  if 0 then begin
    src = file_retrieve(/str)
    src.remote_data_dir='http://sprg.ssl.berkeley.edu/data/'
    url_index = 'http://sprg.ssl.berkeley.edu/data/spp/sweap/prelaunch/gsedata/EM/spanai/'
    pathindex = strmid(url_index,strlen(src.remote_data_dir))
    indexfile = file_retrieve(_extra=src,pathindex)+'/.remote-index.html'
 ;   links = file_extract_html_links(indexfile,count,verbose=verbose,no_parent=url_index)  ; Links with '*' or '?' or leading '/' are removed.
    fileformat = 'spp/sweap/prelaunch/gsedata/EM/spanai/'+links[-1]+'PTP_data.dat'
  endif

  src = file_retrieve(/str)
  src.remote_data_dir='http://sprg.ssl.berkeley.edu/data/'
  fileformat = 'spp/sweap/prelaunch/gsedata/EM/spanai/2015*/PTP_data.dat'
  files = file_retrieve(_extra=src,fileformat,last_version=1)
  spp_ptp_file_read,files

  
  
  spp_init_realtime,filename=rtfile
  spp_ptp_file_read,rtfile
  

  spp_ptp_file_read,file[-1]
  spp_apid_data,rt_flag=1
  
;  del_data,'*'
;  f= file_search('~/Downloads/PTP*.dat')
;  f1= file_search('spp*.ptp')
;  f2=file_search('/disks/data/spp/sweap/','*PTP*')
;  files = [F2[-1],f1[-1]]
;  files = [file,f1[-1]]
  
  store_data,'*',/clear

  spp_ptp_file_read,files

  spp_apid_data,rt_flag=1,/finish


  spp_apid_data,apdata=ap
  print_struct,ap  
  
spp_swp_spani_tof_histogram,/ylog  ;,trange,xrange=xrange

spp_swp_reduce

gunvoltage =[0,10.3,50.3,100.4,500.3,1000.3,2000.1,3000.1,4000.1]
gunsupplycurrent = [.0013,.0015,.0024,.0033,.0115,.0216,.0418,.0619,.0820]
plot,gunvoltage,gunsupplycurrent

endif


end


spp_apdat_info,/print
crit = spp_apdat('340x')
crit.help





