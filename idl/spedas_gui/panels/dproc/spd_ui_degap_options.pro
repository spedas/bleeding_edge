;+
;NAME:
;  spd_ui_degap_options
;
;PURPOSE:
;  Front end interface allowing the user to select options for degapping data.
;
;CALLING SEQUENCE:
;  return_values = spd_ui_degap_options(gui_id, statusbar, historywindow)
;
;INPUT:
;  gui_id: widget id of group leader
;  statusbar: status bar object ref.
;  historywindow: history window object ref.
;
;OUTPUT:
;  return values: anonymous structure containing input parameters for dproc routine
;  {
;   dt: Interval passed to degap routine
;   margin: degap margin
;   opts: Array of flags determining extra options
;         [set degap flag, set max gap size]
;   flag: User-specified flag to fill gaps with, uses NaNs if not set
;   maxgap: Maximum gap size to be removed, uses total range of data if not set 
;   suffix: Suffix for new variable
;   ok: Flag indicating success 
;  }
;
;NOTES:
;  (Gaps are removed were greater than dt+margin and less than maxgap)
;  
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;-

pro spd_ui_degap_options_event, event

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
                     /noname,/center, title='Error in Degap Options')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif

;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    state.historywin->update,'SPD_UI_DEGAP_OPTIONS: Widget killed', /dontshow
    state.statusbar->update,'Degap canceled'
    widget_control, event.top, /destroy
    return
  endif

  m = 'Degap: '

;user value for case statement
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 then begin
    Case uval Of
      'OK': begin
        ;Get interval
        widget_control, state.interval, get_value = interval
        if finite(interval) && (interval gt 0) then begin
          (*state.pvals).dt = interval
        endif else begin
          ok = dialog_message('Invalid interval, please enter a numeric value greater than 0.', $
                                /center,title='Degap Error')
          break
        endelse

        ;Get margin
        widget_control, state.margin, get_value = margin
        if finite(margin) && (margin gt 0) then begin
          (*state.pvals).margin = margin
        endif else begin
          ok = dialog_message('Invalid margin, please enter a numeric value greater than 0.', $
                                /center,title='Degap Error')
          break
        endelse

        ;Get extra options
        for i=0, n_elements(state.opts)-1 do begin
          (*state.pvals).opts[i] = widget_info(state.opts[i],/button_set)
        endfor

        ;Get flag if applicable
        if widget_info(state.flag,/sensitive) then begin
          widget_control, state.flag, get_value = flag
          if finite(flag) then begin
            (*state.pvals).flag = flag
          endif else begin
            ok = dialog_message('Invalid flag, please re-enter', $
                                /center,title='Degap Error')
            break
          endelse
        endif

        ;Get max gap if applicable
        if widget_info(state.maxgap,/sensitive) then begin
          widget_control, state.maxgap, get_value = maxgap
          if finite(maxgap) && (maxgap ge 1) then begin
            (*state.pvals).maxgap = maxgap
          endif else begin
            ok = dialog_message('Invalid maximum gap, enter a numeric value greater than or equal to 1.', $
                                /center,title='Degap Error')
            break
          endelse
        endif

        ;Get Suffix
        widget_control, state.suffix, get_value=suffix
        (*state.pvals).suffix = suffix

        ;Set success flag
        (*state.pvals).ok = 1b

        widget_control, event.top, /destroy
        return
      end

      'CANCEL': begin
        state.historywin->update,'SPD_UI_DEGAP_OPTIONS: Widget canceled', /dontshow
        state.statusbar->update,'Degap canceled'
        widget_control, event.top, /destroy
        return
      end

      'INTERVAL': begin ;update status bar 
        if event.valid && event.value gt 0 then begin
          state.statusbar->update,m+'Time interval set to '+strtrim(event.value,2)+' seconds'
        endif else state.statusbar->update,m+'Time interval must be a numeric value greater than 0.'
      end

      'MARGIN': begin ;update status bar
        if event.valid && event.value gt 0 then begin
          state.statusbar->update,m+'Margin set to '+strtrim(event.value,2)+' seconds'
        endif else state.statusbar->update,m+'Margin must be a numeric value greater than 0.'
      end

      'FLAGB': widget_control, state.flag, sens = event.select  ;sensitize spinner

      'FLAG': begin ;update status bar 
        if event.valid then state.statusbar->update,m+'Filling gaps with '+strtrim(event.value,2) $
          else state.statusbar->update,m+'Flag must be a numeric value.'
      end

      'MAXGAPB': widget_control, state.maxgap, sens = event.select  ;sensitize spinner

      'MAXGAP': begin ;update status bar
        if event.valid && event.value ge 1 then begin
          state.statusbar->update,m+'Maximum gap set to '+strtrim(event.value,2)+' points'
        endif else state.statusbar->update,m+'Maxmimum gap must be a numeric value greater than or equal to 1.'
      end
      
      else: dprint,  'Unknown Uval' ;this should not happen
    Endcase
  endif

  widget_control, event.top, set_uval = state, /no_copy

