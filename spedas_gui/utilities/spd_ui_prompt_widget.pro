
;+
;NAME:
; spd_ui_prompt_widget.pro
;
;PURPOSE:
;  Simple standardized popup, for yes/no,yes_to_all,no_to_all,cancel
;  Like dialog_message, but allows additional options, and automatically logs/prompts
;
;CALLING SEQUENCE:
;  result = spd_ui_prompt_widget(parent,statusbar,historywin,"Continue?")
;
;INPUT:
;  parent: Widget Id of parent widget(Note that if parent is invalid, it will block until a response is received. See documentation for XMANAGER:NO_BLOCK keyword)
;  statusBar: The statusbar object to which output should be sent, if unavailable pass null object(obj_new())
;  historywin:  The historywin object to which output should be sent if unavailable pass null object(obj_new())
;  promptText=promptText: The text of the prompt to be displayed to the user.
;  no=no :Include "No" Button
;  yes=yes: Include "Yes" Button
;  allno=allno: Include "No To All" button.
;  allyes=allyes: Include "Yes To All" button.
;  cancel=cancel: Include "Cancel" button.
;  ok=ok: Include "Ok" button.
;  maxwidth=maxwidth: Control the width at which the prompt starts wrapping prompt text.
;  defaultValue=defaultValue: Set to string to return as default. (Occurs during error or close by clicking "X")
;                    Normally default is value of right-most button.
;  title=title:  Set window title to string.
;
;  traceback=traceback: Do a trace to calling location
;
;  frame_attr=frame_attr: Control the window appearance via TLB_FRAME_ATTR.  Values:
;  1 Base cannot be resized, minimized, or maximized.
;  2 Suppress display of system menu.
;  4 Suppress title bar.
;  8 Base cannot be closed.
;  16 Base cannot be moved.
;  For multiple effects add values together.
;  There are differences between Linux and Windows, so test before using. TLB_FRAME_ATTR=8 seems to work everywhere.
;
;OUTPUT:
; Returns an all lower case string with the response text:
; "no","yes","yestoall","notoall","cancel","ok"
;
;
;NOTES:
;  1. If no button keywords are set, "ok" is used.
;  2. Based heavily on deprecated gui load subroutine: spd_ui_load_clob_prompt:
;  3. If a parent widget is unavailable, statusbar, or historywin unavailable, you can pass null values
;    result = spd_ui_prompt_widget(0l,obj_new(),obj_new(),prompt="Continue?")
;    This call will interact with other widgets in a way that is similar to a call to error_message
;
;
;HISTORY:
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-03-12 17:12:52 -0700 (Thu, 12 Mar 2015) $
;$LastChangedRevision: 17128 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_prompt_widget.pro $
;
;---------------------------------------------------------------------------------

pro spd_ui_prompt_widget_event, event

  compile_opt idl2, hidden
  
  Widget_Control, event.TOP, Get_UValue=state, /No_Copy
  
  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in spd_ui_prompt_widget'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
    state.historyWin->update,'Prompt Widget Killed', /dontshow
    Widget_Control, event.TOP, Set_uValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  if is_string(uval) then begin
    *state.answer = uval
    Widget_Control, event.top, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
  endif
  
  RETURN
end

