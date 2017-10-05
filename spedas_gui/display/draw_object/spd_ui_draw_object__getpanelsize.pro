;+
;spd_ui_draw_object method: GetPanelSize
;
;Returns an array that shows panel size.
;Inputs:
;  xdims(2 element double array):  The start and stop position of the panel x-axis, coordinates normalized to the draw area 
;  ydims(2 element double array):  The start and stop position of the panel y-axis, coordinates normalized to the draw area 
;Outputs:
;  array format = [xpos,ypos,width,height]
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getpanelsize.pro $
;-
function spd_ui_draw_object::getPanelSize,xdims,ydims

  compile_opt idl2
  
  xpos = self->norm2pt(xdims[0],0)
  xlen = self->norm2pt(xdims[1]-xdims[0],0)
  ypos = self->norm2pt(ydims[0],1)
  ylen = self->norm2pt(ydims[1]-ydims[0],1)
  
  return,[xpos,ypos,xlen,ylen]
  
end
