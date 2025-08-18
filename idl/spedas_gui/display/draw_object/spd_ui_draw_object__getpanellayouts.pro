;+
;spd_ui_draw_object method: getPanelLayouts
;
;This routine aggregates the layout structures from
;the panel objects into one array.  This makes certain
;layout operations simpler
;
;INPUTS:
;  panels: An array of spd_ui_panels
;  
;OUTPUTS:
;  an array of layout structures returned by the spd_ui_panel->getLayoutStructure() method
; 
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getpanellayouts.pro $
;-
function spd_ui_draw_object::getPanelLayouts,panels

  compile_opt idl2,hidden
  
  layout_struct = panels[0]->getLayoutStructure()
  
  layout_array = replicate(layout_struct,n_elements(panels))
  
  for i = 0,n_elements(panels)-1 do begin
    layout_array[i] = panels[i]->getLayoutStructure()
  endfor

  return,layout_array

end
