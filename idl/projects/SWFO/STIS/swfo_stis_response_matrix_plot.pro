; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-17 15:01:15 -0800 (Sun, 17 Dec 2023) $
; $LastChangedRevision: 32298 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_response_matrix_plot.pro $
; $ID: $






;  Multiple matrix plots
pro swfo_stis_response_matrix_plot,resp,window=win,single=single,tid=tid,fto=fto,side=side

  
  if keyword_set(win) then     wi,win,wsize=[700,700] ;,/show

  calval = swfo_stis_inst_response_calval()
  particle = resp.particle_name
  ;  dprint, 'Energy lost calc for', simstat.particle_name
  if ~keyword_set(tid) then tid = 0
  if ~keyword_set(fto) then fto = 4
  ifto_type = calval.names_fto[tid,fto-1]
  particle_fto = particle+'-'+ifto_type
  dprint,particle_fto
  
  ;r=resp
  
  
  ;labels = strsplit('XXX O T OT F FO FT FTO Total',/extract)
  ;labels = strsplit('XXX 1 2 12 3 13 23 123 Total',/extract)
  zrange = minmax(resp.g4,/pos)
  xrange = resp.xbinrange
  yrange = resp.ybinrange
  
  options,lim,xlog=1,/ylog,xrange=xrange,/ystyle,/xstyle,yrange=yrange,xmargin=[10,10],/zlog,zrange=zrange,/no_interp
  options,lim,xtitle='Energy incident (keV)',ytitle='Energy Measured (keV)'
  
  title = 'Energy Response  '+calval.instrument_name +'  '+particle_fto

  
  options,lim,title=title

  side = tid

  if fto eq 8 then G2 = total(resp.g4[*,*,1:7,side],3) $
  else G2 = resp.g4[*,*,fto,side]

  ;      dprint,dlevel=3,side,fto,total(g2)
  ;      options,lim,title = title+slabel+'_'+labels[fto]
  specplot,resp.e_inc,resp.e_meas,G2,limit=lim
  
  func = struct_value(calval.nrglost_vs_nrgmeas,particle_fto)
  ;printdat,func
  if isa(func) then begin    ; overplot the prediected response
    deposited_energy = dgen(/y)
    energy_lost = func(param=func,deposited_energy)
    inc_nrg =   deposited_energy +  energy_lost
    oplot,inc_nrg,deposited_energy
  endif

  oplot,dgen(),dgen();,linestyle=1
 ; oplot,dgen()+12,dgen() , color = 6 ;,linestyle=1


  fname = str_sub(title,' ','_')
  ;printdat,fname
  plot_dir = struct_value(calval,'plot_directory')
  if plot_dir then makepng,plot_dir+fname

 end





