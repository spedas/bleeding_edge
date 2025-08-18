;+
;FUNCTION:    get_color_indx
;PURPOSE:   returns the color index value closest to the input rgb value.
;INPUT:    color:  3 x N array of rgb values:
;             [[r,g,b],[r,g,b],...]
;KEYWORDS:
;
; This stand-alone version split off from get_colors so that it can be
; called by other routines before compiling get_colors.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-07-29 17:32:53 -0700 (Fri, 29 Jul 2022) $
; $LastChangedRevision: 30977 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/get_color_indx.pro $
;
;Written by: Davin Larson    96-01-31
;-
function get_color_indx,color
  tvlct,r,g,b,/get
  vecs = replicate(1.,n_elements(r)) # reform(color)
  tbl = [[r],[g],[b]]
  d = sqrt( total((vecs-tbl)^2,2) )
  m = min(d,bin)
  return,byte(bin)
end
