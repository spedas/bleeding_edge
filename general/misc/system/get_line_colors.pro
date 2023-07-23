;+
;FUNCTION get_line_colors
;   Get the current line colors, or line colors specified by input and/or keyword.
;   Returns the result as an array of 24 (3x8) RGB colors: [[R,G,B], [R,G,B], ...].
;   This DOES NOT alter the color table or assert any new line colors.  To do that
;   you would pass the result of this routine to line_colors, initct, or as an
;   option for a tplot variable.
;
;   To set custom line colors for any tplot panel do one of the following:
;
;       lines = n  ; where 0 <= n <= 10
;       options, varname, 'line_colors', lines
;
;       lines = get_line_colors(line_clrs, KEYWORD=value, ...)
;       options, varname, 'line_colors', lines
;
;   To disable custom line colors for a tplot variable:
;
;       options, varname, 'line_colors', -1
;
;USAGE:
;   mycolors = get_line_colors([line_clrs] [, KEYWORD=value, ...])
;
;INPUTS:
;   line_clrs : This input is optional.  Can take one of two forms:
;
;   (1) Integer array of 24 (3x8) RGB values: [[R,G,B], [R,G,B], ...] that defines the
;       first 7 colors (0-6) and the last (255).  Tplot assumes the following:
;
;         Index           Purpose
;        --------------------------------------------------
;           0             black (or any dark color)
;          1-6            fixed line colors
;          7-254          color table (bottom_c to top_c)
;          255            white (or any light color)
;        --------------------------------------------------
;
;       Indices 0 and 255 are associated with !p.background and !p.color.  For a light
;       background, set !p.background = 255 and !p.color = 0.  Do the opposite for a
;       dark background.  Use revvid to toggle between these options.
;
;   (2) Integer that selects one of the predefined color schemes:
;
;           0  : primary and secondary colors [black, magenta, blue, cyan, green, yellow, red, white]
;          1-4 : four different schemes suitable for colorblind vision
;           5  : same as 0, except orange replaces yellow for better contrast on white
;           6  : same as 0, except gray replaces yellow for better contrast on white
;           7  : see https://www.nature.com/articles/nmeth.1618 except no reddish purple
;           8  : see https://www.nature.com/articles/nmeth.1618 except no yellow
;           9  : same as 8 but permuted so vector defaults are blue, orange, reddish purple
;          10  : Chaffin's CSV line colors, suitable for colorblind vision
;
;   If there is no input and no keywords are set, this routine returns the current
;   line colors.
;
;KEYWORDS:
;   COLOR_NAMES: String array of 8 line color names.  You must use line color names 
;       recognized by spd_get_color().  RGB values for unrecognized color names are 
;       set to zero.  Note that named colors are approximated by the nearest RGB 
;       neighbors in the currently loaded color table.  This can work OK for rainbow
;       color tables, but for tables that primarily encode intensity, the actual 
;       colors can be quite different from the requested ones.
;
;   MYCOLORS: A structure defining up to 8 custom colors.  This provides an alternate 
;       method of poking individual custom colors into color indices 0-6 and 255.
;
;              { ind    : up to 8 integers (0-6 or 255)              , $
;                rgb    : up to 8 RGB levels [[R,G,B], [R,G,B], ...]    }
;
;       The indicies (ind) specified in this structure will replace one or more of the
;       current line colors.  You are not allowed to change color indices 7-254, because
;       those are reserved for the color table.  Indices 0 and 255 allow you to define 
;       custom background and foreground colors.
;
;   GRAYBKG: Set color index 255 to gray [211,211,211] instead of white.  See keyword
;       MYCOLORS for a general method of setting any line color to any RGB value.
;       For example, GRAYBKG=1 is equivalent to MYCOLORS={ind:255, rgb:[211,211,211]}.
;
;       To actually use this color for the background, you must set !p.background=255
;       (normally combined with !p.color=0).
;
;common blocks:
;   colors:      IDL color common block.  Many IDL routines rely on this.
;   colors_com:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-03-05 09:48:09 -0800 (Sun, 05 Mar 2023) $
; $LastChangedRevision: 31581 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/get_line_colors.pro $
;
;Created by David Mitchell;  February 2023
;-

function get_line_colors, line_clrs, color_names=color_names, mycolors=mycolors, graybkg=graybkg

  @colors_com

; Initialize with the current or default line colors

  default = fix([[0,0,0],[255,0,255],[0,0,255],[0,255,255],[0,255,0],[255,255,0],[255,0,0],[255,255,255]])
  if (n_elements(line_colors_common) eq 24) then default = line_colors_common

; Three methods for setting the fixed line colors (0-6 and 255)

