;+
;
;spd_ui_draw_object method: makeView
;
;creates the views for a panel,
;incorporates all the layout information 
;that can effect this.
;
;Inputs:
;  dims(2 element long) : The number of rows and columns in the overall layout
;  margins(6 element double):  [leftMargin,rightMargin,topMargin,bottomMargin,horizontalMargin,verticalMargin] in draw-area normalized coordinates
;  pos(4 element long):  [row,col,rowSpan,colSpan] of the panel being drawn.
;  pcoord(4 element double): User defined explicit panel position, in draw-area normalized coords: [xpos,ypos,xsize,ysize], if unused, will be -1 
;  markernum(long): The number of markers in the panel.  Each marker is in a different view, so a number of markerviews equal to markernum will be returned
;  bottomsizes(double array): Array of verical text sizes to be allocated at the bottom of each panel
;  topsizes(double array): Array of verical text sizes to be allocated at the top of each panel
;Outputs:
;  view(object reference):  The static panel IDLgrView
;  annotation(object reference):  The panel IDLgrView for dynamic display elements(ie annotations etc.. that are being updated)
;  markers(array of object references):  Array of IDLgrViews for each marker.  Each marker ends up needing to be put in separate views,
;                                      to guarantee proper layering.
;  xplotpos(2 element double):  The determined x-position of panel in draw-area normalized coordinates [xstart,xstop]
;  yplotpos(2 element double):  The determined y-position of panel in draw-area normalized coordinates [ystart,ystop] 
;  fail(boolean):  Will be 1 if operation fails, 0 otherwise
;  outmargins(5 element double) :  Indicates the size of the various panel regions in draw-normalized coordinates, so that cursor clicks can be properly resolved. [left,right,top,bottom,var]
;  errmsg(anonymous struct): Returns information about an error that has occured. This is not implemented uniformly, but used in particular 
;    cases where it is helpful to return error information up to the calling routine so, for example, popup messages can be issued to user.
;    It is intended that developers make use of it to return other errors (or informational messages) when they find it necessary.
;    Note: if no such error occurs errmsg is simply not set.
;    errmsg being set does not guarantee fail=1 and likewise fail=1 is not an indication that errmsg is set.
;    See also notes in spd_ui_draw_object__update
;           
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-06-11 15:56:35 -0700 (Wed, 11 Jun 2014) $
;$LastChangedRevision: 15353 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__makeview.pro $
;-
                          
