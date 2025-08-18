;+
;NAME:
;  spd_ui_smooth_data_options
;
;PURPOSE:
;  Front end interface allowing the user to select options for smoothing data.
;
;CALLING SEQUENCE:
;  return_values = spd_ui_smooth_data_options(gui_id, statusbar, historywindow)
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
;   dttype: Array of flags determining how smoothing is applied [default,forward,backward]
;   opts: Array of flags determining extra options [no_time_intrp,true_t_integtration,smooth_nans]
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

pro spd_ui_smooth_data_options_event, event

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
                     /noname,/center, title='Error in Smooth Data Options')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif

;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    state.historywin->update,'SPD_UI_SMOOTH_DATA_OPTIONS: Widget killed', /dontshow
    state.statusbar->update,'Smooth Data canceled'
    widget_control, event.top, set_uval=state, /no_copy
    widget_control, event.top, /destroy
    return
  endif

  m = 'Smooth Data: '

;user value for case statement
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 then begin
    Case uval Of
      'OK': begin
        ; Check if the user selected No Time Interpolation
        ; if so, warn them that this is computationally intensive and may cause IDL to go unresponsive for a long time
        not_interp = widget_info(state.tlb, find_by_uname='ibutton')
        dotimeinterp = widget_info(not_interp, /sensitive)
        if dotimeinterp eq 0 then begin
            yesno = dialog_message('No Time Interpolation selected - this can be very slow and may cause IDL to become unresponsive. Are you sure you would like to continue?', $
                title='Warning: operation may take a long time', /center, /question)
            if yesno eq 'No' then break
        endif
        
        ;Get Resolution
        widget_control, state.res, get_value=res
        if finite(res) && (res gt 0) then (*state.pvals).dt = res $
          else begin
            ok = dialog_message('Invalid resolution, please enter a numeric value greater than 0.', $
                                /center,title='Smooth Data Error')
            break
          endelse

        ;Get Interpolation Cadence
        if widget_info(state.icad, /sensitive) then begin
          widget_control, state.icad, get_value=icad
          if finite(icad) && (icad gt 0) then begin
            (*state.pvals).icad = icad
            (*state.pvals).setICad = 1b
          endif else begin
              ok = dialog_message('Invalid cadence, please enter a numeric value greater than 0.', $
                                  /center,title='Smooth Data Error')
              break
            endelse
        endif

        ;Get Type
        for i=0, n_elements(state.dttype)-1 do begin
          (*state.pvals).dttype[i] = widget_info(state.dttype[i],/button_set)
        endfor
          
        ;Get Options
        for i=0, n_elements(state.opts)-1 do begin
          (*state.pvals).opts[i] = (widget_info(state.opts[i],/button_set) && $
                                    widget_info(state.opts[i],/sensitive) )
        endfor

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
        state.historywin->update,'Smooth Data Options Cancelled', /dontshow
        state.statusbar->update,'Smooth Data canceled'
        widget_control, event.top, set_uval=state, /no_copy
        widget_control, event.top, /destroy
        return
      end

      'RES': begin
        if event.valid && event.value gt 0 then state.statusbar->update, $
          m+'Using '+strtrim(event.value,2)+' sec resolution.' $
        else state.statusbar->update,m+'Resolution must be a numeric value greater than 0.' 
      end 

      'ICAD': begin
        if event.valid && event.value gt 0 then state.statusbar->update, $
          m+'Interpolation cadence set to '+strtrim(event.value,2)+' sec resolution.' $
        else state.statusbar->update,m+'Interpolation cadence must be a numeric value greater than 0.' 
      end

      'IBUTTON': begin
        widget_control, state.icad, sens=event.select
      end

      'NOT': begin
        ;these options have not been implemented with no_time_interp set
        widget_control, state.opts[1], sens = ~event.select
        widget_control, state.opts[2], sens = ~event.select 
        widget_control, state.ibase, sens = ~event.select
      end

      else: dprint,  'Unknown Uval' ;this should not happen
    endcase
  endif

widget_control, event.top, set_uval = state

end

