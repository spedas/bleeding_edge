;+
; NAME:
;   jbt_jday2date (function)
;
; PURPOSE:
;   Convert a longword integer Julian day number into a date string in format
;   'yyyy-mm-dd', such as '2012-10-16'.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   result = jbt_jday2date(jday)
;
; ARGUMENTS:
;   jday: (In, required) A longword integer Julian day number.
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
;   2012-11-02: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-02: Initial release to TDAS.
;
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-11-02 16:35:10 -0700 (Fri, 02 Nov 2012) $
; $LastChangedRevision: 11172 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/jbt_jday2date.pro $
;
;-

function jbt_jday2date, jday

compile_opt idl2

caldat, jday, month, day, year

date = string(year, form='(I0)') + '-' + string(month, form='(I02)') + $
  '-' + string(day, form='(I02)')

return, date
end
