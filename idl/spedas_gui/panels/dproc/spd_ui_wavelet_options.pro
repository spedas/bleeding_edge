;+
;NAME:
;  spd_ui_wavelet_options
;
;PURPOSE:
;  A widget used to set keyword options for creating power spectra.  This
;  widget returns an anonymous structure of keyword settings that is passed
;  through the OPTIONS positional parameter of SPD_UI_WAVELET.  Intended to
;  be called from SPD_UI_DPROC.
;
;CALLING SEQUENCE:
;  opt_struct = spd_ui_wavelet_options(gui_id, trObj, historyWin,
;               statusBar, varname)
;
;INPUT:
;  gui_id: The GUI id that should be the top level id of the Data Processing
;          window.
;  dataobj: The data object
;  trObj: The timerange object that is created in SPD_GUI.
;  historyWin: The history window object.
;  statusBar: The status bar object for the Data Processing window.
;  varname: The variable name -- since wavlet defaults depend on the
;           time resoultion of each variable, this need to be done
;           separately for each one
;KEYWORDS:
;  none
;
;OUTPUT:
;  opt_struct: The anonymous structure contain options and keyword settings for
;              SPD_UI_WAVELET.
;            
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-02-25 13:27:50 -0800 (Fri, 25 Feb 2022) $
;$LastChangedRevision: 30620 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/dproc/spd_ui_wavelet_options.pro $
;-

pro spd_ui_wavelet_options_event, event

  Compile_Opt idl2, hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
     Catch, /Cancel
     Help, /Last_Message, Output = err_msg
     spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Wavelet Options'
     Widget_Control, event.TOP, Set_UValue=state, /No_Copy
     widget_control, event.top,/destroy
     RETURN
  ENDIF
  
  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
    ;Print, 'Power Spectra Options widget killed' 
     state.historyWin->Update,'SPD_UI_WAVELET_OPTIONS: Widget killed' 
     Widget_Control, event.TOP, Set_UValue=state, /No_Copy
     Widget_Control, event.top, /Destroy
     RETURN 
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  state.historyWin->update,'SPD_UI_WAVELET_OPTIONS: User value: '+uval  ,/dontshow
  
  CASE uval OF
     'OK': BEGIN
        widget_control, state.trWidget, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
        if ~valid then begin
           dummy = dialog_message('Invalid time range inputed. Use format: YYYY-MM-DD/hh:mm:ss',/center)
           break
        endif
;Need to try the memory test, etc, here
        t00 = state.tr_obj->getstarttime()
        t01 = state.tr_obj->getendtime()
        sst = where(*state.tptr Ge t00 And *state.tptr Le t01, nsst)
        If(nsst Eq 0) Then Begin
           dummy = dialog_message('No data in selected time range',/center)
           break
        Endif
        memtest = spd_ui_wv_memory_test(state.varname, (*state.tptr)[sst], $
                                        jv, prange, info_txt, memok=memok, jvok=jvok)
        prange0_widget = widget_info(event.top, find_by_uname='prange0')
        widget_control, prange0_widget, get_value=prange0
        prange1_widget = widget_info(event.top, find_by_uname='prange1')
        widget_control, prange1_widget, get_value=prange1
        if valid_num(prange0) and valid_num(prange1) then begin  
          if double(prange1) gt double(prange0) then begin   
            prange = [double(prange0), double(prange1)]
          endif else begin
            dprint,"Error: Max period is not larger than min period. We'll use the default prange values."   
          endelse
        endif else begin
          dprint,"Error: Period values are not valid numbers. We'll use the default prange values."  
        endelse
                                        
        info_widget = widget_info(event.top, find_by_uname='info')
        widget_control, info_widget, set_value = info_txt
;If  memok or jvok are 0, then break
        If(memok Eq 0) Then Begin
           dummy = dialog_message('Too much data in selected time range',/center)
           break
        Endif
        If(jvok Eq 0) Then Begin
           dummy = dialog_message('Not enough data in selected time range',/center)
           break
        Endif
;Otherwise roll on
        (*state.opt_struct_ptr).prange = prange
;set the time range
        (*state.opt_struct_ptr).trange = [t00, t01]
