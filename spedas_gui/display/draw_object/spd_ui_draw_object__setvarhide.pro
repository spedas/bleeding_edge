;+
;
;spd_ui_draw_object method: setVarHide
;
;This routine sets the hide value for variables on a panel with
;a particular index.  It is mainly here for organization and to prevent duplication
;
;Inputs:
;  hidevalue(boolean): The value that the hide flag will be set to.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__setvarhide.pro $
;-

pro spd_ui_draw_object::setVarHide,panel,hideValue

  compile_opt idl2,hidden

  if ptr_valid(panel.varInfo) then begin
  
     for j = 0,n_elements(*panel.varInfo)-1 do begin
        var = (*panel.varInfo)[j]
        
        if obj_valid(var.textObj) then begin
          var.textObj->setProperty,hide=hideValue
        endif
     endfor
    
   endif

end
