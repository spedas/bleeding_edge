function mms_unix2tai_fixed, tinput

  tai_minus_unix = 378691200d0

  load_leap_table2, leaps, juls

  jd1958 = julday(1, 1, 1958, 0, 0, 0)

  if n_elements(tinput) eq 1 then begin

    tinput_1958 = double(tinput) + tai_minus_unix
    tai_guess = tinput_1958

    ; Leap-second lookup must be performed in TAI time coordinates.
    ; Since the input is a Unix timestamp, iteratively solve:
    ;
    ;   TAI = Unix + tai_minus_unix + leap(TAI)
    ;
    ; where leap(TAI) is obtained from the MMS TAI-based leap table.
    ; This guarantees that mms_unix2tai() and mms_tai2unix() are exact
    ; inverses across leap-second boundaries.
    ;
    ; The iteration usually converges in 1-2 rounds but we'll use 10 just to be conservtive
    
    for iter = 0, 10 do begin

      tai_juls = tai_guess/double(86400) + jd1958

      loc_greater = where(tai_juls gt juls, count_greater)

      if count_greater gt 0 then begin
        current_leap = double(leaps[loc_greater[count_greater-1]])
      endif else begin
        current_leap = 0d0
      endelse

      tai_new = tinput_1958 + current_leap

      if tai_new eq tai_guess then break

      tai_guess = tai_new

    endfor

    toutput = tai_guess

  endif else begin

    toutput = dblarr(n_elements(tinput))

    for i = 0, n_elements(tinput)-1 do begin

      tinput_1958 = double(tinput[i]) + tai_minus_unix
      tai_guess = tinput_1958

      ; Leap-second lookup must be performed in TAI time coordinates.
      ; Since the input is a Unix timestamp, iteratively solve:
      ;
      ;   TAI = Unix + tai_minus_unix + leap(TAI)
      ;
      ; where leap(TAI) is obtained from the MMS TAI-based leap table.
      ; This guarantees that mms_unix2tai() and mms_tai2unix() are exact
      ; inverses across leap-second boundaries.
      ;
      ; The iteration usually converges in 1-2 rounds but we'll use 10 just to be conservtive

      for iter = 0, 10 do begin

        tai_juls = tai_guess/double(86400) + jd1958

        loc_greater = where(tai_juls gt juls, count_greater)

        if count_greater gt 0 then begin
          current_leap = double(leaps[loc_greater[count_greater-1]])
        endif else begin
          current_leap = 0d0
        endelse

        tai_new = tinput_1958 + current_leap

        if tai_new eq tai_guess then break

        tai_guess = tai_new

      endfor

      toutput[i] = tai_guess

    endfor

  endelse

  return, toutput

end