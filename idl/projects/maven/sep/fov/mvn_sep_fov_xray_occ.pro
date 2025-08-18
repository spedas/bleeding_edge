;20180705 Ali
;goes through sep x-ray occultations and calculates and plots fit parameters

pro mvn_sep_fov_xray_occ

  @mvn_sep_fov_common.pro
  @mvn_sep_handler_commonblock.pro

  occfolder='/home/rahmati/Desktop/sep/sep x-rays/all occs/'
  mvn_sep_fov,/restore
  whr=where(mvn_sep_fov.occ.sx1 gt 0,/null,nocc)
  oct=mvn_sep_fov[whr].time ;occ times
  tminmax=[0,0]
  for iocc=0,nocc-1 do begin
    time=oct[iocc]
    if time lt tminmax[0] or time gt tminmax[1] then begin
      mvn_sep_fov,/load,/arc,trange=time,/tplot,occalt=[50,70.]
      sep1=*(sep1_svy.x)
      tminmax=minmax(sep1.time)
    endif else continue
    whr2=where(mvn_sep_fov.occ.sx1 gt 0,/null,nocc2)
    oct2=mvn_sep_fov[whr2].time ;occ times
    occ=mvn_sep_fov[whr2].occ.sx1 ;occ fov number
    for iocc2=0,nocc2-1 do begin
      time2=oct2[iocc2]
      trange=time2+5.*60.*[-1.,1.] ;5mins before and after
      tplot,trange=trange
      makepng,occfolder+'tplot_'+time_string(time2,format=2)+'_sep_xray_occ'
      sep=([0,1,0,1])[occ[iocc2]-1]
      sld=([0,0,1,1])[occ[iocc2]-1]

      for idet=0,5 do begin
        mvn_sep_fov_xray,/occ,sep=sep,sld=sld,det=idet,trange=trange
        p=getwindows('mvn_sep_xray_occ')
        if keyword_set(p) then p.save,resolution=150,occfolder+'fit_'+time_string(time2,format=2)+'_sep'+strtrim(sep+1,2)+mvn_sep_fov0.detlab[idet]+'_xray_occ.png'
      endfor
    endfor
  endfor
    
end