PRO sitl_report_latest_old, dir=dir, force=force
  compile_opt idl2
  clock= tic('sitl_report_latest')
  
  ;//////////////////////////////////////////////
  json = 1L
  paramset = 'SITL_Dayside_Basic';'SITL_Tail_Basic';'SITL_Basic_NoFPI';'SITL_Basic_Tail'; SITL_Basic_Dayside
  if undefined(dir) then dir = '/Volumes/moka/public_html/eva/' $
    else dir = spd_addslash(dir)
  if undefined(force) then force = 1
  ;////////////////////////////////////////////////
  mms_init
  
  ;-------------
  ; CATCH ERROR
  ;-------------
  catch, error_status; !ERROR_STATE is set
  if error_status ne 0 then begin
    catch, /cancel; Disable the catch system
    eva_error_message, error_status
    message, /reset; Clear !ERROR_STATE
    return
  endif
  
  ;--------------------
  ; LOAD FOMstr (AUTO)
  ;--------------------
  eva_sitl_load_soca_simple, unix_FOMstr=unix_FOMstr,/no_gui
  if n_tags(unix_FOMstr) eq 0 then begin
    print, 'Failed to load FOMstr (AUTO)'
    return
  endif
  
  ;------------------------------------
  ; Load FOMstr (SITL)
  ;------------------------------------

  get_latest_sitl_from_soc, fom_file, error_flag, error_msg
  if error_flag then begin
    print,'EVA: '+error_msg
    result=dialog_message(error_msg,/center)
    return
  endif
  restore, fom_file
  mms_convert_fom_tai2unix, FOMstr, s, start_string
  tfom = eva_sitl_tfom(s)
  Dnew=eva_sitl_strct_read(s,tfom[0])
  
  get_data,'mms_soca_fomstr',data=D,lim=lim,dl=dl; skelton
  store_data,'mms_stlm_fomstr',data=Dnew,lim=lim,dl=dl
  options,   'mms_stlm_fomstr',ytitle='FOM', ysubtitle='(SITL)', constant=[50,100,150,200]
  options,   'mms_stlm_fomstr','unix_FOMStr_mod', s; add unixFOMStr_mod
  options,   'mms_stlm_fomstr','unix_FOMStr_org'; remove unixFOMStr_org
  
  ylim, 'mms_stlm_fomstr',0,1.1*max(Dnew.y,/nan)

  ;--------------------------------------
  ; CHECK Submission of SITL_selections
  ;--------------------------------------
  if (s.METADATAEVALTIME ne unix_FOMstr.METADATAEVALTIME) then begin
    print,'SITL_selections not submitted yet...returning'
    ;return
    SUBMITTED = 0L
  endif else SUBMITTED = 1L
  force = 1
  
