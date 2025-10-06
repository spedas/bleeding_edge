pro swfo_aws_nc2sav_makefile,trange=trange,make_sav=make_sav,load_sav=load_sav,daily=daily,force_make=force_make,info=info
  trange = timerange(trange)
  root=root_data_dir()
  sav_path='swfo/data/sci/aws/.sav/'
  nc_path='swfo/aws/'
  filepath='preplt/SWFO-L1/l0/SWFOWCD/YYYY/MM/YYYYMMDD/'
  filename='OR_SWFOWCD-L0_SL1_sYYYYDOYhh*.nc'

  if keyword_set(daily) then begin
    nd=long(trange[1]-trange[0])/86400
    for day=0,nd-1 do begin
      tr=trange[0]+(day+[0,1])*86400.
      sav_file=file_retrieve(sav_path+'daily/'+filepath.substring(0,-10)+filename.substring(0,-10)+'MMDD.sav',tr=tr,valid=keyword_set(load_sav))
      if keyword_set(make_sav) then begin
        sav_files=file_retrieve(sav_path+filepath+filename+'.sav',trange=tr,resolution=3600,/valid,verbose=1)
        if ~keyword_set(force_make) then if max((file_info(sav_files)).mtime) le (file_info(sav_file)).mtime then continue
        swfo_apdat_info,/reset
        swfo_aws_nc2sav_makefile,/load,tr=tr,info=info
        if keyword_set(info['current_filehash']) then swfo_apdat_info,file_save=sav_file,/compress,parents=info['file_hash_list']
      endif
      if keyword_set(load_sav) then swfo_apdat_info,file_restore=sav_file
    endfor
    swfo_apdat_info,/create,/print,info=info
    return
  endif

  if keyword_set(make_sav) then begin
    ncfiles=file_retrieve(nc_path+filepath+filename,trange=trange,resolution=3600,/valid,verbose=1)
    rdr=ccsds_frame_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
    frames_name = 'swfo_frame_data'
    foreach ncfile,ncfiles do begin
      sav_file=root+sav_path+(ncfile).substring(-111)+'.sav'
      if ~keyword_set(force_make) then if (file_info(ncfile)).mtime le (file_info(sav_file)).mtime then continue
      swfo_apdat_info,/reset
      swfo_stis_apdat_init,/reset,/save_flag
      dprint,dlevel=2,'Loading '+file_info_string(ncfile)
      dat = ncdf2struct(ncfile)
      frames = struct_value(dat,frames_name,default = !null)
      index = rdr.getattr('index')
      dprint,dlevel=1,string(index)+'   '+ file_basename(ncfile)+ '  '+strtrim(n_elements(frames)/1024, 2)
      rdr.read,frames
      swfo_apdat_info,/print
      parent_chksum=file_checksum(ncfile,/add_mtime,relative_position=strlen(root+nc_path))
      swfo_apdat_info,file_save=sav_file,/compress,parents=parent_chksum
    endforeach
  endif

  if keyword_set(load_sav) then begin
    sav_files=file_retrieve(sav_path+filepath+filename+'.sav',trange=trange,resolution=3600,/valid,verbose=1)
    foreach sav_file,sav_files do swfo_apdat_info,file_restore=sav_file
    swfo_apdat_info,/create,/print,info=info
  endif


end