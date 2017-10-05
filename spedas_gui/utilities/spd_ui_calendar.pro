;+ 
;NAME:
; spd_ui_calendar.pro
;
;PURPOSE:
; Calendar selection widget for the GUI
;
;CALLING SEQUENCE:
; spd_ui_calendar,title, otime, gui_id, startyear
;
;INPUT:
; title: Title of the calendar window
; otime: Time object
; gui_id: Widget ID of the widget that called the calendar
; startyear: Start year in 'Year' list
; 
; 
;HISTORY:
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-


PRO spd_ui_calendar_update, wbase, state

    compile_opt idl2, hidden
  
  widget_control, state.month, get_value=month
  widget_control, state.year, get_value=year
  
  ; Find offset for first day of the month
  offset = (julday(month, 1, year)+1) mod 7
  
  ; Deal with leap years
  if ( julday(1, 1, year+1) - julday(1, 1, year) ) gt 365 then $
    state.numdays[1] = 29  else state.numdays[1] = 28
  
  
  ; Add/remove extra buttons for when month overflows
  if (offset + state.numdays[month-1]) gt 35 then begin
    if ~widget_info(state.temp, /valid_ID) then begin
      state.temp = widget_base(state.calBase, /row, xpad=0, ypad=0, space=0,frame=0)
      bID = widget_button(state.temp, value='', /no_release, xsize=40, ysize=35, $
                                          uvalue='DAY', uname='35')
      bID = widget_button(state.temp, value='', /no_release, xsize=40, ysize=35, $
                                          uvalue='DAY', uname='36')
    endif
    j=36
  endif else begin
    j=34
    if widget_info(state.temp, /valid_ID) then widget_control, state.temp, /destroy
  endelse
  
  
  ; Number the calendar buttons using the starting offset from above
  i=1
  for k=0, j do begin
    id = widget_info(wBase, find_by_uname=strtrim(k,2))
    if (k lt offset) or (k ge (offset + state.numdays[month-1])) then begin
      widget_control, id, set_value='', sensitive=0 
    endif else begin
      widget_control, id, set_value=strtrim(i,2), sensitive=1
      i++
    endelse
  endfor

  return

END ;---------------------------------------



PRO spd_ui_calendar_event, event
    
    compile_opt idl2, hidden
  
  catch, _err
  if _err then begin
    catch, /cancel
    ok = error_message('An error has occured and the calender must shut down.', /noname)
    widget_control, event.top, /destroy
  endif
    
