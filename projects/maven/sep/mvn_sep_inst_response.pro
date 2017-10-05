

function mvn_sep_sim_rotate_by_180,data1          ; simulate the B side
data2 = data1
data2.pos[0] = -data1.pos[0]
data2.pos[1] = -data1.pos[1]
data2.dir[0] = -data1.dir[0]
data2.dir[1] = -data1.dir[1]
data2.edep[*,0] = data1.edep[*,1]
data2.edep[*,1] = data1.edep[*,0]
;data2.a      = data1.b
;data2.b      = data1.a
return,data2
end


function mvn_sep_inst_response_retrieve,pathnames,age_limit=age_limit
pdunn = file_retrieve(/struct)
if ~keyword_set(age_limit) then age_limit=900 ; 3600*4
pdunn.min_age_limit=age_limit
pdunn.local_data_dir = '~/data/pdunn/'
pdunn.remote_data_dir = 'http://sprg.ssl.berkeley.edu/~davin/pdunn/'
pdunn.archive_ext = '.arc'
pdunn.archive_dir = 'archive/'
pdunn.ignore_filesize = 1
files = file_retrieve(pathnames,_extra=pdunn)
return,files
end



pro mvn_sep_read_mult_sim_files,simstat,data,desc=desc,pathnames=pathnames,type=type,dosymm=dosymm
last_pathname=''
str_element,simstat,'pathnames',last_pathname
if array_equal(pathnames,last_pathname) then begin
    dprint,dlevel=1, 'Pathnames: ',pathnames[0],' Match. Returning.'
    return
endif
simstat=0
files = mvn_sep_inst_response_retrieve(pathnames)
str_element,/add,simstat,'desc',desc
str_element,/add,simstat,'files',files
str_element,/add,simstat,'pathnames',pathnames
dprint,'Loading: ',files
fmt = {event:0L,einc:0.,pos:[0.,0.,0.],dir:[0.,0.,0.],edep:[[0.,0.,0.],[0.,0.,0.]],E_tot:0.}   ; [F T O] order in these files
;#    Event  |  (keV)  |  Pos_x     Pos_y     Pos_z    |  Dir_x     Dir_y     Dir_z    |     AF        AT        AO        BF        BT        BO     Total
npart=0
data=0
;e_inc_num=0.
;if keyword_set(xbinsize) then begin
;endif

for i=0,n_elements(files)-1 do begin
  file = files[i]
  d = read_asc(file,simstat,format=fmt)
  ns = max(d.event)     ; estimate of number of test particles
  descfile = str_sub(file,'.dat','.txt')
  if file_test(/regular,descfile) then printdat,read_asc(descfile,simstat)
 ; str_element,simstat,'numberofparticles',ns
  dprint,dlevel=2,'Loaded',n_elements(d),' data samples out of ',ns,' in ',file
  npart += ns     
  append_array,data,d 
;  if keyword_set(xbinsize) then begin
;      e_inc_num += 
;  endif
endfor

data.edep = reverse(data.edep,1)   ; switch order to O T F
data.dir = shift(data.dir,1,0)     ; rotate through axes
data.pos = shift(data.pos,1,0)     ;

if n_elements(type) eq 1 then str_element,/add,data,'type',replicate(type,n_elements(data))
;str_element,/add,data,'det_ed',reform([data.a,data.b],3,2,n_elements(data))
tp = n_elements(type) eq 1 ? type : 0
;if ~keyword_set(npart) then npart = max(data.event)
sim_area = 0.
str_element,simstat,'sim_area',sim_area
if 0 then begin
w = where(data.event gt shift(data.event,-1),nroll)              ; account for multiple files
npart = total(/preserve,data[w].event)
endif else nroll =1

str_element,/add,simstat,'npart',npart
str_element,/add,simstat,'sim_area',sim_area * nroll     ; account for multiple files - assume all have same area.
if keyword_set(dosymm) then begin
    data=[data,mvn_sep_sim_rotate_by_180(data)]
    simstat.sim_area *= 2
    simstat.npart *=2
endif

;str_element,/add,simstat,'data',data
end


function reform2,vec
if n_elements(vec) eq 1 then return, vec[0]
return, reform(vec)
end



;+
;FUNCTION:  crossp_trans(a,b)
;INPUT: 
; a,b:  real(3,n) vector arrays dimension (3,n) or (3)
;PURPOSE:
; performs cross product on arrays
;CREATED BY:
; Davin Larson
;-
function crossp_trans,a,b
  if n_params() ne 2 then message, ' Wrong format, Use: crossp2(a,b)'
  dim_a = size(/dimen,a)
  dim_b = size(/dimen,b)
    dim = n_elements(dim_a) eq 2 ? dim_a : dim_b   ; crude but works
    c=replicate(a[0]*b[0] , dim)
 ;   printdat,dim_a,dim_b,c
    c[0,*]= reform2(a[1,*]) * reform2(b[2,*]) - reform2(a[2,*]) * reform2(b[1,*])
    c[1,*]= reform2(a[2,*]) * reform2(b[0,*]) - reform2(a[0,*]) * reform2(b[2,*]) 
    c[2,*]= reform2(a[0,*]) * reform2(b[1,*]) - reform2(a[1,*]) * reform2(b[0,*]) 
    return,c
end



pro mvn_sep_response_simdata_rand,type,data=data,simstat=simstat,seed=seed,window=win
if not keyword_set(type) then type = 0
if keyword_set(simstat) then return
dprint,'Creating simulated data distribution'
d={event:0L,einc:0.,pos:[0.,0.,0.],dir:[0.,0.,0.],A:[0.,0.,0.],B:[0.,0.,0.],e_tot:0., type:0}
d = {event:0L,einc:0.,pos:[0.,0.,0.],dir:[0.,0.,0.],edep:[[0.,0.,0.],[0.,0.,0.]],E_tot:0.}   ; [F T O] order in these files
n = 20000000L
n = 10000000L
;n = 1000000L
log10_sr = [0,5d]
str_element,/add,simstat,'sim_energy_range', 10d ^ log10_sr
str_element,/add,simstat,'sim_energy_log', 1
str_element,/add,simstat,'sphere_radius', 80.  ; mm
str_element,/add,simstat,'sim_area', simstat.sphere_radius^2 *!dpi  ; mm^2
str_element,/add,simstat,'npart',n
str_element,/add,simstat,'desc','Sim'
str_element,/add,simstat,'Particle_name','simpart'
str_element,/add,simstat,'xbinsize',.1d
;str_element,/add,simstat,'area', 1.
data = replicate(d,n)
data.event = lindgen(n)
data.einc = 10d^(log10_sr[0] + randomu(seed,n) * (log10_sr[1]-log10_sr[0]))
; Random distribution of starting points over surface of sphere
phi = randomu(seed,n) * 360d
theta = asin(randomu(seed,n) * 2-1) *180/!dpi
sphere_to_cart,simstat.sphere_radius,theta,phi,vec=vec
data.pos = transpose(vec)
; Get Random directions
  phi = randomu(seed,n) * 360d
  oldway=0
if oldway then begin 
  theta = asin(randomu(seed,n) * 2-1) *180/!dpi     ;  uniform distribution of directons
endif else begin
  theta = asin( sqrt( randomu(seed,n)  )   ) *180/!dpi  ; non-uniform - Better for surface of sphere
endelse
  sphere_to_cart,1,theta,phi,vec=vec
  data.dir = transpose(vec)
; Must rotate direction distribution into position of starting point on sphere
if oldway then begin
  w = where( total(data.pos * data.dir,1) gt 0, nw)
  if nw ne 0 then data[w].dir = -data[w].dir              ; force inward trajectories  only
endif else begin
  q = get_quaternion(-data.pos,/last_index)
  q[0,*] = -q[0,*]    ; inverse rotation
  temp = quaternion_rotation(data.dir,q,/last_index)  
  data.dir = temp
endelse
if n_elements(win) ne 0 then begin
  wi,win,/show,wsize=[600,800]
  xyz_to_polar,vec,theta=th2,phi=ph2,mag=r,/ph_0_360
  !p.multi=[0,0,4]
  printdat,phi,theta
  plot,xb,histbins(phi,xb),xtitle='PHI'
  if keyword_set(ph2) then oplot,color=2,xb,histbins(phi,xb)
  plot,xb,histbins(theta,xb,/shift),xtitle='THETA'
  if keyword_set(th2) then oplot,color=6,xb,histbins(theta,xb)
;  plot,xb,histbins(r,xb,range=[0,2])
  psym=10
  plot,xb,histbins(vec[*,0],xb,/shift),yrange=n*[0,2.]/n_elements(xb),psym=psym
  oplot,xb,histbins(vec[*,1],xb,/shift),color=2,psym=psym
  oplot,xb,histbins(vec[*,2],xb,/shift),color=6,psym=psym

  plot,xb,histbins( total( data.pos *data.dir,1), xb),xtitle='POS dot DIR'
  !p.multi=0
  printdat,xb
