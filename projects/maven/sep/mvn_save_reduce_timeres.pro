
pro mvn_save_reduce_timeres,pathformat,trange=trange0,init=init,timestamp=timestamp,verbose=verbose,mag_cluge=mag_cluge,resstr=resstr,resolution=res,description=description

if keyword_set(init) then begin
  trange0 = [time_double('2014-9-22'), systime(1) ]
  if init lt 0 then trange0 = [time_double('2013-12-5'), systime(1) ]
endif else trange0 = timerange(trange0)



if keyword_set(mag_cluge) then begin
  pathformat =  'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l1_pl_$RES_YYYYMMDD.sav'  
  description = 'Preliminary MAG Data  - NOT to be used for science purposes. Read info for more info'
endif

if ~keyword_set(resstr) then resstr = '30sec'
if ~keyword_set(res) then begin
   res = double(resstr)
   if strpos(resstr,'min') ge 0 then res *= 60
   if strpos(resstr,'hr') ge 0 then res *= 3600
   dprint,dlevel=3,'Time resolution not provided, Using: ',res,' seconds'
endif


fullres_fmt = str_sub(pathformat, '$RES', 'full')
redures_fmt = str_sub(pathformat, '$RES', resstr)

day = 86400L
trange = day* double(round( (timerange((trange0+ [ 0,day-1]) /day)) ))         ; round to days
nd = round( (trange[1]-trange[0]) /day) 

for i=0L,nd-1 do begin
  tr = trange[0] + [i,i+1] * day
  tn = tr[0]
  prereq_files=''

  fullres_files  = mvn_pfp_file_retrieve(fullres_fmt,trange=tn +[-.001,1.0001d]*day ,/daily_names)   ; use a little bit of files on either side. /This should always return 3 filenames
  redures_file   = mvn_pfp_file_retrieve(redures_fmt,trange=tn,/daily_names,/create_dir)
  
  dprint,dlevel=3,fullres_files[0]
  
  if file_test(fullres_files[1],/regular) eq 0 then begin
    dprint,verbose=verbose,dlevel=2,fullres_files[1]+' Not found. Skipping
    continue
  endif

  append_array,prereq_files,fullres_files

  prereq_info = file_info(prereq_files)
  prereq_timestamp = max([prereq_info.mtime, prereq_info.ctime])
  
  target_info = file_info(redures_file)
  target_timestamp =  target_info.mtime 
  
  if keyword_set(timestamp) then target_timestamp = time_double(timestamp) < target_timestamp

  if prereq_timestamp lt target_timestamp then continue    ; skip if L1 does not need to be regenerated
  dprint,dlevel=1,'Generating new file: '+redures_file
  
  alldata=0
;  all_dependents=''
  all_dependents = file_checksum(prereq_files,/add_mtime)
  
  for j=0,n_elements(fullres_files)-1 do begin
     f = fullres_files[j]
     if file_test(/regular,f) eq 0 then continue
     restore,f    ;,/verbose   ; it is presumed that the variables: 'data' and 'dependents' are defined here.
     append_array,alldata,data
     append_array,all_dependents,dependents
     if j eq 1 then info = header else info=0
  endfor
  
  data = average_hist(alldata,alldata.time,binsize=res,range=tr,stdev=sigma,xbins=centertime)
  data.time = centertime
  sigma.time = centertime
 
  dependents = all_dependents
  
  save,file=redures_file ,data,sigma,dependents,info,description=description

endfor
  
end


