PRO sppeva_sitl_csv2tplot, filename, var=var, status=status, suffix=suffix
  compile_opt idl2
  
  ;----------------
  ; INITIALIZE
  ;----------------
  status = 0
  if undefined(filename) then begin
    filename = dialog_pickfile(FILTER='*.csv')
    if strlen(filename) eq 0 then begin
      status = 1
      return
    endif
  endif
  if undefined(var) then begin
    if strmatch(strlowcase(filename),'*_fld_*') then begin
      expected_mode = 'FLD'
    endif else begin
      expected_mode = 'SWP'
    endelse
    if not strmatch(expected_mode, !SPPEVA.COM.MODE) then begin
      msg = ['The specified input file is for '+expected_mode+' ']
      msg = [msg, 'whereas EVA is currently in '+!SPPEVA.COM.MODE+' mode. ']
      msg = [msg, 'Please switch the EVA mode or specify the correct']
      msg = [msg, 'file to restore.']
      answer = dialog_message(msg,/center)
      status = 2
      return 
    endif
    var = strlowcase('spp_'+expected_mode+'_fomstr')
  endif

  ;----------------
  ; READ CSV
  ;---------------- 
  result = read_csv(filename, COUNT=Nsegs, HEADER=header, N_TABLE_HEADER=6, $
    NUM_RECORDS=nmax, TABLE_HEADER=table_header)
  if Nsegs eq 0 then begin
    print, "No data found in ", file, "; Returning"
    status = 3
    return
  endif
  
  
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
    DISCUSSION: result.FIELD7, $
    TABLE_HEADER: table_header}
  
  ;----------------
  ; TPLOT VARIABLE
  ;----------------
  if undefined(suffix) then suffix = ''
  
  SPPEVA_SITL_STRCT2TPLOT, s, var+suffix
  status = 4
END
