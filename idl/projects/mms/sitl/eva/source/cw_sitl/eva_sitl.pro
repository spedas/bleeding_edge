; $LastChangedBy: moka $
; $LastChangedDate: 2024-07-13 23:42:39 -0700 (Sat, 13 Jul 2024) $
; $LastChangedRevision: 32743 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl.pro $
pro eva_sitl_cleanup, parent = parent
  compile_opt idl2
  @eva_sitl_com
  ; id_sitl = widget_info(parent, find_by_uname='eva_sitl')
  ; widget_control, id_sitl, GET_VALUE=s

  obj_destroy, sg.myview
  obj_destroy, sg.myviewB
  obj_destroy, sg.myfont
  obj_destroy, sg.myfontL
end

pro eva_sitl_fom_recover, strcmd
  compile_opt idl2
  @eva_sitl_com

  i = i_fom_stack ; which step to plot? current--> i=0, one_step_past--> i=1

  imax = n_elements(fom_stack)
  case strcmd of
    'undo': i++ ; one step backward in time
    'redo': i-- ; one step forward in time
    'rvrt': i = imax - 1
  endcase

  case 1 of
    i lt 0: i = 0
    i ge imax: i = imax - 1
    else: begin
      ptr = fom_stack[i]
      dr = *ptr
      tfom = eva_sitl_tfom(dr.f)
      store_data, 'mms_stlm_fomstr', data = eva_sitl_strct_read(dr.f, tfom[0])
      options, 'mms_stlm_fomstr', 'unix_FOMStr_mod', dr.f
      if (n_tags(dr.b) gt 0) then begin
        store_data, 'mms_stlm_bakstr', data = eva_sitl_strct_read(dr.b, min(dr.b.start, /nan))
        options, 'mms_stlm_bakstr', 'unix_BAKStr_mod', dr.b
      endif
      eva_sitl_strct_yrange, 'mms_stlm_output_fom'
      eva_sitl_strct_yrange, 'mms_stlm_fomstr'
      eva_sitl_copy_fomstr
      tplot, verbose = 0
    end
  endcase
  i_fom_stack = i
end

; This procedure validates the input 't' (in FOMstr mode)
function eva_sitl_seg_validate, t
  compile_opt idl2

  get_data, 'mms_stlm_fomstr', data = D, lim = lim, dl = dl
  tfom = eva_sitl_tfom(lim.unix_fomstr_mod)
  nt = n_elements(t)
  case nt of
    1: msg = ((t lt tfom[0]) or (tfom[1] lt t)) ? 'Out of time range' : 'ok'
    2: begin
      r = segment_overlap(t, tfom)
      case r of
        -2: msg = 'Out of time range'
        - 1: msg = 'Out of time range'
        1: msg = 'Out of time range'
        2: msg = 'Out of time range'
        4: msg = 'Segment too big.'
        else: msg = 'ok'
      end ; case r of
    end
    else: message, '"t" must be 1 or 2 element array.'
  endcase
  if ~strmatch(msg, 'ok') then rst = dialog_message(msg, /info, /center)
  return, msg
end

