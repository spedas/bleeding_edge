;swfo_ccsds_frame_read
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-10-27 15:44:24 -0700 (Mon, 27 Oct 2025) $
; $LastChangedRevision: 33798 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_frame_read_crib.pro $







pro swfo_ccsds_frame_read,reader=rdr,trange=trange,current=current,typecase=typecase,user_pass=user_pass

  common swfo_ccsds_frame_read_common, reader
  t0 = systime(1)

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

  if ~isa(reader,'CCSDS_FRAME_READER') then begin
    swfo_stis_apdat_init,/save_flag
    reader = ccsds_frame_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
    reader.parent_dict.init = 0
    reader.parent_dict.user_pass = user_pass
  endif

  rdr=reader

  if ~isa(user_pass) then user_pass = rdr.parent_dict.user_pass


  if ~isa(no_download) then no_download = 0    ;set to 1 to prevent download
  no_update = 1      ; set to 1 to prevent checking for updates
  run_proc = 1


  ;https://sprg.ssl.berkeley.edu/data/swfo/outgoing/swfo-l1/l0/
  source = {$
    remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
    master_file:'swfo/.master', $
    min_age_limit :100,$
    no_update : no_update ,$
    no_download :no_download ,$
    user_pass:  user_pass, $
    resolution: 3600L  }
     

  if ~keyword_set(trange) then begin
    if ~keyword_set(current) then current=24
    trange = systime(1)   + [-1,0] * 3600d   * current  ; last 24 hours
  ;  if rdr.source_dict.haskey('frame_time') then begin
  ;    trange[0] = rdr.source_dict.frame_time - 300
  ;  endif

  endif


  if ~isa(typecase,'string') then  typecase = 'WCD'

  case typecase of
    'WCD': begin
      pathname = 'swfo/aws/preplt/SWFO-L1/l0/SWFOWCD/YYYY/MM/YYYYMMDD/OR_SWFOWCD-L0_SL1_sYYYYDOYhh*.nc'
      source.resolution = 3600
      allfiles = file_retrieve(pathname,_extra=source,trange=trange,verbose=2)  ; get All the files first
      fileformat =  file_basename(str_sub(pathname,'*.nc',''))
      filerange = time_string(time_double(trange)+[0,3600],tformat=fileformat)
      ;      if keyword_set(lastfile) then filerange[0] = file_basename(lastfile)
      if 0 then begin
        w = where(file_basename(allfiles) gt filerange[0] and file_basename(allfiles) lt filerange[1] and file_test(allfiles),nw,/null)
      endif else begin
        w = where(file_test(allfiles),nw,/null)
      endelse

      files = allfiles[w]
      frames_name = 'swfo_frame_data'
    end
    'CBU': begin
      pathname = 'swfo/aws/L0/SWFOCBU/YYYY/MM/DD/OR_SWFOCBU-L0_SL1_s*.nc'
      pathname = 'swfo/aws/preplt/SWFO-L1/l0/SWFOCBU/YYYY/MM/YYYYMMDD/OR_SWFOCBU-L0_SL1_sYYYYDOYhh*.nc'
      source.resolution = 3600
      allfiles = file_retrieve(pathname,_extra=source,trange=trange,verbose=2)  ; get All the files first
      fileformat =  file_basename(str_sub(pathname,'*.nc',''))
      filerange = time_string(time_double(trange)+[0,3600],tformat=fileformat)
      ;      if keyword_set(lastfile) then filerange[0] = file_basename(lastfile)
      if 0 then begin
        w = where(file_basename(allfiles) gt filerange[0] and file_basename(allfiles) lt filerange[1] and file_test(allfiles),nw,/null)
      endif else begin
        w = where(file_test(allfiles),nw,/null)
      endelse




