;+
;PROCEDURE loadct2, colortable
;   By default LOADCT2 uses the same color table used by LOADCT
;   This can be changed in 3 ways:
;   1) Use the FILE keyword to define a new file
;   2) Define the environment variable IDL_CT_FILE to point to a new file
;   3) Place a new color table file in the same directory as LOADCT2 that matches
;         the name: 'colors*.tbl'.  (The last file found with file_search is used).
;
;INPUTS:
;   colortable: Color table number.  Required.
;
;KEYWORDS:
;   REVERSE: If set, then reverse the table order from bottom_c to top_c.
;   PREVIOUS_CT: Needed by tplot to change color tables on the fly.
;   PREVIOUS_REV: Needed by tplot to change color tables on the fly.
;   FILE:  (string) Color table file
;          If FILE is not provided then LOADCT2
;          Uses the environment variable IDL_CT_FILE to determine
;          the color table file if FILE is not set.
;   LINE_CLRS: Integer array of 24 (3x8) RGB colors: [[R,G,B], [R,G,B], ...]
;          If this input does not have exactly 24 elements, then a predefined set of 8 colors
;          will be used based on the value of the first element.  Pre-defined color schemes
;          are currently (see code below for any new undocumented schemes):
;             0  : primary colors
;            1-4 : four different schemes suitable for colorblind vision
;             5  : primary colors, except orange replaces yellow for better contrast on white
;             6  : primary colors, except gray replaces yellow for better contrast on white
;             7  : see https://www.nature.com/articles/nmeth.1618 except no reddish purple
;             8  : see https://www.nature.com/articles/nmeth.1618 except no yellow
;             9  : same as 8 but purmuted so vector defaults are blue, orange, reddish purple
;            10  : Chaffin's CSV line colors, suitable for colorblind vision
;   LINE_COLOR_NAMES:  String array of 8 line color names.  You must use line color names
;          recognized by spd_get_color().  RGB values for unrecognized color names are set
;          to zero.  Note that named colors are approximated by the nearest RGB neighbors in 
;          the currently loaded color table.  This can work OK for rainbow color tables, but 
;          for tables that primarily encode intensity, the actual colors can be quite different
;          from the requested ones.
;   COLOR_NAMES: Synonym for LINE_COLOR_NAMES.  Allows better keyword minimum matching, if the
;          previous keyword can be retired.
;   MYCOLORS:
;          A structure defining up to 8 custom colors.  This provides an alternate method of
;          poking individual custom colors into the fixed color indices (0-6 and 255).
;
;            { ind  : up to 8 integers (0-6 or 255)              , $
;              rgb  : up to 8 RGB levels [[R,G,B], [R,G,B], ...]    }
;
;          You can also specify LINE_CLRS and LINE_COLOR_NAMES, and this keyword can make further
;          adjustments.
;
;          The indicies (ind) specified in MYCOLORS will replace one or more of these
;          colors.  You are not allowed to change color indices 7-254, because those
;          are reserved for the color table.  Indices 0 and 255 allow you to define 
;          custom foreground and background colors.
;   GRAYBKG: Set color index 255 to gray [211,211,211] instead of white.
;          See keyword MYCOLORS for a general method of setting any line color to any RGB value.
;          For example, GRAYBKG=1 is equivalent to MYCOLORS={ind:255, rgb:[211,211,211]}.
;          To actually use this color for the background, you must set !p.background=255
;          (normally combined with !p.color=0).
;   RGB_TABLE: Named variable that returns the current 3x8 line color table.
;          get_line_colors() provides the same functionality.
;
;common blocks:
;   colors:      IDL color common block.  Many IDL routines rely on this.
;   colors_com:
;See also:
;   "get_colors","colors_com","bytescale"
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-02-25 17:51:45 -0800 (Sat, 25 Feb 2023) $
; $LastChangedRevision: 31526 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/loadct2.pro $
;
;Created by Davin Larson;  August 1996
;-

