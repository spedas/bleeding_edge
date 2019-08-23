;20170505 Ali
;statistical analysis on results of mvn_pui_stat

pro mvn_pui_stat2
  filename_all='/home/rahmati/Desktop/pui_sims/idlsave_all13.dat'
  filename_sw='/home/rahmati/Desktop/pui_sims/idlsave_sw11.dat'

  if 0 then begin ;load all data
    restore,filename_all ;restores stat,binsize,np
    stop
    stat2=reform(stat,size(stat,/n_elements)) ;making stat 1d
    stat3=stat2[where(stat2.centertime gt 0.,/null)] ;where data is available
    if 0 then begin ;choose solar wind
      mvn_pui_sw_orbit_coverage,times=stat3.centertime,alt_sw=alt_sw,conservative=1,spice=1
      stat4=stat3[where(finite(alt_sw),/null,count1)] ;only solar wind, pretty conservative to keep bad stuff out
      save,stat4,pui0,filename=filename_sw
    endif else stat4=stat3
  endif else restore,filename_sw ;restores stat4,binsize,np
  ;stop
  sized2m=size(stat4.d2m) ;for backward compatibitily
  if sized2m[0] eq 3 then begin
    sizesep=size(stat4.d2m.sep) ;for backward compatibitily
    if sizesep[0] eq 3 then sw6=1 else sw6=0 ;idlsave_sw6 and below
    if sizesep[0] eq 2 then sw7=1 else sw7=0 ;idlsave_sw7 and above
  endif else begin
    sw6=0
    sw7=0
    sw10=1
  endelse

  fnan=!values.f_nan
  ct=stat4.centertime
  if sw10 then begin
    store_data,'pui_stat_sep1_tot',ct,data={x:ct,y:[[transpose(stat4.sep[0].tot)],[100.*replicate(1.,n_elements(ct))]]},limits={ylog:1,yrange:[1,1e4],colors:'brgm',labels:['model','data','cme','100'],labflag:1,ytickunits:'scientific'}
    store_data,'pui_stat_sep2_tot',ct,data={x:ct,y:[[transpose(stat4.sep[1].tot)],[100.*replicate(1.,n_elements(ct))]]},limits={ylog:1,yrange:[1,1e4],colors:'brgm',labels:['model','data','cme','100'],labflag:1,ytickunits:'scientific'}
    store_data,'pui_stat_sep_att',ct,data={x:ct,y:transpose(stat4.sep.att)},limits={yrange:[0,3],colors:'br',labels:['SEP1','SEP2'],labflag:-1,panel_size:0.5} ;1:open att, 2:closed att
    store_data,'pui_stat_sep_qf',ct,data={x:ct,y:transpose(stat4.sep.qf)},limits={yrange:[-1,2],colors:'br',labels:['SEP1','SEP2'],labflag:-1,panel_size:0.5}
    store_data,'pui_stat_sep_dt',ct,data={x:ct,y:transpose(stat4.sep.dt)},limits={ylog:1,colors:'br',labels:['SEP1','SEP2'],labflag:-1,panel_size:0.5}
    store_data,'pui_stat_swi_mode',ct,data={x:ct,y:stat4.swi.mode},limits={yrange:[-1,2],panel_size:0.5,psym:3} ;0: sw mode, 1:sheath mode
    store_data,'pui_stat_swi_att',ct,data={x:ct,y:stat4.swi.att},limits={yrange:[0,3],panel_size:0.5,psym:3} ;1:open att, 2:closed att
    store_data,'pui_stat_swi_qf',ct,data={x:ct,y:stat4.swi.qf},limits={yrange:[-1,2],panel_size:0.5}
    store_data,'pui_stat_swi_dt',ct,data={x:ct,y:stat4.swi.dt},limits={ylog:1,panel_size:0.5,psym:3}
    store_data,'pui_stat_sta_dt',ct,data={x:ct,y:stat4.sta.dt},limits={ylog:1,panel_size:0.5,psym:3}
    store_data,'pui_stat_sta_dE/E',ct,data={x:ct,y:stat4.sta.dee},limits={ylog:1,panel_size:0.5,psym:3}
    store_data,'pui_stat_sta_mass',ct,data={x:ct,y:transpose(stat4.sta.mass)},limits={ylog:1,panel_size:0.5,psym:3}
    store_data,'pui_stat_scpot',ct,data={x:ct,y:stat4.scpot}
  endif

  if 1 then begin ;getting rid of unfavorable upstream parameters
    usw=sqrt(total(stat4.swi.vsw^2,1)) ;solar wind speed (km/s)
    mag=sqrt(total(stat4.mag^2,1)) ;magnetic field (T)
    costub=total(stat4.swi.vsw*stat4.mag,1)/(usw*mag) ;cos(thetaUB)
    tub=!radeg*acos(costub) ;thetaUB 0<tub<180
    lowusw=usw lt 400. ;low usw
    lowmag=mag lt pui0.magthresh ;low mag (high error in B)
    lowtub=abs(costub) gt pui0.costubthresh ;low thetaUB < 14deg
    if sw10 then begin
      swimode=stat4.swi.mode ne 0. ;swia not in solar wind mode (unreliable velocity and density)
      swiatt=~finite(stat4.swi.att) ;use all swia att's
      swiqf=stat4.swi.qf lt pui0.swiqfthresh ;bad quality swia moments
      stat45=stat4
      stat4=stat4[where(~(lowmag or lowtub or swimode or swiatt or swiqf))]
      ;    stat4[where(stat4.sep[0].qf lt .3,/null)].sep[0].tot[0]=fnan ;more reliable SEP
      ;    stat4[where(stat4.sep[1].qf lt .3,/null)].sep[1].tot[0]=fnan ;more reliable SEP
      stat4[where(stat4.sep[0].qf lt .3 or stat4.sep[0].tot[0] lt 420./stat4.sep[0].att^6. or stat4.sep[0].tot[1] lt 420./stat4.sep[0].att^6. or stat4.sep[0].tot[2] gt 24./stat4.sep[0].att^6.,/null)].sep[0].tot[0]=fnan ;more reliable SEP
      stat4[where(stat4.sep[1].qf lt .3 or stat4.sep[1].tot[0] lt 420./stat4.sep[1].att^6. or stat4.sep[1].tot[1] lt 420./stat4.sep[1].att^6. or stat4.sep[1].tot[2] gt 24./stat4.sep[1].att^6.,/null)].sep[1].tot[0]=fnan ;more reliable SEP
    endif
    if sw6 then stat4[where(lowusw or lowmag or lowtub,/null)].d2m.sep=fnan ;more reliable SEP
    if 0 then begin ;plot upstream parameter histogram distributions
      nsw_hist=histogram(10.*stat4.swi.nsw)
      usw_hist=histogram(usw)
      mag_hist=histogram(1e10*mag)
      tub_hist=histogram(tub)
      p=plot(nsw_hist,xtitle='10*Nsw (cm-3)',/xlog)
      p=plot(usw_hist,xtitle='Usw (km/s)')
      p=plot(mag_hist,xtitle='10*MAG (nT)',/xlog)
      p=plot(tub_hist,xtitle='thetaUB (degrees)')
    endif
  endif

  if sw10 then stat4.sep.qf=stat4.sep.tot[1]/stat4.sep.tot[0] ;turn qf into d2m!

  if 1 then begin ;orbit averaging
    count2=n_elements(stat4)
    dt=stat4[1:-1].centertime-stat4[0:-2].centertime ;dt of samples (s), usually equal to binsize, unless no/bad data, orbit jump, or solar wind jump
    index2=where(dt gt 60.*60.*24.*10.,/null,swjumps) ;solar wind jumps (swjumps: number of time periods entirely inside the bowshock)
    index3=where(dt gt 60.*100.,/null,norbits) ;orbit jumps (norbits: number of orbits minus 1)
    ;  index3=where((stat4.centertime mod 1001) eq 0,/null,norbits) ;arbitrary time binning
    index4=lonarr(norbits+2) ;orbit edges
    index4[1:-2]=index3 ;last element of each orbit (except the very last orbit)
    index4[0]=-1 ;first orbit starting edge
    index4[-1]=count2-1 ;last orbit ending edge
    stat5=replicate(stat4[0],norbits+1) ;orbit average statistics

    for j=0,norbits do begin ;loop over orbits
      stat6=stat4[index4[j]+1:index4[j+1]]

      stat5[j].centertime=average(stat6.centertime,/nan)
      stat5[j].mag[0]=exp(average(alog(sqrt(total(stat6.mag^2,1))),/nan,stdev=stdev,nsamples=nsamples))
      stat5[j].mag[1]=stdev
      stat5[j].mag[2]=nsamples
      stat5[j].swi.vsw[0]=average(sqrt(total(stat6.swi.vsw^2,1)),/nan,stdev=stdev,nsamples=nsamples)
      stat5[j].swi.vsw[1]=stdev
      stat5[j].swi.vsw[2]=nsamples
      stat5[j].swi.nsw=exp(average(alog(stat6.swi.nsw),/nan,stdev=stdev,nsamples=nsamples))
      stat5[j].ifreq.pi=average(stat6.ifreq.pi,2,/nan,stdev=stdev,nsamples=nsamples)
      stat5[j].ifreq.ei=exp(average(alog(stat6.ifreq.ei),2,/nan,stdev=stdev,nsamples=nsamples))
      stat5[j].ifreq.cx=exp(average(alog(stat6.ifreq.cx),2,/nan,stdev=stdev,nsamples=nsamples))
      if sw6 then stat5[j].sep=exp(average(alog(stat6.sep),3,/nan,stdev=stdev,nsamples=nsamples))
      if sw10 then stat5[j].sep.qf=exp(average(alog(stat6.sep.qf),2,/nan,stdev=stdev,nsamples=nsamples))
      stat5[j].d2m.swi[0]=exp(average(alog(stat6.d2m.swi[0]),2,/nan,stdev=stdev,nsamples=nsamples,weight=stat6.d2m.swi[2]))
      stat5[j].d2m.swi[1]=exp(stdev)
      stat5[j].d2m.swi[2]=nsamples
      stat5[j].d2m.sta[0]=exp(average(alog(stat6.d2m.sta[0]),2,/nan,stdev=stdev,nsamples=nsamples,weight=stat6.d2m.sta[2]))
      stat5[j].d2m.sta[1]=exp(stdev)
      stat5[j].d2m.sta[2]=nsamples
      stat5[j].params[0]=average(stat6.params[0],/nan)
      stat5[j].params[1]=average(stat6.params[1],/nan)
    endfor
  end

  if 1 then begin ;arbitrary averaging of orbit averages
    range=minmax(stat4.centertime)
    ndays=(range[1]-range[0])/60./60./24. ;1day resolution
      ndays/=7. ;1week res
    nbins=ceil(ndays)
    stat6=stat5
    stat5=replicate(stat4[0],nbins)

    stat5.mag[0]=exp(average_hist(alog(stat6.mag[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.swi.vsw[0]=average_hist(stat6.swi.vsw[0],stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
    stat5.swi.nsw=exp(average_hist(alog(stat6.swi.nsw),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.ifreq[0].pi=average_hist(stat6.ifreq[0].pi,stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
    stat5.ifreq[1].pi=average_hist(stat6.ifreq[1].pi,stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
    stat5.ifreq[0].ei=exp(average_hist(alog(stat6.ifreq[0].ei),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.ifreq[1].ei=exp(average_hist(alog(stat6.ifreq[1].ei),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.ifreq[0].cx=exp(average_hist(alog(stat6.ifreq[0].cx),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.ifreq[1].cx=exp(average_hist(alog(stat6.ifreq[1].cx),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.sep[0].qf=exp(average_hist(alog(stat6.sep[0].qf),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.sep[1].qf=exp(average_hist(alog(stat6.sep[1].qf),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.d2m[0].swi[0]=exp(average_hist(alog(stat6.d2m[0].swi[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.d2m[1].swi[0]=exp(average_hist(alog(stat6.d2m[1].swi[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.d2m[0].sta[0]=exp(average_hist(alog(stat6.d2m[0].sta[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.d2m[1].sta[0]=exp(average_hist(alog(stat6.d2m[1].sta[0]),stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range))
    stat5.params[0]=average_hist(stat6.params[0],stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
    stat5.params[1]=average_hist(stat6.params[1],stat6.centertime,/nan,xbins=xbins,nbins=nbins,range=range)
    stat5.centertime=xbins
  endif

  if 0 then begin ;everything
    stat5=stat4
    stat5.mag[0]=sqrt(total(stat4.mag^2,1))
    stat5.swi.vsw[0]=sqrt(total(stat4.swi.vsw^2,1))
  endif

  ct=stat5.centertime
  ;stop
  ;store_data,'*',/delete
  if 1 then begin ;tplot stuff
    store_data,'pui_stat_mag',ct,1e9*stat5.mag[0]
    ;  ylim,'pui_stat_mag',.1,100,1
    ylim,'pui_stat_mag',1,20,1
    store_data,'pui_stat_usw',ct,stat5.swi.vsw[0]
    ylim,'pui_stat_usw',300,700,0
    store_data,'pui_stat_nsw',ct,stat5.swi.nsw
    ylim,'pui_stat_nsw',.1,100,1
    ylim,'pui_stat_nsw',.7,20,1

    store_data,'pui_stat_ifreq_pi',ct,transpose(stat5.ifreq.pi),limits={colors:'br',labels:['H','O'],labflag:1}
    ;  store_data,'pui_stat_ifreq_pi_O',ct,stat5.ifreq[1].pi,limits={ylog:1,yrange:[1e-8,1e-6]}
    store_data,'pui_stat_ifreq_cx',data={x:ct,y:transpose(stat5.ifreq.cx)},limits={ylog:1,yrange:[1e-8,1e-6],colors:'br',labels:['H','O'],labflag:1}
    ;  store_data,'pui_stat_ifreq_cx_H',data={x:ct,y:stat5.ifreq[0].cx},limits={ylog:1,yrange:[1e-8,1e-6]}
    ;  store_data,'pui_stat_ifreq_cx_O',data={x:ct,y:stat5.ifreq[1].cx},limits={ylog:1,yrange:[1e-8,1e-6]}
    store_data,'pui_stat_ifreq_ei',data={x:ct,y:transpose(stat5.ifreq.ei)},limits={ylog:1,yrange:[1e-9,1e-7],colors:'br',labels:['H','O'],labflag:1}
    ;  store_data,'pui_stat_ifreq_ei_H',data={x:ct,y:stat5.ifreq[0].ei},limits={ylog:1,yrange:[1e-8,1e-6]}
    ;  store_data,'pui_stat_ifreq_ei_O',data={x:ct,y:stat5.ifreq[1].ei},limits={ylog:1,yrange:[1e-8,1e-6]}
    ifreq=[[[stat5.ifreq.pi]],[[stat5.ifreq.cx]],[[stat5.ifreq.ei]]]
    ifreq_tot=total(ifreq,/nan,3)
    ifreq2=[[[ifreq[*,*,0]]],[[ifreq[*,*,1]]],[[ifreq[*,*,2]]],[[ifreq_tot]]]
    ;  store_data,'pui_stat_ifreq_H_tot',data={x:ct,y:reform(ifreq_tot[0,*])},limits={ylog:1,yrange:[1e-7,1e-6]}
    ;  store_data,'pui_stat_ifreq_O_tot',data={x:ct,y:reform(ifreq_tot[1,*])},limits={ylog:1,yrange:[1e-7,1e-6]}
    store_data,'pui_stat_ifreq_H',data={x:ct,y:reform(ifreq2[0,*,*])},limits={ylog:1,yrange:[1e-9,1e-6],colors:'brgk',labels:['PI','CX','EI','tot'],labflag:-1}
    store_data,'pui_stat_ifreq_O',data={x:ct,y:reform(ifreq2[1,*,*])},limits={ylog:1,yrange:[1e-9,1e-6],colors:'brgk',labels:['PI','CX','EI','tot'],labflag:-1}
    ;  ylim,'pui_stat_ifreq_*',1e-8,1e-7,0
    ;  options,'pui_stat_ifreq_pi_?','ystyle',1

    if sw6 then store_data,'pui_stat_d2m_sep1',ct,stat5.d2m[1].sep[0]
    if sw6 then store_data,'pui_stat_d2m_sep2',ct,stat5.d2m[1].sep[1]
    if sw10 then begin
      store_data,'pui_stat_d2m_sep',data={x:ct,y:transpose(stat5.sep.qf)},limits={colors:'br',labels:['SEP1','SEP2'],labflag:-1,psym:1}
      ;    store_data,'pui_stat_d2m_sep1',ct,stat5.sep[0].qf
      ;    store_data,'pui_stat_d2m_sep2',ct,stat5.sep[1].qf
      store_data,'pui_stat_d2m_H',data={x:ct,y:[[stat5.d2m[0].swi[0]],[stat5.d2m[0].sta[0]]]},limits={colors:'br',labels:['SWIA','STATIC'],labflag:1}
      store_data,'pui_stat_d2m_O',data={x:ct,y:[[stat5.d2m[1].swi[0]],[stat5.d2m[1].sta[0]]]},limits={colors:'br',labels:['SWIA','STATIC'],labflag:1}
      ;  store_data,'pui_stat_d2m_swi_H',ct,stat5.d2m[0].swi[0]
      ;  store_data,'pui_stat_d2m_sta_H',ct,stat5.d2m[0].sta[0]
      ;  store_data,'pui_stat_d2m_swi_O',ct,stat5.d2m[1].swi[0]
      ;  store_data,'pui_stat_d2m_sta_O',ct,stat5.d2m[1].sta[0]
      ylim,'pui_stat_d2m*',.1,10,1
      ;  ylim,'pui_stat_d2m_sep?',.01,100,1
      ;  options,'pui_stat_ifreq_pi_?','psym',3

      store_data,'pui_stat_Gyro_Period_(sec)',data={x:ct,y:transpose(stat5.params.tg)},limits={yrange:[1,1e3],ylog:1,labels:['H+','O+'],colors:'br',labflag:1,ytickunits:'scientific'}
      store_data,'pui_stat_Gyro_Radius_(1000km)',data={x:ct,y:transpose(stat5.params.rg/1e6)},limits={yrange:[.1,100],ylog:1,labels:['H+','O+'],colors:'br',labflag:1,ytickunits:'scientific'}
      store_data,'pui_stat_Max_Energy_(keV)',data={x:ct,y:transpose(stat5.params.kemax/1e3)},limits={yrange:[.1,300],ylog:1,labels:['H+','O+'],colors:'br',labflag:1,ytickunits:'scientific'}
      store_data,'pui_stat_Number_Density_(cm-3)',data={x:ct,y:[[transpose(stat5.params.totnnn)],[stat5.swi.nsw]]},limits={yrange:[.001,100],ylog:1,labels:['H+','O+','SWIA'],colors:'brg',labflag:1,ytickunits:'scientific'}
      store_data,'pui_stat_Number_Flux_(cm-2.s-1)',data={x:ct,y:transpose(stat5.params.totphi)},limits={yrange:[1e4,1e6],ylog:1,labels:['H+','O+'],colors:'br',labflag:1}
      store_data,'pui_stat_Momentum_Flux_(g.cm-1.s-2)',data={x:ct,y:transpose(stat5.params.totmph)},limits={yrange:[1e-11,1e-9],ylog:1,labels:['H+','O+'],colors:'br',labflag:1}
      store_data,'pui_stat_Energy_Flux_(eV.cm-2.s-1)',data={x:ct,y:transpose(stat5.params.toteph)},limits={yrange:[1e8,1e10],ylog:1,labels:['H+','O+'],colors:'br',labflag:1}

      tplot,'pui_stat_*'
    endif
  endif

  if 0 then begin
    sepr=sqrt(total(stat4.sep.xyz^2,1,/nan))
    ;  p=plot(stat4.sep[0].qf,reform(sepr[0,*])/1e3,'b.',/xlog,/ylog,xtitle='d/m',ytitle='Radial Distance (km)')
    ;  p=plot(stat4.sep[1].qf,reform(sepr[1,*])/1e3,'r.',/o)
    mvn_pui_radial_binner,reform(sepr[0,*]),stat4.sep[0].qf,r0,n0,std0,ste0
    mvn_pui_radial_binner,reform(sepr[1,*]),stat4.sep[1].qf,r1,n1,std1,ste1
    p=plot(n0,r0,'b',/o)
    p=plot(n1,r1,'r',/o)
    p=plot(n0*ste0,r0,'b--',/o)
    p=plot(n1*ste1,r1,'r--',/o)
    p=plot(n0/ste0,r0,'b--',/o)
    p=plot(n1/ste1,r1,'r--',/o)
    no=mvn_pui_exoden(1e3*r0,species='O') ;hot O density (cm-3)
    p=plot(no*mean([[n0],[n1]],dim=2,/nan),r0,'g',/o,name='SEP')
    sep1map=mvn_pui_2d_map(stat4.sep[0].xyz,stat4.sep[0].qf,100,/sep)
    sep2map=mvn_pui_2d_map(stat4.sep[1].xyz,stat4.sep[1].qf,100,/sep)
    p=image(alog10(sep1map),layout=[3,2,3],min=-1,max=1,margin=.1,rgb_table=colortable(33),axis_style=2,title='O SEP1',/current)
    mvn_pui_plot_mars_bow_shock,/half,/kkm
    p=image(alog10(sep2map),layout=[3,2,6],min=-1,max=1,margin=.1,rgb_table=colortable(33),axis_style=2,title='O SEP2',/current)
    mvn_pui_plot_mars_bow_shock,/half,/kkm
    p=colorbar(/orient)
  endif

  if 0 then begin
    mstr=['H','O'] ;mass string
    for im=0,1 do begin ;loop over mass 0:H, 1:O
      p=image(mean(alog10(stat2d.d2m.swi[im]),/nan,dim=3),layout=[3,2,1+im],/current,min=-1,max=1,margin=.1,rgb_table=colortable(33),axis_style=2,title=mstr[im]+' SWIA')
      mvn_pui_plot_mars_bow_shock,/half,/kkm
      p=image(mean(alog10(stat2d.d2m.sta[im]),/nan,dim=3),layout=[3,2,4+im],/current,min=-1,max=1,margin=.1,rgb_table=colortable(33),axis_style=2,title=mstr[im]+' STATIC')
      mvn_pui_plot_mars_bow_shock,/half,/kkm
      ;    p=colorbar(/orient)
    endfor

  endif

  if 0 then begin
    p=plot(stat5.mag[0],stat5.swi.vsw[0],'.',/xlog) ;imf vs vsw (no correlation)
    p=plot(stat5.mag[0],stat5.swi.nsw,'.',/xlog,/ylog) ;mag vs nsw (highly correlated)
    p=plot(stat5.swi.vsw[0],stat5.swi.nsw,'.',/ylog) ;vsw vs nsw (correlated)
    p=plot(stat5.ifreq[0].cx,stat5.ifreq[0].ei,'.b',/xlog,/ylog,xrange=[1e-8,1e-5],yrange=[1e-9,1e-6]) ;cx vs ei (correlated)
    p=plot(stat5.ifreq[1].cx,stat5.ifreq[1].ei,'.r',/o)
    p=plot(stat5.ifreq[0].cx,stat5.ifreq[0].pi,'.',/xlog,xrange=[1e-8,1e-5]) ;cx vs pi (not correlated)
    p=plot(stat5.ifreq[0].pi,stat5.ifreq[1].pi,'.') ;pi H vs O (correlated)
    p=plot(stat5.d2m[0].sta[0],stat5.d2m[1].sta[0],'.',/xlog,/ylog)
    p=plot(stat5.swi.vsw[0],stat5.sep[1],'.',/xlog,/ylog)
    p=plot(stat5.ifreq[1].pi,stat5.d2m[1].swi[0],'.b',xtitle=['PI freq (s-1)'],ytitle=['O d2m ratio'])
    p=plot(stat5.ifreq[1].pi,stat5.d2m[1].sta[0],'.r',/o,title='SWIA: blue, STATIC: red')
    p=plot(1e9*stat5.mag[0],stat5.d2m[1].sta[0],'.',/xlog,/ylog,yrange=[.1,10],xtitle=['MAG (nT)'],ytitle=['STATIC O d2m ratio'])
    p=plot(stat5.swi.vsw[0],stat5.d2m[1].sta[0],'.',/xlog,/ylog,yrange=[.1,10],xtitle=['Usw (km/s)'],ytitle=['STATIC O d2m ratio'])
    p=plot(stat5.swi.nsw,stat5.d2m[1].sta[0],'.',/xlog,/ylog,yrange=[.1,10],xtitle=['Nsw (cm-3)'],ytitle=['STATIC O d2m ratio'])
  endif

  if 0 then begin ;escape rate comparison
    p=plot(/o,6e25*stat5.d2m[0].swi[0],'b')
    p=plot(/o,6e25*stat5.d2m[0].sta[0],'r')
    p=plot(/o,6e32*stat5.ifreq[0].cx,'g')
  endif

  if 0 then begin ;escape rate vs. Ls
    mvn_pui_au_ls,times=ct,mars_au=mars_au,mars_ls=mars_ls,spice=0
    staswi=(stat5.d2m.sta[0]+stat5.d2m.swi[0])/2.
    sep12=mean(stat5.sep.qf,dim=1,/nan)
    staswisep12=mean([[reform(staswi[1,*])],[sep12]],/nan,dim=2)
    h2o=6./7.*mean(staswi[0,*]/staswisep12,/nan)
    have=6e25*mean(staswi[0,*],/nan)
    oave=7e25*mean(staswisep12,/nan)
    h2o2=have/oave
    p=plot([0],/nodata,xrange=[0,360],yrange=[1e25,1e27],/ylog,xtitle='$Solar Longitude ( L_s )$',ytitle='Weekly Averaged Neutral Escape Rate ($s^{-1}$)',xtickinterval=90,xminor=8,xticklen=.5,xsubticklen=.05,xgridstyle=1)
    p=plot(/o,mars_ls,6e25*staswi[0,*],'b',name='H')
    p=plot(/o,mars_ls,7e25*staswisep12,'r',name='O')
    p=legend()
    p=plot(/o,[71,71],[1e25,1e27],'c') ;aphelion
    p=plot(/o,[251,251],[1e25,1e27],'m') ;perihelion
    ;p=plot([0],/nodata,xrange=[0,360],yrange=[1e25,1e27],/ylog,xtitle='$L_s$',ytitle='H escape rate ($s^{-1}$)',xtickinterval=90)
    ;p=plot(/o,mars_ls,6e25*stat5.d2m[0].sta[0],'r',name='STATIC')
    ;p=plot(/o,mars_ls,6e25*stat5.d2m[0].swi[0],'b',name='SWIA')
    ;p=legend()
    ;p=plot([0],/nodata,xrange=[0,360],yrange=[1e25,1e27],/ylog,xtitle='$L_s$',ytitle='O escape rate ($s^{-1}$)',xtickinterval=90)

    ;p=plot(/o,mars_ls,7e25*stat5.d2m[1].sta[0],'r',name='STATIC')
    ;p=plot(/o,mars_ls,7e25*stat5.d2m[1].swi[0],'b',name='SWIA')
    ;p=legend()
    ;p=scatterplot(/o,mars_ls,6e25*(stat5.d2m[0].sta[0]+stat5.d2m[0].swi[0])/2.,magnitude=ct,rgb=33)
  endif

  if 0 then begin ;sta/swi ratios
    p=plot(ct,stat5.d2m[0].sta[0]/stat5.d2m[0].swi[0],'b',/ylog,yrange=[.1,10],/stairs)
    p=plot(ct,stat5.d2m[1].sta[0]/stat5.d2m[1].swi[0],'r',/o,/stairs)
  endif

  if 0 then begin ;sep qf vs. d2m ratios
    p=plot([0],/nodata,/ylog,xtitle='Quality Flag',ytitle='SEP d2m Ratio',yrange=[1e-3,1e3])
    p=plot(/o,stat5.sep[0].qf,stat5.sep[0].tot[1]/stat5.sep[0].tot[0],'b.',name='SEP1F')
    p=plot(/o,stat5.sep[1].qf,stat5.sep[1].tot[1]/stat5.sep[1].tot[0],'r.',name='SEP2F')
    p=legend()
  endif

  if 0 then begin ;sep d2m ratio vs. birth distance
    p=plot([0],/nodata,/xlog,/ylog,xtitle='SEP d2m Ratio',ytitle='Radial Distance (km)')
    p=plot(/o,stat5.sep[0].qf,1e-3*sqrt(total((stat5.sep[0].xyz)^2,1)),'b.',name='SEP1F')
    p=plot(/o,stat5.sep[1].qf,1e-3*sqrt(total((stat5.sep[1].xyz)^2,1)),'r.',name='SEP2F')
  endif

  if 0 then begin ;sep d2m ratio vs. birth sza
    p=plot([0],/nodata,/ylog,xtitle='SZA',ytitle='SEP d2m Ratio')
    p=plot(/o,!radeg*mvn_pui_sza(stat5.sep[0].xyz[0],stat5.sep[0].xyz[1],stat5.sep[0].xyz[2]),stat5.sep[0].qf,'b.',name='SEP1F')
    p=plot(/o,!radeg*mvn_pui_sza(stat5.sep[1].xyz[0],stat5.sep[1].xyz[1],stat5.sep[1].xyz[2]),stat5.sep[1].qf,'r.',name='SEP2F')
    p=legend()
  endif

  if 0 then begin ;sep d2m ratio vs. model count rate
    p=plot([0],/nodata,/xlog,/ylog,xtitle='model count rate (1/s)',ytitle='SEP d2m Ratio')
    p=plot(/o,stat5.sep[0].tot[0]*stat4.sep[0].att^6.,stat5.sep[0].qf,'b.',name='SEP1F')
    p=plot(/o,stat5.sep[1].tot[0]*stat4.sep[1].att^6.,stat5.sep[1].qf,'r.',name='SEP2F')
    p=legend()
  endif

  if 0 then begin ;sep d2m ratio vs. data count rate
    p=plot([0],/nodata,/xlog,/ylog,xtitle='data count rate (1/s)',ytitle='SEP d2m Ratio')
    p=plot(/o,stat5.sep[0].tot[1]*stat4.sep[0].att^6.,stat5.sep[0].qf,'b.',name='SEP1F')
    p=plot(/o,stat5.sep[1].tot[1]*stat4.sep[1].att^6.,stat5.sep[1].qf,'r.',name='SEP2F')
    p=legend()
  endif

  if 0 then begin ;sep d2m ratio vs. cme count rate
    p=plot([0],/nodata,/xlog,/ylog,xtitle='CME count rate (1/s)',ytitle='SEP d2m Ratio')
    p=plot(/o,stat5.sep[0].tot[2]*stat4.sep[0].att^6.,stat5.sep[0].qf,'b.',name='SEP1F')
    p=plot(/o,stat5.sep[1].tot[2]*stat4.sep[1].att^6.,stat5.sep[1].qf,'r.',name='SEP2F')
    p=legend()
  endif

  if 0 then begin
    p=plot([0],/nodata,/xlog,/ylog,xtitle='MAG (nT)',ytitle='SEP d2m Ratio')
    p=plot(/o,1e9*stat5.mag[0],stat5.sep[0].qf,'b.',name='SEP1F')
    p=plot(/o,1e9*stat5.mag[0],stat5.sep[1].qf,'r.',name='SEP2F')
    p=legend()
  endif

  if 0 then begin
    p=plot([0],/nodata,/ylog,xtitle='Usw (km/s)',ytitle='SEP d2m Ratio')
    p=plot(/o,stat5.swi.vsw[0],stat5.sep[0].qf,'b.',name='SEP1F')
    p=plot(/o,stat5.swi.vsw[0],stat5.sep[1].qf,'r.',name='SEP2F')
    p=legend()
  endif

  alswi=exp(average(alog(stat5.d2m.swi[0]),2,/nan))
  alsta=exp(average(alog(stat5.d2m.sta[0]),2,/nan))
  avswi=average(stat5.d2m.swi[0],2,/nan)
  avsta=average(stat5.d2m.sta[0],2,/nan)
  ;stop
end