; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-10-11 10:32:34 -0700 (Fri, 11 Oct 2024) $
; $LastChangedRevision: 32884 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_inst_response_crib.pro $
; $ID: $







;pro swfo_stis_inst_response
;file=  '/Users/davin/Downloads/simulation_results_proton_seed03.dat'
;swfo_stis_read_mult_sim_files,simstat,data,desc=desc,pathnames=file,type=1  ;,dosymm=dosymm
;printdat,simstat,data,desc

;end



function swfo_stis_sim_rotate_by_180,data1          ; simulate the B side
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


function swfo_stis_inst_response_retrieve,pathnames,age_limit=age_limit
  pdunn = file_retrieve(/struct)
  if ~keyword_set(age_limit) then age_limit= 3600*4
  pdunn.min_age_limit=age_limit
  pdunn.local_data_dir = '~/data/pdunn/swfo/stis/'
  pdunn.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/swfo/data/sci/stis/prelaunch/geant/
  pdunn.archive_ext = '.arc'
  pdunn.archive_dir = 'archive/'
  pdunn.ignore_filesize = 1
  files = file_retrieve(pathnames,_extra=pdunn)
  return,files
end


pro swfo_stis_read_mult_sim_files,simstat,data,testrun=testrun,desc=desc,pathnames=pathnames,type=type,dosymm=dosymm
  last_pathname=''
  str_element,simstat,'pathnames',last_pathname
  if array_equal(pathnames,last_pathname) then begin
    dprint,dlevel=1, 'Pathnames: ',pathnames[0],' Match. Returning.'
    return
  endif
  simstat=0
  str_element,/add,simstat,'sensornum',1
  str_element,/add,simstat,'attenuator',0


  files = swfo_stis_inst_response_retrieve(pathnames)
  ;files = pathnames
  ;SIM_Energy_range = [1e1,1e5]
  if ~keyword_set(desc) then desc='4Pi'
  str_element,/add,simstat,'SIM_Energy_range',sim_energy_range
  str_element,/add,simstat,'desc',desc
  str_element,/add,simstat,'files',files
  str_element,/add,simstat,'pathnames',pathnames
  dprint,'Loading: ',files

  fmt = {event:0L,einc:0.,pos:[0.,0.,0.],dir:[0.,0.,0.],edep:[[0.,0.,0.],[0.,0.,0.]],E_tot:0.}   ; [F T O] order in these files
  ;#    Event  |  (keV)  |  Pos_x     Pos_y     Pos_z    |  Dir_x     Dir_y     Dir_z    |     Open1        Open2       open3       Foil1     Foil2     Foil3     Total
  npart=0LL
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

  ;  data.edep = reverse(data.edep,1)   ; switch order to O T F
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
    data=[data,swfo_stis_sim_rotate_by_180(data)]
    simstat.sim_area *= 2
    simstat.npart *=2
  endif

  str_element,/add,simstat,'testrun',testrun
  ;str_element,/add,simstat,'data',data
end



pro swfo_stis_read_mult_sim_files_old,simstat,data,desc=desc,pathnames=pathnames,type=type,dosymm=dosymm
  last_pathname=''
  str_element,simstat,'pathnames',last_pathname
  if array_equal(pathnames,last_pathname) then begin
    dprint,dlevel=1, 'Pathnames: ',pathnames[0],' Match. Returning.'
    return
  endif
  simstat=0
  files = swfo_stis_inst_response_retrieve(pathnames)
  str_element,/add,simstat,'desc',desc
  str_element,/add,simstat,'files',files
  str_element,/add,simstat,'pathnames',pathnames
  dprint,'Loading: ',files
  fmt = {event:0L,einc:0.,pos:[0.,0.,0.],dir:[0.,0.,0.],edep:[[0.,0.,0.],[0.,0.,0.]],E_tot:0.}   ; [F T O] order in these files
  ;#    Event  |  (keV)  |  Pos_x     Pos_y     Pos_z    |  Dir_x     Dir_y     Dir_z    |     Open1        Open2       open3       Foil1     Foil2     Foil3     Total
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
    data=[data,swfo_stis_sim_rotate_by_180(data)]
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



pro swfo_stis_response_simdata_rand,type,data=data,simstat=simstat,seed=seed,window=win
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


;
;function swfo_stis_response_flux_to_bin_cr,b,omega,pnum,response=r,parameter=par  ;,omega=omega
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
;   cr_e = swfo_stis_response_flux_to_bin_CR(param=par.pts.electron,response=par.pts.electron.response)
;   if species eq 'electron' then return,cr_e
;   cr_p = swfo_stis_response_flux_to_bin_CR(param=par.pts.proton  ,response=par.pts.proton.response)
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
pro swfo_stis_response_matrix_plots_lin,r,window=win,single=single
  if keyword_set(win) then     wi,win,/show,wsize=[1100,850]
  ;labels = strsplit('XXX O T OT F FO FT FTO Total',/extract)
  labels = strsplit('XXX 1 2 12 3 13 23 123 Total',/extract)
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
    ;slabel = side ? 'B' : 'A'
    slabel = side ? 'O' : 'F'
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



pro swfo_stis_response_plot_gf,r,window=win,ylog=ylog,xrange=xrange  ;,face=face
  ;            x O  T OT  F  OF  FT FTO   Total
  colors = [0,2, 4, 1, 6,  5,  3, 0,   5]
  linestyle = [0,2]
  yrange = [0,2]
  if ~keyword_set(face) then face=0
  face_str = (['Aft','Both','Front'])[face+1]
  atten = (['Open','Closed'])[r.attenuator]
  SEP  = (['???','SEP1','SEP2'])[r.sensornum]
  title = r.desc+' '+r.particle_name+' '+SEP+' '+atten+' '+face_str


  if keyword_set(win) then     wi,win,/show,wsize=[600,600]
  if keyword_set(ylog) then yrange=[.0001,100]
  str_element,r,'fdesc',subtitle
  einc = r.e_inc
  ;   str_element,r,'xbinrange',xrange
  if not keyword_set(xrange) then xrange = minmax(einc)
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

