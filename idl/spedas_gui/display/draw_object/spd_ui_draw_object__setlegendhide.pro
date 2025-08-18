;+
;
;spd_ui_draw_object method: setLegendHide
;
;Because the static components of the legend are still somewhat
;dynamic(Because they can be manipulated between updates), 
;This routine is needed to manipulate them separately
;From the lists in self.staticViews & self.dynamicViews
;Inputs:
;  dynamic(boolean keyword):, set to hide dynamic component of the legend
;  hide:(boolean): set to the hide value you want to use
; 
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__setlegendhide.pro $
;-

pro spd_ui_draw_object::setLegendHide,dynamic=dynamic,hide=hide

 compile_opt idl2,hidden

 if n_elements(hide) gt 0 then begin
   if keyword_set(hide) then begin
     hideValueDynamic = 1
     hideValueStatic = 1
   endif else begin
     hideValueDynamic = 0
     hideValueStatic = 0
   endelse 
 endif else if self.legendOn eq 1 || self.legendOn eq 2 then begin
   if keyword_set(dynamic) then begin
     hideValueStatic = 0
     hideValueDynamic = 0
   endif else begin
     hideValueDynamic = 1
     hideValueStatic = 1
   endelse
 endif else begin
   hideValueDynamic = 1
   hideValueStatic = 1
 endelse

 if ptr_valid(self.panelInfo) then begin
  
   for i = 0,n_elements(*self.panelInfo)-1 do begin
    
     panel = (*self.panelInfo)[i]
      
     if ~obj_valid(panel.legendModel) then continue
    
  ;   print,i,hidevaluestatic,hidevaluedynamic
    
     panel.legendModel->setProperty,hide=hideValueStatic
     panel.legendAnnoModel->setProperty,hide=hideValueDynamic
    
     self->setVarHide,panel,hideValueDynamic
      
   endfor
    
  endif

end
