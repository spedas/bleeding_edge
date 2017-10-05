;
; Event handler for scatter plot tab
;
pro stel3d_widget_scattertab_event, ev
compile_opt idl2

  widget_control, ev.top, GET_UVALUE=val
  widget_control, ev.id, GET_UVALUE=uval
  ;help, ev, /STRUCT

  if uval eq !null then return
  case uval of 
    'scattertab:MAXTEXT':begin
      
    end
    'scattertab:MAXSLIDER':begin
      ;print, ev.value
      widget_control, widget_info(ev.top, FIND_BY_UNAME='scattertab:MINSLIDER'), GET_VALUE=minval
      if ev.value lt minval then begin
        widget_control, ev.id, SET_VALUE=minval+1
        widget_control, widget_info(ev.top, FIND_BY_UNAME='scattertab:MAXTEXT'), SET_VALUE=strcompress(string(minval+1), /REMOVE_ALL)
        return
      endif
      widget_control, widget_info(ev.top, FIND_BY_UNAME='scattertab:MAXTEXT'), SET_VALUE=strcompress(string(ev.value), /REMOVE_ALL)
      
    end
    'scattertab:MINTEXT':begin
      
    end
    'scattertab:MINSLIDER':begin
      widget_control, widget_info(ev.top, FIND_BY_UNAME='scattertab:MAXSLIDER'), GET_VALUE=maxval
      if ev.value gt maxval then begin
        widget_control, ev.id, SET_VALUE=maxval-1
        widget_control, widget_info(ev.top, FIND_BY_UNAME='scattertab:MINTEXT'), SET_VALUE=strcompress(string(maxval-1), /REMOVE_ALL)
        return
      end
      widget_control, widget_info(ev.top, FIND_BY_UNAME='scattertab:MINTEXT'), SET_VALUE=strcompress(string(ev.value), /REMOVE_ALL)
    end
    else:message, 'no match'
  endcase
  ;
  ; Get values from sliders
  widget_control, widget_info(ev.top, FIND_BY_UNAME='scattertab:MINSLIDER'), GET_VALUE=minval
  widget_control, widget_info(ev.top, FIND_BY_UNAME='scattertab:MAXSLIDER'), GET_VALUE=maxval
  ;
  ; update oScatte object based on the values specified
  !null = stel3d_create_scatter(val['oData'], MINVAL=minval, MAXVAL=maxval, UPDATE=val['oScatter'])
  val['oWindow'].draw

end