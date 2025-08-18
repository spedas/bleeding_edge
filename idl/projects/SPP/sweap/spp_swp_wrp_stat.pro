;Ali: June 2020
;spp_swp_wrp_stat,apid
;if no apid is set, shows all stats
;for wrapper apids, shows stats for their content_apid.
;for the rest of the apids, shows which wrapper apids they are routed to.
;typically run after loading SSR or PTP files (spp_ssr_file_read or spp_ptp_file_read)
;can also show stats for swem_wrp L1 cdf files using keywords 'load' (used once to load cdf files) and 'cdf'
;group: sequence group: 0:middle of multipacket (very rare, huge packets? usually sign of error) 1:start of multi-packet 2:end of multi-packet 3:single packet
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2024-02-27 18:50:02 -0800 (Tue, 27 Feb 2024) $
; $LastChangedRevision: 32464 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/spp_swp_wrp_stat.pro $
;-

pro spp_swp_wrp_stat,load=load,cdf=cdf,ptp=ptp,apid,capid=capid0,noheader=noheader,stats=stats,all=all,comp=comp,group=group,trange=trange,tplot_comp_ratio=tplot_comp_ratio,original_time=original_time

  spp_swp_apdat_init
  apr=[0,'7ff'x] ;range of all apids: to check for possible bad packets
  if keyword_set(all) then apr=['340'x,'3c0'x] ;range of sweap apids
  wapr=['348'x,'34f'x] ;range of wrapper apids
  aprs=orderedhash('spc_ALL',['351'x,'35f'x],'spa_ALL',['360'x,'36f'x],'spb_ALL',['370'x,'37f'x],'spe_ALL',['360'x,'37f'x],'spi_ALL',['380'x,'3bf'x],$
    'spa_archive',['360'x,'363'x],'spb_archive',['370'x,'373'x],'spi_archive',['380'x,'397'x],$
    'spa_survey' ,['364'x,'36f'x],'spb_survey' ,['374'x,'37f'x],'spi_survey' ,['398'x,'3bf'x],'TOTAL',apr)
  stat={nca:0ull,tot:0d,tdt:0d,tod:0d}
  stats=replicate(stat,apr[1]-apr[0]+1)

  if ~isa(apid) then begin
    stats2=replicate(stat,[apr[1]-apr[0]+1,wapr[1]-wapr[0]+1])
    names=replicate('',wapr[1]-wapr[0]+1)
    for wapid=wapr[0],wapr[1] do begin
      spp_swp_wrp_stat,wapid,load=load,cdf=cdf,ptp=ptp,stats=stats,all=all,comp=comp,group=group,trange=trange,tplot_comp_ratio=tplot_comp_ratio,original_time=original_time
      for istat=0,3 do stats2[*,wapid-wapr[0]].(istat)=stats.(istat)
      names[wapid-wapr[0]]=(spp_apdat(wapid)).name
    endfor
    headertext=['Total # of Packets','Total Bytes','Bytes/sec','% Bytes']
    format=['i12)','i12)','f12.3)','f12.2)']
    for istat=3,0,-1 do begin
      print,headertext[istat],[wapr[0]:wapr[1]],'all',format='(156("-"),/,a-36,8Z12,a12)'
      print,'Name','APID dec','0xhex',names,'wrp_all',format='(a4,a20,10a12)'
      pkts=stats2.(istat)
      if istat eq 3 then pkts=100.*stats2.tot/(replicate(1.,apr[1]-apr[0]+1)#total(stats2.tot,1))
      pkts[where(~finite(pkts),/null)]=0.
      for ap=apr[0],apr[1]-1 do begin
        totpkts=total(pkts[ap-apr[0],*])
        if istat eq 3 && total(stats2.tot) ne 0 then totpkts=100.*total(stats2[ap-apr[0],*].tot)/total(stats2.tot)
        if keyword_set(all) || (totpkts ne 0) then print,(spp_apdat(ap)).name,ap,ap,pkts[ap-apr[0],*],totpkts,format='(a-20,i4,7(" "),"0x",Z03,9'+format[istat]
      endfor
      print,'TOTALS'
      foreach apr0,aprs,apr1 do begin
        totpkts=total(pkts[apr0[0]-apr[0]:apr0[1]-apr[0],*],1)
        if istat eq 3 && total(stats2.tot) ne 0 then totpkts=100.*total(stats2[apr0[0]-apr[0]:apr0[1]-apr[0],*].tot,1)/total(stats2.tot)
        if keyword_set(all) || (total(totpkts) ne 0) then print,apr1,0,0,totpkts,total(totpkts),format='(a-20,i4,7(" "),"0x",Z03,9'+format[istat]
      endforeach
    endfor
    print,'Compression Ratio',[wapr[0]:wapr[1]],'all',format='(156("-"),/,a-36,8Z12,a12)'
    print,'Name','APID dec','0xhex',names,'wrp_all',format='(a4,a20,10a12)'
    foreach apr0,aprs,apr1 do begin
      tottod=total(stats2[apr0[0]-apr[0]:apr0[1]-apr[0],*].tod,1)
      tottot=total(stats2[apr0[0]-apr[0]:apr0[1]-apr[0],*].tot,1)
      ratio=tottod/tottot
      ratio[where(~finite(ratio),/null)]=0.
      ratio2=total(tottod)/total(tottot)
      if keyword_set(all) || (total(tottot) ne 0) then print,apr1,0,0,ratio,ratio2,format='(a-20,i4,7(" "),"0x",Z03,9f12.3)'
    endforeach
    totcgbits=total(tottot)*8./1e9
    totdgbits=total(tottod)*8./1e9
    print,'Total Compressed Gbits: '+strtrim(totcgbits,2)
    print,'Total Decompressed Gbits: '+strtrim(totdgbits,2)
    return
  endif

  apdat=spp_apdat(apid)
  if ~keyword_set(apdat) then message,'unknown apid!'
  apid=apdat.apid
  type=apdat.name
  if (apid lt wapr[0]) || (apid gt wapr[1]) then begin ;apid is not a wrapper apid
    print,apdat.name,apid,apid,format='(a-20,i4,7(" "),"0x",Z03)'
    for wapid=wapr[0],wapr[1] do spp_swp_wrp_stat,wapid,load=load,cdf=cdf,ptp=ptp,capid=apid,comp=comp,group=group,trange=trange,tplot_comp_ratio=tplot_comp_ratio,original_time=original_time,noheader=wapid ne wapr[0]
    return
  endif

  if isa(capid0) then apr=[capid0,capid0] else print,apdat.name,apid,apid,format='(156("-"),/,a-20,i4,7(" "),"0x",Z03)'
  if ~keyword_set(noheader) then print,'Name','APID dec','0xhex','N_packets','Total_Bytes','Bytes/sec','Comp-Ratio','Average','Decomprsd','stdev','Decomprsd','%db/b','Decomprsd',format='(a4,a20,11a12)'

  if keyword_set(cdf) then begin
    if ~keyword_set(type) then message,'unknown apid!'
    if keyword_set(load) then spp_swp_load,type=type,spx='swem',trange=trange,ptp=ptp
    if keyword_set(ptp) then level='PTP' else level='L1'
    get_data,'psp_swp_swem_'+type+'_'+level+'_SEQN_GROUP',tt,sg
    get_data,'psp_swp_swem_'+type+'_'+level+'_PKT_SIZE',tt,ps
    get_data,'psp_swp_swem_'+type+'_'+level+'_CONTENT_TIME_DIFF',tt,td
    get_data,'psp_swp_swem_'+type+'_'+level+'_CONTENT_APID',tt,ca
    get_data,'psp_swp_swem_'+type+'_'+level+'_CONTENT_DECOMP_SIZE',tt,ds
    get_data,'psp_swp_swem_'+type+'_'+level+'_CONTENT_COMPRESSED',tt,cc
    if ~keyword_set(ca) then return
  endif else begin
    array=apdat.array
    if ~keyword_set(array) then return
    str_element,array,'content_apid',success=success
    if success then begin
      tt=array.time
      sg=array.seqn_group
      ps=array.pkt_size
      td=array.content_time_diff
      ca=array.content_apid
      ds=array.content_decomp_size
      cc=array.content_compressed
    endif else return
  endelse

  if keyword_set(original_time) then tt-=td
  if keyword_set(trange) then begin
    trange=timerange(trange)
    if n_elements(trange) ne 2 then message,'expected 2-element trange!'
    trange=time_double(trange)
    wt=where((tt gt trange[0]) and (tt lt trange[1]),/null)
    if ~keyword_set(wt) then return
    tt=tt[wt]
    sg=sg[wt]
    ps=ps[wt]
    td=td[wt]
    ca=ca[wt]
    ds=ds[wt]
    cc=cc[wt]
  endif
  tr=minmax(tt)
  dtt=tr[1]-tr[0]

  if isa(group) then begin
    wsg=where(sg eq group,/null)
    if ~keyword_set(wsg) then return
    tt=tt[wsg]
    ps=ps[wsg]
    td=td[wsg]
    ca=ca[wsg]
    ds=ds[wsg]
    cc=cc[wsg]
  endif

  wcc=where(cc,/null)
  wncc=where(~cc,/null)
  if keyword_set(wcc) then ds[wcc]-=20 ;remove the header
  if keyword_set(wncc) then ds[wncc]=ps[wncc]-12-20 ;also remove the wrapper packet header
  if isa(comp) then begin
    if comp eq 0 then wcc=wncc
    if ~keyword_set(wcc) then return
    tt=tt[wcc]
    ps=ps[wcc]
    td=td[wcc]
    ca=ca[wcc]
    ds=ds[wcc]
  endif
  ps=double(ps)
  ds=double(ds)

  for ap=apr[0],apr[1] do begin
    w=where(ca eq ap,nca)
    if nca eq 0 then continue
    tot=total(ps[w])
    tod=total(ds[w])
    to2=total(ps[w]^2)
    td2=total(ds[w]^2)
    stdev=sqrt(to2/nca-(tot/nca)^2)
    stded=sqrt(td2/nca-(tod/nca)^2)
    av=tot/nca
    ad=tod/nca
    stats[ap-apr[0]].tdt=tot/dtt
    stats[ap-apr[0]].nca=nca
    stats[ap-apr[0]].tot=tot
    stats[ap-apr[0]].tod=tod+(12+20)*nca
    if keyword_set(capid0) then ap2=apid else ap2=ap
    print,(spp_apdat(ap2)).name,ap2,ap2,nca,tot,tot/dtt,(ad+12+20)/av,av,ad,stdev,stded,100.*stdev/av,100.*stded/(ad+12+20),format='(a-20,i4,7(" "),"0x",Z03,2i12,8f12.3)'
    if keyword_set(tplot_comp_ratio) then begin
      store_data,'psp_swp_'+(spp_apdat(ap2)).name+'_'+type+'_COMP_RATIO_wrap_time',tt[w],(12+20+ds[w])/ps[w]
      ;store_data,'psp_swp_'+(spp_apdat(ap2)).name+'_'+type+'_COMP_RATIO_orig_time',tt[w]-td[w],(12+20+ds[w])/ps[w]
    endif
  endfor


  if 0 then begin ;old method 1
    h=histogram(ca,locations=xbins,min=capid0,max=capid0)
    w=where(h,nca)
    if nca eq 0 then return
    av=average_hist(float(ps),ca,binsize=1,stdev=stdev)
    tot=av*h
    if keyword_set(capid0) then begin
      xbins=apid
      tot=total(ps[where(ca eq capid0)])
      av=tot/h
    endif
    for iw=0,nca-1 do print,(spp_apdat(xbins[w[iw]])).name,xbins[w[iw]],xbins[w[iw]],h[w[iw]],tot[w[iw]],av[w[iw]],stdev[w[iw]],stdev[w[iw]]/av[w[iw]],format='(a-20,i3,Z12,i12,i12,f12.3,f12.3,f12.2)'
    ;print,transpose([[xbins[w]],[xbins[w]],[h[w]],[tot[w]],[av[w]],[stdev[w]]]),format='(i,Z,i,i,f,f)'
  endif

  if 0 then begin ;old method 2
    h=histogram(ca,locations=xbins,min=apr[0],max=apr[1])
    w=where(h,nca)
    av=average_hist(float(ps),ca,binsize=1,stdev=stdev,range=[-.5+apr[0],apr[1]],xbins=xbinsav)
    tot=av*h
    if keyword_set(capid0) then begin
      w=capid0-apr[0]
      if h[w] eq 0 then return
      nca=1
      xbins[w]=apid
    endif
    for iw=0,nca-1 do print,(spp_apdat(xbins[w[iw]])).name,xbins[w[iw]],xbins[w[iw]],h[w[iw]],tot[w[iw]],av[w[iw]],stdev[w[iw]],stdev[w[iw]]/av[w[iw]],format='(a-20,i3,Z12,i12,i12,f12.3,f12.3,f12.2)'
  endif
end