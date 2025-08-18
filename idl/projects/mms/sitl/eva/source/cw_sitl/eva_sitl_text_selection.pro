FUNCTION eva_sitl_text_selection, s, email=email, bak=bak
  
  if keyword_set(bak) then begin
    msg = ''
    nmax = n_elements(s.FOM)
  endif else begin
    msg =       eva_sitl_buffdistr(/msg,observatoryID='MMS1')
    msg = [msg, eva_sitl_buffdistr(/msg,observatoryID='MMS2')]
    msg = [msg, eva_sitl_buffdistr(/msg,observatoryID='MMS3')]
    msg = [msg, eva_sitl_buffdistr(/msg,observatoryID='MMS4')]
    nmax = s.NSEGS
  endelse
  
  msg = [msg, ' ']
  
  if keyword_set(bak) then begin
    msg = [msg, '/////// BACK STRUCTURE MODE /////////////', '']
    idx = where(s.DATASEGMENTID eq -1L, ct)
    if ct gt 0 then begin
      NbuffNew = long(total(s.SEGLENGTHS[idx]))
      msg = [msg, 'Total number of new segments = ' + strtrim(string(ct),2)]
      msg = [msg, 'Total number of new buffers = ' + strtrim(string(NbuffNew),2)]
    endif
  endif
  
  
  msg = [msg,'']      
  vsep = '================================================='
  ;vsep = '---------------------------'
  msg = [msg, vsep,'List of selections',vsep]
  
  if keyword_set(bak) then begin
    msg = [msg,'START TIME          - END TIME           ,   FOM,  SIZE, USER, OBSSET, DISCUSSION']
  endif else begin
    msg = [msg,'START TIME          - END TIME           ,   FOM, USER, OBSSET, DISCUSSION']
  endelse

  for n=0,nmax-1 do begin; for each segment
    if keyword_set(bak) then begin;...... back-structure
      stime = time_string(s.START[n])
      etime = time_string(s.STOP[n] + 10.d0)
    endif else begin;............. fomStr
      stime = time_string(s.TIMESTAMPS[s.START[n]])
      etime = time_string(s.TIMESTAMPS[s.STOP[n]]+10.d0)
    endelse
    str_fom = string(s.FOM[n],format='(F5.1)')
    discussion = s.DISCUSSION[n]
    srcID   = s.SOURCEID[n]
    tn = tag_names(s)
    idx=where(tn eq 'OBSSET',ct)
    if ct eq 1 then begin
      if s.OBSSET[n] eq 0B then begin
        obsset = '????'
      endif else begin
        obsset = eva_obsset_byte2bitarray(s.OBSSET[n],/str)
      endelse
    endif
    if keyword_set(bak) then begin
      seglengths = string(s.SEGLENGTHS[n],format='(I4)')
      msg = [msg,stime+' - '+etime+', '+str_fom+', '+seglengths+', '+srcID+', '+obsset+', '+discussion]
    endif else begin
      msg = [msg,stime+' - '+etime+', '+str_fom+', '+srcID+', '+obsset+', '+discussion]
    endelse
  endfor
  msg = [msg, ' ']


  return, msg
END
