;+ 
;NAME:
; thm_ui_npar
;PURPOSE:
; Simple widget that allows user to change n parameter values and units (if units were
; specified)
;CALLING SEQUENCE:
; new_value = thm_ui_npar(name, init_value, [radio_array=radio_array], $
;                         [radio_value=radio_value])
;INPUT:
; name = the name of the parameter, can be an array
; init_value = the initial value of the parameter, e.g., '1.0', must
;              be a string array of the smae size as name
; radio_array = optional string array containing radio button names
; title=title = optional title for the panel
; radio_value = optional string containing the radio button to set initially
;OUTPUT:
; new_value = the output value of the parameters, a string array of values,
;             e.g., ['4.67', '3.0', ...n]
;             if optional radio buttons were used the last element of  the array
;             will contain the radio button selection,
;             e.g., ['4.67', '3.0', ..., 'inches']
;METHODS:
; thm_ui_npar0 - creates the window, widgets, and calls the xmanager
; thm_ui_npar0_event - event handler for the window (handles parameter input, cancel/
;                      accept buttons, and window close 'X'
; thm_ui_rad_event - event handler for the radio buttons; thm_ui_npar0 - creates the window, widgets, and calls the xmanager
;HISTORY:
; 5-feb-2007, jmm, jimm@ssl.berkeley.edu
; 25-OCt-2007, jmm, added KILL_REQUEST block
; 15-may-2008, cg, added optional title for widget
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2012-01-26 16:47:04 -0800 (Thu, 26 Jan 2012) $
;$LastChangedRevision: 9627 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_npar.pro $
;
;-

Pro thm_ui_npar0_event, event
  common thm_ui_npar0_private, value_sav

;If the 'X' is hit...
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
    value_sav = 'Cancelled'
    widget_control, event.top, /destroy
    Return
  Endif
  widget_control, event.id, get_uval = uval
  If(uval Eq 'YES') Then Begin
    widget_control, event.top, /destroy
  Endif Else If(uval Eq 'NO') Then Begin
    value_sav = 'Cancelled'
    widget_control, event.top, /destroy
  Endif Else Begin
    j = fix(strmid(uval, 4))
    widget_control, event.id, get_val = temp_string
    value_sav[j] = temp_string
  Endelse
Return
End

Pro thm_ui_rad_event, event
  common thm_ui_npar0_private, value_sav

  ; retrieve the radio button selection and save it
  widget_control, event.id, get_value = value
  value_sz = size(value_sav, /dimensions)
  value_sav(value_sz-1) = value

Return
End

Pro thm_ui_npar0, name, init_value, radio_array=radio_array, radio_value=radio_value,$
                  title=title

  if strlen(title) gt 1 then $
     master = widget_base(/col, title = title, /tlb_kill_request_events)$
     else master = widget_base(/col, title = 'Input Values', /tlb_kill_request_events)

  n = n_elements(name)
  listw = intarr(n)
  For j = 0, n-1 Do Begin
    uvalj = 'LIST'+strcompress(/remove_all, j)
    ;listid = widget_base(master, /row, /align_center, /frame)
    listid = widget_base(master, /row, /align_center)
    if name[j] ne '' then flabel = widget_label(listid, value = name[j])
    if init_value[j] ne '' then   listw[j] = widget_text(listid, $
                      value = init_value[j], $
                      xsiz = max(strlen(init_value[j]))+20, $
                      ysiz = 1, uval = uvalj, $
                      /editable, /all_events)

  Endfor

  ;if the radio button option was used...
  if keyword_set(radio_array) then Begin
    units_base = widget_base(master, /exclusive, /row, /align_center)
    radio_button = indgen(n_elements(radio_array))
    for i=0, n_elements(radio_array)-1 do Begin
      radio_button[i] = widget_button(units_base, val = radio_array[i], $
                                      event_pro='thm_ui_rad_event')
    endfor
    loc = where(radio_array Eq radio_value)
    widget_control, radio_button(loc), /set_button
  endif

  no_button = widget_button(master, val = 'Cancel', $
                            uval = 'NO', /align_center)
  yes_button = widget_button(master, val = 'Accept and Close', $
                             uval = 'YES', /align_center)

  CenterTlb, master
  widget_control, master, /no_copy
  widget_control, master, /realize
  xmanager, 'thm_ui_npar0', master

  Return
End

Function thm_ui_npar, name, init_value, radio_array=radio_array, radio_value=radio_value, $
                      title=title
  common thm_ui_npar0_private, value_sav

  n = n_elements(name)
  If(n_elements(init_value) Ne n) Then Begin
    dprint, 'Mismatched input'
    Return, ''
  Endif
  value_sav = init_value
  
  if not keyword_set(title) then title=' '

  If keyword_set(radio_array) Then Begin
    value_sav = [[init_value], radio_value]
    thm_ui_npar0, name, init_value, radio_array=radio_array, radio_value=radio_value, $
                  title=title
  endif Else Begin
    thm_ui_npar0, name, init_value, title=title
  endelse
  
  Return, value_sav
End
