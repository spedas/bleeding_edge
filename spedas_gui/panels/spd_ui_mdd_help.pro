;+
; Name:
;     spd_ui_mdd_help
;
; Purpose:
;     Additional information for the MDD GUI
;
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-08-21 12:21:00 -0700 (Thu, 21 Aug 2014) $
;$LastChangedRevision: 15698 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_neutral_sheet_help.pro $
;-

; Name:
;    spd_ui_mdd_help_event
;
; Purpose:
;    Event handler for this panel
;
pro spd_ui_mdd_help_event, event
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


pro spd_ui_mdd_help, parent_tlb

  catch, err_mva_help

  ; catch any errors opening the panel
  if err_mva_help ne 0 then begin
    catch, /cancel
    help, /last_message, output=err_msg
    dprint, dlevel = 1, err_msg
    err_msgbox = error_message('An unknown error occured while opening the MDD GUI help window. See the console for details', /noname, /center, title='Error in MVA GUI Help')
    return
  endif

  ; create the base widget for the neutral models panel
  tlb = Widget_Base(/Col, Title='MDD STD GUI Help', Group_Leader=parent_tlb, $
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
    ' ', $
    'The MDD & STD methods are to determine the structures dimensionality (i.e. whether is is 1-D, 2-D or 3-D), to ', $
    'build a dimensionality based (dim-based) coordinate system and a proper moving frame in space data analysis ', $
    'based on which one can directly compare with simulated and theoretical works. ', $
    ' ', $
    '1. MDD method can be used to analyze the dimensionality character of observed structures using multipoint vector', $
    'field measurements of four or more spacecraft. A new dim-based coordinate system  can be built and the normal', $
    'of 1-D structure and invariant axis of a 2-D structure can be found instantly at every observed time moment.', $
    ' ', $
    '2. STD method can be used to calculate the velocity of quasi-stationary structures at every observed moment in', $
    'time from multi-point magnetic field measurements.', $
    ' ', $
    'For additional help using this GUI go to: http://spedas.org/wiki/index.php?title=Tools_Menu_-_SPEDAS_GUI', $ 
    ' ', $
    ' ', $
    'REFERENCES:', $
    '1. Shi, Q. Q., C. Shen, Z. Y. Pu, M. W. Dunlop, Q.-G. Zong, H. Zhang, C.J. Xiao, Z. X. Liu, and A. Balogh (2005),',$
    'Dimensional analysis of observed structures using multipoint magnetic field measurements: Application to Cluster,', $
    'Geophys. Res. Lett., 32, L12105, doi:10.1029/2005GL022454.', $
    ' ', $
    '2. Shi, Q. Q., C. Shen, M. W. Dunlop, Z. Y. Pu, Q.-G. Zong, Z.-X. Liu, E. A. Lucek, and A. Balogh (2006),',$
    'Motion of observed structures calculated from mullti-point magnetic field measurements: Application to Cluster,', $
    'Geophys. Res. Lett., 33, L08109, doi:10.1029/2005GL025073.', $
    ' ']
 
  infoText=Widget_Text(mainBase, value = helpMessage, uvalue='INFOTEXT', /wrap, xsize=88, ysize=26)

  ;;;;;;;;;;;;;;;;;;;;; Model Name selection ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  buttonBase = Widget_Base(bottomBase, /row)
  closeButton = Widget_Button(buttonBase, value='Close', uval='CLOSE', xsize=90, tooltip='Close this window', /align_center)

  helpstate = {tlb: tlb}

  ptrHelpState = ptr_new(helpState, /no_copy)
  Widget_Control, tlb, set_uvalue = ptrHelpState, /no_copy
  centertlb, tlb
  Widget_Control, tlb, /realize
  XManager, 'spd_ui_mdd_help', tlb, /no_block

  return

end
