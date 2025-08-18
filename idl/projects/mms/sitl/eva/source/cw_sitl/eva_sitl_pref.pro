
PRO eva_sitl_pref_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ;eva_sitl_update_board, state, value
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_sitl_pref_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY  
  return, ret
END

FUNCTION eva_sitl_pref_event, ev
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
    state.bgAdvanced:  begin;{ID:0L, TOP:0L, HANDLER:0L, SELECT:0, VALUE:0 }
      pref.EVA_BAKSTRUCT = ev.SELECT 
      widget_control, state.STATE_SITL.drpSave, SENSITIVE=(~ev.SELECT)
;      widget_control, state.STATE_SITL.btnUndo, SENSITIVE=(~ev.SELECT)
;      widget_control, state.STATE_SITL.btnRedo, SENSITIVE=(~ev.SELECT)
;      widget_control, state.STATE_SITL.btnAllAuto, SENSITIVE=(~ev.SELECT)
      widget_control, state.STATE_SITL.cbMulti, SENSITIVE=(~ev.SELECT)
      widget_control, state.STATE_SITL.cbWTrng, SENSITIVE=(~ev.SELECT)
;      widget_control, state.STATE_SITL.btnSplit, SENSITIVE=(~ev.SELECT)
;      widget_control, state.STATE_SITL.btnFill, SENSITIVE=(~ev.SELECT)
;      widget_control, state.STATE_SITL.drpHighlight, SENSITIVE=ev.SELECT
      
      ;---------------------
      ; Update SUBMIT MODULE
      ;---------------------
      strButton = (ev.SELECT) ? 'BAKSTR' : 'DRAFT'
      id_submit = widget_info(state.group_leader, find_by_uname='eva_sitlsubmit')
      submit_stash = WIDGET_INFO(id_submit, /CHILD)
      widget_control, submit_stash, GET_UVALUE=submit_state, /NO_COPY;******* GET
      widget_control, submit_state.btnDraft, SET_VALUE = ' '+strButton+' '
      submit_state.PREF.EVA_BAKSTRUCT = ev.SELECT
      widget_control, submit_stash, SET_UVALUE=submit_state, /NO_COPY;******* SET
      id_submit = widget_info(state.group_leader, find_by_uname='eva_sitluplink')
      submit_stash = WIDGET_INFO(id_submit, /CHILD)
      widget_control, submit_stash, GET_UVALUE=submit_state, /NO_COPY;******* GET
      widget_control, submit_state.mainbase, SENSITIVE=(~ev.SELECT)
      widget_control, submit_stash, SET_UVALUE=submit_state, /NO_COPY;******* SET
      end
    state.bgTestmode:  begin;{ID:0L, TOP:0L, HANDLER:0L, SELECT:0, VALUE:0 }
      pref.EVA_TESTMODE_SUBMIT = (~ev.SELECT); "Selected" means "submission enabled (i.e, not in test mode)"
      end
    state.btnSplitNominal: begin
      r = get_mms_sitl_connection(group_leader=ev.TOP)
      val = mms_load_fom_validation()
      pref.EVA_SPLIT_SIZE = val.NOMINAL_SEG_RANGE[1]
      widget_control, state.fldSplit, SET_VALUE=strtrim(string(pref.EVA_SPLIT_SIZE),2)
      end
    state.btnSplitMaximum: begin
      r = get_mms_sitl_connection(group_leader=ev.TOP)
      val = mms_load_fom_validation()
      pref.EVA_SPLIT_SIZE = val.SEG_BOUNDS[1]
      widget_control, state.fldSplit, SET_VALUE=strtrim(string(pref.EVA_SPLIT_SIZE),2)
      end
    state.fldSplit: begin
      pref.EVA_SPLIT_SIZE = long(ev.VALUE)
      end
    state.drpGLS1: begin; { WIDGET_DROPLIST, ID:0L, TOP:0L, HANDLER:0L, INDEX:0L }
      pref.EVA_GLS1_ALGO = state.glSet[ev.INDEX]
      end
    state.drpGLS2: begin; { WIDGET_DROPLIST, ID:0L, TOP:0L, HANDLER:0L, INDEX:0L }
      pref.EVA_GLS2_ALGO = state.glSet[ev.INDEX]
    end
    state.drpGLS3: begin; { WIDGET_DROPLIST, ID:0L, TOP:0L, HANDLER:0L, INDEX:0L }
      pref.EVA_GLS3_ALGO = state.glSet[ev.INDEX]
    end

