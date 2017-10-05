pro mvn_polar_plot,tpname=tpname,tval,val,body=body, over=over,trange=tr,tlabel=tlabel, check_objects=check_objects,spiral_vsw=spiral_vsw
  frame='ECLIPJ2000'
  scale = 149.6e6   ; 1AU in km
  
  dtr = timerange(tr)

  tres = 86400 * 7d 
  tpos = dgen(range=dtr,res=tres/10.)
  pos = spice_body_pos(body,'Sun',utc=tpos,frame=frame, check_objects=check_objects) /scale
  
  if not keyword_set(over) then begin
    lim = struct(/isotropic,xrange=[-1.7,.5],yrange=[-1.7,.6],/xstyle,/ystyle,xtitle='X (A.U.)',ytitle='Y (A.U.)',title='Energetic Ion Flux (log scale)')
    plot,psym=4,[0,0],[0,0],_extra=lim
    over = get_plot_state()
  endif else restore_plot_state,over
  
    
;  col = fix( (t_ -dtr[0]) / (dtr[1]-dtr[0]) * (255-7)) + 7
  col = bytescale(tpos, range=dtr)
  plots,pos[0,*],pos[1,*],color = col , noclip=0
 ; printdat,pos
  
  dt = dtr[1]-dtr[0]
  ticks = ceil(tpos/tres)
  ticks = ticks[ uniq(ticks) ] * tres
  tick_labs = time_string(ticks,tformat=' MTH-DD')
  printdat,tick_labs
  tick_pos =  spice_body_pos(body,'Sun',utc=ticks,frame=frame, check_objects=check_objects) /scale
  plots,tick_pos[0,*],tick_pos[1,*], psym=4, noclip=0
  if keyword_set(tlabel) then begin
     xyouts,tick_pos[0,0:*:4],tick_pos[1,0:*:4],tick_labs[0:*:4]
  endif
;  spiral=1
  if keyword_set(spiral_vsw) then begin
     xs=tick_pos[0,*]
     ys=tick_pos[1,*]
     omega = 2*!pi/3600./24./27.3
     vsw = spiral_vsw /scale
     for i=0,n_elements(ticks)-1,4 do begin
       r1 = sqrt(xs[i]^2+ys[i]^2)
       t1 = ticks[i] 
       phi1 = atan(ys[i],xs[i])
       t= dgen(range=t1+tres*[-2,0])
       col  = bytescale(t, range=dtr)       
       r = (vsw * (t-t1) +r1 ) > 0
       phi = -omega * (t-t1) + phi1
;       phi0 = (phi1 - r1*omega/vsw)
;       phi = dgen(range=-[0,!pi])
       
