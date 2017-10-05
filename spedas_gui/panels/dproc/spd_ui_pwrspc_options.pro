;+
;NAME:
;  spd_ui_pwrspc_options
;
;PURPOSE:
;  A widget used to set keyword options for creating power spectra.  This
;  widget returns an anonymous structure of keyword settings that is passed
;  through the OPTIONS positional parameter of SPD_UI_PWRSPC.  Intended to
;  be called from SPD_UI_DPROC.
;
;CALLING SEQUENCE:
;  opt_struct = spd_ui_pwrspc_options(gui_id, trObj, historyWin, statusBar)
;
;INPUT:
;  gui_id: The GUI id that should be the top level id of the Data Processing
;          window.
;  trObj: The timerange object that is created in SPD_GUI.
;  historyWin: The history window object.
;  statusBar: The status bar object for the Data Processing window.
;  
;KEYWORDS:
;  none
;
;OUTPUT:
;  opt_struct: The anonymous structure contain options and keyword settings for
;              SPD_UI_PWRSPC.
;            
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-05-02 14:17:19 -0700 (Fri, 02 May 2014) $
;$LastChangedRevision: 15029 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/dproc/spd_ui_pwrspc_options.pro $
;-


function spd_ui_pwrspc_options_check_input, state

  Compile_Opt idl2, hidden
  
  fail = 0
  
  if finite(state.bins) then begin
    if state.bins lt 1 then begin
      fail = 1
      state.statusBar->update, 'Bins input must be greater than or equal to 1.  Reset to default'
      ok = dialog_message('Bins input invalid: please enter a value greater than or equal to 1.  Value reset to default.', $
                              /center,title='Power Spectra Error')
      state.bins=3D
      widget_control, state.binsSpin, set_value=state.bins
    endif
  endif else begin
    fail = 1
    state.statusBar->update, 'Bins input invalid.  Reset to default'
    ok = dialog_message('Bins input invalid: please enter a numeric value greater than or equal to 1.  Value reset to default.', $
                              /center,title='Power Spectra Error')
    state.bins=3D
    widget_control, state.binsSpin, set_value=state.bins
  endelse
  
  return, fail
end

pro spd_ui_pwrspc_options_set_value,state

  scrubnansid = widget_info(state.tlb,find_by_uname='scrubnans')
  state.scrubNans = widget_info(scrubnansid,/button_set) 
  
  suffixid = widget_info(state.tlb,find_by_uname='suffix')
  widget_control,suffixid,get_value=suffixtext
  state.suffix=strcompress(suffixtext,/remove_all)

end