; warn the user that we're going to append _wv_pow if they got here with an empty suffix text box
        suffix_widget = widget_info(event.top, find_by_uname='suffix')
        widget_control, suffix_widget, get_value=the_actual_suffix
        if the_actual_suffix eq '' then begin
           warning_msg = dialog_message('No suffix given - to avoid internal naming conflicts, a suffix of _wv_pow will be appended to the end of the variables', /center)
           (*state.opt_struct_ptr).suffix = '_wv_pow'
        endif else (*state.opt_struct_ptr).suffix = strcompress(/remove_all, the_actual_suffix)
        (*state.opt_struct_ptr).success = 1b

        Widget_Control, event.TOP, Set_UValue=state, /No_Copy
        Widget_Control, event.top, /Destroy
        return
     END
     'CANCEL': BEGIN
        state.historyWin->update,'Wavelet Options Cancelled',/dontshow
        (*state.opt_struct_ptr).success=0
        Widget_Control, event.TOP, Set_UValue=state, /No_Copy
        Widget_Control, event.top, /Destroy
        return
     END
     'HELP': BEGIN
        gethelppath,path
        xdisplayfile, path+'spd_ui_wavelet.txt', group=state.gui_id, /modal, done_button='Done', $
                      title='HELP: Wavelet Options'
     END
    ELSE:
  ENDCASE    

  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
end

function spd_ui_wavelet_options, gui_id, dataobj, tr_obj, historyWin, statusBar, varname

  compile_opt idl2
  
  prange = [1.0, 10.0]
  tlb = widget_base(/col, title='Wavelet Options: '+varname, group_leader=gui_id, $
                    /modal, /floating, /base_align_center, /tlb_kill_request_events)

  success = 0b

; Base skeleton          
  mainBase = widget_base(tlb, /col, /align_center, tab_mode=1)
  suffixBase = widget_base(mainBase, /row)
  timeBase = widget_base(mainBase, /col)
  prange0Base = widget_base(mainBase, /row)
  prange1Base = widget_base(mainBase, /row)
  buttonBase = widget_base(mainBase, /row, /align_center)

; Set defaults
  suffix='_wv_pow'

;For prange default, you need dt from the variable, also you want a
;memory check and a jv check
  dataobj -> getvardata, name=varname, time=t
  trange = [tr_obj->getstarttime(), tr_obj->getendtime()]
  sst = where(*t Ge trange[0] And *t Le trange[1], nsst)
  If(nsst Eq 0) Then Begin
     memtest = spd_ui_wv_memory_test(varname, *t, jv, prange, info_txt)
  Endif Else Begin
     memtest = spd_ui_wv_memory_test(varname, (*t)[sst], jv, prange, info_txt)
  Endelse

; Widgets
  infoLabel = widget_label(mainBase, value = 'Variable Memory Test: ')
  infoId = widget_text(mainBase, value = info_txt, uname = 'info', $
                        /scroll, /wrap)

  suffixLabel = widget_label(suffixBase, value = 'Suffix: ')
  suffixId = widget_text(suffixBase, value = suffix, xsize = 22, $
                         uvalue = 'SUFFIX', /editable, /all_events, uname='suffix')

  prange0Label = widget_label(prange0Base, value = 'Min. Period (sec): ')
  prange0Id = widget_text(prange0Base, value = strcompress(/remove_all,prange[0]), xsize = 22, $
                          uvalue = 'PRANGE0', /editable, /all_events, uname='prange0')
  prange1Label = widget_label(prange1Base, value = 'Max. Period (sec): ')
  prange1Id = widget_text(prange1Base, value = strcompress(/remove_all,prange[1]), xsize = 22, $
                          uvalue = 'PRANGE1', /editable, /all_events, uname='prange1')

  trWidget = spd_ui_time_widget(timebase,statusBar,historyWin,timeRangeObj=tr_obj, $
                                uvalue='TIME',uname='time', oneday=0)



; Main window buttons
  okButton = Widget_Button(buttonBase, Value='OK', UVal='OK')
  cancelButton = widget_button(buttonBase, Value='Cancel', UVal='CANCEL')
  helpButton = widget_button(buttonBase, Value='Help', UVal='HELP') 

; Create structure to hold options
  opt_struct = {suffix:suffix, trange:trange, prange:prange, success:success}
  opt_struct_ptr = ptr_new(opt_struct)

  state = {tlb:tlb, gui_id:gui_id, historyWin:historyWin, statusBar:statusBar, $
           tr_obj:tr_obj, opt_struct_ptr:opt_struct_ptr, $
           trwidget:trwidget, varname:varname, tptr:t}

  Centertlb, tlb         
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

  ;keep windows in X11 from snapping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'spd_ui_wavelet_options', tlb, /No_Block
  
  opt_struct = *opt_struct_ptr
  ptr_free, opt_struct_ptr

  RETURN, opt_struct
end
