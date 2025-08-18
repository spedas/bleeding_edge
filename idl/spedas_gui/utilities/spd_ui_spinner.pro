;+
; NAME:
;   SPD_UI_SPINNER
;
; PURPOSE:
;   A compound 'spinner' widget for editing numerical values.
;   Consists of up and down buttons and a text field for display
;   and direct editing.
;
; CALLING SEQUENCE:
;   Result = SPINNER(parent)
;
; KEYWORD PARAMETERS:
;    VALUE: Initial value (float/double)
;    INCREMENT: Numerical ammount spinner value is incremented/decremented
;    LABEL: String to be used as the widget's label
;    UNITS: String containing the units to appear to the right of the value
;    SPIN_TIME: Delay before 'spinning' when clicking up/down buttons
;    XLABELSIZE: Size of the text label in points
;    getXLabelSize: Set to a named variable to pass back the length of the
;                   spinner's label in points
;    TEXT_BOX_SIZE: Size of the text box in # of characters
;    TOOLTIP: String to be used at the buttons' tooltip
;    MAX_VALUE: The maximum allowed value for the spinner (optional)
;    MIN_VALUE: The minimum allowed value for the spinner (optional)
;
; EVENT STRUCTURE:
;   When the field is modified (either directly) or by the
;   up/down buttons, the following event is returned:
;       {ID: id, TOP: top, HANDLER: handler, VALUE: value, VALID: valid}
;
;   VALUE: formatted, double precision number from widget's text field;
;          value is NaN when the text widget contains an unrecognizable
;          or unconvertable number
;   VALID: 0 if value is not a recogizable/convertable number, or if buttons
;         attempt to go outside min/max range, 1 otherwise
;
;
; GETTING/SETTINGS VALUES
;   Using get_value from widget_control will return the same as the VALUE
;    field in the event structure.
;   The set_value procedure expects numerical input (e.g. doubles, floats, ints).
;   Use spd_ui_spinner_set_max_value/spd_ui_spinner_set_min_value to change max_value, min_value.
;   spd_ui_spinner_get_max_value/spd_ui_spinner_get_min_value return MAX_VALUE, MIN_VALUE
;
; NOTES:
; (lphilpott 06/10/11)
; Setting the max_value and min_value will restrict the use of the up and down buttons
; to reach values outside that range.
; They do not impact on values that are typed into the text field (these
; should be handled by the calling function) or any values simply passed to the set_value procedure.
; (lphilpott 06/15/11)
; Use of VALID: VALID=0 if the event is not valid. This includes non-recognizable
; numbers but ALSO cases where the user tries to go outside the allowed min-max range using up and down buttons.
; If the user clicks the up/down button and reaches the limit, the value returned is the limit value and valid=0.
; If the user enters a non numerical value the value returned is NAN and valid=0
; This allows the calling procedure to issue messages to the user such as invalid entry based on both VALUE and VALID.
; Note: valid = 0 only if the starting value of the spinner is at the bounds. If the user holds down the buttons and reaches
; the bounds valid = 1. This avoids problems where existing code processes events only if event.valid = 1.
;
; I have not used max and min to restrict values typed into the field due to the difficulty of knowing when the user
; has finished typing - do not want to reset the value while the user is still entering it.
;
; When using a spinner cases where the user types in a value outside the allowed range need to be handled, also
; invalid entries. If necessary warning messages should be issued to user when they use the up/down buttons and have
; reached the allowed limits.
;
;
; Added get and set procedures for min and max designed to be called externally, eg. spd_ui_spinner_set_max_value
; Idea is to allow max and min to be set in case they need to be changed after spinner is created (e.g for range spinners where allowed values
; depend on whether scaling is linear or log)
;
;HISTORY:
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL: $
;---------------------------------------------------------------------------------


