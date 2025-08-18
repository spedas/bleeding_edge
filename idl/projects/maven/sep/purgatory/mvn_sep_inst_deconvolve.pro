
function mvn_sep_response_load,atten=atten,sepn=sepn,reset=reset,bmap=bm,mapnum=mn
  common mvn_sep_response_load_com,sep1_filename,sep2_filename,sep1_response,sep2_response,bmap,mapnum,e
;  if ~keyword_set(sep1_response) then sep1_response = [[ptr_new(0),ptr_new(0)], $
;                                                       [ptr_new(0),ptr_new(0)], $
;                                                       [ptr_new(0),ptr_new(0)] ]                      
;  if ~keyword_set(sep2_response) then sep2_response = [[ptr_new(0),ptr_new(0)], $
;                                                       [ptr_new(0),ptr_new(0)], $
;                                                       [ptr_new(0),ptr_new(0)] ]                      
  

  if  keyword_set(reset)  then begin
;     ptr_free, ptr_extract(sep1_response)
;     ptr_free, ptr_extract(sep2_response)
     undefine,sep1_response,sep2_response,sep1_filename,sep2_filename
  endif
  if ~keyword_set(sepn) then return,[ptr_new(),ptr_new()]

  if not keyword_set(mn) then mn=8
;  if mn ne 8 then message,'Only Map 8 is ready'

  case sepn of
  1:  begin
      if not keyword_set(sep1_filename) then begin
         sep1_filename='4pi_run05_sep1_response-map-9.sav'
         restore,file=sep1_filename,/verbose
         dprint,sep1_filename,dlevel=1
         sep1_response = [[ptr_new(resp_e0),ptr_new(resp_e1)], $
                         [ptr_new(resp_p0),ptr_new(resp_p1)], $
                         [ptr_new(resp_g0),ptr_new(resp_g1)] ]                      
      endif
      return, reform(sep1_response[atten,*])
      end
  2:  begin
      if not keyword_set(sep2_filename) then begin
         sep2_filename='4pi_run05_sep2_response-map-9.sav'
         restore,file=sep2_filename,/verbose
         dprint,sep2_filename,dlevel=1
;         *sep2_response[0,0] = resp_e0
;         *sep2_response[1,0] = resp_e1
;         *sep2_response[0,1] = resp_p0
;         *sep2_response[1,1] = resp_p1
;         *sep2_response[0,2] = resp_g0
;         *sep2_response[1,2] = resp_g1
         sep2_response = [[ptr_new(resp_e0),ptr_new(resp_e1)], $
                         [ptr_new(resp_p0),ptr_new(resp_p1)], $
                         [ptr_new(resp_g0),ptr_new(resp_g1)] ]                      
      endif
      return, reform(sep2_response[atten,*])
      end
  endcase
end


; returns momentum in units of eV/(km/s),  provide mass in units of eV/(km/s)^2
function particle_momentum,energy,mass=mass,electron=electron,proton=proton,speedoflight = c  ;, kev=kev
c = 299792.d ; km/s
if keyword_set(electron) then mass = 511000.d/c^2  ; eV/(km/s)^2
if keyword_set(proton) then mass =  938272000.d/c^2
mc2 = mass * c^2
;gamma = 1+energy/mc2
momentum = sqrt(2d * energy * mass * (1 + energy/mc2/2d) )
return,momentum
end




function particle_eflux,energy,omega,parameter=par,response=r,dflux50=dflux50,name=name
if n_elements(omega) eq 0 then omega=[0,1]
if ~keyword_set(par) || keyword_set(r) then begin
    if ~keyword_set(r) then r=ptr_new()
    if ~keyword_set(name) then name = ''
    if ~keyword_set(dflux50) then dflux50 = 100.
    xs = 1.4 + findgen(34)/8   ; [1.5,2,2.5,3,3.5,4,4.5,6.]
    nrg = 10.^xs
    eflx = dflux50 * (nrg/50.)^(-1.)
    flux = spline_fit3(nrg,nrg,eflx,/xlog,/ylog,par =pflux)
    par = {func:'particle_eflux', $
           name:name, $
           spec:replicate(pflux,n_elements(omega)) , $
           response:r,  $
           units_name:'flux'}
    par.spec[1].ys -= .2
    if n_params() eq 0 then return,par
    printdat,par
endif    
fluxes=fltarr(n_elements(energy),n_elements(omega))
for i=0,n_elements(omega)-1 do begin
  fluxes[*,i] = spline_fit3(energy,param=par.spec[omega[i]])    ; /energy
endfor
return,fluxes
end



function all_eflux,energy,omega,pnum,parameter=par   ,Electron_response=re,Proton_response=rp
if n_elements(omega) eq 0 then omega=[0,1]
if n_elements(pnum) eq 0 then pnum = [0,1]
if ~keyword_set(par) || keyword_set(re) || keyword_set(rp) then begin
    electron = particle_eflux(response=re,name='Electron',dflux50=.5 *100)
    proton   = particle_eflux(response=rp,name='Proton',dflux50=10. *1000)
;    proton.spec.ys = proton.spec.ys > (-2)
    par ={func:'all_eflux', pts:[electron,proton], units:'CR',bins:replicate(1b,256) }
    if n_params() eq 0 then return,par
endif
dt = size(/type,energy)
if (dt eq 4) || (dt eq 5) then begin
   flux = fltarr(n_elements(energy),n_elements(omega),n_elements(pnum) )
   for p=0,n_elements(pnum)-1 do begin
     tmp = func(energy,omega,param=par.pts[pnum[p]]) 
;     tmp = particle_eflux(energy,omega,param=par.pts[pnum[p]]) 
;     printdat,tmp
     flux[*,*,p] = tmp
   endfor
   return,flux
endif
message,'Invalid Input'

end



function mvn_sep_response_flux_to_bin_cr,b,omega,pnum, parameter=par  ;,omega=omega,pnum=pnum

if n_elements(omega) eq 0 then omega = [0,1]
if n_elements(pnum) eq 0 then pnum = [0,1]

