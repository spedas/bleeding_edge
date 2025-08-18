;20170731 Ali
;averaging over several days of data for later use

pro mvn_pui_stat3,trange=trange,binsize=binsize,nospice=nospice

  @mvn_pui_commonblock.pro ;common mvn_pui_common

  if ~keyword_set(trange) then trange=['15-4-1','15-5-1']
  if ~keyword_set(binsize) then binsize=128 ;time bin size in sec
  if ~keyword_set(nospice) then begin ;spice load
    timespan,trange
    kernels=mvn_spice_kernels(['STD','SCK','FRM','SPK'],/clear)
    spice_kernel_load,kernels,verbose=3
  endif

  secinday=86400L ;number of seconds in a day
  trange=time_double(trange)
  ndays=round((trange[1]-trange[0])/secinday) ;number of days
  nt=1+floor((secinday-binsize/2.)/binsize) ;number of time steps
  
  mvn_swia_load_l2_data,/loadmom,/loadspec,trange=['14-12-1','14-12-2'] ;to make sure pui is initialized correctly (swia data present for this date)
  mvn_pui_aos,/d0,/nomodel ;initialize pui with NaN's
  stat=replicate(pui[0],[nt,ndays]) ;define stat

  for j=0,ndays-1 do begin ;loop over days
    tr=trange[0]+[j,j+1]*secinday
    mvn_pui_model,binsize=binsize,trange=tr,/d0,/nospice,/nosep,/noeuv,/noswea,/nomag,/nomodel ;pickup ion model; saves data in time array of structures: pui
    if ~keyword_set(swis) then continue ;skip days with no swia spectrum data
    stat[*,j]=pui
  endfor

  rmars=3400e3 ;Mars radius (m)
  stat2=reform(stat,size(stat,/n_elements)) ;making stat 1d
  scp=stat2.data.scp ;maven position (m)
  rad=sqrt(total(scp^2,1)) ;maven radius (m)
  hirad=where(rad gt 2.5*rmars,/null,count) ;where high radius
  stat3=stat2[hirad] ;only high radii
  hiscp=stat3.data.scp ;maven position (m)
  staef=mean(mean(stat3.data.sta.d1.eflux,dim=2,/nan),dim=2,/nan) ;static eflux
  staet=stat3.data.sta.d1.energy ;static energy table
  stams=stat3.data.sta.d1.mass ;static mass table
  swief=stat3.data.swi.swis.data ;swia eflux
  lat=!radeg*mvn_pui_sza(hiscp[2,*],hiscp[0,*],hiscp[1,*])-90. ;latitude [-90 90]
  lon=!radeg*reform(atan(hiscp[0,*],hiscp[1,*])) ;longitude [-180 180]

  data=replicate({time:0d,scp:hiscp[*,0],lat:0.,lon:0.,swief:swief[*,0],swiet:pui1.swiet,staef:staef[*,*,0],staet:staet[*,0],stams:stams[*,0]},count)
  data.time=stat3.centertime
  data.scp=hiscp
  data.lat=lat
  data.lon=lon
  data.swief=swief
  data.staef=staef
  data.staet=staet
  data.stams=stams
  
;  save,data,file='data-16-7
;  restore,file='data-16-7
  dataavg=average(data,/nan)
  p=plot(dataavg.swiet,dataavg.swief,/xlog,/ylog,/stairs,xtitle='Energy (eV)',ytitle='EFlux',name='SWIA')
  p=plot(dataavg.staet,dataavg.staef[*,0],/stairs,name='STATIC Mass 1.1',/o,'b')
  p=plot(dataavg.staet,dataavg.staef[*,1],/stairs,name='STATIC Mass 2.2',/o,'g')
  p=plot(dataavg.staet,dataavg.staef[*,2],/stairs,name='STATIC Mass 4.7',/o,'r')
  p=plot(dataavg.staet,dataavg.staef[*,3],/stairs,name='STATIC Mass 9.4',/o,'c')
  p=plot(dataavg.staet,dataavg.staef[*,4],/stairs,name='STATIC Mass 17.1',/o,'m')
  p=plot(dataavg.staet,dataavg.staef[*,5],/stairs,name='STATIC Mass 30.6',/o,'y')
  p=plot(dataavg.staet,dataavg.staef[*,6],/stairs,name='STATIC Mass 42.4',/o,'--')
  p=plot(dataavg.staet,dataavg.staef[*,7],/stairs,name='STATIC Mass 62.5',/o,'-.')
  p=legend()
  stop
end