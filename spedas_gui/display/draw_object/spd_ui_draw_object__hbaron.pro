;+
;
;spd_ui_draw_object method: hBarOn
;
;start drawing the horizontal bar
;  all(boolean keyword):  Set to turn on for all panels.
;                         Default is for single panel mode
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__hbaron.pro $
;-

pro spd_ui_draw_object::hBarOn,all=all

  compile_opt idl2,hidden
  
  if keyword_set(all) then begin
    self.hBarOn = 2
  endif else begin
    self.hBarOn = 1
  endelse
  
end