;       r =  -vsw/omega * phi
       x = r * cos(phi) 
       y = r * sin(phi)
       plots,x,y,color=col, noclip=0,linestyle=2
     endfor
  endif

  if keyword_set(tpname) then begin
     get_data,tpname,data=d,alim=lim
    tval = d.x
    val = d.y  
    str_element,lim,'ylog',ylog
    str_element,lim,'yrange',yrange
    if ~keyword_set(yrange) then yrange = minmax(val,/pos)
    if keyword_set(ylog) then begin
       val = alog10(val)
       yrange= alog10(yrange)
    endif
    val = val / (yrange[1]-yrange[0])
    val = val/5
  endif

  if keyword_set(val) then begin
    ind = minmax(where(tval le dtr[1] and tval ge dtr[0],n))
  
    i0 = ind[0]
    i1 = ind[1]
    t_ = tval[i0:i1]
    val_ = val[i0:i1]
    
    pos =  spice_body_pos(body,'Sun',utc=t_ ,frame=frame, check_objects=check_objects) /scale
    npos = pos * ([1,1,1] # (1+val_) )
    col = bytescale(t_, range=dtr)
    
    plots,npos[0,*],npos[1,*],color =col , noclip=0
  endif


end





;begin main program

if not keyword_set(tr) then begin
  loadct2,39
  tr = ['14 3 19','14 7 19']
  ace_epm_load,/k0,trange=tr
  mvn_sep_var_restore,trange=tr
  f='/disks/data/maven/pfp/sep/l2/full/2014/03/mvn_sep_l2_S2-cal-eflux-svy-full_20140320_87day_v00.cdf'
  cdf2tplot,f
  ylim,'SEP-??_*_eflux',1,1,1
  zlim,'SEP-??_*_eflux',1,1,1
  mk=mvn_spice_kernels(trange=tr)
  spice_kernel_load,mk
  frame='ECLIPJ2000'
  dprint,'Create some TPLOT variables with position data and then plot it.'
  spice_position_to_tplot,'MAVEN','SUN',frame=frame,res=3600d*24,scale=scale,name=n1
  spice_position_to_tplot,'Earth','SUN',frame=frame,res=3600d*24,scale=scale,name=n2
  spice_position_to_tplot,'MARS','SUN',frame=frame,res=3600d*24,scale=scale,name=n3
    
    mvn_sep_create_subarrays,'mvn_sep2_svy',/smooth
    
endif
wi,1

scale = 149.6e6   ; 1AU in km

dtr = time_double(tr)
mars_pos = spice_body_pos('Mars','Sun',utc=dgen(range=dtr,500),frame=frame, check_objects=check_objects) /scale

dtr = time_double(tr)
get_data,'ACE_EPM_K0_Ion_mid',data=ace
ace_pos =  spice_body_pos('Earth','Sun',utc=ace.x,frame=frame, check_objects=check_objects) /scale

wshow

;plot,/nodata,[0,0],/isotropic,xrange=[-1.5,.5],yrang=[-1.5,.5]

;oplot,maven_pos[0,*],maven_pos[1,*]     
;oplot,ace_pos[0,*],ace_pos[1,*]     
;oplot,mars_pos[0,*],mars_pos[1,*]     

get_data,'SEP-2F_ion_eflux',data=sep
maven_pos =spice_body_pos('MAVEN','Sun',utc=sep.x,frame=frame, check_objects=check_objects) /scale

esteps = reform(sep.v[0,*])
flux = sep.y / sep.v  * 1000
w_very_lo = [6,7]
w_lo = [10,11]
w_mid= [14,15,16]
w_hi = [18,19,20]
flux_mid = average(flux[*,w_mid],2)
store_data,'SEP-2f_ion_eflux_mid',data={x:sep.x, y:flux_mid},dlim={ylog:1}


get_data,'mvn_sep2_B-O_<Rate>_Energy',data=sep
flux = sep.y / (replicate(1,n_elements(sep.x)) # sep.v )  * 1000  *20
flux_mid = average(flux[*,[19,20,21]],2)
store_data,'SEP-2B-O_ion_eflux_mid',data={x:sep.x, y:flux_mid},dlim={ylog:1}


;ace_flux 

over = 0

t=ace.x
;y=sin( (t-t[0]) / 86400.)
y = alog10(ace.y)/20.
;y -= min(y)
;mvn_polar_plot,ace.x,y,body='Earth',over=over,trange=tr,/tlabel,/spiral



vsw = 400.
mvn_polar_plot,tpname='ACE_EPM_K0_Ion_mid',body='Earth',over=over,trange=tr,/tlabel,spiral=vsw

t=sep.x
y = alog10(flux_mid)/20.
;y -= min(y)
;mvn_polar_plot,tpname='SEP-2f_ion_eflux_mid',body='MAVEN',over=over,trange=tr, check_objects='MAVEN',tlabel=1,spiral=vsw
mvn_polar_plot,tpname='SEP-2B-O_ion_eflux_mid',body='MAVEN',over=over,trange=tr, check_objects='MAVEN',tlabel=1,spiral=vsw

mvn_polar_plot,body='Mars',over=over,trange=tr,tlabel=1
wshow

options,'ACE_EPM_K0_Ion_mid',colors='r'
options,'SEP-2B-O_ion_eflux_mid',colors='b'
store_data,'Ion_Flux',data='ACE_EPM_K0_Ion_mid SEP-2B-O_ion_eflux_mid'

end


