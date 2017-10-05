;+ 
;NAME:
; spd_ui_time_widget.pro
;
;PURPOSE:
; Compound widget used to generate standardized time selection ui,
;  for all tabs in the load data window.
;
;CALLING SEQUENCE:
; widgetid = spd_ui_time_widget(parent,statusBar,historyWin,timeRangeObj=timeRangeObj,uvalue=uvalue,uname=uname, oneday=oneday)
;
;INPUT:
; parent: ID of base in which compound widget will sit
; statusBar: statusBar Object for reporting errors and user info
; historywin: historywin object for reporting errors and user info
; timeRangeObj: a spd_ui_time_range storing the range that will be used.
;               If provided, the compound widget will mutate this object
; uvalue:  Assign a user value to this widget
; uname: assign a user name to this widget
; oneday: flag to determine whether the range is fixed to one day
; startyear: optional keyword to change the start year for the calendar widget
;            default start year is 2000
;
;OUTPUT:
; This widget's id
; 
;NOTES:
;1. Returns events of the form:
;      return_struct = {time_widget,id:0l,top:0l,handler:0l,timerange:obj_new(),error:0}
;
;2. Can use get_value and set_value keywords with widget control, to return the time range object
;  that this compound widget mutates.
;
;HISTORY:
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
; $LastChangedRevision: 14326 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_time_widget.pro $
;-

