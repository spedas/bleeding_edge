;+
;PROCEDURE line_colors
;   Alters one or more of the fixed colors (indices 0-6 and 255) without changing
;   the color table.  This includes the line colors (1-6) and the background (0) 
;   and foreground (255) colors.
;
;USAGE:
;  line_colors [, line_clrs] [, KEYWORD=value, ...]
;
;INPUTS:
;   line_clrs : Can take one of two forms:
;
;   (1) Integer array of 24 (3x8) RGB values: [[R,G,B], [R,G,B], ...] that defines
;       the first 7 colors (0-6) and the last (255).
;
;   (2) Integer that selects a predefined color scheme:
;
;           0  : primary and secondary colors [black, magenta, blue, cyan, green, yellow, red, white]
;          1-4 : four different schemes suitable for colorblind vision
;           5  : same as 0, except orange replaces yellow for better contrast on white
;           6  : same as 0, except gray replaces yellow for better contrast on white
;           7  : see https://www.nature.com/articles/nmeth.1618, except no reddish purple
;           8  : see https://www.nature.com/articles/nmeth.1618, except no yellow
;           9  : same as 8 but permuted so vector defaults are blue, orange, reddish purple
;          10  : Chaffin's CSV line colors, suitable for colorblind vision
;          11  : same as 5, except a darker green for better contrast on white
;
;    If not specified, use the current (or default) line color scheme and use keywords to
;    make modifications.
;
;KEYWORDS:
;    COLOR_NAMES:  String array of 8 line color names.  You must use line color
;                  names recognized by spd_get_color().  RGB values for unrecognized
;                  color names are set to zero.  Not recommended, because named 
;                  colors are approximated by the nearest RGB neighbors in the 
;                  currently loaded color table.  This can work OK for rainbow color
;                  tables, but for tables that primarily encode intensity, the 
;                  actual colors can be quite different from the requested ones.
;                  Included for backward compatibility.
;
;    MYCOLORS:     A structure defining up to 8 custom colors.  These are fixed
;                  colors used to draw colored lines (1-6) and to define the
;                  background (0) and foreground (255) colors.
;
;                     { ind    : up to 8 integers (0-6 or 255)              , $
;                       rgb    : up to 8 RGB levels [[R,G,B], [R,G,B], ...]    }
;
;                  The indicies (ind) specified in MYCOLORS will replace one or
;                  more of the default colors.  You are not allowed to change
;                  color indices 7-254, because those are reserved for the
;                  color table.  Indices 0 and 255 allow you to define custom
;                  background and foreground colors.  For example, the following
;                  chooses color scheme 5, but sets the background color to light
;                  gray with a black foreground (pen) color:
;
;                     line_colors, 5, mycolors={ind:255, rgb:[211,211,211]}
;                     !p.color = 0
;                     !p.background = 255
;
;    GRAYBKG:      Set color index 255 to gray [211,211,211] instead of white.
;                  See keyword MYCOLORS for a general method of setting any line 
;                  color to any RGB value.  For example, GRAYBKG=1 is equivalent 
;                  to MYCOLORS={ind:255, rgb:[211,211,211]}.
;
;                  To actually use this color for the background, you must set 
;                  !p.background=255 (normally combined with !p.color=0).
;
;    PREVIOUS_LINES: Named variable to hold the previous line colors.
;                  Tplot needs this to swap line colors on the fly.
;
;       SUCCESS:   Returns 1 if the routine finishes normally, 0 otherwise.
;
;SEE ALSO:
;    get_line_colors() : Works like this routine, but returns a 24 element array
;                  instead of asserting the new line colors.  Allows you to define
;                  a custom set of line colors in a format that you can use as an
;                  option for a tplot variable.
;    initct :      Loads a color table without changing the line colors, except by
;                  keyword.
;
;common blocks:
;   colors:      IDL color common block.  Many IDL routines rely on this.
;   colors_com:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-01-28 08:52:54 -0800 (Tue, 28 Jan 2025) $
; $LastChangedRevision: 33098 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/line_colors.pro $
;
;Created by David Mitchell;  February 2023
;-

pro line_colors, line_clrs, color_names=color_names, mycolors=mycolors, graybkg=graybkg, $
                        previous_lines=previous_lines, success=ok

  common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
  @colors_com

  ok = 0
  tvlct,r,g,b,/get

  previous_lines = get_line_colors()
  nmax = n_elements(line_colors_presets[0,0,*]) - 1

  case n_elements(line_clrs) of
       0 : ; do nothing and allow color_names, mycolors, and/or graybkg to take effect
       1 : begin
             if ((line_clrs lt 0) or (line_clrs gt nmax)) then begin
               print,"  Line color scheme undefined: ", strtrim(string(line_clrs),2)
               print,""
               return
             endif
           end
      24 : begin
             delta = abs((size(line_clrs))[0:2] - [2,3,8])
             if (total(delta) ne 0) then begin
               print,"  Line color array must have dimensions of 3x8."
               print,""
               return
             endif
           end
    else : begin
             print,"  You must supply a 3x8 array of RGB values or a scheme number."
             print,""
             return
           end
  endcase
  
  new_lines = get_line_colors(line_clrs, color_names=color_names, mycolors=mycolors, graybkg=graybkg)
  line_colors_common = new_lines

  cols = [indgen(7), 255]
  r[cols] = new_lines[0,*]
  g[cols] = new_lines[1,*]
  b[cols] = new_lines[2,*]

  tvlct,r,g,b

  r_curr = r  ; Important!  Update the colors common block.
  g_curr = g
  b_curr = b

  ok = 1

end
