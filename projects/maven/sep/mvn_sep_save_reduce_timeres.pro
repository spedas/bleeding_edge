; $LastChangedBy: ali $
; $LastChangedDate: 2021-05-30 19:45:35 -0700 (Sun, 30 May 2021) $
; $LastChangedRevision: 30010 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_save_reduce_timeres.pro $

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

function mvn_sep_att_arc,data ;keeps burst (archive) att states in the lowres files
  arc=replicate({time:data[0].time,att:data[0].att,duration:data[0].duration},n_elements(data))
  arc.time=data.time
  arc.att=data.att
  arc.duration=data.duration
  return,arc
end


pro mvn_sep_save_reduce_timeres,pathformat=pathformat,trange=trange0,init=init,timestamp=timestamp,verbose=verbose,$
  resstr=resstr,resolution=res,description=description,hourly=hourly

  if keyword_set(init) then trange0=[time_double('2013-12-03'),systime(1)] else trange0=timerange(trange0)
  if keyword_set(hourly) then resstr='01hr'
  if ~keyword_set(resstr) then resstr='5min'
  if ~keyword_set(res) then begin
    res=double(resstr)
    if strpos(resstr,'min') ge 0 then res *= 60
    if strpos(resstr,'hr') ge 0 then res *= 3600
    dprint,dlevel=3,'Time resolution not provided, Using: ',res,' seconds'
  endif

  fullres_fmt='maven/data/sci/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_1day.sav'
  if resstr eq '01hr' then fullres_fmt='maven/data/sci/sep/l1/sav_5min/YYYY/MM/mvn_sep_l1_YYYYMMDD_5min.sav'
  redures_fmt='maven/data/sci/sep/l1/sav_'+resstr+'/YYYY/MM/mvn_sep_l1_YYYYMMDD_'+resstr+'.sav'

  day = 86400L
  trange = day* double(round( (timerange((trange0+ [ 0,day-1]) /day)) ))         ; round to days
  nd = round( (trange[1]-trange[0]) /day)

  for i=0L,nd-1 do begin
    tr = trange[0] + [i,i+1] * day
    tn = tr[0]
    prereq_files=''

    fullres_file=mvn_pfp_file_retrieve(fullres_fmt,trange=tn,/daily_names)
    redures_file=mvn_pfp_file_retrieve(redures_fmt,trange=tn,/daily_names)

    dprint,dlevel=3,fullres_file

    if tr[0] gt time_double('2014-07-17') and tr[0] lt time_double('2014-9-21') then begin
      dprint,verbose=verbose,dlevel=3,'Cruise to Mars, Spacecraft hybernation
      continue
    endif

    if file_test(fullres_file,/regular) eq 0 then begin
      dprint,verbose=verbose,dlevel=2,fullres_file+' Not found. Skipping...
      continue
    endif

    append_array,prereq_files,fullres_file

    prereq_info = file_info(prereq_files)
    prereq_timestamp = max([prereq_info.mtime, prereq_info.ctime])

    target_info = file_info(redures_file)
    target_timestamp =  target_info.mtime

    if keyword_set(timestamp) then target_timestamp = time_double(timestamp) < target_timestamp

    if prereq_timestamp lt target_timestamp then continue    ; skip if lowres L1 does not need to be regenerated
    dprint,verbose=verbose,dlevel=3,'Generating new file: '+redures_file

    f = fullres_file
    if file_test(/regular,f) eq 0 then continue
    dprint,verbose=verbose,dlevel=2,'Loading '+file_info_string(f)
    restore,f
    source_filename=f

    if resstr eq '5min' then begin
      if n_elements(s1_svy) gt 1 then s1_svy=mvn_sep_att_correction(s1_svy,res,tr,/fltatt) else s1_svy=0
      if n_elements(s2_svy) gt 1 then s2_svy=mvn_sep_att_correction(s2_svy,res,tr,/fltatt) else s2_svy=0

      if keyword_set(s1_arc) then s1_arc=mvn_sep_att_arc(s1_arc)
      if keyword_set(s2_arc) then s2_arc=mvn_sep_att_arc(s2_arc)
    endif else begin
      if n_elements(s1_svy) gt 1 then s1_svy=average_hist(s1_svy,s1_svy.time,binsize=res,range=tr,/nan)
      if n_elements(s2_svy) gt 1 then s2_svy=average_hist(s2_svy,s2_svy.time,binsize=res,range=tr,/nan)
      if n_elements(ap24) gt 24 then ap24=average_hist(ap24,ap24.time,binsize=res,range=tr,/nan) else ap24=0
    endelse

    if n_elements(s1_arc) gt 1 then s1_arc=average_hist(s1_arc,s1_arc.time,binsize=res,range=tr,/nan) else s1_arc=0
    if n_elements(s2_arc) gt 1 then s2_arc=average_hist(s2_arc,s2_arc.time,binsize=res,range=tr,/nan) else s2_arc=0

    if n_elements(s1_hkp) gt 1 then s1_hkp=average_hist(s1_hkp,s1_hkp.time,binsize=res,range=tr,/nan) else s1_hkp=0
    if n_elements(s2_hkp) gt 1 then s2_hkp=average_hist(s2_hkp,s2_hkp.time,binsize=res,range=tr,/nan) else s2_hkp=0

    if n_elements(s1_nse) gt 1 then s1_nse=average_hist(s1_nse,s1_nse.time,binsize=res,range=tr,/nan) else s1_nse=0
    if n_elements(s2_nse) gt 1 then s2_nse=average_hist(s2_nse,s2_nse.time,binsize=res,range=tr,/nan) else s2_nse=0

    if n_elements(m1_hkp) gt 1 then m1_hkp=average_hist(m1_hkp,m1_hkp.time,binsize=res,range=tr,/nan) else m1_hkp=0
    if n_elements(m2_hkp) gt 1 then m2_hkp=average_hist(m2_hkp,m2_hkp.time,binsize=res,range=tr,/nan) else m2_hkp=0

    if n_elements(ap20) gt 1 then ap20=average_hist(ap20,ap20.time,binsize=res,range=tr,/nan) else ap20=0
    if n_elements(ap21) gt 1 then ap21=average_hist(ap21,ap21.time,binsize=res,range=tr,/nan) else ap21=0
    if n_elements(ap22) gt 1 then ap22=average_hist(ap22,ap22.time,binsize=res,range=tr,/nan) else ap22=0
    if n_elements(ap23) gt 1 then ap23=average_hist(ap23,ap23.time,binsize=res,range=tr,/nan) else ap23=0
    ;  if n_elements(ap24) gt 1 ;lower cadence than 5min
    ;  if n_elements(ap25) gt 1 ;apid not available

    file_mkdir2,file_dirname(redures_file)
    save,filename=redures_file,verbose=verbose,s1_hkp,s1_svy,s1_arc,s1_nse,s2_hkp,s2_svy,s2_arc,s2_nse,m1_hkp,m2_hkp,$
      ap20,ap21,ap22,ap23,ap24,source_filename,sw_version,prereq_info,spice_info,description=description
    dprint,verbose=verbose,dlevel=1,'Saved   '+file_info_string(redures_file)

  endfor

end
