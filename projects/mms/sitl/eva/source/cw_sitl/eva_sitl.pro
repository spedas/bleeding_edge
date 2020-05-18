
PRO eva_sitl_cleanup, parent=parent
  @eva_sitl_com
;  id_sitl = widget_info(parent, find_by_uname='eva_sitl')
;  widget_control, id_sitl, GET_VALUE=s
  
  obj_destroy,sg.myview
  obj_destroy,sg.myviewB
  obj_destroy,sg.myfont
  obj_destroy,sg.myfontL
END

PRO eva_sitl_fom_recover,strcmd
  compile_opt idl2
  @eva_sitl_com

  i = i_fom_stack; which step to plot? current--> i=0, one_step_past--> i=1

  imax = n_elements(fom_stack)
  case strcmd of
    'undo': i++; one step backward in time
    'redo': i--; one step forward in time
    'rvrt': i = imax-1
  endcase

  case 1 of
    i lt 0    : i = 0
    i ge imax : i = imax-1
    else: begin
      ptr = fom_stack[i]
      dr = *ptr
      tfom = eva_sitl_tfom(dr.F)
      store_data,'mms_stlm_fomstr',data=eva_sitl_strct_read(dr.F,tfom[0])
      options,'mms_stlm_fomstr','unix_FOMStr_mod',dr.F
      if (n_tags(dr.B) gt 0) then begin
        store_data,'mms_stlm_bakstr',data=eva_sitl_strct_read(dr.B,min(dr.B.START,/nan))
        options,'mms_stlm_bakstr','unix_BAKStr_mod',dr.B
      endif
      eva_sitl_strct_yrange,'mms_stlm_output_fom'
      eva_sitl_strct_yrange,'mms_stlm_fomstr'
      tplot,verbose=0
    end
  endcase
  i_fom_stack = i
END

; This procedure validates the input 't' (in FOMstr mode)
FUNCTION eva_sitl_seg_validate, t
  compile_opt idl2

  get_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
  tfom = eva_sitl_tfom(lim.UNIX_FOMSTR_MOD)
  nt = n_elements(t)
  case nt of
    1: msg =  ((t lt tfom[0]) or (tfom[1] lt t)) ? 'Out of time range' : 'ok' 
    2: begin
      r = segment_overlap(t, tfom)
      case r of
        -2: msg = 'Out of time range'
        -1: msg = 'Out of time range'
        1: msg = 'Out of time range'
        2: msg = 'Out of time range'
        4: msg = 'Segment too big.'
        else: msg = 'ok'
      end; case r of
      end
    else:message,'"t" must be 1 or 2 element array.'
  endcase
  if ~strmatch(msg,'ok') then rst = dialog_message(msg,/info,/center)
  return, msg
END

; For a given time range 'trange', create "segSelect"
; which will be passed to eva_sitl_FOMedit for editing
PRO eva_sitl_seg_add, trange, state=state, var=var
  compile_opt idl2

  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return
  endif
  trange_org = trange
  ; validation (trange)
  if n_elements(trange) ne 2 then begin
    rst = dialog_message('Select a time interval by two left-clicks.',/info,/center)
    return
  endif

  if trange[1] lt trange[0] then begin
    trange_temp = trange[0]
    trange = [trange[1], trange_temp]
  endif

  if ~state.pref.EVA_BAKSTRUCT then begin
    BAK = 0
    msg = eva_sitl_seg_validate(trange) ; Validate against FOM time interval
    if ~strmatch(msg,'ok') then return
  endif else BAK = 1
  
  time = timerange(/current)
  
  if BAK eq 1 then begin
    ; validation (BAKStr: make sure 'trange' does not overlap with existing segments)
    get_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl
    s = lim.unix_BAKStr_mod
    Nsegs = n_elements(s.FOM)

    ct_overlap = 0; count number of overlapped segments
    for N=0,Nsegs-1 do begin
      if (strpos(s.STATUS[N],'DELETED') lt 0) then begin
        if s.START[N] gt s.STOP[N] then begin
