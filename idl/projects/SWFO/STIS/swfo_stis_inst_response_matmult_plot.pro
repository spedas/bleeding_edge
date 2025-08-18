

pro swfo_stis_inst_response_matmult_plot,spec_func,window=win

  transpose = 0
  
  calval = swfo_stis_inst_response_calval()
  if 1 then begin
    resp = calval.responses[ spec_func.name ]
  endif else begin
    resp = spec_func.inst_response    
  endelse
  
;  energy = spec_func.xlog ? 10^spec_func.xs  : spec_func.xs
;  flux   = spec_func.ylog ? 10^spec_func.ys  : spec_func.ys
  
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
    if keyword_set(win) then wi,win,wsize = [1400,900] , show=show
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
    color = 4
    oplot,xv,yv,color = color,thick=3
    
    oplot,xv, 1e7 *xv^(-1.6)
    oplot,xv, 2.48e2 *xv^(-1.6)

   ; oplot,energy,flux,color=6;,psym=-1,color = 6
    
      bmap = result.resp.bmap[0:671]
      rate = result.rate_dtcor[0:671]
      rate = result.rate[0:671]
      bmap.rate = rate
    if 0 then begin

      ; bmap.rate *= bmap.nrg_meas_avg /80   ; should make this correction outside this routine

      bmap.flux = bmap.rate / bmap.geom  / bmap.nrg_meas_delta   ;* bmap.nrg_proton_avg / 80

      w1 = where(bmap.fto eq 1 and bmap.tid eq 0)
      b1 = bmap[w1]
      energy = b1.nrg_inc
      flux  = b1.flux
      oplot,energy,flux,psym= 4,color = 2

      w3 = where(bmap.fto eq 4 and bmap.tid eq 0)
      b3 = bmap[w3]
      energy = b3.nrg_inc
      flux  = b3.flux
      oplot,energy,flux,psym= 4,color = 6
      
    endif
    if 1 then begin
      
      swfo_stis_response_rate2flux,rate,resp,method=method  

      names = ['O-3','O-1']
      
      for i=0,n_elements(names)-1 do begin
        name = names[i]
        w = where( resp.bmap.name eq name and finite(resp.bmap.flux) and (resp.bmap.e0_inc lt 6000.) and (resp.bmap.nrg_meas gt 25.) ,/null)
        if keyword_set(w) then begin
          bmap =resp.bmap[w]
          oplot,bmap.e0_inc , bmap.flux, psym= bmap[0].psym, color = bmap[0].color

        endif
        
      endfor
      
    endif

        
    
    
  endelse
  


  dprint
  test = 0
  ;test = 2
  if test eq 1 then begin
    delta_time = 300
    lim4 = lim0
    ylim,lim4,.1,1000,1
    options,lim4,ytitle = 'Error ',title='Error (dT = '+strtrim(delta_time,2)+' Seconds)'
    str_element,lim4,'position',pos[*,1],/add
    
    box,lim4
    oplot, dgen(), dgen() *0+1 , color=4
    nrg1 = b1.nrg_inc
    f1_f = b1.flux / func(nrg1,param=spec_func)
    oplot,nrg1,f1_f, color=2, psym = 4
    nrg3 = b3.nrg_inc
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
    oplot,b1.nrg_inc,df1_f * 100, color=2
    oplot,b3.nrg_inc,df3_f * 100, color=6
  endif




end