pro loadct2,ct,invert=invert,reverse=revrse,file=file,previous_ct=previous_ct,previous_rev=previous_rev,$
               graybkg=graybkg, line_clrs=line_clrs,line_color_names=line_color_names,mycolors=mycolors,$
               color_names=color_names,rgb_table=rgb_table
  compile_opt idl2, hidden
  COMMON colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
  @colors_com

  if n_elements(ct) eq 0 then begin
    dprint,'You must specify a color table.'
    return
  endif

  if !d.name eq 'NULL' or !d.name eq 'HP' then begin   ; NULL device and HP device do not support loadct
    dprint,'Device ',!d.name,' does not support color tables. Command Ignored'
    return
  endif

  deffile = getenv('IDL_CT_FILE')
  
  ; flag specifying that the CT environment variable was set, or color table supplied via file keyword
  ; this is a kludge to support color table #s above 43 with user-supplied color table files - egrimes, 3Sep2019
  if keyword_set(deffile) or keyword_set(file) then env_ct_set = 1b else env_ct_set = 0b 
  
  dir = ''
  if not keyword_set(deffile) then begin  ; looks for color table file in same directory
    stack = scope_traceback(/structure)
    filename = stack[scope_level()-1].filename
    dir = file_dirname(filename)
    deffile = file_search(dir+'/'+'colors*.tbl',count=nf)
    if nf gt 0 then deffile=deffile[nf-1]              ; Use last one found
    ;dprint,'Using color table: ',deffile,dlevel=3
  endif
  if not keyword_set(file) and keyword_set(deffile) then file=deffile
  
  if keyword_set(file) && ~file_test(file) then file=dir + path_sep() + file

; Primary color names (only correct if LINE_CLRS=0)

  black = 0
  magenta = 1
  blue = 2
  cyan = 3
  green = 4
  yellow = 5
  red = 6
  bottom_c = 7

  revrse = keyword_set(revrse)
  if n_elements(color_table) eq 0 then color_table=ct
  previous_ct = color_table
  if n_elements(color_reverse) eq 0 then color_reverse=revrse
  previous_rev = color_reverse
  
  
  if (ct le 43 or env_ct_set) then loadct,ct,bottom=bottom_c,file=file $
                                else loadct,ct ; this line is changed
                                ;to be able to load color tables > 43
  color_table = ct
  color_reverse = revrse

  top_c = !d.table_size-2
  white =top_c+1
  cols = [black,magenta,blue,cyan,green,yellow,red,white]  ; correct for LINE_CLRS=0
  primary = cols[1:6]


  tvlct,r,g,b,/get

  if revrse then begin
    r[bottom_c:top_c] = reverse(r[bottom_c:top_c])
    g[bottom_c:top_c] = reverse(g[bottom_c:top_c])
    b[bottom_c:top_c] = reverse(b[bottom_c:top_c])
  endif

  new_line_colors = 0

  if (n_elements(line_colors_common) ne 24) then begin
    r[cols] = [0,1,0,0,0,1,1,1]*255
    g[cols] = [0,0,0,1,1,1,0,1]*255
    b[cols] = [0,1,1,1,0,0,0,1]*255
    line_colors_common = fix([[0,0,0],[255,0,255],[0,0,255],[0,255,255],[0,255,0],[255,255,0],[255,0,0],[255,255,255]])
  endif else begin
    r[cols] = line_colors_common[0,*]
    g[cols] = line_colors_common[1,*]
    b[cols] = line_colors_common[2,*]
  endelse

  if keyword_set(graybkg) then begin
    r[cols[7]] = 211
    g[cols[7]] = 211
    b[cols[7]] = 211
    if n_elements(graybkg) eq 3 then begin
      r[cols[7]] = graybkg[0]
      g[cols[7]] = graybkg[1]
      b[cols[7]] = graybkg[2]
    endif
    new_line_colors = 1
  endif

; Three methods for setting the fixed line colors (0-6 and 255)

; Method 1: Line and background colors by name

  if keyword_set(color_names) then line_color_names = color_names
  if keyword_set(line_color_names) then begin
    if ((n_elements(line_color_names) ne 8) or (size(line_color_names,/type) ne 7)) then begin
      dprint,'line_color_names must be an 8-element string array'
      return
    endif
    line_clrs=transpose(spd_get_color(line_color_names,/rgb))
    ; then fall through to the line_clrs processing
  endif
 
