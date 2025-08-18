;+ 
;NAME: 
; spd_ui_dprint_display
;
;PURPOSE:  
; Object to handle error reporting from ssl_general routines that use dprint
;
;CALLING SEQUENCE:
; spd_ui_display = Obj_New("SPD_UI_DPRINT_DISPLAY")
;
;
;
;METHODS:
; GetProperty
; SetProperty
; Print
;
;HISTORY:
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_dprint_display__define.pro $
;-----------------------------------------------------------------------------------

pro spd_ui_dprint_display::print,message_array,prefix=prefix

  compile_opt idl2

  if ~keyword_set(prefix) then begin
    prefix=''
  endif
  
   prefix_len = strlen(prefix)
   spaces = prefix_len gt 0 ? string(replicate(32b,prefix_len)) : ''

   for i = 0,n_elements(message_array)-1 do begin
     if i eq 0 then begin
       msg = prefix+message_array[i]
     endif else begin
       msg = spaces+message_array[i]
     endelse
     
     if obj_valid(self.hWin) then begin
       self.hWin->update,msg
     endif
     
     if obj_valid(self.sBar) then begin
       self.sBar->update,msg
     endif
   endfor
end

pro spd_ui_dprint_display::getProperty,statusBar=statusBar,historyWin=historyWin

  statusBar=self.sBar
  historyWin=self.hWin

end

pro spd_ui_dprint_display::setProperty,statusBar=statusBar,historyWin=historyWin

  compile_opt idl2

  if obj_valid(statusBar) && obj_isa(statusBar,'spd_ui_message_bar') then begin
    self.sBar=statusBar
  endif
  
  if obj_valid(historyWin) && obj_isa(historyWin,'spd_ui_history') then begin
    self.hWin=historyWin
  endif
    
end

  
function spd_ui_dprint_display::init,statusBar=statusBar,historyWin=historyWin

  compile_opt idl2

   self->setProperty,statusBar=statusBar,historyWin=historyWin
   return, 1
end ;--------------------------------------------------------------------------------                 

pro spd_ui_dprint_display__define

  compile_opt idl2

   struct = { spd_ui_dprint_display,$
              sBar:obj_new(),$
              hWin:obj_new()$
             }

end
