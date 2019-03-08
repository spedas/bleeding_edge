;+
;
;PROCEDURE:       MPLOT_SYMLOG
;
;PURPOSE:         Draws a tplot variable with a bi-symmetric log y-axis
;                 that allows to display both positive and negative
;                 values in log scale.
; 
;                 In general, it is assumed to be only used as follows:
;
;                 IDL> options, 'tplot name', tplot_routine='mplot_symlog'
;
;                 In the current version, it can only draw multi-line plots.
;
;INPUTS:          Tplot data and settings same to 'mplot'.
;
;KEYWORDS:
;
;      DATA:      A structure that contains the elements 'x', 'y', and ['dy'].
;                 (used by 'tplot').
;
;    LIMITS:      A structure that contains any combination of the following elements:
;                 All PLOT/OPLOT keywords (i.e., psym, symsize, linestyle, colors, etc.)
;
;CREATED BY:      Takuya Hara on 2016-09-27.
;
;LAST MODIFICATION:
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-03-07 15:00:40 -0800 (Thu, 07 Mar 2019) $
; $LastChangedRevision: 26774 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/mplot_symlog.pro $
;
;-
FUNCTION mplot_symlog_ytick_p, axis, index, number
  times = 'x'
  ; A special case.
  IF number EQ 0 THEN RETURN, '0'

  ; Assuming multiples of 10 with format.
  ex = STRING(number, '(e8.0)')
  pt = STRPOS(ex, '.')

  first = STRMID(ex, 0, pt)
  sign = STRMID(ex, pt+2, 1)
  thisExponent = STRMID(ex, pt+3)
  
  ; Shave off leading zero in exponent
  WHILE STRMID(thisExponent, 0, 1) EQ '0' DO thisExponent = STRMID(thisExponent, 1)

  ; Fix for sign and missing zero problem.
  IF (LONG(thisExponent) EQ 0) THEN BEGIN
     sign = ''
     thisExponent = '0'
  ENDIF

  IF (first EQ '  1') OR (first EQ ' 1') THEN BEGIN
     first = ''
     times = ''
  ENDIF

  ; Make the exponent a superscript.
  IF sign EQ '-' THEN BEGIN
     RETURN, first + times + '10!U' + sign + thisExponent + '!N'
  ENDIF ELSE BEGIN
     RETURN, first + times + '10!U' + thisExponent + '!N'
  ENDELSE
END
FUNCTION mplot_symlog_ytick_n, axis, index, number
  times = 'x'
  ; A special case.
  IF number EQ 0 THEN RETURN, '0'

  ; Assuming multiples of 10 with format.
  ex = STRING(number, '(e8.0)')
  pt = STRPOS(ex, '.')

  first = STRMID(ex, 0, pt)
  sign = STRMID(ex, pt+2, 1)
  thisExponent = STRMID(ex, pt+3)

  ; Shave off leading zero in exponent
  WHILE STRMID(thisExponent, 0, 1) EQ '0' DO thisExponent = STRMID(thisExponent, 1)

  ; Fix for sign and missing zero problem.
  IF (LONG(thisExponent) EQ 0) THEN BEGIN
     sign = ''
     thisExponent = '0'
  ENDIF

  IF (first EQ '  1') OR (first EQ ' 1') THEN BEGIN
     first = ''
     times = ''
  ENDIF

  ; Make the exponent a superscript.
  IF sign EQ '-' THEN BEGIN
     RETURN, '-' + first + times + '10!U' + sign + thisExponent + '!N'
  ENDIF ELSE BEGIN
     RETURN, '-' + first + times + '10!U' + thisExponent + '!N'
  ENDELSE
END