;The user value of the top-level base widget is an anonymous structure that holds the widget IDs of the month, day,
; and year label widgets as well as stored values for hours, minutes, and seconds.
  WIDGET_CONTROL, event.TOP, GET_UVALUE = state, /no_copy
  WIDGET_CONTROL, event.ID, GET_UVALUE = uval
   
  IF Size(uval, /Type) NE 0 THEN BEGIN
    CASE uval OF
      'OK':begin
           ;Pull month/day/year values from display widgets
             widget_control, state.year, get_value = year
             widget_control, state.month, get_value = month
             widget_control, state.day, get_value = day
             
           ;Create time double from separate time elements and apply to time object
             datetime = time_double(strtrim(year,2)+'-'+strtrim(month,2)+'-'+strtrim(day,2) $
                    +'/'+strtrim(state.hour,2)+':'+strtrim(state.minute,2)+':'+strtrim(state.second,2))
             state.otime->setproperty, tdouble=datetime
             
             widget_control, event.top, set_uvalue=state, /no_copy
             Widget_Control, event.top, /Destroy
             return
           end
           
      'CANCEL':begin
                 widget_control, event.top, /Destroy
                 return
               end
               
      'HOURS':BEGIN
                IF event.valid then begin
                  IF event.value LT 0 OR event.value GE 24 THEN BEGIN
                    limit = event.value lt 0 ? 0:23
                    state.hour = limit
                    Widget_Control, event.id, set_value = limit
                  ENDIF ELSE BEGIN
                    state.hour=event.value
                  ENDELSE
                ENDIF
              END
              
      'MINUTES':BEGIN
                  IF event.valid then begin
                    IF event.value LT 0 OR event.value GE 60 THEN BEGIN
                      limit = event.value lt 0 ? 0:59
                      state.minute = limit
                      Widget_Control, event.id, set_value = limit
                    ENDIF ELSE BEGIN
                      state.minute=event.value
                    ENDELSE
                  ENDIF
                END
                
      'SECONDS':BEGIN
                  IF event.valid then begin
                    IF event.value LT 0 OR event.value GE 60 THEN BEGIN
                      limit = event.value lt 0 ? 0:59
                      state.second = limit
                      Widget_Control, event.id, set_value = limit
                    ENDIF ELSE BEGIN
                      state.second=event.value
                    ENDELSE
                  ENDIF
                END
                
      'DAY':BEGIN
              widget_control, event.id, get_value=day
              widget_control, state.day, set_value=day
            END
            
      'YEAR':BEGIN
               widget_control, state.year, set_value=widget_info(event.id, /combobox_gettext)
               spd_ui_calendar_update, state.wBase, state
             END
             
      'MONTH':BEGIN
                widget_control, event.id, get_value=tlist
                widget_control, state.month, $ 
                  set_value= strtrim((where(tlist eq widget_info(event.id, /combobox_gettext)))[0]+1,2)
                spd_ui_calendar_update, state.wBase, state 
              END
              
    ENDCASE
  ENDIF 
  
  widget_control, event.top, set_uvalue=state, /no_copy
  
  Return
  
END ;--------------------------------------------------------------




PRO spd_ui_calendar, title, otime, gui_id, startyear=startyear

    compile_opt idl2, hidden

;Verify valid time object was passed in
  if obj_valid(otime) then begin
    intime=otime->getstructure()
  endif else begin
    otime=obj_new('spd_ui_time')
    intime=otime->getstructure()
  endelse

;Create base widgets to hold labels for the selected month, day, and year. Set the initial values of the labels.
   wBase = WIDGET_BASE(COLUMN = 1, SCR_XSIZE = 370, $ 
      TITLE=title, /Align_Center, /modal, group_leader=gui_id) 
   wDateBase = WIDGET_BASE(wBase, /ROW)
   wYearBase = WIDGET_BASE(wDateBase, /COL, /align_center, xpad=5, ypad=2)
   wTimeBase = WIDGET_BASE(wDateBase, /COL, /base_align_right, xsize=250)
   wSubBase = WIDGET_BASE(wYearBase, /ROW) 
   wSubTimeBase = WIDGET_BASE(wTimeBase, /COL, xpad=1, tab_mode=1)
   wVoid = WIDGET_LABEL(wSubBase, VALUE = 'Year: ') 
   wYear = WIDGET_LABEL(wSubBase, VALUE = '1999', xsize=40)
   wSubBase = WIDGET_BASE(wYearBase, /ROW) 
   wVoid = WIDGET_LABEL(wSubBase, value = 'Month: ') 
   wMonth = WIDGET_LABEL(wSubBase, value = '10', xsize=20) 
   wSubBase = WIDGET_BASE(wYearBase, /ROW) 
   wVoid = WIDGET_LABEL(wSubBase, VALUE = 'Day: ') 
   wDay = WIDGET_LABEL(wSubBase, VALUE = '22', xsize=20)    
   
   ; Get size of largest spinner label and set for all if larger than standard 
   test = widget_label(wsubtimebase, value = 'Seconds: ')
   xls = widget_info(test, /geometry)
   widget_control, test, /destroy
   
   xls = xls.xsize gt 52 ? xls.xsize:52 
      
   wHour=spd_ui_spinner(wSubTimeBase, Label='Hour: ', xlabelsize=xls, Increment=1, Value=intime.hour, uval='HOURS')
   wMinute=spd_ui_spinner(wSubTimeBase, Label='Minute: ', xlabelsize=xls, Increment=1, Value=intime.min, uval='MINUTES')
   wSecond=spd_ui_spinner(wSubTimeBase, Label='Second: ', xlabelsize=xls, Increment=1, Value=intime.sec, uval='SECONDS')
   


