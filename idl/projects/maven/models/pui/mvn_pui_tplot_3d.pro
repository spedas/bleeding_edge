;20170424 Ali
;takes care of 3d tplots and plots

pro mvn_pui_tplot_3d,store=store,tplot=tplot,trange=trange,swia3d=swia3d,stah3d=stah3d,stao3d=stao3d,lineplot=lineplot,$
  datimage=datimage,modimage=modimage,d2mimage=d2mimage,nowin=nowin,denprof=denprof,d2mqf=d2mqf,denmap=denmap

  @mvn_pui_commonblock.pro ;common mvn_pui_common
  centertime=pui.centertime

  if ~pui0.do3d then begin
    dprint,'For 3D analysis, please run mvn_pui_model,/do3d first. returning...'
    return
  endif
  if keyword_set(swia3d) || keyword_set(stah3d) || keyword_set(stao3d) then switch3d=1 else switch3d=0
  if n_elements(lineplot) ne 0 or keyword_set(datimage) or keyword_set(modimage) or keyword_set(d2mimage) then img=1 else img=0

  if keyword_set(store) or img or keyword_set(denprof) or keyword_set(d2mqf) or keyword_set(denmap) then begin
    if keyword_set(swics) then begin
      ;swap swia dimentions to match the model (time-energy-az-el)
      ;also, reverse the order of elevation (deflection) angles to start from positive theta (like static)
      swiaef3d=reverse(transpose(pui.data.swi.swica.data,[3,0,2,1]),4)
      swicaen=transpose(info_str[pui.data.swi.swica.info_index].energy_coarse)
    endif else begin
      swiaef3d=replicate(!values.f_nan,[pui0.nt,pui0.swieb,pui0.swina,pui0.swine])
      swicaen=pui1.swiet
    endelse

    d1eflux=transpose(pui.data.sta.d1.eflux[*,*,*,[0,4]],[4,0,1,2,3]) ;mass channel 0:Hydrogen, 4:Oxygen
    d1energy=transpose(pui.data.sta.d1.energy)
    swind=where(finite(swiaef3d[*,0,0,0]),/null,swcount) ;no archive available index
    d1ind=where(finite(d1energy[*,0]),/null,d1count) ;no d1 available index
    minswi=pui0.minpara*mvn_pui_min_eflux(swiaef3d) ;min over energy and elevation dimensions
    minsta=pui0.minpara*mvn_pui_min_eflux(d1eflux) ;min over energy and elevation dimensions

    kefswi=transpose(pui.model.fluxes.swi3d.eflux,[4,0,1,2,3]) ;pickup model energy flux
    kefsta=transpose(pui.model.fluxes.sta3d.eflux,[4,0,1,2,3])
    kqfswi=transpose(pui.model.fluxes.swi3d.qf,[4,0,1,2,3]) ;pickup model quality flag
    kqfsta=transpose(pui.model.fluxes.sta3d.qf,[4,0,1,2,3])
    krvswi=transpose(pui.model.fluxes.swi3d.rv,[5,1,2,3,4,0]) ;pickup position,velocity
    krvsta=transpose(pui.model.fluxes.sta3d.rv,[5,1,2,3,4,0])
    krrswi=sqrt(total(krvswi[*,*,*,*,*,0:3]^2,6))/1e3 ;pickup radial distance (km)
    krrsta=sqrt(total(krvsta[*,*,*,*,*,0:3]^2,6))/1e3

    mstr=['H','O'] ;mass string
    frmtstr=[['b.','r.'],['c.','m.']] ;plot format string [[H swi,O swi],[H sta,O sta]]
    ebinlim=[[37,17],[17,8]] ;energy bin lower limit for [[H swi,O swi],[H sta,O sta]], lower limit energy: [H,O]=[110,2000]keV
    dim3d=pui0.swina*pui0.swine*(ebinlim+1) ;used to create tplots of all energy/anode/elevation d2m's

    get_data,'mvn_alt_sw_(km)',data=alt_sw
    if keyword_set(alt_sw) and keyword_set(swim) then begin
      goodsw=finite(alt_sw.y)
      swimode=pui.data.swi.swim.swi_mode eq 0 ;swia in solar wind mode
      swiqf=pui.data.swi.swim.quality_flag gt pui0.swiqfthresh ;good quality swia moments
      vsw=pui.data.swi.swim.velocity_mso
      usw=sqrt(total(vsw^2,1)) ;solar wind speed (km/s)
      mag=pui.data.mag.mso
      imf=sqrt(total(mag^2,1)) ;magnetic field (T)
      costub=total(vsw*mag,1)/(usw*imf) ;cos(thetaUB)
      tub=!radeg*acos(costub) ;thetaUB 0<tub<180
      himag=imf gt pui0.magthresh ;high mag (low error in B)
      hitub=abs(costub) lt pui0.costubthresh ;thetaUB > 14deg
      swindex=where(goodsw and swimode and swiqf and himag and hitub,/null) ;only good solar wind
    endif else swindex=!null

    ;get rid of too low model and data flux (below detection threshold) and too high data flux (solar wind)
    kefsta2=kefsta
    kefsta[where((kefsta lt minsta) or (d1eflux lt minsta) or (d1eflux gt pui0.maxthre),/null)]=0.
    knnsta=d1eflux/kefsta

    if keyword_set(denprof) then p=plot([0],/nodat,/xlog,/ylog,xtitle='d2m Ratio',ytitle='Altitude (km)')
    if keyword_set(denmap) then p=window()
    if keyword_set(d2mqf) then p=plot([0],/nodat,/ylog,xtitle='Quality Flag',ytitle='d2m Ratio')

    for im=0,1 do begin ;loop over mass 0:H, 1:O
      kefswim=kefswi[*,*,*,*,im]
      kefswim[where((kefswim lt minswi) or (swiaef3d lt minswi) or (swiaef3d gt pui0.maxthre),/null)]=0.
      knnswi=swiaef3d/kefswim/(~kefswi[*,*,*,*,~im]) ;exospheric neutral density (cm-3) data/model ratio
      knnswi2=knnswi[*,0:ebinlim[im,0],*,*]
      knnsta2=knnsta[*,0:ebinlim[im,1],*,*,im]
      logswi=alog(reform(knnswi2,[pui0.nt,dim3d[im,0]]))
      logsta=alog(reform(knnsta2,[pui0.nt,dim3d[im,1]]))
      avgswi=exp(average(logswi,2,stdev=sswi,nsamples=nswi,/nan))
      avgsta=exp(average(logsta,2,stdev=ssta,nsamples=nsta,/nan))
      pui.d2m[im].swi[0]=avgswi
      pui.d2m[im].sta[0]=avgsta
      pui.d2m[im].swi[1]=exp(sswi)
      pui.d2m[im].sta[1]=exp(ssta)
      pui.d2m[im].swi[2]=nswi
      pui.d2m[im].sta[2]=nsta

      if keyword_set(store) then begin
        t3dswi=dgen(pui0.nt*dim3d[im,0],range=timerange(pui0.trange))
        t3dsta=dgen(pui0.nt*dim3d[im,1],range=timerange(pui0.trange))
        if swcount gt 0 then store_data,'mvn_d2m_ratio_avg_swia_'+mstr[im],data={x:centertime[swind],y:avgswi[swind]},limits={ylog:1,colors:'r'}
        if d1count gt 0 then store_data,'mvn_d2m_ratio_avg_stat_'+mstr[im],data={x:centertime[d1ind],y:avgsta[d1ind]},limits={ylog:1,colors:'r'}
        store_data,'mvn_d2m_ratio_all_swia_'+mstr[im],data={x:t3dswi,y:reform(transpose(knnswi2),pui0.nt*dim3d[im,0])},limits={ylog:1,psym:3}
        store_data,'mvn_d2m_ratio_all_stat_'+mstr[im],data={x:t3dsta,y:reform(transpose(knnsta2),pui0.nt*dim3d[im,1])},limits={ylog:1,psym:3}
        store_data,'mvn_d2m_ratio_swia_'+mstr[im],data=['mvn_d2m_ratio_all_swia_'+mstr[im],'mvn_d2m_ratio_avg_swia_'+mstr[im],'mvn_pui_line_1'],limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}
        store_data,'mvn_d2m_ratio_stat_'+mstr[im],data=['mvn_d2m_ratio_all_stat_'+mstr[im],'mvn_d2m_ratio_avg_stat_'+mstr[im],'mvn_pui_line_1'],limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}
      endif

      if keyword_set(swindex) then begin
        pui3.swi[im]=mvn_pui_2d_map(krvswi[swindex,0:ebinlim[im,0],*,*,im,*],knnswi2[swindex,*,*,*],pui0.d2mmap)
        pui3.sta[im]=mvn_pui_2d_map(krvsta[swindex,0:ebinlim[im,1],*,*,im,*],knnsta2[swindex,*,*,*],pui0.d2mmap)
        if keyword_set(denprof)then begin
          p=plot(knnswi2[swindex,*,*,*],krrswi[swindex,0:ebinlim[im,0],*,*,im]-pui0.rmars,/o,frmtstr[im,0],name=mstr[im]+' SWIA')
          p=plot(knnsta2[swindex,*,*,*],krrsta[swindex,0:ebinlim[im,1],*,*,im]-pui0.rmars,/o,frmtstr[im,1],name=mstr[im]+' STATIC')
        endif
        if keyword_set(denmap)then begin
          p=image(alog10(pui3.swi[im]),layout=[2,2,1+im],/current,min=-1,max=1,margin=.1,rgb_table=colortable(33),axis_style=2,title=mstr[im]+' SWIA d2m')
          mvn_pui_plot_mars_bow_shock,/half,/kkm
          p=image(alog10(pui3.sta[im]),layout=[2,2,3+im],/current,min=-1,max=1,margin=.1,rgb_table=colortable(33),axis_style=2,title=mstr[im]+' STATIC d2m')
          mvn_pui_plot_mars_bow_shock,/half,/kkm
        endif
        if keyword_set(d2mqf) then begin
          p=plot(kqfswi[swindex,0:ebinlim[im,0],*,*,im],knnswi2[swindex,*,*,*],/o,frmtstr[im,0],name=mstr[im]+'+ SWIA')
          p=plot(kqfsta[swindex,0:ebinlim[im,1],*,*,im],knnsta2[swindex,*,*,*],/o,frmtstr[im,1],name=mstr[im]+'+ STATIC')
        endif
      endif
    endfor

    if keyword_set(denprof) or keyword_set(d2mqf) then begin
      p=legend()
      p=text(0,0,time_string(pui0.trange))
    endif

    if keyword_set(denmap) then begin
      p=colorbar(/orient)
      p=text(0,0,time_string(pui0.trange))
    endif

    if keyword_set(store) and switch3d then begin
      store_data,'mvn_s*_model*_A*D*',/delete
      store_data,'mvn_s*_data*_A*D*',/delete
      dprint,dlevel=2,'Creating 3D tplots. This will take a few seconds to complete...'
      verbose=0
    endif

    if img and ~keyword_set(nowin) then p=window(background_color='k',dim=[400,200])
    mrgn=.01
    rgbt=33
    kefswimo=total(kefswi,5) ;swia model all masses
    if n_elements(lineplot) ne 0 then begin
      minswia=average(minswi[lineplot,*,*,*],1,/nan)
      kefswia=average(kefswi[lineplot,*,*,*,*],1,/nan)
      swiaefa=average(swiaef3d[lineplot,*,*,*],1,/nan)
      minstaa=average(minsta[lineplot,*,*,*,*],1,/nan)
      kefstaa=average(kefsta2[lineplot,*,*,*,*],1,/nan)
      d1eflua=average(d1eflux[lineplot,*,*,*,*],1,/nan)
      kefswia[where(~finite(alog(kefswia)),/null)]=1e-7
      swiaefa[where(~finite(alog(swiaefa)),/null)]=1e-7
      kefstaa[where(~finite(alog(kefstaa)),/null)]=1e-7
      d1eflua[where(~finite(alog(d1eflua)),/null)]=1e-7
      d1en=average(d1energy[lineplot,*],1,/nan)
    endif

    if keyword_set(trange) then begin
      trange=time_double(trange)
      tstep=floor((trange-pui[0].centertime+pui0.tbin/2.)/pui0.tbin)
    endif else tstep=[0,pui0.nt-1]
    tsteps=lindgen(1l+tstep[1]-tstep[0],start=tstep[0])

    for j=0,pui0.swina-1 do begin ;loop over azimuth bins (phi)
      for k=0,pui0.swine-1 do begin ;loop over elevation bins (theta): + to - theta goes left to right on the screen
        jj=15-((j+9) mod 16) ;to sort vertical placement of tplot panels: center is usually sunward for swia (x-axis for both swia and static)
        lojk=[4,16,1+k+j*4]

        if keyword_set(swia3d) then begin
          swimjk=kefswimo[tsteps,*,jj,k]
          swidjk=swiaef3d[tsteps,*,jj,k]
          if n_elements(lineplot) ne 0 then begin
            p=plot([0],/nodata,/xlog,/ylog,xrange=[20.,30e3],yrange=[1e3,1e9],layout=lojk,/current,margin=mrgn,background_color='w')
            p=plot(pui1.swiet,minswia[*,jj,k],/stairs,/o,color='c') ;data threshold
            p=plot(pui1.swiet,swiaefa[*,jj,k],/stairs,/o,color='g') ;data
            p=plot(pui1.swiet,kefswia[*,jj,k,0],/stairs,/o,color='b') ;model H+
            p=plot(pui1.swiet,kefswia[*,jj,k,1],/stairs,/o,color='r') ;model O+
          endif
          if keyword_set(modimage) then p=image(alog10(swimjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(swidjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(swidjk/swimjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_swia_model_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime[tsteps],swimjk,pui1.swiet,verbose=verbose
            store_data,'mvn_swia_data_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime[tsteps],swidjk,swicaen,verbose=verbose
            options,'mvn_swia*_A*D*',spec=1,ytickunits='scientific'
            ylim,'mvn_swia*_A*D*',25.,25e3,1
            zlim,'mvn_swia*_A*D*',1e4,1e8,1
          endif
        endif

        if keyword_set(stao3d) then begin
          statjk=kefsta2[tsteps,*,jj,k,1]
          d1efjk=d1eflux[tsteps,*,jj,k,1]
          if n_elements(lineplot) ne 0 then begin
            p=plot([0],/nodata,/xlog,/ylog,xrange=[1.,40e3],yrange=[1e3,1e9],layout=lojk,/current,margin=mrgn,background_color='w')
            p=plot(d1en,minstaa[*,jj,k,1],/stairs,/o,color='m') ;data O+ threshold
            p=plot(d1en,d1eflua[*,jj,k,1],/stairs,/o,color='g') ;data O+
            p=plot(d1en,kefstaa[*,jj,k,1],/stairs,/o,color='r') ;model O+
          endif
          if keyword_set(modimage) then p=image(alog10(statjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(d1efjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(d1efjk/statjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_stat_model_puo_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime[tsteps],statjk,d1energy[tsteps,*],verbose=verbose
            store_data,'mvn_stat_data_HImass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime[tsteps],d1efjk,d1energy[tsteps,*],verbose=verbose
          endif
        endif

        if keyword_set(stah3d) then begin
          statjk=kefsta2[tsteps,*,jj,k,0]
          d1efjk=d1eflux[tsteps,*,jj,k,0]
          if n_elements(lineplot) ne 0 then begin
            p=plot([0],/nodata,/xlog,/ylog,xrange=[1.,40e3],yrange=[1e3,1e9],layout=lojk,/current,margin=mrgn,background_color='w')
            p=plot(d1en,minstaa[*,jj,k,0],/stairs,/o,color='m') ;data H+ threshold
            p=plot(d1en,d1eflua[*,jj,k,0],/stairs,/o,color='g') ;data H+
            p=plot(d1en,kefstaa[*,jj,k,0],/stairs,/o,color='b') ;model H+
          endif
          if keyword_set(modimage) then p=image(alog10(statjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(d1efjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(d1efjk/statjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_stat_model_puh_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime[tsteps],statjk,d1energy[tsteps,*],verbose=verbose
            store_data,'mvn_stat_data_LOmass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime[tsteps],d1efjk,d1energy[tsteps,*],verbose=verbose
          endif
        endif
      endfor
    endfor

    if keyword_set(store) and switch3d then begin
      options,'mvn_stat*_A*D*',spec=1,ytickunits='scientific'
      ylim,'mvn_stat*_A*D*',10.,35e3,1
      zlim,'mvn_stat*_A*D*',1e4,1e8,1
    endif

  endif

  if keyword_set(swia3d) then begin
    swiastat='swia'
    modelmass=''
    datamass=''
  endif

  if keyword_set(stah3d) then begin
    swiastat='stat'
    modelmass='_puh'
    datamass='_LOmass'
  endif

  if keyword_set(stao3d) then begin
    swiastat='stat'
    modelmass='_puo'
    datamass='_HImass'
  endif

  if switch3d and keyword_set(tplot) then begin
    !p.background=2
    !p.color=-1
    xsize=480
    ysize=1000
    for iw=0,3 do begin
      wi,iw+1,wsize=[xsize,ysize],wposition=[iw*xsize,0]
      wi,iw+5,wsize=[xsize,ysize],wposition=[iw*xsize,0]
      tplot,'mvn_'+swiastat+'_data'+datamass+'_A*D'+strtrim(iw,2),window=iw+1
      tplot,'mvn_'+swiastat+'_model'+modelmass+'_A*D'+strtrim(iw,2),window=iw+5
    endfor
    !p.background=-1
    !p.color=0
  endif
  ;stop
end
