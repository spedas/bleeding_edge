;
; EVENT handler for View panel
;
pro stel3d_widget_viewtab_event, ev
  widget_control, ev.top, GET_UVALUE=val
  widget_control, ev.id, GET_UVAlUE=uval
  ;help, ev, /STRUCT
  
  case uval of
    'viewtab:RESET': begin
      val['oGroup'].SetProperty, TRANSFORM= val['inittrans']
      ;update angle information
      rot_angles = stel3d_get_rotation_angles(val['inittrans'], /DEGREE)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:XANG'), $
        SET_VALUE=strcompress(string(rot_angles[0], FORMAT='(F10.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:YANG'),  $
        SET_VALUE=strcompress(string(rot_angles[1], FORMAT='(F10.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:ZANG'),  $
        SET_VALUE=strcompress(string(rot_angles[2], FORMAT='(F10.1)'), /REMOVE_ALL)
      ;Redraw  
      val['oWindow'].Draw
    end
    'viewtab:BOX':begin
      val['oBox'].SetProperty, HIDE=abs((ev.select)-1)
      val['oWindow'].Draw
    end
    'viewtab:CENTER':begin
      val['oCenterX'].SetProperty, HIDE=abs((ev.select)-1)
      val['oCenterY'].SetProperty, HIDE=abs((ev.select)-1)
      val['oCenterZ'].SetProperty, HIDE=abs((ev.select)-1)
      val['oWindow'].Draw
    end
    'viewtab:XY':begin
      val['oGroup'].SetProperty, TRANSFORM=val['zerotrans']
      val['oGroup'].GetProperty, TRANSFORM=trans
      ;update angle information
      rot_angles = stel3d_get_rotation_angles(trans, /DEGREE)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:XANG'), $
        SET_VALUE=strcompress(string(rot_angles[0], FORMAT='(F10.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:YANG'),  $
        SET_VALUE=strcompress(string(rot_angles[1], FORMAT='(F10.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:ZANG'),  $
        SET_VALUE=strcompress(string(rot_angles[2], FORMAT='(F10.1)'), /REMOVE_ALL)
      val['oWindow'].Draw
    end
    'viewtab:XZ':begin
      val['oGroup'].SetProperty, TRANSFORM=val['zerotrans']
      val['oGroup'].Rotate, [1,0,0], -90
      val['oGroup'].GetProperty, TRANSFORM=trans
      ;update angle information
      rot_angles = stel3d_get_rotation_angles(trans, /DEGREE)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:XANG'), $
        SET_VALUE=strcompress(string(rot_angles[0], FORMAT='(F10.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:YANG'),  $
        SET_VALUE=strcompress(string(rot_angles[1], FORMAT='(F10.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:ZANG'),  $
        SET_VALUE=strcompress(string(rot_angles[2], FORMAT='(F10.1)'), /REMOVE_ALL)
      val['oWindow'].Draw
    end
    'viewtab:YZ':begin
      val['oGroup'].SetProperty, TRANSFORM=val['zerotrans']
      val['oGroup'].Rotate, [1,0,0], -90
      val['oGroup'].Rotate, [0,1,0], 90
      val['oGroup'].GetProperty, TRANSFORM=trans
      ;update angle information
      rot_angles = stel3d_get_rotation_angles(trans, /DEGREE)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:XANG'), $
        SET_VALUE=strcompress(string(rot_angles[0], FORMAT='(F10.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:YANG'),  $
        SET_VALUE=strcompress(string(rot_angles[1], FORMAT='(F10.1)'), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='viewtab:ZANG'),  $
        SET_VALUE=strcompress(string(rot_angles[2], FORMAT='(F10.1)'), /REMOVE_ALL)
      val['oWindow'].Draw
    end
    'viewtab:AXIS':begin
      val['oAxisX'].SetProperty, HIDE=abs((ev.select)-1)
      val['oAxisY'].SetProperty, HIDE=abs((ev.select)-1)
      val['oAxisZ'].SetProperty, HIDE=abs((ev.select)-1)
      val['oWindow'].Draw
    end
    else: message, 'no match'
  endcase
  
  ;update widget information
 
  
end