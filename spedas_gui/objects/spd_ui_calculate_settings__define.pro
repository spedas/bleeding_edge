;+ 
;NAME: 
; spd_ui_calculate_settings__define
;
;PURPOSE:  
;  Keeps track of state for calculate panel when closed.
;
;CALLING SEQUENCE:
; calcSettings = Obj_New("SPD_UI_CALCULATE_SETTINGS")
;
;INPUT:
; none
;
;ATTRIBUTES:
;
;  path:  string, path to the calculate file
;  name: string,name of the calculate file
;  text: string array, containing text of the buffer
;
;OUTPUT:
;  calculate settings object reference
;
;METHODS:
;   
;  GetProperty
;  SetProperty
;
;NOTES:
;  Methods: GetAll,SetAll are now managed automatically using the parent class spd_ui_getset.  
;  You can still call these methods when using objects of type spd_ui_calculate_settings__define, and
;  call them in the same way as before
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-16 11:55:55 -0700 (Thu, 16 Apr 2015) $
;$LastChangedRevision: 17342 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_calculate_settings__define.pro $
;
;-----------------------------------------------------------------------------------

pro spd_ui_calculate_settings::setProperty,$
                                      text=text,$
                                      _extra=ex
   
   ;handle general cases using parent class
   self->spd_ui_getset::setProperty,_extra=ex
   
   ;handle special case
   if n_elements(text) ne 0 then begin
          ptr_free,self.text
          self.text = ptr_new(text)
   endif
   

                                      
end

pro spd_ui_calculate_settings::getProperty,$
                                 text=text,$
                                 _ref_extra=ex

  ;handle general case using parent class
  self->spd_ui_getset::getProperty,_extra=ex

  ;handle special case
  if arg_present(text) then begin
    if ptr_valid(self.text) then begin
      text = *self.text
    endif else begin
      test = ''
    endelse
  endif      
                                 
end


function spd_ui_calculate_settings::init

  self.name = '-scratch-'
  text = strarr(1)
  text[0] = ' '
  self.text = ptr_new(text)
  return,1
  
end

pro spd_ui_calculate_settings__define

  struct = { SPD_UI_CALCULATE_SETTINGS, $
               path:'',$
               name:'',$
               text:ptr_new(), $
               inherits spd_ui_getset    $ ; generalized setProperty/getProperty/getAll/setAll methods   
               }

end

