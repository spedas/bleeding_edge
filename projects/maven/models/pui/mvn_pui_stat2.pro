;20170505 Ali
;statistical analysis on results of mvn_pui_stat

pro mvn_pui_stat2
filename_all='C:\Users\rahmati\idl\idlsave_all9.dat'
filename_sw='C:\Users\rahmati\idl\idlsave_sw9.dat'

if 0 then begin ;load all data
  restore,filename_all ;restores stat,binsize,np
  stop
  stat2=reform(stat,size(stat,/n_elements)) ;making stat 1d
  stat3=stat2[where(stat2.centertime gt 0.,/null)] ;where data is available
  if 1 then begin ;choose solar wind
    mvn_pui_sw_orbit_coverage,times=stat3.centertime,alt_sw=alt_sw,conservative=1,spice=1
    stat4=stat3[where(finite(alt_sw),/null,count1)] ;only solar wind, pretty conservative to keep bad stuff out
    save,stat4,binsize,np,filename=filename_sw
  endif else stat4=stat3
endif else restore,filename_sw ;restores stat4,binsize,np
;stop
sizesep=size(stat4.d2m.sep) ;for backward compatibitily
if sizesep[0] eq 3 then sw6=1 else sw6=0 ;idlsave_sw6 and below
if sizesep[0] eq 2 then sw7=1 else sw7=0 ;idlsave_sw7 and above

if sw7 then begin
  ct=stat4.centertime
  store_data,'pui_stat_sep1_tot',ct,data={x:ct,y:[[transpose(stat4.d2m[0].sep.tot)],[100.*replicate(1.,n_elements(ct))]]},limits={ylog:1,yrange:[1,1e4],colors:'brgm',labels:['model','data','cme','100'],labflag:1,ytickunits:'scientific'}
  store_data,'pui_stat_sep2_tot',ct,data={x:ct,y:[[transpose(stat4.d2m[1].sep.tot)],[100.*replicate(1.,n_elements(ct))]]},limits={ylog:1,yrange:[1,1e4],colors:'brgm',labels:['model','data','cme','100'],labflag:1,ytickunits:'scientific'}
  store_data,'pui_stat_sep_qf',ct,data={x:ct,y:transpose(stat4.d2m.sep.qf)},limits={yrange:[0,1],colors:'br',labels:['SEP1','SEP2'],labflag:1}
  store_data,'pui_stat_swi_mode',ct,data={x:ct,y:stat4.swimode},limits={yrange:[-1,2]} ;0: sw mode, 1:sheath mode
  store_data,'pui_stat_swi_att',ct,data={x:ct,y:stat4.swiatt},limits={yrange:[0,3]} ;1:open att, 2:closed att
endif

if 1 then begin ;getting rid of unfavorable upstream parameters
  usw=sqrt(total(stat4.vsw^2,1)) ;solar wind speed (km/s)
  mag=sqrt(total(stat4.mag^2,1)) ;magnetic field (T)
  costub=total(stat4.vsw*stat4.mag,1)/(usw*mag) ;cos(thetaUB)
  tub=!radeg*acos(costub) ;thetaUB 0<tub<180
  lowusw=usw lt 400. ;low usw
  lowmag=mag lt 1e-9 ;low mag (high error in B)
  lowtub=abs(costub) gt .9 ;low thetaUB < 26deg
  if sw7 then begin
    swimode=stat4.swimode ne 0. ;swia not in solar wind mode (unreliable velocity and density)
    swiatt=stat4.swiatt eq 0. ;all att's
    stat4[where(lowmag or lowtub or swimode or swiatt,/null)]=fill_nan(stat4[0])
    stat4[where(stat4.d2m[0].sep.qf lt .3 or stat4.d2m[0].sep.tot[0] lt 300./stat4.d2m[0].sep.att^6. or stat4.d2m[0].sep.tot[1] lt 300./stat4.d2m[0].sep.att^6. or stat4.d2m[0].sep.tot[2] gt 30./stat4.d2m[0].sep.att^6.,/null)].d2m[0].sep.tot[0]=!values.f_nan ;more reliable SEP
    stat4[where(stat4.d2m[1].sep.qf lt .3 or stat4.d2m[1].sep.tot[0] lt 300./stat4.d2m[1].sep.att^6. or stat4.d2m[1].sep.tot[1] lt 300./stat4.d2m[1].sep.att^6. or stat4.d2m[1].sep.tot[2] gt 30./stat4.d2m[1].sep.att^6.,/null)].d2m[1].sep.tot[0]=!values.f_nan ;more reliable SEP
  endif
  if sw6 then stat4[where(lowusw or lowmag or lowtub,/null)].d2m.sep=!values.f_nan ;more reliable SEP
  if 0 then begin ;plot upstream parameter histogram distributions
    nsw_hist=histogram(10.*stat4.nsw)
    usw_hist=histogram(usw)
    mag_hist=histogram(1e10*mag)
    tub_hist=histogram(tub)
    p=plot(nsw_hist,xtitle='10*Nsw (cm-3)',/xlog)
    p=plot(usw_hist,xtitle='Usw (km/s)')
    p=plot(mag_hist,xtitle='10*MAG (nT)',/xlog)
    p=plot(tub_hist,xtitle='thetaUB (degrees)')
  endif
