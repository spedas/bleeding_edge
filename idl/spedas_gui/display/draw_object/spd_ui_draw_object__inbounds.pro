;+
;spd_ui_draw_object method: inBounds
;
;returns true if the current cursor location is within the bounds of the panel past as an argument
;panelInfo(struct):  struct that stores information for the draw object about the panel in question
;location(keyword, 2-element double):  Overrides the default location stored in self.cursorLoc with the value in the keyword
;                                      Default behavior uses self.cursorloc
; 
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__inbounds.pro $
;-
function spd_ui_draw_object::inBounds,panelInfo,location=location

  compile_opt idl2,hidden
  
  if ~keyword_set(location) then location = self.cursorloc
  
  ;print,'x',panelInfo.xplotpos,'y',panelInfo.yplotpos
  
  return,location[0] ge panelInfo.xplotpos[0] && $
    location[0] le panelInfo.xplotpos[1] && $
    location[1] ge panelInfo.yplotpos[0] && $
    location[1] le panelInfo.yplotpos[1]
    
end
