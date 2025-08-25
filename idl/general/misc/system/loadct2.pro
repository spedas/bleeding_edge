;+
;PROCEDURE loadct2, colortable
;   By default LOADCT2 uses the same color table used by LOADCT
;   This can be changed in 3 ways:
;   1) Use the FILE keyword to define a new file
;   2) Define the environment variable IDL_CT_FILE to point to a new file
;   3) Place a new color table file in the same directory as LOADCT2 that matches
;         the name: 'colors*.tbl'.  (The last file found with file_search is used).
;
;   This routine now uses get_line_colors() to define the eight fixed RGB colors for
;   drawing lines and setting the background and foreground colors.  All line color 
;   keywords work as before but are now passed to that function.  Please place any
;   new line color schemes in get_line_colors().
;
;USAGE:
;   loadct2, colortable [, KEYWORD=value, ...]
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
;   LINE_CLRS: Integer array of 24 (3x8) RGB values: [[R,G,B], [R,G,B], ...]
;          If this input does not have exactly 24 elements, then a predefined set of 8 colors
;          will be used based on the value of the first element.  Pre-defined color schemes
;          are currently (see code below for any new undocumented schemes):
;             0  : primary colors
;            1-4 : four different schemes suitable for colorblind vision
;             5  : primary colors, except orange replaces yellow for better contrast on white
;             6  : primary colors, except gray replaces yellow for better contrast on white
;             7  : see https://www.nature.com/articles/nmeth.1618 except no reddish purple
;             8  : see https://www.nature.com/articles/nmeth.1618 except no yellow
;             9  : same as 8 but permuted so vector defaults are blue, orange, reddish purple
;            10  : Chaffin's CSV line colors, suitable for colorblind vision
;   LINE_COLOR_NAMES:  String array of 8 line color names.  You must use line color names
;          recognized by spd_get_color().  RGB values for unrecognized color names are set
;          to zero.  Note that named colors are approximated by the nearest RGB neighbors in 
;          the currently loaded color table.  This can work OK for rainbow color tables, but 
;          for tables that primarily encode intensity, the actual colors can be quite different
;          from the requested ones.  Included for backward compatibility.
;   COLOR_NAMES: Synonym for LINE_COLOR_NAMES.  Allows better keyword minimum matching, if the
;          previous keyword can be retired.  Both keywords are accepted - this one takes precedence.
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
;   RGB_TABLE: Named variable that returns the color table as a 256x3 array of RGB values
;
;common blocks:
;   colors:      IDL color common block.  Many IDL routines rely on this.
;   colors_com:
;See also:
;   "get_colors","colors_com","bytescale","get_line_colors","line_colors","showct","initct"
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
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

  tvlct,r,g,b,/get

  if revrse then begin
    r[bottom_c:top_c] = reverse(r[bottom_c:top_c])
    g[bottom_c:top_c] = reverse(g[bottom_c:top_c])
    b[bottom_c:top_c] = reverse(b[bottom_c:top_c])
  endif

; Set line colors:  get_line_colors() contains all methods for setting custom colors.

  if keyword_set(color_names) then line_color_names = color_names  ; equivalent keywords
  lines = get_line_colors(line_clrs, color_names=line_color_names, mycolors=mycolors, graybkg=graybkg)
  line_colors_common = lines

  r[cols] = lines[0,*]
  g[cols] = lines[1,*]
  b[cols] = lines[2,*]
  rgb_table = [[r],[g],[b]]

  tvlct,r,g,b

  r_curr = r  ;Important!  Update the colors common block.
  g_curr = g
  b_curr = b

end
