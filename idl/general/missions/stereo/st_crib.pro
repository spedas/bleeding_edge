;st_crib.pro



pro rotation_finder,name ,deltat=deltat
names=tnames(name,n)
if not keyword_set(deltat) then deltat=10.
for i=0,n-1 do begin
   get_data,names[i],data=d
   dt = median(d.x-shift(d.x,1))
   n = ceil(deltat/dt)
   b = smooth(d.y,[n,0],/nan)
   b1 = shift(b,-n,0)
   b2 = shift(b,n,0)
   angle = acos(total((b1*b2),2) / sqrt(total(b1^2,2)*total(b2^2,2)) ) *180/!pi
   store_data,names[i]+'_drot',data={x:d.x, y:angle}
endfor

end



pro st_swea_cut,var,t
  print,time_string(t),var

if not keyword_set(lim) then begin
   xlim,lim,1,2000,1
   ylim,lim,1e5,1e10,1
   units,lim,'eflux'
   options,lim,ymargin=[4,4]
endif

;help,st_swea_dist(tname='sta_SWEAb_Distribution',index=0)
prt=0
data = st_swea_dist(probe='a',t)
wi,1   &  spec3d, data,lim=lim  & wshow  & if prt then makepng,tstr+'_spec_A',/mkdir
;switched plot3d to plot3d_new to avoid name conflict in IDL 8.1
;wi,2   &  plot3d_new, data,/zero  & wshow    & if prt then makepng,tstr+'_p3d_A'
datb = st_swea_dist(probe='b',t)
wi,3   &  spec3d, datb,lim=lim  & wshow  & if prt then makepng,tstr+'_spec_B'
;switched plot3d to plot3d_new to avoid name conflict in IDL 8.1
;wi,4   &  plot3d_new, datb,/zero  & wshow    & if prt then makepng,tstr+'_p3d_B'

;usage:  ctime,routin='st_swea_cut'               ; swea_cut routine

end


pro st_make_data,probe=probe

if not keyword_set(probe) then probe='a'
ndays = 1
t0 = time_double('6-11-3')
dt = ndays*3600d*24d
t0 = floor(t0/dt)*dt
t1= t0 +3*dt
stereo_init
dir = !stereo.local_data_dir + '.temp/'+probe+'/'
root = root_data_dir()+'stereo'
for t=t0,t1,dt do begin
  del_data,'*'
  dprint,time_string(t)
  timespan,t,ndays
  st_swea_load,probe=probe
  st_mag_load,probe=probe
  pathname=time_string(t,tformat='YYYY/st'+probe+'_data_YYYYMMDD_v01')
  tplot_save,file=dir+pathname
endfor



end




if 0 then begin
timespan,'6-11-1'   ; Boom deployment
timespan,'6-11-1',10  ; First ten days
timespan,'6-11-3'   ; first mag
timespan,'6-11-6'   ; Perigee #1
timespan,'6-11-14'   ; Spike in flux at 2 hour separation in time. Caused by off pointing of spacecraft
timespan,'6-11-16', 2 ; type III events
timespan,'6-12-13'   ; - CME
timespan,'6-12-14',1 & t='2006-12-14/14:12'   ; IP shock with trailing Mag cloud
timespan,'6 12 15',2  ; Lunar shadow #1
timespan,'7 1 20',2   ; Lunar shadow #2 (b only)
timespan,'7-3-9'
timespan,'7-3-29'
timespan,'7 4 13',2
timespan,'7-5-1',2   ;- CME
timespan,'7-5-21',2  ; MC
timespan,'7-11-20',1 ; MC
timespan,'8 1 1',1
timespan,'8-1-304',1 ; Test with deflectors off
timespan,'8-4-15',1   ; McFadden's variable flux
endif




tspan = timerange()
if ~keyword_set(lasttspan) ||  ~array_equal(tspan,lasttspan) then begin

lasttspan = 0
;  Set window positions
;   for i=0,4 do wdelete,i

dprint,print_trace=3,/print_dtime,/print_dlevel
wi,0
multi_monitor = !d.y_size gt 1050  ; assume multiscreen if tplot window is large
 ; multi_monitor=1
if keyword_set(multi_monitor) then begin
  wsize = [500,400]
  wpos1 = [0,-1200]
endif else begin
  wsize = [400,300]
  wpos1 = [0,110]
