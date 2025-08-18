
;+
;Method:
;  getPanelTitleSize
;
;Purpose:
;  Retreives the vertical size (in points) of the largest panel
;  title from an array of panel objects.
;
;Input:
;  panels: Array of panel object references
;
;Output:
;  return value: Largest vertical size (pts) 
;
;Notes:
;  see also: __getVariableSize
;            __getRowTextSizes
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-06-11 15:56:35 -0700 (Wed, 11 Jun 2014) $
;$LastChangedRevision: 15353 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getpaneltitlesize.pro $
;
;-
function spd_ui_draw_object::getPanelTitleSize,panels

    compile_opt idl2, hidden
  
  
  size = 0
  
  if undefined(panels) then return, size
  
  for i=0, n_elements(panels)-1 do begin
  
    panel = panels[i]
    
    if obj_valid(panel) && obj_isa(panel,'SPD_UI_PANEL') then begin
    
      panel->getproperty, settings=panelsettings
    
      if obj_valid(panelsettings) && obj_isa(panelsettings,'SPD_UI_PANEL_SETTINGS') then begin
        
        panelsettings->getproperty, titleobj=titleobj, titleMargin=titleMargin
        
        if obj_valid(titleobj) && obj_isa(titleobj,'SPD_UI_TEXT') then begin
          
          titleobj->getproperty, value=title, size=titleSize, show=showTitle
          
          if keyword_set(showTitle) && title ne '' then begin
            size = (titleSize + titleMargin) > size
          endif
          
        endif
      
      endif
      
    endif
  
  endfor
  
  return, size 
   
end