endif

if sw7 then stat4.d2m.sep.qf=stat4.d2m.sep.tot[1]/stat4.d2m.sep.tot[0] ;turn qf into d2m!

if 0 then begin ;orbit averaging
  count2=n_elements(stat4) ;should be equal to count1 above
  dt=stat4[1:-1].centertime-stat4[0:-2].centertime ;must be equal to binsize, otherwise orbit jump
  index2=where(dt gt 60.*60.*24.*10.,/null,swjumps) ;solar wind jumps (swjumps: number of time periods entirely inside the bowshock)
  index3=where(dt gt binsize,/null,norbits) ;orbit jumps (norbits: number of orbits minus 1)
;  index3=where((stat4.centertime mod 1001) eq 0,/null,norbits) ;arbitrary time binning
  index4=lonarr(norbits+2) ;orbit edges
  index4[1:-2]=index3 ;last element of each orbit (except the last orbit)
  index4[0]=-1 ;first orbit starting edge
  index4[-1]=count2-1 ;last orbit ending edge
  stat5=replicate(stat4[0],norbits+1) ;orbit average statistics

  for j=0,norbits do begin ;loop over orbits
    stat6=stat4[index4[j]+1:index4[j+1]]

    stat5[j].centertime=average(stat6.centertime)
    stat5[j].mag[0]=exp(average(alog(sqrt(total(stat6.mag^2,1))),/nan,stdev=stdev,nsamples=nsamples))
    stat5[j].mag[1]=stdev
    stat5[j].mag[2]=nsamples
    stat5[j].vsw[0]=average(sqrt(total(stat6.vsw^2,1)),/nan,stdev=stdev,nsamples=nsamples)
    stat5[j].vsw[1]=stdev
    stat5[j].vsw[2]=nsamples
    stat5[j].nsw=exp(average(alog(stat6.nsw),/nan,stdev=stdev,nsamples=nsamples))
    stat5[j].ifreq.pi=average(stat6.ifreq.pi,2,/nan,stdev=stdev,nsamples=nsamples)
    stat5[j].ifreq.ei=exp(average(alog(stat6.ifreq.ei),2,/nan,stdev=stdev,nsamples=nsamples))
    stat5[j].ifreq.cx=exp(average(alog(stat6.ifreq.cx),2,/nan,stdev=stdev,nsamples=nsamples))
    if sw6 then stat5[j].d2m.sep=exp(average(alog(stat6.d2m.sep),3,/nan,stdev=stdev,nsamples=nsamples))
    if sw7 then stat5[j].d2m.sep.qf=exp(average(alog(stat6.d2m.sep.qf),2,/nan,stdev=stdev,nsamples=nsamples))
    stat5[j].d2m.swi[0]=exp(average(alog(stat6.d2m.swi[0]),2,/nan,stdev=stdev,nsamples=nsamples,weight=stat6.d2m.swi[2]))
    stat5[j].d2m.swi[1]=exp(stdev)
    stat5[j].d2m.swi[2]=nsamples
    stat5[j].d2m.sta[0]=exp(average(alog(stat6.d2m.sta[0]),2,/nan,stdev=stdev,nsamples=nsamples,weight=stat6.d2m.sta[2]))
    stat5[j].d2m.sta[1]=exp(stdev)
    stat5[j].d2m.sta[2]=nsamples
  endfor
