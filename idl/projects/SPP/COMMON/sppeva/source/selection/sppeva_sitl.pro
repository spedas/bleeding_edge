;+
; NAME: SPPEVA_SITL
;
; PURPOSE: An SPPEVA module for data selection
;
; CREATED BY: Mitsuo Oka   Sep 2018
;
;
; $LastChangedBy: moka $
; $LastChangedDate: 2020-08-02 15:57:07 -0700 (Sun, 02 Aug 2020) $
; $LastChangedRevision: 28971 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sppeva/source/selection/sppeva_sitl.pro $
;-
;
; For a given time range 'trange', create "segSelect"
; which will be passed to eva_sitl_FOMedit for editing
PRO sppeva_sitl_seg_add, trange, state=state, var=var
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

  time = timerange(/current)
  nmax = floor((time[1]-time[0])/1.d0); How many 1 second?
  wgrid = time[0] + dindgen(nmax)  
  ts_limit = time[0]
  te_limit = time[1]

  if n_elements(var) eq 0 then message,'Must pass tplot-variable name'
  segSelect = {ts:trange[0], te:trange[1], fom:5, BAK:0, discussion:' ', var:var,$
    ts_limit:ts_limit, te_limit:te_limit}
  vvv = 'spp_'+strlowcase(!SPPEVA.COM.MODE)+'_fomstr' 
  eva_sitl_FOMedit, state, segSelect, wgrid=wgrid, vvv=vvv, proj='spp', $
    fom_min_value = 0, fom_max_value=!SPPEVA.GENE.fom_max_value, basepos=!SPPEVA.GENE.BASEPOS

END

PRO sppeva_sitl_seg_fill, t, state=state, var=var
  compile_opt idl2
  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return
  endif

  if n_elements(var) eq 0 then message,'Must pass tplot-variable name'
  if n_elements(t) ne 1 then message,'Something is wrong'
  
  vvv = 'spp_'+strlowcase(!SPPEVA.COM.MODE)+'_fomstr'
  get_data,vvv,data=D,lim=lim,dl=dl
  s = dl.FOMstr
  tnew = -1
  
  idx = where((s.START le t) and (t le s.STOP), ct)
  
  for N=0,s.Nsegs-2 do begin
    if (s.STOP[N] lt t) and (t lt s.START[N+1]) then begin
      tnew = [s.STOP[N], s.START[N+1]]
    endif
  endfor
  if (t lt s.START[0]) then begin
    tnew = [!SPPEVA.COM.STRTR[0], s.START[0]]
  endif
  if (s.STOP[s.Nsegs-1] lt t) then begin
    tnew = [s.STOP[s.Nsegs-1], !SPPEVA.COM.STRTR[1]]
  endif

  if n_elements(tnew) ne 2 then message,'Something is wrong'

  sppeva_sitl_seg_add, tnew, state=state, var=vvv
END


; For a given time 't', find the corresponding segment from
; FOMStr and then create "segSelect" which will be passed
; to eva_sitl_FOMedit for editing
PRO sppeva_sitl_seg_edit, t, state=state, var=var, delete=delete, split=split

  ;---------------
  ; CATCH
  ;---------------
  compile_opt idl2
  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return
  endif

  ;---------------
  ; FOMstr
  ;---------------
  if n_elements(var) eq 0 then message,'Must pass tplot-variable name'
  if (n_elements(t) ne 1) and (not keyword_set(delete)) then message,'Something is wrong'
  vvv = 'spp_'+strlowcase(!SPPEVA.COM.MODE)+'_fomstr' 
  get_data,vvv,data=D,lim=lim,dl=dl
  s = dl.FOMstr
  if s.Nsegs eq 0 then begin
    result= dialog_message('SPPEVA: There is no segment to work on.',/center)
    stop
    return
  endif

  ;---------------------
  ; segSelect
  ;---------------------
  if n_elements(t) eq 1 then begin
    idx = where((s.START le t) and (t le s.STOP), ct)
    if ct ge 1 then begin
      ts = s.START[idx[0]]
      te = s.STOP[idx[0]]
      fom = s.FOM[idx[0]]
      discussion = s.DISCUSSION[idx[0]]
    endif
