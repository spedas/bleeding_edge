PRO eva_sitlsubmit_submit, state, ev
  compile_opt idl2
  
  
  ;---------------------
  ; ACCESS SITL MODULE
  ;---------------------
  id_sitl = widget_info(state.parent, find_by_uname='eva_sitl')
  sitl_stash = WIDGET_INFO(id_sitl, /CHILD)
  widget_control, sitl_stash, GET_UVALUE=sitl_state, /NO_COPY;******* GET
  
  ;---------------------
  ; MAIN
  ;---------------------
  print,'EVA: ***** EVENT: btnSubmit *****'
  print,'EVA: TESTMODE='+string(sitl_state.PREF.EVA_TESTMODE_SUBMIT)

  if state.PREF.EVA_BAKSTRUCT then begin
    eva_sitl_submit_bakstr,ev.top, sitl_state.PREF.EVA_TESTMODE_SUBMIT
  endif else begin

    ; Look for pre-existing note
    get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
    tn = tag_names(lmod.unix_FOMstr_mod)
    idx = where(strmatch(tn,'NOTE'),ct)
    if ct gt 0 then begin
      varname = lmod.unix_FOMstr_mod.NOTE
    endif else varname = ''

    ; Textbox for NOTE
    varname = mms_TextBox(Title='EVA TEXTBOX', Group_Leader=ev.top, $
      Label='Please add/edit your comment on this ROI: ', $
      SecondLabel='(The text will wrap automatically. A carriage',$
      ThirdLabel='return is same as hitting the Save button.)',$
      Cancel=cancelled, Continue_Submission=contin, $
      XSize=300, Value=varname)

    ; Submission
    if not cancelled then begin
      print,'EVA: Saving the following string:', varname
      get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
      str_element,/add,lmod,'unix_FOMstr_mod.NOTE', varname
      store_data,'mms_stlm_fomstr',data=Dmod, lim=lmod, dl=dlmod
      if contin then begin
        print,'EVA: Continue Submission....'
        vcase = 0;(state.USER_FLAG eq 4) ? 3 : 0
        eva_sitl_submit_fomstr,ev.top, sitl_state.PREF.EVA_TESTMODE_SUBMIT, vcase, user_flag=sitl_state.USER_FLAG
      endif else print,'EVA:  but just saved...'
    endif else begin
      print,'EVA: Submission cancelled...'
    endelse
  endelse
  
  widget_control, sitl_stash, SET_UVALUE=sitl_state, /NO_COPY;******* SET
END

PRO eva_sitlsubmit_set_value, id, value ;In this case, value = activate
  compile_opt idl2, hidden
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  str_element,/add,state,'pref',value
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_sitlsubmit_get_value, id
  compile_opt idl2, hidden
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
END

FUNCTION eva_sitlsubmit_event, ev
  compile_opt idl2

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return, {ID:ev.handler, TOP:ev.top, HANDLER:0L }
  endif


  parent=ev.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  exitcode=0

  val = mms_load_fom_validation()
  str_element,/add,state,'val',val
  
  ;-----
  case ev.id of
    state.btnValidate: begin
      print,'EVA: ***** EVENT: btnValidate *****'
      title = 'Validation'
      if state.PREF.EVA_BAKSTRUCT then begin
        tn = tnames()
        idx = where(strmatch(tn,'mms_stlm_bakstr'),ct)
        if ct eq 0 then begin
          msg = 'Back-Structure not found. If you wish to'
          msg = [msg, 'submit a FOM structure, please disable the back-']
          msg = [msg, 'structure mode.']
          rst = dialog_message(msg,/error,/center,title=title)
        endif else begin
          get_data,'mms_stlm_bakstr',data=Dmod, lim=lmod,dl=dlmod
          get_data,'mms_soca_bakstr',data=Dorg, lim=lorg,dl=dlorg
          tai_BAKStr_org = lorg.unix_BAKStr_org
          str_element,/add,tai_BAKStr_org,'START', mms_unix2tai(lorg.unix_BAKStr_org.START); LONG
          str_element,/add,tai_BAKStr_org,'STOP',  mms_unix2tai(lorg.unix_BAKStr_org.STOP) ; LONG
          tai_BAKStr_mod = lmod.unix_BAKStr_mod
          str_element,/add,tai_BAKStr_mod,'START', mms_unix2tai(lmod.unix_BAKStr_mod.START); LONG
          str_element,/add,tai_BAKStr_mod,'STOP',  mms_unix2tai(lmod.unix_BAKStr_mod.STOP) ; LONG
  
          header = eva_sitl_text_selection(lmod.unix_BAKStr_mod,/bak)
  
          vsp = '////////////////////////////'
          header = [header, vsp+' VALIDATION RESTULT (NEW SEGMENTS) '+vsp]
          r = eva_sitl_validate(tai_BAKStr_mod, -1, vcase=1, header=header, /quiet, valstruct=state.val); Validate New Segs
          header = [r.msg,' ', vsp+' VALIDATION RESULT (MODIFIED SEGMENTS) '+vsp]
          r2 = eva_sitl_validate(tai_BAKStr_mod, tai_BAKStr_org, vcase=2, header=header, valstruct=state.val); Validate Modified Seg
          
          
        endelse; if ct eq 0
      endif else begin
        get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
        get_data,'mms_soca_fomstr',data=Dorg, lim=lorg,dl=dlorg
        mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
        mms_convert_fom_unix2tai, lorg.unix_FOMStr_org, tai_FOMstr_org; Original FOM for reference
        header = eva_sitl_text_selection(lmod.unix_FOMstr_mod)
        vcase = 0;(state.USER_FLAG eq 4) ? 3 : 0
        r  = eva_sitl_validate(tai_FOMstr_mod, tai_FOMstr_org, vcase=vcase, header=header, valstruct=state.val)
        if(lmod.UNIX_FOMSTR_MOD.UPLINKFLAG eq 1) then begin
          r2 = eva_sitluplink_validateFOM(lmod.UNIX_FOMSTR_MOD)
        endif
      endelse
    end
    state.btnDraft: eva_sitlsubmit_submit, state, ev
    state.btnUplink: eva_sitlsubmit_submit, state, ev
    else:
  endcase

    
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END


FUNCTION eva_sitlsubmit, parent, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, XSIZE = xsize, YSIZE = ysize
  compile_opt idl2

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for eva_sitlsubmit'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_sitlsubmit'
  
  ; ----- STATE -----
  pref = {$
    EVA_BAKSTRUCT: 0}
  str_element,/add,state,'parent',parent
  str_element,/add,state,'pref',pref
  
  ; ----- WIDGET LAYOUT -----

  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, /row,$
    EVENT_FUNC = "eva_sitlsubmit_event", $
    FUNC_GET_VALUE = "eva_sitlsubmit_get_value", $
    PRO_SET_VALUE = "eva_sitlsubmit_set_value", $
    XSIZE = xsize, YSIZE = ysize, SENSITIVE=0)
  str_element,/add,state,'mainbase',mainbase


  str_element,/add,state,'btnValidate',widget_button(mainbase,VALUE=' Validate ')
  dumSubmit = widget_base(mainbase,xsize=100)
  lbl       = widget_label(mainbase,VALUE='SUBMIT')
  str_element,/add,state,'btnDraft',widget_button(mainbase,VALUE=' DRAFT ')
  str_element,/add,state,'btnUplink',widget_button(mainbase,VALUE=' UPLINK ',SENSITIVE=0)








  ; Save out the initial state structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY

  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, mainbase
END