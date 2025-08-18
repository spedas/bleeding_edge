;+
;FUNCTION:   get_qualcolors
;PURPOSE:
;  Returns a copy of the qualcolors structure.
;
;USAGE:
;  qualcolors = get_qualcolors()
;
;INPUTS:
;       none
;
;KEYWORDS:
;       none
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-07-27 13:38:31 -0700 (Wed, 27 Jul 2022) $
; $LastChangedRevision: 30971 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/CSV_Color_Tables/get_qualcolors.pro $
;-
function get_qualcolors
  @colors_com
  common qualcolors_com, qualcolors

  if (size(qualcolors,/type) ne 8) then loadcsv,0,/reset

  qualcolors.color_table = n_elements(color_table) ? color_table : -1
  qualcolors.color_reverse = n_elements(color_reverse) ? color_reverse : 0
  if (qualcolors.color_table lt 1000) then qualcolors.table_name = ''

  return, qualcolors
end
