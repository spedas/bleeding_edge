;+
;NAME:
;  spd_ui_draw_save
;
;Purpose:
;   Outputs current window content into various formats
;
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/spd_ui_draw_save__define.pro $
;-----------------------------------------------------------------------------------

;note resolution is often limited to 4096 pixels
function spd_ui_draw_save::write,fileinfo

  compile_opt idl2

  ;get_lun,lun
  ;openw,lun,file
  self.drawObject->getProperty,$
    destination=currentWin,$
    markerOn=markerOn,$
    legendOn=legendOn,$
    rubberOn=rubberOn,$
    vBarOn=vBarOn,$
    hBarOn=hBarOn,$
    pageSize=pageSize
    
  format = fileinfo.type
  file = fileinfo.name
  options = fileinfo.options
    
  ;turn off cursor animations
  self.drawObject->markerOff
  self.drawObject->legendOff
  self.drawObject->rubberBandOff
  self.drawObject->vBarOff
  self.drawObject->hBarOff
  
  ;resolution,vector
  if format eq '.eps' || format eq '.emf' then begin
  
    if format eq '.emf' then begin
      if strlowcase(!version.os_family) ne 'windows' then begin
        ok = dialog_message('EMF files supported on windows only')
        return,0
      endif
      
      ps = 0
    endif else begin
      ps = 1
    endelse
  
    currentWin->setProperty,units=1
  
    if ptr_valid(options) then begin   
      
      vector = (*options).vector
      
      if keyword_set(vector) then begin
        res = 2.54D/([72,72])
        lineres = 1
        tmp_factor = 100D - (*options).xdpi
        if tmp_factor eq 0 then begin
          fancompressionfactor = 0
        endif else begin
          fancompressionfactor = 10^(tmp_factor/99D * 5 - 6)
        endelse
        specres = ((*options).ydpi/100D)
      endif else begin
        res = 2.54D/([(*options).xdpi,(*options).ydpi])
      endelse
      
      currentWin->getProperty,dimensions=dim,resolution=oldres
      
