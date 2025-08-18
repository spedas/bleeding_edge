;+
;
;spd_ui_draw_object method: removeInstance
;
;this method will remove the instance hide settings from static components
;This is generally meant to be used by image export routines when the
;the legend is off,  if the legend is on, this method may leave the
;dynamic components of the legend hidden
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__removeinstance.pro $
;-
pro spd_ui_draw_object::removeInstance

  compile_opt idl2,hidden
  
  self->setModelHide,self.staticViews,0
  ;hide the components of the legend if they just got turned on
  ;by the previous call
  self->setLegendHide

end
