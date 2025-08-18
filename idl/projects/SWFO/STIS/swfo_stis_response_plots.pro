; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-01-03 22:37:44 -0800 (Wed, 03 Jan 2024) $
; $LastChangedRevision: 32333 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_response_plots.pro $
; $ID: $





 

pro swfo_stis_response_plots,resp  ;,simstat,data,filter=f,window=win ,response=resp            ;,mapnum=mapnum,noise_level=noise_level,seed=seed
  ;if ~ keyword_set(simstat) || ~ keyword_set(data) then return
  if not keyword_set(win) then win=1
  binscale=3
  ;swfo_stis_response_aperture_plot,data,simstat=simstat,window= win++,_extra=f ,binscale=binscale
  ;swfo_stis_response_omega_plot,data,simstat=simstat,window=win++,_extra=f ,binscale=binscale, /posflag
  ;swfo_stis_response_omega_plot,data,simstat=simstat,window=win++,_extra=f ,binscale=binscale

  ;we= where( swfo_stis_response_data_filter(simstat,data,_extra=f,filter=f2),nwe)
  resp = swfo_stis_inst_response(simstat,data,filter=f)
  ;printdat,resp
  if ~keyword_set(resp) then stop

  transpose=1
  ;transpose=0
  
  if 0 then begin
    swfo_stis_inst_response_nrglost_plot,simstat,data,window=win++,tid=0,fto=4
    swfo_stis_inst_response_nrglost_plot,simstat,data,window=win++,tid=1,fto=4

  endif
  ;swfo_stis_response_matrix_plots,resp,window=win++
  ;swfo_stis_response_matrix_plots,resp,window=win++,single=4
  swfo_stis_response_matrix_plot,resp,window=win++ , tid=0, fto=4
  swfo_stis_response_matrix_plot,resp,window=win++ , tid=1, fto=4

  swfo_stis_response_bin_matrix_plot,resp,window=win++,transpose=transpose ,face=0         ; both faces
;  swfo_stis_response_bin_matrix_plot,resp,window=win++,transpose=transpose ,face=-1
;  swfo_stis_response_bin_matrix_plot,resp,window=win++,transpose=transpose ,face=+1
  swfo_stis_response_plot_gf,resp,window=win++,/ylog;,xrange=[1e2,1e6]

  if 0 then begin
    energy = dgen(/log,range=[1.,1e6],6*4+1)
    flux = 1e7 * energy^ (-1.6)
    flux = 2.5e2 * energy^ (-1.6)
    flux = 2.5e4 * energy^ (-1.6)
    w = where(energy gt 2000.)
    ;flux[w] = flux[w] * 100
    pwlin =1

    func_elec = spline_fit3(!null,energy,flux,/xlog,/ylog,pwlin=pwlin)
    str_element,/add,func_elec,'inst_response',resp

    if 1 then begin
      dprint
      swfo_stis_inst_response_matmult_plot,func_elec,window=win++
    endif else begin
      wi,win++,wsize = [1400,800],/show
      erase
      lim2=0
      options,lim2,noerase=1
      opts={xmargin:[10,10] }
      pos = plot_positions(xsizes = [1,2], ysizes=[3,2],xgap=10,ygap=4,options=opts )
      str_element,lim2,'position',pos[*,1],/add

      swfo_stis_response_bin_matrix_plot,resp,transpose=transpose ,limit=lim2,face=0  ;  ,window=win++      ; both faces
      lim3 = lim2
      lim3.position= pos[*,3]
      lim3.title=''

      swfo_stis_response_plot_simflux,func_elec,limit=lim3   ;, energy=energy,flux=flux ; ,window=win

      lim0=lim2
      lim0.position = pos[*,0]
      options,lim0,xrange = [1e7,1e-2]
      options,lim0,/xlog,/xstyle,xtitle = 'Differential Particle Flux',title=''
      box,lim0
      oplot,flux,energy,psym=-1

    endelse


    dprint
    
  endif

end