pro spd_ui_pwrspc_options_event, event

  Compile_Opt idl2, hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Power Spectra Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  

    ;Print, 'Power Spectra Options widget killed' 
    state.historyWin->Update,'SPD_UI_PWRSPC_OPTIONS: Widget killed' 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  state.historyWin->update,'SPD_UI_PWRSPC_OPTIONS: User value: '+uval  ,/dontshow
  
  CASE uval OF
    'APPLY': BEGIN
      widget_control, state.trWidget, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
      if ~valid then begin
        result = dialog_message('Invalid time range inputed. Use format: YYYY-MM-DD/hh:mm:ss',/center)
        break
      endif
      
      ; warn the user that we're going to append _pwr if they got here with an empty suffix text box
      suffix_widget = widget_info(event.top, find_by_uname='suffix')
      widget_control, suffix_widget, get_value=the_actual_suffix
      if the_actual_suffix eq '' then warning_msg = dialog_message('No suffix given - to avoid internal naming conflicts, a suffix of _pwr will be appended to the end of the variables', /center)

      spd_ui_pwrspc_options_set_value,state
      fail = spd_ui_pwrspc_options_check_input(state)
      if (~fail) then begin
        
        if state.settime then begin
          state.tbegin = state.tr_obj->getstarttime()
          state.tend = state.tr_obj->getendtime()
        endif else begin
          state.tbegin = 0
          state.tend = 0
        endelse
        
        if state.tbegin eq state.tend then state.trange=[0,0] $
          else state.trange=[state.tbegin, state.tend]
          
        state.success=1
        
        *state.opt_struct_ptr = {dynamic:state.dynamic, suffix:state.suffix, $
                                 nboxpoints:state.nboxpoints, $
                                 nshiftpoints:state.nshiftpoints, $
                                 trange:state.trange, tbegin:state.tbegin, $
                                 tend:state.tend, bins:long(state.bins), $
                                 noline:state.noline, nohanning:state.nohanning, $
                                 notperhz:state.notperhz, success:state.success,$
                                 scrubNans:state.scrubNans}
        
        Widget_Control, event.TOP, Set_UValue=state, /No_Copy
        Widget_Control, event.top, /Destroy
        return
      end
    END
    'BINS': BEGIN
      if finite(event.value) &&  event.value ge 1 then begin
        state.bins = event.value
        mess = 'Bins set to ' + strcompress(string(long(state.bins)))
        state.statusBar->update, mess
        state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
      endif else begin
        state.bins = event.value
        state.statusBar->update, 'Bins must be a numeric value greater than or equal to 1.'
      endelse
    END
    'BOXSIZE': BEGIN
      state.nboxpoints = long(state.hanning_size[event.index])
      
      mess = 'Window Size set to' + strcompress(string(state.nboxpoints))+ ' points.'
      state.statusBar->update, mess
      state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
    END
    'CANC': BEGIN
      state.historyWin->update,'Power Spectra Options Cancelled',/dontshow
      state.success=0
      *state.opt_struct_ptr = {success:state.success}
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      return
    END
    'DYNAMIC':BEGIN
      state.dynamic = event.select
      widget_control, state.nboxptsList, sensitive=state.dynamic
      widget_control, state.nshiftptsList, sensitive=state.dynamic
      widget_control, state.settimeBase, sensitive=state.dynamic
      
      suffixid = widget_info(event.top,find_by_uname='suffix')
      widget_control,suffixid,get_value=suffixtext
      
      if state.dynamic then begin
        mess = 'Dynamic power spectra selected.' 
        if suffixtext eq '_pwrspc' then begin
          widget_control,suffixid,set_value='_dpwrspc'
        endif
      endif else begin
        mess = 'Dynamic power spectra de-selected.'
        if suffixtext eq '_dpwrspc' then begin
          widget_control,suffixid,set_value='_pwrspc'
        endif 
      endelse
      
      state.statusBar->update, mess
      state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
    END
    'HELP': BEGIN
 
      gethelppath,path
      xdisplayfile, path+'spd_ui_pwrspc.txt', group=state.gui_id, /modal, done_button='Done', $
                    title='HELP: Power Spectra Options'
    END
    'NOHANN': BEGIN
      state.nohanning = event.select

      if event.select then begin
        mess = 'Hanning window turned off.'
      endif else begin
        mess = 'Hanning window turned on.'
      endelse

      state.statusBar->update, mess
      state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
    END
    'NOLINE': BEGIN
      state.noline = event.select

      if event.select then begin
        mess = 'No Line turned on.'
      endif else begin
        mess = 'No Line turned off.'
      endelse

      state.statusBar->update, mess
      state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
    END
    'NOTPERHZ': BEGIN
      state.notperhz = event.select

      if event.select then begin
        mess = 'Not Per Hz turned on.'
      endif else begin
        mess = 'Not Per Hz turned off.'
      endelse

      state.statusBar->update, mess
      state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
    END
    'SETTIME': BEGIN
      state.settime = event.select
      widget_control, state.timeBase, sensitive=state.settime

      if event.select then begin
        mess = 'Set Time Range turned on.'
      endif else begin
        mess = 'Set Time Range turned off.'
      endelse

      state.statusBar->update, mess
      state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
    END
    'SHIFT_PTS': BEGIN
      state.nshiftpoints = long(state.hanning_size[event.index])

      mess = 'Window Shift set to' + strcompress(string(state.nshiftpoints))+ ' points.'
      state.statusBar->update, mess
      state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
    END
    'TIME': BEGIN
      ;nothing to implement at the moment
    END
;    'STARTCAL': BEGIN
;      widget_control, state.trcontrols[0], get_value= val
;      start=spd_ui_timefix(val)
;      state.tr_obj->getproperty, starttime = start_time       
;      if ~is_string(start) then start_time->set_property, tstring=start
;      spd_ui_calendar, 'Choose date/time: ', start_time, state.gui_id
;      start_time->getproperty, tstring=start
;      widget_control, state.trcontrols[0], set_value=start
;
;      mess = 'Start Time set to ' + start
;      state.statusBar->update, mess
;      state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
;    END
;    'STOPCAL': BEGIN
;      widget_control, state.trcontrols[1], get_value= val
;      endt=spd_ui_timefix(val)
;      state.tr_obj->getproperty, endtime = end_time       
;      if ~is_string(endt) then end_time->set_property, tstring=endt
;      spd_ui_calendar, 'Choose date/time: ', end_time, state.gui_id
;      end_time->getproperty, tstring=endt
;      widget_control, state.trcontrols[1], set_value=endt
;
;      mess = 'End Time set to ' + endt
;      state.statusBar->update, mess
;      state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
;    END
  
