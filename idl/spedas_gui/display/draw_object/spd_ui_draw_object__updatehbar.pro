;+
;spd_ui_draw_object method: updateHBar
;
;This routine updates the location of the horizontal bar 
;in each panel.  Behavior is a function of the various
;tracking options and the location of the cursor
;
;location(2-element double): The position of the cursor
;in coordinates normalized to the draw area
;
;panelInfo(pointer to array of structs): Each struct stores the
;metadata for each panel in a format for internal use by the draw object
; 
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__updatehbar.pro $
;-
pro spd_ui_draw_object::updateHBar,location,panelInfo

  compile_opt idl2,hidden

 ;single panel hBar draw mode
  if self.hBarOn eq 1 && ptr_valid(panelInfo) then begin
  
    ;loop over each panel
    for i = 0,n_elements(*panelInfo)-1 do begin
    
      xpos = ((*panelInfo)[i]).xplotpos
      ypos = ((*panelInfo)[i]).yplotpos
      hBar = ((*panelInfo)[i]).hBar
      anno = ((*panelInfo)[i]).annotation
      view = ((*panelInfo)[i]).view
      
      ;For some reason updating the location of the existing bar did not work
      ;So instead, we destroy the old one and create a new one
      old = hBar->get(/all)
      if obj_valid(old) then obj_destroy,old
      hBar->remove,/all
      
      ;If the cursor is within panel bounds, a new horizontal bar is created
      if self->inBounds((*panelInfo)[i]) then begin
      
        yobjpos = (location[1] - ypos[0])/(ypos[1]-ypos[0])
        
        hBar->add,obj_new('IDLgrPolyline',[0.,1.],[yobjpos,yobjpos],[.5,.5],color=self->convertColor([0,0,0]),hide=0,/double)
      endif
      
    ;self.destination->draw,view
    ;self.destination->draw,anno
      
    endfor
    
  ;multiple panel hBar draw mode
  endif else if self.hBarOn eq 2 && ptr_valid(panelInfo) then begin
  
    drawbar = 0
    
    ;this section determines if the cursor is within the area of *any*
    ;panel
    for i = 0,n_elements(*panelInfo)-1 do begin
    
      xpos = ((*panelInfo)[i]).xplotpos
      ypos = ((*panelInfo)[i]).yplotpos
      hBar = ((*panelInfo)[i]).hBar
      anno = ((*panelInfo)[i]).annotation
      view = ((*panelInfo)[i]).view
      
      ;For some reason updating the location of the existing bar did not work
      ;So instead, we destroy the old one and create a new one
      old = hBar->get(/all)
      if obj_valid(old) then obj_destroy,old
      hBar->remove,/all
      
      ;If we're inside the bounds of the panel, we note the location, and that we're inside *some* panel
      if self->inBounds((*panelInfo)[i]) then begin
      
        yobjpos = (location[1] - ypos[0])/(ypos[1]-ypos[0])
        
        drawbar = 1
        
      ;vBar->add,obj_new('IDLgrPolyline',[xobjpos,xobjpos],[0.,1.],[.5,.5],color=self->convertColor([0,0,0]),hide=0)
      endif
      
    endfor
    
    ;If it is in bounds on some panel, then draw the hbar proportional to each panel
    if drawBar then begin
    
      for i = 0,n_elements(*panelInfo)-1 do begin
      
        xpos = ((*panelInfo)[i]).xplotpos
        ypos = ((*panelInfo)[i]).yplotpos
        hBar = ((*panelInfo)[i]).hBar
        anno = ((*panelInfo)[i]).annotation
        view = ((*panelInfo)[i]).view
        
        ;anno->setProperty,hide=0
        ;vBar->remove,/all
        hBar->add,obj_new('IDLgrPolyline',[0.,1.],[yobjpos,yobjpos],[.5,.5],color=self->convertColor([0,0,0]),hide=0,/double)
        
      endfor
      
    endif
    
  endif
  
end
