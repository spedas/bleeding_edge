;+
;FUNCTION:   getct
;PURPOSE:
;  Returns the current color table and line color configuration.
;
;  To restore the user's color table and line color scheme:
;
;      c = getct()
;        ...
;      initct, c.color_table, reverse=c.color_reverse, file=c.ct_file, $
;              line=c.line_array
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-09-15 08:46:05 -0700 (Tue, 15 Sep 2026) $
; $LastChangedRevision: 34897 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/getct.pro $
;
;Created by David L. Mitchell (Sep 2026)
;-

function getct

  @colors_com

  ct = call_function('color_table')
  lc = call_function('get_line_colors')

  result = {ct_file           : ct_file           , $
            color_table       : color_table       , $
            color_reverse     : color_reverse     , $
            line_colors_index : line_colors_index , $
            top_c             : top_c             , $
            bottom_c          : bottom_c          , $
            color_array       : ct                , $
            line_array        : lc                   }

  return, result
  
end