;     else begin
;      result = dialog_message("SPPEVA: Please choose a segment.",/center)
;      return
;    endelse
  endif else begin
    ts = t[0]
    te = t[1]
    fom = 0.
    discussion = ''
    ct = 1L
  endelse
  segSelect = {ts:ts, te:te, fom:fom, BAK: 0, discussion:discussion, var:vvv}

  ;---------------------
  ; Grid
  ;---------------------
  time = timerange(/current)
  nmax = floor((time[1]-time[0])/1.d0); How many 1 second?
  wgrid = time[0] + dindgen(nmax)
  
  ;---------------------
  ; DELETE segSelect
  ;---------------------
  if keyword_set(delete) then begin
    str_element,/add,segSelect,'FOM',0.
    sppeva_sitl_tplot_update, segSelect, vvv
    tplot, verbose=0
    return
  endif
  
  ;---------------------
  ; SPLIT segSelect
  ;---------------------
  if keyword_set(split) then begin
    gTmin = segSelect.TS
    gTmax = segSelect.TE
    gTdel = double(!SPPEVA.GENE.split_size_in_sec)
    gFOM = segSelect.FOM
    gBAK = segSelect.BAK
    gDIS = segSelect.DISCUSSION
    gVAR = segSelect.VAR
    nmax = ceil((gTmax-gTmin)/gTdel)
    gTdel = (gTmax-gTmin)/double(nmax)

    if nmax gt 0 then begin

      ; delete the segment
      segSelect.FOM = 0.
      sppeva_sitl_tplot_update, segSelect, vvv

      ; add split segments
      for n=0,nmax-1 do begin
        Ts = gTmin+gTdel*n
        Te = gTmin+gTdel*(n+1)
        segSelect = {ts:Ts,te:Te,fom:gFOM,BAK:gBAK, discussion:gDIS, var:gVAR}
        sppeva_sitl_tplot_update, segSelect, vvv
      endfor

    endif; if nmax
    tplot,verbose=0
    return
  endif
  
  ;---------------------
  ; EDIT segSelect
  ;---------------------

  eva_sitl_FOMedit, state, segSelect, wgrid=wgrid, vvv=vvv, proj='spp', $
    fom_min_value = 0, fom_max_value=!SPPEVA.GENE.fom_max_value, basepos=!SPPEVA.GENE.BASEPOS
END

PRO sppeva_sitl_seg_delete, t, state=state, var=var
  sppeva_sitl_seg_edit, t, state=state, var=var, /delete
END

PRO sppeva_sitl_seg_delete_all
  vvv = 'spp_'+strlowcase(!SPPEVA.COM.MODE)+'_fomstr'
  fomstr = {Nsegs:0L}
  store_data, vvv, data = {x:time_double(!SPPEVA.COM.STRTR), y:[0.,0.]}, dl={fomstr:fomstr}
  ylim,vvv,0,25,0
  options,vvv,ystyle=1,constant=[5,10,15,20]; Don't just add yrange; Look at the 'fom_vax_value' parameter of eva_sitl_FOMedit
  tplot
END

PRO sppeva_sitl_seg_split, t, state=state, var=var
  sppeva_sitl_seg_edit, t, state=state, var=var, /split
END

PRO sppeva_sitl_fom_recover,strcmd
  compile_opt idl2
  strcmd = strlowcase(strcmd)
  tn = tag_names(!SPPEVA.STACK)
  idx = where(strmatch(tn,!SPPEVA.COM.MODE+'_I'),ct)
  if ct eq 1 then begin    
    i = !SPPEVA.STACK.(idx[0]) ; current location in the list
    imax = !SPPEVA.STACK.(idx[0]+1).Count(); number of elements in the list
    case strcmd of
      'undo': i--; one step backward in time
      'redo': i++; one step forward in time
      else: return
    endcase
    if i lt 0 then begin
      i = 0
      print,'No more history.'
      return
    endif
    if i ge imax then begin
      i = imax-1
      print,'No more history.'
      return
    endif
    s = !SPPEVA.STACK.(idx[0]+1)[i]
    var = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr')
    sppeva_sitl_strct2tplot, s, var
    tplot,verbose=0
    !SPPEVA.STACK.(idx[0]) = i
  endif