;          print, 'N=',N
;          print, 'start=',time_string(s.START[N])
;          print, 'stop=',time_string(s.STOP[N])
;          print, 'trange_org=',time_string(trange_org)
;          stop
;          message,'Something is wrong'
          print, 'EVA: something is wrong'
        endif else begin
          rr = segment_overlap([s.START[N],s.STOP[N]],trange)
          if ((rr eq 4) or (rr eq 3) or (rr eq -1) or (rr eq 1) or (rr eq 0)) then ct_overlap += 1
        endelse
      endif
    endfor
    NOTOK = (ct_overlap gt 0)
    if NOTOK then begin
      msg = 'A new segment must not overlap with existing segments.'
      print, msg
      print,' Selected: ',time_string(trange)
      print,' ct_overlap = ', ct_overlap
      rst = dialog_message(msg,/info,/center)
      return
    endif
    wgrid = [0];s.TIMESTAMPS
    
    ;if trange passed the overlap test, then find the limit for time-range modification
    ;during ADD process.
    
    idx = where(strpos(s.STATUS,'DELETED') lt 0,ND_Nsegs)
    ND_START = s.START[idx]
    ND_STOP  = s.STOP[idx]
    for N=0,ND_Nsegs-2 do begin
      if (ND_STOP[N] lt trange[0]) and (trange[1] le ND_START[N+1]) then begin
        ts_limit = ND_STOP[N]+10.d0
        te_limit = ND_START[N+1]-10.d0
      endif
    endfor
    if trange[1] lt ND_START[0] then begin
      ts_limit = 0.d0
      te_limit = ND_START[0]-10.d0
    endif
    if trange[0] gt ND_STOP[ND_Nsegs-1] then begin
      ts_limit = ND_STOP[ND_Nsegs-1]+10.d0
      te_limit = systime(1,/utc)
    endif
    if ts_limit lt time[0] then ts_limit = time[0]
    if te_limit gt time[1] then te_limit = time[1]
  endif

  if BAK eq 0 then begin
    get_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
    s = lim.unix_FOMStr_mod
    dtlast = s.TIMESTAMPS[s.NUMCYCLES-1]-s.TIMESTAMPS[s.NUMCYCLES-2]
    wgrid = [s.TIMESTAMPS,s.TIMESTAMPS[s.NUMCYCLES-1]+dtlast]
    ts_limit = time[0]
    te_limit = time[1] 
  endif
  
  if BAK ne -1 then begin
    ; calculate new FOM value
    ;  tbl       = state.fom_table
    ;  FOMWindow = mms_burst_fom_window(nind,tbl.FOMSlope, tbl.FOMSkew, tbl.FOMBias)
    ;  seg       = Din.y[ind]
    ;  RealFOM   = (total(seg[sort(seg)]*FOMWindow) <255.0) > 2.0
    ;RealFOM = 40
    
;    if (state.USER_FLAG eq 4) then begin
;      RealFOM = 200
;      valval = mms_load_fom_validation()
;      tedef = trange[0] + valval.FPI_SEG_BOUNDS[1]*10d0
;    endif else begin
      RealFOM = 40
      tedef = trange[1]
;    endelse
    
    ; segSelect
    if n_elements(var) eq 0 then message,'Must pass tplot-variable name'
    segSelect = {ts:trange[0], te:tedef, fom:RealFOM, BAK:BAK, discussion:' ', var:var,$
      ts_limit:ts_limit, te_limit:te_limit}
    vvv = state.pref.EVA_BAKSTRUCT ? 'mms_stlm_bakstr' : 'mms_stlm_fomstr'
    eva_sitl_FOMedit, state, segSelect, wgrid=wgrid, vvv=vvv ;Here, change FOM value only. No trange change.
  endif
END

PRO eva_sitl_seg_fill, t, state=state, var=var
  compile_opt idl2
  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return
  endif

  if n_elements(t) ne 1 then message,'Something is wrong'
  if n_elements(var) eq 0 then message,'Must pass tplot-variable name'
  
  if ~state.pref.EVA_BAKSTRUCT then begin
    BAK = 0
    msg = eva_sitl_seg_validate(t) ; Validate against FOM time interval
    if ~strmatch(msg,'ok') then return
  endif else BAK = 1
  
  if BAK eq 0 then begin
    
    get_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
    s = lim.unix_FOMStr_mod
    tfom = eva_sitl_tfom(s)
    
    tnew = -1
    
    for N=0,s.Nsegs-2 do begin
      ts = s.TIMESTAMPS[s.STOP[N]]+10.d0
      te = s.TIMESTAMPS[s.START[N+1]]
      if (ts lt t) and (t lt te) then tnew = [ts,te]
    endfor
    
    if (t lt s.TIMESTAMPS[s.START[0]]) then begin 
      tnew = [tfom[0],s.TIMESTAMPS[s.START[0]]]
    endif
    if s.STOP[s.Nsegs-1] eq s.NUMCYCLES-1 then begin
      dtlast = s.TIMESTAMPS[s.NUMCYCLES-1]-s.TIMESTAMPS[s.NUMCYCLES-2]
      tfin = s.TIMESTAMPS[s.STOP[s.Nsegs-1]]+dtlast
    endif else begin
      tfin = s.TIMESTAMPS[s.STOP[s.Nsegs-1]]+10.d0
    endelse
    if (tfin lt t) then begin
      tnew = [tfin,tfom[1]]
    endif

    if n_elements(tnew) ne 2 then message,'Something is wrong'
  endif else begin
