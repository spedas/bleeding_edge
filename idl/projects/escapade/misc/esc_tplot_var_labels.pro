;+
;
;PROCEDURE:       ESC_TPLOT_VAR_LABELS
;
;PURPOSE:         Helper (or Wrapper) routine for the tplot visualization.
;                 It can be visualized as the var_label style.
;
;EXAMPLE:         IDL> options, 'tname', tplot_routine='esc_tplot_var_labels'         
;
;CREATED BY:      Takuya Hara on 2025-07-15.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2025-07-15 18:29:18 -0700 (Tue, 15 Jul 2025) $
; $LastChangedRevision: 33470 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/misc/esc_tplot_var_labels.pro $
;
;-
PRO esc_tplot_var_labels, data=data, limits=limits
  FOR i=0, dimen2(data.y)-1 DO append_array, vlab, TRANSPOSE(data.y[nn(data.x, limits.xtickv), i])

  tlim = limits
  str_element, tlim, 'yrange', [0., 1.], /add
  str_element, tlim, 'ystyle', 5, /add
  str_element, tlim, 'xstyle', 5, /add
  data.y[*] = !values.f_nan
  mplot, data=data, limits=TEMPORARY(tlim)

  chsize = limits.charsize
  col  = limits.colors
  pos = limits.position
  vtitle = limits.labels
  IF tag_exist(limits, 'format', /quiet) THEN format = limits.format ELSE format = '(F0.1)'

  xspace = chsize * !d.x_ch_size / !d.x_size
  yspace = chsize * !d.y_ch_size / !d.y_size
  yw = pos[3] - pos[1]

  ypos = pos[3] - yspace
  ypos = (CONVERT_COORD([pos[0], ypos], /normal, /to_data))[1]
  ypos = dgen(range=[ypos, 0.], dimen2(data.y))
  gy   = 2.d0 * limits.ygap * yspace
  hgt  = yspace * dimen2(data.y) 
  
  FOR i=0, dimen1(limits.xtickv)-1 DO BEGIN
     text = STRING(vlab[0, i], format)
     FOR j=1, dimen2(data.y)-1 DO text += '!C' + STRING(vlab[j, i], format)

     XYOUTS, limits.xtickv[i], ypos[0], /data, align=0.5, color=col, TEMPORARY(text), $
             charsize=((hgt LE yw + gy) ? chsize : chsize * ((yw + gy)/hgt))
  ENDFOR 
  xpos = pos[0] - (limits.xmargin[0]-1) * xspace
  xpos = (CONVERT_COORD([xpos, pos[3]], /normal, /to_data))[0]

  text = vtitle[0]
  FOR i=1, dimen1(vtitle)-1 DO text += '!C' + vtitle[i]
  XYOUTS, xpos, ypos[0], TEMPORARY(text), /data, color=col, charsize=((hgt LE yw + gy) ? chsize : chsize * ((yw + gy)/hgt))

  IF limits.xstyle EQ 1 THEN BEGIN
     ypos = pos[1] - 1.5 * yspace
     ypos = (CONVERT_COORD([xpos, ypos], /normal, /to_data))[1]
     FOR i=0, dimen1(limits.xtickv)-1 DO XYOUTS, limits.xtickv[i], ypos, limits.xtickname[i], align=0.5, /data, charsize=chsize
  ENDIF
  RETURN
END
