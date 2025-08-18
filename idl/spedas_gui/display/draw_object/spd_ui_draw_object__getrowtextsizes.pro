;+
;spd_ui_draw_object method: getVariablesRowSizes
;
;Purpose:
;  generates an array that indicates the space variables will occupy for
;    each row in the layout, sizes are in pts
;  
;  INPUTS:
;    an array of spd_ui_panels
;    
;  OUTPUTS:
;    an array of sizes in pts
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-06-11 15:56:35 -0700 (Wed, 11 Jun 2014) $
;$LastChangedRevision: 15353 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getrowtextsizes.pro $
;-
pro spd_ui_draw_object::getRowTextSizes,panels, top_sizes=top_sizes, bottom_sizes=bottom_sizes

  compile_opt idl2,hidden

  panel_layouts = self->getPanelLayouts(panels)
  
  max_row = max(panel_layouts[*].row+panel_layouts[*].rSpan-1)
  
  bottom_sizes = dblarr(max_row)
  top_sizes = dblarr(max_row)
  
  for i = 0,max_row-1 do begin
  
    ;text below panel
    idx = where(panel_layouts[*].row+panel_layouts[*].rSpan-2 eq i,c)
    
    if c gt 0 then begin
      bottom_sizes[i] = self->getVariableSize(panels[idx])
    endif
  
    ;text above panel
    idx = where(panel_layouts[*].row-1 eq i,c)
    if c gt 0 then begin
      top_sizes[i] = self->getPanelTitleSize(panels[idx])
    endif
    
  endfor
  
  
end
