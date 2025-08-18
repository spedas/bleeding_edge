;+
;NAME:
;  spd_ui_high_pass_options
;
;PURPOSE:
;  Front end interface allowing the user to select high pass filter options.
;
;CALLING SEQUENCE:
;  return_values = spd_ui_high_pass_options(gui_id, statusbar, historywindow)
;
;INPUT:
;  gui_id: widget id of group leader
;  statusbar: status bar object ref.
;  historywindow: history window object ref.
;
;OUTPUT:
;  return values: anonymous structure containing input parameters for dproc routine
;  {
;   dt: Time Resolution for smoothing
;   icad: Interpolation cadence (not used by default)
;   setICad: Flag to use interpolation cadence
;   suffix: Suffix for new variable
;   ok: Flag indicating success 
;  }
;
;NOTES:
;  Options for the high pass filter are only used by smooth_in_time.pro to get
;  the running average for calculation.  Since the call to smooth_in_time 
;  contains specific keywords some smoothing options are not available.
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;-

pro spd_ui_high_pass_options_event, event

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
    ok=error_message('An unknown error occured and the window must be restarted, '+ $
                     'see console for details.',/noname,/center, $
                     title='Error in High Pass Filter Options')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif

;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    state.historywin->update,'SPD_UI_HIGH_PASS_OPTIONS: Widget killed', /dontshow
    state.statusbar->update,'High Pass Filter canceled'
    widget_control, event.top, /destroy
    return
  endif

  m = 'High Pass Filter: '

;user value for case statement
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 then begin
    Case uval Of
      'OK': begin
        ;Get resolution
        widget_control, state.ave, get_value = ave
        if finite(ave) && (ave gt 0) then begin
          (*state.pvals).dt = ave
        endif else begin
          ok = dialog_message('Invalid averaging time, please enter a numeric value greater than 0.', $
                              /center,title='High Pass Filter Error')
           break
        endelse

        ;Get interpolation cadence
        if widget_info(state.icad, /sensitive) then begin
          widget_control, state.icad, get_value = icad
          if finite(icad) && (icad gt 0) then begin
            (*state.pvals).icad = icad
            (*state.pvals).seticad = 1b
          endif else begin
            ok = dialog_message('Invalid interpolation cadence, please enter a numeric value greater than 0.', $
                                /center,title='High Pass Filter Error')
            break
          endelse
        endif

        ;Get suffix
        widget_control, state.suffix, get_value = suffix
        if widget_info(state.includeAve, /button_set) then begin
          if (*state.pvals).dt lt 1d then suffix += strcompress(/remove_all, (*state.pvals).dt) $
            else suffix += strcompress(/remove_all, long((*state.pvals).dt))
        endif
        (*state.pvals).suffix = suffix

        ;Set success flag
        (*state.pvals).ok = 1b

        widget_control, event.top, /destroy
        return
      end

      'CANCEL': begin
        state.historywin->update,'SPD_UI_HIGH_PASS_OPTIONS: Widget canceled', /dontshow
        state.statusbar->update,'High Pass Filter canceled'
        widget_control, event.top, /destroy
        return
      end

      'AVE': begin ;update status bar
        if event.valid && event.value gt 0 then state.statusbar->update, $
          m+'Averaging set to '+strtrim(event.value,2)+' seconds' $
        else state.statusbar->update,'Averaging time must be a numeric value greater than 0.' 
      end

      'ICAD': begin ;update status bar
        if event.valid && event.value gt 0 then state.statusbar->update, $
          m+'Interpolation cadence set to '+strtrim(event.value,2)+' seconds' $
        else state.statusbar->update,'Interpolation cadence must be a numeric value greater than 0.'
      end

      'IBUTTON': begin ;sensitize itrp cadence spinner
        widget_control, state.icad, sens=event.select
      end
    Endcase
  endif

  widget_control, event.top, set_uval = state, /no_copy

end

function spd_ui_high_pass_options, gui_id, statusbar, historywin

    compile_opt idl2


  catch, _err
  if _err ne 0 then begin
    catch, /cancel
    ok = error_message('Error starting High Pass filter Options, see console for details.')
    widget_control, tlb, /destroy
    return,{ok:0}
  endif

;Constants
  ave = 60d      ;default resolution
  icad = 3d      ;default interpolate cadence
  suffix = '-hpf'

  tlb = widget_base(title = 'High Pass Filter Options', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


;Main bases
  mainBase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)
    aveBase = widget_base(mainbase, /row, ypad=4)

    interpBase = widget_base(mainbase, /row, ypad=2)

    optionsBase = widget_base(mainbase, /col, /nonexclusive)

    suffixBase = widget_base(mainBase, /row, ypad=8)

    buttonBase = widget_base(mainbase, /row, /align_center, ypad=12)


;Options Widgets
  averageRes = spd_ui_spinner(avebase, label='Averaging Time (sec): ', incr=1, $
                              text_box_size=10, uval='AVE', value=ave, $
                              tooltip='Interval over which to average', min_value=0)

  itrpButtonBase = widget_base(interpBase, /nonexclusive,xpad=0,ypad=0,space=0)
    itrpButton = widget_button(itrpButtonBase, value='Set Interpolation Cadence (sec): ', $
                               uval='IBUTTON', tooltip='By default the data is '+ $
                               'interpolated to its minimum resolution.')
  itrpCadence = spd_ui_spinner(interpBase, text_box_size=10, uval='ICAD', $
                               value=icad, incr=1, sens=0, min_value=0)

  suffixlabel = widget_label(suffixbase, value = 'Suffix: ')
  suffixtext = widget_text(suffixbase, /editable, xsize=15, value=suffix)
  includeBase = widget_base(suffixbase, /nonexclusive, ypad=0)
    includeAve = widget_button(includebase, value='Append Average')

;Buttons
  ok = widget_button(buttonbase, value = 'OK', uval='OK')
  cancel = widget_button(buttonbase, valu = 'Cancel', uval='CANCEL')

;Initializations
  widget_control, includeAve, set_button=1

  values = {dt:ave, icad:icad, seticad:0b, suffix:suffix, ok:0b}

  pvals = ptr_new(values)

  state = {tlb:tlb, gui_id:gui_id, statusbar:statusbar, historywin:historywin, $
           ave:averageRes, icad:itrpCadence, ibase:interpBase, $
           suffix:suffixtext, includeAve:includeAve, $
           pvals:pvals}

  centertlb, tlb

  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_high_pass_options', tlb, /no_block

;Return adjusted values
  values= *pvals
  ptr_free, pvals

  widget_control, /hourglass

  Return, values

end