; For a given time range 'trange', create "segSelect"
; which will be passed to eva_sitl_FOMedit for editing
pro eva_sitl_seg_add, trange, state = state, var = var
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
    rst = dialog_message('Select a time interval by two left-clicks.', /info, /center)
    return
  endif

  if trange[1] lt trange[0] then begin
    trange_temp = trange[0]
    trange = [trange[1], trange_temp]
  endif

  if ~state.pref.eva_bakstruct then begin
    BAK = 0
    msg = eva_sitl_seg_validate(trange) ; Validate against FOM time interval
    if ~strmatch(msg, 'ok') then return
  endif else BAK = 1

  time = timerange(/current)

  if BAK eq 1 then begin
    ; validation (BAKStr: make sure 'trange' does not overlap with existing segments)
    get_data, 'mms_stlm_bakstr', data = D, lim = lim, dl = dl
    s = lim.unix_bakStr_mod
    Nsegs = n_elements(s.fom)

    ct_overlap = 0 ; count number of overlapped segments
    for N = 0, Nsegs - 1 do begin
      if (strpos(s.status[N], 'DELETED') lt 0) then begin
        if s.start[N] gt s.stop[N] then begin
          ; print, 'N=',N
          ; print, 'start=',time_string(s.START[N])
          ; print, 'stop=',time_string(s.STOP[N])
          ; print, 'trange_org=',time_string(trange_org)
          ; stop
          ; message,'Something is wrong'
          print, 'EVA: something is wrong'
        endif else begin
          rr = segment_overlap([s.start[N], s.stop[N]], trange)
          if ((rr eq 4) or (rr eq 3) or (rr eq -1) or (rr eq 1) or (rr eq 0)) then ct_overlap += 1
        endelse
      endif
    endfor
    NOTOK = (ct_overlap gt 0)
    if NOTOK then begin
      msg = 'A new segment must not overlap with existing segments.'
      print, msg
      print, ' Selected: ', time_string(trange)
      print, ' ct_overlap = ', ct_overlap
      rst = dialog_message(msg, /info, /center)
      return
    endif
    wgrid = [0] ; s.TIMESTAMPS

    ; if trange passed the overlap test, then find the limit for time-range modification
    ; during ADD process.

    idx = where(strpos(s.status, 'DELETED') lt 0, ND_Nsegs)
    ND_START = s.start[idx]
    ND_STOP = s.stop[idx]
    for N = 0, ND_Nsegs - 2 do begin
      if (ND_STOP[N] lt trange[0]) and (trange[1] le ND_START[N + 1]) then begin
        ts_limit = ND_STOP[N] + 10.d0
        te_limit = ND_START[N + 1] - 10.d0
      endif
    endfor
    if trange[1] lt ND_START[0] then begin
      ts_limit = 0.d0
      te_limit = ND_START[0] - 10.d0
    endif
    if trange[0] gt ND_STOP[ND_Nsegs - 1] then begin
      ts_limit = ND_STOP[ND_Nsegs - 1] + 10.d0
      te_limit = systime(1, /utc)
    endif
    if ts_limit lt time[0] then ts_limit = time[0]
    if te_limit gt time[1] then te_limit = time[1]
  endif

  if BAK eq 0 then begin
    get_data, 'mms_stlm_fomstr', data = D, lim = lim, dl = dl
    s = lim.unix_fomStr_mod
    dtlast = s.timestamps[s.numcycles - 1] - s.timestamps[s.numcycles - 2]
    wgrid = [s.timestamps, s.timestamps[s.numcycles - 1] + dtlast]
    ts_limit = time[0]
    te_limit = time[1]
  endif

  if BAK ne -1 then begin
    RealFOM = 40
    tedef = trange[1]

    ; segSelect
    if n_elements(var) eq 0 then message, 'Must pass tplot-variable name'
    segSelect = {ts: trange[0], te: tedef, fom: RealFOM, bak: BAK, discussion: ' ', var: var, $
      ts_limit: ts_limit, te_limit: te_limit, obsset: 15b}
    vvv = state.pref.eva_bakstruct ? 'mms_stlm_bakstr' : 'mms_stlm_fomstr'
    eva_sitl_FOMedit, state, segSelect, wgrid = wgrid, vvv = vvv ; Here, change FOM value only. No trange change.
  endif
end

pro eva_sitl_seg_fill, t, state = state, var = var
  compile_opt idl2
  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return
  endif

  if n_elements(t) ne 1 then message, 'Something is wrong'
  if n_elements(var) eq 0 then message, 'Must pass tplot-variable name'

  if ~state.pref.eva_bakstruct then begin
    BAK = 0
    msg = eva_sitl_seg_validate(t) ; Validate against FOM time interval
    if ~strmatch(msg, 'ok') then return
  endif else BAK = 1

  if BAK eq 0 then begin
    get_data, 'mms_stlm_fomstr', data = D, lim = lim, dl = dl
    s = lim.unix_fomStr_mod
    tfom = eva_sitl_tfom(s)

    tnew = -1

    for N = 0, s.nsegs - 2 do begin
      ts = s.timestamps[s.stop[N]] + 10.d0
      te = s.timestamps[s.start[N + 1]]
      if (ts lt t) and (t lt te) then tnew = [ts, te]
    endfor

    if (t lt s.timestamps[s.start[0]]) then begin
      tnew = [tfom[0], s.timestamps[s.start[0]]]
    endif
    if s.stop[s.nsegs - 1] eq s.numcycles - 1 then begin
      dtlast = s.timestamps[s.numcycles - 1] - s.timestamps[s.numcycles - 2]
      tfin = s.timestamps[s.stop[s.nsegs - 1]] + dtlast
    endif else begin
      tfin = s.timestamps[s.stop[s.nsegs - 1]] + 10.d0
    endelse
    if (tfin lt t) then begin
      tnew = [tfin, tfom[1]]
    endif

    if n_elements(tnew) ne 2 then message, 'Something is wrong'
  endif else begin
    ; result = dialog_message("This feature is not needed in the back-structure mode.",/info,/center)
    ; return

    get_data, 'mms_stlm_bakstr', data = D, lim = lim, dl = dl
    s = lim.unix_baKstr_mod
    tnew = -1
    Nsegs = n_elements(s.fom)

    for N = 0, Nsegs - 2 do begin
      ts = s.stop[N] + 10.d0
      te = s.start[N + 1]
      if (ts lt t) and (t lt te) then tnew = [ts, te]
    endfor

    if n_elements(tnew) ne 2 then begin
      msg = 'Please click an open space between two segments.'
      result = dialog_message(msg, /center)
      return
    endif
  endelse

  eva_sitl_seg_add, tnew, state = state, var = var
end