pro swfo_stis_response_plot,r,window=win,ylog=ylog,fluxfunc=fluxfunc,fst=fst
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
    ;slabel = side ? 'B' : 'A'
    slabel = side ? 'O' : 'F'
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
pro swfo_stis_response_bin_matrix_plot_old,r,window=win,face=face
  if keyword_set(win) then     wi,win,/show,wsize=[500,800],icon=0
  xrange = r.xbinrange
  if n_elements(face) eq 0 then face=0
  face_str = (['Aft','Both','Front'])[face+1]

  title= r.desc+' '+r.particle_name+' ('+r.mapname+') '+face_str
  zrange = minmax(float(r.bin3[*,*,0:255]) ,/pos)
  str_element,r,'fdesc',subtitle
  options,lim,xlog=1,xrange=xrange,yrange=[-2,260],/xstyle,/ystyle,xmargin=[10,10],/zlog,zrange=zrange,/no_interp,xtitle='Incident Energy (keV)',ytitle='Bin Number',title=title,subtitle=subtitle
  ;if not keyword_set(ok1) then ok1 = 1
  if keyword_set(face) then z = reform( r.bin3[*, face lt 0, *] ) else z = total(/pres,r.bin3,2)
  specplot,r.e_inc,r.bin_val,z,limit=lim
  ;bmap = swfo_stis_lut2map(mapnum=r.mapnum)
  bmap = swfo_stis_lut2map(mapnum=r.mapnum,sensor=r.sensornum)
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



pro swfo_stis_response_each_bin,r,bins=bins0,window=win,ylog=ylog,omega=omega
  if n_elements(omega) eq 0 then omega=0
  if keyword_set(win) then     wi,win,/show,wsize=[1200,500],icon=0
  ;bmap = swfo_stis_lut2map(mapnum=r.mapnum)
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


pro swfo_stis_response_each_bin_GF,r,bins=bins0,sbins=sbins,window=win,ylog=ylog,overplot=overplot,omega=omega
  if n_elements(omega) eq 0 then omega=0
  if keyword_set(win) then     wi,win,/show,wsize=[1200,600],icon=0

  bmap = r.bmap
  e_inc = r.e_inc
  de_inc = (r.xlog) ? (r.e_inc * r.xbinsize  * alog(10)) : r.xbinsize
  wght = 1/e_inc^2
  yrange = minmax(r.bin3,pos=ylog)  & ystyle=1
  ;yrange = [.8,1e6]  && ystyle=1
  atten_str = (['Open','Closed'])[r.attenuator]
  SEP  = (['???','SEP1','SEP2'])[r.sensornum]
  ;title= r.desc+' ('+r.mapname+')'
  title= r.desc+' '+r.particle_name+' ('+r.mapname+' '+atten_str+' '+sep+') '
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


;
;
;function swfo_stis_response_spectra,r,fluxfunc
;  message,'Obsolete'
;  ;bmap =  swfo_stis_lut2map(lut=r.lut)
;  ;bmap =  swfo_stis_lut2map(mapnum=r.mapnum)
;  bmap = r.bmap
;  scl = [ [[0.],[0.]] ,1/ r.adc_scale ]
;  remap = [0,1,2,1,3,0,3,2]
;  ftot_scale = scl[remap,*]           ; X O T OT F FO FT FTO
;  ftot_scale[[3,6],*] *=2  ; OT and FT events divided by two
;  ftot_scale[7,*] *= 4     ; FTO events divided by four
;  escale = ftot_scale
;  bmap.x = average(bmap.adc,1) * escale[bmap.fto,bmap.tid]
;  bmap.dx = bmap.num * escale[bmap.fto,bmap.tid]
;
;end
;
;
;
;function swfo_stis_adc_calibration,sensornum
;  message,'obsolete.  Contained within swfo_stis_lut2map.pro'
;  adc_scale =  [[[ 43.77, 38.49, 41.13 ] ,  $  ;1A          O T F
;    [ 41.97, 40.29, 42.28 ]] ,  $  ;1B
;    [[ 40.25, 44.08, 43.90 ] ,  $  ;2A
;    [ 43.22, 43.97, 41.96 ]]]   ;  2B
;  adc_scale = adc_scale[*,*,sensornum] / 59.5
;  return,adc_scale
;end
;
;
;function swfo_stis_cal_adc2nrg,adc,tid,fto
;   message,'Obsolete.'
;   adc_scales = 237./59.5
;   return, adc / adc_scales
;
;end
;


pro swfo_stis_response_omega_plot,window=win,data,_extra=ex,filter=filter,binscale=binscale,simstat=simstat,posflag=posflag
  if n_elements(data) le 1 then begin
    dprint,'At least 2 data points are required'
    ;   return
  endif
  if keyword_set(win) then     wi,win,wsize=round([800,400]*1.) ;,/show,icon=0
  ;printdat,ex
  ok = swfo_stis_response_data_filter(simstat,data,_extra=ex,filter=filter,fdesc=fdesc)

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



pro swfo_stis_response_aperture_plot,window=win,data,_extra=ex,filter=filter,binscale=binscale,simstat=simstat
  ok = swfo_stis_response_data_filter(simstat,data,_extra=ex,filter=filter)
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
  if keyword_set(win) then     wi,win,wsize=round([650,330]*1.)  ;,/show,icon=0
  ;w = where(ok,nw)
  ;dprint,nw
  ;printdat,ex,filter
  xrange = minmax(data.pos[1])
  yrange = minmax(data.pos[2])
  options,lim,xtitle='Y position (mm)',ytitle='Z position (mm)',title=title,xmargin=[10,10],/isotropic,xrange=xrange,yrange=yrange,/xstyle,/ystyle;,subtitle=subtitle
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



;pro makeallpngs,name
;  device,window_state=ws
;  for i =0,20 do  if ws[i] then  makepng,name+'_'+strtrim(i,2),window=i
;
;end