;Calendar proper widgets
  calBase = widget_base(wBase, /col, /align_center)
  
;List of years created by adding the starting year to an integer array
; updated to include the possibility of years back to 1800s, egrimes 1/16/13
  if undefined(startyear) then startyear = 2000
  current_year = strmid(systime(), 3, /reverse_offset)
  num_of_years = current_year-startyear+2
  years = strtrim((indgen(num_of_years)+startyear),2) ; include years back to 1800s, for IUGONET
 
  ; create a string for showing the valid date range and
  ; remove the padding introduced by converting the years to strings
  valid_dates_tooltip = 'Valid dates: '+ strcompress(string(startyear), /rem) + ' - ' + strcompress(string(current_year), /rem)

  months = ['January','February','March','April','May','June','July','August','September','October','November','December']
  numDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

  dropBase = widget_base(calBase, /row, /align_center, space=60, ypad=5)
  yearbase = widget_base(dropBase, /row, /align_left)
  yearlabel = widget_label(yearbase, value = 'Year: ')
  yearlist = widget_combobox(yearbase, value = years, uvalue='YEAR', uname='year')
  monthbase = widget_base(dropbase, /row, /align_right)
  monthlabel = widget_label(monthbase, value = 'Month: ')
  monthlist = widget_combobox(monthbase, value = months, uvalue='MONTH', uname='month')
   
   
;Create labels for the caledar's days
  dayBase = widget_base(calBase, /row, /base_align_center, xpad=0, space=0)
  for j=0, 6 do dID = widget_Label(daybase, value=days[j], xsize=40, /align_center)
  
;Create 5 rows of 7 buttons for calendar days 
  rows = lonarr(5)
  for j=0, n_elements(rows)-1 do rows[j] = widget_base(calBase, /row, xpad=0, ypad=0, space=0,frame=0)
  for j=0, n_elements(rows)-1 do begin
    for i=0, 6 do bID = widget_button(rows[j], value='', /no_release, xsize=40, ysize=35, $
                                      uvalue='DAY', uname=strtrim((7*j)+(i),2), ToolTip = valid_dates_tooltip)
  endfor
 
;Create the ok and cancel buttons
   buttonBase = WIDGET_BASE(wBase, /row, /align_center)
   okButton = WIDGET_BUTTON(buttonBase, value='OK', uValue='OK', xsize=75, ToolTip = valid_dates_tooltip)
   cancelButton = WIDGET_BUTTON(buttonBase, value='Cancel', uValue='CANCEL', xsize=75)
   
   
;Realize the top-lvel base widget 
   WIDGET_CONTROL, wBase, /REALIZE 


;Set widget values
   year = strtrim(intime.year, 2)


   WIDGET_CONTROL, yearlist, set_combobox_select = where(years eq year)
   WIDGET_CONTROL, monthlist, set_combobox_select = intime.month-1
   WIDGET_CONTROL, wYear, SET_VALUE=widget_info(yearList,/combobox_gettext)
   WIDGET_CONTROL, wMonth, SET_VALUE=strtrim(intime.month,2)
   WIDGET_CONTROL, wDay, SET_VALUE=STRTRIM(intime.date, 2) 
   
;Hour/min/sec stored directly in state variables, month/day/year stored in their corresponding display widgets
   state = {wBase:wBase, calBase:calBase, month:wMonth, temp:-1L, day:wDay, year:wYear, $
            hour:intime.hour, minute:intime.min, second:intime.sec, otime:otime, numdays:numdays}
 
   spd_ui_calendar_update, wbase, state
   
   WIDGET_CONTROL, wBase, set_uvalue=state, /no_copy 
   
;Call XMANAGER to manage the widget events, and end the procedure.
   XMANAGER, 'spd_ui_calendar', wBase 
   
   return
 
END ;--------------------------------------------------------------
