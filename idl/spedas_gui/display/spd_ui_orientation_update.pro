;+
;
;Purpose:
;  helper function, just colocates some replicated code to modify the
;  canvas size if there is variation when windows or modes are switched.
; 
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/spd_ui_orientation_update.pro $
;-

pro spd_ui_orientation_update,drawObject,windowStorage;, rezoom=rezoom

  cwindow = windowstorage->getactive()
  cwindow->getproperty, settings=cwsettings
  cwsettings->getproperty,canvasSize=canvasSize
  drawObject->getProperty,pageSize=pageSize,destination=dest
  
  if (canvasSize[0] ne pageSize[0] || $
      canvasSize[1] ne pageSize[1]) && $
      obj_valid(dest) then begin
      
      cz = drawObject->getZoom()
      
      ;Note 1: this is done using !D values for consistency with spd_gui
      ;to get reliable behavior, both sections should probably be switched over
      ;to use the resolution property of the window object
      ;Note 2:multiplying by CZ accounts for the difference in reported canvas size that occurs when not at 1.0 zoom
      ;Previous implementations set zoom to 1.0 before changing canvas dimensions.
      ;This could would cause distortions when changing between canvases of different sizes and not at 1.0 zoom
      size_px = [canvasSize[0]*2.54*!D.X_PX_CM,canvasSize[1]*2.54*!D.Y_PX_CM]*cz 
      ;
      ;size_px = [pageSize[0]*2.54*!D.X_PX_CM,pageSize[1]*2.54*!D.Y_PX_CM]
      dest->getProperty,resolution=res
     ; size_px = size_cm/res  
;      drawObject->setZoom,1
      dest->setProperty,virtual_dimensions=size_px
;      drawObject->setZoom,cz
;      
     ;I tentatively removed the rezoom kluge.  I *think* that multiplying size_px by cz makes the kluge unnecessary. pcruce
     ; rezoom=1b
  endif

end
