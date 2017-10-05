;+ 
;NAME:
; Thm_ui_dproc_reset_act_data
;PURPOSE:
; helper function to reset the active data window in dproc panel
;CALLING SEQUENCE:
; spd_ui_dproc_reset_act_data, dproc_id
;INPUT:
; dproc_id = the widget_id for the dproc panel, or the state structure
;OUTPUT:
; None explicit, the active data widget is updated
;HISTORY:
; 15-jan-2009, jmm, jimm@ssl.berkeley.edu
; 23-jan-2009, jmm, uses the dproc_id to update so that part_getspec
;                   options can update active data window correctly
; 1-apr-2009, jmm, Added update_tree keyword
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_dproc_reset_act_data.pro $
;-

Pro spd_ui_dproc_reset_act_data, dproc_id, update_tree = update_tree

  If(is_struct(dproc_id)) Then Begin
      state = dproc_id          ;i've passed in the state structure
  Endif Else Begin
      widget_control, dproc_id, get_uval = state, /no_copy ;i've passed in the widget id
  Endelse

  If(is_struct(state) Eq 0) Then Begin
    message, 'Undefined state structure'
  Endif

  dobj = state.info.loadeddata
;Now get the loaded data, active data, and set up strings
  val_data = ''
  act_data = ''
  val_data_temp = 'No Data Loaded'
  act_data_temp = 'No Active Data'
  If(obj_valid(dobj)) Then Begin
    val_data = dobj -> getall(/parent)
    act_data = dobj -> getactive(/parent)
;create names with times in single strings for display
    If(is_string(val_data)) Then Begin 
      val_data_temp = dobj -> getall(/parent, /times)
      val_data_temp = reform(val_data_temp[0, *]+':    '+$
        val_data_temp[1, *]+' to '+val_data_temp[2, *])
      If(is_string(act_data)) Then Begin
        isactive = sswhere_arr(val_data, act_data)
        If(isactive[0] Ne -1) Then act_data_temp = val_data_temp[isactive]
      Endif
    Endif
  Endif Else Begin
    dprint, 'Invalid Data Object'
    state.statusbar -> update, 'Invalid Data Object'
  Endelse
;Fill the pointers
  If(ptr_valid(state.val_data)) Then ptr_free, state.val_data
  If(is_string(val_data)) Then Begin
    state.val_data = ptr_new(val_data)
  Endif Else state.val_data = ptr_new()
  If(ptr_valid(state.val_data_t)) Then ptr_free, state.val_data_t
  state.val_data_t = ptr_new(val_data_temp)
;Active data pointers    
  If(ptr_valid(state.act_data)) Then ptr_free, state.act_data
  If(is_string(act_data)) Then Begin
    state.act_data = ptr_new(act_data)
  Endif Else state.act_data = ptr_new()
  If(ptr_valid(state.act_data_t)) Then ptr_free, state.act_data_t
  state.act_data_t = ptr_new(act_data_temp)

;Update list widgets if they exist
  If(widget_valid(state.activelist)) Then $
    widget_control, state.activelist, set_value = *state.act_data_t

;Update tree object, if asked to
  If(keyword_set(update_tree)) Then Begin
    If(obj_valid(state.treeobj)) Then state.treeobj -> update
  Endif

  If(is_struct(dproc_id) Eq 0) Then Begin ;reset in widget
      widget_control, dproc_id, set_uval = state, /no_copy
  Endif Else Begin
      dproc_id = temporary(state) ;be sure that changes are made
  Endelse

  Return
End