;    'TSTART': BEGIN ; Start Time entry box
;      widget_control,event.id,get_value=value
;      t0 = spd_ui_timefix(value)
;      If(is_string(t0)) Then Begin
;        ;get both times for limit checking
;        state.tr_obj->GetProperty, startTime=st ;st is starttime object (spd_ui_time__define)
;        state.tr_obj->GetProperty, endTime=et   ;et is endtime object
;        ;set start time value
;        st->SetProperty, tstring = value
;        ;return a warning if the time range is less than zero, or longer than 1 week
;        et->getproperty, tdouble=t1
;        st->getproperty, tdouble=t0
;
;        mess = 'Start Time set to ' + value
;        state.statusBar->update, mess
;        state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
;      Endif
;    END
;    'TEND': BEGIN ; End Time entry box
;      widget_control,event.id,get_value=value
;      t0 = spd_ui_timefix(value)
;      If(is_string(t0)) Then Begin
;        state.tr_obj->GetProperty, startTime=st ;st is starttime object (spd_ui_time__define)
;        state.tr_obj->GetProperty, endTime=et ;et is endtime object (spd_ui_time__define)
;        ;Set end time value
;        et->SetProperty, tstring = value
;        ;return a warning if the time range is less than zero, or longer than 1 week
;        et->getproperty, tdouble=t1
;        st->getproperty, tdouble=t0
;
;        mess = 'End Time set to ' + value
;        state.statusBar->update, mess
;        state.historyWin->update, 'SPD_UI_PWRSPC_OPTIONS: ' + mess
;      Endif
;    END
    ELSE:
  ENDCASE    

  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
end

function spd_ui_pwrspc_options, gui_id, trObj, historyWin, statusBar

  compile_opt idl2
  

  tlb = widget_base(/col, title='Power Spectra Options', group_leader=gui_id, $
                    /modal, /floating, /base_align_center, /tlb_kill_request_events)

; Base skeleton          
  mainBase = widget_base(tlb, /col, /align_center, tab_mode=1)
    dynamicBase = widget_base(mainBase, /row, /nonexclusive)
    suffixBase = widget_base(mainBase, /row)
    nboxptsBase = widget_base(mainBase, /row)
    nshiftptsBase = widget_base(mainBase, /row)
    settimeBase = widget_base(mainBase, /col)
      timeButtonBase = widget_base(settimeBase, /row, /nonexclusive)
      timeBase = widget_base(settimeBase, /col, /frame)
;        tstartBase = widget_base(timeBase, /row)
;        tendBase = widget_base(timeBase, /row)
    binsBaseRow = widget_base(mainBase,/row)
    binsBase = widget_base(binsBaseRow)
    scrubNaNBase = widget_base(binsBaseRow,/nonexclusive) 
    optionsBase = widget_base(mainBase, /row, /nonexclusive)
    buttonBase = widget_base(mainBase, /row, /align_center)

; Set defaults
  dynamic=1
  suffix='_dpwrspc'
  hanning_size=[' 32',' 64',' 128',' 256',' 512',' 1024',' 2048',' 4096', $
                ' 8192',' 16384']
  nboxpoints=256L
  nboxpointsList= where(nboxpoints eq long(hanning_size))
  nshiftpoints=128L
  nshiftpointsList = where(nshiftpoints eq long(hanning_size))
  settime=0
  tbegin=0
  tend=0
  trange=[0,0]
  bins=3D
  noline=0
  nohanning=0
  notperhz=0
  success=0
  scrubNans = 1
  
; Widgets
  dynamicButton = widget_button(dynamicBase, value='Dynamic', uval='DYNAMIC')
  widget_control, dynamicButton, set_button=dynamic
  
  suffixLabel = widget_label(suffixBase, value = 'Suffix: ')
  suffixId = widget_text(suffixBase, value = suffix, xsize = 22, ysize = 1, $
                         uvalue = 'SUFFIX', /editable, /all_events,uname='suffix')
  
  nboxptsLabel = widget_label(nboxptsBase, value='Window Size: ')
  nboxptsList = widget_combobox(nboxptsBase, uval='BOXSIZE', value=hanning_size)
  widget_control, nboxptsList, set_combobox_select=nboxpointsList

  nshiftptsLabel = widget_label(nshiftptsBase, value='Window Shift: ')
  nshift = hanning_size
  nshiftptsList = widget_combobox(nshiftptsBase, uval='SHIFT_PTS', value=nshift)
  widget_control, nshiftptsList, set_combobox_select=nshiftpointsList

