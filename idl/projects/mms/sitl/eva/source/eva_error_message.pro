PRO eva_error_message, error_status, msg=msg
  
  help, /last_message, output=error_message; get error message
  vsn=float(strmid(!VERSION.RELEASE,0,3))
  if vsn ge 8.0 then begin
    r = terminal_size()
    r0 = r[0]
  endif else r0 = 5
  stra = strarr(r0) & stra[0:*] = '='
  strb = strarr(r0) & strb[0:*] = '-'
  format = '('+strtrim(string(r0),2)+'A)'
  
  print, stra,format=format
  
  ; message from IDL
  for jjjj=0,n_elements(error_message)-1 do begin
    print,error_message[jjjj]
  endfor
  
  ; message from EVA
  if n_elements(msg) ne 0 then begin
    print, 'EVA: '+msg
  endif
  print, 'EVA: error index: '+string(error_status)
  print, 'EVA: OS name:   '+!VERSION.OS_NAME
  print, 'EVA: IDL version: '+!VERSION.RELEASE
  print, stra, format=format
END
