;+
;NAME:
;spd_ui_history
;
;PURPOSE:
; A widget to display the all messages generated during this session
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-13 08:15:04 -0700 (Mon, 13 Jul 2015) $
;$LastChangedRevision: 18090 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_history__define.pro $
;+ 
;NAME: 
; spd_ui_history__define
;
;PURPOSE:
; This is a history window object used to display textual information for the user
; (such as a status bar for current states, message bar, or informational bar)
;
;CALLING SEQUENCE:
; To Create:    myHistory = Obj_New("SPD_UI_HISTORY")
; To Use:       myHistory->Update, 'This is a test'
; Or:           result = myHistory->GetState()
;
;INPUT:
;
;KEYWORDS:
; name:   optional name
; state:  set this to one to display
; value:  text to be displayed in the bar 
; xSize:  size of bar in x direction
; ySize:  size of bar in y direction
; debug:  set this value to one for debugging
;
;OUTPUT:
; message bar object reference
;
;METHODS:
; Draw         creates/displays the bar (automatically called by INIT)
; Delete       removes bar from display (object persists)
; Update       updates bar with new message
; SetProperty  procedure to set keywords 
; GetProperty  procedure to get keywords 
; GetState     returns the current state of the bar (on/off) (this is a function)

;HISTORY:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-13 08:15:04 -0700 (Mon, 13 Jul 2015) $
;$LastChangedRevision: 18090 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_history__define.pro $
;-----------------------------------------------------------------------------------