function swfo_stis_rate_correction,rate,deadtime=deadtime
  if ~keyword_set(deadtime) then deadtime = 10e-6
  mrate = 1./ (1 + rate * deadtime)
  return,mrate
end


function psuedo_log_compression_map,nmantissa_bits=nm
  ncol = ishft( 1ul, nm)
  mask = ncol - 1
  c = lindgen(ncol,20-nm)
  mant = c and mask
  expo = ishft(c,-nm)
  dc = ishft(mant + ishft(1,nm),expo-1)
  dc[0:ncol-1] = indgen(ncol)
  return,dc
end


function psuedo_log_compress,d,nmantissa_bits=nm
  dt = d                 ; make a temporary copy
  ncol = ishft( 1ul, nm)
  mask = ncol - 1
  expo = dt * 0
  mant = dt and mask
  while 1 do begin
    w = where( (dt and not mask) ne 0,/null)
    ;printdat,w
    if n_elements(w) eq 0 then break
    expo[w] = expo[w] +1
    mant[w] = dt[w] and mask
    dt[w] = ishft(dt[w],-1)
  endwhile
  cv = ishft(expo,nm) + mant
  return,cv
end



pro swfo_stis_response_plot_simflux,flux_func,window=win,limits=lim ,overplot=overplot,result=result  ;,energy=energy,flux=flux

  if 1 then begin
    calval = swfo_stis_inst_response_calval()
    resp = calval.responses[flux_func.name]
  endif else begin
    resp = flux_func.inst_response
  endelse

  nbins = resp.nbins
  g = total(resp.gb3,2)   ; sum over both faces
  bmap = resp.bmap
  resp_nrg = resp.e_inc
  ;resp_flux = interp(xlog=1,ylog=1,flux,energy,resp_nrg)
  resp_flux = func(resp_nrg,param = flux_func)    ; interpolate the flux to the reponse matrix sampling
  ;resp_rate =  (transpose(g) # resp_flux ) > 1e-5
  resp_rate =  (transpose(resp.Mde) # resp_flux ) > 1e-5
  if arg_present(win) && n_elements(win) eq 1 then wi,win++,wsize = [1200,400]
  options,lim,/ylog,yrange=[1e-4,3e6],xrange=[-2,nbins+5],xmargin=[10,10],/xstyle,/ystyle,ytitle='Count Rate (Hz)'
  xbins = findgen(n_elements(resp_rate))
  plot,noerase=overplot,xbins,resp_rate,  _extra=lim
  deadtime = 8.0e-6
  if 0 then begin
    oplot,resp_rate * swfo_stis_rate_correction(resp_rate,deadtime = deadtime),color=6
    rtot = total(resp_rate)
    corr = swfo_stis_rate_correction(rtot,deadtime=deadtime)
    oplot,resp_rate * corr , color = 4
    printdat,rtot
  endif

  total_rates = fltarr(n_elements(bmap))
  ftobits = [1,2,4]
  for tid=0,1 do begin
    for b = 0,2 do begin
      ok = bmap.tid eq tid and (bmap.fto   and ftobits[b]) ne 0   ;  find all bins that use a particular channel
      w = where(ok,/null)
      rtot = total( resp_rate[w] )
      total_rates[w] += rtot            ; increment total rate in all bins of that use that channel
      dprint, tid, ftobits[b], rtot
    endfor
  endfor
  ;dprint,total_rates
  if 0 then begin
    oplot,total_rates,color=2    
  endif
  oplot,lim.xrange,[1,1]/deadtime,linestyle =1   , color=2
  oplot,lim.xrange,[1,1]/60.,linestyle =1   , color=2
  oplot,lim.xrange,[1,1]*2.,linestyle =1   , color=2

  resp_rate_cor = resp_rate * swfo_stis_rate_correction(total_rates,deadtime=deadtime)
  oplot,resp_rate_cor,color=2
  result = {resp:resp,rate:resp_rate, rate_dtcor: resp_rate_cor}
end


;pro swfo_stis_response_3plot,resp,window=win
;end



pro swfo_stis_swap_det2_det3,data
  for tid=0,1 do begin
    temp = data.edep[2,tid]
    data.edep[2,tid] = data.edep[1,tid]
    data.edep[1,tid] = temp
  endfor

end



function random_poisson,avg,seed=seed  
  common random_poisson_com, pseed
  if isa(seed) then pseed = seed
  n = n_elements(avg)
  cnts = long(avg)
  for i=0l,n-1 do begin
    cnts[i] = randomu(pseed,1,poisson =avg[i],/double)
  endfor
  seed = pseed
  return, cnts
end


function inverse_erf_sigma,x
  common inverse_erf_sigma_common, erf_par
  if ~isa(erf_par) then begin
    xv = dgen(901,[-5.,5.])
    erf_xv = erf(xv)
    erf_par = spline_fit3(!null,erf_xv,xv)
    printdat,erf_par
  endif

  return, -6 > spline_fit3(x,param=erf_par) <6
end


function inverse_erfc_sigma,x
  common inverse_erfc_sigma_common, erfc_par
  if ~isa(erfc_par) then begin
    xv =  dgen(301,[-2.,10.]) 
    erfc_xv =  erfc(xv)/2
    erfc_par = spline_fit3(!null,reverse(erfc_xv),reverse(xv),xlog=1)
    printdat,erfc_par
  endif

  return, -4. > spline_fit3(x,param=erfc_par) < 12.
  ;return,  spline_fit3(x,param=erfc_par) 
end


function poisson_sigma,measured_counts,average_counts,ylog=ylog,psym=psym
  offset=3
  maxcnts = round(average_counts +sqrt(average_counts)*10)+offset > 10
  x = indgen(maxcnts)-offset
  gauss_par = mgauss(/quantize,binsize=1)
  gauss_par.g.x0 = average_counts
  gauss_par.g.s = sqrt(average_counts)
  gdist = mgauss(x,param=gauss_par)
  gauss_par.g.a = 1/total(gdist,/double)
  gdist = mgauss(x,param=gauss_par)
  
  poisson_par = spp_poisson()
  poisson_par.avg = average_counts
  pdist = spp_poisson(x,param=poisson_par)
  
  pdist_cum = total(pdist,/cum)
  gdist_cum = total(gdist,/cum)

  psigma = inverse_erf_sigma(pdist_cum*2-1)
  gsigma = inverse_erf_sigma(gdist_cum*2-1)

  if keyword_set(plotit) || keyword_set(psym) then begin
    !p.multi = [0,1,3]
    plot,x,pdist,ylog=ylog,psym=psym
    oplot,x,gdist,col=6 ,psym=psym
    plot,x,pdist_cum,ylog=ylog,psym=psym
    oplot,x,gdist_cum,col=6,psym=psym
    plot,x,psigma,psym=psym
    oplot,x,gsigma,psym=psym, color=6
    !p.multi=0    
  endif
  
  
  return,gsigma[round(measured_counts)+offset ]
end


; Begin program here

if 0 then $
  allfiles = swfo_stis_inst_response_retrieve('results2/results/*/swfo_stis_*.dat',age_limit=900)

;testrun = '4pi_magcorrect'
;testrun = 'Geom1'
;testrun = '4pi'
;testrun = 'oxygen'
;testrun = 'oxygen_dir'
;testrun = 'run1b'
;testrun = 'Geom1_front'
;testrun = 'Geom1_back'
;testrun = '4pi_sim'
;testrun = '4pi_run05_sep1'
;testrun = '4pi_run05_sep2'
;testrun = 0
;testrun = '4pi_stis_run2'
testrun = '4pi_stis_run3'
testrun = '4pi_stis_run4'
testrun = '4pi_stis_run12'
testrun = '4pi_stis_run13'
;testrun = '4pi_stis'
mapnum=0

if not keyword_set(testrun) then testrun = 'run04_sep2'
undefine,resp_e0,resp_p0,resp_g0,resp_e1,resp_p1,resp_g1,bmap

if ~keyword_set(ltestrun) || ltestrun ne testrun then begin
  undefine,  simstat_e,  simstat_p ,  simstat_g ,  simstat_Ox
  case testrun of

    'run1': begin
      if ~keyword_set(data_e1) then mapnum_last=0
      swfo_stis_response_simulation1_load,-1,data=data_e1,simstat=simstat_e  ; load electrons (but only if data_e1 is not defined
      swfo_stis_response_simulation1_load, 1,data=data_p1,simstat=simstat_p   ; load ions
    end

    'run1b': begin
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames=['results/swfo_stis_e-_AF.dat','results/swfo_stis_e-_AO.dat'],type=-1,/dosymm
      swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames=['results/swfo_stis_proton_AF.dat','results/swfo_stis_proton_AO.dat'],type=+1,/dosymm
      options,simstat_e,xbinsize=0.05
      options,simstat_p,xbinsize=0.05
    end


    '4pi_sim': begin
      swfo_stis_response_simdata_rand,-1,data=data_e1,simstat=simstat_e,seed=seed  ;,window=win
    end

    'high_dens_detectors': begin
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/KoreaDetector/run01/mvn_sep2_e-_seed01_open_AF.dat',type=-1
      ;swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/KoreaDetector/run01/mvn_sep2_e-_seed01_open_AO.dat',type=-1
      ;swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/KoreaDetector/run01/mvn_sep2_proton_seed01_open_AF.dat',type=-1
      ;swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/KoreaDetector/run01/mvn_sep2_proton_seed01_open_AO.dat',type=-1
    end


    'Geom1_front': begin
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/swfo_stis_e-_.dat',type=-1
      swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/geometric_factor/swfo_stis_proton_.dat',type=+1
      swfo_stis_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/swfo_stis_gamma_open_.dat',type=0
      options,simstat_e,xbinsize=0.1
      options,simstat_p,xbinsize=0.1
      options,simstat_g,xbinsize=0.1
    end

    'Geom1_back': begin
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/swfo_stis_e-_back_side_open_.dat',type=-1
      swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/geometric_factor/swfo_stis_proton_back_side_open_.dat',type=+1
      swfo_stis_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/swfo_stis_gamma_back_side_open_.dat',type=0
      options,simstat_e,xbinsize=0.1
      options,simstat_p,xbinsize=0.1
      options,simstat_g,xbinsize=0.1
    end

    'Geom1_both': begin
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/'+['swfo_stis_e-_.dat','swfo_stis_e-_back_side_open_.dat'],type=-1
      swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/geometric_factor/'+['swfo_stis_proton_.dat','swfo_stis_proton_back_side_open_.dat'],type=+1
      swfo_stis_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/'+['swfo_stis_gamma_open_.dat','swfo_stis_gamma_back_side_open_.dat'],type=0
      options,simstat_e,xbinsize=0.1
      options,simstat_p,xbinsize=0.1
      options,simstat_g,xbinsize=0.1
    end

    'closed_back': begin
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/swfo_stis_e-_back_side_closed_.dat',type=-1
      swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/geometric_factor/swfo_stis_proton_back_side_closed_.dat',type=+1
      swfo_stis_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/swfo_stis_gamma_back_side_closed_.dat',type=0
      options,simstat_e,xbinsize=0.1
      options,simstat_p,xbinsize=0.1
      options,simstat_g,xbinsize=0.1
    end

    'closed_front': begin
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/swfo_stis_e-_closed_.dat',type=-1
      swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/geometric_factor/swfo_stis_proton_closed_.dat',type=+1
      swfo_stis_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/swfo_stis_gamma_closed_.dat',type=0
      options,simstat_e,xbinsize=0.1
      options,simstat_p,xbinsize=0.1
      options,simstat_g,xbinsize=0.1
    end

    'run2_iso':begin
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/run2_isotropic/swfo_stis_e-_.dat',type=-1
      swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/run2_isotropic/swfo_stis_proton_.dat',type=+1
      options,simstat_e,xbinsize=1.d/5
      options,simstat_p,xbinsize=1.d/5
    end

    '4pi_open':begin
      ;swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/4PI/run01/swfo_stis_e-_all.dat',type=-1
      ;swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/4PI/run01/swfo_stis_e-_successful.dat',type=-1
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/4PI/run01/swfo_stis_e-_seed??_open.dat',type=-1
      swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/4PI/run01/swfo_stis_proton_seed??_open.dat',type=+1
      swfo_stis_read_mult_sim_files,simstat_g,data_g ,pathnames='results2/results/4PI/run01/swfo_stis_gamma_seed??_open.dat',type=0

      ;swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/run2_isotropic/swfo_stis_proton_.dat',type=+1
      options,simstat_e,xbinsize=1.d/10
      options,simstat_p,xbinsize=1.d/10
      options,simstat_g,xbinsize=1.d/10
    end

    '4pi_magcorrect':begin
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/run2_isotropic/swfo_stis_e-magneticfield_corrected_.dat',type=-1
      swfo_stis_read_mult_sim_files,simstat_p,data_p1,pathnames='results2/results/run2_isotropic/swfo_stis_protonmagneticfield_corrected_.dat',type=+1
      options,simstat_e,xbinsize=1.d/5
      options,simstat_p,xbinsize=1.d/5
    end

    'oxygen':begin  ;
      swfo_stis_read_mult_sim_files,simstat_Ox,data_Ox,pathnames='results2/results/oxygen/swfo_stis_oxygen_.dat',type=2,dosymm=1
      str_element,/add,simstat_Ox,'desc','Oxygen Sim'   ; Needs checking!
      str_element,/add,simstat_Ox,'sensornum',2   ; Needs checking!
      str_element,/add,simstat_Ox,'sim_energy_log',1
      str_element,/add,simstat_Ox,'sim_energy_range',[10.,1e7]
      resp_O0 = swfo_stis_inst_response(simstat_Ox,data_Ox,mapnum=mapnum,bmap=bmap)
    end

    'oxygen_dir':begin  ;
      swfo_stis_read_mult_sim_files,simstat_Ox,data_Ox,pathnames='results2/results/oxygen/swfo_stis_oxygen_randomDir_.dat',type=2,dosymm=1
      str_element,/add,simstat_Ox,'desc','Ox GEOM'   ; Needs checking!
      str_element,/add,simstat_Ox,'particle_name','Oxygen'   ; Needs checking!
      str_element,/add,simstat_Ox,'desc','GEOM'   ; Needs checking!
      str_element,/add,simstat_Ox,'sensornum',2   ; Needs checking!
      str_element,/add,simstat_Ox,'sim_energy_log',1
      str_element,/add,simstat_Ox,'sim_energy_range',[10.,1e7]
      if simstat_ox.sim_area eq 0 then simstat_ox.sim_area= 2 * !pi * 15. ^2   ;  2 circles
      resp_O0 = swfo_stis_inst_response(simstat_Ox,data_Ox,mapnum=mapnum,bmap=bmap)
    end

    'geom1_all_elec':begin  ;
      swfo_stis_read_mult_sim_files,simstat_e,data_e1,pathnames='results2/results/geometric_factor/swfo_stis_e-_allEvents_.dat',type=-1
    end

    'gamma':begin  ;
      swfo_stis_read_mult_sim_files,simstat_g,data_g,pathnames='results2/results/geometric_factor/swfo_stis_gamma_back_side_open_.dat',type=0
    end

    '4pi_stis': begin
      simstat_p = 0
      data_p = 0
      swfo_stis_read_mult_sim_files,simstat_p,data_p,pathnames='simulation_results_proton_seed03.dat',type=+1
      simstat_e = 0
      data_e = 0
      swfo_stis_read_mult_sim_files,simstat_e,data_e,pathnames='simulation_results_e-_seed03.dat',type=+1
    end

    '4pi_stis_run2': begin
      simstat_p = 0
      data_p = 0
      swfo_stis_read_mult_sim_files,simstat_p,data_p,pathnames='simulation_results_run02_seed03_proton.dat',type=+1
      simstat_e = 0
      data_e = 0
      swfo_stis_read_mult_sim_files,simstat_e,data_e,pathnames='simulation_results_run02_seed03_e-.dat',type=+1
    end

    '4pi_stis_run3': begin
      simstat_p = 0
      data_p = 0
      swfo_stis_read_mult_sim_files,simstat_p,data_p,pathnames='simulation_results_run03_seed03_proton.dat',type=+1
      simstat_e = 0
      data_e = 0
      swfo_stis_read_mult_sim_files,simstat_e,data_e,pathnames='simulation_results_run03_seed03_e-.dat',type=+1
      simstat_a = 0
      data_a = 0
      swfo_stis_read_mult_sim_files,simstat_a,data_a,pathnames='simulation_results_run03_seed03_alpha.dat',type=+1
      simstat_g = 0
      data_g = 0
      swfo_stis_read_mult_sim_files,simstat_g,data_g,pathnames='simulation_results_run03_seed03_gamma.dat',type=+1
    end

    '4pi_stis_run4': begin
      simstat_p = 0
      data_p = 0
      swfo_stis_read_mult_sim_files,simstat_p,data_p,pathnames='simulation_results_run04_seed04_proton.dat',type=+1
      simstat_e = 0
      data_e = 0
      swfo_stis_read_mult_sim_files,simstat_e,data_e,pathnames='simulation_results_run04_seed04_e-.dat',type=+1
      simstat_a = 0
      data_a = 0
      swfo_stis_read_mult_sim_files,simstat_a,data_a,pathnames='simulation_results_run04_seed04_alpha.dat',type=+1
      simstat_g = 0
      data_g = 0
      swfo_stis_read_mult_sim_files,simstat_g,data_g,pathnames='simulation_results_run04_seed04_gamma.dat',type=+1
    end


    '4pi_stis_run12': begin
      filename = testrun   + '_v3.sav'
      if file_test(filename) then begin
        restore,filename,/verbose
      endif else begin
        simstat_p = 0
        data_p = 0
        swfo_stis_read_mult_sim_files,testrun=testrun,simstat_p,data_p,pathnames='simulation_results_run12_seed0?_proton.dat',type=+1
        simstat_e = 0
        data_e = 0
        swfo_stis_read_mult_sim_files,testrun=testrun,simstat_e,data_e,pathnames='simulation_results_run12_seed0?_e-.dat',type=+1
        simstat_a = 0
        data_a = 0
        swfo_stis_read_mult_sim_files,testrun=testrun,simstat_a,data_a,pathnames='simulation_results_run12_seed0?_alpha.dat',type=+1
        str_element,/add,simstat_a,'particle_name', 'Alpha'   ; missing from data file
        str_element,/add,simstat_a,'particle_type', 4         ; missing from data file
        simstat_g = 0
        data_g = 0
        swfo_stis_read_mult_sim_files,testrun=testrun,simstat_g,data_g,pathnames='simulation_results_run12_seed0?_gamma.dat',type=+1

        swfo_stis_swap_det2_det3,data_p
        swfo_stis_swap_det2_det3,data_e
        swfo_stis_swap_det2_det3,data_a
        swfo_stis_swap_det2_det3,data_g

        save,simstat_p,data_p,simstat_e,data_e,simstat_a,data_a,simstat_g,data_g,file=filename,/verbose
      endelse
    end


    '4pi_stis_run13': begin
      filename = testrun   + '_v1.sav'
      if file_test(filename) then begin
        restore,filename,/verbose
      endif else begin
        simstat_p = 0
        data_p = 0
        swfo_stis_read_mult_sim_files,testrun=testrun,simstat_p,data_p,pathnames='simulation_results_run12_seed0?_proton.dat',type=+1
        simstat_e = 0
        data_e = 0
        swfo_stis_read_mult_sim_files,testrun=testrun,simstat_e,data_e,pathnames='simulation_results_run13_seed0?_e-.dat',type=+1
        simstat_a = 0
        data_a = 0
        swfo_stis_read_mult_sim_files,testrun=testrun,simstat_a,data_a,pathnames='simulation_results_run12_seed0?_alpha.dat',type=+1
        str_element,/add,simstat_a,'particle_name', 'Alpha'   ; missing from data file
        str_element,/add,simstat_a,'particle_type', 4         ; missing from data file
        simstat_g = 0
        data_g = 0
        swfo_stis_read_mult_sim_files,testrun=testrun,simstat_g,data_g,pathnames='simulation_results_run12_seed0?_gamma.dat',type=+1

        swfo_stis_swap_det2_det3,data_p
        swfo_stis_swap_det2_det3,data_e
        swfo_stis_swap_det2_det3,data_a
        swfo_stis_swap_det2_det3,data_g

        save,simstat_p,data_p,simstat_e,data_e,simstat_a,data_a,simstat_g,data_g,file=filename,/verbose
      endelse
    end




  endcase
endif

ltestrun = testrun



;filename = testrun+'_response-map-'+strtrim(mapnum,2)+'.sav'
;save,file=filename,resp_e0,resp_p0,resp_g0,resp_e1,resp_p1,resp_g1,resp_O0,bmap,mapnum


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

;mapnum= 0

;str_element,/add,simstat_p,'mapnum',mapnum
;str_element,/add,simstat_e,'mapnum',mapnum
;str_element,/add,simstat_g,'mapnum',mapnum
;str_element,/add,simstat_a,'mapnum',mapnum




if 0 then begin
  ;swfo_stis_inst_bin_response,simstat_e,data_e,mapnum=mapnum,noise_level=noise_level
  ;swfo_stis_inst_bin_response,simstat_p,data_p,mapnum=mapnum,noise_level=noise_level
  ; swfo_stis_inst_bin_response,simstat_g,data_g,mapnum=mapnum,noise_level=noise_level
  ;printdat,data_p1,simstat_p

  !p.charsize=1.6
  ;ok = swfo_stis_response_data_filter(simstat_e,data_e1,_extra=f,filter=f)
  win=1
  swfo_stis_response_plots,simstat_p,data_p,window=win,filter=f, response = resp_p
  ;win=11
  ;swfo_stis_response_plots,simstat_e,data_e,window=win,filter=f,response = resp_e
  ;win=21
  ;swfo_stis_response_plots,simstat_g,data_g,window=win,filter=f, response = resp_g

  ;swfo_stis_response_plots,simstat_p1,data_p1,window=win,filter=f
  ;swfo_stis_response_plots,simstat_g,data_g,window=win,filter=f

endif



calval=swfo_stis_inst_response_calval()


if ~keyword_set(p_resp) then begin
  p_resp = swfo_stis_inst_response(simstat_p,data_p,filter=f)
  calval.responses['Proton'] = p_resp
  dprint,'Calculated p_resp'
endif

if ~keyword_set(e_resp) then begin
  e_resp = swfo_stis_inst_response(simstat_e,data_e,filter=f)
  dprint,'Calculated e_resp'
  calval.responses['Electron'] = e_resp
endif

if 0 && ~keyword_set(a_resp) then begin
  a_resp = swfo_stis_inst_response(simstat_a,data_a,filter=f)
  calval.responses[a_resp.particle_name] = a_resp
endif



win=1


if 0 then begin
  test = 0
  p_pks = swfo_stis_inst_response_peakeinc(p_resp,pk2s=p_pk2s,test=test)
  e_pks = swfo_stis_inst_response_peakeinc(e_resp,pk2s=e_pk2s,test=test)

endif


peak = mgauss()
peak.g.a = 10000.
peak.g.x0 = 500
peak.g.s= 300


if ~keyword_set(energy) || 1 then begin
  energy = dgen(/log,range=[1.,1e6],6*4+1)
;  energy = dgen(/log,range=[1.,1e14],14*4+1)
;  energy = dgen(/log,range=[1.,1e7],7*4+1)

  pow = -1.6
  ;pow = -2
  flux_max = 1.01e7 * energy^ pow

  flux_min = 2.48e2 * energy^ pow
  flux_mid = 5.e4 * energy^ pow
  ;flux = 2.5e4 * energy^ pow
  w = where(energy gt 1e3)
  ;flux[w] = flux[w] / 100000.
  pwlin =1
  flux = flux_mid;n / 100 ;_mid / 100.
endif

if 1 then begin
  pow_p = -1.6
  flux =  100. * (energy/50.) ^ pow_p
  w = where(energy gt 900)
  flux = flux; *200
  ;flux = flux_min
  ;flux[w] = flux[w] / 100.

  
endif




if 1 then begin
  flux_cosmicray =  10^1.5 *( (energy/1e7) ^ (-2.667)  )   ;(m2 -st -s Gev)-1
  flux_cosmicray = flux_cosmicray < 10^ 3.2
  flux_cosmicray    /=  1e10   ; (cm2 -st -s kev)-1
  cray_cutoff = 1e5
  flux_cosmicray[ where(energy lt cray_cutoff) ] = 0
  
endif



p_flux = flux   + flux_cosmicray
e_flux = flux/energy *1000
e_flux = flux  /4 ;*2
w = where(energy gt 900,/null)
;e_flux[w] = e_flux[w]/1000 
a_flux = p_flux /40
;cr_flux = flux_cosmicray


p_func_true = spline_fit3(!null,energy,p_flux,/xlog,/ylog,pwlin=pwlin)
;p_func = peak
str_element,/add,p_func_true,'name','Proton'
e_func_true = spline_fit3(!null,energy,e_flux,/xlog,/ylog,pwlin=pwlin)
str_element,/add,e_func_true,'name','Electron'
a_func_true = spline_fit3(!null,energy,a_flux,/xlog,/ylog,pwlin=pwlin)
str_element,/add,a_func_true,'name','Alpha'

;str_element,/add,p_func,'inst_response',p_resp
;str_element,/add,e_func,'inst_response',e_resp
;str_element,/add,a_func,'inst_response',a_resp

flux_func_true = swfo_stis_response_func(eflux_func = e_func_true,pflux_func=p_func_true)


if 1 then begin
  swfo_stis_inst_response_matmult_plot,p_func_true,window=win++
  makepng,'swfo_stis_proton_response_matrix'
  swfo_stis_inst_response_matmult_plot,e_func_true,window=win++
  makepng,'swfo_stis_electron_response_matrix
endif


p_rate_true = func(param=flux_func_true,0,choice=1)
e_rate_true = func(param=flux_func_true,0,choice=2)
t_rate_true = func(param=flux_func_true,0,choice=3)

deltatime = 300.
t_cnts_meas = random_poisson(deltatime * t_rate_true)
t_rate_meas = t_cnts_meas / deltatime




wi,win++  ,/show
ylim,rlim,1e-5,1e5,1
xlim,rlim,-10,700
box,rlim

oplot,t_rate_true
oplot,p_rate_true,color=6
oplot,e_rate_true,color=2


;  method = 1
;swfo_stis_response_rate2flux,p_rate,p_resp,method=method
;swfo_stis_response_rate2flux,e_rate,p_resp,method=method
;swfo_stis_response_rate2flux,t_rate,p_resp,method=method

if 0 then begin
  wi,win++ ,/show

  swfo_stis_response_simflux_plot,flux_func = flux_func_true
  swfo_stis_response_simflux_plot,p_resp,rate=t_rate_true,   /over, name = 'O-3',color=0
  swfo_stis_response_simflux_plot,p_resp,rate=p_rate_true,   /over, name = 'O-3',color=6
  ;swfo_stis_response_simflux_plot,p_resp,rate=e_rate_true,   /over, name = 'O-3',color=2

  swfo_stis_response_simflux_plot,e_resp,rate=t_rate_true,   /over, name = 'F-3',color=0;,psym=2
  ;swfo_stis_response_simflux_plot,e_resp,rate=p_rate_true,   /over, name = 'F-3',color=6;,psym=2
  swfo_stis_response_simflux_plot,e_resp,rate=e_rate_true,   /over, name = 'F-3',color=2;,psym=2

  oplot,energy,flux_min
  oplot,energy,flux_max


  w_p = where(/null,p_resp.bmap.name eq 'O-3' and finite(p_resp.bmap.E0_inc) )
  p_energy_recon = p_resp.bmap[w_p].e0_inc
  p_energy_recon = [25.,45.,70,100,200,500,1000,5000]
  p_energy_recon = [p_energy_recon, 2e4,2e5]

  p_func_recon = spline_fit3(!null,p_energy_recon, 1d4 * p_energy_recon ^ (-2)  ,/xlog,/ylog,pwlin=1)   ; initial guess



  ;w_e = where(/null,e_resp.bmap.name eq 'F-3' and finite(e_resp.bmap.E0_inc))
  ;energy_e = e_resp.bmap[w].e0_inc
  ;flux_e  = 1e4 * energy_e ^ (-2)
  ;e_flux_func_recon = s

  e_energy_recon = [30.,100.,1000.,3000.,10000.]
  e_func_recon = spline_fit3(!null,e_energy_recon, .1 * e_energy_recon ^ (-2)  ,/xlog,/ylog,pwlin=1)   ; initial guess

  flux_func_recon = swfo_stis_response_func(eflux_func = e_func_recon,pflux_func=p_func_recon)

  ;swfo_stis_response_simflux_plot,flux_func = flux_func_recon,/over


  
endif



wi,win++,/show

box,rlim
oplot,t_rate_true
oplot,p_rate_true ,color=6
oplot,e_rate_true,color=2


if ~isa(flux_window,'GRAPHICSWIN') then begin
  flux_window = window(dimensions=[800,800],window_title='Flux Window')
endif else begin
  flux_window.erase
  flux_window.show
endelse


if  ~isa(flux_plot,'PLOT') then begin
  dummydat = [1,1]
  flux_plot = plot(dummydat,/nodata,/ylog,yrange=[1e-4,1e6],xrange=[5,2e6],/xlog,/xstyle,current=flux_window $
     ,xtitle='Incident Energy (keV)',Ytitle='Flux (#/s/ster/cm^2/keV',title='Flux vs Energy' $
     ,font_size=15,window_title='Flux Plot')
  flux_plot.uvalue = dictionary()
  dummy = plot(energy,flux_min,':',/over)
  dummy = plot(energy,flux_max,':',/over)
  dummy = plot(energy,flux_mid,':',/over)
  dummy = plot([50,50.],[1.,1e4],/over,':')
  dummy = plot([2000.,2000.],[.002,5e1],':',/over)
  p_flux_plot=plot(dummydat, /overplot ,'.rd',transparency=90,name='Proton flux',sym_size=.5)
  flux_plot.uvalue.p_flux_plot = p_flux_plot
  e_flux_plot=plot(dummydat, /overplot ,'.bd',transparency=90,name='Electron flux',sym_size=.5)
  flux_plot.uvalue.e_flux_plot = e_flux_plot
  ;t_flux_plot=plot(dummydat, /overplot ,'-',name='Electron rate')
  ;tt = strsplit('O_1 F_1 O_2 F_2 O_12 F_12 O_3 F_3 O_13 F_13 O_23 F_23 O_123 F_123',/extract)
  ;i = indgen(n_elements(tt))
  colors = ['red','blue'] ;,'cyan','magenta']
  ncolors = n_elements(colors)
  ;  ttt = text(i*48+24,1e5+i,tt,/data,alignment=0.5, color = colors[i mod ncolors], font_size=8)

  ;flux_window = flux_plot.window
  ;flux_window.window_title = 'Rate Plot'

endif

p_flux_plot.setdata,  energy, p_flux
e_flux_plot.setdata,  energy, e_flux

if ~isa(rate_window,'GRAPHICSWIN') then begin
  rate_window = window(dimensions=[1600,800],window_title='Rate Window')
endif else begin
  rate_window.erase
endelse

if ~isa(rate_plot,'PLOT') then begin
  dummydat = [1,1]
  rate_plot = plot(dummydat,/nodata,/ylog,yrange=[1e-4,1e6],xrange=[-10,685],/xstyle,current=rate_window $
    ,xtitle='Bin Number',Ytitle='Count Rate',title='Raw Rates vs Bin #',font_size=15,layout=[1,2,1],margin=.1)
  rate_plot.uvalue = dictionary()
  p_rate_plot=plot(dummydat,/nodata, /overplot ,' .r',sym_size=3,name='Proton rate')
  rate_plot.uvalue.p_rate_plot = p_rate_plot
  e_rate_plot=plot(dummydat, /overplot ,' .b',sym_size=3,name='Electron rate')
  rate_plot.uvalue.e_rate_plot = e_rate_plot
  t_rate_plot=plot(dummydat, /overplot ,'-',name='Total rate')
  rate_plot.uvalue.t_rate_plot = t_rate_plot
  tt = strsplit('O_1 F_1 O_2 F_2 O_12 F_12 O_3 F_3 O_13 F_13 O_23 F_23 O_123 F_123',/extract)
  i = indgen(n_elements(tt))
  colors = ['red','blue'] ;,'cyan','magenta']
  ncolors = n_elements(colors) 
  ttt = text(i*48+24,1e5+i,tt,/data,alignment=0.5, color = colors[i mod ncolors], font_size=8)
   rate_plot.window_title = 'Rate Plot'

   cnts_plot = plot(dummydat,/nodata,/ylog,yrange=[1e-2,1e8],xrange=[-10,685],/xstyle,current=rate_window $
     ,xtitle='Bin Number',Ytitle='Counts',title='Raw Counts vs Bin #',font_size=15,layout=[1,2,2],margin=.1)
   cnts_plot.uvalue = dictionary()
   p_cnts_plot=plot(dummydat,/nodata, overplot=cnts_plot ,' .r',sym_size=3,name='Proton rate')
   cnts_plot.uvalue.p_cnts_plot = p_cnts_plot
   e_cnts_plot=plot(dummydat, overplot=cnts_plot ,' .b',sym_size=3,name='Electron rate')
   cnts_plot.uvalue.e_cnts_plot = e_cnts_plot
   t_cnts_plot=plot(dummydat, overplot=cnts_plot ,'-d',name='Total rate',sym_size = .5)
   cnts_plot.uvalue.t_cnts_plot = t_cnts_plot

endif

e_rate_plot.setdata, e_rate_true
p_rate_plot.setdata, p_rate_true
t_rate_plot.setdata, t_rate_true

t_cnts_plot.setdata,t_cnts_meas

if 0 then begin
  t_rate_recon = func(param=flux_func_recon,0)
  oplot,t_rate_recon > 1e-5,color = 4
;  fit,0,rate_t ,param = flux_func_recon,/logfit,names = 'pflux.ys[1,2,3]
  t_rate_recon = func(param=flux_func_recon,0)
  oplot,t_rate_recon > 1e-5,color = 3
endif

print,win
wi,win++,/show

swfo_stis_response_simflux_plot,flux_func = flux_func_true  ;,rate=t_cnts_meas/deltatime
;swfo_stis_response_simflux_plot,p_resp,rate=t_rate_true,   /over , name = 'O-3',color=1
oplot,energy,flux_min,linestyle=1
oplot,energy,flux_max,linestyle=1
oplot,energy,flux_mid,linestyle=1

;flux_plot = plot()
;flux_plot = get_plot_state()

flux_window.show

;p = plot(energy,flux,'r5',transparency=90,/over)





func_recon = swfo_stis_response_correct_flux(t_rate_meas,rate_plot=rate_plot,flux_plot=flux_plot)   ;,flux_plot=flux_plot)

;func_recon = swfo_stis_response_correct_flux(t_rate_true,rate_plot=rate_plot,flux_plot=flux_plot)   ;,flux_plot=flux_plot)


end





