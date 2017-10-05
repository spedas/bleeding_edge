;+
;spd_ui_draw_object method: lockTop
;
;
;This routine sets the locked settings for a top panel in a column of a layout.
;Inputs:
;  panel(object): Reference to a spd_ui_panel that will be modified.
;                 This will generally be a copy to prevent mutation of
;                 central gui copy.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__locktop.pro $
;-

pro spd_ui_draw_object::lockTop,panel

  compile_opt idl2,hidden

  panel->getProperty,xaxis=xaxis,markers=markers
  
 ; panel->setProperty,showvariables = 0
  
  ;General purpose axis settings
  if obj_valid(xaxis) then begin
  
    xaxis->getProperty,placeAnnotation=pa, placeLabel=pl, placetitle=pt
    
    ;We turn off labels, annotations, & date if annotations
    ;are set to be placed on the bottom
    ; lphilpott 6-apr-2012, separating out labels
    if ~pa then begin
      ;xaxis->setProperty,showlabels = 0
      xaxis->setProperty,annotateAxis = 0
      xaxis->setProperty,showdate=0 
    endif
    if ~pl then begin
      xaxis->setProperty, showlabels = 0
    endif
    if ~pt then begin
      xaxis->setProperty, showtitle = 0
    endif
    
 
  endif
  
  ;If marker title is below the axis, then move it to the middle
  if obj_valid(markers) then begin
    marker_list = markers->get(/all)
    
    if ~is_num(marker_list[0]) then begin
      for i = 0,n_elements(marker_list)-1 do begin
      
        marker_list[i]->getProperty,settings=msettings
        
        if obj_valid(msettings) then begin
          msettings->getProperty,vertPlacement=vert
          
          if vert eq 6 then begin
            msettings->setProperty,vertPlacement=3
          endif
        endif
        
      endfor
    endif
  endif
  
end