; For a given time 't', find the corresponding segment from
; FOMStr/BAKStr and then create "segSelect" which will be passed
; to eva_sitl_FOMedit for editing
pro eva_sitl_seg_edit, t, state = state, var = var, delete = delete, split = split
  compile_opt idl2
  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return
  endif

  if n_elements(var) eq 0 then message, 'Must pass tplot-variable name'

  if ~state.pref.eva_bakstruct then begin
    BAK = 0
    msg = eva_sitl_seg_validate(t) ; Validate against FOM time interval
    if ~strmatch(msg, 'ok') then return
  endif else BAK = 1

  if n_elements(t) eq 1 then begin
    case BAK of
      1: begin
        print, time_string(t)
        get_data, 'mms_stlm_bakstr', data = D, lim = lim, dl = dl
        s = lim.unix_bakstr_mod
        idx = where((s.start le t) and (t le s.stop), ct)
        if ct eq 1 then begin
          m = idx[0]
          segSelect = {ts: s.start[m], te: s.stop[m] + 10.d0, fom: s.fom[m], $
            bak: BAK, discussion: s.discussion[m], var: var, obsset: s.obsset[m], $
            createtime: s.createtime[m], datasegmentid: s.datasegmentid[m], finishtime: s.finishtime[m], $
            inplaylist: s.inplaylist[m], ispending: s.ispending[m], numevalcycles: s.numevalcycles[m], $
            parametersetid: s.parametersetid[m], seglengths: s.seglengths[m], sourceid: s.sourceid[m], $
            status: s.status[m]}
        endif else segSelect = 0
        wgrid = [0] ; s.TIMESTAMPS
      end
      0: begin
        get_data, 'mms_stlm_fomstr', data = D, lim = lim, dl = dl
        s = lim.unix_fomstr_mod
        dtlast = s.timestamps[s.numcycles - 1] - s.timestamps[s.numcycles - 2]
        stime = s.timestamps[s.start]
        etime = s.timestamps[s.stop] + 10.d0
        if s.stop[s.nsegs - 1] eq s.numcycles - 1l then begin
          etime[s.nsegs - 1] = s.timestamps[s.numcycles - 1] + dtlast
        endif
        idx = where((stime le t) and (t le etime), ct)
        if ct eq 1 then begin
          segSelect = {ts: stime[idx[0]], te: etime[idx[0]], fom: s.fom[idx[0]], $
            bak: BAK, discussion: s.discussion[idx[0]], var: var, obsset: s.obsset[idx[0]]}
        endif else segSelect = 0

        wgrid = [s.timestamps, s.timestamps[s.numcycles - 1] + dtlast]
      end
      else: segSelect = -1
    endcase
  endif else begin
    if (BAK eq 0) or (BAK eq 1) then begin ; Will be important when deleting multiple segments
      segSelect = {ts: t[0], te: t[1], fom: 0., bak: BAK, discussion: ' ', var: var, obsset: 15b}
    endif else segSelect = -1
  endelse

  if (n_tags(segSelect) eq 7) or (n_tags(segSelect) eq 17) then begin
    if segSelect.bak and ~state.pref.eva_bakstruct then begin
      msg = 'This is a back-structure segment. Ask Super SITL if you really need to modify this.'
      rst = dialog_message(msg, /info, /center)
    endif else begin
      if keyword_set(delete) then begin ; ....... DELETE
        segSelect.fom = 0. ; See line 102 of eva_sitl_strct_update
        eva_sitl_strct_update, segSelect, user_flag = state.user_flag, bak = BAK
        eva_sitl_stack
        tplot, verbose = 0
      endif ; DELETE
      if keyword_set(split) then begin ; ........... SPLIT
        gTmin = segSelect.ts
        gTmax = segSelect.te
        ; gTdel = double((mms_load_fom_validation()).NOMINAL_SEG_RANGE[1]*10.)
        if (state.pref.eva_split_size eq 0) then begin
          val = mms_load_fom_validation()
          str_element, /add, state, 'pref.EVA_SPLIT_SIZE', floor(val.nominal_seg_range[1] * 0.5)
        endif
        gTdel = double(state.pref.eva_split_size * 10.)
        gFOM = segSelect.fom
        gBAK = segSelect.bak
        gDIS = segSelect.discussion
        gVAR = segSelect.var
        gOBS = segSelect.obsset
        nmax = ceil((gTmax - gTmin) / gTdel)
        gTdel = (gTmax - gTmin) / double(nmax)
        if nmax gt 0 then begin
          ; delete the segment
          segSelect.fom = 0. ; See line 102 of eva_sitl_strct_update
          eva_sitl_strct_update, segSelect, user_flag = state.user_flag, /override, bak = BAK

          ; add split segment
          for n = 0, nmax - 1 do begin
            Ts = gTmin + gTdel * n
            Te = gTmin + gTdel * (n + 1)
            segSelect = {ts: Ts, te: Te, fom: gFOM, bak: gBAK, discussion: gDIS, var: gVAR, obsset: gOBS}
            eva_sitl_strct_update, segSelect, user_flag = state.user_flag
          endfor
        endif ; if nmax
        eva_sitl_stack
        tplot, verbose = 0
      endif ; SPLIT
      if (~keyword_set(delete) and ~keyword_set(split)) then begin ; ............. EDIT
        vvv = state.pref.eva_bakstruct ? 'mms_stlm_bakstr' : 'mms_stlm_fomstr'
        eva_sitl_FOMedit, state, segSelect, wgrid = wgrid, vvv = vvv
      endif
    endelse ; if segSelect.BAK
  endif else begin
    print, 'EVA: BAK=', BAK
    print, 'EVA: t=', time_string(t)
    print, 'EVA: n_tags(segSelect)=', n_tags(segSelect)
    if n_tags(segSelect) eq 0 then print, 'EVA: segSelect = ' + strtrim(string(segSelect), 2)
    msg = 'Please choose a segment. '
    msg = [msg, '']
    msg = [msg, 'If you are sure you are selecting a segment,']
    msg = [msg, 'then this may be an error. Please ask Super-SITL.']
    print, 'EVA: ' + msg
    rst = dialog_message(msg, /info, /center)
  endelse
