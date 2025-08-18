;+
; NAME:
;   jbt_date2jday (function)
;
; PURPOSE:
;   Convert a date string in format 'yyyy-mm-dd', such as '2012-10-16', into a
;   longword integer Julian day number.
;
; CATEGORIES:
;   Utilities
;
; CALLING SEQUENCE:
;   result = jbt_date2jday(date)
;
; ARGUMENTS:
;   date: (In, required) A date string in format 'yyyy-mm-dd', such as
;         '2012-10-16'.
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
;   2012-11-02: Initial release to TDAS. JBT, SSL/UCB.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-11-02 16:35:10 -0700 (Fri, 02 Nov 2012) $
; $LastChangedRevision: 11172 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/jbt_date2jday.pro $
;
;-

function jbt_date2jday, date
  ; date must be in format 'yyyy-mm-dd', such as '2012-10-16'

compile_opt idl2

year = long(strmid(date, 0, 4))
mm =  long(strmid(date, 5, 2))
dd = long(strmid(date, 8, 2))

return, julday(mm, dd, year)

end
