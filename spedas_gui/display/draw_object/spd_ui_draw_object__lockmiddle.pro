;+
;spd_ui_draw_object method: lockMiddle
;
;
;This routine sets the locked settings for a middle panel in a column of a layout.
;Inputs:
;  panel(object): Reference to a spd_ui_panel that will be modified.
;                 This will generally be a copy to prevent mutation of
;                 central gui copy.
;                 
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-06-11 15:56:35 -0700 (Wed, 11 Jun 2014) $
;$LastChangedRevision: 15353 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__lockmiddle.pro $
;-
pro spd_ui_draw_object::lockMiddle,panel

  compile_opt idl2,hidden

  panel->getProperty,xaxis=xaxis,settings=settings,markers=markers
  
 ; panel->setProperty,showVariables = 0
  
  ;Whether top or bottom, we turn off the annotations/labels/date for x-axis
  if obj_valid(xaxis) then begin

    xaxis->setProperty,$ ;tickStyle=0, $
                     showdate=0,$
                     showlabels=0,$
                     showtitle=0,$
                     annotateAxis=0
  endif

  
   ;If marker title is above or below the axis, then move it to the middle
  if obj_valid(markers) then begin
    marker_list = markers->get(/all)
    
    if ~is_num(marker_list[0]) then begin
      for i = 0,n_elements(marker_list)-1 do begin
      
        marker_list[i]->getProperty,settings=msettings
        
        if obj_valid(msettings) then begin
          msettings->getProperty,vertPlacement=vert,label=label
          
          if vert eq 6 || vert eq 0 then begin
            msettings->setProperty,vertPlacement=3
            
            ;temporary.  Until marker settings are modifiable, don't draw markers that would overlap other locked p
            if obj_valid(label) then begin
              label->setProperty,show=0
            endif
            
          endif
          
          
        endif
        
     
        
      endfor
    endif
  endif
  
end
