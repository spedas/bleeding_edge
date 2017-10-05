;+
;
;spd_ui_draw_object method: rubberBandOn
;
;Starts drawing the rubber band at the current location
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__rubberbandon.pro $
;-

pro spd_ui_draw_object::rubberBandOn

  compile_opt idl2,hidden
  
  self.rubberOn = 1
  self.rubberStart = self.cursorLoc
  
  if ~self->rubberBand(self.rubberStart,[0.,0.]) then begin
    self.statusBar->update,'Error: Problem drawing rubber band'
  ;t=error_message('Problem drawing rubber band',/traceback)
  endif
  
  self->draw
  
end