end

if 0 then begin ;arbitrary averaging of orbit averages
  nbins=300
  range=minmax(stat4.centertime)
  stat6=stat5
  stat5=replicate(stat4[0],nbins)

  stat5.mag[0]=exp(average_hist(alog(stat6.mag[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.vsw[0]=average_hist(stat6.vsw[0],stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
  stat5.nsw=exp(average_hist(alog(stat6.nsw),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[0].pi=average_hist(stat6.ifreq[0].pi,stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
  stat5.ifreq[1].pi=average_hist(stat6.ifreq[1].pi,stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
  stat5.ifreq[0].ei=exp(average_hist(alog(stat6.ifreq[0].ei),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[1].ei=exp(average_hist(alog(stat6.ifreq[1].ei),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[0].cx=exp(average_hist(alog(stat6.ifreq[0].cx),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.ifreq[1].cx=exp(average_hist(alog(stat6.ifreq[1].cx),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  if sw6 then stat5.d2m[1].sep[0]=exp(average_hist(alog(stat6.d2m[1].sep[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  if sw6 then stat5.d2m[1].sep[1]=exp(average_hist(alog(stat6.d2m[1].sep[1]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  if sw7 then stat5.d2m[0].sep.qf=exp(average_hist(alog(stat6.d2m[0].sep.qf),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  if sw7 then stat5.d2m[1].sep.qf=exp(average_hist(alog(stat6.d2m[1].sep.qf),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[0].swi[0]=exp(average_hist(alog(stat6.d2m[0].swi[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[1].swi[0]=exp(average_hist(alog(stat6.d2m[1].swi[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[0].sta[0]=exp(average_hist(alog(stat6.d2m[0].sta[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.d2m[1].sta[0]=exp(average_hist(alog(stat6.d2m[1].sta[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
  stat5.centertime=xbins
endif

if 1 then begin ;everything
  stat5=stat4
  stat5.mag[0]=sqrt(total(stat4.mag^2,1))
  stat5.vsw[0]=sqrt(total(stat4.vsw^2,1))
endif

ct=stat5.centertime
;stop
if 0 then begin ;tplot stuff
  store_data,'pui_stat_mag',ct,1e9*stat5.mag[0]
  ylim,'pui_stat_mag',.1,100,1
  store_data,'pui_stat_usw',ct,stat5.vsw[0]
  ylim,'pui_stat_usw',100,1000,1
  store_data,'pui_stat_nsw',ct,stat5.nsw
  ylim,'pui_stat_nsw',.1,100,1

  store_data,'pui_stat_ifreq_pi_H',ct,stat5.ifreq[0].pi,limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_pi_O',ct,stat5.ifreq[1].pi,limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_cx_H',data={x:ct,y:stat5.ifreq[0].cx},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_cx_O',data={x:ct,y:stat5.ifreq[1].cx},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_ei_H',data={x:ct,y:stat5.ifreq[0].ei},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_ei_O',data={x:ct,y:stat5.ifreq[1].ei},limits={ylog:1,yrange:[1e-8,1e-6]}
  store_data,'pui_stat_ifreq_H',data={x:ct,y:stat5.ifreq[0].pi+stat5.ifreq[0].cx+stat5.ifreq[0].ei},limits={ylog:1,yrange:[1e-7,1e-6]}
  store_data,'pui_stat_ifreq_O',data={x:ct,y:stat5.ifreq[1].pi+stat5.ifreq[1].cx+stat5.ifreq[1].ei},limits={ylog:1,yrange:[1e-7,1e-6]}
;  ylim,'pui_stat_ifreq_*',1e-8,1e-7,0
  options,'pui_stat_ifreq_pi_?','ystyle',1

  if sw6 then store_data,'pui_stat_d2m_sep1',ct,stat5.d2m[1].sep[0]
  if sw6 then store_data,'pui_stat_d2m_sep2',ct,stat5.d2m[1].sep[1]
  if sw7 then begin
    store_data,'pui_stat_d2m_sep1',ct,stat5.d2m[0].sep.qf
    store_data,'pui_stat_d2m_sep2',ct,stat5.d2m[1].sep.qf
  endif
  store_data,'pui_stat_d2m_swi_H',ct,stat5.d2m[0].swi[0]
  store_data,'pui_stat_d2m_swi_O',ct,stat5.d2m[1].swi[0]
  store_data,'pui_stat_d2m_sta_H',ct,stat5.d2m[0].sta[0]
  store_data,'pui_stat_d2m_sta_O',ct,stat5.d2m[1].sta[0]
  ylim,'pui_stat_d2m*',.1,10,1
  ylim,'pui_stat_d2m_sep?',.01,100,1

  options,'pui_stat_*','psym',0
  wi,0
  tplot,wi=0,'pui*swi_mode pui*swi_att pui*mag pui*usw pui*nsw pui*ifreq*'
  wi,1
  tplot,wi=1,'pui*tot* pui*qf* pui*d2m*
endif

if 1 then begin
  sep1map=mvn_pui_2d_map(stat5.d2m[0].sep.xyz,stat5.d2m[0].sep.qf,200,/sep)
  sep2map=mvn_pui_2d_map(stat5.d2m[1].sep.xyz,stat5.d2m[1].sep.qf,200,/sep)
  p=image(alog10(sep1map),min=-1,max=1,margin=.1,rgb_table=colortable(33),axis_style=2,title='SEP1 d2m')
  mvn_pui_plot_mars_bow_shock,/half,/kkm
  p=image(alog10(sep2map),min=-1,max=1,margin=.1,rgb_table=colortable(33),axis_style=2,title='SEP2 d2m')
  mvn_pui_plot_mars_bow_shock,/half,/kkm
endif

if 0 then begin
p=plot(stat5.mag[0],stat5.vsw[0],'.',/xlog) ;imf vs vsw (no correlation)
p=plot(stat5.mag[0],stat5.nsw,'.',/xlog,/ylog) ;mag vs nsw (highly correlated)
p=plot(stat5.vsw[0],stat5.nsw,'.',/ylog) ;vsw vs nsw (correlated)
p=plot(stat5.ifreq[0].cx,stat5.ifreq[0].ei,'.b',/xlog,/ylog,xrange=[1e-8,1e-5],yrange=[1e-9,1e-6]) ;cx vs ei (correlated)
p=plot(stat5.ifreq[1].cx,stat5.ifreq[1].ei,'.r',/o)
p=plot(stat5.ifreq[0].cx,stat5.ifreq[0].pi,'.',/xlog,xrange=[1e-8,1e-5]) ;cx vs pi (not correlated)
p=plot(stat5.ifreq[0].pi,stat5.ifreq[1].pi,'.') ;pi H vs O (correlated)
p=plot(stat5.d2m[0].sta[0],stat5.d2m[1].sta[0],'.',/xlog,/ylog)
p=plot(stat5.vsw[0],stat5.d2m[1].sep[1],'.',/xlog,/ylog)
p=plot(stat5.ifreq[1].pi,stat5.d2m[1].swi[0],'.b',xtitle=['PI freq (s-1)'],ytitle=['O d2m ratio'])
p=plot(stat5.ifreq[1].pi,stat5.d2m[1].sta[0],'.r',/o,title='SWIA: blue, STATIC: red')
p=plot(1e9*stat5.mag[0],stat5.d2m[1].sta[0],'.',/xlog,/ylog,yrange=[.1,10],xtitle=['MAG (nT)'],ytitle=['STATIC O d2m ratio'])
p=plot(stat5.vsw[0],stat5.d2m[1].sta[0],'.',/xlog,/ylog,yrange=[.1,10],xtitle=['Usw (km/s)'],ytitle=['STATIC O d2m ratio'])
p=plot(stat5.nsw,stat5.d2m[1].sta[0],'.',/xlog,/ylog,yrange=[.1,10],xtitle=['Nsw (cm-3)'],ytitle=['STATIC O d2m ratio'])
endif

if 0 then begin ;escape rate comparison
p=plot(/o,6e25*stat5.d2m[0].swi[0],'b')
p=plot(/o,6e25*stat5.d2m[0].sta[0],'r')
p=plot(/o,6e32*stat5.ifreq[0].cx,'g')
endif

if 0 then begin ;escape rate vs. Ls
mvn_pui_au_ls,times=ct,mars_au=mars_au,mars_ls=mars_ls,spice=0
p=plot([0],/nodata,yrange=[1e25,1e27],/ylog,xtitle='$L_s$',ytitle='H escape rate ($s^{-1}$)')
p=plot(/o,mars_ls,6e25*(stat5.d2m[0].sta[0]+stat5.d2m[0].swi[0])/2.,'g.')
p=scatterplot(/o,mars_ls,6e25*(stat5.d2m[0].sta[0]+stat5.d2m[0].swi[0])/2.,magnitude=ct,rgb=33)
endif

if 0 then begin ;sta/swi ratios
p=plot(ct,stat5.d2m[0].sta[0]/stat5.d2m[0].swi[0],'b',/ylog,yrange=[.1,10],/stairs)
p=plot(ct,stat5.d2m[1].sta[0]/stat5.d2m[1].swi[0],'r',/o,/stairs)
endif

if 0 then begin ;sep qf vs. d2m ratios
p=plot([0],/nodata,/ylog,xtitle='Quality Flag',ytitle='SEP d2m Ratio',yrange=[1e-3,1e3])
p=plot(/o,stat5.d2m[0].sep.qf,stat5.d2m[0].sep.tot[1]/stat5.d2m[0].sep.tot[0],'b.',name='SEP1F')
p=plot(/o,stat5.d2m[1].sep.qf,stat5.d2m[1].sep.tot[1]/stat5.d2m[1].sep.tot[0],'r.',name='SEP2F')
endif

if 0 then begin ;sep d2m ratio vs. birth distance
p=plot([0],/nodata,/xlog,/ylog,xtitle='SEP d2m Ratio',ytitle='Radial Distance (km)')
p=plot(/o,stat5.d2m[0].sep.qf,1e-3*sqrt(total((stat5.d2m[0].sep.xyz)^2,1)),'b.',name='SEP1F')
p=plot(/o,stat5.d2m[1].sep.qf,1e-3*sqrt(total((stat5.d2m[1].sep.xyz)^2,1)),'r.',name='SEP2F')
endif

if 0 then begin ;sep d2m ratio vs. birth sza
p=plot([0],/nodata,/ylog,xtitle='SZA',ytitle='SEP d2m Ratio')
p=plot(/o,!radeg*mvn_pui_sza(stat5.d2m[0].sep.xyz[0],stat5.d2m[0].sep.xyz[1],stat5.d2m[0].sep.xyz[2]),stat5.d2m[0].sep.qf,'b.',name='SEP1F')
p=plot(/o,!radeg*mvn_pui_sza(stat5.d2m[1].sep.xyz[0],stat5.d2m[1].sep.xyz[1],stat5.d2m[1].sep.xyz[2]),stat5.d2m[1].sep.qf,'r.',name='SEP2F')
p=legend()
endif

if 0 then begin
p=plot([0],/nodata,/xlog,/ylog,xtitle='MAG (nT)',ytitle='SEP d2m Ratio')
p=plot(/o,1e9*stat5.mag[0],stat5.d2m[0].sep.qf,'b.',name='SEP1F')
p=plot(/o,1e9*stat5.mag[0],stat5.d2m[1].sep.qf,'r.',name='SEP2F')
p=legend()
endif

if 0 then begin
p=plot([0],/nodata,/ylog,xtitle='Usw (km/s)',ytitle='SEP d2m Ratio')
p=plot(/o,stat5.vsw[0],stat5.d2m[0].sep.qf,'b.',name='SEP1F')
p=plot(/o,stat5.vsw[0],stat5.d2m[1].sep.qf,'r.',name='SEP2F')
p=legend()
endif

alswi=exp(average(alog(stat5.d2m.swi[0]),2,/nan))
alsta=exp(average(alog(stat5.d2m.sta[0]),2,/nan))
avswi=average(stat5.d2m.swi[0],2,/nan)
avsta=average(stat5.d2m.sta[0],2,/nan)
;stop
end