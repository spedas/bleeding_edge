;+
;spd_ui_draw_object method: getVariablesSize
;
;Calculates the maximum space that will be occupied, by any panel's x-axes
;Name is because it used to only account for variables
;Inputs:
;  panels(array of objects): List of spd_ui_panels
;
;NOTES:
;  consider returning an array of panel sizes and performing the max after the fact
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getvariablesize.pro $
;-

function spd_ui_draw_object::getVariableSize,panels

  compile_opt idl2,hidden
  
  max_size = 0
  ;amount of pad
  spacing = 2
  
  ;loop over panels
  for i = 0,n_elements(panels)-1 do begin
    
    total = 0
  
    panels[i]->getProperty,variables=variables,showVariables=showvariables,xaxis=xaxis
    
;This needs to be finished.  Code needs to account for the space occupied by ticks, annotations, datestrings, & labels if it is to be able to render layouts without any collision or error.
;    if obj_valid(xAxis) then begin
;    
;      xAxis->getProperty,$
;            bottomPlacement=bottomPlacement,$
;            topPlacement=topPlacement,$
;            tickStyle=tickStyle,$
;            majorLength=majorLength,$
;            minorLength=minorLength,$
;            
;    
;    endif
    
   
    ;there is a 2 pt pad before, after,
    ;and between each variable section on the panel
    
    if obj_valid(variables) && $
      obj_isa(variables,'IDL_Container') && $
      showvariables then begin
      
      varList = variables->get(/all)
      if obj_valid(varList[0]) then begin
        total=spacing
      
        ;loop over variables.
        for j = 0,n_elements(varList)-1 do begin
        
         ;Get text height of the variable, if it is valid
          varList[j]->getProperty,text=text
          if obj_valid(text) then begin
            text->getProperty,size=size,show=show
            if ~show then continue
            total += size+spacing
          endif
          
        endfor
      endif
      
    endif
    
    max_size = max([max_size,total])
    
  endfor
  
  return,max_size
  
end
