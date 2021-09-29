; Update the EVALSTARTTIME tag in FOMstr
PRO eva_sitluplink_update_evalstarttime, str_evalstarttime
  compile_opt idl2

  tn=tnames('mms_stlm_fomstr',ct)
  if(ct eq 1) then begin
    get_data,'mms_stlm_fomstr',data=D,dl=dl,lim=lim
    s = lim.UNIX_FOMSTR_MOD
    if(str_evalstarttime eq 'N/A') then begin
      str_element,/delete,s,'evalstarttime'
    endif else begin
      str_element,/add, s, 'evalstarttime', time_double(str_evalstarttime)
    endelse
    options,'mms_stlm_fomstr','unix_FOMStr_mod',s ; update structure
  endif
END

; Update the UPLINGFLAG tag in FOMstr
PRO eva_sitluplink_update_uplinkflag, uplinkflag
  compile_opt idl2

  tn=tnames('mms_stlm_fomstr',ct)
  if(ct eq 1) then begin
    get_data,'mms_stlm_fomstr',data=D,dl=dl,lim=lim
    s = lim.UNIX_FOMSTR_MOD
    str_element,/add, s, 'uplinkflag', uplinkflag
    options,'mms_stlm_fomstr','unix_FOMStr_mod',s ; update structure
  endif
END

; Update the diplay in the SITL tab and also validate
PRO eva_sitluplink_display_and_validate, state
  compile_opt idl2
  
  tn=tnames('mms_stlm_fomstr',ct)
  if(ct eq 1) then begin
    get_data,'mms_stlm_fomstr',data=D,dl=dl,lim=lim
  endif else message,'mms_stlm_fomstr not found.'

  tn = tag_names(lim.UNIX_FOMSTR_MOD)
  idx = where(strlowcase(tn) eq 'evalstarttime', ct)
  str_time = (ct eq 1) ? time_string(lim.UNIX_FOMSTR_MOD.EVALSTARTTIME) : 'N/A'
  uplinkflag = lim.UNIX_FOMSTR_MOD.UPLINKFLAG
  if uplinkflag then begin
    btnDraft = 0
    btnUplink = 1
  endif else begin
    btnDraft = 1
    btnUplink = 0
  endelse
  
;  idx = where(strlowcase(tn) eq 'uplinkflag', ct)
;  strButton = 'DRAFT'
;  if (ct gt 0)  && (lim.UNIX_FOMSTR_MOD.UPLINKFLAG eq 1) then begin
;    strButton = 'UPLINK'
;  endif

;  id_sitl = widget_info(state.parent, find_by_uname='eva_sitl')
;  sitl_stash = WIDGET_INFO(id_sitl, /CHILD)
;  WIDGET_CONTROL, sitl_stash, GET_UVALUE=sitl_state, /NO_COPY
;  widget_control, sitl_state.lblEvalStartTime, SET_VALUE='Next SITL Window Start Time: '+str_time
;  widget_control, sitl_state.btnSubmit, SET_VALUE='   '+strButton+'   '
;  WIDGET_CONTROL, sitl_stash, SET_UVALUE=sitl_state, /NO_COPY

  id_submit = widget_info(state.parent2, find_by_uname='eva_sitlsubmit')
  submit_stash = WIDGET_INFO(id_submit, /CHILD)
  widget_control, submit_stash, GET_UVALUE=submit_state, /NO_COPY;******* GET
  widget_control, submit_state.btnDraft,SENSITIVE=btnDraft
  widget_control, submit_state.btnUplink,SENSITIVE=btnUplink
  widget_control, submit_stash, SET_UVALUE=submit_state, /NO_COPY;******* SET

  widget_control, state.lblw1, SENSITIVE=btnUplink
  widget_control, state.lblw2, SENSITIVE=btnUplink
  widget_control, state.lblw3, SENSITIVE=btnUplink
  
  ;--------------------
  ; Validation by Rick
  ;--------------------
;  if(uplinkflag) then begin
;    r = eva_sitluplink_validateFOM(lim.UNIX_FOMSTR_MOD)
;    if(r gt 0) then begin
;      eva_sitluplink_update_evalstarttime, 'N/A'
;      eva_sitluplink_update_uplinkflag, 0
;      widget_control,state.bgUplink,SET_VALUE=0L
;      tplot
;    endif
;  endif
  
  return
END

PRO eva_sitluplink_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  if n_tags(value) eq 0 then begin
    eva_sitl_update_board, state, value
  endif else begin
    str_element,/add,state,'pref',value
  endelse
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_sitluplink_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
END