end

pro eva_sitl_seg_delete, t, state = state, var = var
  compile_opt idl2
  eva_sitl_seg_edit, t, state = state, var = var, /delete
end

pro eva_sitl_seg_split, t, state = state, var = var
  compile_opt idl2
  eva_sitl_seg_edit, t, state = state, var = var, /split
end

pro eva_sitl_set_value, id, value ; In this case, value = activate
  compile_opt idl2
  stash = widget_info(id, /child)
  widget_control, stash, get_uvalue = state, /no_copy
  ; -----
  if n_tags(value) eq 0 then begin
    eva_sitl_update_board, state, value
  endif else begin
    str_element, /add, state, 'pref', value
  endelse
  ; -----
  widget_control, stash, set_uvalue = state, /no_copy
end

function eva_sitl_get_value, id
  compile_opt idl2
  stash = widget_info(id, /child)
  widget_control, stash, get_uvalue = state, /no_copy
  ; -----
  ret = state
  ; -----
  widget_control, stash, set_uvalue = state, /no_copy
  return, ret
end

function eva_sitl_event, ev
  compile_opt idl2
  @xtplot_com.pro
  @tplot_com

  parent = ev.handler
  stash = widget_info(parent, /child)
  widget_control, stash, get_uvalue = state, /no_copy
  if n_tags(state) eq 0 then return, {id: ev.handler, top: ev.top, handler: 0l}

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    widget_control, stash, set_uvalue = state, /no_copy
    message, /reset
    return, {id: ev.handler, top: ev.top, handler: 0l}
  endif

  set_multi = widget_info(state.cbMulti, /button_set)
  set_trange = widget_info(state.cbWTrng, /button_set)
  submit_code = 0
  refresh_dash = 0
  sanitize_fpi = 1
  xtplot_right_click = 1
  save = 1

  case ev.id of
    state.btnAdd: begin
      print, 'EVA: ***** EVENT: btnAdd *****'
      str_element, /add, state, 'group_leader', ev.top
      eva_ctime, /silent, routine_name = 'eva_sitl_seg_add', state = state, occur = 2, npoints = 2 ; npoints
    end
    state.btnFill: begin
      print, 'EVA: ***** EVENT: btnFill *****'
      str_element, /add, state, 'group_leader', ev.top
      eva_ctime, /silent, routine_name = 'eva_sitl_seg_fill', state = state, occur = 1, npoints = 1 ; npoints
    end
    state.btnEdit: begin
      print, 'EVA: ***** EVENT: btnEdit *****'
      str_element, /add, state, 'group_leader', ev.top
      eva_ctime, /silent, routine_name = 'eva_sitl_seg_edit', state = state, occur = 1, npoints = 1 ; npoints
    end
    state.btnDelete: begin
      print, 'EVA: ***** EVENT: btnDelete *****'
      npoints = 1
      occur = 1
      eva_ctime, /silent, routine_name = 'eva_sitl_seg_delete', state = state, occur = occur, npoints = npoints
    end
    state.cbMulti: begin ; Delete N segments with N clicks
      print, 'EVA: ***** EVENT: cbMulti *****'
      npoints = 2000
      occur = 1

      ; The right-click-event during eva_ctime seems to be executed
      ; AFTER this eva_sitl/cbMulti event has ended. So, it is not meaningful to
      ; set xtplot_right_click back to 1 before the end of this event handler.
      ; We set xtplot_right_click 0 here, but we have to execute another widget
      ; event in order to set it back to 1. We have xtplot_right_click=1 at the
      ; beggining of this event handler so that the right click will be turned back
      ; on after any addition SITL event (except cbMulti).
      xtplot_right_click = 0

      eva_ctime, /silent, routine_name = 'eva_sitl_seg_delete', state = state, occur = occur, npoints = npoints
    end
    state.cbWTrng: begin ; Delete N segment within a range specified by 2-clicks
      print, 'EVA: ***** EVENT: cbWTrng *****'
      npoints = 2
      occur = 2
      eva_ctime, /silent, routine_name = 'eva_sitl_seg_delete', state = state, occur = occur, npoints = npoints
    end
    state.btnSplit: begin
      print, 'EVA: ***** EVENT: btnSplit *****'
      result = 'Yes'
      if state.pref.eva_bakstruct then begin
        msg = 'Please DO NOT SPLIT pre-existing segments. '
        msg = [msg, 'You can only split a segment that was newly created during']
        msg = [msg, 'this EVA session (by you) and has not been processed at SDC.']
        msg = [msg, ' ']
        msg = [msg, 'Would you still like to proceed and split?']
        result = dialog_message(msg, /center, /question)
      endif
      if result eq 'Yes' then begin
        str_element, /add, state, 'group_leader', ev.top
        eva_ctime, /silent, routine_name = 'eva_sitl_seg_split', state = state, occur = 1, npoints = 1 ; npoints
        sanitize_fpi = 0
      endif
    end
    state.btnUndo: begin
      print, 'EVA: ***** EVENT: btnUndo *****'
      eva_sitl_fom_recover, 'undo'
    end
    state.btnRedo: begin
      print, 'EVA: ***** EVENT: btnRedo *****'
      eva_sitl_fom_recover, 'redo'
    end
    state.btnAllAuto: begin
      print, 'EVA: ***** EVENT: btnAllAuto *****'
      eva_sitl_fom_recover, 'rvrt'
    end
    ; state.btnValidate: begin
    ; save = 0
    ; print,'EVA: ***** EVENT: btnValidate *****'
    ; title = 'Validation'
    ; if state.PREF.EVA_BAKSTRUCT then begin
    ; tn = tnames()
    ; idx = where(strmatch(tn,'mms_stlm_bakstr'),ct)
    ; if ct eq 0 then begin
    ; msg = 'Back-Structure not found. If you wish to'
    ; msg = [msg, 'submit a FOM structure, please disable the back-']
    ; msg = [msg, 'structure mode.']
    ; rst = dialog_message(msg,/error,/center,title=title)
    ; endif else begin
    ; get_data,'mms_stlm_bakstr',data=Dmod, lim=lmod,dl=dlmod
    ; get_data,'mms_soca_bakstr',data=Dorg, lim=lorg,dl=dlorg
    ; tai_BAKStr_org = lorg.unix_BAKStr_org
    ; str_element,/add,tai_BAKStr_org,'START', mms_unix2tai(lorg.unix_BAKStr_org.START); LONG
    ; str_element,/add,tai_BAKStr_org,'STOP',  mms_unix2tai(lorg.unix_BAKStr_org.STOP) ; LONG
    ; tai_BAKStr_mod = lmod.unix_BAKStr_mod
    ; str_element,/add,tai_BAKStr_mod,'START', mms_unix2tai(lmod.unix_BAKStr_mod.START); LONG
    ; str_element,/add,tai_BAKStr_mod,'STOP',  mms_unix2tai(lmod.unix_BAKStr_mod.STOP) ; LONG
    ;
    ; header = eva_sitl_text_selection(lmod.unix_BAKStr_mod,/bak)
    ;
    ; vsp = '////////////////////////////'
    ; header = [header, vsp+' VALIDATION RESTULT (NEW SEGMENTS) '+vsp]
    ; r = eva_sitl_validate(tai_BAKStr_mod, -1, vcase=1, header=header, /quiet, valstruct=state.val); Validate New Segs
    ; header = [r.msg,' ', vsp+' VALIDATION RESULT (MODIFIED SEGMENTS) '+vsp]
    ; r2 = eva_sitl_validate(tai_BAKStr_mod, tai_BAKStr_org, vcase=2, header=header, valstruct=state.val); Validate Modified Seg
    ; endelse; if ct eq 0
    ; endif else begin
    ; get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
    ; get_data,'mms_soca_fomstr',data=Dorg, lim=lorg,dl=dlorg
    ; mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
    ; mms_convert_fom_unix2tai, lorg.unix_FOMStr_org, tai_FOMstr_org; Original FOM for reference
    ; header = eva_sitl_text_selection(lmod.unix_FOMstr_mod)
    ; vcase = 0;(state.USER_FLAG eq 4) ? 3 : 0
    ; r = eva_sitl_validate(tai_FOMstr_mod, tai_FOMstr_org, vcase=vcase, header=header, valstruct=state.val)
    ; endelse
    ; end
    ; state.btnEmail: begin
    ; print,'EVA: ***** EVENT: btnEmail *****'
    ; if state.PREF.EVA_BAKSTRUCT then begin
    ; msg = 'Email for Back Structure Mode is under construction.'
    ; result = dialog_message(msg,/center)
    ; endif else begin
    ; get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dmod
    ; mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
    ; header = eva_sitl_text_selection(lmod.unix_FOMstr_mod)
    ; body = ''
    ; nmax = n_elements(header)
    ; for n=0,nmax-1 do begin
    ; body += header[n] + 'rtn'
    ; endfor
    ; email_address = 'mitsuo.oka@gmail.com'
    ; syst = systime(/utc)
    ; oUrl = obj_new('IDLnetUrl')
    ; txturl = 'http://www.ssl.berkeley.edu/~moka/evasendmail.php?email='$
    ;          +email_address+'&fomstr='+body+'&time='+syst
    ;        ok = oUrl->Get(URL=txturl,/STRING_ARRAY)
    ;        obj_destroy, oUrl
    ;        result=dialog_message('Email sent to '+email_address,/center,/info)
    ;      endelse
    ;      end
    state.drpHighlight: begin
      save = 0
      print, 'EVA: ***** EVENT: drpHighlight *****'
      tplot
      type = state.hlSet2[ev.index]
      isPending = 0
      inPlaylist = 0
      status = ''
      default = 0
      case type of
        'Default': default = 1
        'isPending': isPending = 1
        'inPlaylist': inPlaylist = 1
        else: status = type
      endcase
      tn = tnames('*bakstr*', ct_bak)
      if (ct_bak gt 0) then begin
        get_data, 'mms_stlm_bakstr', data = D, lim = lim, dl = dl
        if (not default) then begin ; ...... if (not DEFAULT)
          if n_tags(lim) gt 0 then begin
            D = eva_sitl_strct_read(lim.unix_bakStr_mod, 0.d0, $
              ispending = isPending, inplaylist = inPlaylist, status = status)
            nmax = n_elements(D.x)
            if nmax ge 5 then begin
              trange = tplot_vars.options.trange
              left_edges = (D.x[1 : nmax - 1 : 4] > trange[0]) < trange[1]
              right_edges = (D.x[4 : nmax - 1 : 4] > trange[0]) < trange[1]
              data = D.y[2 : nmax - 1 : 4]
              vvv = state.pref.eva_bakstruct ? 'mms_stlm_bakstr' : 'mms_stlm_fomstr'
              eva_sitl_highlight, left_edges, right_edges, data, vvv, /noline
              ; eva_sitl_highlight, left_edges, right_edges, data, state, /noline
            endif ; if nmax
          endif ; if n_tags
        endif else begin
          s = lim.unix_baKstr_mod ; ...........  if DEFAULT
          Nsegs = n_elements(s.fom)
          print, 'EVA:----- List of back-structure segments -----'
          print, 'EVA:number, start time         , FOM    , status, sourceID'
          for N = 0, Nsegs - 1 do begin
            strN = string(N, format = '(I5)')
            strF = string(s.fom[N], format = '(F7.3)')
            print, 'EVA: ' + strN + ': ' + time_string(s.start[N]) + ', ' + strF + ', ' + s.status[N] + ', ' + s.sourceid[N]
          endfor
        endelse
      endif
    end
    state.drpSave: begin
      save = 0
      print, 'EVA: ***** EVENT: drpSave *****'
      widget_control, widget_info(ev.top, find = 'eva_data'), get_value = state_data
      dir = state_data.pref.eva_cache_dir
      type = state.svSet[ev.index]
      case type of
        ; 'Save': eva_sitl_save,/auto,dir=dir
        ; 'Restore': eva_sitl_restore,/auto,dir=dir
        'Save As': eva_sitl_save
        'Restore From': eva_sitl_restore, state_data
        else: answer = dialog_message('Something is wrong.')
      endcase
    end
    ; state.btnSubmit: begin
    ; save=0
    ; print,'EVA: ***** EVENT: btnSubmit *****'
    ; print,'EVA: TESTMODE='+string(state.PREF.EVA_TESTMODE_SUBMIT)
    ; submit_code = 1
    ; if state.PREF.EVA_BAKSTRUCT then begin
    ; eva_sitl_submit_bakstr,ev.top, state.PREF.EVA_TESTMODE_SUBMIT
    ; endif else begin
    ;
    ; ; Look for pre-existing note
    ; get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
    ; tn = tag_names(lmod.unix_FOMstr_mod)
    ; idx = where(strmatch(tn,'NOTE'),ct)
    ; if ct gt 0 then begin
    ; varname = lmod.unix_FOMstr_mod.NOTE
    ; endif else varname = ''
    ;
    ; ; Textbox for NOTE
    ; varname = mms_TextBox(Title='EVA TEXTBOX', Group_Leader=ev.top, $
    ; Label='Please add/edit your comment on this ROI: ', $
    ; SecondLabel='(The text will wrap automatically. A carriage',$
    ; ThirdLabel='return is same as hitting the Save button.)',$
    ; Cancel=cancelled, Continue_Submission=contin, $
    ; XSize=300, Value=varname)
    ;
    ; ; Submission
    ; if not cancelled then begin
    ; print,'EVA: Saving the following string:', varname
    ; get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
    ; str_element,/add,lmod,'unix_FOMstr_mod.NOTE', varname
    ; store_data,'mms_stlm_fomstr',data=Dmod, lim=lmod, dl=dlmod
    ; if contin then begin
    ; print,'EVA: Continue Submission....'
    ; vcase = 0;(state.USER_FLAG eq 4) ? 3 : 0
    ; eva_sitl_submit_fomstr,ev.top, state.PREF.EVA_TESTMODE_SUBMIT, vcase, user_flag=state.USER_FLAG
    ; endif else print,'EVA:  but just saved...'
    ; endif else begin
    ; print,'EVA: Submission cancelled...'
    ; endelse
    ;
    ; endelse
    ; end
    state.drDash: begin
      save = 0
      sanitize_fpi = 0
      refresh_dash = 1
    end
    else: print, 'EVA: else'
  endcase

  ; FPI = (state.USER_FLAG eq 4)
  ; if(FPI and sanitize_fpi) then begin; Revert hacked FOMstr (i.e. remove the fake segment)
  ; get_data,'mms_stlm_fomstr',data=D,dl=dl,lim=lim
  ; s = lim.unix_FOMstr_mod
  ; snew = s
  ; if (s.NSEGS gt 1) and (s.START[0] eq 0) and (s.STOP[0] eq 1) and (s.FOM[0] eq 0.) then begin
  ; str_element,/add,snew, 'FOM', s.FOM[1:s.NSEGS-1]
  ; str_element,/add,snew, 'START', s.START[1:s.NSEGS-1]
  ; str_element,/add,snew, 'STOP', s.STOP[1:s.NSEGS-1]
  ; str_element,/add,snew, 'NSEGS', s.NSEGS-1L
  ; str_element,/add,snew, 'NBUFFS', s.NBUFFS-1L
  ; str_element,/add,snew, 'FPICAL', 0L; Set 0 because the dummy segment does not exist anymore
  ; str_element,/add,lim,'unix_FOMstr_mod',snew
  ; D_hacked = eva_sitl_strct_read(snew,min(snew.START,/nan))
  ; store_data,'mms_stlm_fomstr',data=D_hacked,lim=lim,dl=dl
  ; endif
  ; endif

  ; When not refreshing the dashboard, we update validation structure as often as possible.
  ; The dashboard, whenever refreshing, will use the updated validation structure to
  ; refresh the information. Technically, we could update validation structure within
  ; the dashboard refreshing process, but this will cause numerous access to SDC.
  if ~refresh_dash then begin
    val = mms_load_fom_validation()
    str_element, /add, state, 'val', val
  endif

  if ~submit_code then begin
    tn = tnames('*_stlm_*', ct)
    if ct gt 0 then s = 1 else s = 0
    eva_sitl_update_board, state, s
    if (s eq 1) and (state.stack eq 0) then begin ; At the first call to eva_sitl_update_board
      eva_sitl_stack ; with mms_sitl_ouput_fom, we initiate
      str_element, /add, state, 'stack', 1 ; stacking.
    endif
  endif

  if save then begin
    eva_sitl_save, /auto, dir = dir, /quiet
  endif

  widget_control, stash, set_uvalue = state, /no_copy
  RETURN, {id: parent, top: ev.top, handler: 0l}
