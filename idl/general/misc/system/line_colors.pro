;+
;PROCEDURE line_colors
;   Alters one or more of the fixed colors (indices 0-6 and 255) without changing
;   the color table.  This includes the line colors (1-6) and the background (0) 
;   and foreground (255) colors.
;
;USAGE:
;  line_colors [, line_clrs] [, KEYWORD=value, ...]  ; normal usage
;
;  line_colors, /catalog  ; display a catalog of pre-defined line color schemes
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
;    CATALOG:      Show the pre-defined line color schemes in a separate window.
;
;    BLACK:        Temporarily use a black background for the catalog.
;                  Default is !p.background.
;
;    WHITE:        Temporarily use a white background for the catalog.
;                  Default is !p.background.
;                  (This keyword is ignored if BLACK is set.)
;
;    KEY:          Structure of win options for the catalog window.
;                  Window dimensions of 600x600 cannot be overridden.
;
;    LNUM:         Returns the window number chosen for the catalog plot.
;
;    RESET:        Forget the window number for the catalog plot.
;
;    SUCCESS:      Returns 1 if the routine finishes normally, 0 otherwise.
;
;SEE ALSO:
;    get_line_colors() : Works like this routine, but returns a 24 element array
;                  instead of asserting the new line colors.  Allows you to define
;                  a custom set of line colors in a format that you can use as an
;                  option for a tplot variable.
;
;    initct :      Loads a color table without changing the line colors, except by
;                  keyword.
;
;common blocks:
;   colors:      IDL color common block.  Many IDL routines rely on this.
;   colors_com:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-06-25 14:27:16 -0700 (Thu, 25 Jun 2026) $
; $LastChangedRevision: 34605 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/line_colors.pro $
;
;Created by David Mitchell;  February 2023
;-

pro line_colors, line_clrs, color_names=color_names, mycolors=mycolors, graybkg=graybkg, $
                        catalog=catalog, key=key, previous_lines=previous_lines, $
                        black=black2, white=white2, lnum=lnum2, reset=reset, success=ok

  common line_colors_com, lnum
  common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
  @colors_com

  ok = 0
  tvlct,r,g,b,/get

  previous_lines = get_line_colors()
  nmax = n_elements(line_colors_presets[0,0,*]) - 1

; Display the line color schemes in a separate window

  if keyword_set(catalog) then begin
    wnum = !d.window
    if keyword_set(black2) then white2 = 0
    vswap = (keyword_set(black2) and (!p.background ne 0L)) or (keyword_set(white2) and (!p.background eq 0L))

    lwinkey = {scale:1}
    if (size(key,/type) eq 8) then begin
      ktag = tag_names(key)
      for j=0,(n_elements(ktag)-1) do str_element, lwinkey, ktag[j], key.(j), /add
    endif else lwinkey = {secondary:1, dx:10, dy:-10}
    str_element, lwinkey, 'xsize', 600, /add
    str_element, lwinkey, 'ysize', 600, /add

    if ~keyword_set(reset) then begin
      device, window_state=wstate
      if (size(lnum,/type) ne 0) then if wstate[lnum] then begin
          wset, lnum
          if ((!d.x_size ne lwinkey.xsize) || (!d.y_size ne lwinkey.ysize)) then undefine, lnum
          wset, wnum
        endif else undefine, lnum
    endif else undefine, lnum

    if (vswap) then revvid

    if (size(lnum,/type) eq 0) then win,lnum,/free,key=lwinkey else wset,lnum
    lnum = !d.window & lnum2 = lnum
    line_colors, 0, previous_lines=plines

    plot,[-1],[-1],xrange=[0,4],yrange=[0.5,6.5],xstyle=5,ystyle=5,xmargin=[0.1,0.1],ymargin=[0.1,0.1]
    k = [indgen(7), 255]
    for j=0,nmax do begin
      tlines = j
      line_colors, tlines
      usersym,[-1,-1,1,1,-1],[-1,1,1,-1,-1],/fill
      for i=0,7 do oplot,[float(i)/4.5 + 0.35],[6. - float(j)/3.],psym=8,color=k[i],symsize=4
      usersym,[-1,-1,1,1,-1],[-1,1,1,-1,-1]
      for i=0,7 do oplot,[float(i)/4.5 + 0.35],[6. - float(j)/3.],psym=8,color=!p.color,symsize=4,thick=2
    endfor

    xyouts,1.125,6.25,'Line Color Schemes',align=0.5,charsize=1.8
    x = 0.23
    y = 5.97 - findgen(nmax+2)/3.
    for i=0,nmax do xyouts,x,y[i],i,align=1.0,charsize=1.2

    x = 2.06
    note = ['primary & secondary','','','','', $
            'primary & secondary (yellow -> orange)', $
            'primary & secondary (yellow -> gray)', $
            'Nature Methods 8, 441 (2011)', $
            'Nature Methods 8, 441 (2011)', $
            'Nature Methods 8, 441 (2011)', $
            'Chaffin CSV', $
            'primary & secondary (green -> dark green)']
    for i=0,nmax do xyouts,x,y[i],note[i],align=0,charsize=1.2

    x = findgen(i)/4.48 + 0.35
    y = y[nmax+1] + 0.08
    xlab = strtrim(string(k),2)
    for i=0,7 do xyouts,x[i],y,xlab[i],align=0.5,charsize=1.2

    line_colors, plines
    if (vswap) then revvid
    wset, wnum
  endif

; Make sure line_clrs has one of the allowed formats

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

; Change the line colors

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
