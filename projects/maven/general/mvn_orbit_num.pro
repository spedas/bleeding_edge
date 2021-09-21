;+
;NAME: MVN_ORBIT_NUM
; function: mvn_orbit_num()
;PURPOSE:
; Returns database structure that contains orbit information about each MAVEN orbit.
; Alternatively - Returns the time if given the orbit number or returns the orbit number if given the time.
;
; This routine uses the NAIF convention, where the orbit number increments at periapsis.  Two other
; conventions are in use for MAVEN: (1) orbit number increments at the inbound periapsis segment
; boundary (LM and IUVS), and (2) orbit number increments at apoapsis (NGIMS).  All three conventions
; agree at periapsis.
;  
;Typical CALLING SEQUENCE:
;  orbdata = mvn_orbit_num()
;  store_data,'orbnum',orbdata.peri_time,orbdata.num,dlimit={ytitle:'Orbit'}
;  tplot,var_label='orbnum'
;
;KEYWORDS:
;  VERBOSE:        Message level for dprint.
;
;  RELOAD_TIME:    Interval at which to sync local files with remote server.  Default = 3600 sec.
;
;  REFRESH:        Ignore RELOAD_TIME and check the remote server anyway.
;  
;TYPICAL USAGE:
;  print, mvn_orbit_num(time=systime(1) )          ;  prints current MAVEN orbit number
;  print ,  time_string( mvn_orbit_num(orbnum = 6.0)  ; prints the time of periapsis of orbit number 6
;  timebar, mvn_orbit_num( orbnum = indgen(300) )   ; plots a vertical line at periapsis for the first 300 orbits
;Author: Davin Larson  - October, 2014
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-09-20 09:12:57 -0700 (Mon, 20 Sep 2021) $
; $LastChangedRevision: 30304 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_orbit_num.pro $
;-

function mvn_orbit_num_read,filename,count,verbose=verbose

  MOI_time = time_double('2014-9-22/02:06')        ; this is only approximate!

  nan = !values.f_nan
  dnan = !values.d_nan
  dat = {num:1L, peri_time:MOI_TIME,  peri_MET:dnan,  APO_time:moi_time+17.5*3600,  sol_lon:nan, sol_lat:nan,  sc_lon:nan, sc_lat:nan,  sc_alt:nan, sol_dist:dnan}

  count=0
  if not keyword_set(filename) then return, dat
  fi = file_info(filename)
  dprint,dlevel=4,verbose=verbose,'Reading file: '+filename+'   ('+strtrim(fi.size,2)+' bytes)   Modified: '+time_string(fi.mtime)
  openr,lun,filename,/get_lun
  i=0L
  while ~eof(lun) do begin
    s=''
    readf,lun,s
    dprint,dlevel=5,s
    if i++ lt 2 then continue
    if strmatch(s,'*Unable*') then continue
    dat.num = long(strmid(s,0,5))
    dat.peri_time = time_double( strmid(s,7,20) ,tformat='YYYY MTH DD hh:mm:ss')
    dat.peri_met  = double( strmid(s,33,16)  )
    dat.apo_time =  time_double( strmid(s,51,20) ,tformat='YYYY MTH DD hh:mm:ss')
    dat.sol_lon  =  double(  strmid(s,72,8) )
    dat.sol_lat  =  double(  strmid(s,81,8) )
    dat.sc_lon   =  double(  strmid(s,90,8) )
    dat.sc_lat   =  double(  strmid(s,99,8) )
    dat.sc_alt   =  double(  strmid(s,108,11) )
    dat.sol_dist =  double(  strmid(s,120,12) )
    append_array,alldat,dat,index=count
  endwhile
  append_array,alldat,index=count,/done
  free_lun,lun
  return,alldat
end



function mvn_orbit_num,orbnum=orbnum,time=time,verbose=verbose,reload_time=reload,refresh=refresh

common mvn_orbit_num_com,alldat,time_cached,filenames
if (~keyword_set(time_cached) or keyword_set(refresh)) then time_cached=1d
if ~keyword_set(reload) then reload = 3600    ; default to one hour
if ((systime(1) - time_cached) gt reload) then begin   ; generate no more than once per hour
  if ~keyword_set(source) then source = spice_file_source(preserve_mtime=1,verbose=verbose,ignore_filesize=1,valid_only=1,last_version=0)
  if ~source.no_server then dprint,dlevel=2,verbose=verbose,'Checking server: ' +source.remote_data_dir+' for new orbit files.' $
                       else dprint,dlevel=2,verbose=verbose,'No server: using local orbit files.'
  filenames = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb_rec_??????_??????_v?.orb',  $
                           local_path = source.local_data_dir+'MAVEN/kernels/spk/', $
                           file_mode = '666'o, dir_mode = '777'o, no_server = source.no_server) ; this algorithm will fail if a version 2 file appears.
  filenames = [filenames,spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb_rec.orb', $
                                      local_path = source.local_data_dir+'MAVEN/kernels/spk/', $
                                      file_mode = '666'o, dir_mode = '777'o, no_server = source.no_server)] ; Recent reconstructed orbits
  filenames = [filenames,spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb.orb', $
                                      local_path = source.local_data_dir+'MAVEN/kernels/spk/', $
                                      file_mode = '666'o, dir_mode = '777'o, no_server = source.no_server)]              ; predicted orbits
  filenames = [filenames,spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb.orb.long', $
                                      local_path = source.local_data_dir+'MAVEN/kernels/spk/', $
                                      file_mode = '666'o, dir_mode = '777'o, no_server = source.no_server)]         ; long term predicts
;  dprint,dlevel=2, n_elements(filenames) gt 1 ? transpose(filenames) : filenames
  if debug(3,verbose) then dprint,dlevel=3,verbose=verbose, file_checksum(filenames,/add_mtime,verbose=0)
  
  alldat = mvn_orbit_num_read('')

  last = 1
  for fi=0,n_elements(filenames)-1 do begin
    dat = mvn_orbit_num_read(filenames[fi],count)
    w = where(dat.num gt last, nw)
    if nw gt 0 then append_array,alldat,dat[w]
    last = max(alldat.num)
  endfor
  time_cached = systime(1)
endif

if n_elements(time) ne 0   then return, interp(double(alldat.num),alldat.peri_time,time_double(time))
if n_elements(orbnum) ne 0 then return, interp(alldat.peri_time,double(alldat.num),double(orbnum))
return , alldat
end