FUNCTION eva_sitluplink_event, ev
  compile_opt idl2
  @xtplot_com.pro
  @tplot_com

  parent=ev.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  if n_tags(state) eq 0 then return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
    message, /reset
    return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }
  endif

  update=0
  
  case ev.id of
    state.fldEvalStartTime: begin
      widget_control, ev.id, GET_VALUE=new_time;get new time
      if(strlen(new_time) ge 13) then begin
        eva_sitluplink_update_evalstarttime, new_time[0]
        update=1
      endif
    end
    state.calEvalStartTime: begin
      ;------------------
      ; Initialize time
      ;------------------
      tn = tnames()
      idx=where(tn eq 'mms_soca_fomstr',ct)
      if(ct eq 1) then begin
        get_data,'mms_soca_fomstr',dl=dl,lim=lim
        s = lim.UNIX_FOMSTR_ORG
        tgn = tag_names(s)
        stime = s.TIMESTAMPS[0]
        etime = s.TIMESTAMPS[s.NUMCYCLES-1]
        gtime = stime + 0.66666d0*(etime-stime)
      endif else begin
        gtime = 0.d0
      endelse

      ;------------------
      ; Calendar
      ;------------------
      otime = obj_new('spd_ui_time')
      otime->SetProperty,tstring=time_string(gtime)
      spd_ui_calendar,'EVA Calendar',otime,ev.top
      otime->GetProperty,tstring=tstring         ; get tstring
      eva_sitluplink_update_evalstarttime, tstring
      obj_destroy, otime
      
      ;------------------
      ; Timebar
      ;------------------
      timebar,time_double(tstring), linestyle = 2, thick = 2;,/transient
      widget_control, state.fldEvalStartTime, SET_VALUE=tstring
      update=1
    end
    state.btnEvalStartTime: begin
      ctime,time,y,z,npoints=1
      timebar,time, linestyle = 2, thick = 2;,/transient
      if(time gt 0) then begin
        tstring = time_string(time)
        eva_sitluplink_update_evalstarttime, tstring
        widget_control, state.fldEvalStartTime, SET_VALUE=tstring
        update=1
      endif else begin
        print, 'SITL window start-time not selected.'
      endelse
    end
    state.btnDraw: begin
      widget_control, state.fldEvalStartTime, GET_VALUE=time; update GUI field
      timebar,time, linestyle = 2, thick = 2
    end
    state.btnErase: begin
      tplot
      ;timebar,state.EvalStartTimeDouble, linestyle = 2, thick = 2,/transient
    end
    state.btnReset: begin
      eva_sitluplink_update_evalstarttime, 'N/A'
      eva_sitluplink_update_uplinkflag, 0
      widget_control,state.bgUplink,SET_VALUE=0
      widget_control,state.fldEvalStartTime, SET_VALUE='N/A'
      tplot
      update=1
    end
    state.bgUplink: begin
      widget_control,state.bgUplink,GET_VALUE=gvl
      if(ev.SELECT eq 1) then begin
        if (gvl eq 1)  then begin ; ..................... Yes (Check for evalstarttime)
          tn=tnames('mms_stlm_fomstr',ct)
          if(ct eq 1) then begin
            get_data,'mms_stlm_fomstr',data=D,dl=dl,lim=lim
            tn = tag_names(lim.UNIX_FOMSTR_MOD)
            idx = where(strlowcase(tn) eq 'evalstarttime', ct)
            if(ct eq 0) then begin; ...........................EVAL-STARTTIME not found
              result = dialog_message("Please set start time first.",/center)
              widget_control,state.bgUplink,SET_VALUE=0L
              update=0
            endif else begin;.................... EVAL-STARTTIME found
              eva_sitluplink_update_uplinkflag, gvl ; update FOM
              update=1
            endelse
          endif else message,'mms_stlm_fomstr not found.'
          ;widget_control, state.mainbase, BASE_SET_TITLE=' DISABLE UPLINK '
        endif else begin; if gvl eq 0
          eva_sitluplink_update_uplinkflag, gvl
          ;widget_control, state.mainbase, BASE_SET_TITLE=' ENABLE UPLINK '
          update=1
        endelse
      endif
      end
    else:
  endcase

  if update then eva_sitluplink_display_and_validate, state


  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION eva_sitluplink, parent, parent2, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize
  compile_opt idl2

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for CW_sitl'

  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_sitluplink'
  if not (keyword_set(title)) then title=' ENABLE UPLINK '

  ; ----- STATE -----
  state = {$
    parent:parent,$
    parent2:parent2,$
    EvalStartTime: 'N/A',$
    EvalStopTime: 'N/A',$
    EvalStartTimeDouble: 0.d0}

  ; ----- CONFIG (READ) -----
  cfg = mms_config_read()         ; Read config file and
  pref = mms_config_push(cfg,pref); push the values into preferences
  str_element,/add,state,'pref',pref

  ; ----- SETTINGS ------