PRO spd_ui_history_event, event

  Compile_Opt hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

      ;Put a catch here to insure that the state remains defined

  err_xxx = 0
  Catch, err_xxx
  IF(err_xxx Ne 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO Print, err_msg[j]
    Print, 'Error in History Window'
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy    
    RETURN
  ENDIF

      ;kill request block
      
  IF Size(event, /Type) EQ 0 OR (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
    Exit_Sequence:
;    dprint,  'Widget Killed' 
    state.self->Delete
;    Widget_Control, state.menuID, Set_Button=0
;    Widget_Control, event.TOP, Set_UValue=state, /No_Copy    
;    Widget_Control, event.top, /Destroy
    RETURN      
  ENDIF
  
      ;which widget?
      
  Widget_Control, event.id, Get_UValue=uval
  IF Size(uval, /Type) NE 0 THEN BEGIN
    CASE uval OF
      'CLOSE': BEGIN
;    	dprint,  'History window canceled' 
    	state.self->Delete
;    	Widget_Control, state.menuID, Set_Button=0
;    	Widget_Control, event.TOP, Set_UValue=state, /No_Copy    
;    	Widget_Control, event.top, /Destroy
    	RETURN
    END
      'SAVE': begin
        state.self->Update, 'Saving history file'
        state.self->save,append=0
      end
      ELSE: ;dprint,  ''
    ENDCASE
  ENDIF
  
  Widget_Control, event.TOP, Set_UValue=state, /No_Copy
  
  RETURN
END ;--------------------------------------------------------------------------------


pro spd_ui_history::Save , filename=filename,append=append

xt = time_string(systime(/sec))
ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+'_'+strmid(xt,11,2)+strmid(xt,14,2)+strmid(xt,17,2)
historyFile = 'spd_gui_history_'+ttt+'.txt'
if size(filename,/type) ne 7 then begin
  ;fileName = dialog_pickfile(title = 'SPEDAS GUI History Filename', filter = '*.txt', file = historyFile, /Write)
  fileName = spd_ui_dialog_pickfile_save_wrapper(title = 'SPEDAS GUI History Filename', filter = '*.txt', file = historyFile, /Write,/overwrite_prompt)
endif
If is_string(fileName) Then Begin
  self->GetProperty, Messages=messages
  IF Ptr_Valid(messages) THEN BEGIN
     msgArray=*messages
     writeMessages=msgArray.message

     IF N_Elements(writeMessages) GT 0 THEN BEGIN
	openw, unit, fileName, /get_lun, error=err
;	openw, unit, fileName, /get_lun, append,error=err
        if err ne 0 then begin
          self->update,!error_state.msg,/dontshow,/nosave
          self->SetProperty,lastSaveSuccess= 0
        endif else begin
	  if n_elements(writemessages) gt 0 then begin
	    FOR i=0,N_Elements(writeMessages)-1 DO printf, unit, writeMessages[i]
	  endif
	  printf, unit, 'End of History Window Messages'
	  printf, unit, '------------------------------'

          self->SetProperty,/lastSaveSuccess

	  free_lun, temporary(unit)
        endelse

     ENDIF ELSE BEGIN
	dummy = dialog_message('There are no messages to write', /INFORMATION, /ERROR)
     ENDELSE
  ENDIF ELSE BEGIN
     dummy = dialog_message('There are no messages to write', /INFORMATION, /ERROR)
  ENDELSE
ENDIF ELSE BEGIN
  ; dummy = dialog_message('Invalid file name entered', /INFORMATION, /ERROR)
ENDELSE  

end ;----------------------------------------------------------------------------------


PRO SPD_UI_HISTORY::Draw

     ; check that the window is not already displayed

  IF self.id EQ 0 or self.state EQ 0 THEN BEGIN

        ; create the base, text and button widgets
      
      tlb = Widget_Base(/Col, Title='SPEDAS: History Window', Group_Leader=self.mainID, /tlb_kill_request_events, /float)
      msgs=*self.messages
      indices=Where(msgs.dontShow EQ 0) 
      IF indices[0] EQ -1 THEN msgs1=[''] ELSE msgs1=msgs[indices].message
      historyText = Widget_Text(tlb, UValue='HISTORY', Value=msgs1, XSize = 80, YSize = 40, /Scroll, Frame = 3)
      buttonBase = Widget_Base(tlb, /Row, /Align_Center)
      saveButton = Widget_Button(buttonBase, Value=' Save ', Uvalue='SAVE')
      closeButton = Widget_Button(buttonBase, Value=' Close ', Uvalue='CLOSE')

        ; set the id's

      self.id = tlb
      self.textID = historyText
      self.state = 1
     
        ; display the window
      state = {tlb:tlb, menuID:self.menuID, messages:self.messages, self:self}
      
      Widget_control, tlb, set_uval=state, /no_copy

      Widget_control, tlb, /Realize
      XManager, 'spd_ui_history', tlb, /No_Block

  ENDIF
  
RETURN
END ;--------------------------------------------------------------------------------



PRO SPD_UI_HISTORY::Delete
IF self.id NE 0 THEN BEGIN
   self->getProperty,id=id
   self->getProperty,menuID=menuID
   Widget_Control, menuID, Set_Button=0
   Widget_Control, ID, /Destroy

   self.state = 0
   self.textID = 0
   self.id = 0
ENDIF
END ;--------------------------------------------------------------------------------



PRO SPD_UI_HISTORY::Update, message_in, DontShow=dontShow,nosave=nosave

if ~undefined(message_in) then message = message_in

if ~keyword_set(nosave) then nosave=0

IF Is_String(message)&& N_Elements(message) GT 0 THEN BEGIN
  IF N_Elements(dontShow) EQ 0 THEN dontShow=0 ELSE dontShow=1
  currentTime = time_string(systime(/seconds),/local_time)
  message = '('+currentTime+') ' + message
  messageStruc={message:'', dontShow:0}
  messageArray = *self.messages
  numOld=N_Elements(messageArray)
  numNew=N_Elements(message)
  newArray=replicate(messageStruc, numOld+numNew)
  FOR i=0,NumOld-1 DO BEGIN
    newArray[i].message=messageArray[i].message
    newArray[i].dontShow=messageArray[i].dontShow
  ENDFOR
  FOR i=NumOld,(NumOld+NumNew)-1 DO BEGIN 
    newArray[i].message=message[i-NumOld]
    newArray[i].dontShow=dontShow
  ENDFOR
  Ptr_Free, self.messages
  self.messages = Ptr_New(newArray)
ENDIF
msgs=*self.messages
indices=Where(msgs.dontShow EQ 0)
IF self.state NE 0 && N_Elements(indices) GT 0 THEN WIDGET_CONTROL, self.textID, SET_VALUE=msgs[indices].message  

if ~nosave then begin
  if n_elements(*self.messages) eq 2 then append=0 else append=1       ;If this is the first update since intialization, then make a new file, else append.
  self->save,filename=self.running_history_dir+'/spd_gui_running_history.txt',append=append
endif
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_HISTORY::GetState
RETURN, self.state
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_HISTORY::ReadJournalFile
  if logical_true(!journal) then begin
    running_history_dir = self.running_history_dir
    journalFile = running_history_dir+'/spd_ui_idlsave.pro'
    if file_test(journalfile,/read) then begin
      journal
      messages=['************ Journal File ************']
      openr, unit, journalFile,/get_lun
      message=''
      WHILE ~eof(unit) DO BEGIN
	readf, unit, message,format='(A)'
	messages = [messages, message]
      ENDWHILE 
      Free_Lun, unit
      journal,journalfile
      for i=0,n_elements(messages)-1 do journal,messages[i]
    endif else messages=-1
  endif else messages=-1
RETURN, Messages
END ;--------------------------------------------------------------------------------



PRO SPD_UI_HISTORY::SetProperty,  $ ; The property set method for the object
            XSize=xsize,              $ ; size of bar in x direction
            YSize=ysize,              $ ; size of bar in y direction
            lastSaveSuccess=lastSaveSuccess, $ ; Flag indicating whether last save was successful
            Draw=draw                   ; set this to one to redisplay  

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(1))
      RETURN
   ENDIF

   ; Check for undefined variables.

   IF N_Elements(xsize) NE 0 THEN self.xsize = xsize
   IF N_Elements(ysize) NE 0 THEN self.ysize = ysize
   IF N_Elements(lastSaveSuccess) NE 0 THEN self.lastSaveSuccess= lastSaveSuccess
   
   IF Keyword_Set(draw) THEN BEGIN
      self->Destroy
      self->Draw
   ENDIF

END ;--------------------------------------------------------------------------------



PRO SPD_UI_HISTORY::GetProperty, $
            ID=id,                   $ ; widget id of history window
            menuID=menuid,           $ ; id of pull down check menu button
            mainID=mainid,           $ ; id of main gui window
            textID=textid,           $ ; id of text widget
            State=state,             $ ; flag to indicate whether bar is diplayed
            Messages=messages,       $ ; initial message to display
            running_history_dir=running_history_dir, $ ; Path for running history file
            lastSaveSuccess=lastSaveSuccess, $ ; Flag indicating whether last save was successful
            XSize=xsize,             $ ; size of bar in x direction
            YSize=ysize                ; size of bar in y direction

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(1))
      RETURN
   ENDIF

      ; return only what's requested

   IF Arg_Present(id) THEN id = self.id
   IF Arg_Present(menuid) THEN menuid = self.menuID
   IF Arg_Present(mainid) THEN mainid = self.mainID
   IF Arg_Present(textid) THEN textid = self.textID
   IF Arg_Present(state) THEN state = self.state
   IF Arg_Present(messages) THEN messages = self.messages
   IF Arg_Present(running_history_dir) THEN running_history_dir = self.running_history_dir
   IF Arg_Present(lastSaveSuccess) THEN lastSaveSuccess = self.lastSaveSuccess
   IF Arg_Present(xsize) THEN xsize = self.xSize
   IF Arg_Present(ysize) THEN ysize = self.ySize

