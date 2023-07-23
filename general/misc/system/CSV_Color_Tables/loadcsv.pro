;+
;PROCEDURE:   loadcsv
;PURPOSE:
;  This is a wrapper/translator for loadcsvcolorbar that loads a CSV color table.
;  It works the same way that 'loadct2' does.  Restrictions are imposed that make
;  this routine compatible with tplot:
;
;    (1) Only eight fixed colors are allowed.  These are loaded into the first
;        seven color indices plus the last, with black = 0 and white = 255 (same
;        as loadct2).  Missing are the gray25, gray50, gray75, brown, and pink.
;        With this change, it is not necessary to manage the top and bottom
;        colors.  Use 'get_qualcolors' to access the fixed color names and indices.
;
;    (2) To distinguish the CSV tables from the traditional loadct2 tables, 1000
;        is added to the CSV table number.  So 78 becomes 1078, etc.  When tplot 
;        sees a color table >= 1000, it knows it's a CSV table and uses this
;        routine instead of loadct2.
;
;    (3) Only table numbers are allowed.  See qualcolors documentation to find 
;        out how to define a new table.
;
;    (4) The qualcolors structure is now initialized by this routine and stored
;        in a common block, which 'loadcsvcolorbar2' uses.  The stand-alone config
;        file 'qualcolors' is ignored, so changes there will have no effect.
;        You can get a copy of the qualcolors structure with 'get_qualcolors'.
;
;    (5) !p.color and !p.background are no longer set by default, so you'll have
;        to do this yourself (typically in your idl_startup).  See 'revvid', which
;        swaps the values for !p.color and !p.background.
;
;  Using 'loadcsv' has the following advantages:
;
;    (1) No need to manage qualcolors, paths, or system variables.  You simply
;        use 'loadcsv' the same way you use 'loadct2'.
;
;    (2) 'loadcsv' and 'loadct2' are aware of each other, so both can be used in
;        the same session whenever you like, and tplot does not get confused.
;
;    (3) The 'tplot' interface is greatly simplified.  No need to manage the top
;        and bottom colors when switching between CSV tables and the standard 
;        tplot tables.  Color tables can be specified on a panel-by-panel basis, 
;        with standard tables interspersed with CSV tables:
;
;          options, varname, 'color_table', N
;          options, varname, 'reverse_color_table', {0|1}
;
;        with N < 1000 for standard tables and N >= 1000 for CSV tables.  As usual,
;        varname can be an array of tplot variable names or indices to affect
;        multiple panels with one command.  Variable names can contain wildcards
;        for the same purpose.
;
;  If you are already using the original qualcolors and 'loadcsvcolortable', and
;  you're happy with how that works, you can keep doing things that way.  This
;  routine will not interfere.
;
;USAGE:
;  loadcsv, colortbl [, KEYWORD=value, ...]
;
;INPUTS:
;       colortbl:     CSV table number + 1000.  Don't forget to add 1000!
;                     If this input is missing, then keyword CATALOG is set.
;
;KEYWORDS:
;       RESET:        Reset the qualcolors structure with the default fixed
;                     line colors, then load colortbl.
;
;       PREVIOUS_CT:  Named variable to hold the previous color table number.
;                     Tplot needs this to swap color tables on the fly.
;
;       PREVIOUS_REV: Named variable to hold the previous color reverse.
;                     Tplot needs this to swap color tables on the fly.
;
;       CATALOG:      Display an image of the CSV color tables and return.
;                     Does not load a color table.
;
;       LINE_CLRS:    Defines custom line colors.  Can take one of two forms:
;
;                     Array of 24 (3x8) RGB values that define 8 fixed colors 
;                     (the first 7 and the last) of the color table:
;                       LINE_CLRS = [[R,G,B], [R,G,B], ...].
;
;                     Integer from 0 to 10 that selects one of the predefined sets
;                     of fixed line colors.  Except for primary colors, these
;                     are suitable for colorblind vision.
;
;                       0  : primary colors
;                      1-4 : four different schemes suitable for colorblind vision
;                       5  : primary colors, except orange replaces yellow for better contrast on white
;                       6  : primary colors, except gray replaces yellow for better contrast on white
;                       7  : see https://www.nature.com/articles/nmeth.1618 except no reddish purple
;                       8  : see https://www.nature.com/articles/nmeth.1618 except no yellow
;                       9  : same as 8 but permuted so vector defaults are blue, orange, reddish purple
;                      10  : Chaffin's CSV line colors, suitable for colorblind vision
;
;                     Default = 10.
;
;       LINE_COLOR_NAMES:  String array of 8 line color names.  You must use line color
;                     names recognized by spd_get_color().  RGB values for unrecognized
;                     color names are set to zero.  Not recommended, because named 
;                     colors are approximated by the nearest RGB neighbors in the 
;                     currently loaded color table.  This can work OK for rainbow color
;                     tables, but for tables that primarily encode intensity, the 
;                     actual colors can be quite different from the requested ones.
;                     Included for backward compatibility.
;
;       COLOR_NAMES:  Synonym for LINE_COLOR_NAMES.  Allows better keyword minimum
;                     matching.  Both keywords are accepted - this one takes precedence.
;
;       MYCOLORS:     A structure defining up to 8 custom colors.  These are 
;                     fixed colors used to draw colored lines (1-6) and to define
;                     the background (0) and foreground (255) colors.
;
;                     { ind    : up to 8 integers (0-6 or 255)              , $
;                       rgb    : up to 8 RGB levels [[R,G,B], [R,G,B], ...]    }
;
;                     The indicies (ind) specified in MYCOLORS will replace one or
;                     more of the default colors.  You are not allowed to change
;                     color indices 7-254, because those are reserved for the
;                     color table.  Indices 0 and 255 allow you to define custom
;                     background and foreground colors.
;
;                     Changes made with LINE_CLRS and MYCOLORS are persistent, so
;                     you can change the color table (indices 7-254) while keeping
;                     the same fixed line colors.  Use line_colors.pro to do the 
;                     reverse: change the line colors while keeping the color table.
;
;       GRAYBKG:      Set color index 255 to gray [211,211,211] instead of white.
;                     See keyword MYCOLORS for a general method of setting any line 
;                     color to any RGB value.  For example, GRAYBKG=1 is equivalent 
;                     to MYCOLORS={ind:255, rgb:[211,211,211]}.
;
;                     To actually use this color for the background, you must set 
;                     !p.background=255 (normally combined with !p.color=0).
;
;       Also passes all keywords accepted by loadcsvcolorbar2.
;
;See also:
;   "initct","line_colors","get_line_colors","loadcsv","get_colors","colors_com","bytescale"
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-03-05 09:49:05 -0800 (Sun, 05 Mar 2023) $
; $LastChangedRevision: 31584 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/CSV_Color_Tables/loadcsv.pro $
;
;CSV color table code: Mike Chaffin
;Tplot-compatible version: David L. Mitchell
;-
pro loadcsv, colortbl, reset=reset, previous_ct=previous_ct, previous_rev=previous_rev, $
                       reverse=crev, catalog=catalog, mycolors=mycolors, line_clrs=line_clrs, $
                       line_color_names=line_color_names, color_names=color_names, graybkg=graybkg, $
                       _EXTRA = ex

  @colors_com  ; allows loadcsv to communicate with loadct2
  common qualcolors_com, qualcolors

