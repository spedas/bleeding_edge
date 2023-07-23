;+
;PROCEDURE:   initct
;PURPOSE:
;  Wrapper for loadct2 and loadcsv.  Calls the appropriate color table 
;  routine based on the requested table number:
;
;      table numbers < 1000  (currently 0-74)      : use loadct2
;      table numbers >= 1000 (currently 1000-1118) : use loadcsv
;
;  There is substantial overlap between the standard and CSV tables:
;
;      Standard Tables      CSV Tables       Note
;    ----------------------------------------------------------------
;          0 - 40           1000 - 1040      identical or nearly so
;         41 - 43           1041 - 1043      different
;         44 - 74           1044 - 1074      identical
;           N/A             1075 - 1118      unique to CSV
;    ----------------------------------------------------------------
;
;  When tables are "nearly identical", only a few colors are different.
;  The nearly identical tables are: [24, 29, 30, 38, 39, 40] <-> 
;  [1024, 1029, 1030, 1038, 1039, 1040].  So, apart from a few slight 
;  differences, there are 122 unique tables.
;
;  Keywords are provided to define fixed colors that are used for lines
;  (1-6), and the background and foreground colors (0,255).
;  ** Once set, these fixed colors are persistent until explicitly changed.
;
;  Use line_colors.pro to change the fixed colors without affecting the rest
;  of the color table.
;
;  Use get_line_colors() to return a 3x8 array containing either the current
;  line colors or custom colors specified by input and keyword.  This can be
;  used to set custom line colors for a tplot variable.  See get_line_colors
;  for details.
;
;USAGE:
;  initct, colortbl [, KEYWORD=value, ...]
;
;INPUTS:
;       colortbl:     Color table number.  If less than 1000, call loadct2
;                     to load one of the standard color tables.  If greater
;                     than or equal to 1000, call loadcsv to load one of
;                     the CSV color tables.  Required.  No default.
;
;KEYWORDS:
;       REVERSE:      If set, reverse the color table (indices 7-254).
;
;       LINE_CLRS:    Defines custom line colors.  Can take one of two forms:
;
;                     (1) Array of 24 (3x8) RGB values that define 8 fixed colors 
;                         (the first 7 and the last) of the color table:
;                         LINE_CLRS = [[R,G,B], [R,G,B], ...].
;
;                     (2) Integer that selects a predefined color scheme:
;
;                         0  : primary and secondary colors
;                        1-4 : four different schemes suitable for colorblind vision
;                         5  : same as 0, except orange replaces yellow for better contrast on white
;                         6  : same as 0, except gray replaces yellow for better contrast on white
;                         7  : https://www.nature.com/articles/nmeth.1618 except no reddish purple
;                         8  : https://www.nature.com/articles/nmeth.1618 except no yellow
;                         9  : same as 8 but permuted so vector defaults are blue, orange, reddish purple
;                        10  : Chaffin's CSV line colors, suitable for colorblind vision
;
;                         See get_line_colors() for RGB values of predefined schemes.
;                         The most recent color schemes may not be documented here.
;
;       COLOR_NAMES:  String array of 8 line color names.  You must use line color
;                     names recognized by spd_get_color().  RGB values for unrecognized
;                     color names are set to zero.  Not recommended, because named 
;                     colors are approximated by the nearest RGB neighbors in the 
;                     currently loaded color table.  This can work OK for rainbow color
;                     tables, but for tables that primarily encode intensity, the 
;                     actual colors can be quite different from the requested ones.
;                     Included for backward compatibility.
;
;       MYCOLORS:     A structure defining up to 8 custom colors.  These are 
;                     fixed colors used to draw colored lines (1-6) and to define
;                     the background (0) and foreground (255) colors.
;
;                     { ind : up to 8 integers (0-6 or 255)              , $
;                       rgb : up to 8 RGB levels [[R,G,B], [R,G,B], ...]    }
;
;                     The indicies (ind) specified in MYCOLORS will replace one or
;                     more of the default colors.  You are not allowed to change
;                     color indices 7-254, because those are reserved for the
;                     color table.  Indices 0 and 255 allow you to define custom
;                     background and foreground colors.
;
;       GRAYBKG:      Set color index 255 to gray [211,211,211] instead of white.
;                     See keyword MYCOLORS for a general method of setting any line 
;                     color to any RGB value.  For example, GRAYBKG=1 is equivalent 
;                     to MYCOLORS={ind:255, rgb:[211,211,211]}.
;
;                     To actually use this color for the background, you must set 
;                     !p.background=255 (normally combined with !p.color=0).
;                     A quick way to do this:  revvid, /white
;
;       PREVIOUS_CT:  Named variable to hold the previous color table number.
;                     Use this to temporarily change the color table and then return
;                     to the previous one.  Tplot needs this to change color tables
;                     on the fly.
;
;       PREVIOUS_REV: Named variable to hold the previous color reverse.
;                     Use this to temporarily change the color table and then return
;                     to the previous one.  Tplot needs this to change color tables
;                     on the fly.
;
;       SHOW:         Show the color table in a separate window after loading.
;
;       SUPPRESS:     Suppress floating overflow error in first call to window.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-03-02 11:08:00 -0800 (Thu, 02 Mar 2023) $
; $LastChangedRevision: 31572 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/initct.pro $
;
;Created by David L. Mitchell (February 2023)
;-

pro initct, ctab, reverse=rv, line_clrs=ln, mycolors=mc, color_names=cn, graybkg=gb, $
                  previous_ct=previous_ct, previous_rev=previous_rev, show=show, $
                  suppress=suppress

  if (n_elements(ctab) eq 0) then begin
    print,"You must supply a color table."
    return
  endif

  ct = fix(ctab[0])

  if (ct lt 1000) then begin
    loadct2, ct, reverse=rv, line_clrs=ln, mycolors=mc, line_color_names=cn, $
                 graybkg=gb, previous_ct=previous_ct, previous_rev=previous_rev
  endif else begin
    loadcsv, ct, reverse=rv, line_clrs=ln, mycolors=mc, line_color_names=cn, $
                 graybkg=gb, previous_ct=previous_ct, previous_rev=previous_rev, /silent
  endelse

  if keyword_set(show) then showct

  if keyword_set(suppress) then i = check_math()

end
