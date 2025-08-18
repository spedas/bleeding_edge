;+
;PROCEDURE showct
;   Show the specified color table and line colors in a new window.  Does not
;   alter the current color table.  Can also show a catalog of color tables.
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
;   GRAYBKG:   Set background color to gray.  See line_colors.pro.  For this to
;              work properly, !p.background must be set to 255 (see keyword
;              WHITE below, or see color_table_crib.pro).
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
;   CATALOG:   Show a catalog of available color tables as a grid of color bars,
;              with the table number below each bar.  Color bars are shown for 
;              the current catalog, unless you choose a different one with of
;              the following four keywords.
;
;   STD:       Use the standard (n < 1000) or csv (n >= 1000) color tables for
;              both the catalog and the table number specified by n.  This is
;              equivalent to FILE=''.
;
;   SPP:       Use the SPP Fields color tables for both the catalog and the table
;              number specified by n.
;
;   FILE:      Use the color table defined by this file (full path and filename)
;              for both the catalog and the table number specified by n.  Set
;              this keyword to the null string ('') to use the standard (n < 1000)
;              or csv (n >= 1000) tables.
;
;   BLACK:     Temporarily use a black background.  Default is !p.background.
;
;   WHITE:     Temporarily use a white background.  Default is !p.background.
;              (This keyword is ignored if BLACK is set.)
;
;SEE ALSO:
;   xpalette:  Shows the current color table in an interactive widget.  Provides
;              more functionality, but only for the current color table.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-02-03 13:34:12 -0800 (Mon, 03 Feb 2025) $
; $LastChangedRevision: 33110 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/showct.pro $
;-
pro showct, color_table, reverse=color_reverse, line_clrs=lines, mycolors=mycolors, $
                         color_names=color_names, graybkg=graybkg, intensity=intensity, $
                         key=key, cnum=cnum2, tnum=tnum2, bnum=bnum2, reset=reset, $
                         catalog=cat, std=std, spp=spp, file=file, black=black, $
                         white=white

  common showct_com, cnum, tnum, bnum

  cols = get_colors()
  pct = cols.color_table
  prev = cols.color_reverse
  plndx = cols.line_colors_index
  plines = get_line_colors()
  ct_file = cols.ct_file
  ct_max = cols.ct_max

  wnum = !d.window
  if keyword_set(black) then white = 0
  vswap = (keyword_set(black) and (!p.background ne 0L)) or (keyword_set(white) and (!p.background eq 0L))
  if (size(file,/type) eq 7) then usr = (file ne '') else usr = 0
  std = keyword_set(std)
  spp = keyword_set(spp)
  nset = usr + std + spp
  if (nset gt 1) then begin
    print,"  You can only specify one set of color tables."
    return
  endif
  if (std) then file = ''

; Get window parameters for individual color tables and catalog

  cwinkey = {secondary:1, dx:10, dy:-10}
  if (size(key,/type) eq 8) then begin
    ktag = tag_names(key)
    for j=0,(n_elements(ktag)-1) do str_element, cwinkey, ktag[j], key.(j), /add
  endif
  str_element, cwinkey, 'xsize', 600, /add
  str_element, cwinkey, 'ysize', 600, /add
  twinkey = {xsize:600, ysize:600, dx:10, top:1}
  bwinkey = {secondary:1, xsize:1000, ysize:764, dx:10, dy:10}

; If previous window(s) have been deleted or resized, then forget them

  if keyword_set(reset) then begin
    undefine, cnum
    undefine, tnum
    undefine, bnum
  endif else begin
    device, window_state=wstate
    if (size(cnum,/type) ne 0) then if wstate[cnum] then begin
        wset, cnum
        if ((!d.x_size ne cwinkey.xsize) || (!d.y_size ne cwinkey.ysize)) then undefine, cnum
        wset, wnum
      endif else undefine, cnum
    if (size(tnum,/type) ne 0) then if wstate[tnum] then begin
        wset, tnum
        if ((!d.x_size ne twinkey.xsize) || (!d.y_size ne twinkey.ysize)) then undefine, tnum
        wset, wnum
      endif else undefine, tnum
    if (size(bnum,/type) ne 0) then if wstate[bnum] then begin
        wset, bnum
        if ((!d.x_size ne bwinkey.xsize) || (!d.y_size ne bwinkey.ysize)) then undefine, bnum
        wset, wnum
      endif else undefine, bnum
  endelse