endelse
wdsize = wsize+[8,25]
wi,1,wsize=wsize,wposition= wpos1
wi,2,wsize=wsize,wposition= wpos1 + [0,1]*wdsize
wi,3,wsize=wsize,wposition= wpos1 + [1,0]*wdsize
wi,4,wsize=wsize,wposition= wpos1 + [1,1]*wdsize
wi,0,wsize=[900,1000],wposition = wpos1+ [2,0] * wdsize

tplot_options,'no_interp',1
tplot_options,'datagap',300 ; 5 minute gap


if 0 then begin
   st_position_load
   st_swaves_load
   st_plastic_load
   tplot_restore,/verbose,file=file_retrieve('swaves/boom_potential/APM_Davin.tplot',_extra=!stereo)

endif


   if n_elements(dopad) eq 0 then dopad=1
   if n_elements(bins)  eq 0 then bins=1
   probe = 'b'
   dopad = 1
   if dopad then begin
   st_mag_load,type=magres
;   xyz_to_polar,'st?_B_'+magres+'_SC'
;   xyz_to_polar,'st?_B_'+magres+'_RTN'
   options,'st?_B_*_inst_th',constant=[-60,60.],yrange=[-90,90],/ystyle

   if 0 then begin
     split_vec,'st?_B_8Hz_RTN'
     options,'sta_B_8Hz_RTN_?',colors='r'
     options,'stb_B_8Hz_RTN_?',colors='b'
     store_data,'stx_B_8Hz_RTN_x', data=tnames('st[ab]_B_8Hz_RTN_x')
     store_data,'stx_B_8Hz_RTN_y', data=tnames('st[ab]_B_8Hz_RTN_y')
     store_data,'stx_B_8Hz_RTN_z', data=tnames('st[ab]_B_8Hz_RTN_z')
     ; tplot,' stx_B_RTN_?',/add

     split_vec,'st?_B_8Hz_SC'
     options,'sta_B_8Hz_SC_?',colors='r'
     options,'stb_B_8Hz_SC_?',colors='b'
     store_data,'stx_B_8Hz_SC_x', data=tnames('st[ab]_B_8Hz_SC_x')
     store_data,'stx_B_8Hz_SC_y', data=tnames('st[ab]_B_8Hz_SC_y')
     store_data,'stx_B_8Hz_SC_z', data=tnames('st[ab]_B_8Hz_SC_z')
     ; tplot,' stx_B_SC_?'

     options,'sta_mom_density',colors='r'
     options,'stb_mom_density',colors='b'
     store_data,'stx_mom_density',data=tnames('st[ab]_mom_density')
     ; tplot,'stx_mom_density',/add
   endif

   endif
   st_position_load
   st_swea_load
   st_swea_mag_load
   store_data,'sta_spec',data='sta_SWEA_en sta_SWEA_secondary',dlimit={spec:0,yrange:[1e3,1e10],ystyle:3}
   store_data,'stb_spec',data='stb_SWEA_en stb_SWEA_secondary',dlimit={spec:0,yrange:[1e3,1e10],ystyle:3}
  ; wi_mfi_load
  ; wi_swe_load
   st_part_moments,probe='a',get_pad=dopad,bins=bins,/get_secondary
   reduce_pads,'sta_SWEA_pad',1,4,4
   reduce_pads,'sta_SWEA_pad',2,0,0
   reduce_pads,'sta_SWEA_pad',2,7,7

   st_part_moments,probe='b',get_pad=dopad,bins=bins,/get_secondary
   reduce_pads,'stb_SWEA_pad',1,4,4
   reduce_pads,'stb_SWEA_pad',2,0,0
   reduce_pads,'stb_SWEA_pad',2,7,7
   zlim,'st?_SWEA_en',1e5,5e8,1

   ;l = tnames(/tplot)

  ; tplot ,'wi_??_mfi_B3GSE st?_B_SC st?_s'
; tplot,'st?_B_inst_* st?_pad-1-4:4'
; tplot,'sta_B_inst_* sta_pad-1-4:4'
; tplot,'stb_B_inst_* stb_pad-1-4:4'

; tplot,'STA_B_inst_theta STA_B_inst_phi sta_B_inst_mag sta_pad-1-4:4'
; tplot,'stb_B_inst_* stb_pad-1-4:4'

