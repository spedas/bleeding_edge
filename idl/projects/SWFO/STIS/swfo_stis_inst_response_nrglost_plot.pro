; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-17 15:01:15 -0800 (Sun, 17 Dec 2023) $
; $LastChangedRevision: 32298 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_inst_response_nrglost_plot.pro $
; $Id: swfo_stis_inst_response_nrglost_plot.pro 32298 2023-12-17 23:01:15Z davin-mac $



pro swfo_stis_inst_response_nrglost_plot,simstat,data,window=win,tid=tid,fto=fto


  if keyword_set(win) then begin
    wi,win++
  endif
  calval = swfo_stis_inst_response_calval()
  particle = simstat.particle_name
;  dprint, 'Energy lost calc for', simstat.particle_name
  if ~keyword_set(tid) then tid = 0
  if ~keyword_set(fto) then fto = 4
  ifto_type = calval.names_fto[tid,fto-1]
  particle_fto = particle+'-'+ifto_type


  n_one = replicate(1,n_elements(data))
  fto_n = total( ([1,2,4] # n_one) * (data.edep[*,tid] ne 0), 1,/preserve)

  d = data[where(fto_n eq fto,/null)]
  xbinsize = 1/40.
  ybinsize = xbinsize
  xrange = simstat.sim_energy_range
  yrange = xrange
  yrange = [.1,5000]
  xval = d.e_tot
  ;xval = d.einc
  yval = d.einc-d.e_tot
  h = histbins2d(xval,yval,xbins,ybins,xbinsize=xbinsize,ybinsize=ybinsize,/xlog,/ylog,xrange=xrange,yrange=yrange)

  xlim,lim,xrange,/log
  ylim,lim,yrange,/log
  zlim,lim,.1,1000,1
  title = 'Energy Loss  '+calval.instrument_name +'  '+particle_fto
  options,lim,/no_interp,title = title,xtitle='Energy Measured (keV)',ytitle,'Energy lost (keV)'
  specplot,xbins,ybins,h*1.,lim=lim
  
  func = struct_value(calval.nrglost_vs_nrgmeas,particle_fto)
  pf,func
  
  fname = str_sub(title,' ','_')
  ;printdat,fname
  plot_dir = struct_value(calval,'plot_directory')
  if plot_dir then makepng,plot_dir+fname
  

end