;    state.bgPath: begin;{ID:0L, TOP:0L, HANDLER:0L, SELECT:0, VALUE:0 }
;      pref.EVA_STLM_INPUT = state.PATH_VALUES[ev.VALUE]
;      print, pref.EVA_STLM_INPUT,' is chosen'
;      end
    else:
  endcase
  ;-----
  
  str_element,/add,state,'pref',pref
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION eva_sitl_pref, parent, GROUP_LEADER=group_leader, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize
  
  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for CW_sitl'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_sitl_pref'
  if not (keyword_set(title)) then title='   SITL   '

  ; ----- GET STATE FROM EACH MODULE -----
  widget_control, widget_info(group_leader,find='eva_sitl'), GET_VALUE=state_sitl
  widget_control, widget_info(group_leader,find='eva_data'), GET_VALUE=state_data

  ; ----- STATE OF THIS WIDGET -----  
  path_values = ['soca','socs','stla']
  state = {pref:state_sitl.PREF, state_sitl:state_sitl, path_values:path_values, $
    group_leader:group_leader}
    
  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_sitl_pref_event", $
    FUNC_GET_VALUE = "eva_sitl_pref_get_value", $
    PRO_SET_VALUE = "eva_sitl_pref_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1,/base_align_left)
  str_element,/add,state,'mainbase',mainbase

  bsGLS = widget_base(mainbase,/column,/frame, space=0, ypad=0)
    lblGLS = widget_label(bsGLS,VALUE='EVA can display up to three ground-loop variables.')
    glSet = ['none','mp-dl-unh']
    str_element,/add,state,'drpGLS1',widget_droplist(bsGLS,VALUE=glSet,TITLE='Ground loop algorithm 1:',SENSITIVE=1)
    str_element,/add,state,'drpGLS2',widget_droplist(bsGLS,VALUE=glSet,TITLE='Ground loop algorithm 2:',SENSITIVE=1)
    str_element,/add,state,'drpGLS3',widget_droplist(bsGLS,VALUE=glSet,TITLE='Ground loop algorithm 3:',SENSITIVE=1)
    str_element,/add,state,'glSet',glSet
    idx = where(glSet eq state.PREF.EVA_GLS1_ALGO,ct)
    if ct gt 0 then widget_control,state.drpGLS1, SET_DROPLIST_SELECT=idx[0]
    idx = where(glSet eq state.PREF.EVA_GLS2_ALGO,ct)
    if ct gt 0 then widget_control,state.drpGLS2, SET_DROPLIST_SELECT=idx[0]
    idx = where(glSet eq state.PREF.EVA_GLS3_ALGO,ct)
    if ct gt 0 then widget_control,state.drpGLS3, SET_DROPLIST_SELECT=idx[0]

  str_element,/add,state,'bgTestmode',cw_bgroup(mainbase,'Enable file submission to SDC',$
    /NONEXCLUSIVE,SET_VALUE=(~state.PREF.EVA_TESTMODE_SUBMIT))
    
  str_cs = strtrim(string(state.PREF.EVA_SPLIT_SIZE),2)
  baseSplit = widget_base(mainbase,space=0,ypad=0,/ROW)
  str_element,/add,state,'fldSplit',cw_field(baseSplit,VALUE=str_cs,TITLE='Split Size: ',/ALL_EVENTS,XSIZE=7)
  str_element,/add,state,'btnSplitNominal',widget_button(baseSplit,VALUE=' Nominal Limit ')
  str_element,/add,state,'btnSplitMaximum',widget_button(baseSplit,VALUE=' Maximum Limit ')
  lblSplit1 = widget_label(mainbase,VALUE="   If 0, EVA will use the default split size")
  lblSplit2 = widget_label(mainbase,VALUE="   which is 1/2 of the nominal limit")
  
  lblSpace = widget_label(mainbase,VALUE=' ')
  lblSuper = widget_label(mainbase,VALUE="Options for super-SITL:")
  bsAdvanced = widget_base(mainbase,space=0,ypad=0,SENSITIVE=(state_data.USER_FLAG eq 2)); Super SITL only
    str_element,/add,state,'bsAdvanced',bsAdvanced
    str_element,/add,state,'bgAdvanced',cw_bgroup(bsAdvanced,'Enable advanced features (i.e., editing back-structure)',$
     /NONEXCLUSIVE,SET_VALUE=state.PREF.EVA_BAKSTRUCT)
  


  
;  path_values_labels = ['SOC Auto (ABS)', 'SOC Auto (ABS) Simulated','SITL Auto']
;  idx = where(strmatch(path_values,state.PREF.EVA_STLM_INPUT),ct)
;  if ct ne 1 then idx = [0]
;  str_element,/add,state,'bgPath',cw_bgroup(mainbase, path_values_labels,$
;    /EXCLUSIVE, LABEL_TOP='Default FOM Selection',/FRAME, SET_VALUE=idx[0])
     

  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY
  RETURN, mainbase
END
