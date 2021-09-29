;
; Obtain Maximum length of vectors in selected time
;
function stel3d_get_max_vector, olep, timeKeys, VEL=vel

  length = -1
  cnt = 0L
  
  foreach elem, timeKeys do begin
    vect = olep.getVector(elem, VEL=vel)
    tmplength = (vect[0])^2 + (vect[1])^2 + (vect[2])^2
    ;print, tmplength
    if tmplength gt length then begin
      length = tmplength
      index = cnt
    endif
    cnt ++
  endforeach

  if length eq -1 then begin
    message, 'result is negative and could be invalid'
    return, !null
  endif
  
;  print, 'Final: ', length
;  print, 'Index: ', index
  return, olep.getVector(timekeys[index], VEL=vel)

end
;
; for test
;
pro test_stel3d_get_max_absolute_index

 infile = file_which('19971212_lep_psd_8532.txt')
 olep = stel_import_lep()
 res = olep.read_lep(infile, DATA=data, TRANGE=['1997-12-12/13:47:00', '1997-12-12/13:51:00'])
 timeKeys = olep.getTimeKeys()
 print, stel3d_get_max_vector(olep, timeKeys)

end