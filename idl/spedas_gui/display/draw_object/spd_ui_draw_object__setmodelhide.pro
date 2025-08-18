;+
;
;spd_ui_draw_object method: setModelHide
;
;This routine sets the hide values for all the models inside the views that it receives as an argument
;It just exists to remove some duplication that occurs when generating an instanced display
;This is a recursive function
;
;Inputs:
;  hidevalue(boolean): The value that the hide flag will be set to.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__setmodelhide.pro $
;-

pro spd_ui_draw_object::setModelHide,input,hideValue

  compile_opt idl2,hidden
 
  if obj_isa(input,'IDLgrModel') then begin
    input->setProperty,hide=hideValue
  endif else if obj_isa(input,'IDL_Container') then begin
    list = input->get(/all,count=c)
  
    if c gt 0 then begin
      for i = 0,c-1 do begin
      
        self->setModelHide,list[i],hideValue
      
      endfor
    endif
  endif 
    
end
