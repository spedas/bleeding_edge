function cumulative_moments,y,x,dx
  if ~isa(x) then x = dindgen( n_elements(y) )
  if ~isa(dx) then begin
    dx=  (shift(x,-1) - shift(x,1)) / 2.
    dx[0] = dx[1]
    dx[-1] = dx[-2]
  endif
  nan = !values.d_nan
  mom = {g:nan, x0:nan, s:nan }
  
  moms = replicate(mom,n_elements(y) )
  
  
  ny= total( y,  /cum,/double)
  nxy = total( x*y  ,/cum,/double)
  nx2y = total( x*x*y,   /cum,/double)

  moms.g = ny
  moms.x0 = nxy / ny
  moms.s = sqrt( nx2y - nxy^2/ny )

  return,moms
end








function swfo_stis_inst_response_peakEinc,resp, $
   width=width, $
   threshold=threshold,  $
   matchnames=matchnames,  $
   test=test,slope=slope,pk2s=pk2s
   
  if ~keyword_set(matchnames) then matchnames = '?-3'
  if ~keyword_set(width) then width = ceil( 1/ resp.xbinsize / 2)
  if ~keyword_set(threshold) then threshold = .0005  ; obsolete
  if ~isa(slope) then slope = -1.6     ; Typically should use the power of flux  ( - 1.6 or -2 or -3)
  
  bmap = resp.bmap
  
  nan = !values.d_nan
  pk =  {g:nan, e0:nan, s:nan}
  pk2 = {g:nan, e0:nan, s:nan, gde:nan, n:nan,  n2:nan,  w:nan }
  nbins =resp.nbins
  e_inc = resp.e_inc
  de_inc = resp.de_inc 
  pks = replicate(pk,nbins)
  pk2s = replicate(pk2,nbins)
  
  gmat = total(resp.gb3,2)
  gmat = resp.MDE
  events = total(resp.bin3,2)
  weight = (e_inc/100) ^ slope
  gfactor = resp.sim_area/100 / resp.nd * !pi

  
  options,lim,yrange=[1.,1],xstyle=3,ystyle=3,/ylog,xrange=resp.xbinrange,xlog=resp.xlog,xtitle='Incident Energy',title=''
  lim.title = string(format='%S: %S Response (slope=%0.1f) ' ,strupcase(resp.testrun),resp.particle_name,slope)
  
;for omega=0,1 do begin
  psym = 10
  
    for b=0,nbins-1 do begin
      map_b = bmap[b]
      name = map_b.name
      nrg_meas = map_b.nrg_meas
      nrg_meas_delta = map_b.nrg_meas_delta
      namestr = map_b.name+string(nrg_meas,nrg_meas_delta,format = '("  ",f0.1," [",f0.1,"] eV")')
      if 0 then begin
        rr = resp.bin3[*,omega,b]*(resp.sim_area /100 / resp.nd * 3.14)
        w = where(total(rr,/cumulative) ge threshold,nw)
        if nw eq 0 then continue
        i1 = (w[0]-width/2) > 0
        i2 = (i1 +width) < n_elements(rr)-1
      endif else if 1 then  begin
        rr =     total(resp.gb3[*,*,b] ,2)
        evb =     events[*,b]
        ; rr =  gmat[*,b]  / e_inc    
        ;rr = 
        mx = max(smooth(rr* e_inc^(-2)  ,5),maxbin)
        irange = 0 > ( maxbin + width*[-1,1] ) < (n_elements(e_inc)-1)
        i1= irange[0]
        i2= irange[1]
        ind = [i1:i2]

      endif else begin
        ind = where(e_inc lt nrg_meas + nrg_meas_delta + 400. ,/null)
      endelse
      ind = where(e_inc lt nrg_meas + nrg_meas_delta + 400. ,/null)
      e = e_inc[ind]
      de = de_inc[ind]
      r = rr[ind]
      pk.g  = total(r)   
      pk.e0 = total(r * e) /pk.g
      pk.s  = sqrt(total(r*(e-pk.e0)^2)/pk.g)
      pks[b] = pk
      

      pk2.n  = total(evb[ind],/double)           ; this portion is still not verified correct   
      pk2.n2  = total(evb[ind]^2,/double)
      pk2.w = total(evb[ind] *  weight[ind],/double)
      pk2.gde  = total(evb[ind] * de) * gfactor
      pk2.e0 = total(evb[ind] * weight[ind] * e_inc[ind])  / pk2.w
      pk2.s  = sqrt(total(evb[ind] *weight[ind] *(e_inc[ind] - pk2.e0)^2) / pk2.w )
      pk2s[b] = pk2
      
      if keyword_set(test) && strmatch(map_b.name,matchnames) then begin
        wi,1
        lim1 = lim
        lim1.title = lim.title + string(format=' Bin %d ',b) + namestr 
        plot,e_inc,rr > .0001,/xlog,/ylog,_extra=lim1,psym=10  ;,yrange=minmax(rr,/pos),psym=psym,title=title
        oplot,e,r > .0001,color=4,psym=psym
        y = pk.g/n_elements(ind)
        plot_xyerr,/over,pk.e0,y,delta_x=pk.s,delta_y=y*.1,color=6
        
        print,b,pk,pk2
        
        wi,2
        lim2 = lim1
        ylim,lim2,.1,1e6
        y = evb * weight > 1e-1
        plot,_extra=lim2,e_inc,y,psym=psym
        plot_xyerr,/overplot,nrg_meas,1e3,delta_x=nrg_meas_delta/2,psym=4,color=6
        oplot , e_inc[ind], y[ind] , color = 4,psym=psym
        ;wi,3
        ;moms = cumulative_moments(rr,alog(e_inc))
        ;plot_xyerr,e_inc,(alog(e_inc) - moms.x0)/moms.s,ps=-1,/xlog

        if test eq 2 then stop
      endif
    endfor
  ;endfor
  if keyword_set(test) then begin
    wi,4
    !p.multi = [0,0,2]
    lim4=lim
    lim4.xrange=0
    lim4.xlog = 0
    lim4.yrange= [1e-4,10]
    options,lim4,xtitle='Bin #',ytitle='Geom/bin [cm2-ster-eV/bin]'
    options
    
    plot_xyerr,!null,pks.g,_extra=lim4,psym=-3
    plot_xyerr,!null,pk2s.g,/overplot,color=4
    
    lim4b = lim4
    options,lim4b,ytitle='Reconstructed Incident Energy (keV)',yrange=[10.,1e4]
    plot_xyerr,!null,pks.e0,delta_y=pks.s,_extra=lim4b
    plot_xyerr,!null,pk2s.e0,/overplot,delta_y=pk2s.s,color=4
   ; plot_xyerr,!null,pks.e0
    
    !p.multi=0
    
  endif
  
  if 1 then begin
    resp.bmap.e0_inc = pk2s.e0
    resp.bmap.e0_inc_delta = pk2s.s
    resp.bmap.gde = pk2s.gde
  endif
    
    
  
  
  return,pks
end