FUNCTION spd_ui_spinner_button_event, event, down_click=down

  compile_opt idl2, hidden
  
  ; Save current select state to later see if the mouse is released.
  widget_control, event.id, SET_UVALUE=event.select
  
  
  IF (event.select eq 0) then begin
    widget_control, event.id, /CLEAR_EVENTS
    RETURN, 0
  ENDIF
  
  
  ; The widget Base and Text Field widget IDs.
  base = widget_info(widget_info(event.id, /PARENT), /PARENT)
  text = widget_info(base, FIND_BY_UNAME='_text')
  handler = base
  
  ; Find parent's event handler.
  WHILE (widget_info(handler, /VALID)) do begin
    par_event_func = widget_info(handler, /EVENT_FUNC)
    par_event_pro = widget_info(handler, /EVENT_PRO)
    
    IF (par_event_func || par_event_pro) then BREAK
    
    handler = widget_info(handler, /PARENT)
  ENDWHILE
  
  
  ; Iterations before starting spin; allows for slow press w/o activating spinner.
  delay = 10
  result = 0
  widget_control, text, GET_UVALUE=state
  i = keyword_set(down) ? -1L : 1L
  
  prevvel = double(state.value)
  
  ; To stop if the mouse is released.
  WHILE (1) do begin
    ;widget_control, text, GET_VALUE=old
    old = double(state.value)
    oldint = old*(1d/state.increment)
    time = systime(1)
    
    
    ;    ; If rounded to nearest fraction, then increment; otherwise, round off.
    ;    ; Avoid roundoff errors by testing against a tiny #.
    ;    IF ( abs(oldint - round(oldint,/L64)) lt 1d-7 ) then $
    ;      new = old + i*state.increment $ ; + 1d-9*i ;tiny number needed?
    ;    ELSE new = (keyword_set(down) ? floor(oldint,/L64) : ceil(oldint,/L64) )*state.increment
    
    
    ;try simple increment instead of rounding
    ;rounding errors *should* be solved by the use of formatannotation
    new = old + i * state.increment
    
    
    ; check whether new is within the min max range
    ;only set valid = 0 if user hits up/down button when value is already min/max (not when user holds down button from other value)
    tmpvalid = 1
    if finite(state.minValue) then begin
      if new lt state.minValue then begin
        new = state.minValue
        if prevvel eq state.minValue then tmpvalid = 0
      endif
    endif
    if finite(state.maxValue) && tmpvalid then begin
      if new gt state.maxValue then begin
        new = state.maxValue
        if prevvel eq state.maxValue then tmpvalid = 0
      endif
    endif
    ; Update the text widget.
    new = spd_ui_spinner_num_to_string(new, state.units,state.precision)
    state.value = new
    widget_control, text, SET_VALUE=new, SET_UVALUE=state
    
    ; Create and feed a new event into any parent's event handler.
    IF (par_event_func || par_event_pro) then begin
;      new_event = {ID: base, TOP: event.top, HANDLER: handler, VALUE: double(new), VALID: tmpvalid}
      new_event = {ID: base, TOP: event.top, HANDLER: handler, VALUE: new, VALID: tmpvalid}
    ;      if (par_event_func) $
    ;        then result = call_function(par_event_func, new_event) $
    ;        else call_procedure, par_event_pro, new_event
    ENDIF
    
    ; Delay start of spin
    ; ### loop ###
    repeat begin
    
      ; Check for new event (mouse - unclick)
      newevent = widget_event(event.top, BAD_ID=bad, /NOWAIT)
      
      ; Quit if bad ID occurs.
      IF (bad ne 0L) then RETURN, 0
      
      widget_control, event.id, GET_UVALUE = x
      
      ; End if mouse was released and
      ; send to parent function/procedure
      IF (x eq 0) then begin
        if (par_event_func) then begin
          return, call_function(par_event_func, new_event)
        endif else if (par_event_pro) then begin
          call_procedure, par_event_pro, new_event
        endif
        return,0
      ENDIF
      
      ; Delay before starting spin.
      IF (delay ne 0) then begin
        WAIT, 0.05d
        delay--
      ENDIF
      
    endrep until delay eq 0
    
    elapsed = systime(1) - time
    
    IF (elapsed lt state.spinTime) then wait, state.spinTime - elapsed
    
  ENDWHILE
  
END ;---------------------------------------------------------------------



FUNCTION spd_ui_spinner_update_event, event

  compile_opt idl2, hidden
  on_ioerror, null
  
  ; Pull new values and save old for reset
  widget_control, event.id, GET_VALUE=new, GET_UVALUE=state
  
  ; For testing/debugging only
  ;if new[0] eq (state.value+state.units) then return,0
  ;if new[0] eq '-*' then return,0

  ;If there are units on the value, then remove them
  if stregex(new,'.*' + state.units + '.*$',/boolean) then begin
    new = (stregex(new,' *(.*)'+state.units + '.*$',/extract,/subexpr))[1]
  endif

  ;carriage return - enter was pressed, we should ensure the value is updated
  if  Tag_Names(event,/Structure_Name) eq 'WIDGET_TEXT_CH' && event.ch eq 10 then begin
    if is_numeric(new,/sci) then begin
        ; if we have a valid number, use calc to evaluate the expression
        a='value='
        b=new
        calc, a+b
        widget_control, event.id, set_value=strtrim(string(value),2)+state.units
        state.value = value
        widget_control, event.id, set_uvalue=state
        
        parent = widget_info(event.id, /PARENT)
        RETURN, {ID: parent, TOP: event.top, HANDLER: event.handler, VALUE: double(value), VALID:is_numeric(value,/sci)}
    endif
  endif

 
  offset = widget_info(event.id, /text_select)
  widget_control,event.id,set_value=new+state.units,set_text_select=offset
  
  parent = widget_info(event.id, /PARENT)
  
  if is_numeric(new,/sci) then begin  ;if the input is a correctly formatted numerical value then store it, and generate an event
    state.value = new
    widget_control,event.id,set_uvalue=state
    on_ioerror, fail
    RETURN, {ID: parent, TOP: event.top, HANDLER: event.handler, VALUE: double(new), VALID: 1}
    fail: RETURN, {ID: parent, TOP: event.top, HANDLER: event.handler, VALUE: !values.D_NAN, VALID: 0}
  endif else begin
    return, {ID: parent, TOP: event.top, HANDLER: event.handler, VALUE: !values.D_NAN, VALID: 0}
  endelse
  
  
