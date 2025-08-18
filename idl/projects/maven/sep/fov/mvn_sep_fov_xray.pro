;20180413 Ali
;plots sco x-1 x-ray count rates vs. sep fov map

pro mvn_sep_fov_xray,det=det,sep=sep,sld=sld,occ=occ,spec=spec,fov=fov,ebin=ebin,trange=trange,save=save,mvnalt=mvnalt,tanalt=tanalt,ylog=ylog,bx=bx
  ;det: detector ['A-O','A-T','A-F','B-O','B-T','B-F']
  ;sep: 0=sep1, 1=sep2
  ;sld: sep look-direction: 0:front, 1:rear
  ;occ: occultation analysis and curve-fit
  ;spec: energy response
  ;fov: fov response
  ;alt: altitude above which to do occultation analysis
  ;tanalt: occultation tangent altitude range
  ;bx: [background counts,x-ray counts]

  @mvn_sep_fov_common.pro
  @mvn_sep_handler_commonblock.pro

  if ~keyword_set(mvn_sep_fov) then begin
    dprint,'sep fov data not loaded. Please run mvn_sep_fov first! returning...'
    return
  endif

  detlab=mvn_sep_fov0.detlab
  pos   =mvn_sep_fov.pos
  pdm   =mvn_sep_fov.pdm
  tal   =mvn_sep_fov.tal
  crh   =mvn_sep_fov.crh
  crl   =mvn_sep_fov.crl
  att   =mvn_sep_fov.att
  times =mvn_sep_fov.time

  if n_elements(sep) eq 0 then sep=0
  if n_elements(det) eq 0 then det=0
  if n_elements(sld) eq 0 then sld=0 ;look direction 0:front 1:rear

  watt=att[sep,*] eq 1. ;open attenuator
  wtal=tal[0,*].sx1 gt 100. ;sco x1 not behind mars
  wpos=([1.,-1.])[sld]*pos[sep*2,*].sx1 gt .97 ;within 14 degrees of center of fov
  wcrl=finite(crl[sep,det,*]) ;finite x-ray counts
  wcrh=crh[sep,det,*] lt 1. ;low background
  wmsh=([-1,0,0,1,0,0])[det]*pos[sep*2,*].mar lt cos(acos(pdm.mar)+20.*!dtor) ;no mars shine
  if keyword_set(trange) then begin
    wtime=times gt trange[0] and times lt trange[1]
    times=times[where(wtime)]
  endif else wtime=1
  ;  wsun=pos[0,*].sun
  ;  wcr3=crl[sep,det,*] gt 1.
  map1=mvn_sep_get_bmap(9,sep+1)
  if mvn_sep_fov0.arc then sepn= sep ? *(sep2_arc.x) : *(sep1_arc.x) else sepn= sep ? *(sep2_svy.x) : *(sep1_svy.x)

  if keyword_set(occ) then begin
    if ~keyword_set(mvnalt) then mvnalt=1000.
    hialt=tal[2,*].mar gt mvnalt
    ;    hialt=1
    if ~keyword_set(tanalt) then tanalt=[-50.,200.]
    wtal=tal[2,*].sx1 gt tanalt[0] and tal[2,*].sx1 lt tanalt[1]
    ;    wtal=1
    whr=where(hialt and wtal and wpos and watt and wtime,/null,nwhr)
    if nwhr eq 0 then message,'no occultation found!'
    p=getwindows('mvn_sep_xray_occ')
    if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_xray_occ')
    p.erase
    p=plot(/current,[0],/nodat,xrange=tanalt,ytitle='SEP'+strtrim(sep+1,2)+detlab[det]+' Count Rate (Hz)',xtitle='Sco X-1 Tangent Altitude (km)')
    p=plot(/o,tal[2,whr].sx1,crl[sep,det,whr],'r1.',ylog=ylog,name='data')
    crav=average_hist(crl[sep,det,whr],tal[2,whr].sx1,binsize=5.,xbins=taltsx1bin,/nan,stdev=stdev,hist=hist)
    p=errorplot(/o,taltsx1bin,crav,stdev/sqrt(hist),name='mean','D')
    p=text(0,0,time_string(minmax(times[whr])))
    if ~keyword_set(bx) then bx=[.67,2.] ;for 2018-03-12 occultation analysis
    mvn_sep_fov_xray_model,bx=bx,whr=whr,fit=reform(crl[sep,det,whr])
 
    if keyword_set(ebin) then begin
      ind=where(map1.name eq detlab[det],nen,/null)
      ind0=ind[ebin]
      if sep eq 0 then sepdat=sepn.data[ind0]/sepn.delta_time else sepdat=interpol(sepn.data[ind0]/sepn.delta_time,sepn.time,times,/nan)
      mvn_sep_fov_xray_fit,reform(tal[2,whr].sx1),reform(sepdat[whr]),param=param
    endif else mvn_sep_fov_xray_fit,reform(tal[2,whr].sx1),reform(crl[sep,det,whr]),param=param
    p=legend()
    return
  endif

  if keyword_set(spec) then begin
    wpo0=abs(pos[sep*2,*].sx1) lt .5 ;out of fov: for background calculation
    p=getwindows('mvn_sep_xray_spec')
    if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_xray_spec')
    p.erase
    p=plot([0],/nodata,/xlog,/ylog,/current,xrange=[10,100],yrange=[.001,1],title='Sco X-1 X-ray Response for SEP'+strtrim(sep+1,2)+' '+(['Front','Rear'])[sld],xtitle='Deposited Energy (keV)',ytitle='Count Rate (Hz)')
    ndet=n_elements(detlab)
    for idet=0,ndet-1 do begin
      wcrl=finite(crl[sep,idet,*]) ;finite x-ray counts
      wcrh=crh[sep,idet,*] lt 1. ;low background
      whr=where(wcrl and wcrh and watt and wtal and wmsh and wpos and wtime,/null) ;where good signal
      wh0=where(wcrl and wcrh and watt and wtal and wmsh and wpo0 and wtime,/null) ;where background
      ind=where(map1.name eq detlab[idet],nen,/null)
      sepspec=mean(sepn[whr].data[ind]/(replicate(1.,nen)#sepn[whr].delta_time),dim=2,/nan) ;in fov count rate
      sepspe0=mean(sepn[wh0].data[ind]/(replicate(1.,nen)#sepn[wh0].delta_time),dim=2,/nan) ;background
      sepspe1=sepspec-sepspe0 ;background subtracted spectra
      sepspe1[where(sepspe1 lt 0.,/null)]=1e-10 ;low counts (to prevent idl plotting routine to mess up negative numbers)
      p=plot(/o,map1[ind].nrg_meas_avg,sepspe1,/stairs,color=mvn_sep_fov0.detcol[idet],name=detlab[idet])
    endfor
    p=legend()
    p=text(0,0,time_string(minmax(times)))
    if keyword_set(save) then p.save,resolution=150,'/home/rahmati/Desktop/sep/sep x-rays/energy response/sep'+strtrim(sep+1,2)+(['Front','Rear'])[sld]+'_xray_energy_response.png'
    return
  endif

  if keyword_set(fov) then begin
    wher=where(wcrl and wcrh and watt and wtal and wmsh,/null) ;where good signal
    range=[-1.,1.]
    crscaled=bytscl(alog10(reform(crl[sep,det,wher])),min=range[0],max=range[1])
    mvn_sep_fov_plot,pos=pos[*,wher].sx1,cr=crscaled
    p=text(.02,.13,time_string(minmax(times)))
    p=colorbar(rgb=33,range=range,title='log10[SEP'+strtrim(sep+1,2)+' '+detlab[det]+' Count Rate (Hz)]',position=[0.5,.1,0.9,.15])
    if keyword_set(save) then p.save,resolution=150,'/home/rahmati/Desktop/sep/sep x-rays/fov response/sep'+strtrim(sep+1,2)+mvn_sep_fov0.detlab[det]+'_xray_fov_response.png'
  endif

end