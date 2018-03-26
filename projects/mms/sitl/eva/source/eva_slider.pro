;+
; NAME:
;   EVA_SLIDER
;
; PURPOSE:
;   A compound slider widget for editing time values.
;   Consists of a text field for display and direct editing of the time value and 
;   a slider for rapid editing of the time value.
;
; CALLING SEQUENCE:
;   Result = EVA_SLIDER(parent)
;
; KEYWORD PARAMETERS:
;    VALUE: Initial time value (double)
;    MAX_VALUE: The maximum allowed time-value for the slider
;    MIN_VALUE: The minimum allowed time-value for the slider
;    LABEL: String to be used as the widget's label
;    
; EVENT STRUCTURE:
;   When the field is modified either directly or by the slider,
;   the following event is returned:
;   {ID: id, TOP: top, HANDLER: handler, VALUE: value}
;   Value is the modified time-value (double)
;   
; $LastChangedBy: moka $
; $LastChangedDate: 2018-03-25 06:58:22 -0700 (Sun, 25 Mar 2018) $
; $LastChangedRevision: 24950 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/eva_slider.pro $
;
PRO eva_slider_set_value, id, value 
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  ;field
  str_value = (keyword_set(state.time)) ? time_string(value) : strtrim(string(value),2)
  widget_control, state.field, SET_VALUE=str_value
  ;slider
  this_value = (keyword_set(state.time)) ? str2time(value) : double(value)
  return_value = (this_value < state.max_value) > state.min_value
  vnew = long(100*(return_value-state.min_value)/(state.max_value-state.min_value))
  widget_control, state.slider, SET_VALUE=vnew
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
END

FUNCTION eva_slider_time_validate, s
  compile_opt idl2
  
  ;---------
  ; length
  ;---------
  len = strlen(s)
  msg = ''
  if (len lt 8) then msg += 'Too short;'
  if (len gt 26) then msg += ' Too long;'
  
  ;----------------------------------
  ; first character must be a number
  ;----------------------------------
  c = strmid(s,0,1)
  if is_numeric(c) eq 0 then msg += ' Not starting from a number;'
  
  ;---------------------
  ; Must contain a colon
  ;---------------------
  if strpos(s,':') lt 0 then msg += ' Not containing a colon;'
  
  return, msg
END

FUNCTION eva_slider_event, ev
  compile_opt idl2

  parent=ev.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  if n_tags(state) eq 0 then return, { ID:ev.handler, TOP:ev.top, HANDLER:0L }

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    RETURN, { ID:parent, TOP:ev.top, HANDLER:ev.handler, VALUE:''}
  endif

  return_value = 0.d0
  
  case ev.id of
    state.slider: begin; ID, TOP, HANDLER, VALUE, DRAG
      return_value = (0.01d0*double(ev.value))*state.DIF_VALUE + state.MIN_VALUE
;      if state.LIMIT then begin
;        time = timerange(/current)
;        return_value = (return_value < time[1]) > time[0]
;      endif
      if(n_elements(state.WGRID) gt 1)then begin
        result = min(double(state.WGRID)-return_value,idx, /absolute, /nan)
        return_value = state.WGRID[idx]
      endif
      str_value = (keyword_set(state.time)) ? time_string(return_value) : strtrim(string(return_value),2)
      widget_control, state.field, SET_VALUE=str_value
      end;state.slider
    state.field: begin
      if keyword_set(state.time) then begin
        strv = ev.value[0]
        err_msg = eva_slider_time_validate(strv)
      endif else begin
        err_msg = ''
      endelse
      if strlen(err_msg) eq 0 then begin
        this_value = (keyword_set(state.time)) ? time_double(ev.value) : double(ev.value)
        return_value = (this_value < state.max_value) > state.min_value
        vnew = long(100*(return_value-state.min_value)/(state.max_value-state.min_value))
        widget_control, state.slider, SET_VALUE=vnew
      endif
      end;state.field
    else:
  endcase

  ; valid = is_numeric(string(numValue))
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
  RETURN, { ID:parent, TOP:ev.top, HANDLER:ev.handler, VALUE:return_value}
END

FUNCTION eva_slider, parent, WGRID=wgrid, TIME=time,$
  VALUE=value, MIN_VALUE=min_value, MAX_VALUE=max_value,$; limit=limit, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,SENSITIVE=sensitive

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for CW_sitl'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'eva_slider'
  if not (keyword_set(title)) then title=' '
  if n_elements(value) eq 0 then value=0 
  if n_elements(min_value) eq 0 then min_value = 0
  if n_elements(max_value) eq 0 then max_value = 0
  if n_elements(wgrid) eq 0 then wgrid = [0]
  if keyword_set(time) eq 0 then time = 0
  min_value = double(min_value)
  max_value = double(max_value)
  value = double(value)
  
  state = {$
    TIME: time, $
    VALUE: value,$
    DIF_VALUE: max_value-min_value,$
    MIN_VALUE: min_value, $
    MAX_VALUE: max_value,$
;    LIMIT: limit, $
    WGRID: wgrid}
  
  ;-------------
  ; BASE 
  ;-------------
  base = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "eva_slider_event", $
    FUNC_GET_VALUE = "eva_slider_get_value", $
    PRO_SET_VALUE = "eva_slider_set_value",/row,$
    SENSITIVE=sensitive, SPACE=0, YPAD=0,/base_align_center)
  str_element,/add,state,'base',base

  ;-------------
  ; FIELD
  ;-------------
  str_value = (keyword_set(time)) ? time_string(value) : strtrim(string(value),2) 
  str_element,/add,state,'field',cw_field(base,VALUE=str_value,TITLE=title,$
    /ALL_EVENTS,XSIZE=19)

  ;-------------
  ; SLIDER
  ;-------------
  v = (value < max_value) > min_value
  vnew = long(100*(v-min_value)/(max_value-min_value))
;  print,'*******'
;  print, value
;  print, min_value
;  print, max_value
;  print, v
;  print, vnew
;  print, '*****'
  if (0 le vnew) and (vnew le 100) then begin
    str_element,/add,state,'slider',widget_slider(base,DRAG=1,MAX=100,MIN=0,VALUE=vnew,$
      /sup,SENSITIVE=sensitive)
  endif

  ; Save out the initial state structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(base, /CHILD), SET_UVALUE=state, /NO_COPY

  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, base
END