END ;---------------------------------------------------------------------



FUNCTION spd_ui_spinner_up_click, event

  compile_opt idl2, hidden
  RETURN, spd_ui_spinner_button_event(event)
  
END ;---------------------------------------------------------------------



FUNCTION spd_ui_spinner_down_click, event

  compile_opt idl2, hidden
  RETURN, spd_ui_spinner_button_event(event, /down_click)
  
END ;---------------------------------------------------------------------



FUNCTION spd_ui_spinner_getvalue, base

  compile_opt idl2, hidden
  
  widget_control, widget_info(base, FIND_BY_UNAME='_text'), GET_VALUE=value,get_uvalue=state
  
  value = value[0]
  ;If there are units on the value, then remove them
  if stregex(value,'.*' + state.units + '.*$',/boolean) then begin
    value = (stregex(value,' *(.*)'+state.units + '.*$',/extract,/subexpr))[1]
  endif

  if is_numeric(value[0],/sci) then begin
    ; if we have a valid number, use calc to evaluate the expression
     a='cexp='
     b=string(value[0])
     ; if the value is in decimal notation, append D0 to force calc to treat it as a double
     if is_numeric(value[0], /decimal) then calc, a+b+'D0' else calc, a+b
  endif else cexp = ''

  ;Return NaN if value isn't numeric or double() conversion fails
  if is_numeric(string(cexp),/sci) then begin
    on_ioerror, fail
    return, double(cexp)
    fail: return, !values.D_NAN
  endif else begin
    return,!values.D_NAN
  endelse
  
END ;---------------------------------------------------------------------



PRO spd_ui_spinner_setvalue, base, value

  compile_opt idl2, hidden
  
  ; Set text widget value
  text = widget_info(base, FIND_BY_UNAME='_text')
  offset = widget_info(text, /text_select)
  
  ;widget_control, text, SET_VALUE=string(value), SET_TEXT_SELECT = offset

  widget_control,text,get_uvalue=state
  state.value = spd_ui_spinner_num_to_string(value,state.units,state.precision)
  widget_control, text, SET_VALUE=state.value,set_text_select=offset
  
  ;Update spinner value with event handler
  set = spd_ui_spinner_update_event( {ID: text, TOP: base, HANDLER: text} )
  
END ;---------------------------------------------------------------------



FUNCTION spd_ui_spinner_num_to_string, num_in, units_in,precision

  compile_opt idl2, hidden

  data = {timeaxis:0,$
    formatid:precision,$ ;default 10
    scaling:0,$
    exponent:0,$
    noformatcodes:1}
  ;exponent:1} ;changing to autoformat

  ; RETURN, string(num_in,FORMAT='(G0)')+  units_in
  RETURN, formatannotation(0,0,num_in,data=data) +  units_in
  
END ;---------------------------------------------------------------------

PRO spd_ui_spinner_remove_spaces, string_in

  compile_opt idl2, hidden
  
  if ~strmatch(string_in, '*[! ]*') then return
  while strmatch(string_in, '*[ ]*') do begin
    bst = byte(string_in)
    space = byte(' ')
    bst = bst[where(bst ne space[0],count)]
    string_in = string(bst)
  endwhile
  
END ;---------------------------------------------------------------------


pro spd_ui_spinner_set_max_value, base, maxvalue
  text = widget_info(base, FIND_BY_UNAME='_text')
  widget_control,text,get_uvalue=state
  state.maxValue = maxvalue
  widget_control, text, set_uvalue=state
end

pro spd_ui_spinner_set_min_value, base, minvalue
  text = widget_info(base, FIND_BY_UNAME='_text')
  widget_control,text,get_uvalue=state
  state.minValue = minvalue
  widget_control, text, set_uvalue=state
end

pro spd_ui_spinner_get_max_value, base, maxvalue
  text = widget_info(base, FIND_BY_UNAME='_text')
  widget_control,text,get_uvalue=state
  maxvalue = state.maxValue
end

