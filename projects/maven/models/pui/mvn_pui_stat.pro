;20170424 Ali
;pickup ion statistical analysis of several days of data

pro mvn_pui_stat,nospice=nospice,img=img,trange=trange,nodataload=nodataload,binsize=binsize,np=np

@mvn_pui_commonblock.pro ;common mvn_pui_common

  if keyword_set(img) then begin
    xsize=3000
    ysize=1500
    wi,0,wsize=[xsize,ysize]
    wi,10,wsize=[xsize,ysize]
    wi,20,wsize=[xsize,ysize]
    wi,30,wsize=[xsize,ysize]
    wi,31,wsize=[xsize,ysize]
    g=window(background_color='k',dim=[400,200])
  endif

secinday=86400L ;number of seconds in a day
if ~keyword_set(trange) then trange=[time_double('14-11-27'),systime(1)]
trange=['19-2-1','now']
trange=time_double(trange)
ndays=ceil((trange[1]-trange[0])/secinday) ;number of days

if ~keyword_set(np) then np=3333
if ~keyword_set(binsize) then binsize=64.
nt=1+floor((secinday-binsize/2.)/binsize) ;number of time steps in a day

if ~keyword_set(nospice) then begin
  timespan,trange
  kernels=mvn_spice_kernels(/all,/clear)
  spice_kernel_load,kernels,verbose=3
;  maven_orbit_tplot,colors=[4,6,2],/loadonly ;loads the color-coded orbit info
endif

swdays=replicate(1,ndays)
for j=0,ndays-1 do begin ;loop over days
  tr=trange[0]+[j,j+1]*secinday
  mvn_pui_sw_orbit_coverage,trange=tr,res=binsize,alt_sw=alt_sw
  if where(finite(alt_sw),/null) eq !null then swdays[j]=0 ;no solar wind coverage
endfor

fnan=!values.f_nan
xyz=replicate(fnan,3) ;xyz or [mean,stdev,nsample]
swi={vsw:xyz,nsw:fnan,mode:fnan,att:fnan,qf:fnan,dt:fnan}
ifreq=replicate({pi:fnan,cx:fnan,ei:fnan},2) ;2 for [H,O]
sep=replicate({tot:xyz,xyz:xyz,att:0b,qf:fnan,dt:fnan},2) ;2 for sep1 and sep2
d2m=replicate({swi:xyz,sta:xyz},2) ;2 for [H,O]
sta={dt:fnan,dee:fnan,mass:[fnan,fnan]}
jsw=where(swdays,nswdays,/null)
mvn_pui_aos ;initialize pui and pui3
stat=replicate({centertime:0d,ifreq:ifreq,mag:xyz,swi:swi,sep:sep,sta:sta,d2m:d2m,params:pui[0].model.params,scpot:fnan},[nt,nswdays])
stat2d=replicate({d2m:pui3},nswdays)

for j=0,nswdays-1 do begin ;loop over days
  tr=trange[0]+[jsw[j],jsw[j]+1]*secinday
  mvn_pui_model,binsize=binsize,np=np,eifactor=1.,/do3d,savetplot=keyword_set(img),/nospice,trange=tr,nodataload=nodataload
  if ~keyword_set(swim) then continue ;no swia data available

  stat[*,j].centertime=pui.centertime
  stat[*,j].ifreq.pi=pui.model.ifreq.pi.tot
  stat[*,j].ifreq.ei=pui.model.ifreq.ei.tot
  stat[*,j].ifreq.cx=pui.model.ifreq.cx
  stat[*,j].mag=pui.data.mag.mso
  stat[*,j].swi.vsw=pui.data.swi.swim.velocity_mso
  stat[*,j].swi.nsw=pui.data.swi.swim.density
  stat[*,j].swi.mode=pui.data.swi.swim.swi_mode
  stat[*,j].swi.att=pui.data.swi.swim.atten_state
  stat[*,j].swi.qf=pui.data.swi.swim.quality_flag
  stat[*,j].swi.dt=pui.data.swi.dt
  stat[*,j].sep.tot=pui.d2m.sep
  stat[*,j].sep.xyz=pui.model[1].fluxes.sep.rv[0:2]
  stat[*,j].sep.att=pui.data.sep.att
  stat[*,j].sep.dt=pui.data.sep.dt
  stat[*,j].sep.qf=pui.model[1].fluxes.sep.qf
  stat[*,j].sta.dt=pui.data.sta.d1.dt
  stat[*,j].sta.dee=pui.data.sta.d1.dee
  stat[*,j].sta.mass=pui.data.sta.d1.mass[[0,4]]
  stat[*,j].params=pui.model.params
  stat[*,j].scpot=pui.data.swe.scpot
  stat[*,j].d2m.swi=pui.d2m.swi
  stat[*,j].d2m.sta=pui.d2m.sta
  stat2d[j].d2m=pui3

  datestr=strmid(time_string(tr[0]),0,10)
  if keyword_set(img) then mvn_pui_tplot_3d_save,graphics=g,datestr=datestr

endfor
save,stat,stat2d,pui0

stop
end