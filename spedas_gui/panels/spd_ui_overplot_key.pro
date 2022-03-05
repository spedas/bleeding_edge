;+
;NAME:
;  spd_ui_overplot_key
;
;PURPOSE:
;  Pops up a window that displays an overview plot key (the same one that's on the website).
;
;CALLING SEQUENCE:
;  spd_ui_overplot_key, gui_id, historyWin, modal=modal, goes=goes
;
;INPUT:
;  gui_id:  The id of the main GUI window.
;  historyWin:  The history window object.
;
;KEYWORDS:
;  modal:  flag to set the modal of the top level base
;  goes: display the GOES overview plot key. 
;      If this is set, it should be set to the GOES spacecraft #, 
;      as GOES 8-12 and GOES 13-15 have different overview plots
;
;OUTPUT:
;  none
;  
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 11:48:01 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_overplot_key.pro $
;-----------------------------------------------------------------------------------

pro spd_ui_overplot_key_draw, state

  compile_opt idl2, hidden
  
  getresourcepath,rpath

  if state.poes eq 1 then begin
    key = read_png(rpath + 'poes_key.png')
  endif else if state.goes eq 0 && state.poes eq 0 && state.secs eq 0 then begin
    key = read_png(rpath + 'overplotkey.png')
  endif else if state.goes ge 8 && state.goes le 12 then begin
    ; GOES 8-12
    key = read_png(rpath + 'goes10-12key.png')
  endif else if state.goes ge 13 && state.goes le 15 then begin
    ; GOES 13-15
    key = read_png(rpath + 'goes13-15key.png')
  endif else if state.secs eq 1 then begin
    ; SECS Quicklook Plots
    key = read_png(rpath + 'secs_quicklook_key.png')
  endif else if state.secs eq 2 then begin
    ; SECS eics mosaic Plots
    key = read_png(rpath + 'secs_mosaic_key.png')
  endif else if state.secs eq 3 then begin
    ; SECS seca mosaic Plots
    key = read_png(rpath + 'seca_mosaic_key.png')
  endif

  keyImageObj = obj_new('IDLgrImage', key, dimen=[1,1])
  
  model = obj_new('IDLgrModel')
  model->add, keyImageObj
  
  viewRect = [0.0, 0.0, 1.0, 1.0]
  view = Obj_New('IDLgrView', units=3, viewplane_rect=[0,0,1.,1.])
  view->add, model
  
  scene = obj_new('IDLgrScene')
  scene->add, view
  
  widget_control, state.keyDisplay, get_value=drawWin
  
  drawWin->draw, scene
  
end

pro spd_ui_overplot_key_event, event

  compile_opt idl2, hidden
  
  Widget_Control, event.TOP, Get_UValue=state, /No_Copy
   
  ;catch block for future additions
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Overplot Key'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
  
    dprint,  'Overview Plot Key widget killed'
    state.historyWin->Update,'SPD_UI_OVERPLOT_KEY: Widget killed'
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN
  ENDIF   
  
  IF(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_DRAW') THEN BEGIN
  
    ;this code redraws the window if manual redraw & expose events are enabled
    if event.type eq 4 then begin
      spd_ui_overplot_key_draw, state
    endif
    
    Widget_Control, event.top, Set_UValue=state, /No_Copy
    RETURN
  ENDIF
  
  ;  what happened?
  ;  widget_control, event.top, get_uval = state
  widget_control, event.id, get_uval = uval
  
  ; check for empty event coming from one of the other event handlers
  if size(uval,/type) eq 0 then begin
    Widget_Control, event.top, Set_UValue = state, /No_Copy
    RETURN
  endif
  
  Case uval Of
    'EXIT': BEGIN
      dprint,  'Overview Plot Key dismissed.'
      Widget_Control, event.top, Set_UValue=state, /No_Copy
      widget_control, event.top, /destroy
      RETURN
    END
    ELSE: dprint,  'Not yet implemented'
  Endcase
  
  Widget_Control, event.top, Set_UValue=state, /No_Copy
  
  Return
end

pro spd_ui_overplot_key, gui_id, historyWin, modal = modal, goes = goes, poes = poes, $
  secs = secs

  compile_opt idl2, hidden
 
  y_length = 0
  screen_size = GET_SCREEN_SIZE()
  y_length = screen_size[1] - 140
  if (screen_size[1] gt 900) then y_length=900
  if (y_length le 450) then y_length=450
  ; check if the GOES or POES overview plot panel sent us here
  if undefined(goes) then goes=0
  if undefined(poes) then poes=0
  if undefined(secs) then secs=0
 
  overplot_xsize = 750
  
  ; ysize for overview plots:
  ;  THEMIS: 900px, GOES: 1015px, POES: 800px
  overplot_ysize = goes ne 0 ? 1015 : 900
  overplot_ysize = poes ne 0 ? 800 : overplot_ysize
  if (secs EQ 1) then begin    
     overplot_ysize = 550
     overplot_xsize = 850
  endif 
  if secs GE 2 then begin
    overplot_ysize = 450
    overplot_xsize = 750     
  endif
 
  keyid = widget_base(/col, title='Overview Plot Key', group_leader=gui_id, modal=modal, TLB_FRAME_ATTR=1)
  
  keyDisplay = widget_draw(keyid, graphics_level=2, renderer=0, retain=2, XSize=overplot_xsize, YSIZE=overplot_ysize, units=0, x_scroll_size=overplot_xsize, y_scroll_size=y_length, /expose_events)
  buttons= widget_base(keyid, /row, /align_center)
  exitButtonBase = widget_base(buttons, /col, /align_center)
  exitButton = widget_button(exitButtonBase, val=' Close ', uval='EXIT', /align_center)

  state = {gui_id:gui_id, historyWin:historyWin, keyDisplay:keyDisplay, goes:goes, poes:poes, secs:secs}
  
  Widget_Control, keyid, Set_UValue=state, /No_Copy
  CenterTLB, keyid
  Widget_Control, keyid, /Realize
  
  Widget_Control, keyid, Get_UValue=state, /No_Copy
  
  spd_ui_overplot_key_draw, state
  
  Widget_Control, keyid, Set_UValue=state, /No_Copy
  Widget_Control, keyid, /Realize
  
  xmanager, 'spd_ui_overplot_key', keyid, /no_block
  Return
end