pro spd_ui_spinner_get_min_value, base, minvalue
  text = widget_info(base, FIND_BY_UNAME='_text')
  widget_control,text,get_uvalue=state
  minvalue = state.minValue
end




FUNCTION spd_ui_spinner, parent,          $
    INCREMENT=inc_set,                    $
    LABEL=label_set,                      $
    SPIN_TIME=spin_time_set,              $
    UNITS=unit_set,                       $
    VALUE=value_set,                      $
    XLABELSIZE=label_size_set,            $
    TEXT_BOX_SIZE=text_box_size,          $
    getXLabelSize=size_out_var,           $
    DISABLE_ALL_EVENTS=disable_all_events,$
    TOOLTIP=tooltip,                      $
    precision=precision,                  $
    MAX_VALUE=max_value_set,              $
    MIN_VALUE=min_value_set,              $
    _EXTRA=_extra
    
    
  compile_opt idl2, hidden
  
  
  if ~keyword_set(precision) then begin
    ; lphilpott 6-mar-2012 reducing default precision as 16 seems like more precision than is possible
    ;precision = 16
    precision = 13
  endif
  
  ; Initiations & checks
  increment = n_elements(inc_set) ? double(inc_set[0]) : 0.1d
  spinTime = keyword_set(spin_time_set) ? (double(spin_time_set) > 0d) : 0.05d
  units = keyword_set(unit_set) ? unit_set : ''
  valuenum = keyword_set(value_set) ? value_set : 0
  value =  spd_ui_spinner_num_to_string(valuenum, units,precision)
  tboxsize = keyword_set(text_box_size) ? text_box_size : 8
  ; if value has been given ensure max and min are moved to allow it
  if n_elements(max_value_set) then begin
    maxvalue = keyword_set(value_set) ? (double(max_value_set) > valuenum) : double(max_value_set)
  endif else maxValue = !values.d_nan
  if n_elements(min_value_set) then begin
    minvalue = keyword_set(value_set) ? (double(min_value_set) < valuenum) : double(min_value_set)
  endif else minValue = !values.d_nan
  state = {VALUE: value, INCREMENT: increment, SPINTIME: spinTime, UNITS: units,$
    precision:precision, MAXVALUE: maxValue, MINVALUE: minValue}
    
    
  ; General base for each part of the compound widget
  base = widget_base(parent, /ROW,            $
    FUNC_GET_VALUE='spd_ui_spinner_getvalue',        $
    PRO_SET_VALUE='spd_ui_spinner_setvalue',         $
    XPAD=0, YPAD=0, SPACE=1, _EXTRA=_extra)
    
   
  ; Label
  label = (keyword_set(label_set)) ? $
    widget_label(base, VALUE=label_set, XSIZE=label_size_set) : ''
    
  if arg_present(size_out_var) then begin
    geo_info = widget_info(label,/geometry)
    size_out_var = geo_info.scr_xsize
  endif
  
  
  ; Text
  ; Note: To fix the issue with zoom redrawing after every keystroke, we pass
  ; the 'disable_all_events' keyword when creating the zoom spinner widget
  if undefined(disable_all_events) then begin
      text = widget_text(base, /editable, /all_events,              $
        EVENT_FUNC='spd_ui_spinner_update_event',                         $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'],    $
        VALUE=value, UNAME='_text', UVALUE=state, XSIZE=tboxsize)
  endif else begin
      text = widget_text(base, /editable,               $
        EVENT_FUNC='spd_ui_spinner_update_event',                         $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'],    $
        VALUE=value, UNAME='_text', UVALUE=state, XSIZE=tboxsize)
  endelse
    
    
  ;Buttons
  button_base = widget_base(base, /ALIGN_CENTER, /COLUMN, /TOOLBAR, XPAD=0, YPAD=0, SPACE=0)
  
  ; Extra pixel added to button padding for Windows
  one = !version.os_family ne 'Windows'
  
  ; 'Up' Button
  up_button = widget_button(button_base, EVENT_FUNC='spd_ui_spinner_up_click',    $
    /BITMAP, VALUE= filepath('spinup.bmp', SUBDIR=['resource','bitmaps']), $
    /PUSHBUTTON_EVENTS, UNAME='_up',UVALUE=0, XSIZE=16+one, YSIZE=10+one, $
    tooltip=tooltip)
    
  ; 'Down' Button
  down_button = widget_button(button_base, EVENT_FUNC='spd_ui_spinner_down_click', $
    /BITMAP, VALUE=filepath('spindown.bmp', SUBDIR=['resource','bitmaps']), $
    /PUSHBUTTON_EVENTS, UNAME='_down', UVALUE=0, XSIZE=16+one, YSIZE=10+one, $
    tooltip=tooltip)
    
    
  RETURN, base
  
END


