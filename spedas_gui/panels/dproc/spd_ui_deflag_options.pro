;+
;NAME:
;  spd_ui_deflag_options
;
;PURPOSE:
;  Front end interface allowing the user to select options for deflagging data.
;
;CALLING SEQUENCE:
;  return_values = spd_ui_deflag_options(gui_id, statusbar, historywindow)
;
;INPUT:
;  gui_id: widget id of group leader
;  statusbar: status bar object ref.
;  historywindow: history window object ref.
;
;OUTPUT:
;  return values: anonymous structure containing input parameters for dproc routine
;  {
;   method: Array of flags specifying deflagging method
;           [repeat last value, interpolate(linear), replace with value]
;   opts: Array of flags determining extra options
;         [set flag (default is 6.8792e28), set max gap size]
;   flag: user-specified flag, will be removed in addition to NaNs & infinity
;   maxgap: maximum gap size, in # of points, to be removed
;   fillval: fill value, for replace option
;   suffix: Suffix for new variable
;   ok: Flag indicating success 
;  }
;
;NOTES:
;
;$LastChangedBy: $
;$LastChangedDate: $
;$LastChangedRevision: $
;$URL: $
;-

pro spd_ui_deflag_options_event, event

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
                     /noname,/center, title='Error in Deflag Options')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif

;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    state.historywin->update,'SPD_UI_DEFLAG_OPTIONS: Widget killed', /dontshow
    state.statusbar->update,'Deflag canceled'
    widget_control, event.top, /destroy
    return
  endif

  m = 'Deflag: '

;user value for case statement
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 then begin
    Case uval Of
      'OK': begin
        ;Get method
        for i=0, n_elements(state.method)-1 do begin
          (*state.pvals).method[i] = widget_info(state.method[i],/button_set)
        endfor

        ;Get options
        for i=0, n_elements(state.opts)-1 do begin
          (*state.pvals).opts[i] = widget_info(state.opts[i],/button_set)
        endfor

        ;Get flag if applicable
        if widget_info(state.flag,/sensitive) then begin
          widget_control, state.flag, get_value = flag
          if finite(flag) then begin
            (*state.pvals).flag = flag
          endif else begin
            ok = dialog_message('Invalid flag, please re-enter.', $
                                /center,title='Deflag Error')
            break
          endelse
        endif

        ;Get max gap if applicable
        if widget_info(state.maxgap,/sensitive) then begin
          widget_control, state.maxgap, get_value = maxgap
          if finite(maxgap) && (maxgap ge 1) then begin
            (*state.pvals).maxgap = maxgap
          endif else begin
            ok = dialog_message('Invalid maximum gap, please enter a numeric value greater than or equal to 1.', $
                                /center,title='Deflag Error')
            break
          endelse
        endif

        ;Get fillval if applicable
        if widget_info(state.fillval,/sensitive) then begin
          widget_control, state.fillval, get_value = fillval
          (*state.pvals).fillval = fillval
        endif

        ;Get Suffix
        widget_control, state.suffix, get_value=suffix
        if widget_info(state.includeMeth,/button_set) then begin
           if (*state.pvals).method[0] then suffix += '-repeat' $
           else if (*state.pvals).method[1] then suffix += '-interp' $
           else suffix += '-replace'
        endif
        (*state.pvals).suffix = suffix

        ;Set success flag
        (*state.pvals).ok = 1b

        widget_control, event.top, /destroy
        return
      end

      'CANCEL': begin
        state.historywin->update,'SPD_UI_DEFLAG_OPTIONS: Widget canceled', /dontshow
        state.statusbar->update,'Deflag canceled'
        widget_control, event.top, /destroy
        return
      end

      'FLAGB': widget_control, state.flag, sens = event.select  ;sensitize spinner

      'FLAG': begin ;update status bar 
        if event.valid then state.statusbar->update,m+'Deflag with '+strtrim(event.value,2) $
          else state.statusbar->update,m+'Invalid flag, please re-enter.'
      end

      'MAXGAPB': widget_control, state.maxgap, sens = event.select  ;sensitize spinner

      'MAXGAP': begin ;update status bar
        if event.valid && event.value ge 1 then begin
          state.statusbar->update,m+'Maximum gap set to '+strtrim(event.value,2)+' points'
        endif else state.statusbar->update,m+'Maxmimum gap must be a numeric value greater than or equal to 1.'
      end

      'FILLVALB': widget_control, state.fillval, sens = event.select  ;sensitize spinner

      'FILLVAL': begin ;update status bar 
        if event.valid then state.statusbar->update,m+'Deflag with '+strtrim(event.value,2) $
          else state.statusbar->update,m+'Invalid flag, please re-enter.'
      end

      else: dprint,  'Unkown Uval' ;this should not happen
    Endcase
  endif

  widget_control, event.top, set_uval = state, /no_copy

