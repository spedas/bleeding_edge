;+
;spd_ui_draw_object method: setCursor
;Makes a vertical bar, updates legends, draws rubber band,
;draws markers(during draw animation), highlights markers
;during mouseover. 
;This routine should be called pretty much
;any time the cursor moves in the draw area.
;
;Location(2-element double):  The cursor location
;in coordinates normalized to the draw area size.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__setcursor.pro $
;-
pro spd_ui_draw_object::setCursor,location

  compile_opt idl2,hidden
  
 ; tm = systime(/seconds)
  
  self.cursorloc = location
  
  ;update the position of the vertical and horizontal bar
  self->updateVBar,location,self.panelInfo
  self->updateHBar,location,self.panelInfo
  
  ;If the rubber band is turned on then update its position when
  ;the cursor position is updated
  if self.rubberOn then begin
  
    if ~self->rubberBand(self.rubberStart,self.cursorLoc - self.rubberStart) then begin
      self.statusBar->update,'Problem drawing rubber band'
    ;t=error_message('Problem drawing rubber band',/traceback)
    endif
    
  endif
  
  ;Single panel legend update block
  if self.legendOn eq 1 && ptr_valid(self.panelInfo) then begin
  
    ;loop over panels
    for i = 0,n_elements(*self.panelInfo)-1 do begin
    
      panel = ((*self.panelInfo)[i])
      
      ;if the cursor is within this panel then update the legend
      if self->inBounds(panel) then begin
      
        ;calculate normalized position of cursor relative to the panel
        xposnorm = (location[0] - panel.xplotpos[0])/(panel.xplotpos[1]-panel.xplotpos[0])
        yposnorm = (location[1] - panel.yplotpos[0])/(panel.yplotpos[1]-panel.yplotpos[0])
        
        ;turn on the legend model(so the legend will be visible)
        if obj_valid(panel.legendModel) then begin
          panel.legendModel->setProperty,hide=0
        endif
        
        ;turn on the annotation model(the actual text objects that the numbers are drawn to are stored in these models)
        if obj_valid(panel.legendAnnoModel) then begin
          panel.legendAnnoModel->setProperty,hide=0
        endif
        
        ;make any variable annotations visible for this panel
        self->setVarHide,panel,0
        ;now update the values in the legend for this panel
        self->updatelegend,[xposnorm,yposnorm],panel
        
      endif else begin
      
        ;if we're out of bounds, hide everything
        if obj_valid(panel.legendModel) then begin
          panel.legendModel->setProperty,hide=1
        endif
        
        if obj_valid(panel.legendAnnoModel) then begin
          panel.legendAnnoModel->setProperty,hide=1
        endif
        
        self->setVarHide,panel,1
      
        ;self->updateLegend,0,0,panel,/blank
        
      endelse
      
    endfor
    
  ;multiple panel legend update block
  endif else if self.legendOn eq 2 && ptr_valid(self.panelInfo) then begin
  
    drawlegend = 0
    
    ;if the cursor is within the bounds of *any* panel, then we update all panels
    ;with values proportional to the panel that the cursor is currently positioned over
    for i = 0,n_elements(*self.panelInfo)-1 do begin
    
      panel = ((*self.panelInfo)[i])
      
      if self->inBounds(panel) then begin
      
        drawlegend = 1
        inBoundsIndex = i
        xposnorm = (location[0] - panel.xplotpos[0])/(panel.xplotpos[1]-panel.xplotpos[0])
        yposnorm = (location[1] - panel.yplotpos[0])/(panel.yplotpos[1]-panel.yplotpos[0])
        
      endif
      
    endfor
    
    ;this block actually does the updating
    if drawlegend then begin
      for i = 0,n_elements(*self.panelInfo)-1 do begin
      
        panel = ((*self.panelInfo)[i])
        
        ;turn on the legend model(so the legend will be visible)
        if obj_valid(panel.legendModel) then begin
          panel.legendModel->setProperty,hide=0
        endif
        
        ;turn on the annotation model(the actual text objects that the numbers are drawn to are stored in these models)
        if obj_valid(panel.legendAnnoModel) then begin
          panel.legendAnnoModel->setProperty,hide=0
        endif
        
        ;make any variable annotations visible for this panel
        self->setVarHide,panel,0
        
        if i eq inBoundsIndex then begin
          self->updatelegend,[xposnorm,yposnorm],panel
        endif else begin
          self->updatelegend,[xposnorm,yposnorm],panel,/noyvalue  
        endelse
      endfor
    endif else begin ;if we aren't drawing blank the text
    
      for i = 0,n_elements(*self.panelInfo)-1 do begin
      
        panel = ((*self.panelInfo)[i])
        
        ;if we're out of bounds, hide everything
        if obj_valid(panel.legendModel) then begin
          panel.legendModel->setProperty,hide=1
        endif
      
        if obj_valid(panel.legendAnnoModel) then begin
          panel.legendAnnoModel->setProperty,hide=1
        endif
      
        self->setVarHide,panel,1
        self->updateLegend,[0,0],panel,/blank

      endfor
      
    endelse
  endif else if ptr_valid(self.panelInfo) then begin
  
    ;loop over panels
    for i = 0,n_elements(*self.panelInfo)-1 do begin
    
      panel = ((*self.panelInfo)[i])
  
      ;if we're out of bounds, hide everything
      if obj_valid(panel.legendModel) then begin
        panel.legendModel->setProperty,hide=1
      endif
      
      if obj_valid(panel.legendAnnoModel) then begin
        panel.legendAnnoModel->setProperty,hide=1
      endif
      
      self->setVarHide,panel,1
    
    endfor
  
  endif
  
  ;Determine if marker should be drawn on cursor update
  ;Single panel marking
  ;This block executes when we are in the process of drawing a new marker
  if self.markerOn eq 1 && $
    ptr_valid(self.panelInfo) && $
    ptr_valid(self.currentMarkers) then begin
    
    panels = *self.panelInfo
    
    ;finds out if the cursor is over a panel and updates the marker position if it is
    for i=0,n_elements(panels)-1 do begin
      if self->inBounds(panels[i]) && $
        self->inBounds(panels[i],location=self.markerStart) then begin
        
        xstart = (self.markerStart[0] - panels[i].xplotpos[0])/(panels[i].xplotpos[1]-panels[i].xplotpos[0])
        xstop = (self.cursorloc[0] - panels[i].xplotpos[0])/(panels[i].xplotpos[1]-panels[i].xplotpos[0])
        
        self->drawMarker,[xstart,xstop],panels[i],(*self.currentMarkers)[0]
        
      endif
      
    endfor
    
  ;multiple panel marking
  ;This block executes when new markers are being drawn on all panels
  endif else if self.markerOn eq 2 && $
    ptr_valid(self.panelInfo) && $
    ptr_valid(self.currentMarkers) then begin
    
    panels = *self.panelInfo
    
    inBounds = 0
    
    ;determine if the cursor is within the bounds of any marker
    for i = 0,n_elements(panels)-1 do begin
      if self->inBounds(panels[i]) && $
        self->inBounds(panels[i],location=self.markerstart) then begin
        inBounds = 1
        xstart = (self.markerStart[0] - panels[i].xplotpos[0])/(panels[i].xplotpos[1]-panels[i].xplotpos[0])
        xstop = (self.cursorloc[0] - panels[i].xplotpos[0])/(panels[i].xplotpos[1]-panels[i].xplotpos[0])
      endif
    endfor
    
    ;if yes then update all markers with x-value proportional
    ;to the panel that the cursor is within
    if inBounds then begin
    
      markers = *self.currentMarkers
      
      for i = 0,n_elements(panels)-1 do begin
        self->drawMarker,[xstart,xstop],panels[i],markers[i]
      endfor
    endif
    
  endif
  
  ;highlight markers during mouseover
  if ptr_valid(self.panelInfo) then begin
  
    panels = *self.panelInfo
    
    ;loop over panels
    for i = 0,n_elements(panels) -1 do begin
     
     
      ;if we have any markers on this panel
      if ptr_valid(panels[i].markerInfo) then begin
      
        xloc = (location[0] - panels[i].xplotpos[0])/(panels[i].xplotpos[1]-panels[i].xplotpos[0])
        
        marked = 0 ; to make sure only one panel gets marked
        
        ;loop over the markers on this panel
        for j = n_elements(*panels[i].markerInfo)-1,0,-1 do begin
        
          marker = (*panels[i].markerInfo)[j]
          
          ;determine if the cursor is over each marker on this panel or not and update the color by rotating the hue 120 or 240 degrees.
          if marker.displayed then begin
          
            ;these first two cases execute identically.  Their results are distinct because marker.color is different if a marker is selected
            ;So rotation ends up occuring from a different starting point
            ;Mouse is over selected marker 
            if (xloc ge marker.pos[0] && xloc le marker.pos[1] && ~marked && self->inBounds(panels[i])) && marker.selected then begin
              marked = 1
              marker.frames[0]->setProperty,color=self->convertColor(self->hueRotation(marker.color))
              marker.frames[1]->setProperty,color=self->convertColor(self->hueRotation(marker.color))
              panels[i].markerIdx = j
            ;Mouse is over unselected marker
            endif else if xloc ge marker.pos[0] && xloc le marker.pos[1] && ~marked && self->inBounds(panels[i]) then begin
              marked = 1
              marker.frames[0]->setProperty,color=self->convertColor(self->hueRotation(marker.color))
              marker.frames[1]->setProperty,color=self->convertColor(self->hueRotation(marker.color))
              panels[i].markerIdx = j
            ;Mouse is not over marker, but it is selected
            endif else if marker.selected then begin
              marker.frames[0]->setProperty,color=self->convertColor(self->huerotation(self->hueRotation(marker.color)))
              marker.frames[1]->setProperty,color=self->convertColor(self->huerotation(self->hueRotation(marker.color)))
            ;Mouse is not over marker and it is not selected
            endif else begin
              marker.frames[0]->setProperty,color=self->convertColor(marker.color)
              marker.frames[1]->setProperty,color=self->convertColor(marker.color)
            endelse
          endif
          
        endfor
        
        ;Making sure the no-marked code is properly updated in the meta-data
        if ~marked then begin
          panels[i].markerIdx = -1
        endif
        
      endif
      
    endfor
    
    ;replace old panel metadata with updated quantities
    ptr_free,self.panelInfo
    self.panelInfo = ptr_new(panels)
    
  endif
  
  ;print,'TM1: ' + strtrim(string((systime(/seconds)-tm)),2)
  
  ;self.destination->draw,self.scene,/draw_instance
  self->draw
  
  ;print,'TM2: ' + strtrim(string((systime(/seconds)-tm)),2)
  
end
