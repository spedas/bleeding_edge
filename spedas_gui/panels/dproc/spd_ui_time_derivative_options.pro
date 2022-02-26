;+
;NAME:
;  spd_ui_time_derivative_options
;
;PURPOSE:
;  Front end interface allowing the user to select options for performing time derivatives on data.
;
;CALLING SEQUENCE:
;  return_values = spd_ui_time_derivative_options(gui_id, statusbar, historywindow)
;
;INPUT:
;  gui_id: widget id of group leader
;  statusbar: status bar object ref.
;  historywindow: history window object ref.
;
;OUTPUT:
;  return values: anonymous structure containing input parameters for dproc routine
;  {
;   swidth: Width of smoothing window, see IDL documentation on smooth() for more info
;   setswidth: Flag indicating whether data is to be smoothed
;   suffix: Suffix for new variable
;   ok: Flag indicating success
;  }
;
;NOTES:
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;-
pro spd_ui_time_derivative_options_event, event

    compile_opt idl2, hidden
  
  widget_control, event.top, get_uval=state, /no_copy
  
;error catch block
  catch, on_err
  if on_err ne 0 then begin
    catch, /cancel
    help, /last_message, output=msg
    if is_struct(state) then begin
      for i=0, n_elements(msg)-1 do state.historywin->update,msg[i]
      gui_id = state.gui_id
      hwin = state.historywin
    endif
    print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted, see console for details.', $
                     /noname,/center, title='Error in Time Derivative Options')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif

;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    state.historywin->update,'SPD_UI_TIME_DERIVATIVE_OPTIONS: Widget killed', /dontshow
    state.statusbar->update,'Time derivative canceled'
    widget_control, event.top, /destroy
    return
  endif

  m = 'Time Derivative: '

;get user value
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 then begin
    Case uval Of
      'OK':begin
        ;Get smoothing width
        if widget_info(state.swidth,/sensitive) then begin
          widget_control, state.swidth, get_value=swidth
          if finite(swidth) && (swidth gt 0) then begin
            (*state.pvals).swidth = swidth
            (*state.pvals).setswidth = 1b
          endif else begin
            ok = dialog_message('Invalid smoothing width, please enter a numeric value greater than 0.', $
                                /center,title='Time Derivative Error')
            break
          endelse
        endif

        ;Get suffix
        widget_control, state.suffix, get_value = suffix
        (*state.pvals).suffix = suffix

        ;Set success flag
        (*state.pvals).ok = 1b
        
        widget_control, event.top, /destroy
        return
      end
      'CANCEL': begin
        state.historywin->update,'SPD_UI_TIME_DERIVATIVE_OPTIONS: Cancelled', /dontshow
        state.statusbar->update,'Time derivative canceled'
        widget_control, event.top, /destroy
        return
      end
      'SMOOTHB': begin
        widget_control, state.swidth, sens=event.select
      end
      'SMOOTH': begin
        if event.valid && event.value gt 0 then state.statusbar->update, $
          m+'Smoothing window set to '+strtrim(event.value,2)+' points.' $
        else state.statusbar->update,'Smoothing window must be a numeric value greater than 0.'
      end
      else: 
    Endcase
  endif

  widget_control, event.top, set_uval = state, /no_copy

end


function spd_ui_time_derivative_options, gui_id, statusbar, historywin

    compile_opt idl2


  catch, _err
  if _err ne 0 then begin
    catch, /cancel
    ok = error_message('Error starting Time Derivative Options, see console for details.')
    widget_control, tlb, /destroy
    return,{ok:0}
  endif

;Constants
  swidth = 50d      ;default smoothing width
  suffix = '-ddt'    ;default suffix

  tlb = widget_base(title = 'Time Derivative Options', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


;Main bases
  mainbase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)
    smoothBase = widget_base(mainbase, /col, ypad=4)

    nameBase = widget_base(mainbase, /row, ypad=4)

    buttonBase = widget_base(mainbase, /row, /align_center, ypad=10)

;Options widgets
  smoothbBase = widget_base(smoothBase,/row,/nonexclusive,xpad=0,ypad=0,space=0)
    smoothbutton = widget_button(smoothbBase, value='Apply Smoothing', uval='SMOOTHB', $
                                 tooltip='Smooth data before taking derivative')
  smoothwidth = spd_ui_spinner(smoothBase,value=swidth,text_box_size=10,uval='SMOOTH', $
                               tooltip='The width of the smoothing window, in elements', $
                               label='   Smoothing Width(# Pts): ', incr=1, sens=0, min_value=0)

  suffixlabel = widget_label(nameBase, value='Suffix: ')
  suffixtext = widget_text(nameBase, value=suffix , /editable, xsize=15)

;Buttons
  ok = widget_button(buttonbase, value = 'OK', uval='OK')
  cancel = widget_button(buttonbase, valu = 'Cancel', uval='CANCEL')


;Initializations
  values = {swidth:swidth, setswidth:0b, suffix:suffix, ok:0b}

  pvals = ptr_new(values)

  state = {tlb:tlb, gui_id:gui_id, statusbar:statusbar, historywin:historywin, $
           sbutton:smoothbutton, swidth:smoothwidth, suffix:suffixtext, $
           pvals:pvals}

  centertlb, tlb

  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_time_derivative_options', tlb, /no_block

;Return adjusted values
  values= *pvals
  ptr_free, pvals

  widget_control, /hourglass

  Return, values

end
