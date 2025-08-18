FUNCTION sitl_report_latest_info, s, file, dir
  compile_opt idl2

  ;-------------
  ; trange
  ;-------------
  nmax = s.NUMCYCLES
  start_time = time_string(s.timestamps[0],precision=3)
  dtlast = s.TIMESTAMPS[nmax-1]-s.TIMESTAMPS[nmax-2]
  end_time = time_string(s.TIMESTAMPS[nmax-1]+dtlast,precision=3)
  trange = [time_double(start_time), time_double(end_time)]

  ;-------------
  ; str_orbit
  ;-------------
  str_trange = time_string(trange)
  sroi_array = get_mms_srois(start_time=str_trange[0], end_time=str_trange[1], sc_id = 'mms1')
  str_orbit = sroi_array[0].ORBIT

  ;-------------
  ; str_window
  ;-------------
  str_ts = strjoin(strsplit(time_string(s.TIMESTAMPS[0]),'-',/extract),'.')
  str_te = strjoin(strsplit(time_string(s.TIMESTAMPS[nmax-1]),'-',/extract),'.')
  str_ds = strmid(str_ts,8,2)
  str_de = strmid(str_te,8,2)
  str_win = strmid(str_ts,0,10)
  if (str_ds ne str_de) then str_win += '-'+strmid(str_te,8,2)
  pname = strjoin(strsplit(time_string(s.TIMESTAMPS[0]),':',/extract))
  pname = strjoin(strsplit(pname,'/',/extract),'_')
  yyyy  = strmid(pname,0,4)

  ;-------------
  ; str_sitl
  ;-------------
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

  if(str_sitl eq 'ABS')then begin
    str_buff = ''
    str_notes = ''
    fname = ''
    evalstarttime=0L
  endif else begin

    ;-------------
    ; str_buff
    ;-------------
    str_buff = strtrim(string(floor(s.NBUFFS)),2)
    min = floor(float(s.NBUFFS)/6.)
    str_buff += ' ('+strtrim(string(min),2)+' min)'

    ;-------------
    ; str_notes
    ;-------------
    tn = tag_names(s)
    idx = where(strmatch(tn,'NOTE'),ct)
    if ct gt 0 then begin
      str_notes = s.NOTE
    endif else str_notes = ''

    idx = where(strmatch(tn,'EVALSTARTTIME'),ct)
    if ct gt 0 then begin
      evalstarttime = s.EVALSTARTTIME
    endif else evalstarttime = 0L

    ;------------------------
    ; selections (sav file)
    ;------------------------
    file_element = strsplit(file,'/',count=count, /extract)
    fname_temp = strsplit(file_element[count-1],'.',count=ct,/extract)
    fname = fname_temp[ct-2]


    ;------------------------
    ; selections (txt file)
    ;------------------------
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

  endelse

  return, {trange:trange, str_win:str_win, yyyy:yyyy, pname:pname,fname:fname, $
    str_sitl:str_sitl, str_buff:str_buff, str_notes:str_notes, $
    str_orbit:str_orbit, evalstarttime:evalstarttime, select:'1'}

END