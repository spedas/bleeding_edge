;+
;
;spd_ui_draw_object method: addDateString
;
;adds the dateString annotation to the axis
;
;Inputs:
;  view(object reference): The IDLgrView to which the string will be added.
;  axisSettings(object reference):  the spd_ui_axis_settings where the associated settings are stored
;  range(2-element double): The start and stop range for the panel
;  scaling(long):  Indicates the scaling used 0(linear),1(log10),2(logN)
;  xplotsize: The length of the x-axis of the panel in normalized coordinates
;  yplotsize: The length of the y-axis of the panel in normalized coordinates
;  labelMargin:  The distance between the variable labels and the y-axis. This
;                parameter is also used to position the dateString, in lieu of a more specific parameter
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__adddatestring.pro $
;-
pro spd_ui_draw_object::addDateString,view,axisSettings,range,scaling,xplotsize,yplotsize,labelmargin

  compile_opt idl2,hidden
  
  axisSettings->getProperty,$
    showDate=showDate,$
    datestring1=datestring1,$
    datestring2=datestring2,$
    placeannotation=placeannotation,$
  ;  scaling=scaling,$
    annotateTextObject=annotateTextObject,$
    tickStyle=tickStyle,$
    bottomPlacement=bottomPlacement,$
    topPlacement=topPlacement,$
    majorLength=majorLength,$
    minorLength=minorLength,$
    isTimeAxis=isTimeAxis
    
  ; view->getProperty,viewPlane_rect=viewPlane_rect
    
  if ~showDate then begin
    return
  endif
  
  if ~isTimeAxis then begin
    return
  endif
  
  ;format the date strings, according to the splash-based format codes
  string1 = formatdate(range[0],datestring1,scaling)
  string2 = formatdate(range[0],datestring2,scaling)
  
  ;Copy the text objects so we can mutate them
  string1Obj = annotateTextObject->copy()
  string2Obj = annotateTextObject->copy()
  
  string1Obj->getProperty,size=size
  
  ;Turn this measure into a panel normal size
  textSizeNorm = self->pt2norm(size,1)/yplotsize
  
  posoffset = textSizeNorm
  
  ;account for tick position when calculating offset for date string
  if tickStyle eq 1 || tickStyle eq 2 then begin
    if (~placeAnnotation && bottomPlacement) || $
      (placeAnnotation && topPlacement) then begin
      posoffset += (self->pt2norm(majorLength > minorLength,1)/yplotsize)
    endif
  endif
  
  xposoffset = -self->pt2norm(labelmargin,0)/xplotsize
  
  string1Obj->setProperty,value=string1
  string2Obj->setProperty,value=string2
  
  ;determine if string goes on top or bottom
  if placeAnnotation then begin
    ; location = [viewPlane_rect[0]/2.,1. + (viewPlane_rect[3]-1+viewPlane_rect[1])/4.,.1]
    location = [xposoffset,1.+posoffset,.1]
  endif else begin
    ;location = [viewPlane_rect[0]/2.,viewPlane_rect[1]/4.,.1]
    location = [xposoffset,0.-posoffset,.1]
  endelse
  
  ;generate text models and add them
  model1 = self->getTextModel(string1Obj,location,1.,0.,justify=1)
  model2 = self->getTextModel(string2Obj,location,-1.,0.,justify=1)
  
  view->add,model1
  view->add,model2
  
end