; Set the background color

  if (vswap) then revvid

; Load the requested color table

  if (n_elements(color_table) gt 0) then begin
    ctab = fix(color_table[0])
    crev = keyword_set(color_reverse)
  endif else begin
    ctab = pct
    crev = (n_elements(color_reverse) gt 0) ? keyword_set(color_reverse) : prev
  endelse
  if ((ctab ne pct) or (crev ne prev)) then begin
    initct, ctab, rev=crev, spp=spp, file=file, success=ok
    if (not ok) then goto, bail
  endif
  mcols = get_colors()

; Load the requested line colors

  if ((n_elements(lines) gt 0) or (size(mycolors,/type) eq 8) or $
      (size(color_names,/type) eq 7) or keyword_set(graybkg)) then begin
    line_colors, lines, color_names=color_names, mycolors=mycolors, graybkg=graybkg, success=ok
    if (not ok) then goto, bail
    newcols = get_colors()
    lndx = newcols.line_colors_index
  endif else begin
    lines = plines
    lndx = plndx
  endelse
  mlines = get_line_colors()

; Show a catalog of color tables in a big window

  if keyword_set(cat) then begin
    if (size(bnum,/type) eq 0) then win,bnum,/free,key=bwinkey else wset,bnum
    bnum = !d.window & bnum2 = bnum
    ncols = mcols.top_c - mcols.bottom_c + 1
    x = float(mcols.bottom_c) + findgen(ncols)
    y = [0.,1.]
    z = x # replicate(1.,2)
    lim = {no_interp:1, no_color_scale:1, xrange:minmax(x), xstyle:5, yrange:minmax(y), ystyle:5, $
           zrange:minmax(z), noerase:1}

    ncols = 7
    nrows = 20
    dx = 1./float(ncols)
    dy = 1./(float(nrows) + 1.5)
    mx = 0.015
    my = 0.010

    if (ctab ge 1000) then begin
      imax = 118
      ioff = 1000
      tmsg = 'CSV Color Tables'
    endif else begin
      imax = mcols.ct_max
      ioff = 0
      cfile = file_basename(mcols.ct_file,'.tbl')
      case cfile of
        ''               : cmsg = 'Standard'
        'spp_fld_colors' : cmsg = 'SPP Fields'
        else             : cmsg = cfile
      endcase
      tmsg = cmsg + ' Color Tables'
    endelse

    erase
    xyouts, 0.5, (1. - dy/2. - my), tmsg, align=0.5, charsize=1.8, /norm
    for i=0,imax do begin
      px = 0. + dx*float(i/nrows)
      py = 1. - dy*float(i mod nrows) - dy
      initct, i+ioff, spp=spp, file=file, success=ok
      if (not ok) then goto, bail
      str_element, lim, 'position', [px+mx, py-dy+my, px+dx-mx, py-my], /add
      specplot, x, y, z, limits=lim
      xyouts, (px + dx/2.), (py - dy - my/2.), string(i+ioff,format='(i4)'), align=0.5, charsize=1.1, /norm
    endfor
    initct, mcols.color_table, rev=mcols.color_reverse, file=mcols.ct_file, line=mlines
  endif

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

  cfile = file_basename(mcols.ct_file,'.tbl')
  case cfile of
    ''               : cmsg = ''
    'spp_fld_colors' : cmsg = 'SPP '
    else             : cmsg = cfile
  endcase
  if (ctab ge 1000) then cmsg = 'CSV '

  msg = cmsg + 'Color Table ' + strtrim(string(ctab),2)
  if (crev) then msg = msg + ' (reverse)'
  msg = msg + '  :  Line Colors ' + strtrim(string(lndx),2)
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
    oplot,x[bot:top],i[bot:top]*n,psym=10
    oplot,x[bot:top],float(r[bot:top])*n,psym=10,color=6
    oplot,x[bot:top],float(g[bot:top])*n,psym=10,color=4
    oplot,x[bot:top],float(b[bot:top])*n,psym=10,color=2
  endif

; Restore the initial color table and line colors

  bail:
  wset, wnum
  if (vswap) then revvid
  initct, pct, rev=prev, line=plines, file=ct_file

end
