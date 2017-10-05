function mms_tai2unix, tinput

  tai_minus_unix = 378691200d0

  load_leap_table2, leaps, juls
  
  juls_tai = juls + leaps/double(86400)
  
  ; Convert tinput into juls:
  
  tinput_juls = tinput/double(86400) + julday(1, 1, 1958, 0, 0, 0)
  
  if n_elements(tinput) eq 1 then begin
    loc_greater = where(tinput_juls gt juls, count_greater)

    last_loc = loc_greater[count_greater-1]
    current_leap = leaps[last_loc]

    ;toutput_juls = tinput_juls(i) - current_leap/double(86400) + 9/double(86400)
    ;toutput_unix = double(86400)*(toutput_juls-julday(1, 1, 1970, 0, 0, 0))

    tinput_1970 = tinput - tai_minus_unix

    toutput = tinput_1970 - current_leap; + 9

  endif else begin
  
    toutput = dblarr(n_elements(tinput))
  
    for i = 0, n_elements(tinput)-1 do begin
      loc_greater = where(tinput_juls[i] gt juls, count_greater)
    
      last_loc = loc_greater[count_greater-1]
      current_leap = leaps[last_loc]
    
      ;toutput_juls = tinput_juls(i) - current_leap/double(86400) + 9/double(86400)
      ;toutput_unix = double(86400)*(toutput_juls-julday(1, 1, 1970, 0, 0, 0))
    
      tinput_1970 = tinput[i] - tai_minus_unix
    
      toutput[i] = tinput_1970 - current_leap; + 9
    
    endfor
  
  endelse
  
  return, toutput
  
end