function spd_ui_prompt_widget,$
  parent,$
  statusBar,$
  historyWin,$
  promptText=promptText,$
  no=no,$
  yes=yes,$
  allno=allno,$
  allyes=allyes,$
  cancel=cancel,$
  ok=ok,$
  maxwidth=maxwidth,$
  defaultValue=defaultValue,$
  title=title,$
  traceback=traceback,$
  frame_attr=frame_attr
  
  compile_opt idl2
  
  if ~is_string(title,/blank) then begin
    title = 'Please Respond'
  endif
  
  if ~is_string(promptText,/blank) then begin
    promptText = ' '
  endif
  
  if ~keyword_set(maxwidth) then begin
    maxwidth = 100
  endif
  
  if widget_valid(parent) then begin
    if ~keyword_set(frame_attr) then begin
      tlb = widget_base(/col, title=title, group_leader=parent, /modal, /tlb_kill_request,/base_align_center)
    endif else begin
      tlb = widget_base(/col, title=title, group_leader=parent, /modal, /tlb_kill_request,/base_align_center,TLB_FRAME_ATTR=frame_attr )
    endelse
  endif else begin
    tlb = widget_base(/col, title=title, /base_align_center)
    if ~keyword_set(frame_attr) then begin
      tlb = widget_base(/col, title=title, /base_align_center)
    endif else begin
      tlb = widget_base(/col, title=title, /base_align_center,TLB_FRAME_ATTR=frame_attr )
    endelse
    parent = 0
  endelse
  
  if keyword_set(frame_attr) and obj_valid(tlb) then begin
    Widget_Control, tlb, TLB_FRAME_ATTR=frame_attr
  endif
  
  ;calculate minimum width required to display text box
  width = 0
  ;value are number of character for button labels +2 for button beveling
  width += keyword_set(yes) ? 7 : 0
  width += keyword_set(no) ? 6 : 0
  width += keyword_set(allyes) ? 13 : 0
  width += keyword_set(allno) ? 12 : 0
  width += keyword_set(cancel) ? 10 : 0
  width += (keyword_set(ok) ||(~keyword_set(allyes) && ~keyword_set(allno) && $
    ~keyword_set(yes) && ~keyword_set(no) && ~keyword_set(cancel))) ? 6 : 0
    
  textlines =  strsplit(promptText,ssl_newline(),/extract, count=numlines)
  width = max([width,strlen(textlines)])
  width += 2
  width = width < maxwidth
  
  ;height is number of new lines + total number of line wraps + margin
  height = numlines + total( (strlen(textlines)+2) / width ) + 1
  
  textBase = widget_text(tlb, value=promptText,xsize=width,editable=0,/wrap,ysize=height)
  buttonBase = widget_base(tlb, /row, /align_center)
  
  ;default ordering and button ordering are not the same for yestoall & notoall.  If present with yes/no,
  ; the non-all option will be the default, but the all-button will be place to the right of the all-button
  if keyword_set(allyes) then begin
    default = "yestoall"
  endif
  
  if keyword_set(yes) then begin
    yesButton = widget_button(buttonBase, value=' Yes ', uvalue='yes')
    default = "yes"
  endif
  
  if keyword_set(allyes) then begin
    yesToAllButton = widget_button(buttonBase, value=' Yes To All ', uvalue='yestoall')
  endif
  
  if keyword_set(allno) then begin
    default = "notoall"
  endif
  
  if keyword_set(no) then begin
    noButton = widget_button(buttonBase, value=' No ', uvalue='no')
    default = "no"
  endif
  
  if keyword_set(allno) then begin
    noToAllButton = widget_button(buttonBase, value=' No To All ', uvalue='notoall')
  endif
  
  if keyword_set(ok) || (~keyword_set(allyes) && ~keyword_set(allno) && $
    ~keyword_set(yes) && ~keyword_set(no) && ~keyword_set(cancel)) then begin
    okButton = widget_button(buttonBase, value=' Ok ', uvalue='ok')
    default = "ok"
  endif
  
  if keyword_set(cancel) then begin
    cancelButton = widget_button(buttonBase, value=' Cancel ', uvalue='cancel')
    default = "cancel"
  endif
  
  ;don't use is_string because it_string doesn't count '' as a string
  if size(defaultValue,/type) eq 7 then begin
    default = defaultValue
  endif
  
  answer = ptr_new(default)
  
  ;  if obj_valid(statusBar) then begin
  ;    statusBar->update,"Popup Requires Response, Prompt Is: " + promptText
  ;  endif
  
  if obj_valid(historyWin) then begin
    historyWin->update,"Opening Popup With Prompt: " + promptText, /dontshow
  endif
  
  if Keyword_Set(traceback) then begin
  
    Help, Calls=callStack
    callingRoutine = (StrSplit(StrCompress(callStack[1])," ", /Extract))[0]
    Help, /Last_Message, Output=idl_traceback
    traceback = scope_traceback()
    Print,''
    Print, 'Traceback Report from ' + StrUpCase(callingRoutine) + ':'
    Print, ''
    for j=0,N_Elements(traceback)-1 do Print, "     " + traceback[j]
    
    if keyword_set(idl_traceback[0]) then begin
      print,'Last IDL Error: '
      print,idl_traceback[0]
      if n_elements(idl_traceback) gt 1 then begin
        print,idl_traceback[1]
      endif
    endif
    
  endif
  
  state = {tlb:tlb, parent:parent, statusBar:statusBar,historyWin:historyWin, answer:answer}
  
  centertlb, tlb
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize
  
  
  XManager, 'spd_ui_prompt_widget', tlb, No_Block=widget_valid(parent)
  
  ;  if obj_valid(statusBar) then begin
  ;    statusBar->update,"Popup Received Response: " + *answer
  ;  endif
  
  if obj_valid(historyWin) then begin
    historyWin->update,"Closing Popup With Response: " + *answer, /dontshow
  endif
  
  return, *answer
end
