;+
;Procedure: num_to_str_pad
;                
;Purpose:
;  This is a very basic operation that gets repeated a lot in date file output.
;  This takes a number as input and pads zeros on the front so that the number outputs
;  at fixed field width.
;  
;Inputs:
;  val:  The number to be converted
;  len: The final length requested
;  
;Keywords:
;  pad:  Select a character other than '0' with which to pad
;  integral: Normally, if val is a floating point type, if will add a .00, If this keyword is set, forces no decimal points.
;  
;Notes:
;  1. For a while I resisted putting this in the distribution as it seemed too specific an operation,
;  but at the point when I was considering implementing this routine for a 4th time in a separate
;  namespace, I just decided to go ahead and add this instead.
;  
;  2. There is no error checking to determine if the input is wider than 'len'
;  
;  3. Currently floating point inputs will produce unreliable results.
;
;Example:
;
;  date_str = num_to_str_pad(year,4)+num_to_str_pad(mon,2)+num_to_str_pad(day,2)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-10-19 15:27:17 -0700 (Wed, 19 Oct 2016) $
; $LastChangedRevision: 22151 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/num_to_str_pad.pro $
;-
function num_to_str_pad,val,len,pad=pad,integral=integral

  compile_opt idl2,hidden

  if ~keyword_set(pad) then begin
    pad = '0'
  endif

  if keyword_set(integral) then begin
    str = strtrim(string(val,format='(I'+strtrim(max([len,ceil(alog10(val))]),2)+')'),2)
  endif else begin
    str = strtrim(val,2)
  endelse

  vlen = strlen(str)
  
  if vlen lt len then begin
    return,strjoin([replicate(pad,len-vlen),str])
  endif else begin
    return,str
  endelse

end