;    result = dialog_message("This feature is not needed in the back-structure mode.",/info,/center)
;    return
    
    get_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl
    s = lim.unix_BAKstr_mod
    tnew = -1
    Nsegs = n_elements(s.FOM)
 
    for N=0,Nsegs-2 do begin
      ts = s.STOP[N]+10.d0
      te = s.START[N+1]
      if (ts lt t) and (t lt te) then tnew = [ts,te]
    endfor

    if n_elements(tnew) ne 2 then begin
      msg = 'Please click an open space between two segments.'
      result = dialog_message(msg,/center)
      return
    endif
  endelse

  eva_sitl_seg_add, tnew, state=state, var=var
END


; For a given time 't', find the corresponding segment from
; FOMStr/BAKStr and then create "segSelect" which will be passed
; to eva_sitl_FOMedit for editing
PRO eva_sitl_seg_edit, t, state=state, var=var, delete=delete, split=split

  compile_opt idl2
  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return
  endif

  if n_elements(var) eq 0 then message,'Must pass tplot-variable name'
  
  if ~state.pref.EVA_BAKSTRUCT then begin
    BAK = 0
    msg = eva_sitl_seg_validate(t) ; Validate against FOM time interval
    if ~strmatch(msg,'ok') then return
  endif else BAK = 1
  
  if n_elements(t) eq 1 then begin
    case BAK of
      1: begin
        print,time_string(t)
        get_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl
        s = lim.UNIX_BAKSTR_MOD
        idx = where((s.START le t) and (t le s.STOP), ct)
        if ct eq 1 then begin
          m = idx[0] 
          segSelect = {ts:s.START[m],te:s.STOP[m]+10.d0,fom:s.FOM[m],$
            BAK:BAK,discussion:s.DISCUSSION[m], var:var, $
            createtime:s.CREATETIME[m],datasegmentid:s.DATASEGMENTID[m],finishtime:s.FINISHTIME[m],$
            inplaylist:s.INPLAYLIST[m],ispending:s.ISPENDING[m],numevalcycles:s.NUMEVALCYCLES[m],$
            parametersetid:s.PARAMETERSETID[m],seglengths:s.SEGLENGTHS[m],sourceid:s.SOURCEID[m],$
            status:s.STATUS[m]}
        endif else segSelect = 0
        wgrid = [0];s.TIMESTAMPS
      end
      0: begin
        get_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
        s = lim.UNIX_FOMSTR_MOD
        dtlast = s.TIMESTAMPS[s.NUMCYCLES-1]-s.TIMESTAMPS[s.NUMCYCLES-2]
        stime = s.TIMESTAMPS[s.START]
        etime = s.TIMESTAMPS[s.STOP] + 10.d0
        if s.STOP[s.NSEGS-1] eq s.NUMCYCLES - 1L then begin
          etime[s.NSEGS-1] = s.TIMESTAMPS[s.NUMCYCLES-1] + dtlast
        endif
        idx = where((stime le t) and (t le etime), ct)
        if ct eq 1 then begin
          segSelect = {ts:stime[idx[0]],te:etime[idx[0]],fom:s.FOM[idx[0]],$
            BAK:BAK, discussion:s.DISCUSSION[idx[0]], var:var}
        endif else segSelect = 0
        
        wgrid = [s.TIMESTAMPS,s.TIMESTAMPS[s.NUMCYCLES-1]+dtlast]
      end
      else: segSelect = -1
    endcase
  endif else begin
    if (BAK eq 0) or (BAK eq 1) then begin; Will be important when deleting multiple segments
      segSelect = {ts:t[0], te:t[1], fom:0., BAK: BAK, discussion:' ', var:var}
    endif else segSelect = -1
  endelse

  
  if (n_tags(segSelect) eq 6) or (n_tags(segSelect) eq 16) then begin
    if segSelect.BAK and ~state.pref.EVA_BAKSTRUCT then begin
      msg ='This is a back-structure segment. Ask Super SITL if you really need to modify this.'
      rst = dialog_message(msg,/info,/center)
    endif else begin
      if keyword_set(delete) then begin;....... DELETE
        segSelect.FOM = 0.; See line 102 of eva_sitl_strct_update
        eva_sitl_strct_update, segSelect, user_flag=state.user_flag, BAK=BAK
        eva_sitl_stack
        tplot,verbose=0
        
      endif; DELETE
      if keyword_set(split) then begin;........... SPLIT
        gTmin = segSelect.TS
        gTmax = segSelect.TE
        ;gTdel = double((mms_load_fom_validation()).NOMINAL_SEG_RANGE[1]*10.)
        if(state.PREF.EVA_SPLIT_SIZE eq 0) then begin
          val = mms_load_fom_validation()
          str_element,/add,state,'pref.EVA_SPLIT_SIZE',floor(val.NOMINAL_SEG_RANGE[1]*0.5)
        endif
        gTdel = double(state.PREF.EVA_SPLIT_SIZE*10.)
        gFOM = segSelect.FOM
        gBAK = segSelect.BAK
        gDIS = segSelect.DISCUSSION
        gVAR = segSelect.VAR
        nmax = ceil((gTmax-gTmin)/gTdel)
        gTdel = (gTmax-gTmin)/double(nmax)
        if nmax gt 0 then begin

          ; delete the segment
          segSelect.FOM = 0.; See line 102 of eva_sitl_strct_update
          eva_sitl_strct_update, segSelect, user_flag=state.user_flag,/override, BAK=BAK

          ; add split segment
          for n=0,nmax-1 do begin
            Ts = gTmin+gTdel*n
            Te = gTmin+gTdel*(n+1)
            segSelect = {ts:Ts,te:Te,fom:gFOM,BAK:gBAK, discussion:gDIS, var:gVAR}
            eva_sitl_strct_update, segSelect, user_flag=state.user_flag
          endfor

        endif; if nmax
        eva_sitl_stack
        tplot,verbose=0
      endif; SPLIT
      if (~keyword_set(delete) and ~keyword_set(split)) then begin;............. EDIT
        vvv = state.pref.EVA_BAKSTRUCT ? 'mms_stlm_bakstr' : 'mms_stlm_fomstr'
        eva_sitl_FOMedit, state, segSelect, wgrid=wgrid, vvv=vvv
      endif
    endelse; if segSelect.BAK
  endif else begin
    print,'EVA: BAK=',BAK
    print,'EVA: t=',time_string(t)
    print,'EVA: n_tags(segSelect)=',n_tags(segSelect)
    if n_tags(segSelect) eq 0 then print,'EVA: segSelect = '+strtrim(string(segSelect),2)
    msg = 'Please choose a segment. '
    msg = [msg,'']
    msg = [msg,'If you are sure you are selecting a segment,']
    msg = [msg,'then this may be an error. Please ask Super-SITL.']
    print,'EVA: '+msg
    rst = dialog_message(msg,/info,/center)
  endelse