; Method 1: Line and background colors by name

  if keyword_set(color_names) then begin
    if ((n_elements(color_names) ne 8) or (size(color_names,/type) ne 7)) then begin
      dprint, 'line_color_names must be an 8-element string array'
      return, 0
    endif
    line_clrs = transpose(spd_get_color(color_names,/rgb))
    ; then fall through to the line_clrs processing
  endif

; Method 2: Line and background colors by array (presets or entirely custom)

  if n_elements(line_clrs) gt 0 then begin
    if n_elements(line_clrs) ne 24 then begin
      case fix(line_clrs[0]) of
        ; Preset 0:  Primary and secondary colors [black, magenta, blue, cyan, green, yellow, red, white]
        0: line_clrs = [[0,0,0],[255,0,255],[0,0,255],[0,255,255],[0,255,0],[255,255,0],[255,0,0],[255,255,255]]
        ; Presets 1-4: Line colors suitable for colorblind vision
        1: line_clrs = [[0,0,0],[67,147,195],[33,102,172],[103,0,31],[178,24,43],[254,219,199],[244,165,130],[255,255,255]]
        2: line_clrs = [[0,0,0],[253,224,239],[77,146,33],[161,215,106],[233,163,201],[230,245,208],[197,27,125],[255,255,255]]
        3: line_clrs = [[0,0,0],[216,179,101],[140,81,10],[246,232,195],[1,102,94],[199,234,229],[90,180,172],[255,255,255]]   
        4: line_clrs = [[0,0,0],[84,39,136],[153,142,195],[216,218,235],[241,163,64],[254,224,182],[179,88,6],[255,255,255]] 
        ; Preset 5:  Same as 0 but substitutes orange for yellow for better contrast on white background
        5: line_clrs = [[0,0,0],[255,0,255],[0,0,255],[0,255,255],[0,255,0],[255,165,0],[255,0,0],[255,255,255]]
        ; Preset 6:  Same as 0 but substitutes gray for yellow for better contrast on white background
        6: line_clrs = [[0,0,0],[255,0,255],[0,0,255],[0,255,255],[0,255,0],[141,141,141],[255,0,0],[255,255,255]]
        ; Preset 7:  Suggested by https://www.nature.com/articles/nmeth.1618, except no reddish purple
        7: line_clrs = [[0,0,0],[230,159,0],[86,180,233],[0,158,115],[240,228,66],[0,114,178],[213,94,0],[255,255,255]]
        ; Preset 8:  Suggested by https://www.nature.com/articles/nmeth.1618, except no yellow
        8: line_clrs = [[0,0,0],[230,159,0],[86,180,233],[0,158,115],[0,114,178],[213,94,0],[204,121,167],[255,255,255]]
        ; Preset 9:  Same as 8 but permuted so default vector colors are blue, orange, reddish purple
        9: line_clrs = [[0,0,0],[86,180,233],[0,114,178],[0,158,115],[230,159,0],[213,94,0],[204,121,167],[255,255,255]]
        ; Preset 10: Chaffin's CSV line colors, suitable for colorblind vision
        10: line_clrs = [[0,0,0],[152,78,163],[55,126,184],[77,175,74],[255,255,51],[255,127,0],[228,26,28],[255,255,255]]
        ; Otherwise: Same as 1
        else: line_clrs = [[0,0,0],[67,147,195],[33,102,172],[103,0,31],[178,24,43],[254,219,199],[244,165,130],[255,255,255]]
      endcase
    endif
    line_clrs = fix(line_clrs)
  endif

; Method 3: Define custom line color(s) by structure - will modify the above color settings

  if keyword_set(mycolors) then begin
    if (n_elements(line_clrs) ne 24) then line_clrs = default
    undefine, ind, rgb
    str_element, mycolors, 'ind', ind  &  ni = n_elements(ind)
    str_element, mycolors, 'rgb', rgb  &  nr = n_elements(rgb)

    if (nr eq ni*3L) then begin
      for i=0,(ni-1) do begin
        if ((ind[i] le 6) or (ind[i] eq 255)) then line_clrs[*,ind[i]<7] = rgb[*,i] $
                                              else print,"Cannot alter color index: ",ind[i]
      endfor
    endif else begin
      print,"Cannot interpret MYCOLORS structure."
      return, 0
    endelse
  endif

  if (n_elements(line_clrs) ne 24) then line_clrs = default

; Set color index 255 to gray (for backward compatibility)

  case n_elements(graybkg) of
     0   : ; do nothing
     1   : line_clrs[*,7] = 211
     3   : line_clrs[*,7] = graybkg
    else : print,"Cannot interpret GRAYBKG."
  endcase

  return, line_clrs

end


