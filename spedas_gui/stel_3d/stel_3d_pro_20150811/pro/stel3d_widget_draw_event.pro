;
; Event Handler for Draw Widget
;
pro stel3d_widget_draw_event, ev

  widget_control, ev.top, GET_UVALUE=val
  ;  ;help, ev, /STRUCT
  ;
  ; Wheel event
  if ev.type eq 7 then begin
    if (ev.clicks) gt 0 then scale = 0.8 else scale = 1.2
    val['oGroup'].Scale, scale, scale, scale ;Zoom
    val['oWindow'].Draw
    return
  endif
  ;
  ; rotation the model with mouse motion
  bHaveTransform = (val['oTrack']).Update(ev, TRANSFORM=qmat)
  if (bhavetransform ne 0) then begin
    val['oGroup']->GetProperty, TRANSFORM=t
    val['oGroup']->SetProperty, TRANSFORM=t#qmat
    val['oWindow']->Draw
    
    ;get rotation angles to display from matrix
    rot_angles = stel3d_get_rotation_angles(t#qmat, /DEGREE)
    ;id= widget_info(ev.top, FIND_BY_UNAME='viewtab:XANG')
    ;print, id
    widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:XANG'), $
       SET_VALUE=strcompress(string(rot_angles[0], FORMAT='(F10.1)'), /REMOVE_ALL)
    widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:YANG'),  $
       SET_VALUE=strcompress(string(rot_angles[1], FORMAT='(F10.1)'), /REMOVE_ALL)
    widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:ZANG'),  $
      SET_VALUE=strcompress(string(rot_angles[2], FORMAT='(F10.1)'), /REMOVE_ALL)
    return
  endif
  ;
  ; mouse press event
  if ev.press eq 1 then begin
    val['oWindow']->SetProperty, QUALITY=1 ;low:0, mid:1, high:2
    widget_control, ev.id, /DRAW_MOTION ;start motion event
  endif
  ;
  ; mouse release event
  if ev.release eq 1 then begin
    val['oWindow']->SetProperty, QUALITY=2  ;low:0, mid:1, high:2
    val['oWindow']->Draw
    widget_control, ev.id, DRAW_MOTION=0 ;stop motion event
  endif
  ;
  ; display context menu
  if (ev.release eq 4) then begin
    ; Obtain the widget ID of the context menu base.
    contextBase = widget_info(ev.top, FIND_BY_UNAME = 'context:Base')
    ; Display the context menu.
    widget_displaycontextmenu, ev.id, ev.X, ev.Y, contextBase
  endif

end
