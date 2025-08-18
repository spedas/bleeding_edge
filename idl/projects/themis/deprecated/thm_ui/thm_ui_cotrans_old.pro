; Generates a new name for a variable, if the old coordinate system is
; in the name, then it is replaced, otherwise, the new system name is
; appended
Function thm_ui_cotrans_newname, vname, c_in0, c_out0

  vnp = strcompress(/remove_all, strlowcase(vname))
  c_in = strcompress(/remove_all, strlowcase(c_in0))
  c_out = strcompress(/remove_all, strlowcase(c_out0))
  lc_in = strlen(c_in)
  vn_test = strpos(vnp, c_in)
  If(vn_test[0] Eq -1) Then nvn = vnp+'_'+c_out $
  Else Begin
    nvn = c_out
    pre = strmid(vnp, 0, vn_test)
    post = strmid(vnp, vn_test+lc_in)
    If(is_string(pre)) Then nvn = pre+nvn
    If(is_string(post)) Then nvn = nvn+post
  Endelse
  Return, nvn
End

;+
;NAME:
; thm_ui_cotrans_old
;PURPOSE:
; Widget for coordinate transforms
;CALLING SEQUENCE:
; thm_ui_cotrans_old, gui_id
;INPUT:
; gui_id = the widget id of the thm_gui widget that called this one.
;OUTPUT:
; none explicit, new variables are created
;HISTORY:
; 26-feb-2007, jmm, jimm@ssl.berkeley.edu
; 10-apr-2007, jmm, changed input from state to the variable names
; 31-may-2007, jmm, rewrite to become its own widget, and to call
;              thm_cotrans, rather than cotrans directly
; 12-jul-2007, jmm, added a message widget, for invalid user input errors
; 06-may-2008, cg, rearranged gui so that message window is at bottom, is
;              longer and doesn't wrap
; 08-apr-2015, af, renaming to avoid conflict with new routine 
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_cotrans_old.pro $
;
;-
Pro thm_ui_cotrans_old_event, event

  Common thm_ui_cotrans_sav, from_sav, to_sav

  err_xxx = 0
  catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    catch, /cancel
    help, /last_message, output = err_msg
    For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
    If(is_struct(state)) Then Begin
      cw = state.cw
      widget_control, state.messw, set_val = err_msg[0]
      For j = 0, n_elements(state.button_arr)-1 Do $
        widget_control, state.button_arr[j], sensitive = 1
      widget_control, event.top, set_uval = state, /no_copy
    Endif Else Begin
      widget_control, event.top, get_uval = state, /no_copy
      If(is_struct(state)) Then Begin
        cw = state.cw
        widget_control, state.messw, set_val = err_msg[0]
        For j = 0, n_elements(state.button_arr)-1 Do $
          widget_control, state.button_arr[j], sensitive = 1
        widget_control, event.top, set_uval = state, /no_copy
      Endif Else cw = -1
    Endelse
    If(widget_valid(cw)) Then Begin
      If(is_struct(wstate)) Then widget_control, cw, set_uval = wstate
      thm_ui_update_history, cw, [';*** FYI', ';'+err_msg]
      thm_ui_update_progress, cw, 'Error--See history'
    Endif
;check for thm_cotrans messages...'
    x1 = strpos(err_msg[0], 'coord. system of input')
    x2 = strpos(err_msg[0], 'know how to transform')
    If(X1[0] Eq -1 And x2[0] Eq -1) Then thm_ui_error
    Return
  Endif
;If the 'X' is hit...
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
    If(is_struct(state) Eq 0) Then $
      widget_control, event.top, get_uval = state, /no_copy
    cw = state.cw
    widget_control, event.top, set_uval = state, /no_copy
    If(is_struct(wstate)) Then $
      widget_control, cw, set_uval = wstate, /no_copy
    widget_control, cw, get_uval = wstate, /no_copy
    For j = 0, n_elements(wstate.button_arr)-1 Do widget_control, $
      wstate.button_arr[j], sensitive = 1
    widget_control, cw, set_uval = wstate, /no_copy
    thm_ui_update_progress, cw, 'Exited from thm_cotrans widget'
    widget_control, event.top, /destroy
    Return
  Endif

  widget_control, event.id, get_uval = uval
  If(uval Eq 'EXIT') Then Begin
    widget_control, event.top, /destroy
  Endif Else If(uval Eq 'COTRANS') Then Begin
