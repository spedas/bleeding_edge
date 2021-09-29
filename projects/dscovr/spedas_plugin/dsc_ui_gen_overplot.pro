;+
; NAME:
;  dsc_ui_gen_overplot
;
; PURPOSE:
;  Widget wrapper for DSCOVR Overview routines (dsc_overview, dsc_overview_mag,
;  and dsc_overview_fc) used to create DSCOVR overview plots in the GUI
;
; INPUT:
; call_sequence:  The GUI call sequence object.  This object stores
;                   a list of calls to external routines.  These calls
;                  are replicated when a GUI document is opened to
;                  reproduce those operations.
; gui_id:         The widget ID of the top level GUI base.
; history_window: The GUI history window object.  This object
;                   provides a viewable textual history of GUI
;                   operations and error reports.
; loaded_data:    The GUI loaded data object.  This object stores all
;                   data and corresponding metadata currently loaded
;                   into the GUI.
; status_bar:     The GUI status bar object.  This object displays
;                   informational messages at the bottom of the main
;                   GUI window.
; time_range:     The GUI's main time range object.  This object
;                   stores the current time range for the GUI and
;                   may be used/modified by the plugin.
; window_storage: Standard windowStorage object
;
;INPUT/OUTPUT:
; data_structure: Structure to hold single panel tracking data
;

; Notes:
;  Adapted from 'poes_ui_gen_overplot.pro'
;  
; ADAPTED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/spedas_plugin/dsc_ui_gen_overplot.pro $
;-

pro dsc_ui_gen_overplot_event, event

  Compile_Opt hidden
 
  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error while generating DSCOVR overview plot'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  

    dprint,  'Generate DSCOVR overview plot widget killed' 
    state.historyWin->Update,'DSCOVR_UI_GEN_OVERPLOT: Widget killed' 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  state.historywin->update,'DSCOVR_UI_GEN_OVERPLOT: User value: '+uval  ,/dontshow
  
  CASE uval OF
    'APPLY': BEGIN
    ; Check whether times set in widget are valid
    timeid = widget_info(event.top, find_by_uname='time')
    widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
    if valid then begin
      state.tr_obj->getproperty, starttime=starttime, endtime=endtime
      starttime->getproperty, tdouble=st_double
      endtime->getproperty, tdouble=et_double
      dur = (et_double - st_double) / 86400
      if dur le 0 then begin
        etxt = 'End time is earlier than start time.'
        ok = dialog_message(etxt,title='Error in Generate Overview Plot', /center, information=1)
        
        Widget_Control, event.top, Set_UValue=state, /No_Copy
        return
      endif
       
      widget_control, /hourglass
      
      if ~state.windowStorage->add(isactive=1) then begin
        ok = spd_ui_prompt_widget(state.tlb,state.statusbar,state.tlb,prompt='Error initializing new window for generating DSCOVR overview plots.', $
               title='Error in DSCOVR overview plot',/traceback, frame_attr=8)
        Widget_Control, event.top, Set_UValue=state, /No_Copy
        return
      endif  
      
      activeWindow = state.windowStorage->GetActive()
    
      state.statusBar->Update,'Generating DSCOVR overview plot. Please wait!...'

			case (state.focus) of
      	'gen': begin
					dsc_overview,trange=[st_double,et_double],/gui, error = error
					routine_name='dsc_overview'
      	end
      	'mag': begin
					dsc_overview_mag,trange=[st_double,et_double],/gui, error = error
					routine_name='dsc_overview_mag'      
      	end
      	'fc': begin
      		dsc_overview_fc,trange=[st_double,et_double],/gui, error = error
      		routine_name='dsc_overview_fc'
      	end
      	else: begin
      		ok = dialog_message(etxt,title='Error in Generate Overview Plot - Unexpected focus value', /center, information=1)
      	end
      endcase

      if ~error then begin
        
        ;add to call sequence
        state.callSequence->addPluginCall, routine_name, $
          trange = [st_double,et_double], $
          gui=1, import_only=1 ;when replaying overviews, we only want it to import data, since the window/panel structure is already serialized xml tgd document
       
        (*state.data).oplot_calls = (*state.data).oplot_calls + 1 ; update # of calls to overplot
        (*state.data).track_one = 1b
        
        msg = 'DSCOVR overview plot completed.'
      endif else begin
        msg = 'Error generating DSCOVR overview plot.'
      endelse
      state.statusBar->Update, msg
      Widget_Control, event.top, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      return
    endif else ok = dialog_message('Invalid start/end time, please use: YYYY-MM-DD/hh:mm:ss', $
                                   /center)
    END
    'CANC': BEGIN
      state.historyWin->update,'Generate DSCOVR overview plot canceled',/dontshow
      state.statusBar->Update,'Generate DSCOVR overview plot canceled.'
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
		'FOCUS:GEN': state.focus='gen'
		'FOCUS:MAG': state.focus='mag'
		'FOCUS:FC': state.focus='fc'
    'TIME': ; don't send 'Not yet implemented' to the console for time events
    ELSE: dprint,  'Not yet implemented'
  ENDCASE
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
end


