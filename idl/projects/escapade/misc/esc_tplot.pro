;+
;
;PROCEDURE:       ESC_TPLOT
;
;PURPOSE:         Wrapper for MPLOT and SPECPLOT dedicated to the ESCAPADE mission.
;
;INPUTS:          Same as those of MPLOT and SPECPLOT
;
;KEYWORDS:
;
;      DATA:      Structure containing the elements 'x', 'y', ['v', 'dy'].
;
;    LIMITS:      Structure containing any combination of the plotting options.
;
;CREATED BY:      Takuya Hara on 2021-02-04.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-08-18 13:40:41 -0700 (Tue, 18 Aug 2026) $
; $LastChangedRevision: 34766 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/misc/esc_tplot.pro $
;
;-
PRO esc_tplot, data=data, limits=lim, _extra=ext
  str_element, lim, 'psym', value=psym
  IF ~undefined(psym) THEN BEGIN
     IF (ABS(psym) GT 8) AND (ABS(psym) NE 10) THEN BEGIN
        symbol = symcat(ABS(psym))
        str_element, lim, 'psym', sign(psym) * TEMPORARY(symbol), /add_replace
     ENDIF
  ENDIF
  undefine, psym
  
  str_element, lim, 'ct', value=ct
  IF ~undefined(ct) THEN BEGIN
     TVLCT, red0, green0, blue0, /get
     ;IF is_string(ct) THEN make_loadct2, file=ct, /keep
     ;IF is_struct(ct) THEN make_loadct2, _extra=ct
     IF ndimen(ct) EQ 2 THEN BEGIN
        IF dimen2(ct) EQ 3 THEN BEGIN
           ncol = dimen1(ct)
           TVLCT, ct
        ENDIF ELSE BEGIN
           ncol = dimen2(ct)
           TVLCT, TRANSPOSE(ct)
        ENDELSE 
        IF ncol LT 256 THEN IF ~tag_exist(lim, 'top', /quiet) THEN str_element, lim, 'top', ncol-2, /add
     ENDIF

     TVLCT, red, green, blue, /get
  ENDIF 

  str_element, lim, 'graybkg', value=graybkg
  IF ~undefined(graybkg) THEN BEGIN
     IF undefined(red0) THEN TVLCT, red0, green0, blue0, /get
     IF undefined(red) THEN BEGIN
        red   = red0
        green = green0
        blue  = blue0
     ENDIF

     IF N_ELEMENTS(graybkg) EQ 3 THEN BEGIN
        red[-1]   = graybkg[0]
        green[-1] = graybkg[1]
        blue[-1]  = graybkg[2]
     ENDIF ELSE BEGIN
        red[-1]   = graybkg[0]
        green[-1] = graybkg[0]
        blue[-1]  = graybkg[0]
     ENDELSE 
     TVLCT, red, green, blue
        
     xw = [lim.position[0], lim.position[2]]
     yw = [lim.position[1], lim.position[3]]

     POLYFILL, [xw[0], xw[1], xw[1], xw[0]], [yw[0], yw[0], yw[1], yw[1]], /normal, color=255
  ENDIF 

  str_element, lim, 'cshift', value=cshift
  IF ~undefined(cshift) THEN BEGIN
     str_element, lim, 'top', value=top
     IF undefined(top) THEN top = !d.table_size-2
     str_element, lim, 'top', TEMPORARY(top) + 1 - 1.e-5, /add_replace
  ENDIF 

  IF tag_exist(lim, 'ytitle_color', /quiet) THEN IF lim.overplot EQ 0 THEN BEGIN
     ytcol = lim.ytitle_color

     tags  = TAG_NAMES(lim)
     w = WHERE(STRMATCH(tags, 'Y*') EQ 1, nw)
     IF nw GT 0 THEN extract_tags, axisy, lim, tags=tags[w]
     IF tag_exist(lim, 'charsize', /quiet) THEN str_element, axisy, 'charsize', lim.charsize, /add
     
     IF tag_exist(axisy, 'ysubtitle', /quiet) THEN BEGIN
        ytit1 = axisy.ytitle
        ytit2 = axisy.ysubtitle

        ytit1 = ytit1.replace(ytit2, '')
        IF ytit2.contains('!C') THEN BEGIN
           ytit2 = STRSPLIT(ytit2, '!C', /extract)
           ytit2[*] = ''
           ytit2 = STRJOIN(ytit2, '!C')
        ENDIF ELSE ytit2 = ''

        str_element, axisy, 'ytitle', ytit1 + ytit2, /add_replace

        lim.ytitle = (lim.ytitle).replace(ytit1, '!C')
        undefine, ytit1, ytit2
     ENDIF 

     str_element, axisy, 'color', ytcol, /add

     extract_tags, plotstuff, lim, /plot
     str_element, plotstuff, 'xrange', value=ytcol_xr
     IF ~tag_exist(plotstuff, 'yrange', /quiet) THEN BEGIN
        w = WHERE(FINITE(data.x) AND (data.x GE lim.xrange[0] AND data.x LE lim.xrange[1]))
        ytcol_yr = minmax(data.y[w, *])
        str_element, plotstuff, 'ystyle', 4, /add
     ENDIF ELSE BEGIN
        ytcol_yr = plotstuff.yrange
        str_element, plotstuff, 'ystyle', 5, /add
     ENDELSE 
     str_element, plotstuff, 'xstyle', 5, /add_replace

     box, TEMPORARY(plotstuff), TEMPORARY(ytcol_xr), TEMPORARY(ytcol_yr)

     AXIS, yaxis=0, _extra=TEMPORARY(axisy)
  ENDIF 
  
  str_element, lim, 'spec', value=spec
  IF SIZE(spec, /type) EQ 0 THEN spec = 0
  str_element, lim, 'hbar', value=hbar
  IF undefined(hbar) THEN hbar = 0
  IF (hbar) THEN spec = 1
  
  IF (spec) THEN BEGIN
     IF (hbar) THEN BEGIN
        str_element, data, 'y', [ [data.y], [data.y] ], /add_replace
        str_element, data, 'v', [0., 1.], /add

        str_element, lim, 'no_color_scale', 1, /add
        str_element, lim, 'xstyle', 5, /add
        IF ~tag_exist(lim, 'ystyle', /quiet) THEN str_element, lim, 'ystyle', 5, /add

        str_element, lim, 'zrange', [0., 1.], /add
        str_element, lim, 'zstyle', 1, /add

        IF tag_exist(lim, 'colors', /quiet) THEN BEGIN
           str_element, lim, 'top', lim.colors, /add
           str_element, lim, 'bottom', 0, /add
        ENDIF 
     ENDIF

     specplot, data=data, limits=lim, _extra=ext
     
     IF tag_exist(lim, 'labels', /quiet) THEN BEGIN
        tdata = data
        tlim  = lim
        
        str_element, tlim, 'labels', value=labels
        str_element, tlim, 'ystyle', value=ystyle
        IF SIZE(ystyle, /type) EQ 0 THEN str_element, tlim, 'ystyle', 4, /add_replace $
        ELSE str_element, tlim, 'ystyle', 5, /add_replace
        str_element, tlim, 'xstyle', 4, /add_replace
        str_element, tlim, 'nodata', 1, /add

        str_element, tdata, 'y', tdata.y[*, 0:N_ELEMENTS(labels)-1], /add_replace
        mplot, data=TEMPORARY(tdata), limits=TEMPORARY(tlim)
     ENDIF 
  ENDIF ELSE BEGIN
     str_element, lim, 'bins', value=bins
     IF ~undefined(bins) THEN BEGIN
        tlim = lim
        w = WHERE(bins EQ 1, nw)
        IF nw GT 0 THEN BEGIN
           str_element, data, 'y', data.y[*, w], /add_replace
           IF tag_exist(data, 'dy', /quiet) THEN str_element, data, 'dy', data.dy[*, w], /add_replace
           IF tag_exist(tlim, 'colors', /quiet) THEN str_element, tlim, 'colors', tlim.colors[w], /add_replace
           IF tag_exist(tlim, 'labels', /quiet) THEN str_element, tlim, 'labels', tlim.labels[w], /add_replace
        ENDIF 
        str_element, tlim, 'bins', /delete
     ENDIF 

     str_element, lim, 'max_points', value=max_points
     IF ~undefined(max_points) THEN BEGIN
        str_element, lim, 'datagap', value=dg
        nd = ndimen(data.y)
        
        IF nd GT 1 THEN nd = dimen2(data.y)

        FOR i=0, nd-1 DO BEGIN
           xt = data.x
           yt = data.y[*, i]
           IF tag_exist(data, 'dy', /quiet) THEN dyt = data.dy[*, i]

           mplot_downsample_data, max_points, xt, yt, dy=dyt, dg=dg

           IF i EQ 0 THEN BEGIN
              tdata = {x: xt}
              str_element, tdata, 'y', data.y[0:N_ELEMENTS(xt)-1, 0:nd-1], /add
              IF ~undefined(dyt) THEN str_element, tdata, 'dy', data.dy[0:N_ELEMENTS(xt)-1, 0:nd-1], /add
           ENDIF 

           tdata.x = TEMPORARY(xt)
           tdata.y[*, i] = TEMPORARY(yt)
           IF ~undefined(dyt) THEN tdata.dy[*, i] = TEMPORARY(dyt)
        ENDFOR
        data = TEMPORARY(tdata)
        undefine, nd, dg
     ENDIF 
     
     str_element, lim, 'databar', value=dbar
     IF ~undefined(dbar) THEN BEGIN
        tlim = lim

        str_element, tlim, 'ystyle', value=ystyle
        IF undefined(ystyle) THEN ystyle = 4 ELSE ystyle = 5
        str_element, tlim, 'ystyle', ystyle, /add_replace
        str_element, tlim, 'xstyle', 5, /add_replace
        str_element, tlim, 'clip', [-1., 0., 0., 1.], /add

        str_element, tlim, 'labels', value=labels
        IF ~undefined(labels) THEN str_element, tlim, 'labels', /delete
        mplot, data=data, limits=TEMPORARY(tlim)

        extract_tags, lbar, dbar, /oplot
        IF tag_exist(dbar, 'fill', /quiet) THEN BEGIN
           FOR ibar=0, N_ELEMENTS(dbar)-1 DO BEGIN
              extract_tags, lbar, dbar[ibar], except=['yval', 'fill']
              POLYFILL, [lim.xrange, REVERSE(lim.xrange)], [REPLICATE(dbar[ibar].yval[0], 2), REPLICATE(dbar[ibar].yval[1], 2)], _extra=TEMPORARY(lbar), /data
           ENDFOR 
        ENDIF ELSE FOR ibar=0, N_ELEMENTS(dbar.yval)-1 DO OPLOT, lim.xrange, REPLICATE(dbar.yval[ibar], 2), _extra=lbar

        str_element, lim, 'databar', /delete
     ENDIF 

     plots = 0
     draw_cscale = 0
     str_element, lim, 'colors', value=colors
     IF ~undefined(colors) THEN IF (N_ELEMENTS(colors) EQ N_ELEMENTS(data.x)) THEN plots = 1
     ;IF tag_exist(data, 'v', /quiet) AND (dimen1(data.x) EQ dimen1(data.v)) THEN BEGIN
     IF tag_exist(data, 'v', /quiet) THEN IF ( (dimen1(data.y) EQ dimen1(data.v)) OR (dimen2(data.y) EQ dimen1(data.v)) ) THEN BEGIN
        draw_cscale = 1
        IF dimen1(data.x) EQ dimen1(data.v) THEN plots = 1

        IF (plots) THEN BEGIN
           str_element, lim, 'datagap', dg
           IF ~undefined(dg) THEN BEGIN
              gy = data.y
           
              IF tag_exist(data, 'v', /quiet) THEN BEGIN
                 gx = data.x
                 gv = data.v
                 makegap, dg, gx, gv
              ENDIF 
              IF ~undefined(colors) THEN BEGIN
                 gx  = data.x
                 gdy = colors
                 makegap, dg, gx, gdy
              ENDIF 

              gx = data.x
              makegap, dg, gx, gy
           
              data = {x: TEMPORARY(gx), y: TEMPORARY(gy)}
              IF ~undefined(gv)  THEN str_element, data, 'v', TEMPORARY(gv), /add_replace
              IF ~undefined(gdy) THEN colors = TEMPORARY(gdy)
           ENDIF
        ENDIF 
        
        IF undefined(colors) THEN BEGIN
           atags = TAG_NAMES(lim)
           w = WHERE(atags.matches('^Z+') EQ 1, nw)
           IF nw GT 0 THEN ztags = atags[w]
           append_array, ztags, ['bottom', 'top', 'charsize']

           extract_tags, zlim, lim, tags=ztags
           IF tag_exist(zlim, 'zrange', /quiet) THEN zrange = zlim.zrange ELSE zrange = minmax(data.v)
           IF tag_exist(zlim, 'zlog', /quiet) THEN zlog = zlim.zlog ELSE zlog = 0
           IF tag_exist(zlim, 'bottom', /quiet) THEN bottom = zlim.bottom ELSE bottom = 7
           IF tag_exist(zlim, 'top', /quiet) THEN top = zlim.top ELSE top = 254
           colors = colorscale(((zlog) ? ALOG10(data.v) : data.v), mind=zrange[0], maxd=zrange[1], minc=bottom, maxc=top)
        ENDIF
     ENDIF 
     
     IF (plots) THEN BEGIN
        tlim = lim
        str_element, tlim, 'ystyle', value=ystyle
        IF undefined(ystyle) THEN ystyle = 4 ELSE ystyle = 5
        str_element, tlim, 'ystyle', ystyle, /add_replace
        str_element, tlim, 'xstyle', 5, /add_replace
        str_element, tlim, 'clip', [-1., 0., 0., 1.], /add

        str_element, tlim, 'labels', value=labels
        IF ~undefined(labels) THEN str_element, tlim, 'labels', /delete

        mplot, data=data, limits=TEMPORARY(tlim)
        extract_tags, tlim, lim, tags=['linestyle', 'psym', 'symsize', 'thick', 'colorder']
        clip = [(CONVERT_COORD(lim.position[0:1], /normal, /to_data))[0:1], (CONVERT_COORD(lim.position[2:3], /normal, /to_data))[0:1]]

        oflg = 0
        IF tag_exist(tlim, 'psym', /quiet) THEN IF FIX(tlim.psym) EQ 10 THEN oflg = 1
        IF (oflg) THEN BEGIN
           ucol = spd_uniq(colors)
           FOR i=0L, N_ELEMENTS(ucol)-1 DO BEGIN
              ydata = data.y
              c = WHERE(colors NE ucol[i], nc)
              IF nc GT 0 THEN ydata[c, *] = !values.f_nan
              OPLOT, data.x, TEMPORARY(ydata), color=ucol[i], noclip=0, clip=clip, _extra=(i EQ N_ELEMENTS(ucol)-1 ? TEMPORARY(tlim) : tlim)
           ENDFOR 
        ENDIF ELSE BEGIN
           IF tag_exist(tlim, 'colorder', /quiet) THEN BEGIN
              FOR i=0, N_ELEMENTS(tlim.colorder)-1 DO BEGIN
                 ydata = data.y
                 c = WHERE(colors NE tlim.colorder[i], nc)
                 IF nc GT 0 THEN ydata[c, *] = !values.f_nan
                 OPLOT, data.x, TEMPORARY(ydata), color=tlim.colorder[i], noclip=0, clip=clip, _extra=(i EQ N_ELEMENTS(tlim.colorder)-1 ? TEMPORARY(tlim) : tlim)
              ENDFOR 
           ENDIF ELSE $
              PLOTS, data.x, data.y, color=colors, /data, noclip=0, _extra=TEMPORARY(tlim), clip=clip
        ENDELSE
 
        tlim = lim
        str_element, tlim, 'clip', [-1., 0., 0., 1.], /add
        IF ~undefined(labels) THEN str_element, data, 'y', REBIN(data.y, N_ELEMENTS(data.x), N_ELEMENTS(labels), /sample), /add_replace
        str_element, tlim, 'labcolor', value=labcolor
        IF ~undefined(labcolor) THEN str_element, tlim, 'colors', labcolor, /add_replace
     ENDIF 

     IF tag_exist(lim, 'axis', /quiet) THEN BEGIN
        str_element, lim, 'axis', value=aopt
        IF ~tag_exist(aopt, 'charsize', /quiet) THEN IF tag_exist(lim, 'charsize', /quiet) THEN str_element, aopt, 'charsize', lim.charsize, /add
        IF tag_exist(aopt, 'normal') THEN BEGIN
           IF tag_exist(lim, 'ystyle', /quiet) THEN IF lim.ystyle GE 8 THEN str_element, aopt, 'ystyle', 4, /add
        ENDIF 
        str_element, lim, 'axis', TEMPORARY(aopt), /add_replace
     ENDIF 
     
     str_element, lim, 'y2axis', value=y2axis
     IF SIZE(y2axis, /type) NE 0 THEN BEGIN
        tlim = lim
        str_element, tlim, 'overplot', 0, /add_replace

        str_element, tlim, 'ystyle', value=ystyle
        str_element, tlim, 'yaxis',  value=yaxis
        IF SIZE(yaxis, /type) EQ 0 THEN yaxis = 0

        IF (y2axis) THEN BEGIN
           str_element, tlim, 'xstyle', 5, /add_replace
           IF SIZE(ystyle, /type) EQ 0 THEN str_element, tlim, 'ystyle', 4, /add_replace $
           ELSE str_element, tlim, 'ystyle', 5, /add_replace

           IF tag_exist(tlim, 'y2range', /quiet) THEN str_element, tlim, 'yrange', tlim.y2range, /add_replace

           IF (yaxis EQ 1) THEN BEGIN
              tags = tag_names(tlim)

              w = WHERE(STRMATCH(tags, 'Y*') EQ 1, nw)
              IF nw GT 0 THEN extract_tags, aopt, tlim, tags=tags[w]

              w = WHERE(STRMATCH(tags, 'Y2*') EQ 1, nw)
              str_element, aopt, 'charsize', tlim.charsize, /add
              FOR i=0, nw-1 DO BEGIN
                 tag = STRSPLIT(tags[w[i]], '2', /extract)
                 IF STRUPCASE(tag[-1]) EQ 'COLOR' THEN str_element, aopt, tag[-1], tlim.(w[i]), /add $
                 ELSE str_element, aopt, 'y' + tag[-1], tlim.(w[i]), /add 
              ENDFOR 
              str_element, aopt, 'ymargin', /delete
              str_element, aopt, 'ygap', /delete
              str_element, aopt, 'y2axis', /delete
              str_element, aopt, 'ystyle', 1, /delete

              str_element, aopt, 'yrange', tlim.y2range, /add_replace
              str_element, aopt, 'ystyle', 1, /add
              str_element, tlim, 'axis', aopt, /add
           ENDIF 
        ENDIF ELSE BEGIN
           IF yaxis EQ 0 THEN BEGIN
              IF SIZE(ystyle, /type) EQ 0 THEN str_element, tlim, 'ystyle', 8, /add_replace $
              ELSE str_element, tlim, 'ystyle', 9, /add_replace
           ENDIF ELSE BEGIN
              str_element, tlim, 'xstyle', 5, /add_replace
              IF SIZE(ystyle, /type) EQ 0 THEN str_element, tlim, 'ystyle', 4, /add_replace $
              ELSE str_element, tlim, 'ystyle', 5, /add_replace
           ENDELSE 
        ENDELSE 
     ENDIF

     str_element, lim, 'cumulative', value=cumulative
     IF ~undefined(cumulative) THEN BEGIN
        ydata = TOTAL(data.y, 2, /cumulative)
        ydata = REVERSE(ydata, 2)
        str_element, data, 'y', ydata, /add_replace
        IF TAG_EXIST(lim, 'labels', /quiet) THEN str_element, lim, 'labels', REVERSE(lim.labels), /add_replace
        IF TAG_EXIST(lim, 'colors', /quiet) THEN str_element, lim, 'colors', REVERSE(lim.colors), /add_replace
     ENDIF
     
     str_element, lim, 'polyfill', value=pflg
     IF undefined(pflg) THEN pflg = 0
     IF (pflg NE 0) THEN BEGIN
        tdata = data
        tlim = lim
        IF tag_exist(tlim, 'labels') THEN str_element, tlim, 'labels', /delete
        str_element, tlim, 'xstyle', 5, /add_replace
        str_element, tlim, 'ystyle', value=ystyle
        IF undefined(ystyle) THEN ystyle = 4 ELSE ystyle = 5
        str_element, tlim, 'ystyle', ystyle, /add_replace
        str_element, tlim, 'clip', [-1., 0., 0., 1.], /add_replace
        mplot, data=tdata, limits=tlim

        str_element, tlim, 'colors', value=colors
        str_element, tlim, 'psym', value=psym
        IF undefined(psym) THEN psym = 0
        
        ndat = N_ELEMENTS(tdata.y[0, *])
        IF pflg LT 0 THEN BEGIN
           tdata.y = REVERSE(tdata.y, 2)
           colors = REVERSE(colors)
        ENDIF 
        
        ll = CONVERT_COORD(lim.position[0:1], /normal, /to_data) ; lower left corner pos in the data coord.
        ur = CONVERT_COORD(lim.position[2:3], /normal, /to_data) ; upper right corner pos in the data coord.
        FOR i=0, ndat-1 DO BEGIN
           xpos = [tdata.x[0] > ll[0], (tdata.x > ll[0]) < ur[0], tdata.x[-1] < ur[0], tdata.x[0] > ll[0]]
           ypos = [!y.crange[0] > ll[1], (tdata.y[*, i] > ll[1]) < ur[1], !y.crange[0] < ur[1], !y.crange[0] > ll[1]]

           IF psym EQ 10 THEN BEGIN
              xpos = (xpos[0:N_ELEMENTS(xpos)-2] + xpos[1:N_ELEMENTS(xpos)-1]) / 2.d0
              xpos = REBIN(xpos, N_ELEMENTS(xpos)*2, /sample)
              xpos = [xpos[0], xpos[0], xpos, xpos[-1], xpos[-1]]
              ypos = REBIN(ypos, N_ELEMENTS(ypos)*2, /sample)
              ypos = [ypos[0], ypos, ypos[-1]]
           ENDIF 
           
           POLYFILL, xpos, ypos, /data, color=colors[i];, clip=[!x.crange[0], !y.crange[0], !x.crange[1], !y.crange[1]]
        ENDFOR 
        tlim = lim
        str_element, tlim, 'clip', [-1., 0., 0., 1.], /add_replace

        IF tag_exist(tlim, 'colors', /quiet) AND tag_exist(tlim, 'labels', /quiet) THEN BEGIN
           w = WHERE(tlim.colors EQ !p.background, nw)
           IF nw GT 0 THEN BEGIN
              tlim.colors[w] = 0
              tlim.labels[w] = '(' + tlim.labels[w] + ')' 
           ENDIF
           undefine, w, nw
        ENDIF 
     ENDIF 

     str_element, lim, 'xaxis', value=xaxis
     IF SIZE(xaxis, /type) NE 0 THEN BEGIN
        IF tag_exist(lim, 'irregular', /quiet) THEN grid = 1 ELSE grid = 0 
        IF tag_exist(lim, 'angle', /quiet) THEN angle = 1 ELSE angle = 0
        
        xpos = lim.position[0]
        dy = lim.position[3] - lim.position[1]
        xrange = INTERPOL(data.y, data.x, lim.xrange)

        IF is_struct(xaxis) THEN BEGIN
           extract_tags, aopt, xaxis, /axis
           extract_tags, aopt, xaxis, tags=['xtickinterval']
           IF tag_exist(aopt, 'xaxis', /quiet) THEN BEGIN
              atype = aopt.xaxis
              str_element, aopt, 'xaxis', /delete
              IF ~is_struct(aopt) THEN undefine, aopt
           ENDIF
           str_element, xaxis, 'color', value=acol
        ENDIF 
        IF undefined(atype) THEN atype = 1
        IF undefined(acol) THEN acol = 0
        
        IF (atype) THEN ypos = lim.position[1] + 0.25 * dy ELSE ypos = lim.position[3] - 0.25 * dy
        AXIS, xpos, ypos, /normal, xrange=xrange, xaxis=atype, xstyle=1 + 4*grid, charsize=lim.charsize, _extra=aopt, xtick_get=xmajor
        IF tag_exist(lim, 'ytitle', /quiet) THEN ytit = lim.ytitle ELSE ytit = lim.var_label

        IF (grid) THEN BEGIN
           tlim = lim
           extract_tags, tlim, lim, except='ytitle'
           extract_tags, tlim, {yrange: [-1., 1.], ystyle: 5, xstyle: 5}
           mplot, data={x: lim.xrange, y: [-0.5, -0.5]}, lim=tlim

           xticks = INTERPOL(data.x, data.y, xmajor)
           IF is_struct(aopt) THEN BEGIN
              IF tag_exist(aopt, 'xminor', /quiet) THEN BEGIN
                 dx = ABS(xmajor[1] - xmajor[0])
                 xminor = dgen(range=minmax(xmajor) + [-dx, dx], resolution=dx/aopt.xminor)
                 w = WHERE(xminor GT xrange[0] AND xminor LT xrange[1], nw)
                 IF nw GT 0 THEN xminor = xminor[w] ELSE undefine, xminor
              ENDIF 
           ENDIF 
           IF MAX(xmajor - FLOOR(xmajor)) GT 0 THEN xtickformat = '(F0.1)' ELSE xtickformat = '(I0)'
           IF (angle) THEN xtickname = (xmajor MOD 360.) ELSE xtickname = xmajor
           FOR i=0, N_ELEMENTS(xmajor)-1 DO BEGIN
              XYOUTS, xticks[i], 0.2, /data, charsize=lim.charsize, align=0.5, xtickname[i].tostring(xtickformat), color=acol
              OPLOT, [ xticks[i], xticks[i] ], [-0.8, -0.2], color=acol
           ENDFOR

           IF ~undefined(xminor) THEN BEGIN
              xticks = INTERPOL(data.x, data.y, xminor)
              FOR i=0, N_ELEMENTS(xminor)-1 DO BEGIN
                 w = WHERE(xmajor EQ xminor[i], nw)
                 IF nw EQ 0 THEN OPLOT, [ xticks[i], xticks[i] ], [-0.65, -0.35], color=acol
              ENDFOR
           ENDIF

           XYOUTS, xpos, 0.25 * dy + lim.position[1], /normal, charsize=lim.charsize, ytit + ' ', /align, color=acol
        ENDIF ELSE XYOUTS, xpos, 0.5 * (lim.position[1] + lim.position[3]), /normal, charsize=lim.charsize, ytit + ' ', /align, color=acol
     ENDIF ELSE BEGIN
        IF SIZE(tlim, /type) EQ 0 THEN tlim = lim

        str_element, tlim, 'auto_ylog', aylog
        IF ~undefined(aylog) THEN BEGIN
           w = WHERE(data.x GE tlim.xrange[0] AND data.x LE tlim.xrange[1], nw)
           IF nw GT 0 THEN BEGIN
              ayr = ALOG10(minmax(data.y[w, *], /pos))
              IF ayr[1] - ayr[0] GT ALOG10(aylog) THEN str_element, tlim, 'ylog', 1, /add_replace
           ENDIF 
        ENDIF 

        mplot, data=data, limits=tlim, _extra=ext
        IF TAG_EXIST(tlim, 'color_offset', /quiet) THEN str_element, lim, 'color_offset', tlim.color_offset, /add_replace
        
        IF tag_exist(tlim, 'ystyle', /quiet) THEN IF (tlim.ystyle GE 8 AND tag_exist(tlim, 'axis', /quiet)) THEN BEGIN
           str_element, tlim, 'axis', value=aopt
           IF tag_exist(aopt, 'normal', /quiet) THEN BEGIN
              str_element, aopt, 'normal', value=norm
              str_element, aopt, 'normal', /delete
              str_element, aopt, 'ystyle', 1, /add_replace

              IF tlim.ystyle EQ 8 THEN BEGIN
                 yr = [CONVERT_COORD(tlim.position[0:1], /normal, /to_data), CONVERT_COORD(tlim.position[2:3], /normal, /to_data)]
                 yr = [yr[1], yr[-2]]/norm
              ENDIF ELSE yr = tlim.yrange / norm 
                 
              IF tag_exist(tlim, 'ylog', /quiet) THEN BEGIN
                 str_element, aopt, 'ylog', tlim.ylog, /add
                 IF aopt.ylog EQ 1 THEN str_element, aopt, 'ytickunits', 'scientific', /add
              ENDIF 

              str_element, aopt, 'yrange', TEMPORARY(yr), /add
              AXIS, _extra=TEMPORARY(aopt)
           ENDIF
        ENDIF 
        undefine, tlim
     ENDELSE 
     
     IF (draw_cscale) THEN BEGIN
        str_element, zlim, 'ztitle', ztitle
        str_element, zlim, 'zoffset', zoffset
        str_element, zlim, 'zposition', zposition
              
        extract_tags, clim, zlim, except=['ztitle', 'zoffset', 'zposition', 'charsize', 'bottom', 'top']
        
        IF is_struct(clim) THEN BEGIN
           ztags = tag_names(clim)
           ytags = 'Y' + ztags.substring(1)
           FOR iz=0, N_ELEMENTS(ztags)-1 DO struct_replace_field, clim, ztags[iz], clim.(iz), newtag=ytags[iz]
        ENDIF
        draw_color_scale, charsize=lim.charsize, brange=[bottom, top], range=zrange, log=zlog, title=ztitle, position=zposition, offset=zoffset, _extra=TEMPORARY(clim)
     ENDIF 
  ENDELSE 
  IF ~undefined(red0) THEN TVLCT, red0, green0, blue0

  toffset = (SCOPE_VARFETCH(common='tplot_com1', 'tplot_vars')).settings.time_offset
  tscale  = (SCOPE_VARFETCH(common='tplot_com1', 'tplot_vars')).settings.time_scale

  str_element, lim, 'flag', value=flag
  IF ~undefined(flag) THEN BEGIN
     extract_tags, flim, lim, except=['flag', 'graybkg', 'spec']
     str_element, flim, 'psym', 1, /add

     IF is_struct(flag) THEN BEGIN
        flg = flag
        extract_tags, flim, flg, tags=['psym', 'symsize', 'colors'] 
     ENDIF ELSE BEGIN
        get_data, tnames(flag), data=flg, alim=alim
        extract_tags, flim, alim, tags=['psym', 'symsize', 'colors']
     ENDELSE
     
     w = WHERE(flg.y EQ 1, nw)
     IF nw GT 0 THEN BEGIN
        ind = ARRAY_INDICES(flg.y, w)
        fx = flg.x[REFORM(ind[0, *])]
        IF ndimen(flg.v) EQ 2 THEN fy = flg.v[w] ELSE fy = flg.v[REFORM(ind[1, *])]
     ENDIF     
     str_element, flim, 'overplot', 1, /add
     esc_tplot, data={x: (fx - toffset)/tscale, y: fy}, lim=flim
  ENDIF 
  
  str_element, lim, 'timebar', value=tbar
  IF ~undefined(tbar) THEN BEGIN
     IF is_struct(tbar) THEN BEGIN
        ntags = N_TAGS(tbar)
        FOR i=0, ntags-1 DO append_array, ntbar, N_ELEMENTS(tbar.(i))
        IF N_ELEMENTS(spd_uniq(ntbar)) GT 1 THEN $
           FOR i=0, ntags-1 DO IF ntbar[i] EQ 1 THEN str_element, tbar, (TAG_NAMES(tbar))[i], REPLICATE(tbar.(i), MAX(ntbar)), /add_replace
        
        str_element, tbar, 'time', value=btime
        str_element, tbar, 'psym', value=bpsym
        IF tag_exist(tbar, 'color', /quiet) THEN BEGIN
           str_element, tbar, 'color', value=bcol
           str_element, tbar, 'color', /delete
        ENDIF 
        extract_tags, bext, tbar, /oplot
        IF tag_exist(bext, 'psym', /quiet) THEN str_element, bext, 'psym', /delete
        IF MAX(ntbar) GT 1 THEN BEGIN
           FOR i=0, MAX(ntbar)-1 DO BEGIN
              FOR j=0, N_TAGS(bext)-1 DO str_element, bext1, (TAG_NAMES(bext))[j], (bext.(j))[i], /add
              append_array, bext2, TEMPORARY(bext1)
           ENDFOR
           bext = TEMPORARY(bext2)
        ENDIF 
     ENDIF ELSE BEGIN
        IF ISA(tbar, 'LIST') THEN BEGIN
           FOR i=0, N_ELEMENTS(tbar)-1 DO BEGIN
              ttbar = tbar[i]
              append_array, btime, ttbar.time
              IF tag_exist(ttbar, 'color', /quiet) THEN append_array, bcol, ttbar.color ELSE append_array, bcol, 0
              undefine, ttbar
           ENDFOR
           bext = tbar 
        ENDIF ELSE btime = tbar
     ENDELSE
     
     IF undefined(bcol) THEN bcol = 0
     IF is_string(bcol) THEN bcol = get_colors(bcol)
     IF is_string(btime) THEN btime = time_double(btime)
     xpos = (btime - toffset)/tscale
     
     FOR i=0, N_ELEMENTS(xpos)-1 DO BEGIN
        xp = (CONVERT_COORD([xpos[i], 0.], /data, /to_normal))[0]
        IF ~undefined(bext) THEN bext1 = bext[i]
        PLOTS, [xp, xp], [lim.position[1], lim.position[3]], /normal, color=bcol[i], _extra=TEMPORARY(bext1), clip=lim.position, noclip=0

        IF ~undefined(bpsym) THEN BEGIN
           nb = nn2(data.x, xpos[i])
           IF tag_exist(lim, 'colors', /quiet) THEN bsymcol = lim.colors ELSE bsymcol = 0
           IF N_ELEMENTS(bsymcol) NE dimen2(data.y) THEN bsymcol = REPLICATE(bsymcol, dimen2(data.y))
           FOR i=0, dimen2(data.y)-1 DO OPLOT, [data.x[nb]], [data.y[nb, i]], psym=bpsym, color=bsymcol[i]
        ENDIF 
     ENDFOR 
     str_element, lim, 'timebar', /delete
  ENDIF 

  IF tag_exist(lim, 'note', /quiet) THEN nflg = 0 ELSE nflg = 1 

  IF (nflg) THEN RETURN

  charsize = !p.charsize
  IF charsize EQ 0 THEN charsize = 1.

  str_element, lim, 'note', value=note  
  str_element, lim, 'charsize', value=charsize
  str_element, lim, 'position', value=pos
  str_element, lim, 'note_charisze', value=chsize
  str_element, lim, 'note_flag', value=flag
  str_element, lim, 'note_color', value=color
  
  xspace = charsize * !d.x_ch_size / !d.x_size
  yspace = charsize * !d.y_ch_size / !d.y_size
 
  IF SIZE(chsize, /type) EQ 0 THEN chsize = charsize
  IF SIZE(flag, /type) EQ 0 THEN flag = 0
  IF SIZE(color, /type) EQ 0 THEN color = 0
  
  FOR fi=0, N_ELEMENTS(flag)-1 DO BEGIN
     CASE flag[fi] OF
        0: BEGIN                ; upper left corner
           xpos = pos[0] + xspace * 2.5
           ypos = pos[3] - yspace * 2.5
           align = 0
        END
        1: BEGIN                ; upper right corner
           xpos = pos[2] - xspace * 2.5
           ypos = pos[3] - yspace * 2.5
           align = 1
        END 
        2: BEGIN                ; lower right corner
           xpos = pos[2] - xspace * 2.5
           ypos = pos[1] + yspace * 1.5
           align = 1
        END 
        3: BEGIN                ; lower left corner
           xpos = pos[0] + xspace * 2.5
           ypos = pos[1] + yspace * 1.5
           align = 0
        END 
        ELSE: RETURN
     ENDCASE 
     
     XYOUTS, xpos, ypos, note[fi], /normal, charsize=chsize, color=color, align=align
  ENDFOR 
  RETURN
END
