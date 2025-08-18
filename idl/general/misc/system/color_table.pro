;+
;FUNCTION:   color_table
;PURPOSE:
;  Returns the current color table as a 256x3 array.
;
;USAGE:
;  ctab = color_table()
;
;INPUTS:
;       None.
;
;KEYWORDS:
;       None.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-05-16 16:31:53 -0700 (Tue, 16 May 2023) $
; $LastChangedRevision: 31865 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/color_table.pro $
;
;Created by David L. Mitchell (May 2023)
;-

function color_table

  COMMON colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

  return, [[r_curr],[g_curr],[b_curr]]

end
