;+
; PROCEDURE: PRINT_STR_MAXLET
;   print_str_maxlet, str, maxlet
;
; PURPOSE:
;   Print a string with the maximum number of letters in one line.
;
;   str : A string
;   maxlet : The maximum number of letters in one line.
;            The default value is 80.
;
; EXAMPLE:
;   gatt = cdf_var_atts(cdffilename)
;   print_str_maxlet, gatt.TEXT, 100
;
; Written by Y.-M. Tanaka, August 22, 2011 (ytanaka at nipr.ac.jp)
;-

;**********************************************************
;*** print_str_maxlet is used to show rules of the road ***
;**********************************************************
pro print_str_maxlet, str, maxlet

;----- Check input argument -----;
if ~keyword_set(maxlet) then maxlet=80
if size(str, /type) ne 7 then begin
  message,'STR must be of string type.', /info
  return
endif

;----- Print a string -----;
remstr=str
remstrlen=strlen(remstr)

while (remstrlen gt maxlet) do begin
  line1=strmid(remstr, 0, maxlet)

  ispace=strpos(line1, ' ')	; Check if space exists.
  if ispace lt 0 then begin
    line1=strmid(line1, 0, maxlet)
    remstr=strmid(remstr, maxlet, remstrlen-maxlet+1)
  endif else begin
    ;--- Find space ---;
    for ichar=0, maxlet-1 do begin
      char1=strmid(line1, maxlet-ichar-1, 1)
      if char1 eq ' ' then begin
        line1=strmid(line1, 0, maxlet-ichar-1)
        remstr=strmid(remstr, maxlet-ichar, remstrlen-maxlet+ichar+1)
        break
      endif
    endfor
  endelse

  print, line1
  remstrlen=strlen(remstr)
endwhile

print, remstr

end