function spd_ui_time_widget_event,event

  Compile_Opt idl2, hidden
  
  err = 0
  catch,err
  if err ne 0 then begin
    catch,/cancel
    ok = error_message('There has been an unexpected error in the time widget',title='time widget error', /center,traceback = 1)
    Help, /Last_Message, Output = err_msg
    if is_struct(state) then begin
      FOR j = 0, N_Elements(err_msg)-1 DO state.historywin->update,err_msg[j]
      return_struct = {time_widget,id:state.base,top:event.top,handler:0l,timerange:state.timeRangeObj,error:1}
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      return,return_struct
    endif else begin
      return,{time_widget,id:0l,top:event.top,handler:0l,timerange:obj_new(),error:1}
    endelse
  endif
  
  base = event.handler
  stash = widget_info(base,/child)
  widget_control, stash, Get_UValue=state, /no_copy
  
  widget_control, event.id, get_uvalue = uval 
  case uval of
    'ONEDAY': BEGIN
      state.oneday = event.select
      id = widget_info(state.base, find_by_uname='stopbase')
      widget_control, id, sensitive=(~event.select)
      if event.select then begin
        state.timerangeobj->GetProperty, startTime=st ;st is starttime object (spd_ui_time__define)
        state.timerangeobj->GetProperty, endTime=et   ;et is endtime object
        st->getproperty, tdouble=t0
        et->setproperty, tdouble=t0 + 86400d  
        et->getproperty, tstring=t1s
        widget_control,state.stoptext, set_value =t1s
        
        ;also check validity of starttime (if start isn't valid it won't necc be the same as st above)
        ;need this incase the stop time was previously invalid
        startid = widget_info(state.base,find_by_uname='start_time')
        widget_control,startid,get_value=startvalue
        tstart = spd_ui_timefix(startvalue)
        if is_string(tstart) then state.valid=1b ; end time should be valid since we set it ourselves
      endif
    END
    'START_TIME':BEGIN ; Start Time entry box
      widget_control,event.id,get_value=value
      t0 = spd_ui_timefix(value)
      state.valid = 0b ;will only be reset to 1 if new time is valid
      If(is_string(t0)) Then Begin
          ;get both times for limit checking
          state.timerangeobj->GetProperty, startTime=st ;st is starttime object (spd_ui_time__define)
          state.timerangeobj->GetProperty, endTime=et   ;et is endtime object
          ;set start time value
          st->SetProperty, tstring = value
          
          ;set end time if loading single day
          st->getproperty, tdouble=t0
          if state.oneday then begin
            et->setproperty, tdouble = t0 + 86400d
            et->getproperty, tstring=t1s
            widget_control,state.stoptext, set_value =t1s
          endif
          
          ;return a warning if the time range is less than zero, or longer than 1 week
          et->getproperty, tdouble=t1
          If(t1 Le t0) Then state.statusBar->update, 'End time less than/equal to Start time.' $
          Else If((t1-t0) Gt 7.0*86400.0d0) Then begin
            state.valid=1b
            state.statusBar->update, 'Time range is longer than One Week.' 
          endif Else begin
            state.valid=1b
            state.statusBar->update, 'Valid Start Time Entered'
          endelse
      Endif Else state.statusBar->update, 'INVALID START TIME ENTERED.  Format: YYYY-MM-DD/hh:mm:ss'
    END
    'START_CAL':BEGIN;Calendar button
      widget_control, state.startText, get_value= val
      start=spd_ui_timefix(val)
      state.valid = 0b ;will only be reset to 1 if new time is valid

      state.timerangeobj->getproperty, starttime=start_obj
      state.timerangeobj->getproperty, endtime=end_obj
      spd_ui_calendar,'Choose Start Date/Time:',start_obj, state.base, startyear=state.startyear
      start_obj->getproperty, tdouble=t0
      
      if state.oneday then begin
        end_obj->setproperty, tdouble = t0 + 86400d
        end_obj->getproperty, tstring=t1s
        widget_control,state.stoptext, set_value =t1s
      endif
      
      end_obj->getproperty, tdouble=t1
      if t1 le t0 then state.statusBar->update, 'End time less than/equal to Start time.' $
        else if(t1-t0) gt 7.0*86400.0d0 then begin
          state.valid=1b
          state.statusBar->update, 'Time range is longer than One Week.'
        endif else begin
          state.valid=1b
          state.statusBar->update, 'Valid Start Time Entered'
        endelse
      start_obj->getproperty, tstring=start
      widget_control,state.starttext, set_value = start        
    END
    'STOP_TIME':BEGIN ; Stop Time entry box
      widget_control,event.id,get_value=value
      t0 = spd_ui_timefix(value)
      state.valid = 0b ;will only be reset to 1 if new time is valid

      If(is_string(t0)) Then Begin
          state.timerangeobj->GetProperty, startTime=st ;st is starttime object (spd_ui_time__define)
          state.timerangeobj->GetProperty, endTime=et ;et is endtime object (spd_ui_time__define)
      ;Set end time value
          et->SetProperty, tstring = value
      ;return a warning if the time range is less than zero, or longer than 1 week
          et->getproperty, tdouble=t1
          st->getproperty, tdouble=t0
          If(t1 Le t0) Then state.statusBar->update, 'End time less than/equal to Start time.' $
          Else If((t1-t0) Gt 7.0*86400.0d0) Then begin
            state.valid=1b
            state.statusBar->update, 'Time range is longer than One Week.'
          endif Else begin
            state.valid=1b
            state.statusBar->update, 'Valid End Time Entered'
          endelse
      Endif Else state.statusBar->update, 'INVALID END TIME ENTERED.  Format: YYYY-MM-DD/hh:mm:ss'
    END
    'STOP_CAL':BEGIN;Calendar button
      widget_control, state.stopText, get_value= val
      endt=spd_ui_timefix(val)
      state.valid = 0b ;will only be reset to 1 if new time is valid

      state.timerangeobj->getproperty, starttime=start_obj
      state.timerangeobj->getproperty, endtime=end_obj
      spd_ui_calendar,'Choose End Date/Time:',end_obj, state.base, startyear=state.startyear
      start_obj->getproperty, tdouble=t0
      end_obj->getproperty, tdouble=t1
      if t1 le t0 then state.statusBar->update, 'End time less than/equal to Start time.' $
        else if(t1-t0) gt 7.0*86400.0d0 then begin
          state.valid=1b
          state.statusBar->update, 'Time range is longer than One Week.'
        endif else begin
          state.valid=1b
          state.statusBar->update, 'Valid Start Time Entered'
        endelse
      end_obj->getproperty, tstring=endt
      widget_control,state.stoptext, set_value = endt     
    END
    ELSE:
  end
  
  return_struct = {time_widget,id:state.base,top:event.top,handler:0l,timerange:state.timeRangeObj,error:1}
  
  widget_control, stash, Set_UValue=state, /no_copy
  
  return,return_struct

