;+
; $LastChangedBy: ali $
; $LastChangedDate: 2023-10-21 18:50:42 -0700 (Sat, 21 Oct 2023) $
; $LastChangedRevision: 32205 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mag/mvn_mag_gen_l1_sav.pro $
;This procedure will create IDL save files from STS files.  It is only intended to be run from a batch job
;-

pro mvn_mag_gen_l1_sav,trange=trange0,init=init,verbose=verbose
  message,'obsolete, replaced by mvn_mag_sts_to_sav'

  if keyword_set(init) then begin
    trange0 = [time_double('2014-10-6'), systime(1) ]
    if init lt 0 then trange0 = [time_double('2014-9-22'), systime(1) ]
  endif else trange0 = timerange(trange0)

  ;filename example:/maven/data/sci/mag/l1/2014/10/mvn_mag_ql_2014d290pl_20141017_v00_r01.sts
  STS_fileformat =  'maven/data/sci/mag/l1/YYYY/MM/mvn_mag_ql_YYYY*DOYpl_YYYYMMDD_v??_r??.sts'
  sav_fileformat =  'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l1_pl_$RES_YYYYMMDD.sav'

  L1fmt = str_sub(sav_fileformat, '$RES', 'full')
  res = 86400L
  trange = res* double(round( (timerange((trange0+ [ 0,res-1]) /res)) ))         ; round to days
  nd = round( (trange[1]-trange[0]) /res)

  for i=0L,nd-1 do begin
    tr = trange[0] + [i,i+1] * res
    mag_l1_files = mvn_pfp_file_retrieve(STS_fileformat,trange=tr,/daily_names)
    mag_l1_file = mag_l1_files[0]
    if file_test(mag_l1_file,/regular) eq 0 then continue

    sav_filename = mvn_pfp_file_retrieve(L1fmt,/daily,trange=tr[0],source=source,verbose=verbose,create_dir=1)
    if file_modtime(mag_l1_file) lt file_modtime(sav_filename) then continue    ; skip if L1 does not need to be regenerated
    dprint,dlevel=1,verbose=verbose,'Generating L1 file: '+sav_filename

    data = mvn_mag_l1_sts_read(mag_l1_file,header=header)
    dependents = file_checksum(mag_l1_file,/add_mtime)

    save,file=sav_filename,data,dependents,header,description='Preliminary MAG Data - Not to be used for science purposes. Read header for more info'
  endfor

end