CR = 0
if 0 then begin
for j=0,n_elements(pnum)-1   do begin
  r = *(par.pts[pnum[j]].response)
  de_inc = (r.xlog) ? ( r.xbinsize  * alog(10)) : r.xbinsize/r.e_inc   ; delta_e over e
  resp = r.bin3 
;  dim = size(/dimen,resp)
;  dim2 = [dim[0],dim[1]*dim[2]] 
  for i=0,n_elements(omega)-1 do begin
    eflux =  func(r.e_inc,omega[i],pnum[j],param=par)
;    eflux =  all_eflux(r.e_inc,omega[i],pnum[j],param=par)
    de_flux = de_inc * eflux 
    CR += reform(resp[*,omega[i],*],/overwrite) ## de_flux
  endfor
endfor
endif else begin
for j=0,n_elements(pnum)-1   do begin
  r = *(par.pts[pnum[j]].response)
  if r.xlog ne 1 then message,'Error'
;  de_inc = (r.xlog) ? ( r.xbinsize  * alog(10)) : r.xbinsize/r.e_inc   ; delta_e over e
  de_inc = r.xbinsize * alog(10)
  resp = r.bin3
  dim = size(/dimen,resp)
  resp = reform(/overwrite,resp,dim[0]*dim[1],dim[2])
;  dim2 = [dim[0],dim[1]*dim[2]] 
    eflux =  func(r.e_inc,omega,pnum[j],param=par)
;    eflux =  all_eflux(r.e_inc,omega[i],pnum[j],param=par)
    eflux = reform(eflux,dim[0]*dim[1])
    de_flux = de_inc * eflux 
    CR += resp ## de_flux
endfor
endelse

;    CR *=  (r.area_cm2 / r.nd)
  CR *= (r.sim_area /100 / r.nd * 3.14)
if keyword_set(b) then CR=CR[b] else CR=CR[0:255]
return,CR
end






function mvn_sep_amoeba_min, vec, parameter=par, spectra=spectra, ret_par=ret_par
common mvn_sep_amoeba_min_com, par0,spectra0,dim,ind,v_ind,p_ys,n_ind,nv_ind,c,d
if keyword_set(par) then begin
   par0 = par
   if keyword_set(spectra) then str_element,/add,par0,'spectra',spectra
   str_element,par0,'spectra',spectra0
   dim = size(/dimen,par0.pts.spec.ys)
   str_element,par0,'bins',bins
   n_ind = 256
   if keyword_set(bins) then ind = where(bins,n_ind) else ind= indgen(256)
   v_ind = where( par0.pts.spec.vary,nv_ind )
   p_ys = (par0.pts.spec.ys)[*]
endif 
if keyword_set(ret_par) then return,par0
if n_elements(vec) eq 0 then vec = (par0.pts.spec.ys)[v_ind]

p_ys[v_ind] = vec
par0.pts.spec.ys = reform(p_ys,dim)

model_rate = mvn_sep_response_flux_to_bin_cr(param=par0)
str_element,par0,'background',bg
if keyword_set(bg) then model_rate += bg.data/bg.duration 

;model_rate += bg_rate 
measured_rate = spectra0.data/spectra0.duration
residual = measured_rate - model_rate

chi2 = sqrt(total((residual[ind])^2 )/n_ind)

;ns =16
ys=par0.pts.spec.ys
xs=par0.pts.spec.xs
;dx1 = (xs - shift(xs, 1,0,0))
;dx2 = (shift(xs,-1,0,0) - xs)
;dx2[ns-1,*,*] = dx2[ns-2,*,*]
;dy1 = (ys - shift(ys, 1,0,0)) / dx1
;dy2 = (shift(ys,-1,0,0) - ys) / dx2
;dy2[ns-1,*,*] = par0.pts[*].spec[*].slp_extra
d2 =( (shift(ys,-1,0,0) + shift(ys,1,0,0) -2*ys)/ (shift(xs,-1,0,0) - shift(xs,1,0,0)) )^2 
penalty = total(d2[1:dim[0]-2,*,*]  )/dim[0]    ; sum of all second derivatives

penalty2 = sqrt(total((par0.pts.spec[0].ys - par0.pts.spec[1].ys)^2 ))  ; anisotropy

return,chi2 + penalty/100. + penalty2/500000
end




pro mvn_sep_response_each_bin_old,r,bins=bins0,window=win,ylog=ylog
if keyword_set(win) then     wi,win,/show,wsize=[1200,500],icon=0
bmap = mvn_sep_lut2map(lut=r.lut)
einc = r.e_inc
wght = 1/einc^2
yrange = minmax(r.bin2,pos=ylog)
title= r.desc+' ('+r.mapname+')'
plot,/nodata,minmax(einc,/pos),yrange,/xlog,ylog=ylog,xtitle='Incident Energy (keV)',ytitle='GF',title=title
bins = keyword_set(bins0) ? bins0 : indgen(256)
for i=0,n_elements(bins)-1 do begin
   bin=bins[i]
   dgf = r.bin2[*,bin] 
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

pro mvn_sep_response_each_bin_GF_old,r,bins=bins0,sbins=sbins,window=win,ylog=ylog,overplot=overplot
if keyword_set(win) then     wi,win,/show,wsize=[1200,600],icon=0
bmap = mvn_sep_lut2map(mapnum=r.mapnum,sensor=r.sensornum)
e_inc = r.e_inc
de_inc = (r.xlog) ? (r.e_inc * r.xbinsize  * alog(10)) : r.xbinsize
wght = 1/e_inc^2
yrange = minmax(r.bin2,pos=ylog)
yrange = [.8,1e6]
title= r.desc+' ('+r.mapname+')'
if ~keyword_set(overplot) then plot,/nodata,minmax(e_inc,/pos),yrange,ystyle=1,/xlog,ylog=ylog,xtitle='Incident Energy (keV)',ytitle='GF',title=title
overplot = 1
bins = keyword_set(bins0) ? bins0 : indgen(256)
for i=0,n_elements(bins)-1 do begin
   bin=bins[i]
   dgf = r.bin2[*,bin] 