end

function spd_ui_degap_options, gui_id, statusbar, historywin

    compile_opt idl2


  catch, _err
  if _err ne 0 then begin
    catch, /cancel
    ok = error_message('Error starting Degap Options, see console for details.')
    widget_control, tlb, /destroy
    return,{ok:0b}
  endif

;Constants
  intrvl = 1d         ;initial interval (sec)
  mrgn = .25d         ;initial margin (sec)
  maxg = 10000d       ;initial maximum gap (sec)
  flg = 0d            ;initial flag
  suffix = '-degap'

  tlb = widget_base(title = 'Degap Options', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


;Main bases
  mainBase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)

    timesBase = widget_base(mainbase, /col, ypad=4)

    optionsBase = widget_base(mainbase, /row, ypad=2)
      obBase = widget_base(optionsbase, /col, /nonexclusive)
      spBase = widget_base(optionsbase, /col)

    suffixBase = widget_base(mainBase, /row, ypad=8)

    buttonBase = widget_base(mainbase, /row, /align_center, ypad=12)


;Options Widgets
  interval = spd_ui_spinner(timesBase, value=intrvl, text_box_size=10, incr=1, $
                            label='Time Interval (sec):  ', getxlabelsize=xlsize, $
                            uval='INTERVAL',tooltip='dt is the time interval for tests', min_value=0)

  margin = spd_ui_spinner(timesBase, value=mrgn, text_box_size=10, incr=.05, $
                          label='Margin (sec): ', xlabelsize=xlsize, $
                          uval='MARGIN',tooltip='Minimum gap to be removed is (dt+margin)', min_value=0)

  flagbutton = widget_button(obBase, value='Set Flag:', uval='FLAGB', $
                             tooltip='Value to fill gaps with. Uses '+ $
                             'NaNs if not set')
  maxgapbutton = widget_button(obBase, value='Set Maximum Gap (sec):', uval='MAXGAPB', $
                               tooltip='Maximum length of gap to remove, in seconds')
    flag = spd_ui_spinner(spBase, value=flg, text_box_size=10, incr=1, sens=0, $
                          uval='FLAG')
    maxgap = spd_ui_spinner(spBase, value=maxg, text_box_size=10, incr=1, sens=0, $
                            uval='MAXGAP', min_value=1)

  suffixlabel = widget_label(suffixbase, value = 'Suffix: ')
  suffixtext = widget_text(suffixbase, /editable, xsize=15, value=suffix)


;Buttons
  ok = widget_button(buttonbase, value = 'OK', uval='OK')
  cancel = widget_button(buttonbase, valu = 'Cancel', uval='CANCEL')



;Initializations
  
  values = {dt:intrvl, margin:mrgn, opts:[0b,0b], flag:flg, maxgap:maxg, suffix:suffix, ok:0b}

  pvals = ptr_new(values)

  state = {tlb:tlb, gui_id:gui_id, statusbar:statusbar, historywin:historywin, $
           interval:interval, margin:margin, opts:[flagbutton, maxgapbutton], $
           flag:flag, maxgap:maxgap, suffix:suffixtext, $
           pvals:pvals}

  centertlb, tlb

  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_degap_options', tlb, /no_block


;Return adjusted values
  values= *pvals
  ptr_free, pvals

  widget_control, /hourglass

  Return, values

end
