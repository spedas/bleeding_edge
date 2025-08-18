;+
; NAME:
;   tplot_time_to_epoch (function)
;
; PURPOSE:
;   Convert tplot time stamps into CDF epoch.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   result = tplot_time_to_epoch(, tarr, epoch16 = epoch16)
;
; ARGUMENTS:
;
; KEYWORDS:
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2013-03-19: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2013-03-27 14:23:02 -0700 (Wed, 27 Mar 2013) $
; $LastChangedRevision: 11915 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/tplot_time_to_epoch.pro $
;
;-

function tplot_time_to_epoch, tarr, epoch16 = epoch16

compile_opt idl2

; tarr = time_double(date) + dindgen(10) + randomn(seed, 10, /double)

tstr = time_string(tarr, prec = 12)
; print, tstr

year = long(strmid(tstr, 0, 4))
; print, tstr
; print, year

month = long(strmid(tstr, 5, 2))
; print, tstr
; print, month

day = long(strmid(tstr, 8, 2))
; print, tstr
; print, day

hour = long(strmid(tstr, 11, 2))
; print, tstr
; print, hour

minute = long(strmid(tstr, 14, 2))
; print, tstr
; print, minute

second = long(strmid(tstr, 17, 2))
; print, tstr
; print, second

milli = long(strmid(tstr, 20, 3))
if keyword_set(epoch16) then begin
  micro = long(strmid(tstr, 23, 3))
  nano  = long(strmid(tstr, 26, 3))
  pico  = long(strmid(tstr, 29, 3))
  cdf_epoch16, epoch, year, month, day, hour, minute, second, milli, micro, $
    nano, pico, /compute_epoch
endif else begin
  cdf_epoch, epoch, year, month, day, hour, minute, second, milli, $
    /compute_epoch
endelse

return, epoch

end

