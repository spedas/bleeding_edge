;+
;NAME:
;  spd_ui_join_variables_options
;
;PURPOSE:
;  Front end interface allowing the user to select options for joining separate variables.
;
;CALLING SEQUENCE:
;  return_values = spd_ui_join_variables_options(gui_id, statusbar, historywindow)
;
;INPUT:
;  gui_id: widget id of group leader
;  statusbar: status bar object ref.
;  historywindow: history window object ref.
;
;OUTPUT:
;  return values: anonymous structure containing input parameters for dproc routine
;  {
;   new_name: new_name for new variable
;   ok: Flag indicating success
;  }
;
;NOTES:
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/dproc/spd_ui_join_variables_options.pro $
;-

pro spd_ui_join_variables_options_event, event

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
                     /noname,/center, title='Error in Join Variables Options')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif

;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    state.historywin->update,'SPD_UI_JOIN_VARIABLES_OPTIONS: Widget killed', /dontshow
    state.statusbar->update,'Join Variables canceled'
    widget_control, event.top, /destroy
    return
  endif

  m = 'Join Variables: '

;get user value
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 then begin
    Case uval Of
      'OK':begin

        ;Get new_name
        widget_control, state.new_name, get_value = new_name
        
        if stregex(new_name,'^ *$',/bool) then begin
          ok = dialog_message('Must enter a new variable name.',/center,title='Join Variables Error')
          break
        endif
        
        if stregex(new_name,' +',/bool) then begin
          ok = dialog_message('Variable name cannot have spaces.',/center,title='Join Variables Error')
          break
        endif
        
        (*state.pvals).new_name = new_name

        ;Set success flag
        (*state.pvals).ok = 1b
        
        widget_control, event.top, /destroy
        return
      end
      'CANCEL': begin
        state.historywin->update,'SPD_UI_JOIN_VARIABLES_OPTIONS: Cancelled', /dontshow
        state.statusbar->update,'Join Variables canceled'
        widget_control, event.top, /destroy
        return
      end
      else: 
    Endcase
  endif

  widget_control, event.top, set_uval = state, /no_copy

end


function spd_ui_join_variables_options, gui_id, statusbar, historywin

    compile_opt idl2


  catch, _err
  if _err ne 0 then begin
    catch, /cancel
    ok = error_message('Error starting Join Variable Options, see console for details.')
    widget_control, tlb, /destroy
    return,{ok:0}
  endif

;Constants
  new_name = 'new_var'    ;default name


  tlb = widget_base(title = 'Join Variables Options', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


;Main bases
  mainbase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)
    nameBase = widget_base(mainbase, /row, ypad=4)

    buttonBase = widget_base(mainbase, /row, /align_center, ypad=10)

;Options widgets

  namelabel = widget_label(nameBase, value='New Variable Name: ')
  nametext = widget_text(nameBase, value=new_name , /editable, xsize=15)

;Buttons
  ok = widget_button(buttonbase, value = 'OK', xsize=60, uval='OK')
  cancel = widget_button(buttonbase, valu = 'Cancel', xsize=60, uval='CANCEL')


;Initializations
  values = {new_name:new_name, ok:0b}

  pvals = ptr_new(values)

  state = {tlb:tlb, gui_id:gui_id, statusbar:statusbar, historywin:historywin, $
           new_name:nametext, pvals:pvals}

  centertlb, tlb

  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_join_variables_options', tlb, /no_block

;Return adjusted values
  values= *pvals
  ptr_free, pvals

  widget_control, /hourglass

  Return, values

end
