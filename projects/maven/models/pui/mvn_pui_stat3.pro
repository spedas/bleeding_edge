;20170731 Ali
;averaging over several days of data for later use

pro mvn_pui_stat3,trange=trange,binsize=binsize,nospice=nospice

  @mvn_pui_commonblock.pro ;common mvn_pui_common

  if ~keyword_set(trange) then get_timespan,trange else timespan,trange
  if ~keyword_set(binsize) then binsize=128
  if ~keyword_set(nospice) then begin
    kernels=mvn_spice_kernels(['STD','SCK','FRM','SPK'],/clear)
    spice_kernel_load,kernels,verbose=3
  endif

  mvn_pui_model,binsize=binsize,trange=trange,/d0,/nospice,/nosep,/noeuv,/noswea,/nomag,/nomodel
  
  rmars=3400e3 ;m
  scp=pui.data.scp ;maven position (m)
  rad=sqrt(total(scp^2,1))
  hirad=where(rad gt 2.5*rmars,/null)
  hipui=pui[hirad]
  hiscp=hipui.data.scp ;maven position (m)
  staef=mean(mean(hipui.data.sta.d1.eflux,dim=2,/nan),dim=2,/nan)
  swief=hipui.data.swi.swis.data
  lat=!radeg*mvn_pui_sza(hiscp[2,*],hiscp[0,*],hiscp[1,*])-90.
  lon=!radeg*reform(atan(hiscp[0,*],hiscp[1,*]))
  stop
end