end

;Will return internal 'one day' flag for given time widget
;
function spd_ui_time_widget_is_oneday, id

    compile_opt idl2, hidden
  
  stash = widget_info(id,/child)
  widget_control, stash, Get_UValue=state, /no_copy
  oneday = state.oneday
  widget_control, stash, Set_UValue=state, /no_copy
  return, oneday
  
end

;Will return validity of current dates when used 
;with widget_control. Must be manually set to be
;used as the get_value function.
function spd_ui_time_widget_is_valid,id

  Compile_Opt idl2, hidden
  
  stash = widget_info(id,/child)
  widget_control, stash, Get_UValue=state, /no_copy
  valid = state.valid
  widget_control, stash, Set_UValue=state, /no_copy
  return, valid
end

function spd_ui_time_widget_get_value,id

  Compile_Opt idl2, hidden
  
  stash = widget_info(id,/child)
  widget_control, stash, Get_UValue=state, /no_copy
  timeRangeObj = state.timeRangeObj
  widget_control, stash, Set_UValue=state, /no_copy
  return, timeRangeObj
end

pro spd_ui_time_widget_set_value,id,value

  Compile_Opt idl2, hidden
   stash = widget_info(id,/child)
   widget_control, stash, Get_UValue=state, /no_copy
   if obj_valid(value) then begin
     state.timeRangeObj=value
   endif
   widget_control, state.startText, $
     set_value=time_string(state.timerangeobj->getstarttime())
   widget_control, state.stopText, $
     set_value=time_string(state.timerangeobj->getendtime())
   widget_control, stash, Set_UValue=state, /no_copy
end

pro spd_ui_time_widget_update,baseid, oneday=oneday

  Compile_Opt idl2, hidden

  stash = widget_info(baseid,/child)
  
  widget_control,stash,get_uvalue=state, /no_copy
  
  state.timerangeobj->getproperty, starttime=start_obj
  state.timerangeobj->getproperty, endtime=end_obj
  
  start_obj->getproperty, tstring=t0
  end_obj->getproperty, tstring=t1
  
  widget_Control,state.startText,set_value=t0
  widget_control,state.stopText,set_value=t1
  
  if (time_double(t1)-time_double(t0) ne 86400) && state.oneday then begin
    state.oneday = 0
    endid = widget_info(state.base, find_by_uname='stopbase')
    widget_control, endid, sensitive=1
    widget_control, state.onedayID, set_button=0
  endif else begin
    ;Set Use One Day option
    ; assume, for now, that time range already = 86400 sec
    ; logic will have to be reworked if this is not the case
    if n_elements(oneday) eq 1 then begin ;cannot use keyword_set()
      state.oneday = oneday
      endid = widget_info(state.base, find_by_uname='stopbase')
      widget_control, endid, sensitive=~oneday
      widget_control, state.onedayID, set_button=oneday
    endif
  endelse
  
  widget_control, stash, SET_uvalue=state, /no_copy
end