; Put up an image of the CSV color tables

  if keyword_set(catalog) then begin
    wnum = !d.window
    colortabledir = file_dirname(file_which('loadcsvcolorbar2.pro'))+"/"
    read_png, colortabledir + 'all_idl_tables_sm.png', img
    sz = size(img)
    win, /free, /sec, xsize=sz[2], ysize=sz[3], dx=10, dy=-10
    tv, img, /true
    wset, wnum
    return
  endif

; Make sure colortbl is reasonable

  csize = size(colortbl,/type)
  if ((csize lt 1) or (csize gt 5)) then begin
    print,"You must specify a CSV table number."
    return
  endif
  ctab = fix(colortbl[0])
  if (ctab lt 1000) then begin
    print,"You must add 1000 to the CSV table number."
    return
  endif

; Set the line colors (use Chaffin's CSV colors as default instead of primary colors)

  if ((size(line_clrs,/type) eq 0) && (n_elements(line_colors_common) ne 24)) then line_clrs = 10
  if keyword_set(color_names) then line_color_names = color_names  ; equivalent keywords
  lines = get_line_colors(line_clrs, color_names=line_color_names, mycolors=mycolors, graybkg=graybkg)
  line_colors_common = lines

  ni = 8
  j = [indgen(7), 255]
  r = reform(lines[0,*])
  g = reform(lines[1,*])
  b = reform(lines[2,*])

; Define a tplot-compatible version of the qualcolors structure

  if ((size(qualcolors,/type) ne 8) or keyword_set(reset)) then begin
    qualcolors = {black         : 0, $
                  purple        : 1, $ 
                  blue          : 2, $
                  green         : 3, $ 
                  yellow        : 4, $
                  orange        : 5, $
                  red           : 6, $
                  white         : !d.table_size-1, $
                  nqual         : 8, $
                  bottom_c      : 7, $
                  top_c         : !d.table_size-2, $
                  colornames    : ['black','purple','blue','green','yellow','orange','red','white'], $
                  qi            : [  0,   1,   2,   3,   4,   5,   6, !d.table_size-1 ], $ 
                  qr            : [  0, 152,  55,  77, 255, 255, 228, 255 ], $
                  qg            : [  0,  78, 126, 175, 255, 127,  26, 255 ], $
                  qb            : [  0, 163, 184,  74,  51,   0,  28, 255 ], $
                  table_name    : '', $
                  color_table   : -1, $
                  color_reverse :  0   }
  endif

; Poke custom colors into the qualcolors structure and update line_colors_common

  qualcolors.qi = j
  qualcolors.qr = r
  qualcolors.qg = g
  qualcolors.qb = b

  line_colors_common[0,*] = qualcolors.qr
  line_colors_common[1,*] = qualcolors.qg
  line_colors_common[2,*] = qualcolors.qb

; Load the CSV table

  crev = keyword_set(crev)
  qualcolors.color_table = ctab                ; external table number for tplot
  qualcolors.color_reverse = crev              ; color reverse flag
  ctab -= 1000                                 ; internal table number for loadcsvcolorbar2
  loadcsvcolorbar2, ctab, reverse=crev, _EXTRA = ex
  qualcolors.table_name = file_basename(ctab)  ; corresponding filename

; Tell tplot and loadct2 what happened

  bottom_c = qualcolors.bottom_c
  top_c = qualcolors.top_c
  ctab = qualcolors.color_table
  if (n_elements(color_table) eq 0) then previous_ct = ctab else previous_ct = color_table
  color_table = ctab
  if (n_elements(color_reverse) eq 0) then previous_rev = crev else previous_rev = color_reverse
  color_reverse = crev

end
