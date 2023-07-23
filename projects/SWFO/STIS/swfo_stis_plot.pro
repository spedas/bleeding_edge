;+
; This routine can be used for interactive plotting.
; Run using:
; ctime,routine_name='swfo_stis_plot',/silent
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-02-24 16:27:51 -0800 (Fri, 24 Feb 2023) $
; $LastChangedRevision: 31520 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_crib.pro $
; $ID: $
;-


; sample plotting procedure


pro  swfo_stis_oplot_err,x,y,dx=dx,dy=dy,color=color,psym=psym
  if isa(psym) then oplot,color=color,psym=psym,x,y
  for i= 0, n_elements(x)-1 do begin
    if isa(dx)  then oplot,x[i]+[-dx[i],dx[i]],[y[i],y[i]],color=color
    if isa(dy)  then oplot,[x[i],x[i]]  , y[i]+ [-dy[i],dy[i]], color=color
    
  endfor
end


function swfo_stis_plot_fit_peak,x,y,verbose=verbose
  par = mgauss(numg=1)
  mx = max(y * (x gt 50),maxbin)
  n = 3
  bins = [-n:n] + maxbin
  par.g.x0 = x[maxbin]
  par.g.s=10
  par.g.a = y[maxbin] * par.g.s * 2
  ;print,x[maxbin],y[maxbin]
  ;pf,par
  fit,verbose=verbose,x[bins],y[bins],param=par,names='G',result=res;,/logfit
  pf,par
  return,par
end





pro  swfo_stis_plot,var,t,param=param,trange=trange,nsamples=nsamples,lim=lim,fit=par    ; This is very simple sample routine to demonstrate how to plot recently collecte spectra

  common swfo_stis_plot_com, def_param
  
  if isa(param,'dictionary') then def_param = param

  if ~isa(def_param,'dictionary') then def_param=dictionary()
  
  param = def_param
  
  if ~param.haskey('range') then param.range = 30   ; interval in seconds
  if ~param.haskey('window') then param.window =1
  ;if ~param.haskey('units') then param.units = 'Eflux'
  ;if ~param.haskey('xunits') then param.xunits = 'NRG'
  if ~param.haskey('lim') then begin
    param.lim = dictionary()
    xlim,param.lim,1,1e5,1
    ;xlim,param.lim,10000,32000.,0
    ylim,param.lim,.001,1e7,1
    units = 'Eflux'
    options,param.lim,units=units,ytitle=units,xtitle='Energy (keV)',xunits='ADC'
  endif
  if ~param.haskey('routine_name') then param.routine_name = 'swfo_stis_plot'
  if ~param.haskey('nsamples') then param.nsamples = 20
  if ~param.haskey('ddata') then begin
    if (sci = swfo_apdat('stis_sci'))  then begin ; First look for data from the L0 data stream
      param.ddata = sci.data   ; L0 data
    endif else begin        ;   Look for data from the L0 or L1 tplot variables
      get_data,'swfo_stis_sci_COUNTS',ptr_str = tplot_data, time
      if isa(tplot_data,'dynamicarray') then begin
        param.ddata = tplot_data.ddata        
      endif else begin
        dprint,dlevel=2,'No data source available.'
        return
      endelse
    endelse
  endif
  
  
  
  