PRO mplot_symlog, data=data, limits=lim
  IF SIZE(data.y, /type) EQ 5 THEN nan = !values.d_nan ELSE nan = !values.f_nan
  
  str_element, lim, 'overplot', value=overplot
  str_element, lim, 'labflag', value=labflag
  str_element, lim, 'labels', value=labels
  str_element, lim, 'all_labels', value=all_labels   ;pseudo vars only
  str_element, lim, 'label_index', value=label_index ;pseudo vars only
  str_element, lim, 'labpos', value=labpos
  str_element, lim, 'labsize', value=lbsize
  str_element, lim, 'ytitle', value=ytitle
  str_element, lim, 'ysubtitle', value=ysubtitle
  str_element, lim, 'charsize', value=charsize
  str_element, lim, 'colors', value=colors
  str_element, lim, 'xtickname', value=xtickname
  str_element, lim, 'yrange', value=yrange
  str_element, lim, 'verbose', value=verbose
  
  IF SIZE(charsize, /type) EQ 0 THEN charsize = !p.charsize
  IF charsize EQ 0 THEN charsize = 1.

  str_element, lim, 'labflag', /delete
  str_element, lim, 'labels', /delete
  str_element, lim, 'all_labels', /delete
  str_element, lim, 'labpos', /delete
  str_element, lim, 'labsize', /delete

  extract_tags, alim, lim, /axis
  str_element, lim, 'ytitle', /delete
  str_element, lim, 'ysubtitle', /delete
  dlim = lim

  pdat = data
  plim = lim
  w = WHERE(pdat.y LT 0., nw)
  IF nw GT 0 THEN pdat.y[w] = nan

  ndat = data
  nlim = lim
  w = WHERE(ndat.y GT 0., nw)
  IF nw GT 0 THEN ndat.y[w] = nan
  ndat.y = ABS(ndat.y)

  pos = lim.position
  xrange = lim.xrange
  dy = pos[3] - pos[1]
  ycenter = pos[1] + .5*dy

  str_element, plim, 'position', [pos[0], ycenter, pos[2:*]], /add_replace
  str_element, nlim, 'position', [pos[0:2], ycenter], /add_replace

  w = WHERE(data.x GE xrange[0] AND data.x LE xrange[1], nw)
  IF nw GT 0 THEN BEGIN
     ymax = MAX(ABS(data.y[w, *]))*1.05 
     pmax = REFORM(pdat.y[w[nw-1], *])
     nmax = REFORM(ndat.y[w[nw-1], *])
     tmax = pdat.x[w[nw-1]]
  ENDIF ELSE BEGIN
     ymax = MAX(ABS(data.y))*1.05
     pmax = REFORM(pdat.y[N_ELEMENTS(data.x)-1, *])
     nmax = REFORM(ndat.y[N_ELEMENTS(data.x)-1, *])
     tmax = pdat.x[N_ELEMENTS(data.x)-1]
  ENDELSE 

  IF SIZE(yrange, /type) NE 0 THEN BEGIN
     ymax = MAX(ABS(yrange))
     ymin = MIN(yrange)
     IF ymin LT 0. THEN BEGIN
        dprint, dlevel=1, verbose=verbose, 'Minimum yrange value is negative!'
        ymin = Max(abs(yrange))/1.0e3
     ENDIF 
  ENDIF
  IF SIZE(ymin, /type) EQ 0 THEN BEGIN ;set ymin based on data, jmm, 2019-03-05
     ymin = ymax/1.0e3
  ENDIF

  str_element, plim, 'xtickname', REPLICATE(' ', N_ELEMENTS(xtickname)), /add_replace
  str_element, plim, 'yrange', [ymin, ymax], /add_replace
  str_element, plim, 'ylog', 1, /add_replace
  str_element, plim, 'ystyle', 1, /add_replace
  str_element, plim, 'ytickformat', 'mplot_symlog_ytick_p', /add_replace

  str_element, nlim, 'yrange', [ymax, ymin], /add_replace
  str_element, nlim, 'ylog', 1, /add_replace
  str_element, nlim, 'ystyle', 1, /add_replace
  str_element, nlim, 'ytickformat', 'mplot_symlog_ytick_n', /add_replace

  IF KEYWORD_SET(labels) THEN nlab = N_ELEMENTS(labels) ;# of labels for variable
  xlast = REPLICATE(tmax, nlab)

  IF (overplot) THEN BEGIN
     extract_tags, plim, {xstyle: 5, ystyle: 5, overplot: 0}
     extract_tags, nlim, {xstyle: 5, ystyle: 5, overplot: 0}
     str_element, dlim, 'overplot', 0, /add_replace
  ENDIF

  ytn = !y.tickname
  !y.tickname[*] = '     '
  extract_tags, dlim, {xstyle: 5, ystyle: 5}
  extract_tags, alim, {xstyle: 5, yticks: 1, yminor: 1, yticklayout: 1}
  box, dlim
  axis, yaxis=0, _extra=alim
  !y.tickname[*] = ytn

