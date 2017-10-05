;+
;
;spd_ui_draw_object method: hueRotation
;
;This rotates the hue of of the input color by 120 degrees
;The output is the rotated color 
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__huerotation.pro $
;-

function spd_ui_draw_object::hueRotation,color

  compile_opt idl2,hidden
  
  color_convert,color[0],color[1],color[2],hue,light,sat,/rgb_hls
  hue = (hue + 120) mod 360
  light = 1 - light
  color_convert,hue,light,sat,red,grn,blu,/hls_rgb
  return,[red,grn,blu]
  
end
