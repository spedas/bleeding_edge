
PRO sppeva_pref_user_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=wid, /NO_COPY
  ;-----
  ;eva_sitl_update_board, wid, value
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=wid, /NO_COPY
END

FUNCTION sppeva_pref_user_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=wid, /NO_COPY
  ;-----
  ret = wid
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=wid, /NO_COPY
  return, ret
END

FUNCTION sppeva_pref_user_event, event
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
    wid.fldFullName:begin
      widget_control, event.id, GET_VALUE=strNew
      wid.user_copy.FULLNAME = strNew
      end
    wid.fldEmail:begin
      widget_control, event.id, GET_VALUE=strNew
      wid.user_copy.EMAIL = strNew
      end
;    wid.fldID:begin
;      widget_control, event.id, GET_VALUE=strNew
;      wid.user_copy.ID = strNew
;      end
    wid.fldTeam:begin
      widget_control, event.id, GET_VALUE=strNew
      wid.user_copy.TEAM = strNew
      end
    else:
  endcase
  ;-----

  WIDGET_CONTROL, stash, SET_UVALUE=wid, /NO_COPY
  RETURN, { ID:parent, TOP:event.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION sppeva_pref_user, parent, GROUP_LEADER=group_leader, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for sppeva_pref_user'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'sppeva_pref_user'
  if not (keyword_set(title)) then title='  USER PROFILE  '

  wid = {user_copy:!SPPEVA.USER}
  
  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  base = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "sppeva_pref_user_event", $
    FUNC_GET_VALUE = "sppeva_pref_user_get_value", $
    PRO_SET_VALUE = "sppeva_pref_user_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1,/base_align_left)
  str_element,/add,wid,'base',base
  lbl2 = widget_label(base,VALUE=' ')
  lbl1 = widget_label(base,VALUE='These info will be inserted into the CSV output file.')
  str_element,/add,wid,'fldFullName',cw_field(base,VALUE=!SPPEVA.USER.FULLNAME,TITLE='Full Name',/ALL_EVENTS,xsize=50)
  str_element,/add,wid,'fldEmail',   cw_field(base,VALUE=!SPPEVA.USER.EMAIL,   TITLE='Email    ',/ALL_EVENTS,xsize=50)
  ;str_element,/add,wid,'fldID',      cw_field(base,VALUE=!SPPEVA.USER.ID,      TITLE='ID       ',/ALL_EVENTS,xsize=20)
  str_element,/add,wid,'fldTeam',    cw_field(base,VALUE=!SPPEVA.USER.TEAM,    TITLE='Team (e.g. FIELDS, SWEAP)',/ALL_EVENTS,xsize=20)

  WIDGET_CONTROL, WIDGET_INFO(base, /CHILD), SET_UVALUE=wid, /NO_COPY
  RETURN, base
END