;printdat,param
;  range = struct_value(param,'range',default=[-.5,.5]*30)
;  lim   = struct_value(param,'lim',default=lim)
;  xval  = struct_value(param,'xval',default= 'NRG')
;  wind  = struct_value(param,'window',default=1)
;  nsamples  = struct_value(param,'nsamples',default=30)
;  units = struct_value(param,'units',default='Eflux')
;  read_object = struct_value(param,'read_object')
  
  
  
  if param.haskey('read_object') && isa(param.read_object,'socket_reader') then begin
    trec = systime(1)
    if trec gt param.read_object.getattr('time_received') +10 then begin
      dprint,dlevel = 2, "Forced timed socket read. Don't forget to exit ctime!"
      param.read_object.timed_event
    endif
  endif
  
  if isa(t) then begin
    
    ;    if param.range eq 0 then trange=t else  trange = t+param.range*[-.5,.5]
    trange = t+param.range*[-.5,.5]
  endif
  

 ; hkp = swfo_apdat('stis_hkp2')
 ; hkp_data   = hkp.data


  if keyword_set(trange) then begin
    nearest = trange[0] eq trange[1]
    samples=param.ddata.sample(range=trange,tagname='time' ,nearest=nearest)  
    nsamples = n_elements(samples)
    dprint,nsamples,trange-t
    ;tmid = average(trange)
    ;hkp_samples = hkp_data.sample(range=tmid,nearest=tmid,tagname='time')
  endif else begin
    nsamples = param.nsamples
    size = param.ddata.size
    index = [size-nsamples:size-1]    ; get indices of last N samples
    samples=param.ddata.slice(index)           ; extract the last N samples
    ;hkp_samples= hkp.data.slice(/last)
  endelse

  
  ymin = min( struct_value(param.lim,'yrange',default=0.))
  
  names='SPEC_' + ['O1','O2','O3','F1','F2','F3']
  nans = replicate(!values.f_nan,48)
  format = {name:'',color:0,linestye:0,psym:-4,linethick:2,geomfactor:1.,x:nans,y:nans,dx:nans,dy:nans,xunits:'',yunits:'',lim:obj_new()}
  channels = replicate(format,n_elements(names))
  channels.name = names
  channels.color = [2,4,6,1,3,0]

  old_window = !d.window
  if isa(samples) then begin
    wi,param.window
   
    l1a = swfo_stis_sci_level_1a(samples)
    ;h= [l1a.hash,0]   ; get the uniq segments
    ;up =   uniq(h)       
    ;u0= [0,up]
    
    h = l1a.hash
    if nsamples gt 1 then   h[-1] = 0    ; ignore the last one
    dh = h - shift(h,-1)   ; ignore any spectrum in which the following hkp changes
         
    u = h.uniq()

    
    if param.lim.xunits eq 'ADC' then param.lim.xtitle = 'ADC units' else param.lim.xtitle = 'Deposited Energy (keV)

    lim = param.lim
    ;box,lim
    ;init=0
    lim.title = trange_str(minmax(samples.time))
    if 1 then begin
      par = mgauss(numg=1)
    endif
    
    
    
    
    
    
    for i=0,n_elements(u)-1 do begin
      w = where(h eq u[i] and dh eq 0,/null,nw)
      if nw eq 0 then continue
      datw=l1a[w]
      dat = average(datw)
      nc = n_elements(channels)
      for c = 0,nc-1 do begin
        ch = channels[c]
        str_element,dat,ch.name,y
        dy  = y*0.
        str_element,dat,ch.name+'_err',dy
        if param.lim.xunits eq 'ADC'  then begin
          str_element,dat,ch.name+'_adc',x
          str_element,dat,ch.name+'_dadc',dx
        endif else begin
          str_element,dat,ch.name+'_nrg',x
          str_element,dat,ch.name+'_dnrg',dx
        endelse
        case strupcase(param.lim.units) of
          "EFLUX": begin 
            scale = x 
            param.lim.ytitle = 'Energy Flux (#/cm2/ster/s)'
            end
          'ERATE': begin
            scale = 1
            param.lim.ytitle = 'Rate  (#/sec/adc)'
            end
        endcase
       
        y = y * scale
        y = y > ymin/10.
        ;swfo_stis_oplot_err,x,y,color=ch.color,psym=ch.psym
        if ~keyword_set(newlim) then begin
          newlim =lim.tostruct()
          if ~lim.haskey('yrange') || (lim.yrange[0] eq lim.yrange[1]) then newlim.yrange=minmax(/positive,y)
          box,newlim
         ; init = 1
        endif
        ch.x = x
        ch.y = y
        ch.dx = dx
        ch.dy = dy
        ch.lim = lim
        channels[c] = ch
        oplot,x,y ,color=ch.color,psym=ch.psym
        if param.haskey('dofit')  && (c ge 0) && i eq n_elements(u)-1 then begin
          ;printdat,u
          ;savetomain,x
          ;savetomain,y
          ;print,x,y
          par = swfo_stis_plot_fit_peak(x,y,verbose=param.haskey('verbose'))
          pf,par,color=ch.color
          if c ge 0  then          print,par.g[0]
          if c eq 5 then print
        endif
        
        
      endfor
    endfor

    if 0 then begin
      xv = dgen()
      
      flux_min = 2.48e2 * xv ^ (-1.6)  ; #/sec/cm2/ster/keV
      flux_max = 1.01e7 * xv ^ (-1.6)
      if strupcase(param.lim.units) eq 'EFLUX' then  scale = xv else scale = 1
      oplot, xv, flux_min * scale
      oplot, xv, flux_max * scale
      if 1 then begin
        ;stop
        w = where(x ge 30 and x lt 2000)
        flux_min = 2.48e2 * x ^ (-1.6)
        eflux_min  = x * flux_min
        dt = 30.
        counts = flux_min * .2 * dt * dx
        flux = counts /.2 / dt / dx
        dflux = sqrt(counts+1.) / .2/dt/dx
        oplot,x,flux * x, color = 2,psym=10
        oplot,x,(flux+dflux) * x, color = 2,psym=10
        oplot,x,(flux-dflux) * x, color = 2,psym=10
        ;print,total(counts[w])/dt
        ;print,max(dflux/flux)
        ;print,dx/x
        ;print,x
        ;print,dx

      endif
      
      if 0 then begin
        w = where(x ge 10 and x lt 8000)
        flux_max = 1.01e7 * x ^ (-1.6)
        eflux_max  = x * flux_max
        dt = 2.
        geom = .002
        counts = flux_max * geom * dt * dx
        flux = counts /geom / dt / dx
        dflux = sqrt(counts+1.) / geom/dt/dx
        oplot,x,flux * x, color = 6,psym=10
        oplot,x,(flux+dflux) * x, color = 6,psym=10
        oplot,x,(flux-dflux) * x, color = 6,psym=10
        ;print,total(counts[w])/dt
        ;print,max(dflux/flux)
        ;print,dx/x
        
      endif
      
      
    endif
        
  endif
  
;  if isa(param,'dictionary') then begin
;    if ~param.haskey('lim') then param.lim=dictionary(lim)
;    if ~param.haskey('routine_name') then param.routine_name = 'swfo_stis_plot'
;    if ~param.haskey('window') then param.window= wind
;    if ~param.haskey('range') then param.range = range
;  endif



;{        3152.9827       239.47570       6.0271145}   EM DAP / FM Detector
;{        6168.1520       240.70090       16.162878}
;{        3550.5448       240.11675       10.268422}
;{        3980.8447       239.29993       6.1326823}
;{        6657.8149       240.89125       15.161478}
;{        3966.9739       239.54395       9.2053748}



;{        2870.7481       226.52453       5.2746233}   EM DAP / EM Detector
;{        3886.7794       205.31196       10.490959}
;{        3997.6211       289.59776       11.638202}
;{        3843.9637       215.74410       5.5227683}
;{        7470.5782       233.91078       25.323929}
;{        4220.7271       228.81207       8.7603103}



  
  
  ;  store_data,'mem',systime(1),memory(/cur)/(2.^6),/append
end