;   oplot,e_inc,dgf > yrange[0]/2.,color=bmap[bin].color,psym=-bmap[bin].psym,symsize=1
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





pro mvn_sep_eflux_plot,param=par0,window = win,units=units,overplot=overplot

if keyword_set(win) then wi,3,wsize = [500,700],/show
if ~keyword_set(units) then units = 'Eflux
flim=0
options,flim,xtitle='Energy',ytitle='Particle '+units
xrange = [10,1e7]
xv = dgen(300,range=xrange,/log)
case strupcase(units) of
'EFLUX': begin
   norm = 1d
   yrange = [1e-4,1e5]
   end
'FLUX' : begin
   norm = 1./xv
   yrange = [1e-8,100]
   end
endcase
xlim,flim,xrange,/log  
ylim,flim,yrange,/log
if keyword_set(overplot) then restore_plot_state,overplot,/show else box,flim
overplot = get_plot_state()
xv =  dgen(300,range=flim.xrange,/log)

oplot,xv,norm* all_eflux(xv,0,0,param=par0)  , color = 6
oplot,xv,norm* all_eflux(xv,1,0,param=par0)  , color = 6, linestyle=2
oplot,xv,norm* all_eflux(xv,0,1,param=par0)  , color = 2
oplot,xv,norm* all_eflux(xv,1,1,param=par0)  , color = 2, linestyle=2

e     =  10^par0.pts.spec.xs
case strupcase(units) of
'EFLUX': norm = 1d
'FLUX' : norm = 1./e
endcase
eflux =  10^par0.pts.spec.ys
oplot,e,eflux*norm,/psym

end



pro mvn_sep_bin_cr_plot,param=par0,window=win,spectra=spectra,overplot=overplot,color=color, plot_residual=plot_residual,units=units
if keyword_set(win) then   wi,2,wsize = [1300,600],/show

if keyword_set(plot_residual) && keyword_set(par0) then begin
  !p.multi = [0,1,2]
endif

xrange =[-2,260]

if keyword_set(overplot) then restore_plot_state,overplot,/show $
else plot,[0,1],/NODATA,/ylog,xmargin=[10,10],yrange=[.0001,1e3],xrange=xrange,psym=10,/xstyle,/ystyle,title= 'All',xtitle='Bin Number',ytitle='Count Rate'
overplot = get_plot_state()


if not keyword_set(units) then units='rate' $
else bmap = mvn_sep_lut2map(mapnum = spectra.mapid,sensor=spectra.sensor)


case strlowcase(units) of
'counts' : znorm = 1.
'rate'   : znorm = spectra.duration
'nrate'  : znorm = spectra.duration * bmap.nrg_meas_delta / bmap.nrg_meas_avg
;'eflux'  : znorm = spectra.duration * bmap.nrg_meas_delta / bmap.nrg_meas_avg * geom
endcase

if keyword_set(spectra) then begin

  bins = replicate(1b,256)
  str_element,par0,'bins',bins
;  bins = par0.bins
  ind= where(bins )
  ds = spectra.data / znorm
  oplot,indgen(256),ds,psym=10
  oplot,ind,ds[ind],/psym
endif

if keyword_set(par0) then begin
  cr_e = mvn_sep_response_flux_to_bin_cr(0,[0,1],0,param=par0)
  cr_p = mvn_sep_response_flux_to_bin_cr(0,[0,1],1,param=par0)
  cr_t = cr_e + cr_p    ;mvn_sep_response_flux_to_bin_cr('',[0,1],param=par0)

  str_element,par0,'background',background
  if keyword_set(background) then begin
    cr_bg = background.data / background.duration
    oplot,indgen(256),cr_bg,psym=10,color=5
    cr_t = cr_t+cr_bg
  endif

  oplot,cr_t,color=4,psym=10
  oplot,cr_p,color=2,psym=10
  oplot,cr_e,color=6,psym=10
;  oplot,ind,cr_t[ind]       ,color=3,psym=1; ,mvn_sep_response_flux_to_bin_cr(ind,[0,1],param=par0)

  if keyword_set(residual) then begin
    plot,xrange,xrange*0,linestyle=1,xmargin=[10,10],yrange=[-2,2],xrange=xrange,psym=10,/xstyle,ystyle=2,title= 'All',xtitle='Bin Number',ytitle='Residual'
    residual = alog10( ds/cr_t )
    residual = (-2) > residual < 2
;dprint,minmax(cr_t)
;oplot,xrange,xrange*0.,linestyle=1
    oplot,residual, psym=10
    oplot,ind,residual[ind], psym=4
    !p.multi = 0
  endif
endif

end





function  mvn_sep_eflux_estimate,spectra,par0=par0,ptest=ptest,background=background

responses = mvn_sep_response_load(sepn=spectra.sensor,atten=spectra.att - 1,mapnum=spectra.mapid)
resp_e = responses[0]
resp_p = responses[1]
if ~keyword_set(par0) then par0 = all_eflux(electron_response=resp_e,proton_response=resp_p)

par0.pts.spec.linear=1
par0.pts.spec.slp_extra = -2.

if spectra.sensor eq 0 then return,fill_nan(par0)
if keyword_set(background) then begin
  str_element,/add,par0,'background',background
  spectra_sub = spectra
  bg_counts =  background.data/background.duration * spectra.duration
  spectra_sub.data = spectra.data - background.data/background.duration * spectra.duration
  ddata = sqrt(spectra_sub.data + bg_counts)
endif else begin
  spectra_sub = spectra
  ddata = sqrt(spectra.data)
endelse

bmap  = mvn_sep_get_bmap(spectra.mapid,spectra.sensor)
;mvn_sep_det_cal,bmap,spectra.sensor,units=1    
geom = 0.18

par0.pts[0].spec.ys = -3.8  ; reduce electron flux to negligible level
;par0.pts[1].spec.ys = -2  ; reduce proton flux to negligible level

;einc = (*resp_p).peakeinc
energy = bmap.nrg_meas_avg  + 10    ; approximately correct for both protons and electrons


