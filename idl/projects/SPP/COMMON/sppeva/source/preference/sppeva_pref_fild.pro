
PRO sppeva_pref_fild_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=wid, /NO_COPY
  ;-----
  ;eva_sitl_update_board, wid, value
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=wid, /NO_COPY
END

FUNCTION sppeva_pref_fild_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=wid, /NO_COPY
  ;-----
  ret = wid
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=wid, /NO_COPY
  return, ret
END

FUNCTION sppeva_pref_fild_event, event
  compile_opt idl2

  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return, { ID:event.handler, TOP:event.top, HANDLER:0L }
  endif

  parent=event.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=wid, /NO_COPY


  ;-----
  case event.id of
    wid.ID:begin
      widget_control, event.id, GET_VALUE=strNew
      wid.fild_copy.SPPFLDSOC_ID = strNew
      end
    wid.password:begin
      widget_control, event.id, GET_VALUE=strNew
      wid.fild_copy.SPPFLDSOC_PW = strNew
      end
;    wid.LOCAL_DATA_DIR:begin
;      widget_control, event.id, GET_VALUE=strNew
;      wid.fild_copy.FLD_LOCAL_DATA_DIR = spd_addslash(strNew)
;      end
    else:
  endcase
  ;-----

  WIDGET_CONTROL, stash, SET_UVALUE=wid, /NO_COPY
  RETURN, { ID:parent, TOP:event.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION sppeva_pref_fild, parent, GROUP_LEADER=group_leader, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for sppeva_pref_fld'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'sppeva_pref_fld'
  if not (keyword_set(title)) then title='  FIELD  '

  wid = {fild_copy:!SPPEVA.FILD}
  
  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  base = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "sppeva_pref_fild_event", $
    FUNC_GET_VALUE = "sppeva_pref_fild_get_value", $
    PRO_SET_VALUE = "sppeva_pref_fild_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1,/base_align_left)
  str_element,/add,wid,'base',base
  lbl4 = widget_label(base,VALUE='The settings below can be configured in an idl_startup file')
  lbl3 = widget_label(base,VALUE='as well. The settings in the idl_startup file will override')
  lbl2 = widget_label(base,VALUE='the settings below.')
  lbl2 = widget_label(base,VALUE=' ')
  lbl1 = widget_label(base,VALUE='Credential for retrieving files from SPPFLDSOC.')
  str_element,/add,wid,'ID',      cw_field(base,VALUE=!SPPEVA.FILD.SPPFLDSOC_ID,TITLE='ID      ',/ALL_EVENTS,xsize=50)
  str_element,/add,wid,'password',cw_field(base,VALUE=!SPPEVA.FILD.SPPFLDSOC_PW,TITLE='password',/ALL_EVENTS,xsize=50)
  ;lbl3 = widget_label(base,VALUE='Location for storing FIELD data')
  ;str_element,/add,wid,'LOCAL_DATA_DIR', cw_field(base,VALUE=!SPPEVA.FILD.FLD_LOCAL_DATA_DIR,TITLE='LOCAL_DATA_DIR',/ALL_EVENTS,xsize=40)
  
  WIDGET_CONTROL, WIDGET_INFO(base, /CHILD), SET_UVALUE=wid, /NO_COPY
  RETURN, base
END
