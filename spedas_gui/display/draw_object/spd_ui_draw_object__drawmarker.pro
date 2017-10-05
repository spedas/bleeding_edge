;+
;spd_ui_draw_object method: drawMarker
;
;draws marker and updates the range in the marker object. Applies to marker is progress.
;
;markerRange (2-element double array):  The start and stop position of the marker in panel-normalized coordinates, 
;                                       (note that start may be larger than stop, if marker was drawn right->left)
;
;panel (struct): Struct used by draw object to store panel information
;
;marker(object):  Reference to the marker being drawn
;
;remove(boolean keyword): Set this keyword to remove the marker
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__drawmarker.pro $
;-
pro spd_ui_draw_object::drawMarker,markerRange,panel,marker,remove=remove

  compile_opt idl2,hidden
  
  zstack = .21
  
  xbegin = min(markerRange,/nan)
  xend = max(markerRange,/nan)
  
  ; print,xbegin,xend
  
  ;get rid of old partial markers
  old = panel.marker->get(/all)
  if obj_valid(old[0]) then obj_destroy,old
  panel.marker->remove,/all
  
  if keyword_set(remove) then return
  
  ;get all the settings for the marker being drawn
  marker->getProperty,settings=settings
  
  settings->getProperty,$
    fillColor=fillColor,$
    lineStyle=lineStyle,$
    drawOpaque=drawOpaque
    
  lineStyle->getProperty,$
    id=lineid,$
    show=lineshow,$
    color=linecolor,$
    thickness=linethick
    
  ;generate new border for the marker
  lineleft = obj_new('IDLgrPolyline',$
    [xbegin,xbegin],$
    [0.,1.],$
    replicate(zstack,2)+.00001,$
    linestyle=lineid,$
    hide=~lineshow,$
    color=self->convertColor(linecolor),$
    thick=linethick,$
    /double)
    
  lineright = obj_new('IDLgrPolyline',$
    [xend,xend],$
    [0.,1.],$
    replicate(zstack,2)+.00001,$
    linestyle=lineid,$
    hide=~lineshow,$
    color=self->convertColor(linecolor),$
    thick=linethick,$
    /double)
    
  ;This is the semi-transparent interior of the marker
  poly = obj_new('IDLgrPolygon',$
    [xbegin,xend,xend,xbegin],$
    [0.,0.,1.,1.],$
    replicate(zstack,4),$
    color=self->convertColor(fillColor),$
    alpha_channel=drawOpaque,$
    /double)
    
  panel.marker->add,lineleft
  panel.marker->add,lineright
  panel.marker->add,poly
  
  ;Need to use the locked range if the layout is locked
  if panel.locked then begin
    range = ([xbegin,xend]*(panel.lockedrange[1]-panel.lockedrange[0]))+panel.lockedrange[0]
  endif else begin
    range = ([xbegin,xend]*(panel.xrange[1]-panel.xrange[0]))+panel.xrange[0]
  endelse
  
  ;   print,time_string(range)
  
  ;updating the range
  marker->setProperty,range=range
  
end
