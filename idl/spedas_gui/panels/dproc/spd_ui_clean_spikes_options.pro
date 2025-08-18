;+
;NAME:
;  spd_ui_clean_spikes_options
;
;PURPOSE:
;  Front end interface allowing the user to select options for cleaning spikes from data.
;
;CALLING SEQUENCE:
;  return_values = spd_ui_clean_spikes_options(gui_id, statusbar, historywindow)
;
;INPUT:
;  gui_id: widget id of group leader
;  statusbar: status bar object ref.
;  historywindow: history window object ref.
;
;OUTPUT:
;  return values: anonymous structure containing input parameters for dproc routine
;  {
;   thresh: Threshold for determining spikes (see clean_spikes.pro)
;   swidth: Width of smoothing window, see IDL documentation on smooth() for more info
;   suffix: Suffix for new variable
;   ok: Flag indicating success
;  }
;
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;-

pro spd_ui_clean_spikes_options_event, event

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
                     /noname,/center, title='Error in Clean Spikes Options')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif

;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    state.historywin->update,'SPD_UI_CLEAN_SPIKES_OPTIONS: Widget killed', /dontshow
    state.statusbar->update,'Clean Spikes canceled'
    widget_control, event.top, /destroy
    return
  endif

  m = 'Clean Spikes: '

;get user value
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 then begin
    Case uval Of
      'OK':begin
      ;Get threshold
        widget_control, state.thresh, get_value=thresh
        if finite(thresh) && (thresh ge 1) then begin
          (*state.pvals).thresh = thresh
        endif else begin
          ok = dialog_message('Invalid threshold, please enter a numeric value greater than or equal to 1.', $
                              /center,title='Clean Spikes Error')
          break
        endelse

      ;Get smoothing width
        widget_control, state.swidth, get_value=swidth
        if finite(swidth) && (swidth gt 0) then begin
          (*state.pvals).swidth = swidth
        endif else begin
          ok = dialog_message('Invalid smoothing width, please enter a numeric value greater than 0.', $
                              /center,title='Clean Spikes Error')
          break
        endelse

        ;Get suffix
        widget_control, state.suffix, get_value = suffix
        (*state.pvals).suffix = suffix

        ;Set success flag
        (*state.pvals).ok = 1b
        
        widget_control, event.top, /destroy
        return
      end
      'CANCEL': begin
        state.historywin->update,'SPD_UI_CLEAN_SPIKES_OPTIONS: Cancelled', /dontshow
        state.statusbar->update,'Clean Spikes canceled'
        widget_control, event.top, /destroy
        return
      end
      'THRESH': begin
        if event.valid && event.value ge 1 then state.statusbar->update, $
          m+'Threshold set to '+strtrim(event.value,2)+'.' $
        else state.statusbar->update,'Threshold must be a numeric value greater than or equal to 1.'
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

function spd_ui_clean_spikes_options, gui_id, statusbar, historywin

    compile_opt idl2


  catch, _err
  if _err ne 0 then begin
    catch, /cancel
    ok = error_message('Error starting Clean Spikes Options, see console for details.')
    widget_control, tlb, /destroy
    return,{ok:0}
  endif

;Constants
  swidth = 3d             ;default smoothing width
  suffix = '-despiked'    ;default suffix
  thresh = 10d            ;default threshold

  tlb = widget_base(title = 'Clean Spikes Options', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


;Main bases
  mainbase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)
    threshBase = widget_base(mainbase, /row, ypad =2)

    smoothBase = widget_base(mainbase, /row, ypad=2)

    nameBase = widget_base(mainbase, /row, ypad=4)

    buttonBase = widget_base(mainbase, /row, /align_center, ypad=10)

;Options widgets
  smoothwidth = spd_ui_spinner(smoothBase,value=swidth,label='Smoothing Width(# Pts):  ',text_box_size=10, $
                               uval='SMOOTH',incr=1,tooltip='The width, in elements, of the '+ $
                               'smoothing window', getxlabelsize=xlsize, min_value=0)

  threshnumber = spd_ui_spinner(threshBase,value=thresh,label='Threshold:  ',text_box_size=10, $
                                uval='THRESH',incr=1,tooltip='Set lower for more liberal determination of spikes, [1,infinity)', xlabelsize=xlsize, min_value=1)

  suffixlabel = widget_label(nameBase, value='Suffix: ')
  suffixtext = widget_text(nameBase, value=suffix , /editable, xsize=15)

;Buttons
  ok = widget_button(buttonbase, value = 'OK', uval='OK')
  cancel = widget_button(buttonbase, valu = 'Cancel', uval='CANCEL')


;Initializations
  values = {thresh:thresh, swidth:swidth, suffix:suffix, ok:0b}

  pvals = ptr_new(values)

  state = {tlb:tlb, gui_id:gui_id, statusbar:statusbar, historywin:historywin, $
           thresh:threshnumber, swidth:smoothwidth, suffix:suffixtext, $
           pvals:pvals}

  centertlb, tlb

  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_clean_spikes_options', tlb, /no_block

;Return adjusted values
  values= *pvals
  ptr_free, pvals

  widget_control, /hourglass

  Return, values

end
