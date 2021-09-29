PRO eva_sitluplink_title, parent
  compile_opt idl2
  
  id_sitl = widget_info(parent, find_by_uname='eva_sitluplink')
  sitl_stash = WIDGET_INFO(id_sitl, /CHILD)
  widget_control, sitl_stash, GET_UVALUE=sitl_state, /NO_COPY;******* GET
  widget_control, sitl_state.bgUplink, GET_VALUE = bgUplink
  if bgUplink eq 1 then begin
    title = ' DISABLE UPLINK '
  endif else begin
    title = ' ENABLE UPLINK '
  endelse
  widget_control, sitl_state.mainbase, BASE_SET_TITLE=title
  widget_control, sitl_stash, SET_UVALUE=sitl_state, /NO_COPY;******* SET  
END