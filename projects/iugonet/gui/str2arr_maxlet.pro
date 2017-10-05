;+
; PROCEDURE: STR2ARR_MAXLET
;   str2arr_maxlet, str, maxlet, str_arr
;
; PURPOSE:
;   Divide a long string and insert it to a string array.
;   str : string or string array
;   maxlet : The maximum number of letters in one line.
;            The default value is 80.
;   strarr : output string array
;
; EXAMPLE:
;   gatt = cdf_var_atts(cdffilename)
;   print_str_maxlet, gatt.TEXT, 100
;
; Written by Y.-M. Tanaka, April 27, 2012 (ytanaka at nipr.ac.jp)
;-

function str2arr_maxlet, str, maxlet=maxlet

;----- Check input argument -----;
if ~keyword_set(maxlet) then maxlet=80
if size(str, /type) ne 7 then begin
  message,'STR must be of string type.', /info
  return, 0
endif

;----- Divide a string and insert it to a string array -----;
str_arr=strarr(300)

ndim=size(str, /n_dimensions)
if ndim eq 0 then begin
  nele=1
endif else if ndim eq 1 then begin
  nele=size(str, /n_elements)
endif else begin
  message,'The array dimension is not supported.', /info
  return, 0
endelse

iline=0
for iarr=0, nele-1 do begin
  remstr=str[iarr]
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

    str_arr(iline)=line1
    iline++
    remstrlen=strlen(remstr)
  endwhile

  str_arr(iline)=remstr
  iline++
endfor

str_arr=str_arr(0:iline-1)

return, str_arr

end