endif
;data.type = type
emin = ([10.,0.,200.])[type+1]
emin = 0
data.edep[2,*] =  reform([1,1] # (data.einc-emin) > 0.,[1,2,n])
end


function mvn_sep_adc_calibration
;message,'obsolete.  Contained within mvn_sep_lut2map.pro'
adc_scale =  [[[ 43.77, 38.49, 41.13 ] ,  $  ;1A          O T F
               [ 41.97, 40.29, 42.28 ]] ,  $  ;1B
              [[ 40.25, 44.08, 43.90 ] ,  $  ;2A
               [ 43.22, 43.97, 41.96 ]]]   ;  2B
adc_scale = adc_scale / 59.5   
return,adc_scale
end

;
;function mvn_sep_response_flux_to_bin_cr,b,omega,pnum,response=r,parameter=par  ;,omega=omega
;if n_elements(omega) eq 0 then omega = [0,1]
;;n_omega = n_elements(omega)
;;n_einc  = n_elements(r.e_inc)
;;n_bins
;;types = [0,1]
;flux =  func(r.e_inc,omega,param=par)
;flux_dim = size(/dimen,flux)
;resp = r.bin3
;resp_dim = size(/dimen,resp)
;
;de_inc = (r.xlog) ? (r.e_inc * r.xbinsize  * alog(10)) : r.xbinsize
;de_inc = de_inc # replicate(1,flux_dim[1])
;de_flux = de_inc * flux
;
;;printdat,de_inc,de_flux
;resp = reform(resp,resp_dim[0]*resp_dim[1],resp_dim[2])
;de_flux = reform(de_flux,flux_dim[0] * flux_dim[1])
;;printdat,resp,de_flux
;CR = resp ## de_flux
;CR *=  (r.area_cm2 / r.nd)
;if keyword_set(b) then CR=CR[b]
;return,reform(CR)
;end
;


;function particle_flux,energy,omega,parameter=par,response=r,dflux50=dflux50,name=name
;if n_elements(omega) eq 0 then omega=[0,1]
;if ~keyword_set(par) || keyword_set(r) then begin
;    if ~keyword_set(r) then r=0
;    if ~keyword_set(name) then name = ''
;    if ~keyword_set(dflux50) then dflux50 = 100.
;    nrg = 10.^[1.5,2,2.5,3,3.5,4,4.5,6.]
;    flx = dflux50 * (nrg/50.)^(-3)
;    flux = spline_fit3(nrg,nrg,flx,/xlog,/ylog,par =pflux)
;    par = {func:'particle_flux', $
;           name:name, $
;           spec:replicate(pflux,n_elements(omega)) , $
;           response:r,  $
;           units_name:'flux'}
;    par.spec[1].ys -= .1
;    if n_params() eq 0 then return,par
;    printdat,par
;endif    
;fluxes=fltarr(n_elements(energy),n_elements(omega))
;for i=0,n_elements(omega)-1 do begin
;  fluxes[*,i] = spline_fit3(energy,param=par.spec[omega[i]])
;endfor
;return,fluxes
;end



;
;function all_flux,energy,omega,parameter=par,Electron_response=re,Proton_response=rp,species=species
;if ~keyword_set(species) then species=''
;if n_elements(omega) eq 0 then omega=[0,1]
;if ~keyword_set(par) || keyword_set(re) || keyword_set(rp) then begin
;    electron = particle_flux(response=re,name='Electron',dflux50=.5)
;    proton   = particle_flux(response=rp,name='Proton',dflux50=10.)
;    par ={func:'all_flux', pts:{electron:electron, Proton:proton}, units:'CR' }
;    if n_params() eq 0 then return,par
;endif
;dt = size(/type,energy)
;if (dt eq 4) || (dt eq 5) then begin
;   el_flux = func(energy,omega,param=par.pts.electron)
;   pr_flux = func(energy,omega,param=par.pts.proton)
;   if species eq 'electron' then return,el_flux
;   if species eq 'proton' then return,pr_flux
;   return,el_flux + pr_flux
;endif
;;if n_params() eq 0 then energy=par.pts.electron.response.e_inc
;
;if 1 || par.units eq 'CR' then begin
;   cr_e = mvn_sep_response_flux_to_bin_CR(param=par.pts.electron,response=par.pts.electron.response)
;   if species eq 'electron' then return,cr_e
;   cr_p = mvn_sep_response_flux_to_bin_CR(param=par.pts.proton  ,response=par.pts.proton.response)
;   if species eq 'proton' then return,cr_p
;   cr_t = cr_p+ cr_e
;endif
;
;if dt eq 2  or dt eq 1 or dt eq 3 then return, cr_t[energy]    ; energy is the index
;
;return,cr_t
;
;end




;
;
;function particle_flux,energy,omega,type,nrg=nrg,flx=flx,parameter=par
;if keyword_set(nrg) and keyword_set(flx) then begin
;    newflux = spline_fit3(energy,nrg,flx,/xlog,/ylog,par=electron)
;    newflux = spline_fit3(energy,nrg,flx,/xlog,/ylog,par=ion)
;    par = {func:'particle_flux',$ 
;           electron:electron,       $
;           ion: ion, $
;           units_name:'Flux'}
;endif
;elec_flux = spline_fit3(energy,param=par.electron)
;ion_flux = spline_fit3(energy,param=par.ion)
;return,elec_flux
;end
;

;  Multiple matrix plots
pro mvn_sep_response_matrix_plots,r,window=win,single=single
if keyword_set(win) then     wi,win,/show,wsize=[1100,850]
labels = strsplit('XXX O T OT F FO FT FTO Total',/extract)
zrange = minmax(r.g4,/pos) 
xrange = r.xbinrange
yrange = r.ybinrange
options,lim,xlog=1,/ylog,xrange=xrange,/ystyle,/xstyle,yrange=yrange,xmargin=[10,10],/zlog,zrange=zrange,/no_interp,xtitle='Energy incident (keV)',ytitle='Enery Deposited (keV)'
if not keyword_set(single) then !p.multi = [0,4,4]
if not keyword_set(ok1) then ok1 = 1
wnum=0
atten = (['Open','Closed'])[r.attenuator]
title = r.desc+' '+r.particle_name+' SEP '+atten+' '

for side =0,1 do begin
  slabel = side ? 'B' : 'A'
  for fto = 1,8 do begin
     if fto eq 8 then G2 = total(r.g4[*,*,1:7,side],3) $
     else G2 = r.g4[*,*,fto,side]
dprint,dlevel=3,side,fto,total(g2)
    options,lim,title = title+slabel+'_'+labels[fto]
    if keyword_set(single) then begin
       if single ne fto then continue
       if side ne 0 then continue
    endif
    specplot,r.e_inc,r.e_meas,G2,limit=lim
    oplot,dgen(),dgen(),linestyle=1
  endfor
endfor
!p.multi=0
end


;  Multiple matrix plots
pro mvn_sep_response_matrix_plots_lin,r,window=win,single=single
  if keyword_set(win) then     wi,win,/show,wsize=[1100,850]
  labels = strsplit('XXX O T OT F FO FT FTO Total',/extract)
  zrange = minmax(r.g4,/pos)
  xrange = r.xbinrange
  yrange = r.ybinrange
  xrange = [0.,200]
  yrange = [0.,200]
  options,lim,xlog=0,ylog=0,xrange=xrange,/ystyle,/xstyle,yrange=yrange,xmargin=[10,10],/zlog,zrange=zrange,/no_interp,xtitle='Energy incident (keV)',ytitle='Enery Deposited (keV)'
  if not keyword_set(single) then !p.multi = [0,4,4]
  if not keyword_set(ok1) then ok1 = 1
  wnum=0
  for side =0,1 do begin
    slabel = side ? 'B' : 'A'
    for fto = 1,8 do begin
      if fto eq 8 then G2 = total(r.g4[*,*,1:7,side],3) $
      else G2 = r.g4[*,*,fto,side]
      dprint,dlevel=3,side,fto,total(g2)
      options,lim,title = slabel+'_'+labels[fto]
      if keyword_set(single) then begin
        if single ne fto then continue
        if side ne 0 then continue
      endif
      specplot,r.e_inc,r.e_meas,G2,limit=lim
      oplot,dgen(),dgen(),linestyle=1
    endfor
  endfor
  !p.multi=0
end



pro mvn_sep_response_plot_gf,r,window=win,ylog=ylog,xrange=xrange  ;,face=face
;            x O  T OT  F  OF  FT FTO   Total
   colors = [0,2, 4, 1, 6,  5,  3, 0,   5]
   linestyle = [0,2]
   yrange = [0,2]
   if ~keyword_set(face) then face=0
   face_str = (['Aft','Both','Front'])[face+1]
   face_str=''
   
   if keyword_set(win) then     wi,win,/show,wsize=[600,600]
   if keyword_set(ylog) then yrange=[.0001,100]
   str_element,r,'fdesc',subtitle
   einc = r.e_inc
   str_element,r,'xbinrange',xrange
   if not keyword_set(xrange) then xrange = minmax(einc)
   xrange = [1e3,1e5]
   title = r.desc+' '+r.particle_name+' '+face_str
   for side=0,1 do begin
     ls = linestyle[side]
     G = total( total(r.G4[*,*,*,side],3), 2) 
     if ~keyword_set(fst) then  plot,[1,2],/nodata,xrange=xrange,/xlog,/xstyle,thick=2,yrange=yrange,ylog=ylog,xtitle='Incident Energy (keV)',ytitle='Geometric Area (cm^2)',title=title,subtitle=subtitle
     fst=1
;     oplot , einc,G   ,color = colors[8],linestyle =ls   ; total
     for fto = 1,7 do begin
       G = total(r.g4[*,*,fto,side],2) 
       oplot,einc,G > yrange[0]/3,color=colors[fto],linestyle=ls,thick=1
     endfor
   endfor
end

pro mvn_sep_response_plot,r,window=win,ylog=ylog,fluxfunc=fluxfunc,fst=fst
   colors = [0,2,4,1,6,5,3,0,5]
   linestyle = [0,2]
   yrange = [0,2]
   if keyword_set(win) then     wi,win,/show,wsize=[600,800]
   if keyword_set(ylog) then yrange=[.0001,1000]
   einc = r.e_inc
   emeas = r.e_meas
   flux = keyword_set(fluxfunc) ? func(param=fluxfunc,einc) : replicate(1,n_elements(einc)) 
   de_inc = (r.xlog) ? (einc * r.xbinsize  * alog(10)) : r.xbinsize
   deflux = de_inc * flux
   de_meas = (r.ylog) ? (emeas * r.ybinsize *alog(10)) : r.ybinsize
   dprint,dlevel=1,r.desc,r.xbinsize,r.ybinsize
   for side=0,1 do begin
     slabel = side ? 'B' : 'A'
     ls = linestyle[side]
     CR= reform( total(r.G4[*,*,1:7,side],3) ## deflux ) / de_meas
     dprint,'Total Counts in ',slabel,':',total(cr * de_meas)
     if ~keyword_set(fst) then  plot,[1,2],/nodata,xrange=minmax([emeas,einc]),/xlog,yrange=yrange,ylog=ylog,xtitle='Energy (keV)',ytitle='Count Rate per keV',title=r.desc
     fst=1
     oplot , emeas,CR   ,color = colors[8],linestyle =ls,psym=10
     for fto = 1,7 do begin
       CR = reform(r.g4[*,*,fto,side] ## deflux) /de_meas
       oplot,emeas,CR,color=colors[fto],linestyle=ls,psym=10
       dprint,dlevel=3,side,fto,total(CR * de_meas)
     endfor
   endfor
end


; ADC bin Response  MATRIX
pro mvn_sep_response_bin_matrix_plot_old,r,window=win,face=face
if keyword_set(win) then     wi,win,/show,wsize=[500,800],icon=0
xrange = r.xbinrange
if n_elements(face) eq 0 then face=0
face_str = (['Aft','Both','Front'])[face+1]

title= r.desc+' '+r.particle_name+' ('+r.mapname+') '+face_str
zrange = minmax(float(r.bin3[*,*,0:255]) ,/pos)
str_element,r,'fdesc',subtitle
options,lim,xlog=1,xrange=xrange,yrange=[-1,260],/xstyle,/ystyle,xmargin=[10,10],/zlog,zrange=zrange,/no_interp,xtitle='Incident Energy (keV)',ytitle='Bin Number',title=title,subtitle=subtitle
;if not keyword_set(ok1) then ok1 = 1
if keyword_set(face) then z = reform( r.bin3[*, face lt 0, *] ) else z = total(/pres,r.bin3,2)
specplot,r.e_inc,r.bin_val,z,limit=lim
;bmap = mvn_sep_lut2map(mapnum=r.mapnum)
bmap = mvn_sep_lut2map(mapnum=r.mapnum,sensor=r.sensornum)
;bmap = r.bmap
for tid=0,1 do begin
  for fto=1,7 do begin
     w = where(bmap.tid eq tid and bmap.fto eq fto,nw)
     if nw gt 0 then begin
        b = bmap[w].bin
        bmap0 = bmap[w[0]]
        oplot,b*0.+ xrange[0]*1.5,b,psym=bmap0.psym,symsize=.5,color=bmap0.color
        xyouts,xrange[0]*1.5,average(b),' '+bmap0.name,color=bmap0.color        
     endif
  endfor
endfor

end


; ADC bin Response  MATRIX (transposed)
pro mvn_sep_response_bin_matrix_plot,r,window=win,face=face,transpose=transpose,overplot=overplot,energy_range=ei_range,zlog=zlog
if n_elements(zlog) eq 0 then zlog=1
if ~keyword_set(ei_range) then ei_range = minmax(r.e_inc)
bin_range = [-2,260]
if n_elements(face) eq 0 then face=0
face_str = (['Aft','Both','Front'])[face+1]
atten_str = (['Open','Closed'])[r.attenuator]
title= r.desc+' '+r.particle_name+' ('+r.mapname+' '+atten_str+') '+face_str
resp_matrix = float(r.bin3[*,*,0:255] )   * (r.sim_area /100 / r.nd * 3.14)
zrange = minmax(resp_matrix ,/pos)
if keyword_set(face) then z = reform( resp_matrix[*, face lt 0, *] ) else z = total(/pres,resp_matrix,2)
str_element,r,'fdesc',subtitle
if keyword_set(transpose) then begin
  options,lim,ylog=1,xrange=bin_range,yrange=ei_range,/xstyle,/ystyle,xmargin=[10,10],zlog=zlog,zrange=zrange,/no_interp,ytitle='Incident Energy (keV)',xtitle='Bin Number',title=title
  if keyword_set(win) then     wi,win,/show,wsize=[1300,800],icon=0
  x = indgen(256)
  y = r.e_inc
  z = transpose(z)
endif else begin
  options,lim,xlog=1,xrange=ei_range,yrange=bin_range,/xstyle,/ystyle,xmargin=[10,10],zlog=zlog,zrange=zrange,/no_interp,xtitle='Incident Energy (keV)',ytitle='Bin Number',title=title,subtitle=subtitle
  if keyword_set(win) then     wi,win,/show,wsize=[500,800],icon=0
  y = indgen(256)
  x = r.e_inc
endelse
;if not keyword_set(ok1) then ok1 = 1
specplot,x,y,z,limit=lim
overplot=get_plot_state()
bmap = mvn_sep_get_bmap(r.mapnum,r.sensornum)
;bmap = r.bmap
labpos1 = 5.
labpos2 = 8.
for tid=0,1 do begin
  for fto=1,7 do begin
     w = where(bmap.tid eq tid and bmap.fto eq fto,nw)
     if nw gt 0 then begin
        b = bmap[w].bin
        bmap0 = bmap[w[0]]
        if keyword_set(transpose) then begin
          oplot,b,b*0.+ labpos1,psym=bmap0.psym,symsize=.5,color=bmap0.color
          xyouts,average(b),labpos2,' '+bmap0.name,color=bmap0.color  ,align=.5      
        endif else begin
          oplot,b*0.+ ei_range[0]*1.5,b,psym=bmap0.psym,symsize=.5,color=bmap0.color
          xyouts,ei_range[0]*1.5,average(b),' '+bmap0.name,color=bmap0.color        
        endelse
     endif
  endfor
endfor

end


pro mvn_sep_response_each_bin,r,bins=bins0,window=win,ylog=ylog,omega=omega
if n_elements(omega) eq 0 then omega=0
if keyword_set(win) then     wi,win,/show,wsize=[1200,500],icon=0
;bmap = mvn_sep_lut2map(mapnum=r.mapnum)
bmap =r.bmap
einc = r.e_inc
wght = 1/einc^2
yrange = minmax(r.bin3,pos=ylog)
title= r.desc+' ('+r.mapname+')'
plot,/nodata,minmax(einc,/pos),yrange,/xlog,ylog=ylog,xtitle='Incident Energy (keV)',ytitle='GF',title=title
bins = keyword_set(bins0) ? bins0 : indgen(256)
for i=0,n_elements(bins)-1 do begin
   bin=bins[i]
   dgf = r.bin3[*,omega,bin] 
   oplot,einc,dgf > yrange[0]/2.,color=bmap[bin].color,psym=-bmap[bin].psym,symsize=1
   if keyword_set(bins0) then begin
      dgf_max = max(dgf,emx)
      einc_avg = average(dgf*einc*wght)/average(dgf*wght)
      einc_max = einc[emx]      
      txt = '!c'+bmap[bin].name+'!c'+strtrim(bin,2)
      xyouts,einc_avg,yrange[1],txt,align=.5,color=bmap[bin].color,charsize=1
   endif
endfor

end

pro mvn_sep_response_each_bin_GF,r,bins=bins0,sbins=sbins,window=win,ylog=ylog,overplot=overplot,omega=omega
if n_elements(omega) eq 0 then omega=0
if keyword_set(win) then     wi,win,/show,wsize=[1200,600],icon=0

bmap = r.bmap
e_inc = r.e_inc
de_inc = (r.xlog) ? (r.e_inc * r.xbinsize  * alog(10)) : r.xbinsize
wght = 1/e_inc^2
yrange = minmax(r.bin3,pos=ylog)
yrange = [.8,1e6]
title= r.desc+' ('+r.mapname+')'
if ~keyword_set(overplot) then plot,/nodata,minmax(e_inc,/pos),yrange,ystyle=1,/xlog,ylog=ylog,xtitle='Incident Energy (keV)',ytitle='GF',title=title
overplot = 1
bins = keyword_set(bins0) ? bins0 : indgen(256)
for i=0,n_elements(bins)-1 do begin
   bin=bins[i]
   dgf = r.bin3[*,omega,bin] 
   oplot,e_inc,dgf > yrange[0]/2.,color=bmap[bin].color,psym=-bmap[bin].psym,symsize=1
      dgf_max = max(dgf,emx)
      einc_avg = average(dgf*e_inc*wght)/average(dgf*wght)
      einc_max = e_inc[emx]      
      txt = bmap[bin].name+'!c'+strtrim(bin,2)
      GF = total(dgf )  ;* de_inc)
      oplot,[einc_avg],[gf],/psym
   if keyword_set(bins0) then begin
      xyouts,einc_avg,gf,txt,align=.5,color=bmap[bin].color,charsize=1
   endif
endfor
for i=0,n_elements(sbins)-1 do begin
   bin=sbins[i]
   dgf = r.bin2[*,bin] 
   oplot,e_inc,dgf > yrange[0]/2.,color=bmap[bin].color,psym=-bmap[bin].psym,symsize=1
      dgf_max = max(dgf,emx)
      einc_avg = average(dgf*e_inc*wght)/average(dgf*wght)
      einc_max = e_inc[emx]      
      txt = bmap[bin].name+'!c'+strtrim(bin,2)
      GF = total(dgf )  ;* de_inc)
      oplot,[einc_avg],[gf],/psym
;   if keyword_set(bins0) then begin
      xyouts,einc_avg,gf,txt,align=.5,color=bmap[bin].color,charsize=1
;   endif
endfor

end




function mvn_sep_response_spectra,r,fluxfunc
message,'Obsolete'
;bmap =  mvn_sep_lut2map(lut=r.lut)
;bmap =  mvn_sep_lut2map(mapnum=r.mapnum)
bmap = r.bmap
scl = [ [[0.],[0.]] ,1/ r.adc_scale ]
remap = [0,1,2,1,3,0,3,2]
ftot_scale = scl[remap,*]           ; X O T OT F FO FT FTO
ftot_scale[[3,6],*] *=2  ; OT and FT events divided by two
ftot_scale[7,*] *= 4     ; FTO events divided by four
escale = ftot_scale
bmap.x = average(bmap.adc,1) * escale[bmap.fto,bmap.tid]
bmap.dx = bmap.num * escale[bmap.fto,bmap.tid]
 
end

pro mvn_sep_inst_bin_response,simstat,data,new_seed=new_seed,noise_level=noise_level,mapnum=mapnum,bmap=bmap
;common mvn_sep_inst_bin_response_com , seed
if size(/type,simstat) ne 8  then begin
   undefine,data
   return
endif
if n_elements(new_seed) ne 0 then seed = new_seed
str_element,/add,simstat,'seed',new_seed
n = n_elements(data)
if n le 1 then begin
   dprint,'Must have at least 2 successful events'
   return
endif
;str_element,simstat,'sensornum',sensornum
sensornum = simstat.sensornum
if ~keyword_set(mapnum) then str_element,simstat,'mapnum',mapnum
if ~keyword_set(noise_level) then str_element,simstat,'noise_level',noise_level
if n_elements(noise_level) ne 1 then noise_level=1.
;if n_elements(sensornum) ne 1 then sensornum=1
if n_elements(mapnum) ne 1 then mapnum = 8
noise_rms = noise_level * [[2.,3.,2.],[2.,3.,2.]]   ; noise O T F in kev 
adc_scale = mvn_sep_adc_calibration()
;adc_scale = adc_scale[*,*,sensornum]
threshold = noise_rms * 5   ; 5 sigma threshold
shft = [1,1,1,2,1,1,2,4]
if keyword_set(mapnum) then begin
  lut = mvn_sep_create_lut(mapnum=mapnum)
  mapname = mvn_sep_mapnum_to_mapname(mapnum)
  bmap = mvn_sep_lut2map(lut=lut,sensor=sensornum)
  lut = fix( reform(lut,4096,2,8) )
  lut[*,*,0] = 256                 ;  not triggered (not detected)
  lut[*,*,5] = 257                 ;  FO event  (not handled correctly yet)
endif
one_n = replicate(1,n)
str_element,/add,data,'fto',bytarr(2,n)
str_element,/add,data,'em',fltarr(2,n)
str_element,/add,data,'bin',intarr(2,n)
for side=0,1 do begin
;   slabel = side ? 'B' : 'A'
;   ec3 = side ? data.b : data.a                          ; collected (deposited) energy in each of 3 detectors
   ec3 = data.edep[*,side]                                     ; energy deposited in each of 3 detectors for that side
   noise3 =  (noise_rms[*,side] # one_n) * randomn(seed,3,n)     ; generate noise in kev
   em3 = ec3 + noise3
   fto3 = em3 gt (threshold[*,side] # one_n)           ; determine FTO pattern  based on # above  threshold
   em3 = em3 * fto3                                             ; clear untriggered channels
   em  = total(em3,1)                                           ; total energy in all 3 triggered channels
   scl3 = (adc_scale[*,side,sensornum-1] # one_n)            
   adc3 = long(em3 * scl3)  <  4095
   ftocode = reform(fto3 ## [1,2,4])                        ; This does not properly account for FO events!!
   adc = total(/pres,adc3,1) / shft[ftocode]    ; FT and OT  adc values are divided by 2,  FTO are divided by 4
   adc_bin = lut[adc,side * one_n,ftocode]
   data.fto[side] = ftocode
   data.em[side] = em
   data.bin[side] = adc_bin
;   if keyword_set(add) then begin
;     str_element,/add,data,slabel+'_em',em
;     str_element,/add,data,slabel+'_fto',ftocode
;     str_element,/add,data,slabel+'_adc',adc
;     str_element,/add,data,slabel+'_bin',adc_bin
;   endif
endfor
str_element,/add,simstat,'noise_level',noise_level
str_element,/add,simstat,'mapnum',mapnum
str_element,/add,simstat,'mapname',mapname
;str_element,/add,simstat,'lut',lut
;str_element,/add,simstat,'bmap',bmap

end



;  this function returns a true or false depending on if projection of particle direction will
;  pass through a rectangle centered at pos with edges of size width.
function mvn_sep_response_projection_filter,data,pos,width
  a = (where(width eq 0,nw))[0]   ; must be 2 for now
  if nw ne 1 then message,'At least one of width dimensions must be zero'
  if a ne 0 then message, 'Not ready yet'
  one = replicate(1,n_elements(data))
  pos_ = pos # one                            
  pdist= reform( ( (pos_[a] # one)- data.pos[a]) / data.dir[a]  )          ; projected distance to a-plane
  proj = data.pos + ([1,1,1] # pdist) * data.dir                  ; intersection point of dir line with rectangle's plane
  d  = sqrt(total( (pos_ - proj)^2 ,1) )                       ;  distance to center of rectangle
  ok = pdist gt 0                                                 ; use only particles moving toward rectangle
  ok = ok and proj[1,*] lt pos[1]+width[1]/2.  and proj[1,*] gt pos[1]-width[1]/2.
  ok = ok and (proj[2,*] lt pos[2]+width[2]/2.  and proj[2,*] gt pos[2]-width[2]/2.)
;  ok =ok and ((A_rad lt center) or (B_rad lt center)) 
  return,ok
end



function mvn_sep_response_data_filter,simstat,data,filter=filter, $
 ;     plus_xdir=plus_xdir,minus_xdir=minus_xdir, $
      a_side=a_side,b_side=b_side,o_det=o_det,f_det=f_det,center=center,erange=erange, $
      derange=derange, $
      detname=detname, $
      xdir=xdir,ypos=ypos, $
      fdesc=fdesc, $
      dir = dir, angle = angle,  $
      col_af=col_af,det_af=det_af,impact_bmin=impact_bmin,impact_pos=impact_pos
filter=0
str_element,/add,filter,'xdir',xdir
str_element,/add,filter,'ypos',ypos
str_element,/add,filter,'dir',dir
str_element,/add,filter,'angle',angle
str_element,/add,filter,'a_side',a_side
str_element,/add,filter,'b_side',b_side
str_element,/add,filter,'o_det',o_det
str_element,/add,filter,'f_det',f_det
str_element,/add,filter,'center',center
str_element,/add,filter,'erange',erange
str_element,/add,filter,'derange',derange
str_element,/add,filter,'col_af',col_af
str_element,/add,filter,'det_af',det_af
str_element,/add,filter,'impact_bmin',impact_bmin
str_element,/add,filter,'impact_pos',impact_pos
str_element,/add,filter,'detname',detname

printdat,filter,/val,output=s
s[0]=' '
fdesc = strjoin(strcompress(s,/remove_all),', ')
str_element,/add,filter,'fdesc',fdesc
n = n_elements(data)
if n lt 1 then begin
   dprint,'At least 1 data points are required'
   return,-1
endif
ok = data.e_tot ge 0                   ; all true
one = replicate(1,n_elements(data))
if keyword_set(center) then begin
  det_width=[0,14.4,8.4]
  one = replicate(1,n_elements(data))
  A_pos = [-10,25.,-12.5] # one                              ; note: Z position is a guess.
  A_dist= ( (A_pos[0] # one)- data.pos[0]) / data.dir[2]
  A_proj = data.pos + ([1,1,1] # A_dist) * data.dir
  A_rad  = sqrt(total( (A_pos -A_proj)^2 ,1) )
  B_pos = A_pos *([-1,-1,1] # one)
  B_dist= ( (B_pos[2] # one)- data.pos[2]) / data.dir[2]
  B_proj = data.pos + ([1,1,1]# B_dist) * data.dir
  B_rad  = sqrt(total( (B_pos -B_proj)^2 ,1) )
  ok =ok and ((A_rad lt center) or (B_rad lt center)) 
endif
det_pos = [10.,-25.,-12.5]
det_width = [0,14.4,8.4]
;det_width = [0,10d,10d]
;det_pos = [0,0,0]

col_pos =  det_pos + [30.,0,0]
col_width = 2 * det_width
if keyword_set(det_Af) then  ok = ok and mvn_sep_response_projection_filter(data,det_pos,det_width)
if keyword_set(col_Af) then  ok = ok and mvn_sep_response_projection_filter(data,col_pos,col_width)
if keyword_set(impact_bmin) then begin 
   dpos = (impact_pos # one) -data.pos
   c = crossp_trans(dpos,data.dir)
   b = sqrt(total( c^2, 1 ))
   ok = ok and (b le impact_bmin)
endif
if keyword_set(XDIR) then ok = ok and (data.dir[0] * xdir ge 0)
;if keyword_set(plus_xdir) then ok = ok and (data.dir[0] gt 0)
;if keyword_set(minus_xdir) then ok = ok and (data.dir[0] lt 0)
if keyword_set(YPOS) then ok = ok and (data.pos[1] * YPOS ge 0)
angt = 10d   ; 10 degrees
if keyword_set(angle) then angt = angle
if keyword_set(DIR)  then begin
   ang = acos( total( data.dir * (dir # one ),1 )/sqrt(total(dir^2.))  )  *180 /!dpi
   ok = ok and (ang lt angt)
endif
if keyword_set(a_side) then ok = ok and (data.pos[1] lt 0)
if keyword_set(b_side) then ok = ok and (data.pos[1] gt 0)
if keyword_set(F_det)  then ok = ok and (data.pos[0]*data.pos[1] lt 0)
if keyword_set(O_det)  then ok = ok and (data.pos[0]*data.pos[1] gt 0)
if keyword_set(erange) then ok = ok and (data.einc ge erange[0] and data.einc lt erange[1])
if keyword_set(derange) then ok = ok and (data.e_tot ge derange[0] and data.e_tot lt derange[1])
if keyword_set(detname) then begin
;   str_element,simstat,'bmap',bmap
   bmap = simstat.bmap
;   if ~keyword_set(bmap) then   bmap = mvn_sep_lut2map(lut=simstat.lut)
   bins = where( strmatch(bmap.name,detname) ,nbins)
   ok1 = 0
   for side=0,1 do for b=0,nbins-1 do ok1 = ok1 or (data.bin[side] eq bins[b])
   ok = ok and ok1
endif
w_ok = where(ok,n_ok)
npart =0
str_element,simstat,'npart',npart
s[0]=strjoin(strtrim([n_ok,n,npart],1),'/')
fdesc = strjoin(strcompress(s,/remove_all),', ')
str_element,/add,filter,'fdesc',fdesc


return,ok
end




function mvn_sep_inst_response,simstat,data0,mapnum=mapnum ,noise_level=noise_level,filter=filter ,bmap=bmap
if n_elements(data0) le 1 then begin
   dprint,'Must have at least 2 successful events'
   return,0
endif

mvn_sep_inst_bin_response,simstat,data0,mapnum=mapnum,noise_level=noise_level  ,bmap=bmap

w= where( mvn_sep_response_data_filter(simstat,data0,_extra=filter,filter=out_filter),nw)
if nw le 1 then begin
   dprint,'Filter leaves no data. Must have at least 2 successful events'
;   return,0
endif
if nw lt 10 then begin
   dprint,'Very few samples.',nw
endif
if nw ne 0 then data=data0[w]

;str_element,simstat,'nsuccess',nw
;str_element,simstat,'type',type
;str_element,simstat,'sensornum',sensornum
str_element,simstat,'npart',npart
str_element,simstat,'sim_energy_range',simrange
str_element,simstat,'sim_energy_log',simlog
str_element,simstat,'n_omega',n_omega
;str_element,simstat,'noise_level',noise_level
str_element,simstat,'desc',desc
str_element,simstat,'sim_area',area_mm2
str_element,simstat,'xbinsize',xbinsize
str_element,simstat,'ybinsize',ybinsize

str_element,out_filter,'fdesc',fdesc

area_cm2 = area_mm2/100.
;if n_elements(noise_level) ne 1 then noise_level=1.
;if n_elements(sensornum) ne 1 then sensornum=0
;if n_elements(type) ne 1 then type=0               ;  -1: electrons,  1:protons,   2:???
if ~keyword_set(xbinsize) then xbinsize= .025
if ~keyword_set(ybinsize) then ybinsize= xbinsize

srange =  simlog ? alog10(simrange) : simrange
brange=  minmax([1.,simrange] )        ;[1.,100e3]

xlog=1
ylog=1
xbinrange = brange
ybinrange = brange
ndata = n_elements(data)
ND = npart * xbinsize / (srange[1] - srange[0])
nx_einc = long((xlog ? alog10(xbinrange[1]/xbinrange[0]) : xbinrange[1]-xbinrange[0]) / xbinsize)
ny_emeas= long((ylog ? alog10(ybinrange[1]/ybinrange[0]) : ybinrange[1]-ybinrange[0]) / ybinsize)
xs0 = xlog ? alog(xbinrange[0]) : xbinrange[0]
ys0 = ylog ? alog(ybinrange[0]) : ybinrange[0]
ny_bins = 258L   ; max(lut)+1
if ~keyword_set(n_omega) then n_omega = 2L
G4=fltarr(nx_einc,ny_emeas,8,2)
adcbin_hist = lonarr(nx_einc,n_omega,ny_bins)
adcbin_index= lindgen(nx_einc,n_omega,ny_bins)
bin_val = indgen(ny_bins)
ei_val = ( (indgen(nx_einc)+.5d) *xbinsize) + xs0
if xlog then ei_val = 10.d^ ei_val
em_val = ( (indgen(ny_emeas)+.5d) *ybinsize) + ys0
if ylog then em_val = 10.d^ em_val
if ndata ne 0 then begin
  einc = data.einc
  one_n = replicate(1,ndata)
  for side=0,1 do begin
     ftocode = data.fto[side]
     adc_bin = data.bin[side]
     em      = data.em[side]
     einc_bin = long(  (xlog ? alog10(einc/xbinrange[0]) : einc-xbinrange[0]) / xbinsize )
     omega_bin = data.dir[0] gt 0                                ;  separate into two 'angle' bins based on the x direction
     ind = adcbin_index[einc_bin,omega_bin,adc_bin]
     h = histogram(ind,binsize=1,min=0,max= nx_einc*ny_bins*n_omega-1)   
     adcbin_hist += h
     for fto = 0,7 do begin
;       if fto eq 0 then ok = ftocode gt 0 else $
       ok = fto eq ftocode
       w = where(ok,nw)
       if nw eq 0 then begin
         dprint,dlevel=3,side,fto, ' Not encountered ',desc
         continue
       endif
       G2 = histbins2d(einc[w],em[w],ei_val2,em_val2,xbinsize=xbinsize,ybinsize=ybinsize,xrange=xbinrange,yrange=ybinrange,xlog=xlog,ylog=ylog)
       G2 = G2/ND * area_cm2 ;*!dpi; *2* 4 ; normalize to area  (cm^2) * 4pi ster
       if ~keyword_set(g4) then G4 = replicate(0.,[size(/dimen,G2),8,2] )
       G4[*,*,fto,side] = g2
     endfor
  endfor
endif


response= simstat
str_element,/add,response,'bmap',bmap
str_element,/add,response,'ndata',ndata
str_element,/add,response,'nd',nd
str_element,/add,response,'xlog',xlog
str_element,/add,response,'ylog',ylog
str_element,/add,response,'xbinsize',xbinsize
str_element,/add,response,'ybinsize',ybinsize
str_element,/add,response,'xbinrange',xbinrange
str_element,/add,response,'ybinrange',ybinrange
str_element,/add,response,'e_inc',ei_val
str_element,/add,response,'e_meas',em_val
str_element,/add,response,'G4',g4
str_element,/add,response,'bin3',adcbin_hist
str_element,/add,response,'GB3' , adcbin_hist *  (response.sim_area /100 / response.nd * 3.14)
str_element,/add,response,'bin_val',bin_val
peakeinc = mvn_sep_inst_response_peakeinc(response,width=30)
str_element,/add,response,'peakeinc',peakeinc
str_element,/add,response,'fdesc',fdesc
str_element,/add,response,'filter',out_filter

return,response
end


pro mvn_sep_response_omega_plot,window=win,data,_extra=ex,filter=filter,binscale=binscale,simstat=simstat,posflag=posflag
if n_elements(data) le 1 then begin
   dprint,'At least 2 data points are required'
;   return
endif
if keyword_set(win) then     wi,win,/show,wsize=round([800,400]*1.),icon=0
;printdat,ex
ok = mvn_sep_response_data_filter(simstat,data,_extra=ex,filter=filter,fdesc=fdesc)

title='Angular Direction'
desc = '-'
particle = '-'
if keyword_set(posflag) then title='Position Angle'
str_element,simstat,'title',title
str_element,simstat,'desc',desc
str_element,simstat,'particle_name',particle
title = title+' '+desc+' '+particle
subtitle = fdesc

;if keyword_set(simstat) then begin
;   npart=-1
;   str_element,simstat,'npart',npart
;   n = total(ok)
;   dprint,n ,' of ',npart
;endif
w = where(ok,nw)
erase
;if nw eq 0 then return
xrange = [0,360] 
yrange = [-1,1.] 
!p.multi = [0,2,2]
options,lim,xtitle='Phi (degrees)',ytitle='sin(theta) ',title=title,xmargin=[10,10],xrange=xrange,yrange=yrange,/xstyle,/ystyle,subtitle=fdesc
if nw ne 0 then begin
   dir = keyword_set(posflag) ? data[w].pos : data[w].dir
   xyz_to_polar,transpose(dir),theta=th,phi=ph,mag=r,/ph_0_360
   sth = sind(th)
endif
   plot,_extra=lim,[0,1],/nodata
if keyword_set(binscale) then  begin    ;binscale =1
   xbinsize = binscale / !x.s[1] / !d.x_size 
   ybinsize = binscale / !y.s[1] / !d.y_size
endif
zv = histbins2d(ph,sth,xv,yv,xbinsize=xbinsize,ybinsize=ybinsize,xrange=xrange,yrange=yrange) 
;printdat,xbinsize,ybinsize
;printdat,yv,minmax(yv)
   options,lim,/zlog,zrange=minmax(/pos,[zv[*],1.,10])    ,/no_interp  
   specplot,xv,yv,zv,limit=lim,/overplot
;   if keyword_set(binscale) && binscale ge 10 then oplot,_extra=lim,ph,sind(th),psym=3;,/nodata

   plot,total(zv,1),yv,yrange=yrange,xmargin=[10,10] ,/ystyle  ;,xrange=minmax(tot
   plot,xv,total(zv,2),xrange=xrange,xmargin=[10,10],/xstyle

;directions
if nw ne 0 then begin 
   if keyword_set(posflag) then   range=minmax(dir) else range=[-1,1]
   plot,xb,histbins(dir,xb,range=range),/nodata
   nb = n_elements(xb)
   oplot,xb,histbins(dir[0,*],xb,range=range,/shift,nbins=nb),color=2,psym=10
   oplot,xb,histbins(dir[1,*],xb,range=range,/shift,nbins=nb),color=4,psym=10
   oplot,xb,histbins(dir[2,*],xb,range=range,/shift,nbins=nb),color=6,psym=10
endif

if 0 then begin
   specplot,xv,yv,zv,limit=lim;,/overplot
   if binscale ge 10 then oplot,_extra=lim,ph,sind(th),psym=3;,/nodata
endif
 !p.multi=0



end



pro mvn_sep_response_aperture_plot,window=win,data,_extra=ex,filter=filter,binscale=binscale,simstat=simstat
ok = mvn_sep_response_data_filter(simstat,data,_extra=ex,filter=filter)
w = where(ok,nw)
;if nw le 1 then begin 
;  dprint,'Not enough data'
;  return
;endif
title='Start Position'
desc = ''
particle = ''
str_element,simstat,'title',title
str_element,simstat,'desc',desc
str_element,simstat,'particle_name',particle
title = title+' '+desc+' '+particle
str_element,filter,'fdesc',subtitle
if keyword_set(win) then     wi,win,/show,wsize=round([650,330]*1.),icon=0
;w = where(ok,nw)
;dprint,nw
;printdat,ex,filter
xrange = minmax(data.pos[1])
yrange = minmax(data.pos[2])
options,lim,xtitle='Y position (mm)',ytitle='Z position (mm)',title=title,xmargin=[10,10],/isotropic,xrange=xrange,yrange=yrange,/xstyle,/ystyle,subtitle=subtitle
plot,_extra=lim,[0,1],/nodata
   if nw eq 0 then begin
     dprint, 'No selected data!'
;     erase
     return
   endif  
;    xp = data[w].pos[0]
;    yp = data[w].pos[1]
 if keyword_set(binscale) then begin                          ; binscale =1 gives one bin per pixel
   xbinsize = binscale / !x.s[1] / !d.x_size 
   ybinsize = binscale / !y.s[1] / !d.y_size
 endif
   zv = histbins2d(data[w].pos[1],data[w].pos[2],xv,yv,xbinsize=xbinsize,ybinsize=ybinsize)
   options,lim,/zlog,zrange=minmax(/pos,zv)    ,/no_interp  
   specplot,xv,yv,zv,limit=lim
;   printdat,xv,yv,zv,xbinsize,ybinsize
end



pro makeallpngs,name
  device,window_state=ws
  for i =0,20 do  if ws[i] then  makepng,name+'_'+strtrim(i,2),window=i

end

pro mvn_sep_response_plots,simstat,data,filter=f,window=win             ;,mapnum=mapnum,noise_level=noise_level,seed=seed
if ~ keyword_set(simstat) || ~ keyword_set(data) then return
if not keyword_set(win) then win=1
binscale=3
mvn_sep_response_aperture_plot,data,simstat=simstat,window= win++,_extra=f ,binscale=binscale
mvn_sep_response_omega_plot,data,simstat=simstat,window=win++,_extra=f ,binscale=binscale, /posflag
mvn_sep_response_omega_plot,data,simstat=simstat,window=win++,_extra=f ,binscale=binscale

;we= where( mvn_sep_response_data_filter(simstat,data,_extra=f,filter=f2),nwe)
resp = mvn_sep_inst_response(simstat,data,filter=f)
;printdat,resp
if ~keyword_set(resp) then stop

mvn_sep_response_matrix_plots,resp,window=win++
mvn_sep_response_matrix_plots,resp,window=win++,/single
;mvn_sep_response_bin_matrix_plot,resp,window=win++ ,face=0         ; both faces
mvn_sep_response_bin_matrix_plot,resp,window=win++ ,face=-1
mvn_sep_response_bin_matrix_plot,resp,window=win++ ,face=+1
mvn_sep_response_plot_gf,resp,window=win++,/ylog,xrange=[1e3,1e5]

end






; Begin program here

if 0 then $
   allfiles = mvn_sep_inst_response_retrieve('results2/results/*/mvn_sep_*.dat',age_limit=900)

;testrun = '4pi_magcorrect'
;testrun = 'Geom1'
;testrun = '4pi'
 testrun = 'oxygen'
 testrun = 'oxygen_dir'
;testrun = 'run1b'
;testrun = 'Geom1_front'
;testrun = 'Geom1_back'
;testrun = '4pi_sim'
testrun = '4pi_run05_sep1'
testrun = '4pi_run05_sep2'
;testrun = 0
mapnum=9

if not keyword_set(testrun) then testrun = 'run04_sep2'
undefine,resp_e0,resp_p0,resp_g0,resp_e1,resp_p1,resp_g1,bmap

if ~keyword_set(ltestrun) || ltestrun ne testrun then begin
  undefine,  simstat_e,  simstat_p ,  simstat_g ,  simstat_Ox
endif
ltestrun =testrun
case testrun of 

'run1': begin
if ~keyword_set(data_e1) then mapnum_last=0
mvn_sep_response_simulation1_load,-1,data=data_e1,simstat=simstat_e  ; load electrons (but only if data_e1 is not defined
mvn_sep_response_simulation1_load, 1,data=data_p1,simstat=simstat_p   ; load ions
end

'run1b': begin
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames=['results/mvn_sep_e-_AF.dat','results/mvn_sep_e-_AO.dat'],type=-1,/dosymm
mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames=['results/mvn_sep_proton_AF.dat','results/mvn_sep_proton_AO.dat'],type=+1,/dosymm
options,simstat_e,xbinsize=0.05
options,simstat_p,xbinsize=0.05
end


'4pi_sim': begin
 mvn_sep_response_simdata_rand,-1,data=data_e1,simstat=simstat_e,seed=seed  ;,window=win
end

'high_dens_detectors': begin
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/KoreaDetector/run01/mvn_sep2_e-_seed01_open_AF.dat',type=-1
;mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/KoreaDetector/run01/mvn_sep2_e-_seed01_open_AO.dat',type=-1
;mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/KoreaDetector/run01/mvn_sep2_proton_seed01_open_AF.dat',type=-1
;mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/KoreaDetector/run01/mvn_sep2_proton_seed01_open_AO.dat',type=-1
end


'Geom1_front': begin
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/mvn_sep_e-_.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/geometric_factor/mvn_sep_proton_.dat',type=+1
mvn_sep_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/mvn_sep_gamma_open_.dat',type=0
options,simstat_e,xbinsize=0.1
options,simstat_p,xbinsize=0.1
options,simstat_g,xbinsize=0.1
end

'Geom1_back': begin
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/mvn_sep_e-_back_side_open_.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/geometric_factor/mvn_sep_proton_back_side_open_.dat',type=+1
mvn_sep_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/mvn_sep_gamma_back_side_open_.dat',type=0
options,simstat_e,xbinsize=0.1
options,simstat_p,xbinsize=0.1
options,simstat_g,xbinsize=0.1
end

'Geom1_both': begin
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/'+['mvn_sep_e-_.dat','mvn_sep_e-_back_side_open_.dat'],type=-1
mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/geometric_factor/'+['mvn_sep_proton_.dat','mvn_sep_proton_back_side_open_.dat'],type=+1
mvn_sep_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/'+['mvn_sep_gamma_open_.dat','mvn_sep_gamma_back_side_open_.dat'],type=0
options,simstat_e,xbinsize=0.1
options,simstat_p,xbinsize=0.1
options,simstat_g,xbinsize=0.1
end

'closed_back': begin
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/mvn_sep_e-_back_side_closed_.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/geometric_factor/mvn_sep_proton_back_side_closed_.dat',type=+1
mvn_sep_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/mvn_sep_gamma_back_side_closed_.dat',type=0
options,simstat_e,xbinsize=0.1
options,simstat_p,xbinsize=0.1
options,simstat_g,xbinsize=0.1
end

'closed_front': begin
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/mvn_sep_e-_closed_.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/geometric_factor/mvn_sep_proton_closed_.dat',type=+1
mvn_sep_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/mvn_sep_gamma_closed_.dat',type=0
options,simstat_e,xbinsize=0.1
options,simstat_p,xbinsize=0.1
options,simstat_g,xbinsize=0.1
end

'run2_iso':begin
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/run2_isotropic/mvn_sep_e-_.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/run2_isotropic/mvn_sep_proton_.dat',type=+1
options,simstat_e,xbinsize=1.d/5
options,simstat_p,xbinsize=1.d/5
end

'4pi_open':begin
;mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/4PI/run01/mvn_sep_e-_all.dat',type=-1
;mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/4PI/run01/mvn_sep_e-_successful.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/4PI/run01/mvn_sep_e-_seed??_open.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/4PI/run01/mvn_sep_proton_seed??_open.dat',type=+1
mvn_sep_read_mult_sim_files,simstat_g,data_g ,pathnames='results2/results/4PI/run01/mvn_sep_gamma_seed??_open.dat',type=0

;mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/run2_isotropic/mvn_sep_proton_.dat',type=+1
options,simstat_e,xbinsize=1.d/10
options,simstat_p,xbinsize=1.d/10
options,simstat_g,xbinsize=1.d/10
end

'4pi_magcorrect':begin
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/run2_isotropic/mvn_sep_e-magneticfield_corrected_.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/run2_isotropic/mvn_sep_protonmagneticfield_corrected_.dat',type=+1
options,simstat_e,xbinsize=1.d/5
options,simstat_p,xbinsize=1.d/5
end

'oxygen':begin  ;
mvn_sep_read_mult_sim_files,simstat_Ox,data_Ox,pathnames='results2/results/oxygen/mvn_sep_oxygen_.dat',type=2,dosymm=1
str_element,/add,simstat_Ox,'desc','Oxygen Sim'   ; Needs checking!
str_element,/add,simstat_Ox,'sensornum',2   ; Needs checking!
str_element,/add,simstat_Ox,'sim_energy_log',1
str_element,/add,simstat_Ox,'sim_energy_range',[10.,1e7]
resp_O0 = mvn_sep_inst_response(simstat_Ox,data_Ox,mapnum=mapnum,bmap=bmap)
end

'oxygen_dir':begin  ;
mvn_sep_read_mult_sim_files,simstat_Ox,data_Ox,pathnames='results2/results/oxygen/mvn_sep_oxygen_randomDir_.dat',type=2,dosymm=1
str_element,/add,simstat_Ox,'desc','Ox GEOM'   ; Needs checking!
str_element,/add,simstat_Ox,'particle_name','Oxygen'   ; Needs checking!
str_element,/add,simstat_Ox,'desc','GEOM'   ; Needs checking!
str_element,/add,simstat_Ox,'sensornum',2   ; Needs checking!
str_element,/add,simstat_Ox,'sim_energy_log',1
str_element,/add,simstat_Ox,'sim_energy_range',[10.,1e7]
if simstat_ox.sim_area eq 0 then simstat_ox.sim_area= 2 * !pi * 15. ^2   ;  2 circles
resp_O0 = mvn_sep_inst_response(simstat_Ox,data_Ox,mapnum=mapnum,bmap=bmap)
end

'geom1_all_elec':begin  ;
mvn_sep_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/mvn_sep_e-_allEvents_.dat',type=-1
end

'gamma':begin  ;
mvn_sep_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/mvn_sep_gamma_back_side_open_.dat',type=0
end


'run03_sep1':begin
mvn_sep_read_mult_sim_files,simstat_e,pathnames='results2/results/4PI/run03/mvn_sep1_e-_atten0_seed??_.dat',type=-1,data_e
mvn_sep_read_mult_sim_files,simstat_p,pathnames='results2/results/4PI/run03/mvn_sep1_proton_atten0_seed??_.dat',type=+1,data_p
mvn_sep_read_mult_sim_files,simstat_g,pathnames='results2/results/4PI/run03/mvn_sep1_gamma_atten0_seed??_.dat',type=0,data_g 
resp_e0 = mvn_sep_inst_response(simstat_e,data_e,mapnum=mapnum,bmap=bmap)
resp_p0 = mvn_sep_inst_response(simstat_p,data_p,mapnum=mapnum,bmap=bmap)
resp_g0 = mvn_sep_inst_response(simstat_g,data_g,mapnum=mapnum,bmap=bmap)
mvn_sep_read_mult_sim_files,simstat_e1,data_e1,pathnames='results2/results/4PI/run03/mvn_sep1_e-_atten1_seed??_.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p1,data_p1,pathnames='results2/results/4PI/run03/mvn_sep1_proton_atten1_seed??_.dat',type=+1
mvn_sep_read_mult_sim_files,simstat_g1,data_g1 ,pathnames='results2/results/4PI/run03/mvn_sep1_gamma_atten1_seed??_.dat',type=0
resp_e1 = mvn_sep_inst_response(simstat_e1,data_e1,mapnum=mapnum,bmap=bmap)
resp_p1 = mvn_sep_inst_response(simstat_p1,data_p1,mapnum=mapnum,bmap=bmap)
resp_g1 = mvn_sep_inst_response(simstat_g1,data_g1,mapnum=mapnum,bmap=bmap)
end


'run03_sep2':begin
mvn_sep_read_mult_sim_files,simstat_e,pathnames='results2/results/4PI/run03/mvn_sep2_e-_atten0_seed??_.dat',type=-1,data_e
mvn_sep_read_mult_sim_files,simstat_p,pathnames='results2/results/4PI/run03/mvn_sep2_proton_atten0_seed??_.dat',type=+1,data_p
mvn_sep_read_mult_sim_files,simstat_g,pathnames='results2/results/4PI/run03/mvn_sep2_gamma_atten0_seed??_.dat',type=0,data_g 
resp_e0 = mvn_sep_inst_response(simstat_e,data_e,mapnum=mapnum,bmap=bmap)
resp_p0 = mvn_sep_inst_response(simstat_p,data_p,mapnum=mapnum,bmap=bmap)
resp_g0 = mvn_sep_inst_response(simstat_g,data_g,mapnum=mapnum,bmap=bmap)
mvn_sep_read_mult_sim_files,simstat_e1,data_e1,pathnames='results2/results/4PI/run03/mvn_sep2_e-_atten1_seed??_.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p1,data_p1,pathnames='results2/results/4PI/run03/mvn_sep2_proton_atten1_seed??_.dat',type=+1
mvn_sep_read_mult_sim_files,simstat_g1,data_g1 ,pathnames='results2/results/4PI/run03/mvn_sep2_gamma_atten1_seed??_.dat',type=0
resp_e1 = mvn_sep_inst_response(simstat_e1,data_e1,mapnum=mapnum,bmap=bmap)
resp_p1 = mvn_sep_inst_response(simstat_p1,data_p1,mapnum=mapnum,bmap=bmap)
resp_g1 = mvn_sep_inst_response(simstat_g1,data_g1,mapnum=mapnum,bmap=bmap)
end


'run04_sep1':begin
mvn_sep_read_mult_sim_files,simstat_e,pathnames='results2/results/4PI/run04/mvn_sep1_e-_atten0_seed??_.dat',type=-1,data_e
mvn_sep_read_mult_sim_files,simstat_p,pathnames='results2/results/4PI/run04/mvn_sep1_proton_atten0_seed??_.dat',type=+1,data_p
;mvn_sep_read_mult_sim_files,simstat_g,pathnames='results2/results/4PI/run04/mvn_sep1_gamma_atten0_seed??_.dat',type=0,data_g 
resp_e0 = mvn_sep_inst_response(simstat_e,data_e,mapnum=mapnum,bmap=bmap)
resp_p0 = mvn_sep_inst_response(simstat_p,data_p,mapnum=mapnum,bmap=bmap)
;resp_g0 = mvn_sep_inst_response(simstat_g,data_g,mapnum=mapnum,bmap=bmap)
mvn_sep_read_mult_sim_files,simstat_e1,data_e1,pathnames='results2/results/4PI/run04/mvn_sep1_e-_atten1_seed??_.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p1,data_p1,pathnames='results2/results/4PI/run04/mvn_sep1_proton_atten1_seed??_.dat',type=+1
;mvn_sep_read_mult_sim_files,simstat_g1,data_g1 ,pathnames='results2/results/4PI/run04/mvn_sep1_gamma_atten1_seed??_.dat',type=0
resp_e1 = mvn_sep_inst_response(simstat_e1,data_e1,mapnum=mapnum,bmap=bmap)
resp_p1 = mvn_sep_inst_response(simstat_p1,data_p1,mapnum=mapnum,bmap=bmap)
;resp_g1 = mvn_sep_inst_response(simstat_g1,data_g1,mapnum=mapnum,bmap=bmap)
end



'run04_sep2':begin
mvn_sep_read_mult_sim_files,simstat_e,pathnames='results2/results/4PI/run04/mvn_sep2_e-_atten0_seed??_.dat',type=-1,data_e
mvn_sep_read_mult_sim_files,simstat_p,pathnames='results2/results/4PI/run04/mvn_sep2_proton_atten0_seed??_.dat',type=+1,data_p
;mvn_sep_read_mult_sim_files,simstat_g,pathnames='results2/results/4PI/run04/mvn_sep2_gamma_atten0_seed??_.dat',type=0,data_g 
resp_e0 = mvn_sep_inst_response(simstat_e,data_e,mapnum=mapnum,bmap=bmap)
resp_p0 = mvn_sep_inst_response(simstat_p,data_p,mapnum=mapnum,bmap=bmap)
;resp_g0 = mvn_sep_inst_response(simstat_g,data_g,mapnum=mapnum,bmap=bmap)
mvn_sep_read_mult_sim_files,simstat_e1,data_e1,pathnames='results2/results/4PI/run04/mvn_sep2_e-_atten1_seed??_.dat',type=-1
mvn_sep_read_mult_sim_files,simstat_p1,data_p1,pathnames='results2/results/4PI/run04/mvn_sep2_proton_atten1_seed??_.dat',type=+1
;mvn_sep_read_mult_sim_files,simstat_g1,data_g1 ,pathnames='results2/results/4PI/run04/mvn_sep2_gamma_atten1_seed??_.dat',type=0
resp_e1 = mvn_sep_inst_response(simstat_e1,data_e1,mapnum=mapnum,bmap=bmap)
resp_p1 = mvn_sep_inst_response(simstat_p1,data_p1,mapnum=mapnum,bmap=bmap)
;resp_g1 = mvn_sep_inst_response(simstat_g1,data_g1,mapnum=mapnum,bmap=bmap)
end


'run02B_sep1':begin
  mvn_sep_read_mult_sim_files,simstat_e,pathnames='g4work/sep/results/run02/mvn_sep1_e-_atten0_seed??_.dat',type=-1,data_e
  mvn_sep_read_mult_sim_files,simstat_p,pathnames='g4work/sep/results/run02/mvn_sep1_proton_atten0_seed??_.dat',type=+1,data_p
  ;mvn_sep_read_mult_sim_files,simstat_g,pathnames='g4work/sep/results/run02/mvn_sep1_gamma_atten0_seed??_.dat',type=0,data_g
  resp_e0 = mvn_sep_inst_response(simstat_e,data_e,mapnum=mapnum,bmap=bmap)
  resp_p0 = mvn_sep_inst_response(simstat_p,data_p,mapnum=mapnum,bmap=bmap)
  ;resp_g0 = mvn_sep_inst_response(simstat_g,data_g,mapnum=mapnum,bmap=bmap)
  mvn_sep_read_mult_sim_files,simstat_e1,data_e1,pathnames='g4work/sep/results/run02/mvn_sep1_e-_atten1_seed??_.dat',type=-1
  mvn_sep_read_mult_sim_files,simstat_p1,data_p1,pathnames='g4work/sep/results/run02/mvn_sep1_proton_atten1_seed??_.dat',type=+1
  ;mvn_sep_read_mult_sim_files,simstat_g1,data_g1 ,pathnames='g4work/sep/results/run02/mvn_sep1_gamma_atten1_seed??_.dat',type=0
  resp_e1 = mvn_sep_inst_response(simstat_e1,data_e1,mapnum=mapnum,bmap=bmap)
  resp_p1 = mvn_sep_inst_response(simstat_p1,data_p1,mapnum=mapnum,bmap=bmap)
  ;resp_g1 = mvn_sep_inst_response(simstat_g1,data_g1,mapnum=mapnum,bmap=bmap)
end

'run02B_sep2':begin
  mvn_sep_read_mult_sim_files,simstat_e,pathnames='g4work/sep/results/run02/mvn_sep2_e-_atten0_seed??_.dat',type=-1,data_e
  mvn_sep_read_mult_sim_files,simstat_p,pathnames='g4work/sep/results/run02/mvn_sep2_proton_atten0_seed??_.dat',type=+1,data_p
  ;mvn_sep_read_mult_sim_files,simstat_g,pathnames='g4work/sep/results/run02/mvn_sep2_gamma_atten0_seed??_.dat',type=0,data_g
  resp_e0 = mvn_sep_inst_response(simstat_e,data_e,mapnum=mapnum,bmap=bmap)
  resp_p0 = mvn_sep_inst_response(simstat_p,data_p,mapnum=mapnum,bmap=bmap)
  ;resp_g0 = mvn_sep_inst_response(simstat_g,data_g,mapnum=mapnum,bmap=bmap)
  mvn_sep_read_mult_sim_files,simstat_e1,data_e1,pathnames='g4work/sep/results/run02/mvn_sep2_e-_atten1_seed??_.dat',type=-1
  mvn_sep_read_mult_sim_files,simstat_p1,data_p1,pathnames='g4work/sep/results/run02/mvn_sep2_proton_atten1_seed??_.dat',type=+1
  ;mvn_sep_read_mult_sim_files,simstat_g1,data_g1 ,pathnames='g4work/sep/results/run02/mvn_sep2_gamma_atten1_seed??_.dat',type=0
  resp_e1 = mvn_sep_inst_response(simstat_e1,data_e1,mapnum=mapnum,bmap=bmap)
  resp_p1 = mvn_sep_inst_response(simstat_p1,data_p1,mapnum=mapnum,bmap=bmap)
  ;resp_g1 = mvn_sep_inst_response(simstat_g1,data_g1,mapnum=mapnum,bmap=bmap)
end


'4pi_run05_sep1':begin
  mvn_sep_read_mult_sim_files,simstat_e,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep1_e-_atten0_seed??_.dat',type=-1,data_e
  mvn_sep_read_mult_sim_files,simstat_p,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep1_proton_atten0_seed??_.dat',type=+1,data_p
  ;mvn_sep_read_mult_sim_files,simstat_g,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep1_gamma_atten0_seed??_.dat',type=0,data_g
  str_element,/add,simstat_e,'desc','4Pi'
  str_element,/add,simstat_p,'desc','4Pi'
;  str_element,/add,simstat_g1,'desc','4Pi'
  resp_e0 = mvn_sep_inst_response(simstat_e,data_e,mapnum=mapnum,bmap=bmap)
  resp_p0 = mvn_sep_inst_response(simstat_p,data_p,mapnum=mapnum,bmap=bmap)
  ;resp_g0 = mvn_sep_inst_response(simstat_g,data_g,mapnum=mapnum,bmap=bmap)
  mvn_sep_read_mult_sim_files,simstat_e1,data_e1,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep1_e-_atten1_seed??_.dat',type=-1
  mvn_sep_read_mult_sim_files,simstat_p1,data_p1,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep1_proton_atten1_seed??_.dat',type=+1
  ;mvn_sep_read_mult_sim_files,simstat_g1,data_g1 ,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep1_gamma_atten1_seed??_.dat',type=0
  str_element,/add,simstat_e1,'desc','4Pi'
  str_element,/add,simstat_p1,'desc','4Pi'
  ;  str_element,/add,simstat_g1,'desc','4Pi'
  resp_e1 = mvn_sep_inst_response(simstat_e1,data_e1,mapnum=mapnum,bmap=bmap)
  resp_p1 = mvn_sep_inst_response(simstat_p1,data_p1,mapnum=mapnum,bmap=bmap)
  ;resp_g1 = mvn_sep_inst_response(simstat_g1,data_g1,mapnum=mapnum,bmap=bmap)
end

'4pi_run05_sep2':begin
  mvn_sep_read_mult_sim_files,simstat_e,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep2_e-_atten0_seed??_.dat',type=-1,data_e
  mvn_sep_read_mult_sim_files,simstat_p,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep2_proton_atten0_seed??_.dat',type=+1,data_p
  ;mvn_sep_read_mult_sim_files,simstat_g,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep2_gamma_atten0_seed??_.dat',type=0,data_g
  str_element,/add,simstat_e,'desc','4Pi'
  str_element,/add,simstat_p,'desc','4Pi'
  resp_e0 = mvn_sep_inst_response(simstat_e,data_e,mapnum=mapnum,bmap=bmap)
  resp_p0 = mvn_sep_inst_response(simstat_p,data_p,mapnum=mapnum,bmap=bmap)
  ;resp_g0 = mvn_sep_inst_response(simstat_g,data_g,mapnum=mapnum,bmap=bmap)
  mvn_sep_read_mult_sim_files,simstat_e1,data_e1,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep2_e-_atten1_seed??_.dat',type=-1
  mvn_sep_read_mult_sim_files,simstat_p1,data_p1,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep2_proton_atten1_seed??_.dat',type=+1
  str_element,/add,simstat_e1,'desc','4Pi'
  str_element,/add,simstat_p1,'desc','4Pi'
  ;mvn_sep_read_mult_sim_files,simstat_g1,data_g1 ,pathnames='g4work/davinMaven/results/4PI/run05/mvn_sep2_gamma_atten1_seed??_.dat',type=0
  resp_e1 = mvn_sep_inst_response(simstat_e1,data_e1,mapnum=mapnum,bmap=bmap)
  resp_p1 = mvn_sep_inst_response(simstat_p1,data_p1,mapnum=mapnum,bmap=bmap)
  ;resp_g1 = mvn_sep_inst_response(simstat_g1,data_g1,mapnum=mapnum,bmap=bmap)
end


endcase

filename = testrun+'_response-map-'+strtrim(mapnum,2)+'.sav'
save,file=filename,resp_e0,resp_p0,resp_g0,resp_e1,resp_p1,resp_g1,resp_O0,bmap,mapnum


undefine,f
;dir =[1,0,0]
;xdir = -1
str_element,/add,f,'xdir',xdir
str_element,/add,f,'erange',erange
str_element,/add,f,'dir',dir
str_element,/add,f,'angle',angle
str_element,/add,f,'ypos',ypos
str_element,/add,f,'f_det',f_det
str_element,/add,f,'a_side',a_side
str_element,/add,f,'det_af',det_af
str_element,/add,f,'col_af',col_af
str_element,/add,f,'derange',derange
str_element,/add,f,'detname',detname
str_element,/add,f,'impact_bmin',impact_bmin
str_element,/add,f,'impact_pos',impact_pos
printdat,f,output=s,/val
fdesc = strjoin(strcompress(s,/remove_all),', ')
dprint,fdesc ;,/val

if 1 then begin
mvn_sep_inst_bin_response,simstat_e,data_e,mapnum=mapnum,noise_level=noise_level
mvn_sep_inst_bin_response,simstat_p,data_p,mapnum=mapnum,noise_level=noise_level
mvn_sep_inst_bin_response,simstat_g,data_g,mapnum=mapnum,noise_level=noise_level
;printdat,data_p1,simstat_p

;ok = mvn_sep_response_data_filter(simstat_e,data_e1,_extra=f,filter=f)
win=0
mvn_sep_response_plots,simstat_e,data_e,window=win,filter=f
mvn_sep_response_plots,simstat_p,data_p,window=win,filter=f
mvn_sep_response_plots,simstat_p1,data_p1,window=win,filter=f
mvn_sep_response_plots,simstat_g,data_g,window=win,filter=f

endif

if 0 then begin
resp=resp_p0
bmap =resp.bmap
omega=0
over=0
bins0 = where(strmatch(bmap.name,'B-O'))
;mvn_sep_response_each_bin,resp_p0,bins=bins0,window=20,ylog=1,omega=omega
mvn_sep_response_each_bin_GF,resp_p0,bins=bins0,window=20,ylog=1,omega=omega,over=over
endif


if testrun eq 'oxygen_dir' then begin
  mvn_sep_inst_bin_response,simstat_Ox,data_Ox,mapnum=mapnum,noise_level=noise_level
  win=0
  mvn_sep_response_plots,simstat_Ox,data_Ox,window=win,filter=f

endif



if 0 then begin
erange=[0,0]
w = where(data_e1.einc lt 1e4 and data_e1.fto[0] eq 7)
plot,[1,1],/nodata,xrange=[1,1e4],yrange=[1,1e4],/xlog,/ylog
;oplot,data_e1[w].edep[0,0],data_e1[w].edep[1,0],psym=3
color = bytescale(data_e1[w].einc,range=[500,1e4],/log)
plots,data_e1[w].edep[2,0],data_e1[w].edep[1,0],psym=4,color=color,symsize=.3
endif 


end