if  keyword_set(ptest) then begin
  mvn_sep_spectra_plot,spectra,window=1,over=over1
  mvn_sep_spectra_plot,background,over=over1
  mvn_sep_spectra_plot,spectra_sub,over=over1
endif
  
energy_width = bmap.nrg_meas_delta
eflux = spectra_sub.data  / energy_width * energy / geom/ spectra_sub.duration   > 1e-2

p_eflux_extrap =  [1e-2,1e-2,5e-2,20e-2,1e-1,1e-1,5e-3,2e-3]
p_energy_extrap = [2e4  ,1e5 ,2e5,  5e5, 1e6, 2e6, 5e6, 8e6 ]

p_eflux_extrap = 10^[-2.59375, -2.24219, -1.89062, -1.90469, -2.29844, -2.63594]
p_energy_extrap= 10^[4.29858, 4.96682, 5.69194, 5.96209, 6.54502, 7.01422]

p_eflux_extrap = 10^[-2.41094, -2.17188, -1.37031, -1.31406, -1.70781, -1.67969, -0.779687, -0.765625, -2.46719]
p_energy_extrap= 10^[4.17062, 4.41232, 4.79621, 5.00948, 5.50711, 5.77725, 6.09005, 6.36019, 6.77251]

p_eflux_extrap = 10^[-2.41094, -2.17188, -1.37031, -1.31406, -1.70781, -1.67969, -2.     ,      -2.2, -2.5]
p_energy_extrap= 10^[4.17062,   4.41232,  4.79621,  5.00948,  5.50711,  5.77725,  6.09005,   6.36019,   6.77251]

p_eflux_extrap = 10^[-3., -4.]
p_energy_extrap= 10^[5., 6.]

proton= spectra_sub

p_eflux =  proton.data  / energy_width * energy / geom/ proton.duration

;w = where((bmap.name eq 'A-O') and (energy gt 22) and (energy lt 5000),nw)   ; A side - open
w = where((bmap.name eq 'A-O') and (bmap.adc[0] ge 8) and (bmap.adc[1] le 4086),nw)   ; A side - open
ef = p_eflux[w]
e  = energy[w]

w = where((bmap.name eq 'A-OT') and (energy gt 8000 and energy lt 10000.),nw)   ; A side - open

ef = [ef, p_eflux[w]]
e  = [e,energy[w]]

spec={energy:e,eflux:ef}
str_element,/add,par0,'R_ion',spec

xs =par0.pts[1].spec[1].xs 
par0.pts[1].spec[1].ys = interp( alog10(ef),alog10(e), xs) > (-3)    ; Proton - Aft look direction


w = where((bmap.name eq 'B-O') and (energy gt 22) and (energy lt 5000),nw)   ; B stack - open
ef = p_eflux[w]
e  = energy[w]

w = where((bmap.name eq 'B-OT') and (energy gt 8000 and energy lt 10000.),nw)   ; B stack - open
ef = [ef, p_eflux[w]]
e  = [e,energy[w]]

spec={energy:e,eflux:ef}
str_element,/add,par0,'F_ion',spec    ; Forward look directions ion



xs =par0.pts[1].spec[0].xs 
par0.pts[1].spec[0].ys = interp( alog10(ef),alog10(e), xs) > (-3)    ; Proton - Forward look direction


;
;
;w = where((bmap.name eq 'B-O') and (energy lt 5000),nw)   ; B side - open
;xs =par0.pts[1].spec[0].xs 
;log_eflux = interp( alog10([eflux[w],p_eflux_extrap]),alog10([energy[w],p_energy_extrap]), xs)     ; proton - Aft look direction
;;log_eflux[where(xs gt 3.8)] = -2.5
;par0.pts[1].spec[0].ys = log_eflux               ; proton - Forward look direction
;
;par0.pts[1].spec.ys = par0.pts[1].spec.ys > ( -2.8)       ; Set minimum Eflux for proton
;dim = size(/dimen,par0.pts.spec.ys)                   
;;par0.pts[1].spec.ys[dim[0]-1] = -3          ; Set minimum Eflux for proton
;;par0.pts[1].spec.vary[dim[0]-1] = 0 

proton = spectra_sub
proton.data = proton.duration * mvn_sep_response_flux_to_bin_cr(param=par0)   ; get estimate of proton contribution to full spectra data

if keyword_set(ptest) then begin
   undefine,over1,over2,over3,over4
;   mvn_sep_response_bin_matrix_plot,*par0.pts[1].response,window=4 ,face=-1,/trans
;   mvn_sep_bin_cr_plot,param=par0,spectra=spectra_sub,over=1
   mvn_sep_eflux_plot,param=par0,win=3,over=over3
   mvn_sep_response_bin_matrix_plot,*par0.pts[1].response,window=2 ,face=-1,/trans,over=over2,energy_range=[1e-4,1e6]
   mvn_sep_bin_cr_plot,param=par0,spectra=spectra,over=over2;,window=2
  mvn_sep_spectra_plot,spectra_sub,win=1 ,over=over1
  mvn_sep_spectra_plot,proton,over=over1,linestyle=2
endif

s_sigma =  ddata ;sqrt(spectra.data)  ; Assume Poisson statistics
p_sigma = sqrt(proton.data)
e_sigma = sqrt(ddata^2 + proton.data + 1)

electron = spectra_sub
electron.data = (spectra_sub.data - proton.data)  > 0.1
w = where(electron.data lt 3*e_sigma,nw)
if nw eq 0 then message,'Not expected'
e_eflux =  electron.data  / energy_width * energy / geom/ spectra_sub.duration
e_eflux[w] = 2e-3
e_eflux = e_eflux > 1e-3   ; non zero but negligible

e_energy_extrap = alog10([1000.,1e4,1e5])
e_eflux_extrap =  alog10([1e-3,2e-4,2e-5])

w = where((bmap.name eq 'A-F') and (energy gt 22) and (energy lt 400) ,nw)   ; A stack - Foil
ef = e_eflux[w]
e  = energy[w]
w = where((bmap.name eq 'A-FT') and (energy gt 400) and (energy lt 3000) ,nw)   ; A stack - Foil-Thick
ef = [ef, e_eflux[w]]
e  = [e,energy[w]]

