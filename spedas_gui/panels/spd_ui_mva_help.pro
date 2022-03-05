;+
; Name:
;     spd_ui_mva_help
;
; Purpose:
;     Additional information for the MVA GUI
;
;
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 11:48:01 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_mva_help.pro $
;-

; Name:
;    spd_ui_mva_help_event
;
; Purpose:
;    Event handler for this panel
;
pro spd_ui_mva_help_event, event
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


pro spd_ui_mva_help, parent_tlb

  catch, err_mva_help

  ; catch any errors opening the panel
  if err_mva_help ne 0 then begin
    catch, /cancel
    help, /last_message, output=err_msg
    dprint, dlevel = 1, err_msg
    err_msgbox = error_message('An unknown error occured while opening the MVA GUI help window. See the console for details', /noname, /center, title='Error in MVA GUI Help')
    return
  endif

  ; create the base widget for the neutral models panel
  tlb = Widget_Base(/Col, Title='MVA GUI Help', Group_Leader=parent_tlb, $
    /Floating, /tlb_kill_request_events,/modal)
  mainBase = Widget_Base(tlb, /col)
  bottomBase = Widget_Base(tlb, /col, /base_align_center, /align_center)

  getresourcepath, resource_path
  palettebmp = read_bmp(resource_path + 'color.bmp', /rgb)
  cal = read_bmp(resource_path + 'cal.bmp', /rgb)
  helpbmp = read_bmp(resource_path + 'question.bmp', /rgb)

  spd_ui_match_background, tlb, helpbmp
  spd_ui_match_background, tlb, palettebmp
  spd_ui_match_background, tlb, cal

  ;;;;;;;;;;;;;;;;;;;;; Information Text Box ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  helpMessage=['INTRODUCTION: ', $
    'The main purpose of minimum or maximum variance analysis (MVA) is to find, from single-spacecraft data, an', $
    'estimator for the direction normal to a one-dimensional (1-D) or approximately 1-D current layer, wave front, ', $
    'or other transition layer in a plasma. Fpr 2-D or 3-D structures it can also be used to provide a local Cartesian', $
    'coordinate system. It can not only be performed to analyze the mangnetic field data, but also to any vector ', $
    'fields such as electric fields, velocity and mass flux.', $
    ' ', $
    'Additional help will soon be available in the Users Guide on the SPEDAS wiki pages:', $ 
    '    http://spedas.org/wiki/index.php?title=Tools_Menu_-_SPEDAS_GUI', $
    ' ', $
    'REFERENCES:', $
    '1. Sonnerup, B. U. O., and M. Scheible (1998), Minimum and Maximum Variance Analysis, in Analysis Methods',$
    '   for Multi-Spacraft Data, edited by G. Paschemann and P. W. Daly, pp185-200, Int. Space Sci. Inst., Bem', $
    ' ', $
    ' ', $
    'Note: the example event when one starts this GUI is from:',$
    'https://agupubs.onlinelibrary.wiley.com/doi/epdf/10.1029/2010JA016316']
    
  infoText=Widget_Text(mainBase, value = helpMessage, uvalue='INFOTEXT', /wrap, xsize=88, ysize=18)

  ;;;;;;;;;;;;;;;;;;;;; Model Name selection ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  buttonBase = Widget_Base(bottomBase, /row)
  closeButton = Widget_Button(buttonBase, value='Close', uval='CLOSE', tooltip='Close this window', /align_center)

  helpstate = {tlb: tlb}

  ptrHelpState = ptr_new(helpState, /no_copy)
  Widget_Control, tlb, set_uvalue = ptrHelpState, /no_copy
  centertlb, tlb
  Widget_Control, tlb, /realize
  XManager, 'spd_ui_mva_help', tlb, /no_block
  
  return
  
end
