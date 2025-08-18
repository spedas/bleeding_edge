
PRO eva_pref_gen_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ;eva_sitl_update_board, state, value
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_pref_gen_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
END

FUNCTION eva_pref_gen_event, ev
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

  ;-----
  case ev.id of
    state.fldCPWIDTH:begin
      widget_control, ev.id, GET_VALUE=strNewWidth
      str_element,/add,state,'PREF.EVA_CPWIDTH',long(strNewWidth[0])
    end
    state.btnDefault:begin
      str_element,/add,state,'PREF.EVA_CPWIDTH',state.cpwidth_default
      widget_control, state.fldCPWIDTH, SET_VALUE=state.cpwidth_default; update GUI field
      end
    state.fldBasePos:begin
      widget_control, ev.id, GET_VALUE=strNewBasePos
      str_element,/add,state,'PREF.EVA_BASEPOS',long(strNewBasePos[0])
      end
    state.btnBasePos_Default:begin
      str_element,/add,state,'PREF.EVA_BASEPOS',state.basepos_default
      widget_control, state.fldBasePos, SET_VALUE=state.basepos_default
      end
    else:
  endcase
  ;-----

  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION eva_pref_gen, parent, GROUP_LEADER=group_leader, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for eva_pref_gen'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_pref_gen'
  if not (keyword_set(title)) then title='  GENERAL  '

  ; ----- GET STATE FROM EACH MODULE -----
  widget_control, widget_info(group_leader,find='eva_sitl'), GET_VALUE=state_sitl
  widget_control, widget_info(group_leader,find='eva_data'), GET_VALUE=state_data

  ; ----- PREFERENCES -----
  widget_control, state_data.PARENT, GET_UVALUE=eva_wid
  cfg = mms_config_read()
  idx=where(strmatch(tag_names(cfg),'EVA_CPWIDTH'),ct)
  if ct gt 0 then cpwidth = cfg.EVA_CPWIDTH else cpwidth=eva_wid.CPWIDTH_DEFAULT
  idx=where(strmatch(tag_names(cfg),'EVA_BASEPOS'),ct)
  if ct gt 0 then basepos = cfg.EVA_BASEPOS else basepos=eva_wid.BASEPOS_DEFAULT

  pref = {EVA_CPWIDTH: cpwidth, EVA_BASEPOS: basepos}
  
  ; ---- STATE ----
  state = {cpwidth_default:eva_wid.cpwidth_default, group_leader:group_leader,$
           basepos_default:eva_wid.basepos_default, pref:pref}

  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_pref_gen_event", $
    FUNC_GET_VALUE = "eva_pref_gen_get_value", $
    PRO_SET_VALUE = "eva_pref_gen_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1,/base_align_left)
  str_element,/add,state,'mainbase',mainbase
  lblSpace1 = widget_label(mainbase,VALUE="  ")
  str_element,/add,state,'fldCPWIDTH',cw_field(mainbase,VALUE=pref.EVA_CPWIDTH,TITLE='Control Panel Width',/ALL_EVENTS,XSIZE=10)
  str_element,/add,state,'btnDefault',widget_button(mainbase,VALUE=' Default')
  str_element,/add,state,'fldBasePos',cw_field(mainbase,VALUE=pref.EVA_BASEPOS,TITLE='Screen Base Position',/ALL_EVENTS,XSIZE=10)
  str_element,/add,state,'btnBasePos_default',widget_button(mainbase,VALUE=' Default')
  
  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY
  RETURN, mainbase
END
