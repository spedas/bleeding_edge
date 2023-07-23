;+
;PROCEDURE showct
;   Show the specified color table in a new window.  Does not alter the current
;   color table.
;
;USAGE:
;   showct [, n] [, KEYWORD=value, ...]
;
;INPUTS:
;   n:         Color table number.  Standard tables have n < 1000.  CSV tables
;              have n >= 1000.  See 'initct' for details.  If n is not provided,
;              show the current color table.
;
;KEYWORDS:
;   REVERSE:   If set, then reverse the table order from bottom_c to top_c.
;
;   LINE_CLRS: Show an alternate line scheme.  See line_colors.pro.
;
;   COLOR_NAMES: Names of custom line colors.  See line_colors.pro.
;
;   MYCOLORS:  Structure of custom line colors.  See line_colors.pro.
;
;   GRAYBKG:   Set background color to gray.  See line_colors.pro.
;
;   INTENSITY: Show intensity in a separate window.
;
;   KEY:       Structure of win options.  Window dimensions of 600x600
;              cannot be overridden.
;
;   CNUM:      Returns the window number chosen for the color table plot.
;
;   TNUM:      Returns the window number chosen for the intensity plot.
;
;   RESET:     Forgets any window numbers.
;
;SEE ALSO:
;   xpalette:  Shows the current color table in an interactive widget.  Provides
;              more functionality, but only for the current color table.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-03-25 15:25:34 -0700 (Sat, 25 Mar 2023) $
; $LastChangedRevision: 31666 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/showct.pro $
;-
pro showct, color_table, reverse=color_reverse, line_clrs=lines, mycolors=mycolors, $
                         color_names=color_names, graybkg=graybkg, intensity=intensity, $
                         key=key, cnum=cnum2, tnum=tnum2, reset=reset

  common showct_com, cnum, tnum

  cols = get_colors()
  crev = keyword_set(color_reverse)
  wnum = !d.window

  cwinkey = {secondary:1, dx:10, dy:-10}
  if (size(key,/type) eq 8) then begin
    ktag = tag_names(key)
    for j=0,(n_elements(ktag)-1) do str_element, cwinkey, ktag[j], key.(j), /add
  endif
  str_element, cwinkey, 'xsize', 600, /add
  str_element, cwinkey, 'ysize', 600, /add
  twinkey = {xsize:600, ysize:600, dx:10, top:1}

; If previous window(s) have been deleted or resized, then forget them

  if keyword_set(reset) then begin
    undefine, cnum
    undefine, tnum
  endif else begin
    device, window_state=wstate
    if (size(cnum,/type) ne 0) then if wstate[cnum] then begin
        wset, cnum
        if ((!d.x_size ne 600) || (!d.y_size ne 600)) then undefine, cnum
        wset, wnum
      endif else undefine, cnum
    if (size(tnum,/type) ne 0) then if wstate[tnum] then begin
        wset, tnum
        if ((!d.x_size ne 600) || (!d.y_size ne 600)) then undefine, tnum
        wset, wnum
      endif else undefine, tnum
  endelse

; Load the requested color table

  if (n_elements(color_table) gt 0) then begin
    ctab = fix(color_table[0])
    initct,ctab,previous_ct=pct,reverse=crev,previous_rev=prev
  endif else begin
    ctab = cols.color_table
    pct = ctab
    if (crev && (ctab ge 0)) then begin
      initct,ctab,previous_ct=pct,reverse=crev,previous_rev=prev
    endif else begin
      crev = cols.color_reverse
      prev = crev
    endelse
  endelse

  if (ctab lt 0) then begin
    print,"Color table not defined."
    return
  endif

; Load the requested line colors

  if ((n_elements(lines) gt 0) or (size(mycolors,/type) eq 8) or $
      (size(color_names,/type) eq 7) or keyword_set(graybkg)) then begin
    line_colors, lines, color_names=color_names, mycolors=mycolors, graybkg=graybkg, previous_lines=plines
  endif else begin
    lines = get_line_colors()
    plines = lines
  endelse

; Plot the table in a grid of filled squares

  if (size(cnum,/type) eq 0) then win,cnum,/free,key=cwinkey else wset,cnum
  cnum = !d.window & cnum2 = cnum
  plot,[-1],[-1],xrange=[0,4],yrange=[0.5,6.5],xstyle=5,ystyle=5,xmargin=[0.1,0.1],ymargin=[0.1,0.1]
  k = indgen(16)*16

  usersym,[-1,-1,1,1,-1],[-1,1,1,-1,-1],/fill
  for j=0,15 do for i=k[j],k[j]+15 do oplot,[float(i mod 16)/4.5 + 0.35],[6. - float(j)/3.],$
                                            psym=8,color=i,symsize=4

  usersym,[-1,-1,1,1,-1],[-1,1,1,-1,-1]
  for j=0,15 do for i=k[j],k[j]+15 do oplot,[float(i mod 16)/4.5 + 0.35],[6. - float(j)/3.],$
                                            psym=8,color=!p.color,symsize=4,thick=2

  msg = 'Color Table ' + strtrim(string(ctab),2)
  if (crev) then msg = msg + ' (reverse)'
  xyouts,2.0,6.25,msg,align=0.5,charsize=1.8

; Show color indices along the left margin

  x = 0.23
  y = 5.97 - findgen(16)/3.
  nums = strtrim(string(16*indgen(16)),2)
  for i=0,15 do xyouts,x,y[i],nums[i],align=1.0,charsize=1.2

; Identify the bottom and top colors

  tvlct, r, g, b, /get

  pen = !p.color
    i = sqrt(float(r)^2. + float(g)^2. + float(b)^2.)
    i_min = min(i, dark)
    i_max = max(i, lite)
    i_avg = sqrt(3.*(127.5*127.5))

    !p.color = (i[cols.bottom_c] gt i_avg) ? dark : lite
    x = [float(cols.bottom_c mod 16)/4.5 + 0.35]
    y = [5.95 - float(cols.bottom_c/16)/3.]
    xyouts,x,y,"B",align=0.5,charsize=1.4

    !p.color = (i[cols.top_c] gt i_avg) ? dark : lite
    x = [float(cols.top_c mod 16)/4.5 + 0.35]
    y = [5.95 - float(cols.top_c/16)/3.]
    xyouts,x,y,"T",align=0.5,charsize=1.4
  !p.color = pen

; Show intensity plot

  if keyword_set(intensity) then begin
    lines = 5
    line_colors, lines
    x = findgen(256)
    n = 100./sqrt(3.*(255.^2.))
    bot = cols.bottom_c
    top = cols.top_c
    if (size(tnum,/type) eq 0) then win,tnum,/free,relative=cnum,key=twinkey else wset,tnum
    tnum = !d.window & tnum2 = tnum
    plot,[-1.],[-1.],xrange=[0,256],/xsty,yrange=[0,100],/ysty,charsize=1.4, $
         title=msg,ytitle='Intensity (%)',xtitle='Color Index',xticks=4,xminor=8
    oplot,x,i*n,psym=10
    oplot,x[bot:top],float(r[bot:top])*n,psym=10,color=6
    oplot,x[bot:top],float(g[bot:top])*n,psym=10,color=4
    oplot,x[bot:top],float(b[bot:top])*n,psym=10,color=2
  endif

; Restore the initial color table and line colors

  wset, wnum
  if (ctab ne pct || crev ne prev) then initct,pct,reverse=prev
  if (max(abs(lines - plines)) gt 0) then line_colors, plines

end