spec={energy:e,eflux:ef}
str_element,/add,par0,'F_elec',spec



xs =par0.pts[0].spec[0].xs 
par0.pts[0].spec[0].ys = interp( alog10(ef),alog10(e), xs) > (-3)    ; Electron - Reverse look direction

w = where((bmap.name eq 'B-F') and (energy gt 22) and (energy lt 400) ,nw)   ; A side - Foil
ef = e_eflux[w]
e  = energy[w]
w = where((bmap.name eq 'B-FT') and (energy gt 400) and (energy lt 3000) ,nw)   ; A side - Foil-Thick
ef = [ef, e_eflux[w]]
e  = [e,energy[w]]

spec={energy:e,eflux:ef}
str_element,/add,par0,'R_elec',spec



xs =par0.pts[0].spec[1].xs 
par0.pts[0].spec[1].ys = interp( alog10(ef),alog10(e), xs) > (-3)    ; Electron - Reverse look direction


guess = spectra_sub
guess.data = guess.duration * mvn_sep_response_flux_to_bin_cr(param=par0)
if keyword_set(ptest) then begin
  undefine,over1,over2,over3
  mvn_sep_spectra_plot,spectra_sub,win=1 ,over=over1,tids=tids
;  mvn_sep_spectra_plot,proton,over=over1
  mvn_sep_spectra_plot,electron,over=over1, linestyle=3,tids=tids
  mvn_sep_spectra_plot,guess,over=over1 , linestyle=4,tids=tids
  mvn_sep_eflux_plot,param=par0,win=3,over=over3
  
  mvn_sep_bin_cr_plot,param=par0,window=2,spectra=spectra_sub
  dprint,'Test on'
endif

return,par0
end





function  mvn_sep_eflux_estimate2,spectra,par0=par0,ptest=ptest,background=background

responses = mvn_sep_response_load(sepn=spectra.sensor,atten=spectra.att - 1,mapnum=spectra.mapid)
resp_e = responses[0]
resp_p = responses[1]
if ~keyword_set(par0) then par0 = all_eflux(electron_response=resp_e,proton_response=resp_p)

par0.pts.spec.linear=1
par0.pts.spec.slp_extra = -2.

if spectra.sensor eq 0 then return,fill_nan(par0)

;case spectra.mapid of
;8: begin
;      ion_bins = 
;      elec_bins
;   end
;
;
;
;endcase

if keyword_set(background) then begin
  str_element,/add,par0,'background',background
  spectra_sub = spectra
  bg_counts =  background.data/background.duration * spectra.duration
  spectra_sub.data = spectra.data - background.data/background.duration * spectra.duration
  ddata = sqrt(spectra_sub.data + bg_counts)
endif else begin
  spectra_sub = spectra
  ddata = sqrt(spectra.data)
endelse

bmap  = mvn_sep_get_bmap(spectra.mapid,spectra.sensor)
;mvn_sep_det_cal,bmap,spectra.sensor,units=1    
geom = 0.18

;par0.pts[0].spec.ys = -3.8  ; reduce electron flux to negligible level

;einc = (*resp_p).peakeinc
energy = bmap.nrg_meas_avg  + 10    ; approximately correct for both protons and electrons

  
energy_width = bmap.nrg_meas_delta
eflux = spectra_sub.data  / energy_width * energy / geom/ spectra_sub.duration   > 1e-2

p_eflux_extrap =  [1e-2,1e-2,5e-2,20e-2,1e-1,1e-1,5e-3,2e-3]
p_energy_extrap = [2e4  ,1e5 ,2e5,  5e5, 1e6, 2e6, 5e6, 8e6 ]

p_eflux_extrap = 10^[-2.59375, -2.24219, -1.89062, -1.90469, -2.29844, -2.63594]
p_energy_extrap= 10^[4.29858, 4.96682, 5.69194, 5.96209, 6.54502, 7.01422]

p_eflux_extrap = 10^[-2.41094, -2.17188, -1.37031, -1.31406, -1.70781, -1.67969, -0.779687, -0.765625, -2.46719]
p_energy_extrap= 10^[4.17062, 4.41232, 4.79621, 5.00948, 5.50711, 5.77725, 6.09005, 6.36019, 6.77251]

p_eflux_extrap = 10^[-2.41094, -2.17188, -1.37031, -1.31406, -1.70781, -1.67969, -2.     ,      -2.2, -2.5]
p_energy_extrap= 10^[4.17062,   4.41232,  4.79621,  5.00948,  5.50711,  5.77725,  6.09005,   6.36019,   6.77251]

p_eflux_extrap = 10^[-3., -4.]
p_energy_extrap= 10^[5., 6.]

proton= spectra_sub

p_eflux =  proton.data  / energy_width * energy / geom/ proton.duration

w = where((bmap.name eq 'A-O') and (energy gt 22) and (energy lt 5000),nw)   ; A side - open
ef = p_eflux[w]
e  = energy[w]

w = where((bmap.name eq 'A-OT') and (energy gt 8000 and energy lt 10000.),nw)   ; A side - open
ef = [ef, p_eflux[w]]
e  = [e,energy[w]]

spec={energy:e,eflux:ef}
str_element,/add,par0,'R_ion',spec

xs =par0.pts[1].spec[1].xs 
par0.pts[1].spec[1].ys = interp( alog10(ef),alog10(e), xs) > (-3)    ; Proton - Aft look direction


w = where((bmap.name eq 'B-O') and (energy gt 22) and (energy lt 5000),nw)   ; B stack - open
ef = p_eflux[w]
e  = energy[w]

w = where((bmap.name eq 'B-OT') and (energy gt 8000 and energy lt 10000.),nw)   ; B stack - open
ef = [ef, p_eflux[w]]
e  = [e,energy[w]]

spec={energy:e,eflux:ef}
str_element,/add,par0,'F_ion',spec    ; Forward look directions ion