function spd_ui_time_widget,$
                       parent,$
                       statusBar,$
                       historyWin,$
                       timeRangeObj=timeRangeObj,$
                       uvalue=uvalue,$
                       uname=uname, $
                       oneday=oneday, $
                       suppressoneday=suppressoneday, $
                       startyear=startyear

  Compile_Opt idl2, hidden
  
  base = widget_base(parent,$
                     event_func='spd_ui_time_widget_event',$
                     func_get_value='spd_ui_time_widget_get_value',$
                     pro_set_value='spd_ui_time_widget_set_value')
                     
  if keyword_set(uvalue) then begin
    widget_control,base,set_uvalue=uvalue
  endif
  
  if keyword_set(uname) then begin
    widget_control,base,set_uname=uname
  endif
  
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, parent, cal  
  
  starttime = '2007-03-23/00:00:00'
  stoptime = '2007-03-24/00:00:00'
  ; Start/Stop Time objects
  if obj_valid(timeRangeObj) && (obj_class(timeRangeObj) eq 'SPD_UI_TIME_RANGE') then begin
    timeRangeObj->getproperty, startTime=startt, endTime=stopt
    startt->getproperty, tdouble=stdouble
    if stdouble ne 0 then begin
      startt->getproperty,tstring=starttime
      stopt->getproperty,tstring=stoptime
    endif else begin
      startt->setproperty,tstring=starttime
      stopt->setproperty,tstring=stoptime
    endelse
  endif else begin
    timeRangeObj = Obj_New("SPD_UI_TIME_RANGE", startTime=startt, endTime=stopt)
    startt->setproperty,tstring=starttime
    stopt->setproperty,tstring=stoptime
  endelse
  
  if ~obj_valid(statusBar) then begin
    ok = error_message('Time widget passed an invalid statusBar',title='time widget error', /center,traceback = 1)
    return,0
  endif
  
  if ~obj_valid(historyWin) then begin
    ok = error_message('Time widget passed an invalid historyWin',title='time widget error', /center,traceback = 1)
    return,0
  endif 
  
  label_width = 75
  
  stash = widget_base(base)
  
  ttextBase = Widget_Base(stash, /Col, tab_mode=1, YPad=3)
  startBase = Widget_Base(ttextBase, /Row)
  stopBase = Widget_Base(ttextBase, /Row, uname='stopbase')
  formatBase = Widget_Base(ttextBase, /Row, space=0)
  startLabel = Widget_Label(startBase, Value='Start Time: ', xsize=label_width)
  startText = Widget_Text(startBase, /Editable, /All_events, Value=starttime, $
                        UValue='START_TIME', uname='start_time')
  startcal = widget_button(startbase, val = cal, /bitmap, tab_mode=0, $
                         uval='START_CAL', $
                         tooltip='Choose date/time from calendar.', sensitive=1)
  stopLabel = Widget_Label(stopBase, Value='Stop Time: ', xsize=label_width)
  stopText = Widget_Text(stopBase, /Editable, /All_events, Value=stoptime, $
                       UValue='STOP_TIME')
  stopcal = widget_button(stopbase, val = cal, /bitmap, tab_mode=0, $
                        uval='STOP_CAL', $
                        tooltip='Choose date/time from calendar.', sensitive=1)
  
  if ~keyword_set(suppressoneday) then begin
    if n_elements(oneday) lt 1 then begin
      startt->getproperty, tdouble = t0
      stopt->getproperty, tdouble = t1
      oneday = (t1-t0) eq 86400 ? 1b:0b
    endif
    
    spLabel = Widget_Label(formatBase, Value='', xsize=label_width-1);dummy label for spacing
    onedaybbase = widget_base(formatbase, /row, space=0, ypad=0, /nonexclusive)
    onedayb = widget_button(onedaybbase, value='Use Single Day', uval='ONEDAY', uname='oneday')
    widget_control, onedayb, set_button=oneday
    if oneday then  widget_control, stopbase, sensitive=0
  endif else begin
    oneday=0b
    onedayb=0L
  endelse
  
  if ~keyword_set(startyear) then startyear = 2000 ; default is to leave out years prior to 2000
  
  state = {base:base,$
           timeRangeObj:timeRangeObj,$
           startText:startText,$
           stopText:stopText,$
           valid:1b, $
           statusBar:statusBar,$
           historyWin:historyWin, $
           oneday:oneday, $
           startyear:startyear, $
           onedayID:onedayb} ;remove from state?
  
  widget_control,stash,set_uvalue=state
  
  return,base
  
end
