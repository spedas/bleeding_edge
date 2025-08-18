;
; Purpose:get window size from TDAS
;
function et_diagram_winsize, WID=wid, XSIZE=xsize, YSIZE=ysize
@stel3d_common

  org_wid = !D.WINDOW
  
  window, /FREE, /PIXMAP, XSIZE=size, YSIZE=ysize
  wid = !D.Window
  tplot_options, 'window', wid
  tplot_options,'wshow', 0
  tplot, [11,15,14,1,2]
  xs = !D.X_SIZE
  ys = !D.Y_SIZE
  ;wdelete, wid
  wset, org_wid
  return, [xs, ys]
  
end
;
;
;
pro show_et_diagram_draw_event, ev

  widget_control, ev.top, GET_UVALUE=hstate
  widget_control, ev.id, GET_UVALUE=uval
  win_size = hstate['win_size']
  wstart = widget_info(ev.top, FIND_BY_UNAME='START')
  wend = widget_info(ev.top, FIND_BY_UNAME='END')
  wcurrent = widget_info(ev.top, FIND_BY_UNAME='CURRENT')
  
  ; get normal coordinate
  nx = float(ev.x)/win_size[0]
  ;
  ; Calculate time from the x-coordinate
  newt =  normal_to_data(nx, hstate['tplot_x']) * hstate['time_scale'] + hstate['time_offset']
  if newt gt time_double(hstate['org_etime']) then newt = time_double(hstate['etime'])
  if newt lt time_double(hstate['org_stime']) then newt = time_double(hstate['stime'])
  strnewt = time_string(newt)
  ;strnewt = time_string(newt, FORMAT=4)
  
  case ev.type of
    0:begin ; Click Press Event
      if hstate['click_flg'] eq 0 then begin
;        if newt gt time_double(hstate['etime']) then begin
;          message, /INFO, 'start time should be smaller than end time'
;          return
;        endif
        hstate['start_pos'] = ev.x
        hstate['stime'] = strnewt
        hstate['click_flg'] = 1
        widget_control, wstart, SET_VALUE=hstate['stime']
        ;Draw line for start time
        wset, hstate['wid']
        erase
        device, COPY=[0,0,win_size[0],win_size[1], 0, 0, hstate['wid_pix']]
        if hstate['start_pos'] ne -1 then $
          plots, [ hstate['start_pos'],  hstate['start_pos']], [0, win_size[1]], /DEVICE, COLOR=120
        if hstate['end_pos'] ne -1 then $
          plots, [hstate['end_pos'], hstate['end_pos']], [0, win_size[1]], /DEVICE, COLOR=230
      endif else begin
        if newt lt time_double(hstate['stime']) then begin
          message, /INFO, 'end time should be bigger than start time'
          return
        endif
        hstate['end_pos'] = ev.x
        hstate['etime'] = strnewt
        hstate['click_flg'] = 0
        widget_control, wend, SET_VALUE=hstate['etime']
        ;Draw line for endtime
        wset, hstate['wid']
        erase
        device, COPY=[0, 0, win_size[0], win_size[1], 0, 0, hstate['wid_pix']]
        if hstate['start_pos'] ne -1 then $
          plots, [ hstate['start_pos'],  hstate['start_pos']], [0, win_size[1]], /DEVICE, COLOR=120
        if hstate['end_pos'] ne -1 then $
          plots, [hstate['end_pos'], hstate['end_pos']], [0, win_size[1]], /DEVICE, COLOR=230
        
        ;stel3d_proto, TRANGE=[hstate['stime'],hstate['etime']]
        print, 'TRANGE: ', [hstate['stime'],hstate['etime']]
       
      endelse
      
    end
    2:begin ; Motion Event
      
      wset, hstate['wid']
      erase
      device, COPY=[0,0, win_size[0],win_size[1], 0, 0, hstate['wid_pix']]
      plots, [ev.x, ev.x], [0,win_size[1]], /DEVICE
      plots, [0, win_size[0]], [ev.y, ev.y], /DEVICE
      if hstate['start_pos'] ne -1 then $
        plots, [ hstate['start_pos'],  hstate['start_pos']], [0, win_size[1]], /DEVICE, COLOR=120
      if hstate['end_pos'] ne -1 then $  
        plots, [hstate['end_pos'], hstate['end_pos']], [0, win_size[1]], /DEVICE, COLOR=230
        
      widget_control, wcurrent, SET_VALUE=strnewt
      
    end
    else:
  endcase
