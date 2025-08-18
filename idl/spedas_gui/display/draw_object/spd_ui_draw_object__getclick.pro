;+
;spd_ui_draw_object method: GetClick
;
;
;returns a struct that identifies that panel and the part of the panel under the cursor
;Uses self.cursorLoc to determine current cursor location.
;Output:
;  Struct of the form: {panelidx:0L,component:0,marker:-1}
;PanelIdx(long):  An index into the list of panels on the currently drawn display, not the panel ID field
;Components(short):  0=plot,1=xaxis,2=yaxis,3=zaxis,4=variables,5=legend
;Marker: the index of any marker under the cursor, is -1 if none, index is an index into the list of markers currently stored in the IDL_Container on the copy
;Returns 0L if click is nothing(ie page)
;
;NOTES:
;  Resolution of position is only approximate at this point.
;  In particular, this could be better and distinguishing z-axis from x/yaxis and variable from x axis
;
;  Things that need to be done to improve approximation, account for text height, take layout issues
;  into account.  Resolve variable/z-axis on the same size.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-07-31 09:46:47 -0700 (Thu, 31 Jul 2014) $
;$LastChangedRevision: 15631 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getclick.pro $
;-
function spd_ui_draw_object::getClick

  compile_opt idl2,hidden
  
  if ~ptr_valid(self.panelInfo) then return,0
  
  panels = *self.panelInfo
  
  loc = self.cursorloc
  
  markeridx = -1L
  panelidx = -1L
  
  ;loop through panels
  for i = 0,n_elements(panels)-1 do begin
  
    xpos = panels[i].xplotpos
    ypos = panels[i].yplotpos
    margins = panels[i].margins
    place = panels[i].zplacement
    
    xdiv = xpos[1]-xpos[0]
    ydiv = ypos[1]-ypos[0]
    
    ; check if the user clicked inside a legend
    legendObj = *panels[i].legendInfo
    if obj_valid(legendObj) then begin
        legendObj->getProperty, bvalue=legendbottom, $
            lvalue=legendleft, wvalue=legendwidth, hvalue=legendheight, $
            bunit=bunit, lunit=lunit, wunit=wunit, hunit=hunit
    
        ; make sure the legend location is in pts
        legendbottom = legendObj->ConvertUnit(legendbottom,bunit,0)
        legendleft = legendObj->ConvertUnit(legendleft,lunit,0)
        legendwidth = legendObj->ConvertUnit(legendwidth,wunit,0)
        legendheight = legendObj->ConvertUnit(legendheight, hunit,0)
    endif
    
    ; normalize legend location so that we can rescale to the draw area
    normleft = self->pt2norm(legendleft,0)
    normwidth = self->pt2norm(legendwidth,0)
    normbottom = self->pt2norm(legendbottom,1)
    normheight = self->pt2norm(legendheight,1)
    
    ; get dimensions of the draw area, in points
    self.destination->getProperty,dimensions=dim

    ; get panel width and height, in points
    panelsize = self->getpanelsize(xpos,ypos)
    panelwidth = panelsize[2]
    panelheight = panelsize[3]

    ; legend location in drea area coordinates, in points
    self.destination->getProperty, current_zoom=cz

    da_left = xpos[0]*dim[0]*cz+normleft*dim[0]*cz
    da_right = da_left + normwidth*dim[0]*cz
    da_bottom =  cz*normbottom*dim[1]+cz*ypos[0]*dim[1] 
    da_top = da_bottom + cz*normheight*dim[1]
   
    ; click location in draw area coordinates, in points
    xloc_pts = loc[0]*dim[0]*cz
    yloc_pts = loc[1]*dim[1]*cz

    ; check whether the click was in the legend
    if xloc_pts ge da_left && $
       xloc_pts le da_right && $
       yloc_pts ge da_bottom && $
       yloc_pts le da_top then begin
       return,{panelidx:i,component:5,marker:panels[i].markeridx}
    endif
    ;;; end of the legend specific code
    
    ;Check bounds. (Cursor over plot)
    if loc[0] ge xpos[0] && $  ;panel
      loc[0] le xpos[1] && $
      loc[1] ge ypos[0] && $
      loc[1] le ypos[1] then  begin
      return,{panelidx:i,component:0,marker:panels[i].markeridx}
      
    ;This block handles a click on the left side of the panel
    endif else if loc[0] ge xpos[0] - margins[0] && $ ;left side
      loc[0] le xpos[0] && $
      loc[1] ge ypos[0] && $
      loc[1] le ypos[1] then begin
      
      ;If z-axis is placed on a particular side, you cannot get the other axis by a click on that side
      if place eq 2 then begin
        return,{panelidx:i,component:3,marker:-1} ;zaxis
      endif else begin
        return,{panelidx:i,component:2,marker:-1} ;yaxis
      endelse
     
   ;This block handles a click on the right side of the panel
    endif else if loc[0] ge xpos[1] && $ ;right side
      loc[0] le xpos[1] + margins[1] && $
      loc[1] ge ypos[0] && $
      loc[1] le ypos[1] then begin
      
      ;If z-axis is placed on a particular side, you cannot get the other axis by a click on that side 
      if place eq 3 then begin
        return,{panelidx:i,component:3,marker:-1} ;zaxis
      endif else begin
        return,{panelidx:i,component:2,marker:-1} ; yaxis
      endelse
      
    ;This block handles a click on the top side of the panel
    endif else if loc[0] ge xpos[0] && $ ;top side
      loc[0] le xpos[1] && $
      loc[1] ge ypos[1] && $
      loc[1] le ypos[1] + margins[2] then begin
      
      
      ;If z-axis is placed on a particular side, you cannot get the other axis by a click on that side 
      if place eq 0 then begin
        return,{panelidx:i,component:3,marker:-1} ;zaxis
      endif else begin
        return,{panelidx:i,component:1,marker:-1} ;xaxis
      endelse
      
    ;This block handles a click on the bottom side of the panel
    endif else if loc[0] ge xpos[0] && $ ;bottom side
      loc[0] le xpos[1] && $
      loc[1] ge ypos[0] - margins[3] && $
      loc[1] le ypos[0] then begin
      
      ;If z-axis is placed on a particular side, you cannot get the other axis by a click on that side 
      if place eq 1 then begin
        return,{panelidx:i,component:3,marker:-1} ;zaxis
      endif else begin
        return,{panelidx:i,component:1,marker:-1} ;xaxis
      endelse
      
    ;This block handles variable selection.  Basically, if your selection is outside of margins, it is assumed to be variable
    endif else if loc[0] ge xpos[0] && $
      loc[0] le xpos[1] && $
      loc[1] ge ypos[0] - margins[3] - margins[4] && $
      loc[1] le ypos[0] - margins[3] then begin
      
      return,{panelidx:i,component:4,marker:-1} ; vars
      
    endif
    
  endfor
  
  return,0
  
end
