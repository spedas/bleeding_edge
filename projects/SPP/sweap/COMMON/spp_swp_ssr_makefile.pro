; $LastChangedBy: ali $
; $LastChangedDate: 2021-06-21 09:41:51 -0700 (Mon, 21 Jun 2021) $
; $LastChangedRevision: 30071 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_ssr_makefile.pro $
; $ID: $
;20180524 Ali
;20180527 Davin
;KEYWORDS:
;load_ssr: loads ssr files. very slow, especially during processing of compressed packets.
;load_sav: loads sav files that are generated from ssr files. much faster than above.
;make_sav: creates sav files with one-to-one correspondence to ssr files and/or by apid and day. typically run by a cronjob.
;make_cdf: creates cdf files (L1). typically run by a cronjob.
;force_make: bypasses file timestamp comparison for making files


pro spp_swp_ssr_makefile,trange=trange_full,all=all,type=type,finish=finish,load_ssr=load_ssr,fields=fields, $
  make_cdf=make_cdf,make_ql=make_ql,make_sav=make_sav,load_sav=load_sav,verbose=verbose,reset=reset,sc_files=sc_files, $
  ssr_format=ssr_format,mtime_range=mtime_range,make_tplotvar=make_tplotvar,ssr_prefix=ssr_prefix,force_make=force_make

  if keyword_set(all) then trange_full=[time_double('2018-10-3'),systime(1)] else trange_full=timerange(trange_full)

  t0=systime(1)
  res=86400L
  daynum=round(timerange(trange_full)/res)
  nd=daynum[1]-daynum[0]
  trange=res*double(daynum) ; round to days
  root=root_data_dir()
  output_prefix='psp/data/sci/sweap/'
  sav_ssr=output_prefix+'.sav/L1B/'
  apids=['sc_hkp','swem','wrp', 'spc', 'sp[ab]','spi']+'_*'
  paths=['sc_hkp','swem','swem','spc2','spe',   'spi']
  cdf_suffix='/L1/$NAME$/YYYY/MM/psp_swp_$NAME$_L1_YYYYMMDD_v00.cdf'
  ql_dir=output_prefix+'swem/ql/'
  linkname=output_prefix+'.hidden/.htaccess'
  if ~keyword_set(ssr_prefix) then begin
    ssr_prefix='psp/data/sci/sweap/sao/psp/data/moc_data_products/'
    if keyword_set(fields) then ssr_prefix='psp/data/sci/MOC/SPP/data_products/'
  endif
  if ~isa(ssr_format,/string) then ssr_format = 'YYYY/DOY/*_?_E?'
  if keyword_set(sc_files) then ssr_format = 'YYYY/DOY/*_?_F?'
  if ~isa(make_sav) then make_sav=0
  tr=timerange(trange_full)
  relative_position=strlen(root)

  if keyword_set(load_ssr) || (make_sav eq 1) then begin
    ssr_files=spp_file_retrieve(ssr_format,trange=tr,/daily_names,/valid_only,prefix=ssr_prefix+'ssr_telemetry/',verbose=verbose)
    if ~keyword_set(ssr_files) then dprint,dlevel=2,verbose=verbose,'No files found with format: '+ssr_prefix+'ssr_telemetry/'+ssr_format
    if keyword_set(mtime_range) then begin
      fi=file_info(ssr_files)
      mtrge=time_double(mtime_range)
      w=where(fi.mtime ge mtrge[0],/null)
      fi=fi[w]
      if n_elements(mtrge) ge 2 then begin
        w=where(fi.mtime lt mtrge[1],/null)
        fi=fi[w]
      endif
      ssr_files=fi.name
    endif
    if keyword_set(load_ssr) then spp_ssr_file_read,ssr_files,/sort_flag,/finish,no_init=~keyword_set(reset),kernels=kernels
  endif

  if keyword_set(load_sav) then begin ;loads sav files
    sav_files=spp_file_retrieve(ssr_format+'.sav',trange=tr,/daily_names,prefix=sav_ssr,/valid_only,verbose=verbose)
    if ~keyword_set(sav_files) then dprint,dlevel=2,verbose=verbose,'No files found with format: '+sav_ssr+ssr_format+'.sav'
    if make_sav eq 2 then begin ;loads ssr-specific sav files and creates apid-specific sav files (typically not used by default)
      foreach sav_file,sav_files do begin
        parents='file_checksum not saved for parents of: '+sav_file.substring(relative_position)
        spp_apdat_info,/reset
        spp_apdat_info,file_restore=sav_file,parents=parents
        spp_swp_apdat_init,/reset
        if keyword_set(type) then aps=spp_apdat(type) else aps=spp_apdat(apids)
        parent_chksum=file_checksum(sav_file,/add_mtime,relative_position=relative_position)
        foreach apid,apids,api do spp_apdat_info,apid,cdf_pathname=output_prefix+paths[api]+cdf_suffix,cdf_linkname=linkname
        foreach a,aps do a.sav_makefile,sav_file=file_basename(sav_file),parents=[parent_chksum,'grandparents>',parents]
      endforeach
    endif else begin
      foreach sav_file,sav_files do spp_apdat_info,file_restore=sav_file
      del_data,'spp_*'
      spp_swp_apdat_init,/reset
      spp_apdat_info,finish=finish,/all,/sort_flag
    endelse
  endif

  if make_sav eq 1 then begin ;creates ssr-specific and apid-specific sav files (default)
    foreach ssr_file,ssr_files do begin
      sav_file=root+sav_ssr+(ssr_file).substring(-24)+'.sav' ;substring is preferred here. strsub may fail b/c ssr_prefix can change!
      if ~keyword_set(force_make) then if (file_info(ssr_file)).mtime le (file_info(sav_file)).mtime then continue
      spp_apdat_info,/reset
      spp_swp_apdat_init,/reset
      spp_ssr_file_read,ssr_file,kernels=kernels
      knl_chksum=file_checksum(kernels,/add_mtime,relative_position=relative_position)
      ssr_chksum=file_checksum(ssr_file,/add_mtime,relative_position=strlen(root+ssr_prefix))
      parent_chksum=[knl_chksum,ssr_chksum]
      dprint,parent_chksum
      spp_apdat_info,/print
      foreach memdump,spp_apdat('*_memdump') do memdump.nomem ;clearing memdump ram to get smaller file size. apids:['342'x,'3b8'x,'36d'x,'37d'x]
      foreach prod,spp_apdat('sp[abi]_[as][ft]*') do prod.clear,/noprod ;clearing multidimensional products
      spp_apdat_info,/trim ;trimming the size and clearing last_data_p and ccsds_last
      if keyword_set(type) then aps=spp_apdat(type) else aps=spp_apdat(apids)
      foreach apid,apids,api do spp_apdat_info,apid,cdf_pathname=output_prefix+paths[api]+cdf_suffix,cdf_linkname=linkname
      foreach a,aps do a.sav_makefile,sav_file=file_basename(sav_file),parents=parent_chksum
      spp_apdat_info,file_save=sav_file,/compress,parents=parent_chksum
    endforeach
    ;save,file=sav_file+'.code',/routines,/verbose
  endif

  if keyword_set(make_tplotvar) then spp_swp_tplot,setlim=2

  if keyword_set(make_cdf) then begin ;make cdf files
    ssr_prefix=output_prefix & ssr_format=cdf_suffix ;for the Finish dprint message at the end of the code
    spp_apdat_info,/reset
    spp_swp_apdat_init,/reset
    if keyword_set(type) then aps=spp_apdat(type) else aps=spp_apdat(apids)
    foreach apid,apids,api do spp_apdat_info,apid,cdf_pathname=output_prefix+paths[api]+cdf_suffix,cdf_linkname=linkname
    foreach a,aps do begin
      for day=daynum[0],daynum[1] do begin ;loop over days
        trdaily=double(day*res)
        trange=trdaily+[0,1]*res
        dprint,dlevel=3,verbose=verbose,'Time: '+strjoin("'"+time_string(trange)+"'",' to ')
        if make_cdf eq 2 then a.cdf_makefile,trange=trange ;makes cdf after loading all_apdat from ssr or sav files
        if make_cdf eq 1 then begin ;makes cdf from apid-specific daily sav files
          sav_format=str_sub(a.cdf_pathname.substring(0,-8),'L1','L1A')
          sav_time=time_string(trange[0],tformat=sav_format)
          sav_name=str_sub(sav_time,'$NAME$',a.name)
          sav_files=file_search(root+sav_name+'*_?_??.sav')
          if ~keyword_set(sav_files) then continue
          cdf_file=time_string(trange[0],tformat=a.cdf_pathname)
          cdf_file=root+str_sub(cdf_file,'$NAME$',a.name)
          if ~keyword_set(force_make) then if max((file_info(sav_files)).mtime) le (file_info(cdf_file)).mtime then continue
          if ~keyword_set(dummy) then dummy=obj_new('spp_swp_span_prod') ;ensuring the latest span_prod structure definition is compiled before restoring the save files to avoid type mismatch
          cdf=!null
          parents1=!null
          foreach sav_file,sav_files do begin
            self=!null
            parents='file_checksum not saved for parents of: '+sav_file.substring(relative_position)
            dprint,dlevel=1,verbose=verbose,'Restoring '+file_info_string(sav_file)
            restore,sav_file,/relax,/skip
            if obj_valid(cdf) then cdf.append,self else cdf=self
            parents1=[parents1,parents]
          endforeach
          cdf.trim
          parents2=parents1[uniq(parents1,sort(parents1))]
          time=spp_spc_met_to_unixtime(cdf.array.met,kernels=kernels)
          (*(cdf.data.ptr)).time=time
          cdf.sort
          cdf.cdf_linkname=linkname
          parents_chksum=file_checksum(sav_files,/add_mtime,relative_position=relative_position)
          kernels_chksum=file_checksum(kernels,/add_mtime,relative_position=relative_position)
          cdf.cdf_makefile,filename=cdf_file,parents=[parents_chksum,kernels_chksum,'grandparents>',parents2]
        endif
      endfor
    endforeach
  endif

  if keyword_set(make_ql) then begin
    ql_names=['SWEM2','SE_SUM1','SI_SUM1']
    wi,size=[1200,800]
    nt = n_elements(ql_names)
    tlimit,trange
    for it=0L,nt-1 do begin ;loop over tplots
      pngpath=ql_dir+ql_names[it]+'/YYYY/MM/spp_ql_'+ql_names[it]+'_YYYYMMDD'
      pngfile=spp_file_retrieve(pngpath,trange=trdaily,/create_dir,/daily_names)
      spp_swp_tplot,ql_names[it],/setlim
      makepng,pngfile
    endfor
  endif
  dprint,dlevel=1,verbose=verbose,' Finished in '+strtrim(systime(1)-t0,2)+' seconds on '+systime()+' '+ssr_prefix+'ssr_telemetry/'+ssr_format

end
