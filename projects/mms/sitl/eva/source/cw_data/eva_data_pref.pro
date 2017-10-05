
PRO eva_data_pref_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ;eva_data_update_board, state, value
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_data_pref_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
END

FUNCTION eva_data_pref_event, ev
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
    ;------------------
    ; EVA_CACHE_DIR
    ;------------------
    state.txtPath:begin
      widget_control,state.txtPath, GET_VALUE = file
      pref.EVA_CACHE_DIR = file
      end
    state.btnPath:begin
      cd,current = c; store path to current directory
      file = dialog_pickfile(path=c, /directory,TITLE=' Choose directory')
      if strlen(file) ne 0 then begin
        widget_control, state.txtPath, SET_VALUE = file
        pref.EVA_CACHE_DIR = file
      endif
      end
    ;------------------
    ; EVA_PARAMSET_DIR
    ;------------------
    state.txtPath2:begin
      widget_control,state.txtPath2, GET_VALUE = file
      pref.EVA_PARAMSET_DIR = file
      end
    state.btnPath2:begin
      cd,current = c; store path to current directory
      file = dialog_pickfile(path=c, /directory,TITLE=' Choose directory')
      if strlen(file) ne 0 then begin
        widget_control, state.txtPath2, SET_VALUE = file
        pref.EVA_PARAMSET_DIR = file
      endif
      end
    ;------------------
    ; ABS_LOCAL
    ;------------------
    state.txtPath3:begin
      widget_control,state.txtPath3, GET_VALUE = file
      pref.ABS_LOCAL = file
    end
    state.btnPath3:begin
      cd,current = c; store path to current directory
      file = dialog_pickfile(path=c, TITLE='Choose an ABS file (.sav)', FILTER='*.sav')
      if strlen(file) ne 0 then begin
        widget_control, state.txtPath3, SET_VALUE = file
        pref.ABS_LOCAL = file
      endif
      end
    else:
  endcase
  ;-----
  str_element,/add,state,'pref',pref
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION eva_data_pref, parent, GROUP_LEADER=group_leader, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize
  
  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for CW_sitl'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_data_pref'
  if not (keyword_set(title)) then title='   DATA   '

  ; ----- GET CURRENT PREFERENCES FROM THE MAIN MODULE -----
  widget_control, widget_info(group_leader,find='eva_data'), GET_VALUE=module_state
  state = {pref:module_state.PREF}
    
  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  
  ; main base
  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_data_pref_event", $
    FUNC_GET_VALUE = "eva_data_pref_get_value", $
    PRO_SET_VALUE = "eva_data_pref_set_value",/column,$
  XSIZE = xsize, YSIZE = ysize,sensitive=1)
  str_element,/add,state,'mainbase',mainbase
  
  ; path

  getresourcepath,rpath
  openBMP = read_bmp(rpath + 'folder_horizontal_open.bmp',/rgb)
  spd_ui_match_background, mainbase, openBMP

  str_element,/add,state,'lblCurrent',widget_label(mainbase,VALUE='EVA cache (.tplot files) location',XSIZE=xsize*0.9)
  baseInput = widget_base(mainbase,/row,/align_center)
    str_element,/add,state,'txtPath',widget_text(baseInput,VALUE=state.PREF.EVA_CACHE_DIR,XSIZE=55,/editable)
    str_element,/add,state,'btnPath',widget_button(baseInput,VALUE=openBMP,/Bitmap)
  
  str_element,/add,state,'lblParamSetList',widget_label(mainbase,VALUE='Location of customized parameterSet',XSIZE=xsize*0.9)
  baseInput2 = widget_base(mainbase,/row,/align_center)
    str_element,/add,state,'txtPath2',widget_text(baseInput2,VALUE=state.PREF.EVA_PARAMSET_DIR,XSIZE=55,/editable)
    str_element,/add,state,'btnPath2',widget_button(baseInput2,VALUE=openBMP,/Bitmap)

  str_element,/add,state,'lblPath',widget_label(mainbase,VALUE='Choose an ABS file (.sav)')
  baseInput3 = widget_base(mainbase,/row,/align_center)
    str_element,/add,state,'txtPath3',widget_text(baseInput3,VALUE=state.PREF.ABS_LOCAL,XSIZE=55,/editable)
    str_element,/add,state,'btnPath3',widget_button(baseInput3,VALUE=openBMP,/Bitmap)

  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY
  RETURN, mainbase
END
