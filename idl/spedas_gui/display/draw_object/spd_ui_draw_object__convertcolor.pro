;+
;
;spd_ui_draw_object method: convertColor
;
;
;this routine converts between True color and indexed color
;depending upon which color mode is set by the window
;if keyword: backwards is set, the routine will return a 1x3 array,
;Which may be useful in some applications.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__convertcolor.pro $
;-

function spd_ui_draw_object::convertColor,color,backwards=backwards

  compile_opt idl2,hidden
  
  self.destination->getProperty,palette=pal,color_model=col
  
  if col eq 1 && n_elements(color) eq 1 then return,color
  
  if col eq 0 && n_elements(color) eq 3 then begin
    if (keyword_set(backwards) && size(color,/n_dim) eq 2) || $
      (~keyword_set(backwards) && size(color,/n_dim) eq 1) then begin
      return,color
    endif
    
    if (keyword_set(backwards) && size(color,/n_dim) eq 1) || $
      (~keyword_set(backwards) && size(color,/n_dim) eq 2) then begin
      return,transpose(color)
    endif
  endif
  
  ;If we don't have a valid palette object,
  ;Use the command line color table.
  if ~obj_valid(pal) then begin
    tvlct,r,g,b,/get
    
    pal = obj_new('IDLgrPalette',r,g,b)
    
    self.destination->setProperty,palette=pal
  endif
  
  if n_elements(color) eq 1 then begin
    if keyword_set(backwards) then begin
      return,transpose(pal->getRGB(color))
    endif else begin
      return,pal->getRGB(color)
    endelse
  endif
  
  if n_elements(color) eq 3 then begin
    return,pal->nearestcolor(color[0],color[1],color[2])
  endif
  
  self.statusBar->update,'Error: Invalid color argument passed to spd_ui_draw_object'
  ;t=error_message('Invalid color argument',/traceback)
  return,-1
  
end
