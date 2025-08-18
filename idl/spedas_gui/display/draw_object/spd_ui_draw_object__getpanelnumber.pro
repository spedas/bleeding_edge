;+
;spd_ui_draw_object method: GetPanelNumber
;
;Returns the number of panels currently displayed
;If there is any confusion about the output panel indices, 
;This indicates the maximum value.  0 indicates no panels
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getpanelnumber.pro $
;-
function spd_ui_draw_object::getPanelNumber

  compile_opt idl2,hidden
  
  if ~ptr_valid(self.panelInfo) then return,0
  
  return,n_elements(*self.panelInfo)
  
end
