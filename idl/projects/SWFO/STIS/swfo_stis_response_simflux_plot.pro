; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-04-04 08:02:24 -0700 (Thu, 04 Apr 2024) $
; $LastChangedRevision: 32519 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_response_simflux_plot.pro $
; $Id: swfo_stis_response_simflux_plot.pro 32519 2024-04-04 15:02:24Z davin-mac $






pro swfo_stis_response_simflux_plot,resp,rate=rate,overplot=over,lim=lim,name_match = name_match,flux_func = flux_func,colors=color


;  calval = swfo_stis_inst_response_calval()

;  lim= dictionary('xrange',[1,1e10],'xlog',1,'yrange',[1e-10,1e4],'ylog',1,'ystyle',1,'xstyle',1)
;  lim= dictionary('xrange',[1,1e8],'xlog',1,'yrange',[1e-10,1e5],'ylog',1,'ystyle',1,'xstyle',1)
  lim= dictionary('xrange',[10,1e4],'xlog',1,'yrange',[1e-4,1e5],'ylog',1,'ystyle',1,'xstyle',1)
  
  minflux = lim.yrange[0] *1.5
  
  if ~keyword_set(over) then box,lim

  if keyword_set(flux_func) then begin
    nrg = dgen(100)
    p_flux = func(param=flux_func,nrg,choice=1)
    e_flux = func(param=flux_func,nrg,choice=2)
    oplot,nrg,p_flux,color=5,thick=5
    oplot,nrg,e_flux,color=3,thick=5
  endif

  if keyword_set(rate) then begin
    swfo_stis_response_rate2flux,rate,resp,method=method
  endif
  
  if keyword_set(resp) then begin
    ind = indgen(48,14)
    b = resp.bmap[ind]

    for i=0,14-1 do begin
      name = b[0,i].name
      if isa(name_match,'string') && strmatch(name,name_match) eq 0 then continue
      nrg = b[*,i].nrg_inc
      flx = b[*,i].flux
      ;    flx   = r[*,i] / b[*,i].nrg_meas_delta / b[*,i].geom
      c = b[0,i].color
      if isa(color) then c = color
      oplot,nrg,flx  > minflux , color=c, psym = -b[0,i].psym
    endfor

    
  endif


end





