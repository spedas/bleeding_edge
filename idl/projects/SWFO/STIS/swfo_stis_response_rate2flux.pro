; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-04-04 08:02:24 -0700 (Thu, 04 Apr 2024) $
; $LastChangedRevision: 32519 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_response_rate2flux.pro $
; $Id: swfo_stis_response_rate2flux.pro 32519 2024-04-04 15:02:24Z davin-mac $






;pro swfo_stis_response_rate2flux_old,p_rate,e_rate,window=win,limits=lim ,overplot=overplot,result=result  ;,energy=energy,flux=flux
;  
;  
;  calval = swfo_stis_inst_response_calval()
;  p_resp=calval.responses['Proton']
;  e_resp=calval.responses['Electron']
;  
;  p_bmap = p_resp.bmap
;  p_bmap.rate = p_rate
;  p_bmap.flux = p_rate / p_bmap.nrg_meas_delta / p_bmap.geom
;  p_bmap.nrg_inc = p_bmap.nrg_meas + p_bmap.nrg_lost
;  p_resp.bmap = p_bmap
;  
;  e_bmap = e_resp.bmap
;  e_bmap.rate = e_rate
;  e_bmap.flux = e_rate / e_bmap.nrg_meas_delta / e_bmap.geom
;  e_bmap.nrg_inc = e_bmap.nrg_meas + e_bmap.nrg_lost
;  e_resp.bmap = e_bmap
;
;  ver = '-recovered'
;  ver = ''
;  calval.responses['Proton'+ver] = p_resp
;  calval.responses['Electron'+ver] = e_resp
;  
;  
;  
;  if 0 then begin
;    bmap = resp.bmap
;    resp_nrg = resp.e_inc
;    ;resp_flux = interp(xlog=1,ylog=1,flux,energy,resp_nrg)
;    resp_flux = func(resp_nrg,param = flux_func)    ; interpolate the flux to the reponse matrix sampling
;    ;resp_rate =  (transpose(g) # resp_flux ) > 1e-5
;    resp_rate =  (transpose(resp.Mde) # resp_flux ) > 1e-5
;    if arg_present(win) && n_elements(win) eq 1 then wi,win++,wsize = [1200,400]
;    options,lim,/ylog,yrange=[1e-4,3e6],xrange=[-2,nbins+5],xmargin=[10,10],/xstyle,/ystyle,ytitle='Count Rate (Hz)'
;    xbins = findgen(n_elements(resp_rate))
;    plot,noerase=overplot,xbins,resp_rate,  _extra=lim
;    deadtime = 8.0e-6
;    if 0 then begin
;      oplot,resp_rate * swfo_stis_rate_correction(resp_rate,deadtime = deadtime),color=6
;      rtot = total(resp_rate)
;      corr = swfo_stis_rate_correction(rtot,deadtime=deadtime)
;      oplot,resp_rate * corr , color = 4
;      printdat,rtot
;    endif
;
;    total_rates = fltarr(n_elements(bmap))
;    ftobits = [1,2,4]
;    for tid=0,1 do begin
;      for b = 0,2 do begin
;        ok = bmap.tid eq tid and (bmap.fto   and ftobits[b]) ne 0   ;  find all bins that use a particular channel
;        w = where(ok,/null)
;        rtot = total( resp_rate[w] )
;        total_rates[w] += rtot            ; increment total rate in all bins of that use that channel
;        dprint, tid, ftobits[b], rtot
;      endfor
;    endfor
;    ;dprint,total_rates
;    oplot,total_rates,color=2
;    oplot,lim.xrange,[1,1]/deadtime,linestyle =1   , color=2
;    oplot,lim.xrange,[1,1]/60.,linestyle =1   , color=2
;    oplot,lim.xrange,[1,1]*2.,linestyle =1   , color=2
;
;    resp_rate_cor = resp_rate * swfo_stis_rate_correction(total_rates,deadtime=deadtime)
;    oplot,resp_rate_cor,color=2
;    result = {resp:resp,rate:resp_rate, rate_dtcor: resp_rate_cor}
;    
;  endif
;end



; This should only be useful for O-1, O-3,  and partially for F-3 and F-1
pro swfo_stis_response_rate2flux,rate,resp,method=method,wh = w

  ;  bmap = p_resp.bmap
  w = !null
  if resp.particle_name eq 'Proton' then begin
    w = where(/null,resp.bmap.name eq 'O-3' or resp.bmap.name eq 'O-1')
  endif
  if resp.particle_name eq 'Electron' then begin
    w = where(/null,resp.bmap.name eq 'F-3' or resp.bmap.name eq 'F-1')
  endif
  
  if keyword_set(method) then begin
    resp.bmap[w].rate = rate[w]
    resp.bmap[w].flux = rate[w] / resp.bmap[w].nrg_meas_delta / resp.bmap[w].geom
    resp.bmap[w].nrg_inc = reslp.bmap[w].nrg_meas + resp.bmap[w].nrg_lost    
  endif else begin
    dt = 300.
    resp.bmap[w].rate = rate[w]
    resp.bmap[w].flux = rate[w] / resp.bmap[w].gde
    resp.bmap[w].nrg_inc = resp.bmap[w].e0_inc
    c =   rate[w] * dt
    resp.bmap[w].d_flux = resp.bmap[w].flux / sqrt(c+.5)
    resp.bmap[w].df_f  = 1/sqrt(c+.5)
  endelse
 ; p_resp.bmap = p_bmap

end