;handle possible colors in pseudo variable, jmm, 2019-03-05
;but only if n_colors = n_labels
  IF KEYWORD_SET(all_labels) && $ ;Cannot just use keyword_set for colors, index
     (keyword_set(label_index) || (n_elements(label_index) Gt 0 && label_index[0] Ne -1)) && $
     (keyword_set(colors) || (n_elements(colors) Gt 0 && colors[0] Ne -1)) THEN BEGIN
     nc = n_elements(colors)
     IF NC EQ N_ELEMENTS(all_labels) THEN BEGIN ;one color for each label
        str_element, plim, 'colors', get_colors(colors[label_index]), /add_replace
        str_element, nlim, 'colors', get_colors(colors[label_index]), /add_replace
        pseudo_colors = 1b      ;save a flag for labels
     ENDIF ELSE pseudo_colors = 0b
  ENDIF ELSE pseudo_colors = 0b

  mplot, data=pdat, limits=plim
  plast = CONVERT_COORD(xlast, pmax, /data, /to_norm)
  plast = REFORM(plast[1, *])
     
  mplot, data=ndat, limits=nlim
  nlast = CONVERT_COORD(xlast, nmax, /data, /to_norm)
  nlast = REFORM(nlast[1, *])

  IF KEYWORD_SET(colors) THEN col = get_colors(colors)
  labbins = REPLICATE(1, dimen2(data.y))
  IF KEYWORD_SET(labels) THEN BEGIN
     ylast = plast
     ylast[*] = 0.
     p = WHERE(FINITE(plast), np, complement=m, ncomplement=nm)
     IF np GT 0 THEN ylast[p] = plast[p]
     IF nm GT 0 THEN ylast[m] = nlast[m]
     undefine, p, m, np, nm

     ;# used for calculating label size and placement
     ;should include total number in case of pseudo var
     nlabtot = KEYWORD_SET(all_labels) ? N_ELEMENTS(all_labels):nlab

     IF ~KEYWORD_SET(all_labels) && nlab NE (dimen2(data.y)) THEN $
        dprint, dlevel=2, 'Incorrect number of labels', /no_check_events
     
     yw = [pos[1], pos[3]]
     xw = [pos[0], pos[2]]
     IF NOT KEYWORD_SET(lbsize) THEN $
        lbsize = charsize < (yw[1] - yw[0])/(nlabtot+1) * !d.y_size/!d.y_ch_size $
     ELSE lbsize = lbsize * charsize
     
     IF N_ELEMENTS(labflag) EQ 0 THEN BEGIN
        IF KEYWORD_SET(labpos) THEN labflag = 3 ELSE labflag = 2
     ENDIF 
     
     IF N_ELEMENTS(labflag) EQ 0 THEN labflag = 0 ; no labels
     
     IF (labflag EQ 1) OR (labflag EQ -1) THEN BEGIN ; evenly spaced labels 
        nlabpos = (FINDGEN(nlabtot) + .5) * (yw[1] - yw[0]) / nlabtot + yw[0]
        IF labflag EQ -1 THEN nlabpos = REVERSE(nlabpos)
     ENDIF 

     IF labflag EQ 3 THEN BEGIN ; specified label position
        IF KEYWORD_SET(labpos) THEN BEGIN
           foo = CONVERT_COORD(/data, /to_norm, FINDGEN(N_ELEMENTS(labpos)), labpos)
           nlabpos = foo[1, *]
        ENDIF ELSE dprint, dlevel=2, 'Custom label position not set, please set LABPOS option.' , verbose=verbose
     ENDIF 
     
     IF KEYWORD_SET(all_labels) THEN BEGIN ; pseudo var labels and colors
        lidx = WHERE(label_index LE N_ELEMENTS(all_labels)-1, nl)
        IF nl GT 0 THEN BEGIN
           ; get correct labels and placement for this variable (set in tplot)
           labels = all_labels[label_index[lidx]]
           IF KEYWORD_SET(nlabpos) THEN nlabpos = nlabpos[label_index[lidx]]
        ENDIF ELSE labflag = 0
        nlab = nl               ;jmm, 2019-03-05, avoid crash at line below: ypos = nlabpos[n]
     ENDIF 

     labbins = REPLICATE(1, nlab)
     xpos = xw[1]
  ENDIF ELSE labflag = 0

  IF KEYWORD_SET(labels) AND KEYWORD_SET(labflag) THEN BEGIN
     FOR n=0, nlab-1 DO BEGIN
        ypos = 0.
        IF KEYWORD_SET(nlabpos) THEN BEGIN ; evenly spaced labels
           ypos = nlabpos[n]
        ENDIF ELSE BEGIN        ;labels at end of trace
           ypos = ylast[n]
           ;IF WHERE(FINITE(pmax[n])) THEN ylast = pmax[n] ELSE ylast = nmax[n]
           ;ypos = (CONVERT_COORD(trange[1], ylast, /data, /to_norm))[1]
           ;fooind = where( foo[0,*] le xw[1],count)
           ;if count ne 0 then mx = max(foo[0,fooind],ms)
           ;if count ne 0 then ypos = foo[1,fooind[ms]]
        ENDELSE 
        
        IF ypos LE yw[1] AND ypos GE yw[0] THEN BEGIN
           IF pseudo_colors THEN col_n = col[label_index] $ ;jmm, 2019-03-05
           ELSE col_n = col[n]
           XYOUTS, xpos, ypos, '  ' + labels[n], color=col_n, /norm, charsize=lbsize
        ENDIF
     ENDFOR 
  ENDIF 
  RETURN
END
