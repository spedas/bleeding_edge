;+
;
;spd_ui_draw_object method: vBarOn
;
;start drawing a vertical bar on one or all panels
;Inputs:
;  all(boolean keyword):  Set to turn on for all panels.
;                         Default is for single panel mode
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__vbaron.pro $
;-
pro spd_ui_draw_object::vBarOn,all=all

  compile_opt idl2,hidden
  
  if keyword_set(all) then begin
    self.vBarOn = 2
  endif else begin
    self.vBarOn = 1
  endelse
  
end
