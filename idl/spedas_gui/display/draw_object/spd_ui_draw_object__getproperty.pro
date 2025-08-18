;+
;
;spd_ui_draw_object method: getProperty
;
;
;Query various draw object settings
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getproperty.pro $
;-
pro spd_ui_draw_object::getProperty, $
    destination=destination, $
    markerOn=markerOn, $
    legendOn=legendOn, $
    rubberOn=rubberOn, $
    vBarOn=vBarOn, $
    hBarOn=hBarOn, $
    pageSize=pageSize,$
    lineres=lineres,$
    specres=specres, $
    pointmax=pointmax
    
  compile_opt idl2
  
  destination = self.destination
  markerOn = self.markerOn
  legendOn = self.legendOn
  rubberOn = self.rubberOn
  vBarOn = self.vBarOn
  hBarOn = self.hBarOn
  pageSize = self.currentpageSize
  lineres = self.lineres
  specres = self.specres
  pointmax = self.pointmax
end