;What are the active datasets:
    widget_control, event.top, get_uval = state, /no_copy
    widget_control, state.cw, get_uval = wstate, /no_copy
    If(ptr_valid(wstate.active_vnames)) Then Begin
      vars = *wstate.active_vnames
      widget_control, state.cw, set_uval = wstate, /no_copy
    Endif Else Begin
      widget_control, state.cw, set_uval = wstate, /no_copy
      thm_ui_update_progress, message_wid = state.messw, state.cw, $
        'Cotrans Failed, No Active Data Set'
      widget_control, event.top, set_uval = state, /no_copy
      Return
    Endelse
    new_vars = vars
    For j = 0, n_elements(state.button_arr)-1 Do $
      widget_control, state.button_arr[j], sensitive = 0
    messj = ''
    For j = 0, n_elements(vars)-1 Do Begin
      ic = strcompress(/remove_all, cotrans_get_coord(vars[j]))
      oc = strcompress(/remove_all, strlowcase(to_sav))
      If(ic Eq oc) Then Begin
        messj = 'Input and Output Coordinate Systems are the same for'+vars[j]
        thm_ui_update_progress, message_wid = state.messw, state.cw, messj
        thm_ui_update_history, state.cw, ';'+messj 
      Endif Else If(ic Eq 'unknown') Then Begin
        messj = 'Unknown Input Coordinate System for '+vars[j]+$
          ' No Transformation'
        thm_ui_update_progress, message_wid = state.messw, state.cw, messj
        thm_ui_update_history, state.cw, ';'+messj 
        new_vars[j] = ''
      Endif Else Begin
        thm_ui_update_progress, message_wid = state.messw, state.cw, $
          'Checking for state data...'
        thm_ui_check4spin, vars[j], vspinper, vspinphase, h0
        If(is_string(h0)) Then thm_ui_update_history, state.cw, h0
        thm_ui_check4spin, vars[j], vspinras, vspindec, h1, /rasdec
        thm_ui_update_progress, message_wid = state.messw, state.cw,$
          vars[j]+': '+ic+' to '+oc
        nvj = thm_ui_cotrans_newname(vars[j], ic, oc)
        h2 = 'thm_cotrans,'+''''+vars[j]+''''+', '+''''+nvj+''''+ $
          ', in_coord='+''''+ic+''''+', out_coord='+''''+oc+''''
        thm_ui_update_history, state.cw, h2
        thm_cotrans, vars[j], nvj, in_coord = ic, out_coord = oc
        If(is_string(nvj)) Then Begin
          get_data, nvj, data = ddd
          If(is_struct(ddd)) Then new_vars[j] = nvj Else Goto, failure_j
        Endif Else Begin        ;something odd happened
          failure_j: help, /last_message, output = err_msg
          thm_ui_update_progress, message_wid = state.messw, state.cw, err_msg
          thm_ui_update_history, state.cw, ';'+err_msg
          new_vars[j] = ''
        Endelse
      Endelse
    Endfor
    If(is_string(new_vars) Eq 0) Then Begin
      mess = 'Cotrans Failed, No New variables -- See History for details'
      thm_ui_update_progress, message_wid = state.messw, state.cw, mess
    Endif Else Begin
      thm_ui_update_progress, message_wid = state.messw, state.cw, $
        'Finished Coordinate Transform to '+to_sav
      ok = where(new_vars Ne '') ;must be true if you're here
      new_vars = new_vars[ok]
      thm_ui_update_history, state.cw, $
        thm_ui_multichoice_history('varnames = ', new_vars)
      thm_ui_update_data_all, state.cw, new_vars
    Endelse
    For j = 0, n_elements(state.button_arr)-1 Do $
      widget_control, state.button_arr[j], sensitive = 1
    widget_control, event.top, set_uval = state, /no_copy
  Endif Else Begin
    to_sav = uval
    widget_control, event.top, get_uval = state, /no_copy
    If(state.cw Ne -1) Then $
      thm_ui_update_progress, message_wid = state.messw, state.cw, $
      'Coordinate Transform'+' to '+to_sav
    widget_control, state.ttextw, set_val = '           '+to_sav
    widget_control, event.top, set_uval = state, /no_copy
  Endelse
  Return
End
Pro thm_ui_cotrans_old, calling_widget_id

  Common thm_ui_cotrans_sav, from_sav, to_sav
;Build the widget
  master = widget_base(/col, scr_xsize = 410, $
                       title = 'THEMIS: Coordinate Transformations', $
                       /align_top, group_leader = calling_widget_id, $
                       /tlb_kill_request_events)
;Cotrans buttons widget
  button_master = widget_base(master, /row, /align_center)
  m1 = widget_base(button_master, /row, /align_center, frame=3)
  msp = widget_base(button_master, /col, /align_center)
  m2 = widget_base(button_master, /col, /align_center)
  message_master = widget_base(master, /row)
  splabel=widget_label(msp, value = '       ')
  clabel = widget_label(m1, value = 'Select Output Coordinates:')
  cbuttons = widget_base(m1, /row, /align_center)
;"From" buttons widget
;  fbutbase = widget_base(cbuttons, /col, /align_center)
;  flabel = widget_label(fbutbase, value = 'From:')
;"To" buttons widget
  tbutbase = widget_base(cbuttons, /col, /align_center)
  
;Text widget showing the current transform
  ;ttextbase = widget_base(m2, /col, /align_center)
  ttlabel = widget_label(m2, value = 'Current Transformation:')
  If(n_elements(to_sav) Eq 0) Then to_sav = 'DSL'
  ttextw = widget_text(m2, value =     '            '+to_sav, xsize = 10)
;"Transform" Button
  splabel=widget_label(m2, val = '            ')
  splabel=widget_label(m2, val = '            ')
  splabel=widget_label(m2, val = '            ')
  
  tranbut = widget_button(m2, val = ' Transform ', uval = 'COTRANS', xsize=10)
;"Exit" button
  exitbut = widget_button(m2, val = '  Close  ', uval = 'EXIT', xsize=10)
;message widget
  messw = widget_text(message_master, value = '', xsize = 60, ysize = 5, /scroll)
;set up the coordinate system buttons
  qs = ['SPG', 'SSL', 'DSL', 'GSE', 'GEI', 'GSM']
  nqs = n_elements(qs)
  tj = lonarr(nqs)
  For j = 0, nqs-1 Do $     ;To buttons
    tj[j] = widget_button(tbutbase, value = '   '+qs[j]+'    ', uval = qs[j])

  cw = calling_widget_id 
  widget_control, cw, get_uval = wstate, /no_copy
  wstate.cto_id = master
  widget_control, cw, set_uval = wstate, /no_copy

  state = {thisw:master, cw:cw, ttextw:ttextw, messw:messw, $
           button_arr:[tj, tranbut, exitbut]}

  If(state.cw Ne -1) Then thm_ui_update_progress, state.cw, $
    'Coordinate Transform'+' to '+to_sav

  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  xmanager, 'thm_ui_cotrans_old', master, /no_block


End
