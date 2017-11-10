
PRO eva_sitl_pref2_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ;eva_sitl_update_board, state, value
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_sitl_pref2_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
END

FUNCTION eva_sitl_pref2_event, ev
  compile_opt idl2
  @eva_sitl_com

  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }
  endif

  parent=ev.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  if n_tags(state) eq 0 then return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }
  pref = state.pref

  ;-----
  case ev.id of
    state.btnGuide:begin
      dir = file_search(ProgramRootDir(/ONEUP)+'script/',/MARK_DIRECTORY,/FULLY_QUALIFY_PATH); directory
      print, dir
      online_help, book = dir+'eva_script_guide.pdf'
      end
    state.btnIDs:eva_sitl_replace_id
    state.btnTXT2FOM:begin
      connected = mms_login_lasp(username = username, widget_note = widget_note)
      eva_sitl_restore_txt
      end
    state.btnFOM2BAK:begin
      eva_sitl_fom2bak
      end
    else:
  endcase
  ;-----

  str_element,/add,state,'pref',pref
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION eva_sitl_pref2, parent, GROUP_LEADER=group_leader, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for CW_sitl'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_sitl_pref2'
  if not (keyword_set(title)) then title='   TOOLS   '

  ; ----- GET STATE FROM EACH MODULE -----
  widget_control, widget_info(group_leader,find='eva_sitl'), GET_VALUE=state_sitl
  widget_control, widget_info(group_leader,find='eva_data'), GET_VALUE=state_data

  ; ----- STATE OF THIS WIDGET -----
  state = {pref:state_sitl.PREF, state_sitl:state_sitl}

  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_sitl_pref2_event", $
    FUNC_GET_VALUE = "eva_sitl_pref2_get_value", $
    PRO_SET_VALUE = "eva_sitl_pref2_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1,/base_align_left)
  str_element,/add,state,'mainbase',mainbase
  lblSpace1 = widget_label(mainbase,VALUE="  ")  
  str_element,/add,state,'btnGuide',widget_button(mainbase,VALUE=' Guide (open in PDF)')
  lblFOM2BAK2 = widget_label(mainbase,VALUE="  ")  
  str_element,/add,state,'btnIDs',widget_button(mainbase,VALUE=' Replace source-IDs in the selections')
  str_element,/add,state,'btnTXT2FOM',widget_button(mainbase,VALUE=' Import selections from TEXT to FOM-struct ')
  str_element,/add,state,'btnFOM2BAK',widget_button(mainbase,VALUE=' Import selections from SAV to BAK-struct ')
  


  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY
  RETURN, mainbase
END