end

; -----------------------------------------------------------------------------

function eva_sitl, parent, $
  uvalue = uval, uname = uname, tab_mode = tab_mode, title = title, xsize = xsize, ysize = ysize, $
  dash_ysize = dash_ysize
  compile_opt idl2
  ; @xtplot_com.pro

  if (n_params() eq 0) then message, 'Must specify a parent for CW_sitl'

  if not (keyword_set(uval)) then uval = 0
  if not (keyword_set(uname)) then uname = 'eva_sitl'
  if not (keyword_set(title)) then title = '   MAIN   '

  ; ----- STATE -----
  pref = { $
    eva_bakstruct: 0, $
    eva_testmode_submit: 1, $
    eva_split_size: 0, $ ; val.NOMINAL_SEG_RANGE[1]}
    eva_stlm_input: 'soca', $ ;
    eva_gls1_algo: 'mp-dl-unh', $
    eva_gls2_algo: 'none', $
    eva_gls3_algo: 'none', $
    eva_stlm_update: 1, $
    eva_basepos: 0}

  socs = { $ ; SOC Auto Simulated
    pmdq: ['a', 'b', 'c', 'd'], $ ; probes to be used for calculating MDQs
    input: 'thm_archive'} ; input to be used for simulating SOC-Auto
  stlm = { $ ; SITL Manu
    input: 'socs', $ ; input type (default: 'soca'; or 'socs','stla')
    update_input: 1} ; update input data everytime plotting STLM variables
  state = { $
    parent: parent, $
    pref: pref, $
    socs: socs, $
    stlm: stlm, $
    stack: 0, $
    set_multi: 0, $
    set_trange: 0, $
    rehighlight: 0, $
    launchtime: systime(1, /utc), $
    user_flag: 0, $
    userType: ['MMS member', 'SITL', 'Super SITL'], $
    uplink: 0l} ; ,$;'FPI cal']}
  ; userType: ['Guest','MMS member','SITL','Super SITL']};,'FPI cal']}
  ; val: mms_load_fom_validation()}

  ; ----- CONFIG (READ) -----
  cfg = mms_config_read() ; Read config file and
  pref = mms_config_push(cfg, pref) ; push the values into preferences
  pref.eva_bakstruct = 0
  pref.eva_testmode_submit = 1
  pref.eva_split_size = 0 ; Added on 2016-03-26 (in response to Barbara's request of forcing into the default size)
  str_element, /add, state, 'pref', pref

  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent, /geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize

  hlSet = ['Default', 'isPending', 'inPlaylist', 'Held', 'Complete', 'Overwritten']
  hlSet2 = ['Default', 'isPending', 'inPlaylist', 'Held', 'Complete', 'New', 'Modified', $
    'Deleted', 'Aborted', 'Finished', 'Incomplete', 'Derelict', 'Demoted', 'Realloc', 'Deferred']
  svSet = ['Restore From', 'Save As'] ; svSet = ['Save','Restore','Save As', 'Restore From']

  mainbase = widget_base(parent, uvalue = uval, uname = uname, title = title, $
    event_func = 'eva_sitl_event', $
    func_get_value = 'eva_sitl_get_value', $
    pro_set_value = 'eva_sitl_set_value', /column, $
    xsize = xsize, ysize = ysize, sensitive = 1, space = 0, ypad = 0)
  str_element, /add, state, 'mainbase', mainbase
  str_element, /add, state, 'lblTgtTimeMain', widget_label(mainbase, value = '(Select a paramter-set for SITL)', /align_left, xsize = xsize)

  subbase = widget_base(mainbase, /column, sensitive = 0)
  str_element, /add, state, 'subbase', subbase

  bsAction = widget_base(subbase, /column, /frame)
  ; #####################################################################
  str_element, /add, state, 'drDash', widget_draw(bsAction, graphics_level = 2, xsize = xsize - 20, ysize = dash_ysize, /expose_event)
  ; #####################################################################

  bsAction0 = widget_base(bsAction, /column, space = 0, ypad = 0, sensitive = 0)
  str_element, /add, state, 'bsAction0', bsAction0
  bsActionButton = widget_base(bsAction0, /row)
  bsActionAdd = widget_base(bsActionButton, /column)
  str_element, /add, state, 'btnAdd', widget_button(bsActionAdd, value = '  Add  ')
  str_element, /add, state, 'btnFill', widget_button(bsActionAdd, value = '  Fill  ')
  str_element, /add, state, 'btnEdit', widget_button(bsActionButton, value = '  Edit  ')
  str_element, /add, state, 'btnDelete', widget_button(bsActionButton, value = ' Del ') ; ,/TRACKING_EVENTS)
  bsActionCheck = widget_base(bsActionButton, /column) ; ,/NONEXCLUSIVE)
  str_element, /add, state, 'cbMulti', widget_button(bsActionCheck, value = 'Delete multi seg', sensitive = 1)
  str_element, /add, state, 'cbWTrng', widget_button(bsActionCheck, value = 'Delete w/in a range', sensitive = 1)
  bsActionHistory = widget_base(bsAction0, /row, space = 0, ypad = 0)
  str_element, /add, state, 'btnUndo', widget_button(bsActionHistory, value = ' Undo ')
  str_element, /add, state, 'btnRedo', widget_button(bsActionHistory, value = ' Redo ')
  str_element, /add, state, 'btnAllAuto', widget_button(bsActionHistory, value = ' Revert to Auto ')
  str_element, /add, state, 'bsDummy', widget_base(bsActionHistory, xsize = 40)
  str_element, /add, state, 'btnSplit', widget_button(bsActionHistory, value = ' Split ')
  bsActionHighlight = widget_base(bsAction0, /row, space = 0, ypad = 0)
  str_element, /add, state, 'drpHighlight', widget_droplist(bsActionHighlight, value = hlSet, $
    title = 'Status:', sensitive = 1)
  str_element, /add, state, 'hlSet', hlSet
  str_element, /add, state, 'hlSet2', hlSet2
  ; bsActionSave = widget_base(bsAction0,/ROW, SPACE=0, YPAD=0)
  str_element, /add, state, 'drpSave', widget_droplist(bsActionHighlight, value = svSet, $
    title = 'FOM:', sensitive = 1)
  str_element, /add, state, 'svSet', svSet
  ; bsActionUplink = widget_base(bsAction0, /COLUMN, SPACE=0, YPAD=0)
  ; str_element,/add,state,'lblEvalStartTime',widget_label(bsActionUplink,VALUE='Next SITL Window Start Time: N/A                    ',/align_left)
  ; ;str_element,/add,state,'lblUplink',widget_label(bsActionUplink,VALUE='Uplink - No  ')

  ; bsActionSubmit = widget_base(subbase,/ROW, SENSITIVE=0)
  ; str_element,/add,state,'bsActionSubmit',bsActionSubmit
  ; str_element,/add,state,'btnValidate',widget_button(bsActionSubmit,VALUE=' Validate ')
  ; ;    str_element,/add,state,'btnEmail',widget_button(bsActionSubmit,VALUE=' Email ')
  ; dumSubmit2 = widget_base(bsActionSubmit,xsize=80); Comment out this line when using Email
  ; dumSubmit = widget_base(bsActionSubmit,xsize=60)
  ; str_element,/add,state,'btnSubmit',widget_button(bsActionSubmit,VALUE='   DRAFT   ')

  ; Save out the initial state structure into the first childs UVALUE.
  widget_control, widget_info(mainbase, /child), set_uvalue = state, /no_copy

  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, mainbase
end