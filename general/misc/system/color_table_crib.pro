;+
;CRIB for managing color tables and line colors and taking control of colors in tplot
;
;ROUTINES:
;   initct : Wrapper for loadct2 and loadcsv.  Works the same way as loadct2 and loadcsv,
;            but provides access to both sets of color tables.  Provides keywords for 
;            setting line colors.  The previous routines still exist and can still be 
;            called as before, so there's no need to modify any code unless you want to.
;   showct : Display the current color table or any color table with any line color scheme.
;   revvid : Swaps the values of !p.background and !p.color.
;   line_colors : Choose one of 11 predefined line color schemes, or define a custom scheme.
;   get_line_colors : Returns a 3x8 array of the current line colors [[R,G,B],[R,G,B], ...].
;                     Can also return the 3x8 array for any line color scheme.
;
;   See the headers of these routines for more details.
;
;OVERVIEW:
;
;   Chances are you have a TrueColor display that can produce 256^3 = 16,777,216 colors by
;   adding red, green and blue levels, each from 0 to 255.  Tplot and many associated 
;   routines use a color table, which is a 3x256 array consisting of a small subset of the
;   possible colors.  Tplot reserves eight colors: one for the foreground color, one for the
;   background color, and six for drawing lines.  The rest make up the color table:
;
;       Color           Purpose                             Modify With
;      --------------------------------------------------------------------------
;         0             black (or any dark color)           initct, line_colors
;        1-6            fixed line colors                   initct, line_colors
;        7-254          color table (bottom_c to top_c)     initct
;        255            white (or any light color)          initct, line_colors
;      --------------------------------------------------------------------------
;
;   Colors 0 and 255 are usually associated with !p.background and !p.color.  For a light
;   background, set !p.background = 255 and !p.color = 0.  Do the opposite for a dark
;   background.  Use revvid to toggle between these options.
;
;   There are many possible color tables, because each table uses only 248 out of more than
;   16 million available colors.  The standard catalog has table numbers from 0 to 74, while
;   the CSV catalog has table numbers from 0 to 118.  These ranges overlap, so we need some
;   way to separate them.  I chose to add 1000 to the CSV table numbers, so CSV table 78
;   becomes 1078, etc.  There is also substantial overlap in the tables themselves:
;
;        Standard Tables      CSV Tables       Note
;      ----------------------------------------------------------------
;            0 - 40           1000 - 1040      identical or nearly so
;           41 - 43           1041 - 1043      different
;           44 - 74           1044 - 1074      identical
;             N/A             1075 - 1118      unique to CSV
;      ----------------------------------------------------------------
;
;   When tables are "nearly identical", only a few colors are different.  The nearly identical
;   tables are: [24, 29, 30, 38, 39, 40] <-> [1024, 1029, 1030, 1038, 1039, 1040].  So, apart
;   from a few slight differences, there are 122 unique tables.
;
;   As of this writing, there are 11 predefined line color schemes:
;
;        0  : primary and secondary colors [black, magenta, blue, cyan, green, yellow, red, white]
;       1-4 : four different schemes suitable for colorblind vision
;        5  : same as 0, except orange replaces yellow for better contrast on white
;        6  : same as 0, except gray replaces yellow for better contrast on white
;        7  : https://www.nature.com/articles/nmeth.1618, except no reddish purple
;        8  : https://www.nature.com/articles/nmeth.1618, except no yellow
;        9  : same as 8 but permuted so vector defaults are blue, orange, reddish purple
;       10  : Chaffin's CSV line colors, suitable for colorblind vision
;
;   More schemes can be added by including them in the case statement of get_line_colors().  Always
;   add new schemes at the end of the list (immediately above the "else" statement), so you don't 
;   break anyone else's code.  It's helpful if you can add a note about your scheme.
;
;   Use showct to preview any color table with any line color scheme.
;
;   Tplot has been modified to use initct and line_colors, so you can set custom color tables
;   and line color schemes for individual tplot variables using options.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-04-11 18:47:14 -0700 (Tue, 11 Apr 2023) $
; $LastChangedRevision: 31727 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/color_table_crib.pro $
;
; Created by David Mitchell;  February 2023

pro color_table_crib

  print, 'This routine is not intended to be a procedure.  Read the contents instead.'
  return

; Place the following lines in your idl_startup.pro to initialize your device and color
; table.  Of course, you can choose any of >100 color tables (reversed if desired), any of
; the predefined line color schemes, or completely custom line colors.  This example sets a
; dark background, but many people prefer a light background.

device,decompose=0,retain=2   ; specific to MacOS (settings for other OS's might be different)
                              ;   decompose=0 --> use color table with TrueColor display
                              ;   retain=2 --> IDL provides backing store (safest option)
initct,1074,line=5,/rev,/sup  ; define color table and fixed line colors (suppress error message)
!p.background = 0             ; use tplot fixed color for background (0 = black by default)
!p.color = 255                ; use tplot fixed color for foreground (255 = white by default)

; To use color tables with the Z buffer, do the following:

set_plot, 'z'                            ; switch to virtual graphics device
device, set_pixel_depth=24, decompose=0  ; allow the Z buffer to use color tables

; Change the color table at the command line.  This does not alter the line color scheme, 
; which is persistent until you explicitly change it.

inict, 1091

; Select a new color table and line color scheme at the command line.

initct, 43, line=2

; Change line colors without otherwise modifying the color table.

line_colors, 6

; Swap !p.background and !p.color

revvid

; Use gray instead of white for the background, which looks better in some situations.
; The default gray level is [211,211,211].

revvid, /white  ; if needed
line_colors, 5, /graybkg

; Use a custom gray level for the background.

revvid, /white  ; if needed
line_colors, 5, graybkg=[198,198,198]

; Poke arbitrary RGB colors into indices 1 and 4 of the current line color scheme.

line_colors, mycolors={ind:[1,4], rgb:[[198,83,44],[18,211,61]]}

; Use a fancy rainbow-like CSV color table with line colors suitable for color blind people.
; CSV color tables encode intensity first and color second, which is closer to how humans
; perceive colors.  Reverse the table, so that blue is low and red is high.

initct, 1074, /reverse, line=8

; See a catalog of the many CSV color tables. (Note: loadcsv is not usually called directly.)
; Remember that you have to add 1000 to CSV color table numbers.

loadcsv, /catalog

; Display the current color table with an intensity plot.

showct, /i

; Display any color table with any line color scheme -- DOES NOT modify the current color table.

showct, 1078, line=8, /i
showct, 1091, line=5, /reverse, /graybkg, /i

; Set a custom color table and line color scheme for any tplot variable.  This allows you
; to use multiple color tables and/or line color schemes within a single multi-panel plot.

options, var1, 'color_table', 1074
options, var1, 'reverse_color_table', 1
options, var1, 'line_colors', 10

options, var2, 'color_table', 1078
options, var2, 'reverse_color_table', 0
options, var2, 'line_colors', 5

; Set a custom line color scheme for a tplot variable.

mylines = get_line_colors(5, /graybkg, mycolors={ind:3, rgb:[211,0,211]})
options, var1, 'line_colors', mylines

; Disable custom color tables and line colors for a tplot variable.

options, var1, 'color_table', -1
options, var1, 'line_colors', -1

end ; of crib
;-
