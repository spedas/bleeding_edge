PRO sppeva_sitl_csv2tplot_multi, files, status=status, suffix=suffix
  compile_opt idl2
  
  ;-----------------
  ; INITIALIZE
  ;-----------------
  status = 0
  nmax = n_elements(files)
  for n=0,nmax-1 do begin
    if strmatch(strlowcase(files[n]),'*_fld_*') then begin
      expected_mode = 'FLD'
    endif else begin
      expected_mode = 'SWP'
    endelse
    if not strmatch(expected_mode, !SPPEVA.COM.MODE) then begin
      msg = ['One of the specified input file is for '+expected_mode+' ']
      msg = [msg, 'whereas EVA is currently in '+!SPPEVA.COM.MODE+' mode. ']
      msg = [msg, 'Please switch the EVA mode or specify the correct']
      msg = [msg, 'file to restore.']
      answer = dialog_message(msg,/center)
      status = 2
      return
    endif
    var = strlowcase('spp_'+expected_mode+'_fomstr')
  endfor
  
  ;---------------------
  ; READ THE FIRST CSV
  ;---------------------
  
  Nsegs = 0
  n = 0
  while (Nsegs eq 0) and (n lt nmax) do begin
    result0 = read_csv(files[n], COUNT=Nsegs, HEADER=header, N_TABLE_HEADER=6, $
      NUM_RECORDS=nmax, TABLE_HEADER=table_header)
    n += 1
  endwhile
  
  if (n eq nmax) then begin
    print, "No data found in the selected files; Returning"
    status = 3
    return
  endif else nmin = n 

  str_element,/add,result0,'FIELD6',result0.FIELD4+':'+result0.FIELD6
  
  ;----------------------------
  ; READ THE REST OF THE FILES
  ;----------------------------
  for n=nmin,nmax-1 do begin
    result = read_csv(files[n], COUNT=Nsegs, HEADER=header, N_TABLE_HEADER=6, $
      NUM_RECORDS=nmax, TABLE_HEADER=table_header)
    if Nsegs gt 0 then begin
      str_element,/add,result0,'FIELD1', [result0.FIELD1, result.FIELD1]
      str_element,/add,result0,'FIELD2', [result0.FIELD2, result.FIELD2]
      str_element,/add,result0,'FIELD3', [result0.FIELD3, result.FIELD3]
      str_element,/add,result0,'FIELD4', [result0.FIELD4, result.FIELD4]
      str_element,/add,result0,'FIELD5', [result0.FIELD5, result.FIELD5]
      str_element,/add,result0,'FIELD6', [result0.FIELD6, result.FIELD4+':'+result.FIELD6]
    endif
  endfor
  
  result = result0
  Nsegs = n_elements(result.FIELD1)
  
  ;----------------
  ; STRUCTURE
  ;----------------
  s = {$
    Nsegs:Nsegs, $
    START:time_double(result.FIELD1), $
    STOP: time_double(result.FIELD2), $
    FOM: float(result.FIELD3), $
    SOURCEID: result.FIELD4, $
    BLOCKSTART: result.FIELD5, $
    BLOCKLEN: result.FIELD6, $
    DISCUSSION: result.FIELD7}

  ;----------------
  ; TPLOT VARIABLE
  ;----------------
  if undefined(suffix) then suffix = ''

  sppeva_sitl_strct2tplot, s, var+suffix
  
  status = 4
END