; tplot,'sta_B_RTN* sta_pad-1-4:4 sta_mom_density
; tplot,'stb_B_RTN* stb_pad-1-4:4 stb_mom_density
; tplot,'sta_pad-* sta_mom_density sta_B_RTN*
;
;tplot,'stb_pad-* stb_mom_density stb_B_RTN*'
;tplot,'sta_pad-* sta_mom_density sta_B_RTN*'
tplot_names

;if keyword_set(tnames(/tplot)) then tplot else  tplot,'st?_en st?_mom_density st?_B_RTN*'
if keyword_set(tnames(/tplot)) then tplot else  tplot,'st?_SWEA_en st?_mom_density st?_B_8Hz_RTN*'
   lasttspan = tspan

endif
;stop
if n_elements(npoints) eq 0 then npoints=1
ctime,t,npoints=npoints;,/silent

if not keyword_set(lim) then begin
   xlim,lim,1,2000,1
   ylim,lim,1e5,1e9,1
   units,lim,'eflux'
   options,lim,ymargin=[4,4]
endif

tstr = 'plots/'+time_string(format=2,t[0])
if n_elements(prt) eq 0 then prt=0


w=!d.window
data = st_swea_dist(probe='a',t)
wi,1   &  spec3d, data,lim=lim  & wshow  & if prt then makepng,tstr+'_spec_A',/mkdir
;switched plot3d to plot3d_new to avoid name conflict in IDL 8.1
wi,2   &  plot3d_new, data,/zero  & wshow    & if prt then makepng,tstr+'_p3d_A'
datb = st_swea_dist(probe='b',t)
wi,3   &  spec3d, datb,lim=lim  & wshow  & if prt then makepng,tstr+'_spec_B'
;switched plot3d to plot3d_new to avoid name conflict in IDL 8.1
wi,4   &  plot3d_new, datb,/zero  & wshow    & if prt then makepng,tstr+'_p3d_B'
timebar,t
wi,w


if 0 then $
  ctime,routin='st_swea_cut'               ; swea_cut routine

;eflux_a = conv_units(data)
pd = pad(conv_units(data))
;  pd = pad2(conv_units(data),vsw=[0,0,500.]);wi,3   &  spec3d, pd


if 0 then begin   ;  .run
split_vec,'st?_mom_velocity'
options,'sta_mom_*',colors='r'
options,'stb_mom_*',colors='b'
store_data,'STA_B_inst_theta',data=tnames('sta_mom_symm_theta sta_B_inst_th',/all)
store_data,'STA_B_inst_phi',data=tnames('sta_mom_symm_phi sta_B_inst_phi',/all)
store_data,'STX_Vx',data=tnames('st?_mom_velocity_x OMNI_HRO_?min_Vx',/all)
store_data,'STX_Vy',data=tnames('st?_mom_velocity_y OMNI_HRO_?min_Vy',/all)
store_data,'STX_Vz',data=tnames('st?_mom_velocity_z OMNI_HRO_?min_Vz',/all)

store_data,'STX_density',data=tnames('st?_mom_density OMNI_HRO_?min_proton_density'),dlim={ylog:1}

store_data,'STB_B_inst_theta',data=tnames('stb_mom_symm_theta stb_B_inst_th',/all)
store_data,'STB_B_inst_phi',data=tnames('stb_mom_symm_phi stb_B_inst_phi')
store_data,'STB_Vx',data=tnames('stb_mom_velocity_x OMNI_HRO_1min_Vx')
store_data,'STB_Vy',data=tnames('stb_mom_velocity_y OMNI_HRO_1min_Vy')
store_data,'STB_Vz',data=tnames('stb_mom_velocity_z OMNI_HRO_1min_Vz')
store_data,'STB_density',data=tnames('stb_mom_density OMNI_HRO_1min_proton_density')

tplot,'ST?_B_inst_theta ST?_B_inst_phi st?_mom_symm_ang'

endif



if 0 then begin   ; fitting routines

; .compile st_swea_distfit


fdat=data
par.vsw =[0,10,-300]
par.halo.n=1
par.sc_pot=-12
par.sc_pot=0
par.sc_pot=12
f = st_swea_distfit(fdat,param=par,/set)

wi,1 ,/show
spec3d,data
spec3d,fdat,/over,/the


xv = dgen(/log,300,[.1,5000])
eff=st_swea_secondary_flux(xv,param=psf)
plot,xv,st_swea_secondary_flux(xv,param=psf),/xlog,/ylog

col=0
pf,psf,col=(++col) mod 7 +1





endif



end