END

FUNCTION sppeva_sitl_event, event
  @tplot_com
  compile_opt idl2
  
  parent=event.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=wid, /NO_COPY
  if n_tags(wid) eq 0 then return, { ID:event.handler, TOP:event.top, HANDLER:0L }

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    WIDGET_CONTROL, stash, SET_UVALUE=wid, /NO_COPY
    message, /reset
    return, { ID:event.handler, TOP:event.top, HANDLER:0L }
  endif
  
  SAVE = 1
  
  case event.id of
    wid.btnAdd:  begin
      print,'EVA: ***** EVENT: btnAdd *****'
      str_element,/add,wid,'group_leader',event.top
      eva_ctime,/silent,routine_name='sppeva_sitl_seg_add',state=wid,occur=2,npoints=2;npoints
      end
    wid.btnFill:  begin
      print,'EVA: ***** EVENT: btnFill *****'
      str_element,/add,wid,'group_leader',event.top
      eva_ctime,/silent,routine_name='sppeva_sitl_seg_fill',state=wid,occur=1,npoints=1;npoints
      end
    wid.btnEdit:  begin
      print,'EVA: ***** EVENT: btnEdit *****'
      str_element,/add,wid,'group_leader',event.top
      eva_ctime,/silent,routine_name='sppeva_sitl_seg_edit',state=wid,occur=1,npoints=1;npoints
      end
    wid.btnSplit:begin
      eva_ctime,/silent,routine_name='sppeva_sitl_seg_split',state=wid,occur=1,npoints=1
      end
    wid.btnDelete:begin
      print,'EVA: ***** EVENT: btnDelete *****'
      npoints = 1 & occur = 1
      eva_ctime,/silent,routine_name='sppeva_sitl_seg_delete',state=wid,occur=occur,npoints=npoints
      end
    wid.btnDWR: begin; Delete N segment within a range specified by 2-clicks
      print,'EVA: ***** EVENT: btnDWR *****'
      npoints = 2 & occur = 2
      eva_ctime,/silent,routine_name='sppeva_sitl_seg_delete',state=wid,occur=occur,npoints=npoints
      end
    wid.btnDelAll: begin
      print,'EVA: ***** EVENT: btnDelAll *****'
      sppeva_sitl_seg_delete_all
      end
    wid.btnSWP: begin
      !SPPEVA.COM.MODE = 'SWP'
      SAVE = 0
      end
    wid.btnFLD: begin
      !SPPEVA.COM.MODE = 'FLD'
      SAVE = 0
      end
    wid.btnUndo: sppeva_sitl_fom_recover,'Undo'
    wid.btnRedo: sppeva_sitl_fom_recover,'Redo'
    wid.drpSave: begin
      SAVE = 0
      print,'EVA: ***** EVENT: drpSave *****'
      type = wid.svSet[event.index]
      case type of
        'Save As'     : sppeva_sitl_save
        'Restore From': sppeva_sitl_restore
        'Merge Files': sppeva_sitl_merge
        else: message, 'Something is wrong.'
      endcase
      end
;    wid.btnValidate:answer=dialog_message('This feature is not available yet.',/center)
;    wid.btnSubmit:  answer=dialog_message('This feature is not available yet.',/center)
    else:
  endcase
  
  if SAVE then begin
    sppeva_sitl_save, /auto
    sppeva_sitl_stack
  endif
  sppeva_dash_update
  widget_control, stash, SET_UVALUE=wid, /NO_COPY
  RETURN, { ID:parent, TOP:event.top, HANDLER:0L }
END

