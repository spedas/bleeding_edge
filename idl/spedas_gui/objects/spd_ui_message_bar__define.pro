;+ 
;NAME: 
; spd_ui_message_bar__define
;
;PURPOSE:
; This is a text bar object used to display textual information for the user
; (such as a status bar for current states, message bar, or informational bar)
;
;CALLING SEQUENCE:
; To Create:    myStatusBar = Obj_New("SPD_UI_MESSAGE_BAR", myWidgetBase)
; To Use:       myStatusBar->Update, 'This is a test'
; Or:           result = myStatusBar->GetState()
;
;INPUT:
; parent:       id for the parent widget (must be a base)
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
;
; WARNINGS:
;   You should avoid calling the update method on this object before the widget is realized.
;
;HISTORY:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-09 10:47:18 -0700 (Thu, 09 Jul 2015) $
;$LastChangedRevision: 18043 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_message_bar__define.pro $
;-----------------------------------------------------------------------------------


PRO SPD_UI_MESSAGE_BAR::Draw

IF self.id EQ 0 THEN BEGIN
   IF self.scroll EQ 0 THEN BEGIN
      self.id = WIDGET_TEXT(self.parent, value=*self.messages, xsize = self.xsize, ysize = self.ysize,editable=0)
   ENDIF ELSE BEGIN
     
     ;follwing fix used to stop an x-11 warning that occurs when:
     ;when text widgets are realized
     ;on linux
     ;in modal sub-widgets
     ;with initial text size is smaller than the horizontal width of the text area in characters
     ;the sentinel string guarantees that the initial text is wider than the horizontal width of the text area in characters
     ;it must be at the beginning of the text for the warning to be avoided 
     message_text=[*self.messages]
     m_num = n_elements(message_text)-1
     s_len = strlen(message_text[m_num])
     if s_len lt self.xsize+2 then begin
       message_text[m_num]=message_text[m_num]+strjoin(replicate(' ',(self.xsize+2)-s_len))
     endif
     
     self.id = WIDGET_TEXT(self.parent, value=message_text, xsize = self.xsize, ysize = self.ysize,/scroll, editable=0)
   ENDELSE
   Widget_Control, self.id, SET_TEXT_TOP_LINE=N_Elements(*self.messages)-1
   self.state = 1
ENDIF
END ;--------------------------------------------------------------------------------



PRO SPD_UI_MESSAGE_BAR::Delete
IF self.id NE 0 THEN BEGIN
   WIDGET_CONTROL, self.id, /Destroy
   self.state = 0
   self.id = 0
ENDIF
END ;--------------------------------------------------------------------------------


;NOTE: You should avoid calling the update method on this object before the widget is realized.
PRO SPD_UI_MESSAGE_BAR::Update, value
IF self.id NE 0 THEN BEGIN
   newId = self.currentMsgId+1
   currentTime = time_string(systime(/seconds),/local_time)
   if self.notimestamp eq 1 then begin
     newValue = strtrim(string(newId), 2)+': ' + strmid(value,0,1000)
   endif else begin
     newValue = '(' + currentTime + ') ' + strtrim(string(newId), 2)+': ' + strmid(value,0,1000)
   endelse
   newMessages = [*self.messages, newValue]
   IF N_Elements(newMessages) GT self.msgLimit THEN newMessages = newMessages[1:self.msgLimit]
   
   ;follwing fix used to stop an x-11 warning that occurs when:
   ;when text widgets are realized
   ;on linux
   ;in modal sub-widgets
   ;with initial text size is smaller than the horizontal width of the text area in characters
   ;the sentinel string guarantees that the initial text is wider than the horizontal width of the text area in characters
   ;it must be at the beginning of the text for the warning to be avoided
   ;
   ;fix must be used in this method, even though it is an update method, because update can be called before the layout in which it exists is realized 
   m_num = n_elements(newMessages)-1
   
   s_len = strlen(newMessages[m_num])
   if s_len lt self.xsize+2 then begin
     newMessages[m_num]=newMessages[m_num]+strjoin(replicate(' ',(self.xsize+2)-s_len))
   endif
   
   WIDGET_CONTROL, self.id, SET_VALUE=newMessages
   WIDGET_CONTROL, self.id, SET_TEXT_TOP_LINE=m_num, /no_newline
   self.messages = Ptr_New(newMessages)
   self.value=newValue
   self.currentMsgId=newId
ENDIF 
END ;--------------------------------------------------------------------------------
  

FUNCTION SPD_UI_MESSAGE_BAR::GetState
RETURN, self.state
END ;--------------------------------------------------------------------------------