end

function spd_ui_deflag_options, gui_id, statusbar, historywin

    compile_opt idl2


  catch, _err
  if _err ne 0 then begin
    catch, /cancel
    ok = error_message('Error starting Deflag Options, see console for details.')
    widget_control, tlb, /destroy
    return,{ok:0b}
  endif

;Constants
  maxg = 10000        ;initial maximum gap
  flg = 0d            ;initial flag
  flvl = 0            ;initial fillval
  suffix = '-deflag'

  tlb = widget_base(title = 'Deflag Options', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


;Main bases
  mainBase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)
    methodBase = widget_base(mainbase, /col, ypad=2, /base_align_left)
      methodlabel = widget_label(methodbase, value='Method: ')
      methodbBase = widget_base(methodbase, /row, /exclusive)

    optionsBase = widget_base(mainbase, /row, ypad=2)
      obBase = widget_base(optionsbase, /col, /nonexclusive)
      spBase = widget_base(optionsbase, /col)

    suffixBase = widget_base(mainBase, /row, ypad=8)

    buttonBase = widget_base(mainbase, /row, /align_center, ypad=12)


;Options Widgets
  repeatbutton = widget_button(methodbBase, value='Repeat last value', $
                               tooltip='Repeats the last good value')
  interpbutton = widget_button(methodbBase, value='Interpolate', $
                               tooltip='Uses linear interpolation. The closest'+ $
                               ' value is used near edges. No extrapolation.')
  replacebutton = widget_button(methodbBase, value='Replace with FILLVAL', $
                               tooltip='Replaces with the FILLVAL value')

  flagbutton = widget_button(obBase, value='Set Flag:', uval='FLAGB', $
                             tooltip='The finite value to remove (all values greater than 0.98 of this value will be removed). Default'+ $
                             ' is 6.8792e28 if not set.  NaNs and infinity'+ $
                             ' are always removed.' )
  maxgapbutton = widget_button(obBase, value='Set Maximum Gap:', uval='MAXGAPB', $
                               tooltip='Maximum number of elements'+ $
                               ' that can be filled.')
  fillvalbutton = widget_button(obBase, value='Set FILLVAL:', uval='FILLVALB', $
                                tooltip='Fill Value, default is zero')
  flag = spd_ui_spinner(spBase, value=flg, text_box_size=10, incr=1, sens=0, $
                        uval='FLAG', tooltip='All values greater than 0.98 of this will be removed. Default'+ $
                        ' is 6.8792e28 if not set.  NaNs and infinity are '+ $
                        'always removed.')
  maxgap = spd_ui_spinner(spBase, value=maxg, text_box_size=10, incr=1, sens=0, $
                          uval='MAXGAP', tooltip='Maximum number of elements'+ $
                          ' that can be filled.', min_value=1)
  fillval = spd_ui_spinner(spBase, value=flvl, test_box_size=10, incr=1, sens=0, $
                           uval='FILLVAL', tooltip='Fill Value')

  suffixlabel = widget_label(suffixbase, value = 'Suffix: ')
  suffixtext = widget_text(suffixbase, /editable, xsize=15, value=suffix)
  includeBase = widget_base(suffixbase, /nonexclusive, ypad=0)
  includeMeth = widget_button(includebase, value='Append method')

;Buttons
  ok = widget_button(buttonbase, value = 'OK', uval='OK')
  cancel = widget_button(buttonbase, valu = 'Cancel', uval='CANCEL')

;Initializations
  widget_control, repeatbutton, set_button = 1
  widget_control, includeMeth, set_button = 1
  
  values = {method:[1b,0b,0b], opts:[0b,0b,0b], flag:flg, maxgap:maxg, fillval:flvl, $
            suffix:suffix, ok:0b}

  pvals = ptr_new(values)

  state = {tlb:tlb, gui_id:gui_id, statusbar:statusbar, historywin:historywin, $
           method:[repeatbutton, interpbutton, replacebutton], $
           opts:[flagbutton, maxgapbutton, fillvalbutton], $
           flag:flag, maxgap:maxgap, fillval:fillval, suffix:suffixtext, $
           includeMeth:includeMeth, pvals:pvals}

  centertlb, tlb

  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_deflag_options', tlb, /no_block


;Return adjusted values
  values= *pvals
  ptr_free, pvals

  widget_control, /hourglass

  Return, values

end