END ;--------------------------------------------------------------------------------

;should be called before history object is destroyed
;Originally, this code was part of the cleanup method,
;but IDL heap_gc calls cleanup methods over-often
pro spd_ui_history::saveHistoryFile

  if ~ptr_valid(self.messages) then begin
    result = dialog_message("Unexpected invalid pointer found in history object",/center)
  endif

  if n_elements(*self.messages) eq 2 then append=0 else append=1       ;If this is the first update since intialization, then make a new file, else append.
  self->save,filename=self.running_history_dir+'/spd_gui_running_history.txt',append=append
  
  while ~self.lastSaveSuccess do begin
    result = dialog_message("The running history file has unsaved entries, and may be open in another application.  "+ $
      "Please close the file 'SPD_GUI_RUNNING_HISTORY.TXT in any other applications, and click 'OK'.  "+ $
      "You may also click 'Cancel' to close without saving the running history", /Cancel)
    if result eq 'OK' then begin
      if n_elements(*self.messages) eq 2 then append=0 else append=1       ;If this is the first update since intialization, then make a new file, else append.
      self->save,filename=self.running_history_dir+'/spd_gui_running_history.txt',append=append
    endif else break
  endwhile

end

pro SPD_UI_HISTORY::Cleanup
    ptr_free, self.messages