pro dsc_ui_gen_overplot, gui_id = gui_id, $
                          history_window = historyWin, $
                          status_bar = statusbar, $
                          call_sequence = callSequence, $
                          time_range = tr_obj, $
                          window_storage = windowStorage, $
                          data_structure = data_structure, $
                          _extra = _extra

  compile_opt idl2

  err_xxx = 0
  Catch, err_xxx
  IF(err_xxx Ne 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO Begin
      print, err_msg[j]
      If(obj_valid(historywin)) Then historyWin -> update, err_msg[j]
    Endfor
    Print, 'Error--See history'
    ok = error_message('An unknown error occured starting widget to generate DSCOVR overview plot. ', $
         'See console for details.', /noname, /center, title='Error while generating DSCOVR overview plot')
    spd_gui_error, gui_id, historywin
    RETURN
  ENDIF
  
  tlb = widget_base(/col, title='Generate DSCOVR Overview Plot', group_leader=gui_id, $
          /floating, /base_align_center, /tlb_kill_request_events, /modal)

; Base skeleton          
  mainBase = widget_base(tlb, /col, /align_center, tab_mode=1, space=4)
    txtBase = widget_base(mainbase, /Col, /align_center)
    focusBase = widget_base(mainBase, row=1, /align_center)
      focusButtonBase = widget_base(focusBase, row=1, /align_left, /exclusive)
    midBase = widget_base(mainBase, /Row)
      trvalsBase = Widget_Base(midBase, /Col, Frame=1, xpad=8)
    buttonBase = Widget_Base(mainBase, /row, /align_center)

; Help text
  wj = widget_label(txtbase, value='Creating the overview plot might take a few minutes.', /align_left)

; Focus selection widgets
ButtonGen = widget_button(focusButtonBase, value='General', uvalue='FOCUS:GEN')
ButtonMag = widget_button(focusButtonBase, value='Mag Focus', uvalue='FOCUS:MAG')
ButtonFC  = widget_button(focusButtonBase, value='FC Focus', uvalue='FOCUS:FC')

  widget_control, ButtonGen, /set_button
  focus='gen'

; Time range-related widgets
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, tlb, cal  

  st_text = '2016-06-04/00:00:00.0'
  et_text = '2016-06-05/00:00:00.0'
  
  if ~obj_valid(tr_obj) then begin
		tr_obj=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  endif else begin
  	if (tr_obj.getStartTime() lt time_double('2015-02-11')) then begin
			res = tr_obj.SetStartTime(st_text)
  		res = tr_obj.SetEndTime(et_text)
  	endif
  endelse

  timeWidget = spd_ui_time_widget(trvalsBase,statusBar,historyWin,timeRangeObj=tr_obj, $
                                  uvalue='TIME',uname='time', startyear = 2015);, oneday=1 
  
; Main window buttons
  applyButton = Widget_Button(buttonBase, Value='Apply', UValue='APPLY', XSize=80)
  cancelButton = Widget_Button(buttonBase, Value='Cancel', UValue='CANC', XSize=80)

  ;flag denoting successful run
  success = 0

  ;initialize structure to store variables for future calls
  if ~is_struct(data_structure) then begin
    data_structure = { oplot_calls:0, track_one:0b }
  endif

  data_ptr = ptr_new(data_structure)

  state = {tlb:tlb, gui_id:gui_id, historyWin:historyWin,statusBar:statusBar, $
           tr_obj:tr_obj, focus:focus,success:ptr_new(success), $
           data:data_ptr, $
           callSequence:callSequence,windowStorage:windowStorage} 

  Centertlb, tlb         
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'dsc_ui_gen_overplot', tlb, /No_Block

  ;if pointer or struct are not valid the original structure will be unchanged
  if ptr_valid(data_ptr) && is_struct(*data_ptr) then begin
    data_structure = *data_ptr
  endif

  RETURN
end