END

PRO eva_sitl_seg_delete, t, state=state, var=var
  eva_sitl_seg_edit, t, state=state, var=var, /delete
END

PRO eva_sitl_seg_split, t, state=state, var=var
  eva_sitl_seg_edit, t, state=state, var=var, /split
END

PRO eva_sitl_set_value, id, value ;In this case, value = activate
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

FUNCTION eva_sitl_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;-----
  ret = state
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  return, ret
END

FUNCTION eva_sitl_event, ev
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
  
  set_multi = widget_info(state.cbMulti,/button_set)
  set_trange= widget_info(state.cbWTrng,/button_set)
  submit_code = 0
  refresh_dash = 0
  sanitize_fpi = 1
  xtplot_right_click = 1
  save = 1
  
  case ev.id of
    state.btnAdd:  begin
      print,'EVA: ***** EVENT: btnAdd *****'
      str_element,/add,state,'group_leader',ev.top
      eva_ctime,/silent,routine_name='eva_sitl_seg_add',state=state,occur=2,npoints=2;npoints
      end
    state.btnFill:  begin
      print,'EVA: ***** EVENT: btnFill *****'
      str_element,/add,state,'group_leader',ev.top
      eva_ctime,/silent,routine_name='eva_sitl_seg_fill',state=state,occur=1,npoints=1;npoints
      end
    state.btnEdit:  begin
      print,'EVA: ***** EVENT: btnEdit *****'
      str_element,/add,state,'group_leader',ev.top
      eva_ctime,/silent,routine_name='eva_sitl_seg_edit',state=state,occur=1,npoints=1;npoints
      end
    state.btnDelete:begin
      print,'EVA: ***** EVENT: btnDelete *****'
      npoints = 1 & occur = 1
      eva_ctime,/silent,routine_name='eva_sitl_seg_delete',state=state,occur=occur,npoints=npoints
      end
    state.cbMulti:begin; Delete N segments with N clicks
      print,'EVA: ***** EVENT: cbMulti *****'
      npoints = 2000 & occur = 1
      
      ; The right-click-event during eva_ctime seems to be executed
      ; AFTER this eva_sitl/cbMulti event has ended. So, it is not meaningful to
      ; set xtplot_right_click back to 1 before the end of this event handler.
      ; We set xtplot_right_click 0 here, but we have to execute another widget
      ; event in order to set it back to 1. We have xtplot_right_click=1 at the 
      ; beggining of this event handler so that the right click will be turned back
      ; on after any addition SITL event (except cbMulti).
      xtplot_right_click = 0
    
      eva_ctime,/silent,routine_name='eva_sitl_seg_delete',state=state,occur=occur,npoints=npoints
      end
    state.cbWTrng: begin; Delete N segment within a range specified by 2-clicks
      print,'EVA: ***** EVENT: cbWTrng *****'
      npoints = 2 & occur = 2
      eva_ctime,/silent,routine_name='eva_sitl_seg_delete',state=state,occur=occur,npoints=npoints
      end
    state.btnSplit: begin
      print,'EVA: ***** EVENT: btnSplit *****'
      result = 'Yes'
      if state.PREF.EVA_BAKSTRUCT then begin
        msg = 'Please DO NOT SPLIT pre-existing segments. '
        msg = [msg, 'You can only split a segment that was newly created during']
        msg = [msg, 'this EVA session (by you) and has not been processed at SDC.']
        msg = [msg, ' ']
        msg = [msg, 'Would you still like to proceed and split?'] 
        result = dialog_message(msg,/center,/question)
      endif
      if result eq 'Yes' then begin
        str_element,/add,state,'group_leader',ev.top
        eva_ctime,/silent,routine_name='eva_sitl_seg_split',state=state,occur=1,npoints=1;npoints
        sanitize_fpi=0
      endif
      end
    state.btnUndo: begin
      print,'EVA: ***** EVENT: btnUndo *****'
      eva_sitl_fom_recover,'undo'
      end
    state.btnRedo: begin
      print,'EVA: ***** EVENT: btnRedo *****'
      eva_sitl_fom_recover,'redo'
      end
    state.btnAllAuto: begin
      print,'EVA: ***** EVENT: btnAllAuto *****'
      eva_sitl_fom_recover,'rvrt'
      end
