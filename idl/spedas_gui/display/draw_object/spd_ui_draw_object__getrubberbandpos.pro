;+
;spd_ui_draw_object method: GetRubberBandPos
;
;Returns an array of structs that indicate the panels overlapped by the rubber band
;Input:
;  xonly:
;    If set, constrain along the x-axis only.
;
;Output:
;   structs have the form {idx:0,xrange:[0,1],yrange[0,1],vars:ptr_new()}
;   idx is the panel index in the current display, this is an index into the list of panels displayed, not the ID field from the spd_ui_panel object
;   xrange is the xrange of the panel in non-logarithmic(normal) space
;   yrange is the yrange of the panel in non-logarithmic(normal) space
;   vars is either a null pointer or an array of structs of the form:
;       {range:[0,1]} which stores the range of each variable on the panel
;   returns 0 on fail
;
;Notes: No inputs, uses the information in self.panelInfo, self.rubberStart, self.cursorLoc(considered rubber band stop position
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getrubberbandpos.pro $
;-
function spd_ui_draw_object::GetrubberBandPos,xonly=xonly

  compile_opt idl2
  
  ;prototype output structs
  str = {idx:0,xrange:[0D,1D],yrange:[0D,1D],vars:ptr_new()}
  varstr = {range:[0D,1D]}
  
  if ~ptr_valid(self.panelInfo) then return,0
  
  str_arr = replicate(str,n_elements(*self.panelInfo))
  
  arr_num = 0
  
  ;calculate the borders of the rubberband box
  ;because the box can be oriented in various ways
  ;the start & end pos may not be the expected corner
  left = self.cursorloc[0] < self.rubberstart[0]
  right = self.cursorloc[0] > self.rubberstart[0]
  bottom = self.cursorloc[1] < self.rubberstart[1]
  top = self.cursorloc[1] > self.rubberstart[1]
  
  ; store info about whether any panel is intersected by rubberband
  ; disregarding 'rubberband over x only'
  intersectspanel = 0
  ;loop over panels
  for i = 0,n_elements(*self.panelInfo)-1 do begin
  
    xplotpos = ((*self.panelInfo)[i]).xplotpos
    yplotpos = ((*self.panelInfo)[i]).yplotpos
    
    if ((*self.panelInfo)[i]).locked then begin
  ;  if 0 then begin
      xrange = ((*self.panelInfo)[i]).lockedRange
    endif else begin
      xrange = ((*self.panelInfo)[i]).xrange
    endelse
    
    yrange = ((*self.panelInfo)[i]).yrange
    
    ;determine if rubber band intersects with panel
    ; NB if xonly is set then only x positions are checked. This means you can create a rubberband in empty space below a plot provided
    ; the x settings are okay. To avoid this we also check whether the rubberband actually intersects panel.
    if (right  ge  xplotpos[0] && $
      left   le  xplotpos[1] && $
      (top    ge  yplotpos[0] || keyword_set(xonly)) && $
      (bottom le  yplotpos[1] || keyword_set(xonly))) then begin
      
      if keyword_set(xonly) then begin
        if (right  ge  xplotpos[0] && $
        left   le  xplotpos[1] && $
        top    ge  yplotpos[0] && $
        bottom le  yplotpos[1]) then intersectspanel = 1 
      endif else intersectspanel = 1
      
      ;determine the dimensions of the overlapping box
      bx_right    = right < xplotpos[1]
      bx_left     = left > xplotpos[0]
      bx_top      = top < yplotpos[1]
      bx_bottom   = bottom > yplotpos[0]
      
      ;now calculate ranges
      
      bx_left_norm = (bx_left - xplotpos[0])/(xplotpos[1]-xplotpos[0])
      bx_right_norm = (bx_right - xplotpos[0])/(xplotpos[1]-xplotpos[0])
      bx_bottom_norm = (bx_bottom - yplotpos[0])/(yplotpos[1]-yplotpos[0])
      bx_top_norm = (bx_top - yplotpos[0])/(yplotpos[1]-yplotpos[0])
      
      
      rng_left   = bx_left_norm*(xrange[1]-xrange[0])+xrange[0]
      rng_right  = bx_right_norm*(xrange[1]-xrange[0])+xrange[0]
      rng_bottom = bx_bottom_norm*(yrange[1]-yrange[0])+yrange[0]
      rng_top    = bx_top_norm*(yrange[1]-yrange[0])+yrange[0]
      
      outxrange = [rng_left,rng_right]
      outyrange = [rng_bottom,rng_top]
      
      ;now translate from logarithmic to normal space(if necessary)
      if ((*self.panelInfo)[i]).xscale eq 1 then $
        outxrange = 10D ^ outxrange $
      else if  ((*self.panelInfo)[i]).xscale eq 2 then $
      outxrange = exp(outxrange)

      if ((*self.panelInfo)[i]).yscale eq 1 then $
        outyrange = 10D ^ outyrange $
      else if  ((*self.panelInfo)[i]).yscale eq 2 then $
        outyrange = exp(outyrange)
   
    
      ;store the output info
      str_arr[arr_num].idx = i
      str_arr[arr_num].xrange = outxrange
      
      str_arr[arr_num].yrange = outyrange
     
      ;check variables for rubber band information
      if ptr_valid(((*self.panelInfo)[i]).varInfo) then begin
      
        varInfoArray = *((*self.panelInfo)[i]).varInfo
        
        varstr_arr = replicate(varstr,n_elements(varInfoArray))
        
        for j = 0,n_elements(varInfoArray) - 1 do begin
        
          ;same computation as above
          varrange = varInfoArray[j].range
          
          ;determine values of edges, by scaling proportionately
          varlow = bx_left_norm*(varrange[1]-varrange[0])+varrange[0]
          varhigh = bx_right_norm*(varrange[1]-varrange[0])+varrange[0]
          
          outvarrange = [varlow,varhigh]
          
          ;delog output range
          if varInfoArray[j].scaling eq 1 then begin
            outvarRange = 10. ^ outvarrange
          endif else if varInfoArray[j].scaling eq 2 then begin
            outvarRange = exp(outvarrange)
          endif
          
          varstr_arr[j].range=outvarrange
          
        endfor
        
        str_arr[arr_num].vars = ptr_new(varstr_arr)
        
      endif
    
      arr_num++
    endif
  
  endfor

if (arr_num eq 0 || intersectspanel eq 0) then return,0 else return,str_arr[0:arr_num-1]

end
