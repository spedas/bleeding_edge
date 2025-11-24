;swfo_ccsds_frame_read_crib
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-11-22 07:53:52 -0800 (Sat, 22 Nov 2025) $
; $LastChangedRevision: 33864 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_frame_read_crib.pro $




pro swfo_frame_header_plot, hdrs, _extra = ex
  if n_elements(hdrs) le 1 then begin
    printdat,hdrs
    return
  endif
  plt = get_plot_state()
  ;charsize = !p.charsize
  !p.charsize = 2
  !p.multi = [0,1,8]
  !x.style=3
  !y.style=3
  !y.margin = 1
  !p.psym = struct_value(ex,'psym',default=!p.psym)
  index = lindgen(n_elements(hdrs))
  plot,hdrs.seqn,/ynozero
  seqn_delta = long(hdrs.seqn) - shift(hdrs.seqn,1)
  seqn_delta[0] = 5
  plot,seqn_delta,yrange = [-10,10]
  oplot,seqn_delta,psym=1,color=6,symsize=.5
  plot,hdrs.vcid,/ynozero
  plot,hdrs.sigfield,/ynozero
  ;bitplot,hdrs.index,hdrs.vcid
  plot,hdrs.last4[2],/ynozero
  bitplot,index,hdrs.last4[2],limits=struct(negate=0x0)
  plot,hdrs.seqid,/ynozero
  plot,hdrs.last4[3]
  ;!p.multi=0
  ;!p.charsize = charsize
  restore_plot_state,plt
end