;      source.resolution = 3600
 ;     allfiles = file_retrieve(pathname,_extra=source,trange=trange)  ; get All the files first
      ;      fileformat =  file_basename(str_sub(pathname,'*.nc',''))
      ;      filerange = time_string(time_double(trange)+[0,3600],tformat=fileformat)
      ;      if keyword_set(lastfile) then filerange[0] = file_basename(lastfile)
      ;      w = where(file_basename(allfiles) gt filerange[0] and file_basename(allfiles) lt filerange[1] and file_test(allfiles),nw,/null)
      files = allfiles  ;[w]
      frames_name = 'swfo_frame_data'
    end

    0: begin
      pathname = 'swfo/swpc/L0/YYYY/MM/DD/it_frm-rt-l0_swfol1_sYYYYMMDDThhmm00Z_*.nc'
      files = file_retrieve(pathname,_extra=source,trange=trange)
      w=where(file_test(files),/null)
      files = files[w]
    end
    1: begin
      ;pathname = 'swfo/swpc/E2E2b/decomp/swfo-l1/l0/it_frm-rt-l0_swfol1_s*.nc'
      ;pathname = 'swfo/swpc/E2E4/outgoing/swfo-l1/l0/it_frm-rt-l0_swfol1_s*.nc.gz'
      pathname = 'swfo/swpc/E2E4_RFR/outgoing/swfo-l1/l0/it_frm-rt-l0_swfol1_s*.nc.gz'
      allfiles = file_retrieve(pathname,_extra=source)  ; get All the files first
      fileformat = file_basename(str_sub(pathname,'*.nc.gz','YYYYMMDDThhmm00'))
      filerange = time_string(trange,tformat=fileformat)
      w = where(file_basename(allfiles) ge filerange[0] and file_basename(allfiles) lt filerange[1],nw,/null)
      files = allfiles[w]
      frames_name = 'frames'

      if strmid(pathname,2,3,/reverse) eq '.gz' then begin
        ofiles = str_sub(files,'outgoing','decomp')
        for i=0,n_elements(ofiles)-1 do ofiles[i] = strmid(ofiles[i],0,strlen(ofiles[i])-3)   ; get rid of ".gz"
        file_mkdir2,file_dirname(ofiles)
        dprint,'Unzipping files'
        file_gunzip,files,ofiles
        files=ofiles
      endif
    end
    1.5: begin   ; swpc files
      ;pathname = 'swfo/swpc/E2E2b/decomp/swfo-l1/l0/it_frm-rt-l0_swfol1_s*.nc'
      ;pathname = 'swfo/swpc/E2E4/outgoing/swfo-l1/l0/it_frm-rt-l0_swfol1_s*.nc.gz'
      pathname = 'swfo/swpc/E2E4_RFR/outgoing/swfo-l1/l0/it_frm-rt-l0_swfol1_s*.nc.gz'
      pathname = 'swfo/swpc/E2E4_RFR/outgoing/swfo-l1/l0/it_frm-st-l0_swfol1_s*.nc.gz'
      allfiles = file_retrieve(pathname,_extra=source)  ; get All the files first
      fileformat = file_basename(str_sub(pathname,'*.nc.gz','YYYYMMDDThhmm00'))
      filerange = time_string(trange,tformat=fileformat)
      w = where(file_basename(allfiles) ge filerange[0] and file_basename(allfiles) lt filerange[1],nw,/null)
      files = allfiles[w]
      frames_name = 'frames'

      if strmid(pathname,2,3,/reverse) eq '.gz' then begin
        ofiles = str_sub(files,'outgoing','decomp')
        for i=0,n_elements(ofiles)-1 do ofiles[i] = strmid(ofiles[i],0,strlen(ofiles[i])-3)   ; get rid of ".gz"
        file_mkdir2,file_dirname(ofiles)
        dprint,'Unzipping files'
        file_gunzip,files,ofiles
        files=ofiles
      endif
    end
    2: begin
      pathname = 'swfo/aws/L0/SWFOWCD/YYYY/MM/DD/OR_SWFOWCD-L0_SL1_s*.nc'
      pathname = 'swfo/aws/preplt/SWFO-L1/l0/SWFOWCD/YYYY/jan/YYYYMMDD/OR_SWFOWCD-L0_SL1_s*.nc'
      source.resolution = 24L*3600
      allfiles = file_retrieve(pathname,_extra=source,trange=trange)  ; get All the files first
      fileformat =  file_basename(str_sub(pathname,'*.nc','YYYYDOYhhmm'))
      filerange = time_string(trange,tformat=fileformat)
      w = where(file_basename(allfiles) ge filerange[0] and file_basename(allfiles) lt filerange[1],nw,/null)
      files = allfiles[w]
      frames_name = 'swfo_frame_data'
    end
    2.5: begin
      ;pathname = 'swfo/aws/preplt/SWFO-L1/l0/SWFOWCD/YYYY/jan/YYYYMMDD/OR_SWFOWCD-L0_SL1_sYYYYDOYhh*.nc'
      pathname = 'swfo/aws/preplt/SWFO-L1/l0/SWFOWCD/YYYY/MM/YYYYMMDD/OR_SWFOWCD-L0_SL1_sYYYYDOYhh*.nc'
      source.resolution = 3600
      allfiles = file_retrieve(pathname,_extra=source,trange=trange,verbose=2)  ; get All the files first
      fileformat =  file_basename(str_sub(pathname,'*.nc',''))
      filerange = time_string(time_double(trange)+[0,3600],tformat=fileformat)
      if keyword_set(lastfile) then filerange[0] = file_basename(lastfile)
      if 0 then begin
        w = where(file_basename(allfiles) gt filerange[0] and file_basename(allfiles) lt filerange[1] and file_test(allfiles),nw,/null)
      endif else begin
        w = where(file_test(allfiles),nw,/null)
      endelse

      files = allfiles[w]
      frames_name = 'swfo_frame_data'
    end
    3: begin
      pathname = 'swfo/aws/L0/SWFOCBU/YYYY/MM/DD/OR_SWFOCBU-L0_SL1_s*.nc'
      pathname = 'swfo/aws/preplt/SWFO-L1/l0/SWFOCBU/YYYY/MM/YYYYMMDD/OR_SWFOCBU-L0_SL1_sYYYYDOYhh*.nc'
      source.resolution = 3600
      allfiles = file_retrieve(pathname,_extra=source,trange=trange)  ; get All the files first
      fileformat =  file_basename(str_sub(pathname,'*.nc',''))
      filerange = time_string(time_double(trange)+[0,3600],tformat=fileformat)
      if keyword_set(lastfile) then filerange[0] = file_basename(lastfile)
      w = where(file_basename(allfiles) gt filerange[0] and file_basename(allfiles) lt filerange[1] and file_test(allfiles),nw,/null)
      files = allfiles[w]
      frames_name = 'swfo_frame_data'
    end
  endcase



  if keyword_set(1) then begin

    parent = rdr.parent_dict
    ;rdr.verbose = 3
    dict = rdr.source_dict
    if ~parent.haskey('filehashes') then parent.filehashes = orderedhash()
    dict.run_proc = run_proc
    ;cntr = dynamicarray('index_counter')
    for i = 0, n_elements(files)-1 do begin
      file = files[i]
      basename = file_basename(file)
      filehash = basename.hashcode()
      if rdr.parent_dict.filehashes.haskey(filehash) then begin
        dprint,dlevel=2, file_basename(file)+ ' Already processed'
        continue
      endif
      parent.num_duplicates = 0
      parent.max_displacement = 0
      ;    index
      if file_test(file) then begin
        dat = ncdf2struct(file)
        if ~isa(dat) then begin
          dprint,'Bad file: '+file
          continue
        endif
        dict.file_timerange = time_double([dat.time_coverage_start,dat.time_coverage_end])
        dict.file_nframes = n_elements(dat.size_of_frame)
        dict.frame_time = dict.file_timerange[0]
        dict.frame_dtime = (dict.file_timerange[1] - dict.file_timerange[0]) / dict.file_nframes
        dict.file_hash = filehash
        dict.file_name = file

        frames = struct_value(dat,frames_name,default = !null)
        index = rdr.getattr('index')
        ;    cntr.append, { index:index,   time: time_double( dat.
        dprint,dlevel=1,string(index)+'   '+ file_basename(file)+ '  '+strtrim(n_elements(frames)/1024, 2)+'   '+time_string(dict.frame_time)+'  '+strtrim(filehash,2)
        rdr.read , frames
        ;lastfile = file
        rdr.parent_dict.filename = file
        rdr.parent_dict.filehashes[filehash] = file

      endif else begin
        dprint,'No such file: '+file

      endelse
    endfor

    if isa(files) then begin
      if parent.init eq 0  then begin
        swfo_apdat_info,/create                                 ; Create L0A tplot variables   ; warning PB variable might not get created
        parent.products = dictionary()        ; create dictionary for higher level products
        products = rdr.parent.products

        sci = swfo_apdat('stis_sci')
        products.l0b_da = sci.getattr('level_0b')
        products.l1a_da = sci.getattr('level_1a')
        products.l1b_da = sci.getattr('level_1b')

        products.l1a_red_30_da = dynamicarray(name = 'L1a_red')
        parent.init = 1
      endif

      products = parent.products

      if 1 then begin
        dprint,'Merging Level 0A'
        swfo_apdat_info,/merge,/sort,/uniq           ; This will merge all L0A data, sort and eliminate duplicates

        if 1 then begin
          dprint, 'Computing higher level products'

          if products.haskey('l0b_da') then products.l0b_da.array = swfo_stis_sci_level_0b(/getall)
          if products.haskey('l1a_da') then products.l1a_da.array = swfo_stis_sci_level_1a( products.l0b_da.array )
          if products.haskey('l1b_da') then products.l1b_da.array = swfo_stis_sci_level_1b( products.l1a_da.array )

          if products.haskey('l1a_red_30_da') then products.l1a_red_30_da.array = products.l1a_da.reduce_resolution(30)


        endif


      endif

    endif    else dprint,'No new files'
  endif
  dprint,systime()
  dprint,(systime(1)-t0)

end


