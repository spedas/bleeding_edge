

pro spd_ui_block_ave_options_event, event

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
                     /noname,/center, title='Error in Block Average Options')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif

;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    state.historywin->update,'SPD_UI_BLOCK_AVE_OPTIONS: Widget killed', /dontshow
    state.statusbar->update,'Block Average canceled'
    widget_control, event.top, /destroy
    return
  endif

  m = 'Block Average: '

;user value for case statement
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 then begin
    Case uval Of
      'OK': begin
        ;Get Resolution
        widget_control, state.res, get_value=res
        if finite(res) && (res gt 0) then begin
          (*state.pvals).dt = res
        endif else begin
          ok = dialog_message('Invalid resolution, please enter a numeric value greater than 0.', $
                              /center,title='Block Average Error')
          break
        endelse

        widget_control, state.trange, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
        if (~valid) then begin
          result = dialog_message('Invalid time range inputed. Use format: YYYY-MM-DD/hh:mm:ss',/center)
          break
        endif       

        ; Check for time range limits
        timeid = widget_info(event.top, find_by_uname='time')
        widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
        
        customset = widget_info(state.timebase,/sensitive) 
        if customset && valid then begin ;custom time interval was set and we have a valid trange object
            ; update the time range object
            spd_ui_time_widget_update, timeid
            tobj = spd_ui_time_widget_get_value(timeid)
            ; update the trange object in the values struct
            (*state.pvals).trange = tobj
            (*state.pvals).limit = widget_info(state.timebase,/sensitive)
        endif
        
        ;Get Suffix
        widget_control, state.suffix, get_value=suffix
        if widget_info(state.includeRes,/button_set) then begin
           if (*state.pvals).dt lt 1. then $
             suffix += '-'+strcompress(/remove_all, (*state.pvals).dt) $
           else suffix += '-'+strcompress(/remove_all, long((*state.pvals).dt))
        endif
        (*state.pvals).suffix = suffix

        ;Set success flag
        (*state.pvals).ok = 1b

        widget_control, event.top, /destroy
        return
      end

      'CANCEL': begin
        state.historywin->update,'SPD_UI_BLOCK_AVE_OPTIONS: Widget canceled', /dontshow
        state.statusbar->update,'Block Average canceled'
        widget_control, event.top, /destroy
        return
      end

      'RES': begin
        if event.valid && event.value gt 0 then state.statusbar->update, $
          m+'Using '+strtrim(event.value,2)+' sec resolution.' $
        else state.statusbar->update,m+'Resolution must be a numeric value greater than 0.' 

      end
      'LIMIT': begin
        widget_control, state.timebase, sens = event.select
      end
    Endcase
  endif

  widget_control, event.top, set_uval = state, /no_copy

end





function spd_ui_block_ave_options, gui_id, statusbar, historywin, datap

    compile_opt idl2


  catch, _err
  if _err ne 0 then begin
    catch,/cancel
    ok = error_message('Error starting Block Average Options, see console for details.')
    widget_control, tlb, /destroy
    return,{ok:0}
  endif

;Constants
  res = 60d       ;default resolution
  suffix = '-av'  ;default suffix

  tlb = widget_base(title = 'Block Average Options', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


;Main bases
  mainbase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)
    resBase = widget_base(mainbase, /row)

    timelabelBase = widget_base(mainbase, /row, /nonexclusive)
    timeBase = widget_base(mainbase, /col, fram=1, sensitive=0)

    suffixBase = widget_base(mainBase, /row, ypad=8)

    buttonBase = widget_base(mainbase, /row, /align_center, ypad=12)


;Options Widgets
  resolution = spd_ui_spinner(resbase, label = 'Time Resolution (sec):  ', $
                              text_box_size=10, uval='RES', value=res, incr=1, min_value=0)

  timebutton = widget_button(timelabelbase, value='Limit time range.', uval='LIMIT',$
        tooltip='The averaged variables will be clipped to the selected interval.')
  time = spd_ui_time_widget(timebase, statusbar, historywin, oneday=0b, uname='time')

  suffixlabel = widget_label(suffixBase, value = 'Suffix: ')
  suffixtext = widget_text(suffixbase, /all_events, /editable, tab_mode=1, xsize=15, $
                         value=suffix)
  includeBase = widget_base(suffixbase, /nonexclusive, ypad=0)
    includeRes = widget_button(includebase, value='Append Resolution')


;Buttons
  ok = widget_button(buttonbase, value = 'OK', xsize=60, uval='OK')
  cancel = widget_button(buttonbase, valu = 'Cancel', xsize=60, uval='CANCEL')


;Initializations
  widget_control, includeRes, set_button = 1

  ;time range widget 
  active_data = (*datap)->getactive()

  for i=0, n_elements(active_data)-1 do begin
    (*datap)->getvardata, name=active_data[i], trange=trange
    if ~undefined(trange) then break
  endfor

  ;create new time range object
  if ~undefined(trange) then begin
    tr = obj_new('SPD_UI_TIME_RANGE')
    ok = tr->SetStartTime(trange[0])
    ok = tr->setendtime(trange[1])
    widget_control, time, set_value=tr 
  endif else tr = obj_new('SPD_UI_TIME_RANGE')

  values = {dt:res, trange:tr, limit:0b, suffix:suffix, ok:0b}

  pvals = ptr_new(values)

  state = {tlb:tlb, gui_id:gui_id, statusbar:statusbar, historywin:historywin, $
           res:resolution, timebase:timebase, timebutton:timebutton, trange:time, $
           suffix:suffixtext, includeRes:includeRes, $
           pvals:pvals}

  centertlb, tlb

  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_block_ave_options', tlb, /no_block


;Return adjusted values
  values= *pvals
  ptr_free, pvals

  widget_control, /hourglass

  Return, values

end
