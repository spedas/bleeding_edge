;+
;spd_ui_draw_object method: getMarker
;
;This routine adds a permanent marker to a view
;This is contrasted with a temporary marker, which
;is only drawn as an animation during a cursor event.
;
;Inputs:
;view(IDLgrView): the view to which the marker should be added
;marker(spd_ui_marker): the spd_ui_marker that is being added
;xrange(2-element double): the xrange of that view, needed to position the marker
;zstack(single double): the height at which the marker should be placed.  Marker stacking is
;                         controlled by calling loop, to ensure that they layer correctly.
;Outputs:
;fail(boolean):  This will be set to 1 if a handled error occurs 0 otherwise.
;markerFrames(2-element object array),  2-IDLgrPolyline objects that constitute the border of the marker
;markerPos(2-element double array),  Stores the marker start and end 
;                                                    location normalized proportional to the panel
;markerColor(3-element byte array),  The color of the marker frame, prior to any hue rotation
;markerSelected(boolean):   Whether this marker is currently selected  
;                                                      
;
;NOTES:
;  Permanent marker is contrasted with a temporary marker, which
;  is only drawn as an animation during a cursor event.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__addmarker.pro $
;-
pro spd_ui_draw_object::addMarker,view,marker,xrange,zstack,fail=fail,markerFrames=markerFrames,markerpos=markerpos,markercolor=markercolor,markerSelected=markerSelected

  compile_opt idl2,hidden
  
  fail = 1
  
  ;Markers are shifted up 5% above the input value
  textzStack = zstack+.05
  
  marker->getProperty,settings=settings,range=range,isSelected=isSelected
  
  settings->getProperty,$
    fillColor=fillColor,$
    lineStyle=lineStyle,$
    drawOpaque=drawOpaque,$
    label=label,$
    vertPlacement=vertPlacement
    
  ;only draw markers that are in range
  if range[0] ge xrange[1] then return
  
  range[0] = max([range[0],xrange[0]],/nan)
  
  if range[1] le xrange[0] then return
  
  range[1] = min([range[1],xrange[1]],/nan)
  
  if range[0] le xrange[0] && range[1] ge xrange[1] then return
  
  ;normalized marker position, bounded on [0,1]
  xbegin = max([(range[0] - xrange[0])/(xrange[1]-xrange[0]),0D],/nan)
  xend = min([(range[1] - xrange[0])/(xrange[1]-xrange[0]),1D],/nan)
  
  lineStyle->getProperty,$
    id=lineid,$
    show=lineshow,$
    color=linecolor,$
    thickness=linethick
    
  ;A selected marker starts one rotation from initial color
  if isSelected then begin
    frameColor = self->hueRotation(self->hueRotation(linecolor))
  endif else begin
    frameColor = linecolor
  endelse
  
  ;border
  lineleft = obj_new('IDLgrPolyline',$
    [xbegin,xbegin],$
    [0.,1.],$
    replicate(zstack,2)+.00001,$
    linestyle=lineid,$
    hide=~lineshow,$
    color=self->convertColor(framecolor),$
    thick=linethick,$
    /double)
    
  lineright = obj_new('IDLgrPolyline',$
    [xend,xend],$
    [0.,1.],$
    replicate(zstack,2)+.00001,$
    linestyle=lineid,$
    hide=~lineshow,$
    color=self->convertColor(framecolor),$
    thick=linethick,$
    /double)
    
    
  ;this creates the semi-transparent shading
  poly = obj_new('IDLgrPolygon',$
    [xbegin,xend,xend,xbegin],$
    [0.,0.,1.,1.],$
    replicate(zstack,4),$
    color=self->convertColor(fillColor),$
    alpha_channel=drawOpaque, $
    /double)
    
  ;now create the label
    
  xpos = (xbegin+xend)/2D
  yposarray = 1D - dindgen(7)*1D/6D
  
  ypos = yposarray[vertPlacement]
  
  if vertPlacement eq 0 then begin
    offset = 1
  endif else if vertplacement eq 6 then begin
    offset = -1
  endif else begin
    offset = 0
  endelse
  
  ;marker title
  labelObj = self->getTextObject(label,[xpos,ypos,textZstack],offset,0)
  
  ;model for all this
  model = obj_new('IDLgrModel')
  
  ;adding the objects to the graphics tree
  model->add,lineleft
  model->add,lineright
  
  ;central portion is not added if
  ;postscript is on.  This is because transparency
  ;does not work in postscript, so rather than
  ;a see through pane, you get a solid grey block.
  if ~self.postscript then begin
    model->add,poly
  endif
 
  model->add,labelObj
  
  view->add,model
  
  ;storing the output
  markerpos = [xbegin,xend]
  markerframes = [lineleft,lineright]
  markercolor = linecolor
  markerSelected = isSelected
  
  fail = 0
  
end
