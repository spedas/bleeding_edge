PRO mms_bss_quick
  compile_opt idl2
  mms_init
  
  bss= get_mms_burst_segment_status(/is_pending)
  
  nmax = n_elements(bss)
  bfr = 0L
  for n=0,nmax-1 do begin
    if bss[n].ISPENDING eq 1 then begin
      bfr += (bss[n].TAIENDTIME-bss[n].TAISTARTTIME)
    endif
  endfor
  print, 'Currenty...'
  print, 'total number of HELD segments = ', nmax
  print, 'total number of HELD buffers = ', bfr/10L
  print, 'total time of HELD data =',double(bfr/60L/60L),' [hrs]'
  
END