PRO SPD_UI_MESSAGE_BAR::SetProperty,  $ ; The property set method for the object
            XSize=xsize,              $ ; size of bar in x direction
            YSize=ysize,              $ ; size of bar in y direction
            MsgLimit=msglimit,        $ ; max number of messages
            Refresh=refresh             ; set this to one to redisplay  

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(self.debug))
      RETURN
   ENDIF

   ; Check for undefined variables.

   IF N_Elements(xsize) NE 0 THEN self.xsize = xsize
   IF N_Elements(ysize) NE 0 THEN self.ysize = ysize
   IF N_Elements(msglimit) NE 0 THEN self.msgLimit= msglimit
   
   IF Keyword_Set(refresh) THEN BEGIN
      self->Delete
      self->Draw
   ENDIF

END ;--------------------------------------------------------------------------------



PRO SPD_UI_MESSAGE_BAR::GetProperty,  $
            id=id,                   $ ; widget id
            Name=name,               $ ; optional name of bar
            Messages=messages,       $ ; text to be displayed in the bar 
            State=state,             $ ; flag to indicate whether bar is diplayed
            MsgLimit=msglimit,       $ ; total number of messages to buffer
            XSize=xsize,             $ ; size of bar in x direction
            YSize=ysize,             $ ; size of bar in y direction
            Scroll=scroll              ; size of bar in x direction

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(self.debug))
      RETURN
   ENDIF

   IF Arg_Present(id) then id = self.id
   IF Arg_Present(name) THEN name = self.name
   IF Arg_Present(messages) THEN messages = self.messages
   IF Arg_Present(state) THEN state = self.state
   IF Arg_Present(msglimit) THEN msglimit = self.msgLimit
   IF Arg_Present(xsize) THEN xsize = self.xsize
   IF Arg_Present(ysize) THEN ysize = self.ysize
   IF Arg_Present(scroll) THEN scroll = self.scroll

END ;--------------------------------------------------------------------------------



PRO SPD_UI_MESSAGE_BAR::Cleanup 
    if ptr_valid(self.messages) then ptr_free, self.messages
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_MESSAGE_BAR::Init,    $ ; The INIT method of the bar object.
            parent,                  $ ; id of parent, required
            Name=name,               $ ; optional name of bar
            Value=value,             $ ; text to be displayed in the bar 
            State=state,             $ ; flag to indicate whether bar is diplayed
            MsgLimit=msglimit,       $ ; total number of messages to buffer
            XSize=xsize,             $ ; size of bar in x direction
            YSize=ysize,             $ ; size of bar in y direction
            Scroll=scroll,           $ ; size of bar in x direction
            notimestamp=notimestamp, $ ;don't print the timestamp if this is set, it can take a lot of text on narrow bars 
            Debug=debug                ; set to one for debugging

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF

   self.debug = Keyword_Set(debug)
    
   ; Check that all parameters have values
   
   IF N_Elements(name) EQ 0 THEN name=' '
   IF N_Elements(value) EQ 0 THEN value = '0: Message Bar ' ELSE value='0: '+value
   IF N_Elements(msglimit) EQ 0 THEN msglimit = 21 
   IF N_Elements(state) EQ 0 THEN state=1
   IF N_Elements(xsize) EQ 0 THEN xsize = 10
   IF N_Elements(ysize) EQ 0 THEN ysize = 1
   IF N_Elements(scroll) EQ 0 THEN scroll = 1
   if n_elements(notimestamp) eq 0 then notimestamp = 0

  ; Set all parameters
  
   self.parent = parent
   self.name = name
   self.value = value
   self.messages = Ptr_New(value)
   self.msgLimit = msglimit
   self.state = state
   self.xsize = xsize
   self.ysize = ysize
   self.scroll = scroll
   self.notimestamp = notimestamp

  ; If bar is displayed then create the widget
   
   IF self.state EQ 1 THEN self->Draw

   RETURN, 1
END ;--------------------------------------------------------------------------------



PRO SPD_UI_MESSAGE_BAR__DEFINE

   struct = { SPD_UI_MESSAGE_BAR,   $
              parent: 0L,           $ ; id for the parent widget (must be a base)
              id: 0L,               $ ; widget id for the bar
              name: ' ',            $ ; optional name
              state: 0,             $ ; on/off flag (for display)
              value: ' ',           $ ; text to be displayed in the bar 
              messages:Ptr_New(),   $ ; max number of messages to buffer
              currentMsgId: 0L,        $ ; current id for messages
              msgLimit: 0,          $ ; number of messages to buffer
              xSize: 0,             $ ; size of bar in x direction
              ySize: 0,             $ ; size of bar in y direction
              scroll: 0,            $ ; flag to set scroll arrows
              notimestamp: 0,       $ ; notimestamp set or not?
              debug: 0              $ ; set this value to one for debugging

}

END