;    state.btnValidate: begin
;      save = 0
;      print,'EVA: ***** EVENT: btnValidate *****'
;      title = 'Validation'
;      if state.PREF.EVA_BAKSTRUCT then begin
;        tn = tnames()
;        idx = where(strmatch(tn,'mms_stlm_bakstr'),ct)
;        if ct eq 0 then begin
;          msg = 'Back-Structure not found. If you wish to'
;          msg = [msg, 'submit a FOM structure, please disable the back-']
;          msg = [msg, 'structure mode.']
;          rst = dialog_message(msg,/error,/center,title=title)
;        endif else begin
;          get_data,'mms_stlm_bakstr',data=Dmod, lim=lmod,dl=dlmod
;          get_data,'mms_soca_bakstr',data=Dorg, lim=lorg,dl=dlorg
;          tai_BAKStr_org = lorg.unix_BAKStr_org
;          str_element,/add,tai_BAKStr_org,'START', mms_unix2tai(lorg.unix_BAKStr_org.START); LONG
;          str_element,/add,tai_BAKStr_org,'STOP',  mms_unix2tai(lorg.unix_BAKStr_org.STOP) ; LONG
;          tai_BAKStr_mod = lmod.unix_BAKStr_mod
;          str_element,/add,tai_BAKStr_mod,'START', mms_unix2tai(lmod.unix_BAKStr_mod.START); LONG
;          str_element,/add,tai_BAKStr_mod,'STOP',  mms_unix2tai(lmod.unix_BAKStr_mod.STOP) ; LONG
;          
;          header = eva_sitl_text_selection(lmod.unix_BAKStr_mod,/bak)
;          
;          vsp = '////////////////////////////'
;          header = [header, vsp+' VALIDATION RESTULT (NEW SEGMENTS) '+vsp]
;          r = eva_sitl_validate(tai_BAKStr_mod, -1, vcase=1, header=header, /quiet, valstruct=state.val); Validate New Segs
;          header = [r.msg,' ', vsp+' VALIDATION RESULT (MODIFIED SEGMENTS) '+vsp]
;          r2 = eva_sitl_validate(tai_BAKStr_mod, tai_BAKStr_org, vcase=2, header=header, valstruct=state.val); Validate Modified Seg
;        endelse; if ct eq 0
;      endif else begin
;        get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
;        get_data,'mms_soca_fomstr',data=Dorg, lim=lorg,dl=dlorg
;        mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
;        mms_convert_fom_unix2tai, lorg.unix_FOMStr_org, tai_FOMstr_org; Original FOM for reference
;        header = eva_sitl_text_selection(lmod.unix_FOMstr_mod)
;        vcase = 0;(state.USER_FLAG eq 4) ? 3 : 0
;        r = eva_sitl_validate(tai_FOMstr_mod, tai_FOMstr_org, vcase=vcase, header=header, valstruct=state.val)
;      endelse
;      end
;    state.btnEmail: begin
;      print,'EVA: ***** EVENT: btnEmail *****'
;      if state.PREF.EVA_BAKSTRUCT then begin
;        msg = 'Email for Back Structure Mode is under construction.'
;        result = dialog_message(msg,/center)
;      endif else begin
;        get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dmod
;        mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
;        header = eva_sitl_text_selection(lmod.unix_FOMstr_mod)
;        body = ''
;        nmax = n_elements(header)
;        for n=0,nmax-1 do begin
;          body += header[n] + 'rtn'
;        endfor
;        email_address = 'mitsuo.oka@gmail.com'
;        syst = systime(/utc)
;        oUrl = obj_new('IDLnetUrl')
;        txturl = 'http://www.ssl.berkeley.edu/~moka/evasendmail.php?email='$
;          +email_address+'&fomstr='+body+'&time='+syst
;        ok = oUrl->Get(URL=txturl,/STRING_ARRAY)
;        obj_destroy, oUrl
;        result=dialog_message('Email sent to '+email_address,/center,/info)
;      endelse
;      end
    state.drpHighlight: begin
      save =0
      print,'EVA: ***** EVENT: drpHighlight *****'
      tplot
      type = state.hlSet2[ev.index]
      isPending=0
      inPlaylist=0
      status = ''
      default=0
      case type of
        'Default':default=1
        'isPending': isPending=1
        'inPlaylist': inPlaylist=1
        else: status = type
      endcase
      tn = tnames('*bakstr*',ct_bak)
      if (ct_bak gt 0) then begin
        get_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl
        if (not default) then begin;...... if (not DEFAULT)
          if n_tags(lim) gt 0 then begin
            D = eva_sitl_strct_read(lim.unix_BAKStr_mod, 0.d0,$
              isPending=isPending,inPlaylist=inPlaylist,status=status)
            nmax = n_elements(D.x)
            if nmax ge 5 then begin
              trange   = tplot_vars.OPTIONS.TRANGE
              left_edges  = (D.x[1:nmax-1:4] > trange[0]) < trange[1]
              right_edges = (D.x[4:nmax-1:4] > trange[0]) < trange[1]
              data        = D.y[2:nmax-1:4]
              vvv = state.pref.EVA_BAKSTRUCT ? 'mms_stlm_bakstr' : 'mms_stlm_fomstr'
              eva_sitl_highlight, left_edges, right_edges, data, vvv, /noline
              ;eva_sitl_highlight, left_edges, right_edges, data, state, /noline
            endif; if nmax
          endif; if n_tags
        endif else begin
          s = lim.unix_BAKstr_mod;...........  if DEFAULT
          Nsegs = n_elements(s.FOM)
          print, 'EVA:----- List of back-structure segments -----'
          print, 'EVA:number, start time         , FOM    , status, sourceID'
          for N=0,Nsegs-1 do begin
            strN = string(N, format='(I5)')
            strF = string(s.FOM[N], format='(F7.3)')
            print, 'EVA: '+strN+': '+time_string(s.START[N])+', '+strF+', '+s.STATUS[N]+', '+s.SOURCEID[N]
          endfor
        endelse
      endif
      end
    state.drpSave: begin
      save=0
      print,'EVA: ***** EVENT: drpSave *****'
      widget_control, widget_info(ev.Top,find='eva_data'), GET_VALUE=state_data
      dir = state_data.pref.EVA_CACHE_DIR
      type = state.svSet[ev.index]
      case type of
