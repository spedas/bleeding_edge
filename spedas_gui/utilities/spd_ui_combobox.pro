;+
; NAME:
;   SPD_UI_COMBOBOX
;
; PURPOSE:
;   IDL combobox doesn't actually support null strings('') as entries
;   in the combobox. Entering a null string will generate an error that halts
;   execution.  This is a simple wrapper compound widget to fix this problem
;   by making the box appear empty when it is not.
;
; CALLING SEQUENCE:
;   Result = SPD_UI_COMBOBOX
; 
; KEYWORD PARAMETERS:
;  Exactly the same as normal combobox
; EVENT STRUCTURE:
;  The same as normal combobox, with the exception that the
;  event structure is called 'SPD_UI_COMBOBOX'
;-

function spd_ui_combobox, $
         parent,$
         editable=editable,$
         xsize=xsize,$
         ysize=ysize,$
         value=value,$
         uvalue=uvalue,$
         uname=uname
         
  compile_opt idl2
  
  
  return,widget_combobox(parent,$
                         editable=editable,$
                         xsize=xsize,$
                         ysize=ysize,$
                         value=value,$
                         uvalue=uvalue,$
                         uname=uname)
  
end
