;+
;CRIB for managing color tables and line colors and taking control of colors in tplot
;
;ROUTINES:
;   initct : Wrapper for loadct2 and loadcsv.  Works the same way as loadct2 and loadcsv,
;            but provides access to both sets of color tables.  Provides keywords for 
;            setting line colors.  The previous routines still exist and can still be 
;            called as before, so there's no need to modify any code unless you want to.
;   showct : Display the current color table or any color table with any line color scheme.
;            Also shows a catalog of color tables as a grid of color bars.
;   revvid : Swaps the values of !p.background and !p.color.
;   line_colors : Choose one of 11 predefined line color schemes, or define a custom scheme.
;   get_line_colors : Returns a 3x8 array of the current line colors [[R,G,B],[R,G,B], ...].
;                     Can also return the 3x8 array for any line color scheme.
;   color_table : Returns the current color table as a 256x3 array.
;
;HELPER ROUTINE:
;   tsnap:   Plots Y-Z cuts through any tplot color spectrogram at times (X) selected by 
;            the mouse.  Plots error bars if DY is specified in the tplot variable.
;            Also averages data in time and propagates errors, if desired.  Use this to
;            determine if color variations are significant.
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
;   Table 43 is a custom rainbow-like table designed at SSL.  The standard rainbow table (34)
;   is problematic because it contains a large "dead zone", where many of the color values are
;   hues of green that are hard to distinguish.  Important features of the data can be lost in
;   this dead zone.  Table 43 is designed to have roughly the same number of table entries for
;   each of the distinguishable colors (magenta, blue, cyan, green, yellow, orange, red) and 
;   to extend the overall dynamic range with fade-to-black and saturate-to-deep-red.  This 
;   table minimizes dead zones and is good for showing variations over a wide dynamic range;
;   however, it has a double-peaked intensity curve and is not suitable for the color blind.  
;   It's worth comparing this table with an intensity-based table, such as 1074.  Each table 
;   has its pros and cons.
;
;   Table numbers 49-65 (standard), 1049-1065 (CSV), and 1075-1116 (CSV) encode intensity on
;   a monotonically increasing or decreasing scale, with color as a secondary feature.  These
;   are useful for displaying data where intensity is the most important attribute.
;
;   Table numbers 66-74 (standard) and 1066-1074 (CSV) are cross-fade tables, starting with a
;   deep shade of one color and ending with a deep shade of a different color, with the peak
;   intensity in the center.  Table 74 (or 1074) reversed is similar to a rainbow table.  Its
;   single-peaked intensity curve is good perceptually; however, it has a dead zone from light
;   green to yellow to light orange, which makes up about 25% of the table, so it's not good 
;   for showing variations in the middle of the dynamic range (same problem as table 34).
;
;   Table numbers 1117 and 1118 are cyclical, with the top and bottom colors the same.  These
;   tables are useful for displaying phase data (0 to 360 degrees).
;
;   In addition to the standard and CSV catalogs, you can also choose the SPP Fields catalog
;   which is based on the CET catalog (https://colorcet.com/index.html).  The SPP catalog has 
;   the same goals as the CSV catalog, but has a different set of intensity, cross-fade, and 
;   cyclical tables.  In particular, the SPP catalog has more cross-fade and cyclical options.
;
;   As of this writing, there are 12 predefined line color schemes:
;
;        0  : primary and secondary colors [black, magenta, blue, cyan, green, yellow, red, white]
;       1-4 : four different schemes suitable for colorblind vision
;        5  : same as 0, except orange replaces yellow for better contrast on white
;        6  : same as 0, except gray replaces yellow for better contrast on white
;        7  : https://www.nature.com/articles/nmeth.1618, except no reddish purple
;        8  : https://www.nature.com/articles/nmeth.1618, except no yellow
;        9  : same as 8 but permuted so vector defaults are blue, orange, reddish purple
;       10  : Chaffin's CSV line colors, suitable for colorblind vision
;       11  : same as 5, except a darker green for better contrast on white
;
;   More schemes can be added by including them in the initialization block of get_line_colors.pro.
;   Always add new schemes at the end of the list, so you don't break anyone else's code.  It's 
;   helpful if you can add a note about your scheme.
;
;   Use showct to preview any color table with any line color scheme.  It's always best to try out
;   different color tables on the actual data to evaluate what conveys the important features best
;   without being misleading.  (The most important person not to mislead is yourself.)  There is
;   no substitute for plotting cuts through the color spectrogram with symbols and error bars.
;   This allows you to determine if a change in color is statistically significant.  There is a
;   generic routine that plots cuts through any tplot color spectrogram at times selected by the
;   mouse: tsnap.pro (see that routine's header for more information).
;
;   Tplot has been modified to use initct and line_colors, so you can set custom color tables
;   and line color schemes for individual tplot variables using options.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-05-25 12:08:33 -0700 (Sun, 25 May 2025) $
; $LastChangedRevision: 33340 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/color_table_crib.pro $
;
; Created by David Mitchell;  February 2023

pro color_table_crib

  print, 'This routine is not intended to be a procedure.  Read the contents instead.'
  return

;; Place the following lines in your idl_startup.pro to initialize your device and color
;; table.  Of course, you can choose any of >100 color tables (reversed if desired), any of
;; the predefined line color schemes, or completely custom line colors.  This example sets a
;; dark background, but many people prefer a light background.

device,decompose=0,retain=2   ; specific to MacOS (settings for other OS's might be different)
                              ;   decompose=0 --> use color table with TrueColor display
                              ;   retain=2 --> IDL provides backing store (safest option)
initct,1074,line=5,/rev,/sup  ; define color table and fixed line colors (suppress error message)
!p.background = 0             ; use tplot fixed color for background (0 = black by default)
!p.color = 255                ; use tplot fixed color for foreground (255 = white by default)

;; To use color tables with the Z buffer, do the following:

set_plot, 'z'                            ; switch to virtual graphics device
device, set_pixel_depth=24, decompose=0  ; allow the Z buffer to use color tables

;; Change the color table at the command line.  This does not alter the line color scheme, 
;; which is persistent until you explicitly change it.

initct, 1091

;; Select a new color table and line color scheme at the command line.

initct, 43, line=2

;; Change line colors without otherwise modifying the color table.

line_colors, 6

;; Swap !p.background and !p.color

revvid

;; Use gray instead of white for the background, which looks better in some situations.
;; The default gray level is [211,211,211].

revvid, /white  ; if needed
line_colors, 5, /graybkg

;; Use a custom gray level for the background.

revvid, /white  ; if needed
line_colors, 5, graybkg=[198,198,198]

;; Poke arbitrary RGB colors into indices 1 and 4 of the current line color scheme.

line_colors, mycolors={ind:[1,4], rgb:[[198,83,44],[18,211,61]]}

;; Use an intensity-based, rainbow-like color table (1074).  Reverse the table, so that blue is
;; low and red is high.  Use line colors suitable for the color blind.

initct, 1074, /reverse, line=8

;; Choose the SPP Fields color table catalog.  Once you change the color table catalog,
;; it remains in effect until you use initct to change it.  You can also select the SPP Fields
;; color tables by setting the environment variable IDL_CT_FILE.

initct, 123, /spp

;; Display the current color table with an intensity plot.

showct, /i

;; Display any color table with any line color scheme.  Unlike initct, this does not make any
;; changes to the color table or line colors.

showct, 1078, line=8, /i
showct, 1091, line=5, /reverse, /graybkg, /i

;; Display a catalog of color tables as a grid of color bars in a separate window.  Also show
;; the current color table and corresponding intensity plot.

showct, /i, /cat

;; Show the SPP Fields catalog and a color table from that catalog.

showct, 123, /i, /cat, /spp

;; Following one of these commands, you can omit the CAT keyword and use showct to take a close
;; look at any of the tables in the catalog while the catalog window is still visible.  Keep in
;; mind what you are trying to convey with color.  Is it variations over a wide dynamic range, 
;; or intensity, or something else?  See https://colorcet.com/index.html for tips on choosing
;; a good color table.

showct, 125, /i, /spp
showct, 84, /reverse, /i, /spp

;; Set a custom color table and line color scheme for any tplot variable.  This allows you
;; to use multiple color tables and/or line color schemes within a single multi-panel plot.

options, var1, 'color_table', 1074
options, var1, 'reverse_color_table', 1
options, var1, 'line_colors', 10

options, var2, 'color_table', 1078
options, var2, 'reverse_color_table', 0
options, var2, 'line_colors', 5

;; Set a custom line color scheme for a tplot variable.

mylines = get_line_colors(5, /graybkg, mycolors={ind:3, rgb:[211,0,211]})
options, var1, 'line_colors', mylines

;; Disable custom color tables and line colors for a tplot variable.

options, var1, 'color_table', -1
options, var1, 'line_colors', -1

;; Set color, line style and thickness for constants.  If there are fewer colors
;; than values, then the colors are cycled as needed.  Line styles (0-5) and line
;; thicknesses work the same way.

options, var1, 'constant',    [value0, value1, ...]
options, var1, 'const_color', [color0, color1, ...]
options, var1, 'const_line',  [style0, style1, ...]
options, var1, 'const_thick', [thick0, thick1, ...]

;; Plot Y-Z cuts through a tplot color spectrogram at times (X) selected with the
;; mouse.  This example enables plotting of error bars (ERR=1), averages five 
;; neighboring measurements (NAVG=5), and sets some keywords that are passed to 
;; PLOT.  TSNAP recognizes many keywords for PLOT and WIN (or WINDOW).  See the 
;; header of tsnap.pro for more information.
;;
;; Use this to determine if color variations are significant.

key = {err:1, yrange:[1e3,1e9], ylog:1, psym:10, charsize:1.5, xsize:800, ysize:1000}
tsnap, var1, key=key, navg=5

end ; of crib
;-