;      dim = olddim*oldres/res
      
      ;keyword should be ignored for non-postscript
      if keyword_set(ps) then cmyk = (*options).cmyk
      
    endif else begin
      
      currentWin->getProperty,resolution=res,dimensions=dim
      
      vector = 1
      fancompressionfactor = 10^(40/99D * 5 - 6)
      specres = 1
      
    endelse
    
    currentWin->setProperty,units=0
    
    clipObj = obj_new('IDLgrClipBoard',$
                quality=2,$
                units=1,$
                dimensions=dim,$
                resolution=res)
   
 
  ;  currentWin->getProperty,image_data=img
                
    self.drawObject->setProperty,destination=clipObj
    
    if keyword_set(vector) then begin
    
      self.drawObject->getProperty,lineres=oldline,specres=oldspec
      self.drawobject->setProperty,lineres=lineres,specres=specres,fancompressionfactor=fancompressionfactor
      self.drawObject->update,self.windowStorage,self.loadedData,/postscript
      self.drawobject->setProperty,lineres=oldline,specres=oldspec
      
    endif
    
    ;instancing hides some objects that we want to output
    ;this routine unhides those objects
    self.drawObject->removeInstance
    self.drawObject->draw,vector=vector,postscript=ps,filename=file,cmyk=keyword_set(cmyk)
    self.drawObject->setProperty,destination=currentWin
    
    if keyword_set(vector) then begin
      self.drawObject->update,self.windowStorage,self.loadedData
    endif else begin
      ;an update will automatically create an instance, so we only to
      ;to reset the instance if we're not updating
      ;this routine will re-hide the correct objects and generate a new instance
      self.drawObject->createInstance
    endelse

  endif else if format eq '.png' || $
                format eq '.bmp' || $ 
                format eq '.gif' || $
                format eq '.jpg' || $
                format eq '.jp2' || $
                format eq '.pic' then begin
  
    if ptr_valid(options) then begin
    
      dim = [(*options).xpx,(*options).ypx]
    
    endif else begin
    
      currentWin->getProperty,dimensions=dim
    
    endelse
  
    buffer = obj_new('IDLgrBuffer',dimensions=dim)
    self.drawObject->setProperty,destination=buffer
    ;instancing hides some objects that we want to output
    ;this routine unhides those objects
    self.drawObject->removeInstance
    self.drawObject->draw
    self.drawObject->setProperty,destination=currentWin
    ;this routine will re-hide the correct objects and generate a new instance
    self.drawObject->createInstance
    
    buffer->getProperty,image_data=img
      
    if format eq '.png' then begin
      
      write_png,file,img
      
    endif else if format eq '.bmp' then begin
  
      write_bmp,file,img,/rgb
    
    endif else if format eq '.gif' then begin
  
      if ptr_valid(options) then begin
        dither = (*options).dither
      endif else begin
        dither = 1
      endelse
    
      out_img = color_quan(img[0,*,*],img[1,*,*],img[2,*,*],rv,gv,bv,dither=dither)
    
      write_gif,file,reform(out_img),rv,gv,bv

    endif else if format eq '.jpg' then begin
  
      if ptr_valid(options) then begin
        quality = (*options).quality
      endif else begin
        quality = 75
      endelse
    
      write_jpeg,file,img,true=1,quality=quality
  
 
    endif else if format eq '.jp2' then begin
  
      if ptr_valid(options) then begin
        levels = (*options).levels
        layers = (*options).layers
      endif else begin
        levels = 0
        layers = 1
      endelse
  
      write_jpeg2000,file,img,n_levels=levels,n_layers=layers
    
    endif else if format eq '.pic' then begin
    
      if ptr_valid(options) then begin
        dither = (*options).dither
      endif else begin
        dither = 1
      endelse
  
      out_img = color_quan(img[0,*,*],img[1,*,*],img[2,*,*],rv,gv,bv,dither=dither)
      
      write_pict,file,reform(out_img),rv,gv,bv
  
     endif
  
    endif else begin
      ok = dialog_message("Unrecognized file extension.  Requires valid file extension for output.")
      return,0
    endelse
  
 ; close,lun
 ; free_lun,lun
  
  ;reactivate cursor animations(if needed)
  if keyword_set(markerOn) then begin
    self.drawObject->markerOn,all=(markerOn eq 2)
  endif
  
  if keyword_set(legendOn) then begin
    self.drawObject->legendOn,all=(legendOn eq 2)
  endif
  
  if keyword_set(rubberOn) then begin
    self.drawObject->rubberBandOn,all=(rubberOn eq 2)
  endif
  
  if keyword_set(vBarOn) then begin
    self.drawObject->vBarOn,all=(vBarOn eq 2)
  endif
  
  if keyword_set(hBarOn) then begin
   ; self.drawObject->hBarOn,all=(hBarOn eq 2)
    self.drawObject->hBarOn
  endif
  
  return,1

end

function spd_ui_draw_save::init,draw,loaded,windows

  compile_opt idl2

  if ~keyword_set(draw) || $
     ~obj_valid(draw) || $
     ~obj_isa(draw,'spd_ui_draw_object') then return,0
     
  if ~keyword_set(loaded) || $
     ~obj_valid(loaded) || $
     ~obj_isa(loaded,'spd_ui_loaded_data') then return,0 

  if ~keyword_set(windows) || $
     ~obj_valid(windows) || $
     ~obj_isa(windows,'spd_ui_windows') then return,0 

  self.drawObject = draw
  self.loadedData = loaded
  self.windowStorage = windows

  return,1

end

pro spd_ui_draw_save__define

  struct = { spd_ui_draw_save, $
               drawObject:obj_new(), $ ;the draw Object
               loadedData:obj_new(), $ ;the loaded data object
               windowStorage:obj_new(), $ ; the window Storage object
               dimRatio:[1D,1D] $ ; ratio output inches to screen inches
               }


end
