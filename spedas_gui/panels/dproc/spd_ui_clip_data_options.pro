;+
;NAME:
;  spd_ui_clip_data_options
;
;PURPOSE:
;  Front end interface allowing the user to select options for clipping data.
;
;CALLING SEQUENCE:
;  return_values = spd_ui_clip_data_options(gui_id, statusbar, historywindow)
;
;INPUT:
;  gui_id: widget id of group leader
;  statusbar: status bar object ref.
;  historywindow: history window object ref.
;
;OUTPUT:
;  return values: anonymous structure containing input parameters for dproc routine
;  {
;   maxc: maximum value for clipping
;   minc: minimum value for clipping
;   opts: Array of flags determining extra options
;         [clip adjacent points, insert user-specified flag (instead of NaNs)]
;   flag: user-specified flag, a double to be insterted where values are clipped
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

pro spd_ui_clip_data_options_event, event

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
                     /noname,/center, title='Error in Clip Data Options')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif

;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    state.historywin->update,'SPD_UI_clip_DATA_OPTIONS: Widget killed', /dontshow
    state.statusbar->update,'Clip Data canceled'
    widget_control, event.top, /destroy
    return
  endif

  m = 'Clip Data: '

;user value for case statement
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 then begin
    Case uval Of
      'OK': begin
        ;Get max & min
        widget_control, state.maxclip, get_value=maxc
        widget_control, state.minclip, get_value=minc

        if finite(maxc) then begin ;check max value
          (*state.pvals).maxc = maxc
        endif else begin
          ok = dialog_message('Invalid maximum, please re-enter', $
                              /center, title='Clip Data Error')
          break
        endelse

        if finite(minc) then begin ;check min value
          (*state.pvals).minc = minc
        endif else begin
          ok = dialog_message('Invalid minimum, please re-enter', $
                              /center, title='Clip Data Error')
          break
        endelse

        if maxc le minc then begin ;check that max > min
          ok = dialog_message('Maximum must be greater than minimum, please re-enter', $
                              /center, title='Clip Data Error')
          break
        endif

        ;Clip adjacent?
        (*state.pvals).opts[0] = widget_info(state.clipadj,/button_set)

        ;Set Flag option
        (*state.pvals).opts[1] = widget_info(state.flagb[0],/button_set)
          
        ;Get flag if applicable
        if (*state.pvals).opts[1] then begin
          widget_control, state.flag, get_value=flag
          if finite(flag) then begin
            (*state.pvals).flag = flag
          endif else begin
            ok = dialog_message('Invalid flag, please re-enter', $
                                /center, title='Clip Data Error')
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
        state.historywin->update,'Clip Data Options Cancelled', /dontshow
        state.statusbar->update,'Clip Data canceled'
        widget_control, event.top, /destroy
        return
      end

      'MAX': begin ;update status bar
        if event.valid then state.statusbar->update,m+'Maximum set to '+strtrim(event.value,2)+'.' $
        else state.statusbar->update,m+'Invalid maximum, please re-eneter.'
      end

      'MIN': begin ;update status bar
        if event.valid then state.statusbar->update,m+'Minimum set to '+strtrim(event.value,2)+'.' $
        else state.statusbar->update,m+'Invalid minimum, please re-enter.'
      end

      'FLAGB': begin ;sensitize/desensitize flag spinner
        widget_control, state.flag, sens = widget_info(state.flagb[0],/button_set)
      end

      'FLAG': begin ;update status bar
        if event.valid then state.statusbar->update,m+'Inserting '+strtrim(event.value,2)+'.' $
        else state.statusbar->update,m+'Invalid flag, please re-eneter.'
      end

      else: dprint,  'Unkown Uval' ;this should not happen
    endcase
  endif

widget_control, event.top, set_uval = state

end


function spd_ui_clip_data_options, gui_id, statusbar, historywin

    compile_opt idl2


  catch, _err
  if _err ne 0 then begin
    catch, /cancel
    ok = error_message('Error starting Clip Data Options, see console for details.')
    widget_control, tlb, /destroy
    return,{ok:0}
  endif

;Constants
  minc = -20d      ;default min
  maxc = 20d       ;default max
  flg = 0d         ;default flag
  suffix = '-clip'

  tlb = widget_base(title = 'Clip Data Options', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


;Main bases
  mainBase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)
    maxminBase = widget_base(mainbase, /col, ypad=4)

    clipBase = widget_base(mainbase, /row, ypad=2, /nonexclusive)

    flagBase = widget_base(mainbase, /row, ypad=2)

    suffixBase = widget_base(mainBase, /row, ypad=8)

    buttonBase = widget_base(mainbase, /row, /align_center, ypad=12)


;Options Widgets
  minclip = spd_ui_spinner(maxminbase, value=minc, text_box_size=10, incr=1, $
                           uval='MIN', label='Minimum for Clip:  ', getxlabelsize=xlsize, $
                           tooltip='Values less than the minimum will be clipped')
  maxclip = spd_ui_spinner(maxminbase, value=maxc, text_box_size=10, incr=1, $
                           uval='MAX', label='Maximum for Clip:  ', xlabelsize=xlsize, $
                           tooltip='Values greater than the maximum will be clipped')

  clipadj = widget_button(clipBase, value='Clip Adjacent Points', $
                          tooltip='Clip values adjacent to those outside (min,max)')

  flagbbase = widget_base(flagBase, /col, /exclusive, ypad=0,xpad=0,space=0)
    insertbutton = widget_button(flagbbase, value='Insert Flag: ', uval='FLAGB', $
                                 tooltip='Replace clipped values with a user'+ $
                                         ' specified value') 
    nanbutton = widget_button(flagbbase, value='Insert NaNs', uval='FLAGB', $
                              tooltip='Replace clipped values with NaNs')
  flag = spd_ui_spinner(flagBase, value=0, text_box_size=10, incr=1, $
                        uvla='FLAG', label='', sens=0)

  suffixlabel = widget_label(suffixbase, value = 'Suffix: ')
  suffixtext = widget_text(suffixbase, /editable, xsize=15, value=suffix)


;Buttons
  ok = widget_button(buttonbase, value = 'OK', uval='OK')
  cancel = widget_button(buttonbase, valu = 'Cancel', uval='CANCEL')


;Initializations
  widget_control, nanbutton, set_button=1

  values = {maxc:maxc, minc:minc, opts:[0b,1b], flag:flg, suffix:suffix, ok:0b}

  pvals = ptr_new(values)

  state = {tlb:tlb, gui_id:gui_id, statusbar:statusbar, historywin:historywin, $
           maxclip:maxclip, minclip:minclip, $
           clipadj:clipadj, flagb:[insertbutton,nanbutton], flag:flag, $
           suffix:suffixtext, $
           pvals:pvals}

  centertlb, tlb

  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_clip_data_options', tlb, /no_block


;Return adjusted values
  values= *pvals
  ptr_free, pvals

  widget_control, /hourglass

  Return, values

end
