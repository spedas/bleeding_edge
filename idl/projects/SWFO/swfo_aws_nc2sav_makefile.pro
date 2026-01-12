;$LastChangedBy: rjolitz $
;$LastChangedDate: 2026-01-05 11:49:27 -0800 (Mon, 05 Jan 2026) $
;$LastChangedRevision: 33965 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_aws_nc2sav_makefile.pro $

pro swfo_aws_nc2sav_makefile,trange=trange,make_sav=make_sav,load_sav=load_sav,daily=daily,force_make=force_make,$
  info=info,station=station,res=res,l0b=l0b,l1a=l1a,l1b=l1b,user_pass=user_pass,no_update=no_update, no_download=no_download
  trange = timerange(trange)
  root=root_data_dir()
  sav_path='swfo/data/sci/aws/.sav/'
  nc_path='swfo/aws/'
  if ~keyword_set(station) then station='WCD'
  if ~keyword_set(res) then res='' else res='_'+res
  filepath='preplt/SWFO-L1/l0/SWFO'+station+'/YYYY/MM/YYYYMMDD/'
  filename='OR_SWFO'+station+'-L0_SL1_sYYYYDOYhh*.nc'
  
  source={remote_data_dir:'http://sprg.ssl.berkeley.edu/data/' $ 
    ,master_file: 'swfo/.master'}
    
  if ~keyword_set(no_update) then no_update = 0
  if ~keyword_set(no_download) then no_download = 0
  
  if ~keyword_set(user_pass) then user_pass = getenv('SWFO_USER_PASS')
  if ~keyword_set(user_pass) then begin
    log_info = get_login_info()
    salt = '_a0'
    user_name = log_info.user_name+salt
    user_pass = user_name+':'+log_info.machine_name  ; + !version.release
    pass_word0 = string(format='(i06)', user_pass.hashcode() mod 1000000 )
    dprint,'User_name: ',user_name
    dprint,'password:  ',pass_word0
    user_pass = user_name+ ':' + pass_word0
    printdat,user_pass
  endif

  
  
  source = {$
    remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
    master_file:'swfo/.master', $
    min_age_limit :100,$
    no_update : no_update ,$
    no_download :no_download ,$
    user_pass:  user_pass  }
   

  if keyword_set(daily) then begin
    daysec=86400
    t0=long(trange[0])/daysec
    t1=1+long(trange[1]-1)/daysec
    nd=t1-t0
    for day=0,nd-1 do begin
      tr=(t0+day+[0,1])*daysec
      sav_file=file_retrieve(_extra=source,sav_path+'daily/'+filepath.substring(0,-10)+filename.substring(0,-10)+'MMDD'+res+'.sav',tr=tr,valid=keyword_set(load_sav))
      if keyword_set(make_sav) then begin
        sav_files=file_retrieve(_extra=source,sav_path+filepath+filename+'.sav',trange=tr,resolution=3600,/valid,verbose=1)
        if ~keyword_set(force_make) then if max((file_info(sav_files)).mtime) le (file_info(sav_file.substring(0,-5)+'_30min.sav')).mtime then continue
        swfo_apdat_info,/reset
        swfo_aws_nc2sav_makefile,/load,tr=tr,info=info,station=station,daily=load_sav
        if keyword_set(info['current_filehash']) then begin
          if ~keyword_set(load_sav) then swfo_apdat_info,/compress,parents=info['file_hash_list'],file_save=sav_file
          swfo_apdat_info,/compress,parents=info['file_hash_list'],file_save=sav_file.substring(0,-5)+'_01min.sav',/average,tspan=daysec,binsize=60
          swfo_apdat_info,/compress,parents=info['file_hash_list'],file_save=sav_file.substring(0,-5)+'_30min.sav',/average,tspan=daysec,binsize=60*30
        endif
      endif else if keyword_set(load_sav) then swfo_apdat_info,file_restore=sav_file
    endfor
    return
  endif

  if keyword_set(make_sav) then begin
    ncfiles=file_retrieve(_extra=source,nc_path+filepath+filename,trange=trange,resolution=3600,/valid,verbose=1)
    nctimes=time_double(ncfiles.substring(83,95),tformat='YYYYDOYhhmmss')
    store_data,'nctimes',nctimes,nctimes
    tres_data,'nctimes'
    get_data,'nctimes_tres(s)',dat=dat
    missing=ncfiles[where(dat.y gt 310 and dat.y lt 1000)-1].substring(55)
    rdr=ccsds_frame_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
    dict = rdr.source_dict
    frames_name = 'swfo_frame_data'
    foreach file,ncfiles do begin
      sav_file=root+sav_path+(file).substring(-111)+'.sav'
      if ~keyword_set(force_make) then if (file_info(file)).mtime le (file_info(sav_file)).mtime then continue
      swfo_apdat_info,/reset
      swfo_stis_apdat_init,/reset,/save_flag
      dprint,dlevel=2,'Loading '+file_info_string(file)
      dat = ncdf2struct(file)
      if ~isa(dat) then begin
        dprint,'Bad file: '+file
        continue
      endif
      dict.file_timerange = time_double([dat.time_coverage_start,dat.time_coverage_end])
      dict.file_nframes = n_elements(dat.size_of_frame)
      dict.frame_time = dict.file_timerange[0]
      dict.frame_dtime = (dict.file_timerange[1] - dict.file_timerange[0]) / dict.file_nframes
      dict.file_hash = (file_basename(file)).hashcode()
      dict.station = station eq 'WCD' ? 1:2
      frames = struct_value(dat,frames_name,default = !null)
      index = rdr.getattr('index')
      dprint,dlevel=1,string(index)+'   '+ file_basename(file)+ '  '+strtrim(n_elements(frames)/1024, 2)
      rdr.read,frames
      parent_chksum=file_checksum(file,/add_mtime,relative_position=strlen(root+nc_path))
      swfo_apdat_info,/print,file_save=sav_file,/compress,parents=parent_chksum
    endforeach
  endif

  if keyword_set(load_sav) then begin
    sav_files=file_retrieve(_extra=source,sav_path+filepath+filename+'.sav',trange=trange,resolution=3600,/valid,verbose=1)
    foreach sav_file,sav_files do swfo_apdat_info,file_restore=sav_file
    swfo_apdat_info,/print,/sort,info=info
  endif

end