;  rtr  = [s.TIMESTAMPS[0], s.TIMESTAMPS[s.NUMCYCLES-1]]; SITL file
;  rtr0 = [unix_FOMstr.TIMESTAMPS[0], unix_FOMstr.TIMESTAMPS[unix_FOMstr.NUMCYCLES-1]]; ABS file
;  sol = segment_overlap(rtr, rtr0)
;  if (sol eq 2) or (sol eq -2) then begin
;    SUBMITTED = 0
;    force = 1 
;  endif else begin
;    SUBMITTED = 1
;    force = 1;0
;  endelse

  ;-------------------
  ; GET INFORMATION
  ;-------------------
  
  ; ROI
  nmax = unix_FOMstr.NUMCYCLES
  str_ts = strjoin(strsplit(time_string(unix_FOMstr.TIMESTAMPS[0]),'-',/extract),'.')
  str_te = strjoin(strsplit(time_string(unix_FOMstr.TIMESTAMPS[nmax-1]),'-',/extract),'.')
  str_ds = strmid(str_ts,8,2)
  str_de = strmid(str_te,8,2)
  str_roi = strmid(str_ts,0,10)
  if (str_ds ne str_de) then str_roi += '-'+strmid(str_te,8,2)
  pname = strjoin(strsplit(time_string(unix_FOMstr.TIMESTAMPS[0]),':',/extract))
  pname = strjoin(strsplit(pname,'/',/extract),'_')
  yyyy  = strmid(pname,0,4)
  
  ; time range
  start_time = time_string(unix_FOMstr.timestamps[0],precision=3)
  dtlast = unix_FOMstr.TIMESTAMPS[nmax-1]-unix_FOMstr.TIMESTAMPS[nmax-2]
  end_time = time_string(unix_FOMstr.TIMESTAMPS[nmax-1]+dtlast,precision=3)
  trange = [time_double(start_time), time_double(end_time)]
  
  ; SITL
  if SUBMITTED then begin
    ;arr = ['a','a','a','b','c','c','a']; for test
    arr = s.SOURCEID
    idx = uniq(arr, sort(arr))
    uniq_src = arr[idx]
    mmax = n_elements(uniq_src)
    count = lonarr(mmax)
    for m=0,mmax-1 do begin
      idx = where(arr eq uniq_src[m], ct)
      count[m] = ct
    endfor
    result = max(count,k, /nan)
    str_sitl = uniq_src[k]
    p = strpos(str_sitl,'(')
    if (p ge 0) then str_sitl = strmid(str_sitl,0,p) 
  endif else str_sitl = 'Not submitted yet'
  
  ; buffers selected
  if SUBMITTED then begin
    str_buff = strtrim(string(floor(s.NBUFFS)),2)
    min = floor(float(s.NBUFFS)/6.)
    str_buff += ' ('+strtrim(string(min),2)+' min)'
  endif else str_buff = ''
  
  ; notes
  if SUBMITTED then begin
    tn = tag_names(s)
    idx = where(strmatch(tn,'NOTE'),ct)
    if ct gt 0 then begin
      str_notes = s.NOTE
    endif else str_notes = ''
  endif else str_notes = ''
  
  ; sav file
  if SUBMITTED then begin
    file_element = strsplit(fom_file,'/',count=count, /extract)
    fname_temp = strsplit(file_element[count-1],'.',count=ct,/extract)
    fname = fname_temp[ct-2]
  endif else fname = ''
  ;str_url = 'https://lasp.colorado.edu/mms/sdc/team/about/browse/sitl/sitl_selections/'
  ;str_url = file_element[count-1]
  
  ; png file
  ;--------------
  thisDevice = !D.Name
  Set_Plot, 'Z'
  Erase
  ;Device, Set_Resolution=[1280,768],Set_Pixel_Depth=24, Decomposed=0
  ;Device, Set_Resolution=[1536,922],Set_Pixel_Depth=24, Decomposed=0
  Device, Set_Resolution=[1664,998],Set_Pixel_Depth=24, Decomposed=0
  spd_graphics_config
  ;---------------
  probes = ['1','2','3','4']
  pmax = n_elements(probes)
  pngsize = fltarr(pmax) 
  
  for p=0,pmax-1 do begin
    eva_cmd_load,trange=trange,probes=probes[p],paramset=paramset,paramlist=paramlist, force=force
    dir_png = spd_addslash(dir)+'img/'+yyyy+'/'
    file_mkdir, dir_png
    imax = n_elements(paramlist)
    thislist = strarr(imax)
    for i=0,imax-1 do begin
      a = strsplit(paramlist[i],'*',/extract,count=count)
      case count of
        1: thislist[i] = paramlist[i]
        2: thislist[i] = a[0]+probes[p]+a[1]; if '*' is found
        else: stop 
      endcase
    endfor

    ; var lab
    var_lab = ''
    tn=tnames('mms'+probes[p]+'_position_mlt',mmax)
    if (strlen(tn[0]) gt 0) and (mmax gt 0) then var_lab = [var_lab,tn[0]]
    tn=tnames('mms'+probes[p]+'_position_z',mmax)
    if (strlen(tn[0]) gt 0) and (mmax gt 0) then var_lab = [var_lab,tn[0]]
    tn=tnames('mms'+probes[p]+'_position_y',mmax)
    if (strlen(tn[0]) gt 0) and (mmax gt 0) then var_lab = [var_lab,tn[0]]
    tn=tnames('mms'+probes[p]+'_position_x',mmax)
    if (strlen(tn[0]) gt 0) and (mmax gt 0) then var_lab = [var_lab,tn[0]]
    var_lab = (n_elements(var_lab) gt 1) ? var_lab[1:*] : ''
    tplot_options, 'title','MMS '+probes[p]+'   (updated at '+time_string(systime(/seconds,/utc))+')' 
    tplot,thislist, var_lab=var_lab
    write_png, dir_png+pname+'_mms'+probes[p]+'.png', tvrd(/true)
    info=file_info(dir_png+pname+'_mms'+probes[p]+'.png')
    pngsize[p] = info.SIZE
    tr = timerange() & dt = (tr[1]-tr[0])/3.d0 & tp = 60.d0
    tlimit,-tp+tr[0]        ,tp+tr[0]+     dt & write_png, dir_png+pname+'_mms'+probes[p]+'_a.png',tvrd(/true)
    tlimit,-tp+tr[0]+     dt,tp+tr[0]+2.d0*dt & write_png, dir_png+pname+'_mms'+probes[p]+'_b.png',tvrd(/true)
    tlimit,-tp+tr[0]+2.d0*dt,tp+tr[0]+3.d0*dt & write_png, dir_png+pname+'_mms'+probes[p]+'_c.png',tvrd(/true)
    
    openu,mf,dir+'sitl_report_log.txt',/get_lun,/append
    printf,mf, time_string(systime(/seconds,/utc)), ', eva_cmd_load for p=',probes[p],' with SUBMITED=',SUBMITTED
    free_lun, mf
  endfor
  result = max(pngsize,p,/nan)
  select = strtrim(string(probes[p]),2)
  ;-----------------
  set_plot, thisDevice
    
  ; selection list
  if SUBMITTED then begin
    header = eva_sitl_text_selection(s)
    dir_list = spd_addslash(dir)+'list/'+yyyy+'/'
    file_mkdir, dir_list
    flist = dir_list+pname+'.txt'
    openw, nf, flist,/get_lun
    pmax = n_elements(header)
    for p=0,pmax-1 do begin
      printf, nf, header[p]
    endfor
    free_lun, nf
  endif
  
  ; Orbit Number
 
  str_trange = time_string(trange) 
  sroi_array = get_mms_srois(start_time=str_trange[0], end_time=str_trange[1], sc_id = 'mms'+probes[0])
  this_orbit = sroi_array[0].ORBIT
  
  ;------------------
  ; OUTPUT (JSON)
  ;------------------
  if keyword_set(json) then begin
    if !VERSION.RELEASE lt 8.2 then begin
      print,'JSON SERIALIZE not supported before IDL 8.2'
      return
    endif
    strct = {roi:str_roi, sitl:str_sitl, buff:str_buff, fname:fname, pname:pname, $
      select:select, yyyy:yyyy, notes:str_notes, orbit:this_orbit}
    
    ; Read existing json
    fjson  = spd_addslash(dir)+'sitl_report.json'
    openr,nf,fjson,/get_lun ; open as a file with the pointer at the end
    line = '' & readf, nf, line; first line
    jarr = line
    while ~ eof(nf) do begin
      readf, nf, line
      jarr = [jarr,line]
    endwhile
    free_lun, nf
    jmax = n_elements(jarr)
    
    ; check if the same ROI exists in the list
    idx = where(strpos(jarr,str_roi) ge 0, ct, complement=c_idx, ncomplement=nc)
    ; json_serialize (replace if the same ROI existed)
    if (ct gt 0) then begin; if the same ROI existed...
      jothers = jarr[c_idx]; remove entries with the same ROI
      jarr = ['[', json_serialize(strct)+',',jothers[1:nc-1]]; remove j=0 because it is '['
    endif else begin
      jarr = ['[', json_serialize(strct)+',',jarr[1:jmax-1]]
    endelse

    ; output
    print,'$$$$ output start $$$$$$$$$$$$$$$$$$$$$$'
    openw,mf,fjson,/get_lun ; open as a new file
    print,'nf,mf=',nf,mf
    print,'fjson=',fjson
    pmax = n_elements(jarr)
    for p=0,pmax-1 do begin
      printf, mf, jarr[p]
    endfor
    free_lun, mf
    print,'$$$$ output end $$$$$$$$$$$$$$$$$$$$$$'
  endif; if json
  print, 'SUBMITTED=',SUBMITTED
  toc, clock
END