function spd_ui_smooth_data_options, gui_id, statusbar, historywin

    compile_opt idl2


  catch, _err
  if _err ne 0 then begin
    catch, /cancel
    ok = error_message('Error starting Smooth Data Options, see console for details.')
    widget_control, tlb, /destroy
    return,{ok:0}
  endif

;Constants
  res = 61d      ;initial resolution
  icad = 3d      ;initial interpolate cadence
  suffix = '-sm'

  tlb = widget_base(title = 'Smooth Data Options', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


;Main bases
  mainbase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)
    resBase = widget_base(mainbase, /row)

    typeBase = widget_base(mainbase, /row, /exclusive, ypad=4)

    interpBase = widget_base(mainbase, /row, ypad=2)

    optionsBase = widget_base(mainbase, /col, /nonexclusive)

    nameBase = widget_base(mainBase, /row, ypad=8)

    buttonBase = widget_base(mainbase, /row, /align_center, ypad=12)


;Options Widgets
  resolution = spd_ui_spinner(resbase, label = 'Smoothing Resolution(sec):  ', $
                              text_box_size=10, uval='RES', value=res, incr=1, $
                              tooltip='Interval over which to average', min_value=0)

  dttype = lonarr(3)
    dttype[0] = widget_button(typebase, value='Default', $
                              tooltip='Average over centered interval (t-dt,t+dt)')
    dttype[1] = widget_button(typebase, value='Forward', $
                              tooltip='Average over next interval')
    dttype[2] = widget_button(typebase, value='Backward', $
                              tooltip='Average over previous interval')

  itrpButtonBase = widget_base(interpBase, /nonexclusive,xpad=0,ypad=0,space=0)
    itrpButton = widget_button(itrpButtonBase, value ='Set Interpolation Cadence (sec): ', $
                               uval='IBUTTON',tooltip='By default the data is '+ $
                               'interpolated to its minimum resolution.',uname='ibutton')
  itrpCadence = spd_ui_spinner(interpBase, text_box_size=10, uval='ICAD', $
                               value=icad, incr=1, sens=0, min_value=0)

  opts = lonarr(3)
    opts[0] = widget_button(optionsbase, value='No Time Interpolation', uval='NOT', $
                          tooltip='Do not interpolate to regular-spaced grid before'+ $
                          ' averaging. This option may be slow')
    opts[1] = widget_button(optionsbase, value='True Time Integration', $
                          tooltip='Created for High Pass filter. Subtracts'+ $
                          ' 1/2 of the end points of the integration from '+ $
                          'each value, to obtain the value for an integration'+ $
                          ' over time of the appropriate interval.')
    opts[2] = widget_button(optionsbase, value='Smooth NaNs', $
                          tooltip='Replaces any NaN values in data with '+ $
                                  'smoothed averages.')

  suffixlabel = widget_label(namebase, value = 'Suffix: ')
  suffixtext = widget_text(namebase, /editable, xsize=15, value=suffix)
  includeBase = widget_base(namebase, /nonexclusive, ypad=0)
    includeRes = widget_button(includebase, value='Append Resolution')

;Buttons
  ok = widget_button(buttonbase, value = 'OK', uval='OK')
  cancel = widget_button(buttonbase, valu = 'Cancel', uval='CANCEL')

;Initializations
  widget_control, dttype[0], set_button=1
  widget_control, includeres, set_button=1

  values = {dt:res, icad:icad, setICad:0b, dttype:[0,0,0], opts:[0,0,0], suffix:suffix, ok:0b}

  pvals = ptr_new(values)

  state = {tlb:tlb, gui_id:gui_id, statusbar:statusbar, historywin:historywin, $
           res:resolution, icad:itrpCadence, ibase:interpbase, $
           dttype:dttype, opts:opts, suffix:suffixtext, includeRes:includeRes, $
           pvals:pvals}

  centertlb, tlb

  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_smooth_data_options', tlb, /no_block

;Return adjusted values
  values= *pvals
  ptr_free, pvals

  widget_control, /hourglass

  Return, values

end
