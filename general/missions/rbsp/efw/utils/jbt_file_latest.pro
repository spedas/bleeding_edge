;+
; NAME:
;   jbt_file_latest (function)
;
; PURPOSE:
;   Return the path of the latest file within a folder.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   result = jbt_file_latest(dir)
;
; ARGUMENTS:
;   dir: (In, required) A string of a local directory.
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
;   2012-10-28: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-02: Initial release to TDAS. JBT, SSL/UCB.
;
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-11-02 16:35:10 -0700 (Fri, 02 Nov 2012) $
; $LastChangedRevision: 11172 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/jbt_file_latest.pro $
;
;-

function jbt_file_latest, dir

compile_opt idl2

flist = file_search(dir, '*')

nfile = n_elements(flist)
mtimes = fltarr(nfile)

inew = 0

for i = 0L, nfile - 1 do begin
  info = file_info(flist[i])
  mtimes[i] = info.mtime
endfor

dum = max(mtimes, imax)

return, flist[imax]

end

