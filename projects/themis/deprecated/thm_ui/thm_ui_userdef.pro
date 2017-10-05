;+
;NAME:
; thm_ui_userdef
;PURPOSE:
; A widget that allows the user to define his own operator to be used
; on the data from a tplot variable, e.g., the user types in the
; string '2.0*!pi*q', and a temporary function is created which takes
; the data and does this multiplication. This is pretty experimental.
;CALLING SEQUENCE:
; thm_ui_userdef, gui_id
;INPUT:
; gui_id = the id of the main gui widget
;OUTPUT:
; none explicit, hopefully new tplot variables are created
;HISTORY:
; 7-jun-2007, jmm, jimm@ssl.berkeley.edu
; 19-oct-2010, jmm, Added a comment to trigger a new snapshot
; 30-jul-2013, jmm, Added another comment, to check SVN
; 27-jan-2014, jmm, Another SVN test comment, to check how SVN switch
;                   works, but this comment is different. If svn
;                   switch work as expected then this comment will be
;                   retained in my local SVN working directory.
; 12-Feb-2014, jmm, Testing SVN messaging
; 12-feb-2014, jmm, Another SVN test
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-12 16:01:10 -0800 (Wed, 12 Feb 2014) $
;$LastChangedRevision: 14369 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_userdef.pro $
;-
Pro thm_ui_userdef_event, event
  widget_control, event.id, get_uval = uval
  Case uval Of
    'EXIT': widget_control, event.top, /destroy
    'FUNC': Begin
      widget_control, event.id, get_val = func_text
      If(is_string(func_text)) Then Begin
        widget_control, event.top, get_uval = state, /no_copy
        ptr_free, state.func_text
        state.func_text = ptr_new(temporary(func_text))
      Endif
      widget_control, event.top, set_uval = state, /no_copy
    End
    'GO':Begin
      widget_control, event.id, get_val = func_text
      If(is_string(func_text)) Then Begin
        thm_ui_create_userdef, func_text, func_name
        widget_control, event.top, get_uval = state
        widget_control, state.cw, get_uval = wstate
        If(ptr_valid(wstate.active_vnames)) Then Begin
          tvn = *wstate.active_vnames
          cw = state.cw
          widget_control, state.cw, set_uval = wstate
          widget_control, event.top, set_uval = state
          vn_new = call_function(tvn, func_name) ;vn_new are new variable names
          thm_ui_update_data_all, cw, vn_new, /add_active
        Endif Else Begin
          widget_control, state.cw, set_uval = wstate
          thm_ui_update_progress, state.cw, $
            'No Active Dataset, Nothing happened'
          widget_control, event.top, set_uval = state
        Endelse
      Endif
    End
  Endcase

Return
End
Pro thm_ui_userdef

  master = widget_base(/row, title = 'THEMIS User-Defined Operator')

  label = 'Input string for algeraic operation, with the data to be input represented by a ''qq'''

  funcbase = widget_base(master, /col, /align_left, frame = 5)
  funcdisplay = widget_text(funcbase, uval = 'FUNC', val = '', /all_events, $
                            /editable, xsize = 80, ysize = 12, $
                            frame = 5)
  flabel = widget_label(funcbase, val = label)
;a widget for buttons
  buttons = widget_base(master, /col, /align_center, frame = 5)

; go button
  go_button = widget_base(buttons, /col, /align_center)
  gobut = widget_button(go_button, val = ' GO ', uval = 'GO', $
                        /align_center, scr_xsize = 120)
; save button
  save_button = widget_base(buttons, /col, /align_center)
  savebut = widget_button(go_button, val = 'SAVE ', uval = 'SAVE', $
                        /align_center, scr_xsize = 120)
; exit button
  exit_button = widget_base(buttons, /col, /align_center)
  exitbut = widget_button(exit_button, val = ' Close ', uval = 'EXIT', $
                        /align_center, scr_xsize = 120)
  state = {master:master, funcdisplay:funcdisplay, $
           func_text:ptr_new('')}
  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  xmanager, 'thm_ui_userdef', master, /no_block
  Return
End

