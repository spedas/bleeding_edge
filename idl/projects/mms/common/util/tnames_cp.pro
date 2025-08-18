;+
; FUNCTION:
;     tnames_cp
;   
; PURPOSE:
;     Simple wrapper around the tnames() function that provides output that 
;     can be copy+pasted from the console to create new figures. 
;     
;     See the header of tnames for all input and keyword options
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-07-09 13:13:14 -0700 (Tue, 09 Jul 2019) $
; $LastChangedRevision: 27421 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/tnames_cp.pro $
;-

function tnames_cp, s, n, _extra=_extra
  noquotes = tnames(s, n, _extra=_extra)
  output = '['
  for var_idx=0, n_elements(noquotes)-1 do begin
    if var_idx ne 0 then output = output + ","
    output = output + "'" + noquotes[var_idx] + "'"
  endfor
  output = output + ']'
  return, output
end