xs =par0.pts[1].spec[0].xs 
par0.pts[1].spec[0].ys = interp( alog10(ef),alog10(e), xs) > (-3)    ; Proton - Forward look direction


;
;
;w = where((bmap.name eq 'B-O') and (energy lt 5000),nw)   ; B side - open
;xs =par0.pts[1].spec[0].xs 
;log_eflux = interp( alog10([eflux[w],p_eflux_extrap]),alog10([energy[w],p_energy_extrap]), xs)     ; proton - Aft look direction
;;log_eflux[where(xs gt 3.8)] = -2.5
;par0.pts[1].spec[0].ys = log_eflux               ; proton - Forward look direction
;
;par0.pts[1].spec.ys = par0.pts[1].spec.ys > ( -2.8)       ; Set minimum Eflux for proton
;dim = size(/dimen,par0.pts.spec.ys)                   
;;par0.pts[1].spec.ys[dim[0]-1] = -3          ; Set minimum Eflux for proton
;;par0.pts[1].spec.vary[dim[0]-1] = 0 

proton = spectra_sub
proton.data = proton.duration * mvn_sep_response_flux_to_bin_cr(param=par0)   ; get estimate of proton contribution to full spectra data

if keyword_set(ptest) then begin
   undefine,over1,over2,over3,over4
;   mvn_sep_response_bin_matrix_plot,*par0.pts[1].response,window=4 ,face=-1,/trans
;   mvn_sep_bin_cr_plot,param=par0,spectra=spectra_sub,over=1
   mvn_sep_eflux_plot,param=par0,win=3,over=over3
   mvn_sep_response_bin_matrix_plot,*par0.pts[1].response,window=2 ,face=-1,/trans,over=over2,energy_range=[1e-4,1e6]
   mvn_sep_bin_cr_plot,param=par0,spectra=spectra,over=over2;,window=2
  mvn_sep_spectra_plot,spectra_sub,win=1 ,over=over1
  mvn_sep_spectra_plot,proton,over=over1,linestyle=2
endif

s_sigma =  ddata ;sqrt(spectra.data)  ; Assume Poisson statistics
p_sigma = sqrt(proton.data)
e_sigma = sqrt(ddata^2 + proton.data + 1)

electron = spectra_sub
electron.data = (spectra_sub.data - proton.data)  > 0.1
w = where(electron.data lt 3*e_sigma,nw)
if nw eq 0 then message,'Not expected'
e_eflux =  electron.data  / energy_width * energy / geom/ spectra_sub.duration
e_eflux[w] = 2e-3
e_eflux = e_eflux > 1e-3   ; non zero but negligible

e_energy_extrap = alog10([1000.,1e4,1e5])
e_eflux_extrap =  alog10([1e-3,2e-4,2e-5])

w = where((bmap.name eq 'A-F') and (energy gt 22) and (energy lt 400) ,nw)   ; A stack - Foil
ef = e_eflux[w]
e  = energy[w]
w = where((bmap.name eq 'A-FT') and (energy gt 400) and (energy lt 3000) ,nw)   ; A stack - Foil-Thick
ef = [ef, e_eflux[w]]
e  = [e,energy[w]]

spec={energy:e,eflux:ef}
str_element,/add,par0,'F_elec',spec



xs =par0.pts[0].spec[0].xs 
par0.pts[0].spec[0].ys = interp( alog10(ef),alog10(e), xs) > (-3)    ; Electron - Reverse look direction

w = where((bmap.name eq 'B-F') and (energy gt 22) and (energy lt 400) ,nw)   ; A side - Foil
ef = e_eflux[w]
e  = energy[w]
w = where((bmap.name eq 'B-FT') and (energy gt 400) and (energy lt 3000) ,nw)   ; A side - Foil-Thick
ef = [ef, e_eflux[w]]
e  = [e,energy[w]]

spec={energy:e,eflux:ef}
str_element,/add,par0,'R_elec',spec



xs =par0.pts[0].spec[1].xs 
par0.pts[0].spec[1].ys = interp( alog10(ef),alog10(e), xs) > (-3)    ; Electron - Reverse look direction


guess = spectra_sub
guess.data = guess.duration * mvn_sep_response_flux_to_bin_cr(param=par0)
if keyword_set(ptest) then begin
  undefine,over1,over2,over3
  mvn_sep_spectra_plot,spectra_sub,win=1 ,over=over1,tids=tids
;  mvn_sep_spectra_plot,proton,over=over1
  mvn_sep_spectra_plot,electron,over=over1, linestyle=3,tids=tids
  mvn_sep_spectra_plot,guess,over=over1 , linestyle=4,tids=tids
  mvn_sep_eflux_plot,param=par0,win=3,over=over3
  
  mvn_sep_bin_cr_plot,param=par0,window=2,spectra=spectra_sub
  dprint,'Test on'
endif

return,par0
end





function mvn_sep_spectra_time_average,sepdat,timeres= timeres,trange=trange
num = keyword_set(sepdat) * n_elements(sepdat)
dprint,num
;printdat,sepdat,num

if n_elements(timeres) eq 0 then  timeres = 600L   ; ten minutes
if timeres le 0 then begin
  if keyword_set(trange) then begin
     ind = where(sepdat.time lt trange[1]  and sepdat.time ge trange[0] )
     ii = minmax(ind)
     sepdat.valid=1
     return, sepdat[ii[0]:ii[1]]
  endif
  return,sepdat
endif

w = where(finite(sepdat.time) )   ; must fix to remove invalid samples
timebin = floor(sepdat[w].time / timeres)

;printdat,time_string(minmax(sepdat.time))
;printdat,minmax(timebin)
h = histogram(timebin,rev=rev)
;printdat,h,rev
sepavg = replicate(fill_nan(sepdat[0]),n_elements(h))
for i=0,n_elements(h)-1 do begin
   num = h[i]
   if num eq 0 then begin
 ;     dprint,'gap'
      continue
   endif
   tbins = Rev[Rev[i] : Rev[i+1]-1]
   data = sepdat[tbins]
   dat = data[0]
   dat.valid = n_elements(tbins)
   if n_elements(data) gt 1 then begin
        dat.trange = minmax(data.trange)
        dat.time = average(data.time)
        dat.data  = total(data.data,2)
        dat.rate  = average(data.rate)
        dat.counts_total = total(data.counts_total)
        dat.duration = total(data.duration)
   endif
   sepavg[i] = dat
