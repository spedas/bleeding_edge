;+
; Name:
;     spd_ui_neutral_sheet_help
;
; Purpose:
;     Panel for producing magnetic neutral sheet models in SPEDAS
;
;
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 11:48:01 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_neutral_sheet_help.pro $
;-
; Name:
;     spd_ui_neutral_sheet_help_error
;
; Purpose:
;    Sends errors in this panel to dprint, status bar and history window
;
pro spd_ui_neutral_sheet_help_error, state, error
  if ~undefined(error) && error ne '' then begin
    dprint, dlevel=1, error
   endif else begin
    dprint, dlevel=0, 'Problem in the neutral sheet help panel error procedure, no error provided.'
  endelse
end
; Name:
;    spd_ui_neutral_sheet_help_event
;
; Purpose:
;    Event handler for this panel
;
pro spd_ui_neutral_sheet_help_event, event
  compile_opt idl2, hidden

  Widget_Control, event.top, get_uvalue = ptrHelpState
  helpState = *ptrHelpState

  err_help_event = 0
  catch, err_help_event

  ; catch any errors thrown
  if err_help_event ne 0 then begin
    catch, /cancel
    help, /last_message, output = err_msg
    widget_control, event.top,/destroy
    return
  endif

  ; handle kill requests
  if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
    Widget_Control, event.top, /destroy
    ; run the garbage collector if we're in IDL 6-7
    if double(!version.release) lt 8. then heap_gc
    return
  endif

  ; get the uvalue
  Widget_Control, event.id, get_uvalue=uval

  case uval of
    'CLOSE': begin
      if ptr_valid(ptrHelpState) then ptr_free, ptrHelpState
      Widget_Control, event.top, /destroy
      return
    end
  endcase
end


pro spd_ui_neutral_sheet_help, state

  catch, err_neutral_sheet_help

  ; catch any errors opening the panel
  if err_neutral_sheet_help ne 0 then begin
    catch, /cancel
    help, /last_message, output=err_msg
    dprint, dlevel = 1, err_msg
    err_msgbox = error_message('An unknown error occured while opening the neutral sheet help window. See the console for details', /noname, /center, title='Error in Neutral Sheet Help')
    return
  endif

  ; create the base widget for the neutral models panel
  tlb = Widget_Base(/Col, Title='Neutral Sheet Help', Group_Leader=state.tlb, $
    /Floating, /tlb_kill_request_events,/modal)
  mainBase = Widget_Base(tlb, /col)
  bottomBase = Widget_Base(tlb, /col)

  getresourcepath, resource_path
  palettebmp = read_bmp(resource_path + 'color.bmp', /rgb)
  cal = read_bmp(resource_path + 'cal.bmp', /rgb)
  helpbmp = read_bmp(resource_path + 'question.bmp', /rgb)

  spd_ui_match_background, tlb, helpbmp
  spd_ui_match_background, tlb, palettebmp
  spd_ui_match_background, tlb, cal

 
  ;;;;;;;;;;;;;;;;;;;;; Information Text Box ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  helpMessage=['This model calculates the Neutral Sheet position along the zaxis at a', $
               'specific x and y location, Z of the NS in gsm coordinates. The value', $
               'is positive if the NS is above Z=0 gsm plane, negative if below. ', $
               ' ', $
               'Output Options:', $
               'zNS:  returns Z displacement of the neutral sheet above or below the ', $
               '          XY plane in zgsm of the NS. The Value is positive if NS is above', $
               '          z=0 gsm plane, negative if below.', $
               'dz2NS:  returns the z displacement relative to the input position data. It ', $
               '             is positive if the NS is northward of the SC location, and negative', $
               '             if below. ', $
               ' ', $
               'Models: ', $
               'AEN:        Analytical Equatorial Neutral Sheet Model', $
               'DEN:        Displaced Equatorial Neutral Sheet Model', $
               'Fairfield:    Fairfied Neutral Sheet Model', $
               'Lopez:      Lopez Model (uses KP Index and Magnetic Latitude as input)', $
               'SM:          SM coordinates of input position Data ', $
               'THEMIS:  Uses SM Model for position<8.6RE Hammond model for ', $
               '                 pos>=8.6RE']
  infoText=Widget_Text(mainBase, value = helpMessage, uvalue='INFOTEXT', /wrap, xsize=60, ysize=20)

  ;;;;;;;;;;;;;;;;;;;;; Model Name selection ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  buttonBase = Widget_Base(bottomBase, /row, /align_right)
  closeButton = Widget_Button(buttonBase, value='Close', uval='CLOSE', tooltip='Close this window')

  helpstate = {tlb: tlb}

  ptrHelpState = ptr_new(helpState, /no_copy)
  Widget_Control, tlb, set_uvalue = ptrHelpState, /no_copy
  centertlb, tlb
  Widget_Control, tlb, /realize
  XManager, 'spd_ui_neutral_sheet_help', tlb, /no_block
end