; Method 2: Line and background colors by array (five presets or entirely custom)

  if n_elements(line_clrs) gt 0 then begin
    if n_elements(line_clrs) ne 24 then begin
      ; If the user did not provide 8 colors, then use a color scheme appropriate for colorblind vision
      case fix(line_clrs[0]) of
        ; Preset 0:  The standard SPEDAS colors (useful for resetting this option without doing a .full_reset_session)
        0: line_clrs = [[0,0,0],[255,0,255],[0,0,255],[0,255,255],[0,255,0],[255,255,0],[255,0,0],[255,255,255]]
        ; Presets 1-4: Line colors suitable for colorblind vision
        1: line_clrs = [[0,0,0],[67, 147, 195],[33, 102, 172],[103, 0, 31],[178,24,43],[254,219,199],[244,165,130],[255,255,255]]
        2: line_clrs = [[0,0,0],[253,224,239],[77,146,33],[161,215,106],[233,163,201],[230,245,208],[197,27,125],[255,255,255]]
        3: line_clrs = [[0,0,0],[216,179,101],[140,81,10],[246,232,195],[1,102,94],[199,234,229],[90,180,172],[255,255,255]]   
        4: line_clrs = [[0,0,0],[84,39,136],[153,142,195],[216,218,235],[241,163,64],[254,224,182],[179,88,6],[255,255,255]] 
        ; Preset 5:  Similar to standard colors, but substitutes orange for yellow for better contrast on white background
        5: line_clrs = [[0,0,0],[255,0,255],[0,0,255],[0,255,255],[0,255,0],[255,165,0],[255,0,0],[255,255,255]]
        ; Preset 6:  Similar to standard colors, but substitutes gray for yellow for better contrast on white background
        6: line_clrs = [[0,0,0],[255,0,255],[0,0,255],[0,255,255],[0,255,0],[141,141,141],[255,0,0],[255,255,255]]
        ; Preset 7:  Color table suggested by https://www.nature.com/articles/nmeth.1618 except for reddish purple (Color 7 must be white for the background.)
        7: line_clrs = [[0,0,0],[230,159,0],[86,180,233],[0,158,115],[240,228,66],[0,114,178],[213,94,0],[255,255,255]]
        ; Preset 8:  Color table suggested by https://www.nature.com/articles/nmeth.1618 except for yellow (Color 7 must be white for the background.)
        8: line_clrs = [[0,0,0],[230,159,0],[86,180,233],[0,158,115],[0,114,178],[213,94,0],[204,121,167],[255,255,255]]
        ; Preset 9: Same as 8, except with the colors shifted around so that the default colors 
        ; for vectors are: blue, orange, reddish purple
        9: line_clrs = [[0,0,0],[86,180,233],[0,114,178],[0,158,115],[230,159,0],[213,94,0],[204,121,167],[255,255,255]]
        10: line_clrs = [[0,0,0],[152,78,163],[55,126,184],[77,175,74],[255,255,51],[255,127,0],[228,26,28],[255,255,255]]
        else: line_clrs = [[0,0,0],[67, 147, 195],[33, 102, 172],[103, 0, 31],[178,24,43],[254,219,199],[244,165,130],[255,255,255]]
      endcase
      line_clrs = fix(line_clrs)
    endif
    for i=0, 6 do begin
      r[i] = line_clrs[i*3]
      g[i] = line_clrs[i*3+1]
      b[i] = line_clrs[i*3+2]
    endfor
    ncount = n_elements(r)
    r[ncount-1] = line_clrs[21]
    g[ncount-1] = line_clrs[22]
    b[ncount-1] = line_clrs[23]
    new_line_colors = 1
  endif

; Method 3: Define custom line color(s) by structure - will modify the above color settings

  if keyword_set(mycolors) then begin
    if (n_elements(line_clrs) ne 24) then line_clrs = line_colors_common
    undefine, ind, rgb
    str_element, mycolors, 'ind', ind  &  ni = n_elements(ind)
    str_element, mycolors, 'rgb', rgb  &  nr = n_elements(rgb)

    if (nr eq ni*3L) then begin
      for i=0,(ni-1) do begin
        if ((ind[i] le 6) or (ind[i] eq 255)) then begin
          r[ind[i]] = rgb[0,i]
          g[ind[i]] = rgb[1,i]
          b[ind[i]] = rgb[2,i]
          line_clrs[*,i] = rgb[*,i]
        endif else print,"Cannot alter color index: ",ii[i]
      endfor
      new_line_colors = 1
    endif else begin
      print,"Cannot interpret MYCOLORS structure."
      return
    endelse
  endif

  if (new_line_colors) then line_colors_common = line_clrs

  tvlct,r,g,b

  r_curr = r  ;Important!  Update the colors common block.
  g_curr = g
  b_curr = b

  rgb_table = [[r], [g], [b]]  ; See get_line_colors()

end

