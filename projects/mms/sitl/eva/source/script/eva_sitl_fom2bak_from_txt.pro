FUNCTION eva_sitl_fom2bak_from_txt, fname
  compile_opt idl2
  
  ;---------------------
  ; RESTORE (from .txt)
  ;---------------------
  
  ; read one line at a time, saving the result into array
  openr, lun, fname, /get_lun
  array = ''
  line = ''
  while not eof(lun) do begin
    readf, lun, line
    array = [array, line]
  endwhile
  free_lun, lun
  idx=where(strmatch(array,'*START TIME*'),ct)
  if ct eq 0 then return,-1
  
  n0 = idx[0]
  nmax = n_elements(array)
  for n=0,nmax-1 do begin
    
  endfor
  stop
  return, unix_fomstr
END
