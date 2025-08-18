;+
;spd_ui_draw_object method: SetClick
;
;This routine performs the draw work necessary to display a marker click
;basically this means mutating the selected flag on markerinfo.
;Then when drawn the marker will show up with the appropriate highlighting
;
;Inputs:
;  InfoStruct(struct) : This is the struct returned by spd_ui_draw_object::getClick
;  
;NOTES:
;  This is separated from getclick() to preserve separation between routines that 
;     give information on the display, and ones that mutate display.
;     This way, the calling routine doesn't need to expect a mutation to
;     query the layout 
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__setclick.pro $
;-

pro spd_ui_draw_object::setClick,infostruct

  compile_opt idl2,hidden
  
  ;Doesn't assume infostruct exists to
  ;Allow direct passthrough of getClick output
  ;and to avoid failing when calling routine fails
  if keyword_set(infostruct) && $
    is_struct(infostruct) && $
    infostruct.marker ne -1 && $
    ptr_valid(self.panelInfo) then begin
    
    panels = *self.panelInfo
    
    ;loop over panels to find the selected panel
    for i = 0,n_elements(panels)-1 do begin
    
      if ptr_valid(panels[i].markerInfo) then begin
      
        markers = *panels[i].markerInfo
        
        ;Find the selected value of the currently clicked marker
        if i eq infostruct.panelidx then begin
          old_selected = markers[infostruct.marker].selected
        endif
        
        ;Deselect all other markers.
        ;This is the line that prevents multi-select,ATM
        markers[*].selected = 0
        
        ;If we've got a selection, then flip the selected value
        if i eq infostruct.panelidx then begin
        
          if old_selected eq 1 then begin
            markers[infostruct.marker].selected = 0
          endif else begin
            markers[infostruct.marker].selected = 1
          endelse
          
        endif
        
        ;Replace old marker structs with new-ones to guarantee proper mutation
        ptr_free,panels[i].markerInfo
        panels[i].markerInfo = ptr_new(markers)
        
      endif
      
    endfor
    
    ;Replace old panel structs with new-ones to guarantee proper mutation
    ptr_free,self.panelInfo
    self.panelInfo = ptr_new(panels)
    
  endif
  
  ;This will update the display to show any changed colors
  self->setCursor,self.cursorloc
end
