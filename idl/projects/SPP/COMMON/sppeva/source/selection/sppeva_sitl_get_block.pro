FUNCTION sppeva_sitl_get_block, START, STOP, quiet=quiet
  compile_opt idl2
  
  if strmatch(!SPPEVA.COM.MODE,'FLD') then begin
    tnptr = !SPPEVA.COM.FIELDPTR
  endif else begin
    tnptr = !SPPEVA.COM.SWEAPPTR
  endelse
  
  ; PTR
  tn=tnames(tnptr,ct)
  error=0L
  msg = ''
  if ct eq 1 then begin
    get_data,tnptr,data=DD
    
    ;--------------------
    ; PTR START
    ;--------------------
    result = min(DD.x-START,min_subscript,/abs)
    ptr_start = DD.y[min_subscript]
    if DD.x[min_subscript] gt START then ptr_start -= 1
    
    ;--------------------
    ; PTR START
    ;--------------------
    result = min(DD.x-STOP,min_subscript,/abs)
    ptr_stop = DD.y[min_subscript]
    if DD.x[min_subscript] lt STOP then ptr_stop += 1
    
    ;--------------------------------
    ; Detect a JUMP
    ;--------------------------------
    drv = abs(deriv(DD.x,DD.y))
    idx = where((drv gt 1.) and (START le DD.x) and (DD.x le STOP),ct)
    if(ct gt 0) then begin
      error=1L
      msg = 'There is a segment that crosses the time when'
      msg = [msg,'the pointer jumped back. Please make an adjustment.']
      msg = [msg,'The jump may be at '+time_string(DD.x[idx[0]])]
      print, ''
      print, msg
      print, ''
      print, 'A list of all jumps :'
      print, time_string(DD.x[idx])
    endif
    
    length = ptr_stop-ptr_start+1L
  endif else begin
    error=1L
    msg = tnptr+' not found (sppeva_sitl_get_block)'
    ptr_start=0L
    ptr_stop=0L
    length=0L
  endelse
  PTR = {start:ptr_start, stop: ptr_stop, length:length, error:error}

  if (error gt 0) and ~keyword_set(quiet) then begin
    result = dialog_message(msg,/center)
  endif
  return, PTR
END