;  ;//////////////////////////////
;  valUplinkflag = !VALUES.F_NAN
;  valEvalstarttime = 'N/A'
;  ;//////////////////////////////
;  tn = tnames()
;  idx=where(tn eq 'mms_soca_fomstr',ct)
;  if(ct eq 1) then begin
;    get_data,'mms_soca_fomstr',dl=dl,lim=lim
;    s = lim.UNIX_FOMSTR_ORG
;    tgn = tag_names(s)
;    idxA=where(strlowcase(tgn) eq 'uplinkflag',ctA)
;    idxB=where(strlowcase(tgn) eq 'evalstarttime',ctB)
;    valUplinkflag = (ctA eq 1) ? s.UPLINKFLAG : valUplinkflag
;    valEvalstarttime  = (ctB eq 1) ? s.EVALSTARTTIME : valEvalstarttime
;  endif


  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  
  ; calendar icon
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, parent, cal; thm_ui_match_background

  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_sitluplink_event", $
    FUNC_GET_VALUE = "eva_sitluplink_get_value", $
    PRO_SET_VALUE = "eva_sitluplink_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1, SPACE=0, YPAD=0)
  str_element,/add,state,'mainbase',mainbase

  subbase = widget_base(mainbase,/column,sensitive=0)
  str_element,/add,state,'subbase',subbase
  
;    str_element,/add,state,'lblDummy1',widget_label(subbase,VALUE=' ')
    
    str_element,/add,state,'lblABS',widget_label(subbase,VALUE='Original Settings in ABS:')
    bsABS = widget_base(subbase, /COLUMN, SPACE=0, YPAD=0,/frame,xsize=xsize*0.94)
      str_element,/add,state,'lblABS_tstart',widget_label(bsABS,VALUE='EVAL START TIME: N/A',/align_left)
      str_element,/add,state,'lblABS_uplink',widget_label(bsABS,VALUE='UPLINK FLAG: N/A',/align_left)

    str_element,/add,state,'lblDummy2',widget_label(subbase,VALUE=' ')
    
    str_element,/add,state,'lblFOM',widget_label(subbase,VALUE='Set Window Close Time')
    str_element,/add,state,'lblFOM2',widget_label(subbase,VALUE='(= Next Window Start Time)')
    bsFOM = widget_base(subbase, /COLUMN, SPACE=0, YPAD=0,/frame,xsize=xsize*0.94,/align_center)
      lblEvalStartTime = widget_label(bsFOM,VALUE='  ',/align_left)
      bsEvalStartTime = widget_base(bsFOM,/row, SPACE=0, YPAD=0)
        str_element,/add,state,'fldEvalStartTime',cw_field(bsEvalStartTime,VALUE=valEvalstarttime,TITLE='',/ALL_EVENTS,XSIZE=24)
        str_element,/add,state,'calEvalStartTime',widget_button(bsEvalStartTime,VALUE=cal)
        str_element,/add,state,'btnEvalStartTime',widget_button(bsEvalStartTime,VALUE=' Cursor ')
      bsReset = widget_base(bsFOM,/row, SPACE=0, YPAD=0,/align_center)
        str_element,/add,state,'btnDraw',widget_button(bsReset,VALUE=' Draw ');,xsize=150)
        lblReset1 = widget_label(bsReset,VALUE=' ')
        str_element,/add,state,'btnErase',widget_button(bsReset,VALUE=' Refresh ');,xsize=150)
        lblReset2 = widget_label(bsReset,VALUE='     ')
        str_element,/add,state,'btnReset',widget_button(bsReset,VALUE=' Reset ');,xsize=150)
    
    bsUplink = widget_base(subbase,/row, SPACE=0, YPAD=0)
      lblUplink = widget_label(bsUplink,VALUE='Uplink',/align_left)
      lblUplinkDummy = widget_label(bsUplink,VALUE=': ',/align_left)
      str_element,/add,state,'bgUplink',cw_bgroup(bsUplink,['Disabled','Enabled'],$
        EXCLUSIVE=1,SET_VALUE=0,COLUMN=2)
    str_element,/add,state,'lblw1',widget_label(subbase,VALUE='Click the UPLINK button to finalize',sensitive=0)
    str_element,/add,state,'lblw2',widget_label(subbase,VALUE='submission and close the SITL window.',sensitive=0)
    str_element,/add,state,'lblw3',widget_label(subbase,VALUE='YOU CANNOT UNDO THIS ACTION.',sensitive=0)

  ; Save out the initial state structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY

  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, mainbase
END
