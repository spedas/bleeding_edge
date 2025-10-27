;$LastChangedBy: ali $
;$LastChangedDate: 2025-10-24 16:16:24 -0700 (Fri, 24 Oct 2025) $
;$LastChangedRevision: 33791 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_aws_nc2sav_makefile.pro $

pro swfo_aws_nc2sav_makefile,trange=trange,make_sav=make_sav,load_sav=load_sav,daily=daily,force_make=force_make,$
  info=info,c2=c2,res=res,make_levels=make_levels,l0b=l0b,l1a=l1a,l1b=l1b
  trange = timerange(trange)
  root=root_data_dir()
  sav_path='swfo/data/sci/aws/.sav/'
  nc_path='swfo/aws/'
  if ~keyword_set(c2) then c2='WCD'
  if ~keyword_set(res) then res='' else res='_'+res
  filepath='preplt/SWFO-L1/l0/SWFO'+c2+'/YYYY/MM/YYYYMMDD/'
  filename='OR_SWFO'+c2+'-L0_SL1_sYYYYDOYhh*.nc'
  source={remote_data_dir:'http://sprg.ssl.berkeley.edu/data/',master_file: 'swfo/.master'}

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
        swfo_aws_nc2sav_makefile,/load,tr=tr,info=info,c2=c2,daily=load_sav
        if keyword_set(info['current_filehash']) then begin
          if ~keyword_set(load_sav) then swfo_apdat_info,/compress,parents=info['file_hash_list'],file_save=sav_file
          swfo_apdat_info,/compress,parents=info['file_hash_list'],file_save=sav_file.substring(0,-5)+'_01min.sav',/average,tspan=daysec,binsize=60
          swfo_apdat_info,/compress,parents=info['file_hash_list'],file_save=sav_file.substring(0,-5)+'_30min.sav',/average,tspan=daysec,binsize=60*30
        endif
      endif else if keyword_set(load_sav) then swfo_apdat_info,file_restore=sav_file
    endfor
    swfo_apdat_info,/create,/print,/sort,info=info
    if keyword_set(make_levels) then begin
      dprint,'Making L0b'
      l0b = dynamicarray(swfo_stis_sci_level_0b(/getall),name='swfo_stis_L0b')
      store_data,l0b.name,data=l0b ,tagnames = '*'
      tname = 'swfo_stis_L1a'
      dprint,'Making L1: ',tname
      l1a = dynamicarray(swfo_stis_sci_level_1a(l0b.array),name=tname)
      store_data,tname,data = l1a,tagnames = '*'
      store_data,tname,data = l1a,tagnames = 'SPEC_??',val_tag='_NRG'
      store_data,tname,data = l1a,tagnames = 'SPEC_???',val_tag='_NRG'
      store_data,tname,data = l1a,tagnames = 'SPEC_????',val_tag='_NRG'
      options,tname+'_SPEC_??',spec=1, zlog=1, ylog=1
      options,tname+'_SPEC_???',spec=1, zlog=1, ylog=1
      options,tname+'_SPEC_????',spec=1, zlog=1, ylog=1
      options,tname+'_RATE6',/ylog
      ;options,tname+['_RATE','*SIGMA','*BASELINE', /reverse_order, colors ='bgrmcd'
      options,/def,'*_RATE6 *BASELINE *SIGMA *NOISE_TOTAL',colors='bgrmcd',symsize=.5,labels=channels,labflag=-1,constant=0,/reverse_order
      if 0 then begin
        ; Make reduced time resolution
        tname = 'swfo_stis_60s_L1a'
        dprint,'Making L1: ',tname
        l1a_60sec = l1a.reduce_resolution(60d)
        l1a_60sec_da = dynamicarray( l1a_60sec, name='L1a_60sec' )
        store_data,'L1a_avg', data = l1a_60sec_da, tagnames='*'
        store_data,tname,data = l1a_60sec_da,tagnames = '*'
        store_data,tname,data = l1a_60sec_da,tagnames = 'SPEC_??',val_tag='_NRG'
        store_data,tname,data = l1a_60sec_da,tagnames = 'SPEC_???',val_tag='_NRG'
        store_data,tname,data = l1a_60sec_da,tagnames = 'SPEC_????',val_tag='_NRG'
      endif
    endif
    return
  endif

  if keyword_set(make_sav) then begin
    ncfiles=file_retrieve(_extra=source,nc_path+filepath+filename,trange=trange,resolution=3600,/valid,verbose=1)
    nctimes=time_double(ncfiles.substring(83,95),tformat='YYYYDOYhhmmss')
    store_data,'nctimes',nctimes,nctimes
    tres_data,'nctimes'
    get_data,'nctimes_tres(s)',dat=dat
    missing=ncfiles[where(dat.y gt 310)-1].substring(55)
    rdr=ccsds_frame_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
    dict = rdr.source_dict
    frames_name = 'swfo_frame_data'
    foreach ncfile,ncfiles do begin
      sav_file=root+sav_path+(ncfile).substring(-111)+'.sav'
      if ~keyword_set(force_make) then if (file_info(ncfile)).mtime le (file_info(sav_file)).mtime then continue
      swfo_apdat_info,/reset
      swfo_stis_apdat_init,/reset,/save_flag
      dprint,dlevel=2,'Loading '+file_info_string(ncfile)
      dat = ncdf2struct(ncfile)
      dict.file_timerange = time_double([dat.time_coverage_start,dat.time_coverage_end])
      dict.file_nframes = n_elements(dat.size_of_frame)
      dict.frame_time = dict.file_timerange[0]
      dict.frame_dtime = (dict.file_timerange[1] - dict.file_timerange[0]) / dict.file_nframes
      frames = struct_value(dat,frames_name,default = !null)
      index = rdr.getattr('index')
      dprint,dlevel=1,string(index)+'   '+ file_basename(ncfile)+ '  '+strtrim(n_elements(frames)/1024, 2)
      rdr.read,frames
      parent_chksum=file_checksum(ncfile,/add_mtime,relative_position=strlen(root+nc_path))
      swfo_apdat_info,/print,file_save=sav_file,/compress,parents=parent_chksum
    endforeach
  endif

  if keyword_set(load_sav) then begin
    sav_files=file_retrieve(_extra=source,sav_path+filepath+filename+'.sav',trange=trange,resolution=3600,/valid,verbose=1)
    foreach sav_file,sav_files do swfo_apdat_info,file_restore=sav_file
    swfo_apdat_info,/create,/print,/sort,info=info
  endif

end