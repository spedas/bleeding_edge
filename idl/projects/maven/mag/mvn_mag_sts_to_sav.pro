;+
; $LastChangedBy: ali $
; $LastChangedDate: 2023-10-21 18:50:42 -0700 (Sat, 21 Oct 2023) $
; $LastChangedRevision: 32205 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mag/mvn_mag_sts_to_sav.pro $
;This procedure will create IDL save files from STS files. It is only intended to be run from a batch job
;-

pro mvn_mag_sts_to_sav,trange=trange0,init=init,verbose=verbose,coord=coord,level=level

  if keyword_set(init) then trange0 = [time_double('2013-12'), systime(1) ] else trange0 = timerange(trange0)

  if ~keyword_set(coord) then coord = 'pl'
  if ~keyword_set(level) then level = 'l1'
  if level eq 'l1' then begin
    level2='ql'
    description='Preliminary MAG Data - Not to be used for science purposes. Read header for more info.'
  endif else level2='l2'

  sts_fileformat =  'maven/data/sci/mag/'+level+'/YYYY/MM/mvn_mag_'+level2+'_YYYY*DOY'+coord+'_YYYYMMDD_v??_r??.sts'
  sav_fileformat =  'maven/data/sci/mag/'+level+'/sav/$RES/YYYY/MM/mvn_mag_'+level+'_'+coord+'_$RES_YYYYMMDD.sav'

  fmt = str_sub(sav_fileformat, '$RES', 'full')
  res = 86400L
  trange = res* double(round( (timerange((trange0+ [ 0,res-1]) /res)) )) ;round to days
  nd = round( (trange[1]-trange[0]) /res)

  for i=0L,nd-1 do begin
    tr = trange[0] + [i,i+1] * res
    sts_files = mvn_pfp_file_retrieve(sts_fileformat,trange=tr,/daily_names)
    sts_file = sts_files[0]
    if file_test(sts_file,/regular) eq 0 then continue

    sav_file = mvn_pfp_file_retrieve(fmt,/daily,trange=tr[0],source=source,verbose=verbose,create_dir=1)
    if file_modtime(sts_file) lt file_modtime(sav_file) then continue ;skip if L1 does not need to be regenerated

    data = mvn_mag_sts_read(sts_file,header=header)
    dependents = file_checksum(sts_file,/add_mtime)

    save,file=sav_file,data,dependents,header,description=description
    dprint,verbose=verbose,'Created: '+file_info_string(sav_file)
  endfor

end