;        'Save': eva_sitl_save,/auto,dir=dir
;        'Restore': eva_sitl_restore,/auto,dir=dir
        'Save As': eva_sitl_save
        'Restore From': eva_sitl_restore, state_data
        else: answer = dialog_message('Something is wrong.')
      endcase
      end
;    state.btnSubmit: begin
;      save=0
;      print,'EVA: ***** EVENT: btnSubmit *****'
;      print,'EVA: TESTMODE='+string(state.PREF.EVA_TESTMODE_SUBMIT)
;      submit_code = 1
;      if state.PREF.EVA_BAKSTRUCT then begin 
;        eva_sitl_submit_bakstr,ev.top, state.PREF.EVA_TESTMODE_SUBMIT
;      endif else begin
;        
;        ; Look for pre-existing note
;        get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
;        tn = tag_names(lmod.unix_FOMstr_mod)
;        idx = where(strmatch(tn,'NOTE'),ct)
;        if ct gt 0 then begin
;          varname = lmod.unix_FOMstr_mod.NOTE
;        endif else varname = ''
;        
;        ; Textbox for NOTE
;        varname = mms_TextBox(Title='EVA TEXTBOX', Group_Leader=ev.top, $
;          Label='Please add/edit your comment on this ROI: ', $
;          SecondLabel='(The text will wrap automatically. A carriage',$
;          ThirdLabel='return is same as hitting the Save button.)',$
;          Cancel=cancelled, Continue_Submission=contin, $
;          XSize=300, Value=varname)
;        
;        ; Submission
;        if not cancelled then begin
;          print,'EVA: Saving the following string:', varname
;          get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
;          str_element,/add,lmod,'unix_FOMstr_mod.NOTE', varname
;          store_data,'mms_stlm_fomstr',data=Dmod, lim=lmod, dl=dlmod
;          if contin then begin
;            print,'EVA: Continue Submission....'
;            vcase = 0;(state.USER_FLAG eq 4) ? 3 : 0
;            eva_sitl_submit_fomstr,ev.top, state.PREF.EVA_TESTMODE_SUBMIT, vcase, user_flag=state.USER_FLAG
;          endif else print,'EVA:  but just saved...'
;        endif else begin
;          print,'EVA: Submission cancelled...'
;        endelse
;        
;      endelse
;      end
    state.drDash: begin
      save=0
      sanitize_fpi=0
      refresh_dash = 1
      end
    else: print, 'EVA: else'
  endcase

