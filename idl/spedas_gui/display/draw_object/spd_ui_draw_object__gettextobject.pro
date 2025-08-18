;+
;
;spd_ui_draw_object method: getTextObject
;
;returns a text object by digesting the settings on a spd_ui_text object
;text: a spd_ui_text object
;loc: the normalized location of the text, relative to the view [xpos,ypos,zpos]
;offsetDirFlag: 0=centered,1=abovelocation,-1=belowlocation
;justify, -1 = left, 1=right, 0 = middle
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2014-07-24 11:24:17 -0700 (Thu, 24 Jul 2014) $
;$LastChangedRevision: 15597 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__gettextobject.pro $
;-
function spd_ui_draw_object::getTextObject,text,loc,offsetDirFlag,orientation,justify=justify,enable_formatting=enable_formatting

  compile_opt idl2,hidden
  
  tFont = text->getGrFont()
  
  text->getProperty,color=color,value=value,show=show,size=size
  
  ;calculate parameters determining how the text is justified
  if orientation eq 0 then begin
    if offsetDirFlag eq 0 then begin
      yAlign = .5
    endif else if offsetDirFlag eq 1 then begin
      yAlign = 0.
    endif else begin
      yAlign = 1.
    endelse
    
    if ~keyword_set(justify) then begin
      xAlign = .5
    endif else if justify eq 1 then begin
      xAlign = 1.
    endif else if justify eq -1 then begin
      xAlign = 0.
    endif
    
    baseline = [1,0,0]
    updir = [0,1,0]
    
  endif else begin
  
    if offsetDirFlag eq 0 then begin
      xAlign=.5
    endif else if offsetDirFlag eq 1 then begin
      xAlign = 0.
    endif else begin
      xAlign = 1.
    endelse
    
    if ~keyword_set(justify) then begin
      yAlign = .5
    endif else if justify eq 1 then begin
      yAlign = 1.
    endif else if justify eq -1 then begin
      yAlign = 0.
    endif
    
    baseline=[0,1,0]
    updir = [-1,0,0]
    
  endelse
  
  if size le 0 then begin
    show = 0
    size = 1D
  endif
  
  tFont->setProperty,size=size*self->getZoom()
  
  grText = obj_new('IDLgrText',value,$
    font=tFont,$
    color=self->convertColor(color),$
    hide=~show,$
    location=loc,$
    alignment=xAlign,$
    vertical_alignment=yalign,$
    baseline=baseline,$
    recompute_dimensions=0,$
    updir=updir,$
    enable_formatting=enable_formatting)
    
    
  return,grText
  
end