end


FUNCTION SPD_UI_HISTORY::Init,       $ ; The INIT method of the bar object.
            menuID,                  $ ; id of checked menu button, required
            mainID,                  $ ; id of the main gui window
            State=state,             $ ; flag to indicate whether bar is diplayed
            Message=message,         $ ; initial message to display
            running_history_dir=running_history_dir, $ ; Path for running history file
            lastSaveSuccess=lastSaveSuccess, $ ; Flag indicating whether last save was successful
            XSize=xsize,             $ ; size of bar in x direction
            YSize=ysize,             $ ; size of bar in y direction
            Debug=debug
                
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF

   messageStructure = {message:'', dontShow:0}
   ; Check that all parameters have values
   
   IF NOT Is_Numeric(menuID) THEN RETURN, 0
   IF NOT Is_Numeric(mainID) THEN RETURN, 0
   IF N_Elements(state) EQ 0 THEN state = 0
   IF N_Elements(xsize) EQ 0 THEN xsize = 80
   IF N_Elements(ysize) EQ 0 THEN ysize = 40
   IF N_Elements(message) EQ 0 THEN message='Initializing History Window'
   if n_elements(running_history_dir) eq 0 then cd,current=running_history_dir
   if n_elements(lastSaveSuccess) eq 0 then lastSaveSuccess = 1b
   messageArray=replicate(messageStructure, 1)
   messageArray[0].message=message
   messageArray[0].dontShow=0
   
  ; Set all parameters
  
   self.menuID = menuID
   self.mainID = mainID
   self.id = 0
   self.state = state
   self.messages = Ptr_New(messageArray)
   
   ;dprint, ptr_valid(self.messages)
   
   self.running_history_dir = running_history_dir
   self.lastSaveSuccess = byte(lastSaveSuccess)
   self.xsize = xsize
   self.ysize = ysize

  ; If state is on then display the window
   
   IF self.state EQ 1 THEN self->Draw

   RETURN, 1
END ;--------------------------------------------------------------------------------



PRO SPD_UI_HISTORY__DEFINE

   struct = { SPD_UI_HISTORY,          $

              id: 0L,                  $ ; widget id for the panel
              menuID: 0L,              $ ; id for the pull down menu check box
              textID: 0L,              $ ; id for the text widget
              mainID: 0L,              $ ; id for the main gui window
              state: 0,                $ ; on/off flag (for display)
              messages: Ptr_New(),     $ ; text to be displayed in the bar 
              running_history_dir: '', $ ; Path for running history file
              lastSaveSuccess:1b,      $ ; Flag indicating whether last save was successful
              xSize: 0,                $ ; size of window in x direction
              ySize: 0                 $ ; size of window in y direction

}

END ;--------------------------------------------------------------------------------
