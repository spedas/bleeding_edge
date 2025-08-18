; this function is simply a shortcut in producing the string version
; of floating-point number rounded to the nearest integer.

Function roundst, x, decimal_places = decimal_places, $
                  whitespace = whitespace
  if not keyword_set (decimal_places) then return, $
    strcompress (string (round (x)),/rem)
  
  If decimal_places lt 0 then begin
      format_string = '(F15.'+ roundst (-decimal_places) +')'
      if keyword_set(whitespace) then return,  $
         strcompress (string (round_decimal (X, decimal_places), $
                              format = format_string)) else return,  $
         strcompress (string (round_decimal (X, decimal_places), $
                              format = format_string), /rem)
  Endif else begin
     if keyword_set(whitespace) then return, $
        strcompress (string (round_decimal (X, decimal_places))) else return, $
        strcompress (string (round_decimal (X, decimal_places)))
  endelse
end