end
;
;
;
pro show_et_diagram_event, ev

  widget_control, ev.top, GET_UVALUE=hstate
  widget_control, ev.id, GET_UVALUE=uval
  
  case uval of
    'ok':begin
      hstate['ok'] = 1
      widget_control, ev.top, /DESTROY
    end
    'cancel':begin
      hstate['stime'] = ''
      hstate['etime'] = ''
      widget_control, ev.top, /DESTROY
    end
    else:
  endcase

end
;
;;
;
pro show_et_diagram_cleanup, top
  widget_control, top, GET_UVALUE=hstate
  wdelete, hstate['wid_pix']
  
end
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main
;
; WE PLAN TO USE XTPLOT AND RELATED ROUTINES TO SHOW ET DIAGRAMS. 
; 
; THIS VERSION NEEDS 'gtl971212.tplot' to show an E-t diagram. 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function show_et_diagram, XSIZE=xsize, YSIZE=ysize
@stel3d_common
@tplot_com

  loadct, 39, /SILENT

;  path = routine_filepath()
;  cd, file_dirname(path)
  infile = file_which(in_slice, /INCLUDE_CURRENT_DIR)
  if infile eq '' then begin
    message, '"gtl971212.tplot" file is necessary'
    return, -1
  endif
  tplot_restore, FILE=infile
  ;
  ; get time info
  get_data, 11, data=data
  strtime = time_string(data.x)
  stime = strtime[0]
  etime = strtime[-1] ;last element
  ;  print, 'start time : ', stime
  ;  print, 'end time : ', etime
  
  win_size = et_diagram_winsize(WID=wid_pix, XSIZE=xsize, YSIZE=ysize)
  ;print, 'window size: ', win_size
  
  top = widget_base(/COL)
  wDrawBase = widget_base(top, /COL)
  wDraw = widget_draw(top, XS=win_size[0], YS=win_size[1], GRAPHICS_LEVEL=0, $
    /MOTION_EVENT, /BUTTON_EVENT, EVENT_PRO='show_et_diagram_draw_event', UNAME='draw')
  wTextBase = widget_base(top, /ROW)
  wLabelCurrentTitle = widget_label(wTextBase, VALUE='Cursor Value: ')
  wLabelCurrentValue = widget_label(wTextBase, YSIZE=10, XSIZE=120, VALUE='', UNAME='CURRENT')
  wLabelStart = widget_label(wTextBase, VALUE='Start Time: ')
  wTextStart = widget_text(wTextBase, UNAME='START', VALUE=stime)
  wLabelEnd = widget_label(wTextBase, VALUE='End Time: ')
  wTextEnd = widget_text(wTextBase, UNAME='END', VALUE=etime)
  wButtonBase = widget_base(top, /ROW)
  wButtonOK = widget_button(wButtonBase, UVALUE='ok', VALUE='OK')
  wButtonCancel = widget_button(wButtonBase, UVALUE='cancel', VALUE='Cancel')
  
  widget_control, top, /REALIZE
  widget_control, wDraw, GET_VALUE=wid
  wset, wid
  ;
  ; Draw graph
  device, COPY=[0,0,win_size[0],win_size[1], 0, 0, wid_pix]
;  tplot_options, 'window', wid
;  tplot, [11,15,14,1,2]
  tplot_x = tplot_vars.settings.x
  time_scale  = tplot_vars.settings.time_scale
  time_offset = tplot_vars.settings.time_offset
  
  uval = hash()
  uval['win_size'] = win_size
  uval['click_flg'] = 0
  uval['data'] = data
  uval['org_stime'] = stime
  uval['org_etime'] = etime
  uval['stime'] = stime
  uval['etime'] = etime
  uval['start_pos'] = -1
  uval['end_pos'] = -1
  uval['wid'] = wid
  uval['wid_pix'] = wid_pix
  uval['tplot_x'] = tplot_x
  uval['ok'] = 0
  uval['time_scale'] = time_scale
  uval['time_offset'] = time_offset
  widget_control, top, SET_UVALU=uval 
  
  xmanager, 'show_et_diagram', top, CLEANUP='show_et_diagram_cleanup'
  
  if uval['ok'] eq 1 then begin
    return, [uval['stime'], uval['etime']]
  endif else begin
    return, -1
  endelse
  
end
;
;
;
pro test_show_et_diagram

  thm_init
  ;infile = 'gtl971212.tplot'
  res = show_et_diagram()
  print, 'Return Value: ', res

end