endfor
return , sepavg
end



function mvn_sep_inst_deconvolve,sepdat,timeres=timeres,trange=trange

test=1
if keyword_set(test)  then trange = ['2014-4-20','2014-4-21']  ; ['2014-3-26','2014-3-27'];trange = ['2014-4-20','2014-4-21']  ;
;if keyword_set(test)  then trange = trange = ['2014-3-18','2014-4-21']  ;
if ~keyword_set(sepdat) || keyword_set(test) then $
  mvn_sep_extract_data,'mvn_sep2_svy',sepdat,trange=trange ,num=num 
 ; timeres=600.d

sepspec = mvn_sep_spectra_time_average(sepdat,timeres= timeres,trange=trange) ;,sep_novary=sep_novary)

ns = n_elements(sepspec)

;return,sepspec

for i=0,ns-1 do begin
   if sepspec[i].valid eq 0 || ~finite(sepspec[i].time) then continue
   par=  mvn_sep_eflux_estimate(sepspec[i],background=background) 
   if ~keyword_set(pars) then pars = replicate(fill_nan(par),ns) 
   pars[i] = par
   dprint,i,dlevel=2
endfor

if 0 then begin
elec_energy = 10.^pars.pts[0].spec.xs
ion_energy = 10.^pars.pts[1].spec.xs
elec_eflux  = 10.^pars.pts[0].spec.ys
ion_eflux  = 10.^pars.pts[1].spec.ys
str_element,/add,sepspec,'elec_eflux',float(elec_eflux)
str_element,/add,sepspec,'ion_eflux',float(ion_eflux)
str_element,/add,sepspec,'elec_energy',float(elec_energy)
str_element,/add,sepspec,'ion_energy',float(ion_energy)

elec_eflux_unc = elec_eflux * .1   ; cluge to make uncertainty
ion_eflux_unc = ion_eflux * .1   ;  cluge to make uncertainty
str_element,/add,sepspec,'elec_eflux_unc',float(elec_eflux_unc)
str_element,/add,sepspec,'ion_eflux_unc',float(ion_eflux_unc)
endif else begin

str_element,/add,sepspec,'R_elec',pars.r_elec
str_element,/add,sepspec,'R_ion',pars.r_ion

str_element,/add,sepspec,'F_elec',pars.f_elec
str_element,/add,sepspec,'F_ion',pars.f_ion
endelse

return,sepspec
end




; Begin program here
if keyword_set(test) then begin
   test=0
endif

if ~keyword_set(init) then begin
;   timespan,'14 3 18',65
 ;  timespan,current=35
   timespan,['17 7 25',time_string(systime(1),prec=-3)]
   mvn_sep_var_restore
   tplot,'*SEPS*ATT mvn_sep2*Rate*'
restore,/verbose,'sep2_background.sav'
   init=1
endif

if ~keyword_set(sepn) then sepn=2

if 0 then $
  ctime,routine_name='mvn_sep_spectra_plot'
  
if ~keyword_set(spectra) then $
  mvn_sep_spectra_plot,spectra,win=1,sep=sepn,units=units
  
;mvn_sep_spectra_plot,spectra,win=1,units=units
;ds = spectra.data / spectra.duration

;mvn_sep_det_cal,bmap,sepn,units=1    


if keyword_set(ptest) then par0=0
if not keyword_set(par0) then par0 = mvn_sep_eflux_estimate(spectra,ptest=ptest,background = sep2_bg)

undefine,over1,over2,over3,over4
if not keyword_set(units) then units='eflux'
mvn_sep_spectra_plot,spectra,win=1,units=units,over=over1
mvn_sep_spectra_plot,spectra,win=4,units='eflux',over=over4
mvn_sep_eflux_plot,param=par0,overplot=over4
mvn_sep_eflux_plot,param=par0,win=3,overplot=over3
mvn_sep_bin_cr_plot,param=par0,window=2,spectra=spectra,overplot=over2

if 1 then begin


bmap  = mvn_sep_get_bmap(spectra.mapid,spectra.sensor)
;bmap = (*(par0.pts.response)).bmap

par0.bins = bmap.nrg_meas_avg gt 12.  ; Only fit to data above threshold
par0.bins[[30,78,158,206 ] ] = 0   ; get rid of extremely narrow bins
par0.bins[ where(bmap.det eq 4 and bmap.nrg_meas_avg lt 80) ] = 0   ; get rid of low energy OT
par0.bins[ where(bmap.det eq 5 and bmap.nrg_meas_avg lt 80) ] = 0   ; get rid of low energy FT
par0.bins[ where(bmap.det eq 6 and bmap.nrg_meas_avg lt 300) ] = 0   ; get rid of low energy FTO
;par0.bins[ where(bmap.det eq 6 and bmap.nrg_meas_avg gt 8000) ] =0   ; get rid of high energy FTO
;par0.bins = bmap.x gt 10.
;par0.bins = par0.bins and (bmap.det ge 4)   ; only coincident channels
par0.bins = par0.bins and (bmap.det ne 2)   ; all but thick
;par0.bins = par0.bins and (bmap.det eq 3)   ; foil only


;par0.pts.spec.vary=1
;par0.pts[0].spec.vary=0  ; don't vary the electrons
print,par0.pts.spec.vary


if 0 then begin
part=par0
dprint, 'Start fit'
if not keyword_set(names) then names = 'pts.spec.ys[0,1,2,3,4,5,6,7,8,9]'
fit,bins,ds[bins],param=par0,names=names
;oplot,bins, mvn_sep_response_flux_to_bin_cr(bins,[0,1],param=par0),color=3,psym=1
dprint,   'End fit'
mvn_sep_eflux_plot,param=par0,win=3
mvn_sep_bin_cr_plot,param=par0,window=2,spectra=spectra

