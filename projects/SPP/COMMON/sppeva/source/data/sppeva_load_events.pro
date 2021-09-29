FUNCTION sppeva_load_events, filename, ephem=ephem
  compile_opt idl2
  
;  if undefined(filename) then begin
;    filename = ProgramRootDir()+'spp.mde.txt'
;  endif
;  result = read_ascii(filename, count=count, data_start=6, template=sppeva_load_events_template())
  
  s = sppeva_load_mde()
  nmax = n_elements(s)
  stime = ''
  etime = ''
  label = ''
  ct = 0
  for n = 0, nmax-1 do begin
    if(strpos(s[n],'Orbit') eq 0)then begin
      label = [label, 'Orbit ' + string(ct+1,format='(I2)')]
      ;---------------
      ; Ephem
      ;---------------
      if keyword_set(ephem) then begin
        str = strsplit(s[n+2],' ', count=count,/extract)
        if(count eq 4) then begin
          stime = [stime, time_string(time_double(str[0]+' '+str[1],tformat='MM-DD-YYYY hh:mm:ss'))]
          etime = [etime, time_string(time_double(str[2]+' '+str[3],tformat='MM-DD-YYYY hh:mm:ss'))]
        endif else begin
          rst = dialog_messasge("Something is wrong with "+filename+".")
          return, -1
        endelse
      endif
      ct += 1
    endif

    if not keyword_set(ephem) then begin
      if(strpos(s[n],'Solar Encounter Start') gt 0) then begin
        str = strsplit(s[n],' ', count=count,/extract)
        stime = [stime, time_string(time_double(str[0]+' '+str[1],tformat='MM-DD-YYYY hh:mm:ss'))]
      endif

      if(strpos(s[n],'Solar Encounter Stop') gt 0) then begin
        str = strsplit(s[n],' ', count=count,/extract)
        etime = [etime, time_string(time_double(str[0]+' '+str[1],tformat='MM-DD-YYYY hh:mm:ss'))]
      endif

    endif

  endfor

  stime = stime[1:*]
  etime = etime[1:*]
  label = label[1:*]
  mmax = n_elements(stime)
  orbSet = strarr(mmax)
  for m=0, mmax-1 do begin
    sdate = strmid(STIME[m],0,10)
    edate = strmid(ETIME[m],0,10)
    orbSet[m] = label[m]+': '+sdate+' - '+edate
  endfor

  orbHist = {stime:stime, etime:etime, label:label, count:ct, orbset:orbSet}
  return, orbHist
END