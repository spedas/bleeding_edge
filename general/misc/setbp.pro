;+
;PROCEDURE:  setbp, module
;    This procedure will set BREAKPOINTS at all lines within a program module
;    file that contain the string:  ";bp"
;    A conditional break point is set with  ;bpif  condition statement
;
;Input:  module (string)
;Purpose:   This is a DEBUGGING tool that is used to set breakpoints.
;Keywords:
;    /FUNCTION  Set this keyword if module is a function.
;
; Author:  Davin Larson 2007
;-

pro setbp,module,thisfile=thisfile,functions=functions,bpstring=bpstring

if keyword_set(thisfile) then begin
   file_s = scope_traceback(/struct)
   n = n_elements(file_s)-2
   file = file_s[n].filename
endif else begin
   file_s = routine_info(module,/source,functions=functions)
   file= file_s.path
endelse
openr,unit,file,/get_lun
s=''
line=1

if not keyword_set(bpstring) then bpstring = ';bp'

while not eof(unit) do begin
   readf,unit,s
   pos = strpos(s,bpstring)
   if pos ge 0 then begin
      ifpos = strpos(s,'if',pos)
      condition = ifpos eq pos+3 ? strmid(s,ifpos+3) : 0
      if keyword_set(condition) then breakpoint,file,line, condition = condition  $
      else breakpoint,file,line
      print,line,'  ',s
   endif
   line++
endwhile
free_lun,unit

end