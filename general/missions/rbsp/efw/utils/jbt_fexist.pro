;+
; NAME:
;   jbt_fexist (function)
;
; CATEGORY:
;
; PURPOSE:
;   Check the existence of a local file. Return 1 if the file exists, or 0 if
;   not.
;
; CALLING SEQUENCE:
;   result = jbt_fexist(file)
;
; ARGUMENTS:
;   file: (In, required) A string of a local file to be checked.
;
; KEYWORDS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2011-05-01: Created by Jianbao Tao (JBT), CU/LASP.
;   2012-11-02: Initial release to TDAS. JBT, SSL/UCB.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-11-02 16:35:10 -0700 (Fri, 02 Nov 2012) $
; $LastChangedRevision: 11172 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/jbt_fexist.pro $
;
;-

function jbt_fexist, file

  info = file_info(file)

  return, info.exists

end

