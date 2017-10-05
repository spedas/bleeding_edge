;20160623 Ali
;variation of Davin's mvn_save_reduce_timeres
;for reducing SEP L1 time resolution.
;main keyword: RESSTR: resolution string (e.g. 64sec, 5min, 1hr). default is 5min.

function mvn_sep_att_correction,data,res,tr,fltatt=fltatt ;throws out att actuation times that result in bad/mixed counts
  datt=shift(data.att,-1) ne shift(data.att,1) ;att flips
  w=where(datt,nw,/null)
  if keyword_set(fltatt) then begin ;use float for averaging
    dataflt=data
    str_element,dataflt,'att',0.,/add ;turning att from byte to float for averaging mixed state att's
    str_element,dataflt,'duration',0.,/add ;turning duration from uint to float for averaging mixed durations
    dataflt.att=data.att
    dataflt.duration=data.duration
    data=dataflt
    data[where(data.att eq 0.,/null)].att=!values.f_nan ;turning att state 0b to fNaN
    if nw ne 0 then data[w]=fill_nan(data[0])
  endif else begin ;gets rid of .5res on each side of an att flip to preserve single att state at each time bin
    if nw ne 0 then begin
      fnan=fill_nan(data[0])
      for iw=0,nw-1 do begin
        ww=where(data.time gt data[w[iw]].time-res/2. and data.time lt data[w[iw]].time+res/2.,nww,/null)
        if nww ne 0 then data[ww] = fnan
      endfor
    endif
  endelse
  dataatt=average_hist(data.att,data.time,binsize=res,range=tr,/nan,weight=data.duration)
  datarate=average_hist(data.rate,data.time,binsize=res,range=tr,/nan,weight=data.duration)
  data=average_hist(data,data.time,binsize=res,range=tr,/nan,xbins=centertime)
  data.att=dataatt
  data.rate=datarate
  data.time=centertime
  ntimes=n_elements(centertime)
  data.trange=transpose(rebin(centertime,[ntimes,2]))+rebin(res/2.*[-1.,1.],[2,ntimes])

return,data
end


pro mvn_sep_save_reduce_timeres,pathformat=pathformat,trange=trange0,init=init,timestamp=timestamp,verbose=verbose,$
  resstr=resstr,resolution=res,description=description

if keyword_set(init) then begin
  trange0=[time_double('2014-9-22'),systime(1)]
  if init lt 0 then trange0=[time_double('2013-12-5'),systime(1)]
endif else trange0=timerange(trange0)

if ~keyword_set(resstr) then resstr='5min'
if ~keyword_set(res) then begin
   res=double(resstr)
   if strpos(resstr,'min') ge 0 then res *= 60
   if strpos(resstr,'hr') ge 0 then res *= 3600
   dprint,dlevel=3,'Time resolution not provided, Using: ',res,' seconds'
endif

fullres_fmt='maven/data/sci/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_1day.sav'
redures_fmt='maven/data/sci/sep/l1/sav_'+resstr+'/YYYY/MM/mvn_sep_l1_YYYYMMDD_'+resstr+'.sav'

day = 86400L
trange = day* double(round( (timerange((trange0+ [ 0,day-1]) /day)) ))         ; round to days
nd = round( (trange[1]-trange[0]) /day) 

for i=0L,nd-1 do begin
  tr = trange[0] + [i,i+1] * day
  tn = tr[0]
  prereq_files=''

  fullres_file=mvn_pfp_file_retrieve(fullres_fmt,trange=tn,/daily_names)
  redures_file=mvn_pfp_file_retrieve(redures_fmt,trange=tn,/daily_names,/create_dir)
  
  dprint,dlevel=3,fullres_file
  
  if file_test(fullres_file,/regular) eq 0 then begin
    dprint,verbose=verbose,dlevel=2,fullres_file+' Not found. Skipping
    continue
  endif

  append_array,prereq_files,fullres_file

  prereq_info = file_info(prereq_files)
  prereq_timestamp = max([prereq_info.mtime, prereq_info.ctime])
  
  target_info = file_info(redures_file)
  target_timestamp =  target_info.mtime 
  
  if keyword_set(timestamp) then target_timestamp = time_double(timestamp) < target_timestamp

  if prereq_timestamp lt target_timestamp then continue    ; skip if lowres L1 does not need to be regenerated
  dprint,dlevel=1,'Generating new file: '+redures_file
  
  f = fullres_file
  if file_test(/regular,f) eq 0 then continue
  source_filename=f
  restore,f
  
  s1_arc=0
  s2_arc=0

  if keyword_set(s1_svy) then s1_svy=mvn_sep_att_correction(s1_svy,res,tr,/fltatt)
  if keyword_set(s2_svy) then s2_svy=mvn_sep_att_correction(s2_svy,res,tr,/fltatt)

  if keyword_set(s1_hkp) then s1_hkp=average_hist(s1_hkp,s1_hkp.time,binsize=res,range=tr,/nan)
  if keyword_set(s2_hkp) then s2_hkp=average_hist(s2_hkp,s2_hkp.time,binsize=res,range=tr,/nan)

  if keyword_set(s1_nse) then s1_nse=average_hist(s1_nse,s1_nse.time,binsize=res,range=tr,/nan)
  if keyword_set(s2_nse) then s2_nse=average_hist(s2_nse,s2_nse.time,binsize=res,range=tr,/nan)

  if keyword_set(m1_hkp) then m1_hkp=average_hist(m1_hkp,m1_hkp.time,binsize=res,range=tr,/nan)
  if keyword_set(m2_hkp) then m2_hkp=average_hist(m2_hkp,m2_hkp.time,binsize=res,range=tr,/nan)

  if keyword_set(ap20) then ap20=average_hist(ap20,ap20.time,binsize=res,range=tr,/nan)
  if keyword_set(ap21) then ap21=average_hist(ap21,ap21.time,binsize=res,range=tr,/nan)
  if keyword_set(ap22) then ap22=average_hist(ap22,ap22.time,binsize=res,range=tr,/nan)
  if keyword_set(ap23) then ap23=average_hist(ap23,ap23.time,binsize=res,range=tr,/nan)
;  if keyword_set(ap24) then ap24=average_hist(ap24,ap24.time,binsize=res,range=tr,stdev=sigma,xbins=centertime) ;lower cadence than 5min
;  if keyword_set(ap25) then ap25=average_hist(ap25,ap25.time,binsize=res,range=tr,/nan) ;apid not available
  
  save,filename=redures_file,verbose=verbose,s1_hkp,s1_svy,s1_arc,s1_nse,s2_hkp,s2_svy,s2_arc,s2_nse,m1_hkp,m2_hkp,$
    ap20,ap21,ap22,ap23,ap24,source_filename,sw_version,prereq_info,spice_info,description=description

endfor
  
end