FUNCTION sppeva_sitl, parent, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, XSIZE = xsize, YSIZE = ysize
  compile_opt idl2
  
  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for eva_sitl'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'sppeva_sitl'

  ;--------------------
  ; BASE
  ;--------------------

  base = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, /column,$
    EVENT_FUNC = "sppeva_sitl_event", $
    FUNC_GET_VALUE = "sppeva_sitl_get_value", $
    PRO_SET_VALUE = "sppeva_sitl_set_value", $
    XSIZE = xsize, YSIZE = ysize)
  str_element,/add,wid,'base',base

  ;--------------------
  ; ADD/EDIT
  ;--------------------
  bsActionMain = widget_base(base,/COLUMN,space=0,ypad=0, SENSITIVE=1,/frame)
  str_element,/add,wid,'bsActionMain',bsActionMain
  
    bsInstr = Widget_Base(bsActionMain,/ROW, /Exclusive)
    str_element,/add,wid,'btnFLD', widget_button(bsInstr, Value='FIELDS')
    str_element,/add,wid,'btnSWP', widget_button(bsInstr, Value='SWEAP')
    if strmatch(!SPPEVA.COM.MODE,'FLD') then begin
      widget_control, wid.btnFLD, Set_Button=1
    endif else begin
      widget_control, wid.btnSWP, Set_Button=1
    endelse
  
    ;--------------------
    ; Set Main
    ;--------------------
    bsActionButton = widget_base(bsActionMain,/ROW)
    bsActionButtonAdd = widget_base(bsActionButton,/COLUMN)
    str_element,/add,wid,'btnAdd',widget_button(bsActionButtonAdd,VALUE='  Add  ',ysize=55)
    str_element,/add,wid,'btnFill',widget_button(bsActionButtonAdd,VALUE='  Fill  ')
    bsActionButtonEdit = widget_base(bsActionButton,/COLUMN)
    str_element,/add,wid,'btnEdit',widget_button(bsActionButtonEdit,VALUE='  Edit  ',ysize=55)
    str_element,/add,wid,'btnSplit',widget_button(bsActionButtonEdit,VALUE=' Split ')
    bsActionButtonDel = widget_base(bsActionButton,/COLUMN)
    str_element,/add,wid,'btnDelete',widget_button(bsActionButtonDel,VALUE=' Delete ')
    str_element,/add,wid,'btnDWR',widget_button(bsActionButtonDel, VALUE=' Del w/in a range ')
    str_element,/add,wid,'btnDelAll',widget_button(bsActionButtonDel, VALUE=' Delete All ')
    
    ;--------------------
    ; Set Misc
    ;--------------------
    bsActionMisc = widget_base(bsActionMain,/ROW, SPACE=0, YPAD=0)
    str_element,/add,wid,'btnUndo',widget_button(bsActionMisc,VALUE=' Undo ')
    str_element,/add,wid,'btnRedo',widget_button(bsActionMisc,VALUE=' Redo ')
    str_element,/add,wid,'btnSpace',widget_base(bsActionMisc,xsize=10)
    svSet = ['Restore From', 'Merge Files', 'Save As']
    str_element,/add,wid,'drpSave',widget_droplist(bsActionMisc,VALUE=svSet,$
      TITLE='FOM:',SENSITIVE=1)
    str_element,/add,wid,'svSet',svSet
  
  ;-----------------------
  ; SAVE/VALIDATE/SUBMIT
  ;-----------------------
;  bsActionSubmit = widget_base(base,/ROW, SENSITIVE=1)
;  str_element,/add,wid,'bsActionSubmit',bsActionSubmit
;    str_element,/add,wid,'btnValidate',widget_button(bsActionSubmit,VALUE=' Validate ')
;    dumSubmit = widget_base(bsActionSubmit,xsize=100)
;    str_element,/add,wid,'btnSubmit',widget_button(bsActionSubmit,VALUE='   SUBMIT    ')
;


  ; Save out the initial wid structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(base, /CHILD), SET_UVALUE=wid, /NO_COPY

  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, base
END