; Time range-related widgets
  timeButton = widget_button(timeButtonBase, value='Set Time Range: ', uval='SETTIME')
  widget_control, timeButton, set_button=settime, sensitive=dynamic
  widget_control, timeBase, sensitive=settime

  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, tlb, cal  

; Start/Stop Time objects
  st_text = '2007-03-23/00:00:00.0'
  et_text = '2007-03-24/00:00:00.0'

  if obj_valid(trObj) && (obj_class(trObj) eq 'SPD_UI_TIME_RANGE') then begin
  ; create new time range object
    tr_obj = obj_new('SPD_UI_TIME_RANGE')
    ok = tr_obj->SetStartTime(trObj->getstarttime())
    ok = tr_obj->setendtime(trObj->getendtime())
  endif else begin
    tr_obj = Obj_New("SPD_UI_TIME_RANGE", startTime=st_text, endTime=et_text)
    startt->setproperty,tstring=st_text
    stopt->setproperty,tstring=et_text
    ;timerange=tr_obj
  endelse
 

  trWidget = spd_ui_time_widget(timebase,statusBar,historyWin,timeRangeObj=tr_obj, $
                                uvalue='TIME',uname='time', oneday=0)

;  tstartLabel = Widget_Label(tstartBase,Value='Start Time: ')
;  geo_struct = widget_info(tstartlabel,/geometry)
;  labelXSize = geo_struct.scr_xsize
;  tstartText = Widget_Text(tstartBase, Value=st_text, /Editable, /Align_Left, /All_Events, $
;                           UValue='TSTART')
;  startcal = widget_button(tstartbase, val = cal, /bitmap, tab_mode=0, uval='STARTCAL', uname='startcal', $
;                           tooltip='Choose date/time from calendar.')
;  tendLabel = Widget_Label(tendBase,Value='End Time: ', xsize=labelXSize)
;  tendText = Widget_Text(tendBase,Value=et_text, /Editable, /Align_Left, /All_Events, $
;                         UValue='TEND')
;  stopcal = widget_button(tendbase, val = cal, /bitmap, tab_mode=0, uval='STOPCAL', uname='stopcal', $
;                          tooltip='Choose date/time from calendar.')
  trControls=[trwidget]
  
  nolineButton = widget_button(optionsBase, value='No Line', uval='NOLINE')
  nohannButton = widget_button(optionsBase, value='No Hanning', uval='NOHANN')
  notperhzButton = widget_button(optionsBase, value='Not Per Hz', uval='NOTPERHZ')

  binsSpin = spd_ui_spinner(binsBase, increment=1, value=bins, uval='BINS', text_box_size=4, $
                            /all_events, label='Bins: ', min_value=1)
                            
  scrubNansButton = widget_button(scrubNanBase,uname='scrubnans',value="Remove NaNs From Input?",uval="SCRUBNANS")
  widget_control,scrubNansButton,/set_button
  
  
; Main window buttons
  applyButton = Widget_Button(buttonBase, Value='OK', UVal='APPLY')
  cancelButton = widget_button(buttonBase, Value='Cancel', UVal='CANC')
  helpButton = widget_button(buttonBase, Value='Help', UVal='HELP') 
  
; Create structure to hold options
  opt_struct = {dynamic:dynamic, suffix:suffix, nboxpoints:nboxpoints, $
                nshiftpoints:nshiftpoints, trange:trange, tbegin:tbegin, $
                tend:tend, bins:bins, noline:noline, nohanning:nohanning, $
                notperhz:notperhz, success:success,scrubNans:scrubNans}
  opt_struct_ptr = ptr_new(opt_struct)

  state = {tlb:tlb, gui_id:gui_id, historyWin:historyWin, statusBar:statusBar, $
           hanning_size:hanning_size, dynamic:dynamic, suffix:suffix, $
           nboxpoints:nboxpoints, nshiftpoints:nshiftpoints, settime:settime, $
           trange:trange, tbegin:tbegin, tend:tend, tr_obj:tr_obj, $
           trControls:trControls, bins:bins, noline:noline, nohanning:nohanning, $
           notperhz:notperhz, success:success, opt_struct_ptr:opt_struct_ptr,scrubNans:scrubNans, $
           ;widget IDs
           settimeBase:settimeBase, timeBase:timeBase, nboxptsList:nboxptsList, $
           nshiftptsList:nshiftptsList, binsSpin:binsSpin, trWidget:trWidget}

  Centertlb, tlb         
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'spd_ui_pwrspc_options', tlb, /No_Block
  
  opt_struct = *opt_struct_ptr
  ptr_free, opt_struct_ptr

  RETURN, opt_struct
end