if 0 then begin


  run_proc = 1

  ;stop


  if ~isa(rdr) then begin
    swfo_stis_apdat_init,/save_flag
    rdr = ccsds_frame_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
    !p.charsize = 1.2
  endif





  if 1 || ~keyword_set(files) then begin
    trange = ['2024 9 18','2024 9 19']
    trange = '2024-9-18 / 20:45'
    trange = '2024-9-19 ' + [' 0:0',' 24:00']
    trange = '2024-9-18 ' + [' 0:0',' 24:00']
    trange = ['2024 9 19 12','2024 9 21']
    trange = '2024-9-18 ' + [' 12:0',' 18:00']
    ;trange = ['2024 9 17','2024 9 25']
    trange = '2024 10 17/' + ['0','6']
    trange = '2024 10 18/' + ['0','24']
    ;trange = systime(1) + [-1,0] *3600d *6       ; last few hours
    trange = '2024 10 18/' + ['13:15','16:35']   ; Normal operations including some replay
    trange = ['2024 10 16','2024 10 20']      ; Entirety of E2E2
    ;trange = ['2024 1 291/ 18:00','2024 1 292 / 8:45']   ; some repeated frames
    ;trange = ['2024 1 291/ 22:00','2024 1 292 / 0:45']   ; test some repeated frames
    trange = ['2024 10 16 19:40' , '2024 10 16 2200']    ; LPT?
    trange = ['2024 12 18 12' , '2024 12 18 22']    ; LPT?
    trange = ['2024 12 18 16:00' , '2024 12 18 16:30']    ; memdump test #1
    trange = ['2024 12 18 ' , '2024 12 19']    ; memdump day 1
    trange = ['2024 12 19' , '2024 12 20']    ; memdump day  2
    trange = ['2024 12 18' , '2024 12 21']    ; memdump day  1&2&3
    trange = ['2024 12 20' , '2024 12 21']    ; memdump day  3
    trange = ['2024 12 20 11' , '2024 12 20 14 ']    ; memdump day  3  test only
    trange = ['2025 1 14','2025 1 18']   ; ETE4 RFR
    trange = ['2025 1 16 16','2025 1 16 20']   ; ETE4 RFR
    trange = ['2025 1 12 ','now']   ; ETE4 RFR
    trange = ['2025 1 16 16 ','2025 1 16 19']   ; ETE4 RFR
    trange = ['2025-10- 3 /11 ','2025 10 3 /14']   ; flight with replay
    trange = ['2025 9 30 / 12',time_string(systime(1))]   ; Entire mission
    trange = ['2025-9 30 / 12','2025 10 1'  ]   ; first 12 hours
    trange = ['2025-9 30 / 12','2025 9 30 18'  ]   ; first 6 hours
    trange = ['2025-10 10 / 10','2025 10 10 14'  ]   ; maneuver and bad frames
    trange =  ['2025 10 4 15','2025 10 4 16']   ; bad file time for CBU
    trange = ['2025-10-15 /8 ','2025 10 15 /22 '  ]   ; RW test
    trange =  ['2025-10-17/14:30:00', '2025-10-17/18:25:00'] ; first mag roll with 
    trange = ['2025-10-23 / 14','2025 10 23 / 22'  ]   ; 2nd mag roll with safe hold and replay
    trange = systime(1)   + [-1,0] * 3600d   * 4  ; last few hours
    if rdr.source_dict.haskey('frame_time') then begin
      trange[0] = rdr.source_dict.frame_time - 300
    endif


    no_download = 0    ;set to 1 to prevent download
    no_update = 1      ; set to 1 to prevent checking for updates

    ;https://sprg.ssl.berkeley.edu/data/swfo/outgoing/swfo-l1/l0/
    source = {$
      remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
      master_file:'swfo/.master', $
      min_age_limit :100,$
      no_update : no_update ,$
      no_download :no_download ,$
      resolution: 900L  }

    if ~isa(typecase) then typecase = 2.5
    if ~isa(lastfile) then lastfile = ''
    ;stop

    case typecase of
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


  endif


  if 0 &&  ~isa(dat) then begin

    dat = swfo_ncdf_read(files,force_recdim=1)

    if ~keyword_set(dhdrs) then begin
      foo_rdr = ccsds_frame_reader(mission='SWFO',/no_widget)
      dhdrs = dynamicarray(name='test')
      nframes = n_elements(dat)
      for i=0,nframes-1 do dhdrs.append, foo_rdr.header_struct(dat[i].frames)

    endif
    hdrs = dhdrs.array
    ;hdrs.time = dindgen(n_elements(hdrs))

    if 1 then begin   ; filter out all the duplicate frames
      hsh = hdrs.hashcode
      s= sort(hsh)
      u = uniq( hsh[ s ] )
      hdrs = hdrs[s[u]]
      s = sort(hdrs.index)
      hdrs = hdrs[s]
    endif

    wi,2   ,wsize=[1200,1100]

    if 1 then begin
      hdrs.seqn_delta = hdrs.seqn - shift(hdrs.seqn,1)
      swfo_frame_header_plot, hdrs
      stop


      seqids = hdrs.seqid
      uniq_seqids = seqids[ uniq( seqids, sort(seqids) ) ]
      printdat,uniq_seqids
      for i = 0,n_elements(uniq_seqids)-1 do begin
        w = where( hdrs.seqid eq uniq_seqids[i],nw)
        print,uniq_seqids[i],nw
        swfo_frame_header_plot, hdrs[w]
        stop
      endfor

    endif

  endif





  ;stop

  if 0  then begin
    dprint,print_dtime=0,print_dlevel=0,print_trace=0
    run_proc = 0
    stop
  endif


  if keyword_set(1) then begin

    parent = rdr.parent_dict
    rdr.verbose = 3
    dict = rdr.source_dict
    if ~parent.haskey('filehashes') then parent.filehashes = orderedhash()
    dict.run_proc = run_proc
    ;cntr = dynamicarray('index_counter')
    for i = 0, n_elements(files)-1 do begin
      file = files[i]
      basename = file_basename(file)
      filehash = basename.hashcode()
      if rdr.parent_dict.filehashes.haskey(filehash) then begin
        dprint,dlevel=3, file_basename(file)+ ' Already processed'
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
        lastfile = file
        rdr.parent_dict.filename = file
        rdr.parent_dict.filehashes[filehash] = file

      endif else begin
        dprint,'No such file: ',file

      endelse
    endfor
    if isa(files) then begin
      ;swfo_apdat_info,/create
      ;tplot,'*STIS*TEMP*
      ; wshow,0
      ;tplot ,verbose=0,trange=systime(1)+[-1,.05] *60*60*10
      ;timebar,systime(1)
    endif    else dprint,'No new files'
  endif


  ;stop




  if 0 then begin

    swfo_apdat_info,/print,/all


    printdat,rdr.dyndata.array
    wi,2
    swfo_frame_header_plot, rdr.dyndata.array

    stop




    swfo_stis_tplot,/set
    tplot,'*SEQN *SEQN_DELTA',trange=trange

    stop
    swfo_apdat_info,/sort,/all,/print
    delta_data,'*SEQN',modulo=2^14
    options,'*_delta',psym=-1,symsize=.4,yrange=[-10,10]


    tplot,'*SEQN *SEQN_delta'

    stop
    ;swfo_apdat_info,/make_ncdf,trange=time_double(trange),file_resolution=1800d

  endif

  ;swfo_apdat_info,/create_tplot_vars,/all;,/print  ;  ,verbose=0
  if ~keyword_set(init) then begin
    ;swfo_stis_tplot,'cpt2',/set

    swfo_apdat_info,/create
    l1a_red_da = dynamicarray(name='L1a_red')

    init = 1
  endif

  if init && isa(files) then begin
    dprint,'Merging Level 0A'
    swfo_apdat_info,/merge,/sort,/uniq


    if 1 then begin
      dprint, 'Computing higher level products'
      sci = swfo_apdat('stis_sci')
      l0b_da = sci.getattr('level_0b')
      l1a_da = sci.getattr('level_1a')
      l1b_da = sci.getattr('level_1b')

      l0b_da.array = swfo_stis_sci_level_0b(/getall)
      l1a_da.array = swfo_stis_sci_level_1a( l0b_da.array )
      l1b_da.array = swfo_stis_sci_level_1b( l1a_da.array )
      if ~isa(l1a_red_da,'dynamicarray') then begin
        l1a_red_da = dynamicarray(name = 'L1a_red')
      endif

      l1a_red_da.array = l1a_da.reduce_resolution(30)
    endif


  endif


endif



end