;  FPI = (state.USER_FLAG eq 4)
;  if(FPI and sanitize_fpi) then begin; Revert hacked FOMstr (i.e. remove the fake segment)
;    get_data,'mms_stlm_fomstr',data=D,dl=dl,lim=lim
;    s = lim.unix_FOMstr_mod
;    snew = s
;    if (s.NSEGS gt 1) and (s.START[0] eq 0) and (s.STOP[0] eq 1) and (s.FOM[0] eq 0.) then begin
;      str_element,/add,snew, 'FOM', s.FOM[1:s.NSEGS-1]
;      str_element,/add,snew, 'START', s.START[1:s.NSEGS-1]
;      str_element,/add,snew, 'STOP', s.STOP[1:s.NSEGS-1]
;      str_element,/add,snew, 'NSEGS', s.NSEGS-1L
;      str_element,/add,snew, 'NBUFFS', s.NBUFFS-1L
;      str_element,/add,snew, 'FPICAL', 0L; Set 0 because the dummy segment does not exist anymore
;      str_element,/add,lim,'unix_FOMstr_mod',snew
;      D_hacked = eva_sitl_strct_read(snew,min(snew.START,/nan))
;      store_data,'mms_stlm_fomstr',data=D_hacked,lim=lim,dl=dl
;    endif
;  endif
  
  ;When not refreshing the dashboard, we update validation structure as often as possible.
  ;The dashboard, whenever refreshing, will use the updated validation structure to
  ;refresh the information. Technically, we could update validation structure within
  ; the dashboard refreshing process, but this will cause numerous access to SDC.
  if ~refresh_dash then begin
    val = mms_load_fom_validation()
    str_element,/add,state,'val',val
  endif
  
  if ~submit_code then begin
    tn = tnames('*_stlm_*',ct)
    if ct gt 0 then s=1 else s=0
    eva_sitl_update_board, state, s
    if (s eq 1) and (state.stack eq 0) then begin; At the first call to eva_sitl_update_board
      eva_sitl_stack                             ; with mms_sitl_ouput_fom, we initiate
      str_element,/add,state,'stack',1           ; stacking.
    endif
  endif
  
  if save then begin
    eva_sitl_save,/auto,dir=dir,/quiet
  endif

  
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION eva_sitl, parent, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize
  compile_opt idl2
  ;@xtplot_com.pro

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for CW_sitl'

  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_sitl'
  if not (keyword_set(title)) then title='   MAIN   '
  
  ; ----- STATE -----
  pref = {$
    EVA_BAKSTRUCT: 0,$
    EVA_TESTMODE_SUBMIT: 1,$
    EVA_SPLIT_SIZE:0, $; val.NOMINAL_SEG_RANGE[1]}
    EVA_STLM_INPUT:'soca',$;
    EVA_GLS1_ALGO:'mp-dl-unh',$
    EVA_GLS2_ALGO:'none',$
    EVA_GLS3_ALGO:'none',$
    EVA_STLM_UPDATE:1,$
    EVA_BASEPOS: 0}
    
  socs  = {$; SOC Auto Simulated
    pmdq: ['a','b','c','d'], $ ; probes to be used for calculating MDQs
    input: 'thm_archive'}    ; input to be used for simulating SOC-Auto
  stlm  = {$; SITL Manu
    input: 'socs', $ ; input type (default: 'soca'; or 'socs','stla')
    update_input: 1 } ; update input data everytime plotting STLM variables
  state = {$
    parent:parent, $
    pref:pref, $
    socs:socs, $
    stlm:stlm, $
    stack: 0, $
    set_multi: 0,$
    set_trange: 0,$
    rehighlight: 0,$
    launchtime: systime(1,/utc),$
    user_flag: 0, $
    userType: ['MMS member','SITL','Super SITL'],$
    uplink:0L};,$;'FPI cal']}
    ;userType: ['Guest','MMS member','SITL','Super SITL']};,'FPI cal']}
    ;val: mms_load_fom_validation()}


  ; ----- CONFIG (READ) -----
  cfg = mms_config_read()         ; Read config file and
  pref = mms_config_push(cfg,pref); push the values into preferences
  pref.EVA_BAKSTRUCT = 0
  pref.EVA_TESTMODE_SUBMIT = 1
  pref.EVA_SPLIT_SIZE=0 ; Added on 2016-03-26 (in response to Barbara's request of forcing into the default size)
  str_element,/add,state,'pref',pref
  

  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize

  hlSet = ['Default','isPending','inPlaylist','Held','Complete','Overwritten']
  hlSet2 = ['Default','isPending','inPlaylist','Held','Complete','New','Modified',$
    'Deleted','Aborted','Finished','Incomplete','Derelict', 'Demoted','Realloc', 'Deferred']
  svSet = ['Restore From','Save As'];svSet = ['Save','Restore','Save As', 'Restore From']
  
  mainbase = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_sitl_event", $
    FUNC_GET_VALUE = "eva_sitl_get_value", $
    PRO_SET_VALUE = "eva_sitl_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1, SPACE=0, YPAD=0)
  str_element,/add,state,'mainbase',mainbase
  str_element,/add,state,'lblTgtTimeMain',widget_label(mainbase,VALUE='(Select a paramter-set for SITL)',/align_left,xsize=xsize)

  subbase = widget_base(mainbase,/column,sensitive=0)
  str_element,/add,state,'subbase',subbase

  bsAction = widget_base(subbase,/COLUMN,/frame)
  ;#####################################################################
  str_element,/add,state,'drDash', widget_draw(bsAction,graphics_level=2,xsize=xsize-20,ysize=150,/expose_event)
  ;#####################################################################

  bsAction0 = widget_base(bsAction,/COLUMN,space=0,ypad=0, SENSITIVE=0)
  str_element,/add,state,'bsAction0',bsAction0
    bsActionButton = widget_base(bsAction0,/ROW)
    bsActionAdd = widget_base(bsActionButton,/COLUMN)
      str_element,/add,state,'btnAdd',widget_button(bsActionAdd,VALUE='  Add  ')
      str_element,/add,state,'btnFill',widget_button(bsActionAdd,VALUE='  Fill  ')
    str_element,/add,state,'btnEdit',widget_button(bsActionButton,VALUE='  Edit  ')
    str_element,/add,state,'btnDelete',widget_button(bsActionButton,VALUE=' Del ');,/TRACKING_EVENTS)
    bsActionCheck = widget_base(bsActionButton,/COLUMN);,/NONEXCLUSIVE)
    str_element,/add,state,'cbMulti',widget_button(bsActionCheck, VALUE='Delete multi seg',SENSITIVE=1)
    str_element,/add,state,'cbWTrng',widget_button(bsActionCheck, VALUE='Delete w/in a range',SENSITIVE=1)
    bsActionHistory = widget_base(bsAction0,/ROW, SPACE=0, YPAD=0)
    str_element,/add,state,'btnUndo',widget_button(bsActionHistory,VALUE=' Undo ')
    str_element,/add,state,'btnRedo',widget_button(bsActionHistory,VALUE=' Redo ')
    str_element,/add,state,'btnAllAuto',widget_button(bsActionHistory,VALUE=' Revert to Auto ')
    str_element,/add,state,'bsDummy',widget_base(bsActionHistory,xsize=40)
    str_element,/add,state,'btnSplit',widget_button(bsActionHistory,VALUE=' Split ')
    bsActionHighlight = widget_base(bsAction0,/ROW, SPACE=0, YPAD=0)
      str_element,/add,state,'drpHighlight',widget_droplist(bsActionHighlight,VALUE=hlSet,$
        TITLE='Status:',SENSITIVE=1)
        str_element,/add,state,'hlSet',hlSet
        str_element,/add,state,'hlSet2',hlSet2
    ;bsActionSave = widget_base(bsAction0,/ROW, SPACE=0, YPAD=0)
      str_element,/add,state,'drpSave',widget_droplist(bsActionHighlight,VALUE=svSet,$
        TITLE='FOM:',SENSITIVE=1)
        str_element,/add,state,'svSet',svSet
;    bsActionUplink = widget_base(bsAction0, /COLUMN, SPACE=0, YPAD=0)
;      str_element,/add,state,'lblEvalStartTime',widget_label(bsActionUplink,VALUE='Next SITL Window Start Time: N/A                    ',/align_left)
;      ;str_element,/add,state,'lblUplink',widget_label(bsActionUplink,VALUE='Uplink - No  ')

;  bsActionSubmit = widget_base(subbase,/ROW, SENSITIVE=0)
;  str_element,/add,state,'bsActionSubmit',bsActionSubmit
;    str_element,/add,state,'btnValidate',widget_button(bsActionSubmit,VALUE=' Validate ')
;;    str_element,/add,state,'btnEmail',widget_button(bsActionSubmit,VALUE=' Email ')
;    dumSubmit2 = widget_base(bsActionSubmit,xsize=80); Comment out this line when using Email
;    dumSubmit = widget_base(bsActionSubmit,xsize=60)
;    str_element,/add,state,'btnSubmit',widget_button(bsActionSubmit,VALUE='   DRAFT   ')
  
  ; Save out the initial state structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state, /NO_COPY

  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, mainbase
END
