;+
;Checks for non-monotonic FGM cal. entries, and prints messages if the
;file has a problem.
;No messages = file is ok
;-
Pro thm_test_fgmcal, file_in, probe = probe

  ncal=file_lines(file_in)
  calstr=strarr(ncal)
  openr, 2, file_in
  readf, 2, calstr
  close, 2
  ok_cal = where(calstr Ne '', ncal) ;jmm, 8-nov-2007, cal files have carriage returns at the end
  calstr = calstr[ok_cal]
;define variables
  spinperi=dblarr(ncal)
  offi=dblarr(ncal,3)
  cali=dblarr(ncal,9)
  utci='2006-01-01T00:00:00.000Z'
  utc=dblarr(ncal)
  utcStr=strarr(ncal)
  bz_slope_intercept = dblarr(ncal, 2)
  for i=0,ncal-1 DO BEGIN
     split_result = strsplit(calstr[i], COUNT=lct, /EXTRACT)
     if probe eq 'e' then begin
        if lct ne 16 then begin
           msg = 'Error in FGM cal file. Line: ' + string(i) + ", File: " + file_in
           dprint, dlevel=1, msg
           continue
        endif
        bz_slope_intercept[i,*] = split_result[14:15]
     endif else begin
        if lct ne 14 then begin
           msg = 'Error in FGM cal file. Line: ' + string(i) + ", File: " + file_in
           dprint, dlevel=1, msg
           continue
        endif
     endelse
     utci=split_result[0]
     offi[i,*]=split_result[1:3]
     cali[i,*]=split_result[4:12]
     spinperi[i]=split_result[13]
     utcStr[i]=utci
    ;translate time information
     STRPUT, utci, '/', 10
     utc[i]=time_double(utci)
  ENDFOR
  dt = utc[1:*]-utc
  oops = where(dt Le 0.0, noops)
  If(noops Gt 0) Then Begin
     For j = 0L,noops-1 Do Begin
        print, 'Bad_times: index ', oops[j]
        print, time_string(utc[oops[j]])
        print, time_string(utc[oops[j]+1])
     Endfor
  Endif

  Return
End
