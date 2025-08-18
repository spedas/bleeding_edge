

pro swfo_stis_inst_response_gpa,spec_func,window=win

  transpose = 0
  
  resp = spec_func.inst_response
  energy = spec_func.xlog ? 10^spec_func.xs  : spec_func.xs
  flux   = spec_func.ylog ? 10^spec_func.ys  : spec_func.ys
  
  einc_range = [1,1e6]
  flux_range = [1e-2,1e6]

  if transpose then begin
    if keyword_set(win) then wi,win,wsize = [1000,700],/show
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
    swfo_stis_response_plot_simflux,spec_func,limit=lim3   ;, energy=energy,flux=flux ; ,window=win
    lim0=lim2
    lim0.position = pos[*,0]
    options,lim0,xrange = [1e7,1e-2]
    options,lim0,/xlog,/xstyle,xtitle = 'Differential Particle Flux',title=''
    box,lim0
    oplot,flux,energy,psym=-1
    
  endif else begin
    if keyword_set(win) then wi,win,wsize = [1400,900],/show
    erase
    lim2=0
    options,lim2,noerase=1
    opts={xmargin:[10,10] }
    pos = plot_positions(xsizes = [1,1], ysizes=[3,2],xgap=12,ygap=4,options=opts )
    str_element,lim2,'position',pos[*,0],/add

    swfo_stis_response_bin_matrix_plot,resp,transpose=transpose ,limit=lim2,face=0  ;  ,window=win++      ; both faces
    
    lim3 = lim2
    lim3.position= pos[*,3]
    lim3.title=''
    lim3.xstyle = lim2.ystyle
    lim3.xrange = lim2.yrange
    lim3.xtitle = lim2.ytitle
    lim3.xlog   = 0

    swfo_stis_response_plot_simflux,spec_func,limit=lim3,result=result   ;, energy=energy,flux=flux ; ,window=win

    lim0=lim2
    
    lim0.position = pos[*,2]
    options,lim0,yrange = flux_range
    options,lim0,/ylog,/ystyle,ytitle = 'Differential Particle Flux',title=''
    box,lim0
    xv =dgen()
    yv = func(xv,param=spec_func)
    oplot,xv,yv,color = 4

   ; oplot,energy,flux,color=6;,psym=-1,color = 6
    
    bmap = result.resp.bmap[0:671]    
    rate = result.rate_dtcor[0:671]
    rate = result.rate[0:671]
    bmap.rate = rate
    
   ; bmap.rate *= bmap.nrg_meas_avg /80   ; should make this correction outside this routine
    
    bmap.flux = bmap.rate / bmap.geom  / bmap.nrg_meas_delta   ;* bmap.nrg_proton_avg / 80   
    
    w1 = where(bmap.fto eq 1 and bmap.tid eq 0)
    b1 = bmap[w1]
    energy = b1.nrg_proton_avg
    flux  = b1.flux
    oplot,energy,flux,psym= 4,color = 2
    
    w3 = where(bmap.fto eq 4 and bmap.tid eq 0)
    b3 = bmap[w3]
    energy = b3.nrg_proton_avg
    flux  = b3.flux
    oplot,energy,flux,psym= 4,color = 6

        
    
    
  endelse
  


  dprint
  test = 1
  if test eq 1 then begin
    delta_time = 30
    lim4 = lim0
    ylim,lim4,.1,1000,1
    options,lim4,ytitle = 'Error ',title='Error (dT = '+strtrim(delta_time,2)+' Seconds)'
    str_element,lim4,'position',pos[*,1],/add
    
    box,lim4
    oplot, dgen(), dgen() *0+1 , color=4
    nrg1 = b1.nrg_proton_avg
    f1_f = b1.flux / func(nrg1,param=spec_func)
    oplot,nrg1,f1_f, color=2, psym = 4
    nrg3 = b3.nrg_proton_avg
    f3_f = b3.flux / func(nrg3,param=spec_func)
    oplot,nrg1,f3_f, color=6, psym = 4
    if 1 then begin
      df1_f = 1/ sqrt(delta_time * b1.rate + .1)
      df3_f = 1/ sqrt(delta_time * b3.rate + .1)
      oplot,nrg1,df1_f * 100, color=2
      oplot,nrg3,df3_f * 100, color=6
    endif

  endif
  if test eq 2 then begin
    delta_time = 30
    lim4 = lim0
    ylim,lim4,.1,1000,1
    options,lim4,ytitle = '% Error ',title='Poisson Error (dT = '+strtrim(delta_time,2)+' Seconds)'
    str_element,lim4,'position',pos[*,1],/add
    df1_f = 1/ sqrt(delta_time * b1.rate + .1)
    df3_f = 1/ sqrt(delta_time * b3.rate + .1)
    box,lim4
    oplot,b1.nrg_proton_avg,df1_f * 100, color=2
    oplot,b3.nrg_proton_avg,df3_f * 100, color=6
  endif




end

