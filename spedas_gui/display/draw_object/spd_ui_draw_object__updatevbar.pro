;+
;spd_ui_draw_object method: updateVBar
;This routine updates the location of the vertical bar 
;in each panel.  Behavior is a function of the various
;tracking options and the location of the cursor
;
;location(2-element double): The position of the cursor
;in coordinates normalized to the draw area
;
;panelInfo(pointer to array of structs): Each struct stores the
;metadata for each panel in a format for internal use by the draw object
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__updatevbar.pro $
;-
pro spd_ui_draw_object::updateVBar,location,panelInfo

  compile_opt idl2,hidden

 ;single panel vBar draw mode
  if self.vBarOn eq 1 && ptr_valid(panelInfo) then begin
  
    for i = 0,n_elements(*panelInfo)-1 do begin
    
      xpos = ((*panelInfo)[i]).xplotpos
      ypos = ((*panelInfo)[i]).yplotpos
      vBar = ((*panelInfo)[i]).vBar
      anno = ((*panelInfo)[i]).annotation
      view = ((*panelInfo)[i]).view
      
      ;For some reason updating the location of the existing bar did not work
      ;So instead, we destroy the old one and create a new one
      old = vBar->get(/all)
      if obj_valid(old) then obj_destroy,old
      vBar->remove,/all
      
      ;If we're inside the bounds of the panel, we create the new bar
      if self->inBounds((*panelInfo)[i]) then begin
      
        xobjpos = (location[0] - xpos[0])/(xpos[1]-xpos[0])
        
        vBar->add,obj_new('IDLgrPolyline',[xobjpos,xobjpos],[0.,1.],[.5,.5],color=self->convertColor([0,0,0]),hide=0,/double)
      endif
      
    ;self.destination->draw,view
    ;self.destination->draw,anno
      
    endfor
    
  ;multiple panel vBar draw mode
  endif else if self.vBarOn eq 2 && ptr_valid(panelInfo) then begin
  
    drawbar = 0
    
    ;this section determines if the cursor is within the area of *any*
    ;panel, we loop over all panels
    for i = 0,n_elements(*panelInfo)-1 do begin
    
      xpos = ((*panelInfo)[i]).xplotpos
      ypos = ((*panelInfo)[i]).yplotpos
      vBar = ((*panelInfo)[i]).vBar
      anno = ((*panelInfo)[i]).annotation
      view = ((*panelInfo)[i]).view
      
      ;For some reason updating the location of the existing bar did not work
      ;So instead, we destroy the old one and create a new one
      old = vBar->get(/all)
      if obj_valid(old) then obj_destroy,old
      vBar->remove,/all
      
      ;If we're inside the bounds of the panel, we note the location, and that we're inside *some* panel
      if self->inBounds((*panelInfo)[i]) then begin
      
        xobjpos = (location[0] - xpos[0])/(xpos[1]-xpos[0])
        
        drawbar = 1
        
      ;vBar->add,obj_new('IDLgrPolyline',[xobjpos,xobjpos],[0.,1.],[.5,.5],color=self->convertColor([0,0,0]),hide=0)
      endif
      
    endfor
    
    ;If it is in bounds, then draw the vbar proportional to each panel.
    if drawBar then begin
    
      for i = 0,n_elements(*panelInfo)-1 do begin
      
        xpos = ((*panelInfo)[i]).xplotpos
        ypos = ((*panelInfo)[i]).yplotpos
        vBar = ((*panelInfo)[i]).vBar
        anno = ((*panelInfo)[i]).annotation
        view = ((*panelInfo)[i]).view
        
        ;anno->setProperty,hide=0
        ;vBar->remove,/all
        vBar->add,obj_new('IDLgrPolyline',[xobjpos,xobjpos],[0.,1.],[.5,.5],color=self->convertColor([0,0,0]),hide=0,/double)
        
      endfor
      
    endif
    
  endif
  
end
