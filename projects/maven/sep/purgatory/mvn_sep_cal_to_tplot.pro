pro mvn_sep_cal_to_tplot,newdat,sepnum=sepnum,qfilter=qfilter,smoothcounts=smoothcounts,lowres=lowres,arc=arc

@mvn_sep_handler_commonblock.pro

if ~keyword_set(newdat) and keyword_set(sep1_svy) then begin
  rawdat = sepnum eq 1 ? *sep1_svy.x : *sep2_svy.x
  if keyword_set(arc) and keyword_set(sep1_arc) then rawdat = sepnum eq 1 ? *sep1_arc.x : *sep2_arc.x
  if keyword_set(smoothcounts) then begin
    raw_data=transpose(rawdat.data)
    raw_data=smooth_counts(raw_data)
    rawdat.data=transpose(raw_data)    
  endif
  bkgfile= (mvn_pfp_file_retrieve('maven/data/sci/sep/l1/sav/sep2_bkg.sav'))[0]
  if file_test(bkgfile[0]) then   restore,file=bkgfile,/verb
  ; mvn_sep_spectra_plot,bkg2
  newdat = mvn_sep_get_cal_units(rawdat,background = bkg2,lowres=lowres)
endif

if ~keyword_set(newdat) then return

if keyword_set(qfilter) then  begin
  w = where((newdat.quality_flag and qfilter) ne 0,nw)
  fnan = fill_nan(newdat)
  if nw ne 0 then begin
    newdat[w] = fill_nan(newdat[0])
  endif
endif


prefix='mvn_SEP'+strtrim(sepnum,2)
if keyword_set(smoothcounts) then prefix='<mvn>_SEP'+strtrim(sepnum,2)
if keyword_set(lowres) then begin
  prefix='mvn_5min_SEP'+strtrim(sepnum,2)
  if lowres eq 2 then prefix='mvn_01hr_SEP'+strtrim(sepnum,2)
endif
if keyword_set(arc) then prefix='mvn_arc_SEP'+strtrim(sepnum,2)
if keyword_set(smoothcounts) and keyword_set(lowres) then begin
  prefix='<mvn>_5min_SEP'+strtrim(sepnum,2)
  if lowres eq 2 then prefix='<mvn>_01hr_SEP'+strtrim(sepnum,2)
