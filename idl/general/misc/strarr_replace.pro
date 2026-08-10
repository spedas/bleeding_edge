;-
;FUNCTION:
;  arr =  strarr_replace(stringarray,pattern,replacement)
;PURPOSE:
;  Returns an array of strings with a pattern filled in
; with a "replacement" string.
;
;  This is a modern version of str_replace.pro that
; utilizes the new static method for IDL strings
; (https://www.nv5geospatialsoftware.com/docs/IDL_String.html#Replace).
;
; Example:
; > arr = ['{}_NOISE_SIGMA', '{}_NOISE_BASELINE']
; > filled_arr = strarr_replace(arr, '{}', 'swfo_stis_l1a')
; > print, filled_arr
;   ['swfo_stis_l1a_NOISE_SIGMA', 'swfo_stis_l1a_NOISE_BASELINE']
;
;+
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2026-08-05 18:04:57 -0700 (Wed, 05 Aug 2026) $
; $LastChangedRevision: 34706 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/strarr_replace.pro $
;-

function strarr_replace, arr, pattern, replacement
  n_arr = n_elements(arr)
  new_arr = strarr(n_arr)
  for i=0, n_arr - 1 do begin
    arr_i = arr[i]
    new_arr[i] = arr_i.replace(pattern, replacement)
  endfor
  return, new_arr
end