endif else begin

mvn_sep_eflux_plot,param=par0,win=3
mvn_sep_bin_cr_plot,param=par0,window=2,spectra=spectra

part = mvn_sep_amoeba_min( param = par0, spectra=spectra, /ret_par ) 
undefine,p0
chi2 = mvn_sep_amoeba_min( p0 )
printdat,chi2,p0

;Amoeba, ftol, FUNCTION_NAME=func, FUNCTION_VALUE=y, $
;  NCALLS = ncalls, NMAX = nmax, P0 = p0, SCALE=scale, SIMPLEX=p
scale = replicate( .1, n_elements(p0) )
if ~keyword_set(tol) then tol = 1e-5
undefine,over3,over2
if n_elements(its) eq 0 then its=0
for i=0,its-1 do begin
  vec = mvn_sep_amoeba( tol, function_name = 'mvn_sep_amoeba_min',nmax=nmax,ncalls=nc,scale=scale,p0=p0 ,simplex=simplex)
  par0 = mvn_sep_amoeba_min(/ret_par )
  chi2 = mvn_sep_amoeba_min()
 ; printdat,nc,vec,chi2
  dprint,i,nc,chi2,vec[0];,/phelp
  mvn_sep_eflux_plot,param=par0,win=3,over=over3
  mvn_sep_bin_cr_plot,param=par0,window=2,spectra=spectra ,over=over2
  scale = 0
endfor

endelse

   mvn_sep_response_bin_matrix_plot,*par0.pts[1].response,window=4 ,face=-1,/trans,over=over4,energy_range=[1e-4,1e6]
   mvn_sep_bin_cr_plot,param=par0,spectra=spectra,over=over4;,window=2

   mvn_sep_response_bin_matrix_plot,*par0.pts[1].response,window=5 ,face=+1,/trans,over=over4,energy_range=[1e-4,1e6]
   mvn_sep_bin_cr_plot,param=par0,spectra=spectra,over=over4;,window=2

   mvn_sep_response_bin_matrix_plot,*par0.pts[0].response,window=6 ,face=-1,/trans,energy_range=[1e-4,1e6]
   mvn_sep_bin_cr_plot,param=par0,spectra=spectra,/over

   mvn_sep_response_bin_matrix_plot,*par0.pts[0].response,window=7 ,face=+1,/trans,energy_range=[1e-4,1e6]
   mvn_sep_bin_cr_plot,param=par0,spectra=spectra,/over

   mvn_sep_response_bin_matrix_plot,*par0.pts[0].response,window=8 ,face=+0,/trans,energy_range=[1e-4,1e6]
   mvn_sep_bin_cr_plot,param=par0,spectra=spectra,/over
   response = *par0.pts[0].response
   peakeinc =mvn_sep_inst_response_peakeinc(response,width=30,thresh=.01)
   oplot,peakeinc[0,*].e0,psym=-1
   oplot,peakeinc[1,*].e0,psym=-4
   ;oplot,peakeinc[0,*].g,psym=-1
   ;oplot,peakeinc[1,*].g,psym=-4
   wi,10
   w = where(bmap.name eq 'A-F')
   plot,peakeinc[0,w].e0 , peakeinc[0,w].g,/xlog,psym=-1
   oplot,peakeinc[1,w].e0 , peakeinc[1,w].g,psym=-1

   mvn_sep_response_bin_matrix_plot,*par0.pts[1].response,window=9 ,face=+0,/trans,energy_range=[1e-4,1e6]
   mvn_sep_bin_cr_plot,param=par0,spectra=spectra,/over
   response = *par0.pts[1].response
   peakeinc =mvn_sep_inst_response_peakeinc(response,width=30,thresh=.01)
   oplot,peakeinc[0,*].e0,psym=-1
   oplot,peakeinc[1,*].e0,psym=-4
   ;oplot,peakeinc[0,*].g,psym=-1
   ;oplot,peakeinc[1,*].g,psym=-4


if 0 then begin
win=10
mvn_sep_response_bin_matrix_plot,*par0.pts[1].response,window=win++ ,face=-1,/trans
mvn_sep_response_bin_matrix_plot,*par0.pts[1].response,window=win++ ,face=+1,/trans
mvn_sep_response_bin_matrix_plot,*par0.pts[0].response,window=win++ ,face=-1,/trans
mvn_sep_response_bin_matrix_plot,*par0.pts[0].response,window=win++ ,face=+1,/trans
endif


;ftos=ftos
;tids=tids
if 0 then begin
sfit = spectra
sfit.data = mvn_sep_response_flux_to_bin_cr(indgen(256),[0,1],0,param=par0) * sfit.duration   ; electron only
mvn_sep_spectra_plot,spectra,win=4,ftos=ftos,tids=0,units=units
mvn_sep_spectra_plot,sfit,/over,linestyle=2,ftos=ftos,tids=0,units=units
mvn_sep_spectra_plot,spectra,win=5,ftos=ftos,tids=1,units=units
mvn_sep_spectra_plot,sfit,/over,linestyle=2,ftos=ftos,tids=1,units=units
endif

endif


if 0 then begin
names = 'pts.proton.spec.ys[0,1,2]'
names = 'pts.electron.spec.ys[0,1,2]'
i = where( strmatch(bmap.name,'?-F')  and bmap.x gt  10)
i = where( strmatch(bmap.name,'?-O')  and bmap.x gt  10)
i = where( strmatch(bmap.name,'?-[OF]')  and bmap.x gt  10)
fit,i,ds[i],param=par0,names=names,/logfit
endif

if 0 then begin
for side=0,1 do begin
  for fto=1,7 do begin
     w = where(bmap.fto eq fto and bmap.tid eq side,nw)
     if nw ne 0 then begin
       print,bmap[w[0]].name,total(cr_e[w],/pres),total(cr_p[w],/pres),total(/pres,cr_t[w]),format='(a-8,f8.2,f8.2,f8.2)'
     endif
  endfor
endfor
endif

end