endif
if keyword_set(smoothcounts) and keyword_set(arc) then prefix='<mvn>_arc_SEP'+strtrim(sepnum,2)

  ;
  data = newdat.f_ion_flux
  ;ddata = newdat.f_ion_flux_unc
  ;

  dim = size(/dimen,data)
  r = intarr( dim[0] )
  r[0:2] = 0
  r[3:9] = 0
  r[10:19] = 1
  r[20:*]  = 2
  ;printdat,r
  ;printdat,minmax(r)
  d1 = max(r) +1
  rr = fltarr( d1, dim[0] )
  h = histogram(r,reverse=rev)
  for i=0,d1-1 do if h[i] ne 0 then  rr[i,  Rev[Rev[i] : Rev[i+1]-1] ] =1

  rr = fltarr( d1, dim[0] )
  rr[0,5:12]=1
  rr[1,13:20]=1
  rr[2,21:27]=1

  panel_size = 1.

  data = newdat.f_ion_eflux
  ddata = newdat.f_ion_eflux_unc
  bad = data lt .0* ddata
  w = where(bad, count)
  ; if (count gt 0L) then data[w] = !values.f_nan
  store_data,prefix+'F_ion_eflux',newdat.time,transpose(data),transpose(newdat.f_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1.,1e5],zlog:1,panel_size:panel_size}
  store_data,prefix+'F_ion_eflux_unc',newdat.time,transpose(ddata),transpose(newdat.f_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1.,1e5],zlog:1,panel_size:panel_size}

  data = newdat.r_ion_eflux
  ddata = newdat.r_ion_eflux_unc
  bad = data lt .0* ddata
  w = where(bad, count)
  ; if (count gt 0L) then data[w] = !values.f_nan
  store_data,prefix+'R_ion_eflux',newdat.time,transpose(data),transpose(newdat.R_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1.,1e5],zlog:1,panel_size:panel_size}
  store_data,prefix+'R_ion_eflux_unc',newdat.time,transpose(ddata),transpose(newdat.R_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1.,1e5],zlog:1,panel_size:panel_size}

  data = newdat.f_elec_eflux
  ddata = newdat.f_elec_eflux_unc
  bad = data lt .0* ddata
  w = where(bad, count)
  ; if (count gt 0L) then data[w] = !values.f_nan
  store_data,prefix+'F_elec_eflux',newdat.time,transpose(data),transpose(newdat.f_elec_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1.,1e5],zlog:1,panel_size:panel_size}

  data = newdat.r_elec_eflux
  ddata = newdat.r_elec_eflux_unc
  bad = data lt .0* ddata
  w = where(bad, count)
  ; if (count gt 0L) then data[w] = !values.f_nan
  store_data,prefix+'R_elec_eflux',newdat.time,transpose(data),transpose(newdat.R_elec_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1.,1e5],zlog:1,panel_size:panel_size}

  data = newdat.f_ion_flux
  ddata = newdat.f_ion_flux_unc
  bad = data lt .0* ddata
  w = where(bad, count)
  ; if (count gt 0L) then data[w] = !values.f_nan
  store_data,prefix+'F_ion_flux',newdat.time,transpose(data),transpose(newdat.f_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:panel_size}
  store_data,prefix+'F_ion_flux_unc',newdat.time,transpose(ddata),transpose(newdat.f_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:panel_size}

  data= rr # data
  ddata= sqrt(rr # (ddata ^2))
  eval0 = newdat[0].f_ion_energy
  eval = (rr # eval0) / total(rr,2)
  store_data,prefix+'F_ion_flux_red',newdat.time,transpose(data),eval,dlim={spec:0,yrange:[.01,1e5],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:panel_size}

  data = newdat.r_ion_flux
  ddata = newdat.r_ion_flux_unc
  bad = data lt .0* ddata
  w = where(bad, count)
  ; if (count gt 0L) then data[w] = !values.f_nan
  store_data,prefix+'R_ion_flux',newdat.time,transpose(data),transpose(newdat.f_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:panel_size}
  store_data,prefix+'R_ion_flux_unc',newdat.time,transpose(ddata),transpose(newdat.f_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:panel_size}

  data= rr # data
  ddata= sqrt(rr # (ddata ^2))
  eval0 = newdat[0].R_ion_energy
  eval = (rr # eval0) / total(rr,2)
  store_data,prefix+'R_ion_flux_red',newdat.time,transpose(data),eval,dlim={spec:0,yrange:[.01,1e5],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:panel_size}

  data = newdat.f_elec_flux
  ddata = newdat.f_elec_flux_unc
  bad = data lt .0* ddata
  w = where(bad, count)
  ; if (count gt 0L) then data[w] = !values.f_nan
  store_data,prefix+'F_elec_flux',newdat.time,transpose(data),transpose(newdat.f_elec_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:panel_size}

if 0 then begin
  data= rr # data
  ddata= sqrt(rr # (ddata ^2))
  eval0 = newdat[0].f_elec_energy
  eval = (rr # eval0) / total(rr,2)
  store_data,prefix+'F_elec_flux_red',newdat.time,transpose(data),eval,dlim={spec:0,yrange:[.01,1e5],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:panel_size}
endif

  data = newdat.r_elec_flux
  ddata = newdat.r_elec_flux_unc
  bad = data lt .0* ddata
  w = where(bad, count)
  ; if (count gt 0L) then data[w] = !values.f_nan
  store_data,prefix+'R_elec_flux',newdat.time,transpose(data),transpose(newdat.f_elec_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:panel_size}

if 0 then begin
  data= rr # data
  ddata= sqrt(rr # (ddata ^2))
  eval0 = newdat[0].R_ion_energy
  eval = (rr # eval0) / total(rr,2)
  store_data,prefix+'R_elec_flux_red',newdat.time,transpose(data),eval,dlim={spec:0,yrange:[.01,1e5],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:panel_size}
endif



  store_data,prefix+'F_ion_eflux_tot',data={x:newdat.time,y:newdat.f_ion_eflux_tot},dlim={ylog:1,yrange:[1e3,1e8]}
  store_data,prefix+'R_ion_eflux_tot',data={x:newdat.time,y:newdat.r_ion_eflux_tot},dlim={ylog:1,yrange:[1e3,1e8]}

  store_data,prefix+'F_ion_flux_tot',data={x:newdat.time,y:newdat.f_ion_flux_tot},dlim={ylog:1,yrange:[1.,1e6]}
  store_data,prefix+'R_ion_flux_tot',data={x:newdat.time,y:newdat.r_ion_flux_tot},dlim={ylog:1,yrange:[1.,1e6]}
  

  store_data,prefix+'F_elec_eflux_tot',data={x:newdat.time,y:newdat.f_elec_eflux_tot},dlim={ylog:1,yrange:[1e3,1e8]}
  store_data,prefix+'R_elec_eflux_tot',data={x:newdat.time,y:newdat.r_elec_eflux_tot},dlim={ylog:1,yrange:[1e3,1e8]}

  store_data,prefix+'F_elec_flux_tot',data={x:newdat.time,y:newdat.f_elec_flux_tot},dlim={ylog:1,yrange:[1.,1e6]}
  store_data,prefix+'R_elec_flux_tot',data={x:newdat.time,y:newdat.r_elec_flux_tot},dlim={ylog:1,yrange:[1.,1e6]}

  store_data,prefix+'_QUAL_FLAG',data={x:newdat.time,y:newdat.quality_flag},dlim={tplot_routine:'bitplot',yrange:[-1,8]}


  ;print,(eval0* reform(rr[0,*]))
  ;print,(eval0* reform(rr[1,*]))
  ;print,(eval0* reform(rr[2,*]))
  print,eval0[where(rr[0,*])]
  print,eval0[where(rr[1,*])]
  print,eval0[where(rr[2,*])]
end