pro spd_ui_draw_object::makeView,dims,margins,pos,pcoord,markernum,bottomsizes,topsizes,view=view,annotation=annotation,markers=markers,xplotpos=xplotpos,yplotpos=yplotpos,fail=fail,errmsg=errmsg,outmargins=outmargins

  compile_opt idl2,hidden
  
  
  fail = 1
  
  dims = double(dims)
  margins = double(margins)
  pos = double(pos)
  pcoord = double(pcoord)
  
  ;get total vertical size of text annotations for this panel
  ; -these could probably be summed earlier, but keep them separate
  ;  in case top vs. bottom becomes an important distinction
  
  totalTextSize = total(bottomsizes) + total(topsizes)
  
  bottomsize = bottomsizes[pos[0]+pos[2]-2]
  topsize = topsizes[pos[0]-1]
  
  ;get the space occupied by text below this panel
  if pos[0]+pos[2] - 2 eq 0 then begin
    ;pretty sure this is wrong, but also pretty sure it will never be used -aaf
    partialTextSize = totalTextSize - 0
  endif else begin
    partialTextSize = totalTextSize - total(bottomsizes[0:pos[0]+pos[2]-3]) - total(topsizes[0:pos[0]-1])
  endelse
  
  ;outmargins indicate the range in normalized device coordinates to
  ;be considered part of the region(this is used for identifying context sensitive clicks)
  outmargins = dblarr(5) ; [left,right,top,bottom,var]
  
  ;calculate the amount of space the whole panel will occupy(including margins)
  xused = margins[0] + margins[1] + (dims[1]-1) * margins[4]
  xsize = (1.-xused)/dims[1]
  
  yused = margins[3] + margins[2] + (dims[0]-1) * margins[5] + totalTextSize
  ysize = (1. - yused)/dims[0]
  
  if xsize lt 0 then begin
    self.statusBar->update,'Error: XMargins/Horizontal PanelSpacing too large. No room available for panels'
    self.historyWin->update,'Error: XMargins/Horizontal PanelSpacing too large.  No room for panels'
    errmsg = {TYPE:'ERROR',VALUE:'X margins, spacing, or number of columns too large. No room for panels.'}
    return
    
  endif
  
  if ysize lt 0 then begin
    self.statusBar->update,'Error: YMargins/Vertical PanelSpacing too large.  No room for panels'
    self.historyWin->update,'Error: YMargins/Vertical PanelSpacing too large.  No room for panels'
     errmsg = {TYPE:'ERROR',VALUE:'Y margins, spacing, number of rows, or number of variables too large. No room for panels.'}
    return
    
  endif
  
  ;This calculates the position and length of the view within the window
  ;It also calculates the viewplane rectangle.  This can be thought of as
  ;the coordinate system local to objects placed inside the view.
  ;It is set up so that the plot itself ranges from 0 to 1,  any
  ;margins are outside of that range
  
  ;x size of the plot in normalized coordinates
  ;this accounts for colspan & any margins
  xplot_size = xsize*pos[3] + margins[4]*(pos[3]-1)
  
  ;calculate
  ;1. X size/location of view
  ;2. X size of viewplane_rect
  ;3. X Start & Stop of Plot in normalized window coordinates
  
  xpos = 0.
  xlen = 1.
  
  ;Since different margins apply depending on panel location, we need to have a special case for 
  ;each panel, depending on whether it is on the edge or in the middle of the panel
  if pos[1] eq 1 && pos[1] + pos[3] - 1 eq dims[1] then begin ;leftmost & rightmost panel
  
    xstart = margins[0]
    outmargins[0] = margins[0]/2D
    outmargins[1] = margins[1]/2D
    
  endif else if pos[1] eq 1 then begin  ;leftmost panel
  
    xstart = margins[0]
    
    outmargins[0] = margins[0]/2D
    outmargins[1] = margins[4]/2D
    
  endif else if pos[1] + pos[3] - 1 eq dims[1] then begin ;rightmost panel
  
    xstart = 1. - margins[1] - xplot_size
    
    outmargins[0] = margins[4]/2D
    outmargins[1] = margins[1]/2D
    
  endif else begin  ;neither left nor right
  
    xstart = margins[0] + (xsize+margins[4])*(pos[1]-1.)
    
    outmargins[0] = margins[4]/2D
    outmargins[1] = margins[4]/2D
    
  endelse
  
  ;handle explicit positioning by user
  ;If the user requested a position override defaults
  if pcoord[0] ne -1 then begin
    xstart = pcoord[0]
  endif
  
  if pcoord[2] ne -1 then begin
    xplot_size = pcoord[2]
    if xplot_size eq 0 then begin
    
      self.statusBar->update,'0 width panel cannot be created'
      self.historyWin->update,'0 width panel cannot be created'
      return
    endif
  endif
  
  xstop = xstart + xplot_size
  viewXpos = -(xstart / xplot_size)
  viewXlen = 1. / xplot_size
  
  ;dims = [rownum,colnum]
  ;margins = [left,right,top,bottom,xSpacing,ySpacing] in normalzied
  ;coords
  ;pos = [row,col,rowSpan,colSpan]
  
  ;this layout naturally orders from bottom to top
  ;the line below reverses the ordering of the rows.
  ;so that it orders from top to bottom
  pos[0] = dims[0] - pos[0] + 1
  
  ;Y size of the plot in normalized coordinates
  ;this accounts for rowspan & any interior margins
  ;(interior margins from multiple row span)
  yplot_size = ysize*pos[2] + margins[5]*(pos[2]-1)
  
  ;because rows count in the opposite direction of coordinate system,
  ;the position needs to be shifted down when a panel spans multiple
  ;rows.  This way adding span appears to increase panel size in the
  ;direction of increasing rows.
  pos[0] = pos[0] - (pos[2] - 1)
  
  ;calculate:
  ;1.  Y size/location of view
  ;2. Y dimensions of viewplane_rect
  ;3. Y Start & Stop of the plot in normalized coordinates
  
  ypos = 0.
  ylen = 1.
   
  ;Since different margins apply depending on panel location, we need to have a special case for 
  ;each panel, depending on whether it is on the edge or in the middle of the panel
  if pos[0] eq 1 && pos[0] + pos[2] - 1 eq dims[0] then begin ;case 1: 1 row layout
  
    ystart = margins[2] + bottomsize
    
    outmargins[2] = margins[2]/2D
    outmargins[3] = margins[3]/2D
    
  endif else if pos[0] eq 1 then begin ;case 2: bottom row in layout
  
    ystart = margins[3] + bottomsize
    
    outmargins[2] = margins[5]/2D
    outmargins[3] = margins[3]/2D
    
  endif else if pos[0] + pos[2] - 1 eq dims[0] then begin ;case 3: top row in layout
  
    ystart = 1. - (margins[2] + yplot_size + topsize)
    
    outmargins[2] = margins[2]/2D
    outmargins[3] = margins[5]/2D
    
  endif else begin  ;case 4, somewhere in the middle of layout
  
    ystart = margins[3] + (ysize+margins[5])*(pos[0]-1) + partialTextSize
    
    outmargins[2] = margins[5]/2D
    outmargins[3] = margins[5]/2D
    
  endelse
  
  ;handle explicit positioning by user
  ;If the user requested a position override defaults
  if pcoord[1] ne -1 then begin
    ystart = pcoord[1]
  endif
  
  if pcoord[3] ne -1 then begin
    yplot_size = pcoord[3]
    if yplot_size eq 0 then begin
    
      self.statusBar->update,'0 height panel cannot be created'
      self.historyWin->update,'0 height panel cannot be created'
      return
    endif
  endif
  
  ystop = ystart + yplot_size
  viewYpos = -(ystart / yplot_size)
  viewYlen = 1./ yplot_size
  
  outmargins[4] = bottomsize
  
  ;Now generate the views.  
  ;The logic for IDL views is a little weird, but these settings guarantee that
  ;Things placed in the view can be positioned as if they are in a coordinate system
  ;relative to the panel, rather than relative to the whole layout.  This significantly
  ;simplifes a ton of the positioning code.
  
  ;Even though the views(annotation,view,marker) are different, they have basically
  ;the same settings.  Having different views allows different organization of
  ;the draw tree and sometimes affects layering.
  
  view = OBJ_NEW('IDLgrView')
  
  view->setProperty,units=3,viewplane_rect=[viewXpos,viewYpos,viewXlen,viewYlen], $
    location=[xpos,ypos],dimensions=[xlen,ylen],zclip=[1.,-1.], $
    eye=5.,transparent=1,/double
    
  annotation = OBJ_NEW('IDLgrView')
  
  annotation->setProperty,units=3,viewplane_rect=[viewXpos,viewYpos,viewXlen,viewYlen], $
    location=[xpos,ypos],dimensions=[xlen,ylen],zclip=[1.,-1.], $
    eye=5.,transparent=1,hide=0,/double
    
  ;now loop through and make the marker views
  if markernum gt 0 then begin
    markers = objarr(markernum)
    
    for i = 0,markernum - 1 do begin
    
      marker = obj_new('IDLgrView')
      
      marker->setProperty,units=3,viewplane_rect=[viewXpos,viewYpos,viewXlen,viewYlen], $
        location=[xpos,ypos],dimensions=[xlen,ylen],zclip=[1.,-1.], $
        eye=5.,transparent=1,hide=0,/double
        
      markers[i] = marker
    endfor
  endif
  
  xplotPos = [xstart,xstop]
  yplotPos = [ystart,ystop]
  
  fail = 0
  
end
