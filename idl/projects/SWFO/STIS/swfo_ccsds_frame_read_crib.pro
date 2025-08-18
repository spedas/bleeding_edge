;swfo_test
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-02-17 12:53:26 -0800 (Mon, 17 Feb 2025) $
; $LastChangedRevision: 33137 $
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

  run_proc = 1

  ;stop


  if ~isa(rdr) then begin
    swfo_stis_apdat_init,/save_flag
    rdr = ccsds_frame_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
    !p.charsize = 1.2
  endif



  no_download = 0    ;set to 1 to prevent download
  no_update = 1      ; set to 1 to prevent checking for updates

  ;https://sprg.ssl.berkeley.edu/data/swfo/outgoing/swfo-l1/l0/
  source = {$
    remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
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
    1.5: begin
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
      allfiles = file_retrieve(pathname,_extra=source,trange=trange)  ; get All the files first
      fileformat =  file_basename(str_sub(pathname,'*.nc',''))
      filerange = time_string(time_double(trange)+[0,3600],tformat=fileformat)
      if keyword_set(lastfile) then filerange[0] = file_basename(lastfile)
      w = where(file_basename(allfiles) gt filerange[0] and file_basename(allfiles) lt filerange[1] and file_test(allfiles),nw,/null)
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
  parent = dictionary()
  rdr.parent_dict = parent
  rdr.verbose = 3
  rdr.source_dict.run_proc = run_proc
  cntr = dynamicarray('index_counter')
  for i = 0, n_elements(files)-1 do begin
    file = files[i]
    parent.filename = file
    parent.num_duplicates = 0
    parent.max_displacement = 0
    ;    index
    if file_test(file) then begin
      dat = ncdf2struct(file)
      frames = struct_value(dat,frames_name,default = !null)
      index = rdr.getattr('index')
      ;    cntr.append, { index:index,   time: time_double( dat.
      dprint,dlevel=1,string(index)+'   '+ file_basename(file)+ '  '+strtrim(n_elements(frames)/1024, 2)
      rdr.read , frames
      lastfile = file

    endif else begin
      dprint,'No such file: ',file

    endelse
  endfor
  if isa(files) then begin
    wshow,0
    tplot ,verbose=0,trange=systime(1)+[-1,.05] *60*60*10
    timebar,systime(1)
  endif    else dprint,'No new files'
endif


;stop



swfo_apdat_info,/create_tplot_vars,/all;,/print  ;  ,verbose=0

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

;swfo_stis_tplot,'cpt2

end
