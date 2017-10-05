;+
;NAME:
; spd_ui_image_export_options
;
;PURPOSE:
;  This window allows the selection of file export options 
;  for various formats.
;    
;CALLING SEQUENCE:
; spd_ui_image_export,gui_id,draw_save_object
; 
;INPUT:
; gui_id:  id of top level base widget from calling program
; draw_save_object: the object that does the actual output
;
;OUTPUT:
; 
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_image_export_options.pro $
;
;--------------------------------------------------------------------------------

pro spd_ui_image_export_options_event,event

  compile_opt hidden,idl2

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Export Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
    state.historyWin->update,'Image Export Options Killed',/dontshow
    ptr_free,state.out
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy    
    Widget_Control, event.top, /Destroy
    RETURN      
  ENDIF

  Widget_Control, event.id, Get_UValue=uval

  state.historywin->update,'SPD_UI_IMAGE_EXPORT_OPTIONS: User value: '+uval  ,/dontshow

  CASE uval OF
    'CANC': BEGIN
      state.historyWin->update,'Image Export Options Canceled',/dontshow
      ptr_free,state.out
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'OK': BEGIN
      state.historyWin->update,'Image Export Options Closed',/dontshow
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END  
    'VECTOR': BEGIN
      (*state.out).vector=1
      (*state.out).xdpi = 60
      (*state.out).ydpi = 100
      widget_control,event.top,update=0
      slide1 = widget_info(state.row1,/child)
      widget_control,slide1,/destroy
      ;slide1 = widget_slider(state.row1,title='Line Plot Resolution(%)',minimum=1,maximum=400,value=100,UVALUE='DPIX',units=1,xsize=2)
      slide1 = widget_slider(state.row1,title='Line Plot Resolution(%)',minimum=1,maximum=100,value=60,UVALUE='DPIX',units=1,xsize=2,sensitive=1)
      slide2 = widget_info(state.row2,/child)
      widget_control,slide2,/destroy
      slide2 = widget_slider(state.row2,title='Spectrogram Plot Resolution(%)',minimum=1,maximum=400,value=100,UVALUE='DPIY',units=1,xsize=2)
      widget_control,event.top,update=1
    END 
    'RASTER': BEGIN
      (*state.out).vector=0
      state.win->getProperty,resolution=res
      xdpi = round(2.54/res[0])
      ydpi = round(2.54/res[1])
      (*state.out).xdpi = xdpi
      (*state.out).ydpi = ydpi
      widget_control,event.top,update=0
      slide1 = widget_info(state.row1,/child)
      widget_control,slide1,/destroy
      slide1 = widget_slider(state.row1,title='XAxis Resolution(DPI)',minimum=1,maximum=360,value=xdpi,UVALUE='DPIX',units=1,xsize=2)
      slide2 = widget_info(state.row2,/child)
      widget_control,slide2,/destroy
      slide2 = widget_slider(state.row2,title='YAxis Resolution(DPI)',minimum=1,maximum=360,value=ydpi,UVALUE='DPIY',units=1,xsize=2)
      widget_control,event.top,update=1
    END
    'RGB': (*state.out).cmyk = ~event.select
    'CMYK': (*state.out).cmyk = event.select
    'DPIX':BEGIN
      widget_control,event.id,get_value=dpi
      (*state.out).xdpi=dpi
    END
    'DPIY':BEGIN
      widget_control,event.id,get_value=dpi
      (*state.out).ydpi=dpi
    END
    'XPX':BEGIN
      widget_control,event.id,get_value=xpx
      (*state.out).xpx=xpx
    END
    'YPX':BEGIN
      widget_control,event.id,get_value=ypx
      (*state.out).ypx=ypx
    END
    'DITHER':BEGIN
      (*state.out).dither=~((*state.out).dither)
    END
    'QUALITY':BEGIN
      widget_control,event.id,get_value=quality
      (*state.out).quality=quality
    END
    'LEVELS':BEGIN
      widget_control,event.id,get_value=levels
      (*state.out).levels=levels
    END
    'LAYERS':BEGIN
      widget_control,event.id,get_value=layers
      (*state.out).layers=layers
    END
    'ASCII':BEGIN
      (*state.out).ascii=~((*state.out).ascii)
    END
    ELSE: dprint, 'Not yet implemented'
  ENDCASE
    
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN

end


function spd_ui_image_export_options,gui_id,format,drawObject,options, historywin

  compile_opt idl2
  
  tlb = Widget_Base(/Col, Title='Options', Group_Leader=gui_id, $
    /Modal, /Floating,/base_align_center,/tlb_kill_request_events)
    
  drawObject->getProperty,destination=win
  win->getProperty,dimensions=dim,resolution=res
  
  row1 = widget_base(tlb,/row)
  row2 = widget_base(tlb,/row)
  
  if format eq '.eps' then begin
     
    row3 = widget_base(tlb,/row,/exclusive)
    row4 = widget_base(tlb,/row,/exclusive)
    rowlast = widget_base(tlb,/row)
  
    if ptr_valid(options) then begin
      xdpi = (*options).xdpi
      ydpi = (*options).ydpi
      vec = (*options).vector
      cmyk = (*options).cmyk
    endif else begin
     ; xdpi = round(2.54/res[0])
     ; ydpi = round(2.54/res[1])
      xdpi = 60
      ydpi = 100
      vec = 1
      cmyk = 0
    endelse
  
    if vec then begin
      ;slide1 = widget_slider(row1,title='Line Plot Resolution(%)',minimum=1,maximum=400,value=xdpi,UVALUE='DPIX',units=1,xsize=2)
      slide1 = widget_slider(row1,title='Line Plot Resolution(%)',minimum=1,maximum=100,value=xdpi,UVALUE='DPIX',units=1,xsize=2,sensitive=1)
      slide2 = widget_slider(row2,title='Spectrogram Plot Resolution(%)',minimum=1,maximum=400,value=ydpi,UVALUE='DPIY',units=1,xsize=2)
    endif else begin
      slide1 = widget_slider(row1,title='XAxis Resolution(DPI)',minimum=1,maximum=360,value=xdpi,UVALUE='DPIX',units=1,xsize=2)
      slide2 = widget_slider(row2,title='YAxis Resolution(DPI)',minimum=1,maximum=360,value=ydpi,UVALUE='DPIY',units=1,xsize=2)
    endelse
      
     
      raster_button = widget_button(row3,value='Raster',uvalue='RASTER')
      vector_button = widget_button(row3,value='Vector',uvalue='VECTOR')
    
      if vec then begin
        widget_control,vector_button,/set_button
      endif else begin
        widget_control,raster_button,/set_button 
      endelse
    
      widget_control,vector_button,sensitive=1
      widget_control,raster_button,sensitive=1
 
      rgb_button = widget_button(row4, value='RGB', uvalue='RGB', $
                    tooltip = 'Best for on screen colors (default)')
      cmyk_button = widget_button(row4, value='CMYK', uvalue='CMYK', $
                     tooltip = 'Generally better suited for color printing')

      if cmyk then begin
        widget_control, cmyk_button, /set_button
      endif else begin
        widget_control, rgb_button, /set_button
      endelse
  
    ok_button = widget_button(rowlast,value='OK',uvalue='OK')
    canc_button = widget_button(rowlast,value='Cancel',uvalue='CANC')  
  
    out_struct = { $
                  vector:vec,$
                  xdpi:xdpi,$
                  ydpi:ydpi, $
                  cmyk:0 $
                  }
  endif else if format eq '.emf' then begin
     ; Note: EMF may not be widely used. If any bugs/problems are found consider removing EMF support
    row3 = widget_base(tlb,/row,/exclusive)
    row4 = widget_base(tlb,/row,/exclusive)
    rowlast = widget_base(tlb,/row)
  
    if ptr_valid(options) then begin
      xdpi = (*options).xdpi
      ydpi = (*options).ydpi
      vec = (*options).vector
    endif else begin
     ; xdpi = round(2.54/res[0])
     ; ydpi = round(2.54/res[1])
      xdpi = 60
      ydpi = 100
      vec = 1
    endelse
  
    if vec then begin
      ;slide1 = widget_slider(row1,title='Line Plot Resolution(%)',minimum=1,maximum=400,value=xdpi,UVALUE='DPIX',units=1,xsize=2)
      slide1 = widget_slider(row1,title='Line Plot Resolution(%)',minimum=1,maximum=100,value=xdpi,UVALUE='DPIX',units=1,xsize=2,sensitive=1)
      slide2 = widget_slider(row2,title='Spectrogram Plot Resolution(%)',minimum=1,maximum=400,value=ydpi,UVALUE='DPIY',units=1,xsize=2)
    endif else begin
      slide1 = widget_slider(row1,title='XAxis Resolution(DPI)',minimum=1,maximum=360,value=xdpi,UVALUE='DPIX',units=1,xsize=2)
      slide2 = widget_slider(row2,title='YAxis Resolution(DPI)',minimum=1,maximum=360,value=ydpi,UVALUE='DPIY',units=1,xsize=2)
    endelse
      
     
      raster_button = widget_button(row3,value='Raster',uvalue='RASTER')
      vector_button = widget_button(row3,value='Vector',uvalue='VECTOR')
    
      if vec then begin
        widget_control,vector_button,/set_button
      endif else begin
        widget_control,raster_button,/set_button 
      endelse
    
      widget_control,vector_button,sensitive=1
      widget_control,raster_button,sensitive=1

  
    ok_button = widget_button(rowlast,value='OK',uvalue='OK')
    canc_button = widget_button(rowlast,value='Cancel',uvalue='CANC')  
  
    out_struct = { $
                  vector:vec,$
                  xdpi:xdpi,$
                  ydpi:ydpi $
                  }
 
  endif else begin
  
    if ptr_valid(options) then begin
      xpx = (*options).xpx
      ypx = (*options).ypx
    endif else begin
      xpx = dim[0]
      ypx = dim[1]
    endelse
  
    slide1 = widget_slider(row1,title='XAxis Pixel Number',minimum=2,maximum=4096,value=xpx,UVALUE='XPX',units=1,xsize=2)
    slide2 = widget_slider(row2,title='YAxis Pixel Number',minimum=2,maximum=4096,value=ypx,UVALUE='YPX',units=1,xsize=2)
    
    out_struct = { $
                  xpx:xpx,$
                  ypx:ypx $
                  }
  
    if format eq '.gif' then begin
    
      if ptr_valid(options) then begin
        dith = (*options).dither
      endif else begin
        dith = 1
      endelse
    
      row3 = widget_base(tlb,/row,/nonexclusive)
      dither = widget_button(row3,value='Dither',UVALUE='DITHER')
      
      if dith then begin
        widget_control,dither,/set_button 
      endif
      
      str_element,out_struct,'dither',dith,/add
    endif else if format eq '.pic' then begin
    
      if ptr_valid(options) then begin
        dith = (*options).dither
      endif else begin
        dith = 1
      endelse
    
      row3 = widget_base(tlb,/row,/nonexclusive)
      dither = widget_button(row3,value='Dither',UVALUE='DITHER')
      
      if dith then begin
        widget_control,dither,/set_button 
      endif
      
      str_element,out_struct,'dither',dith,/add
    endif else if format eq '.jpg' then begin
    
      if ptr_valid(options) then begin
        qual = (*options).quality
      endif else begin
        qual = 75
      endelse
    
      row3 = widget_base(tlb,/row)
      quality = widget_slider(row3,title='Jpeg Quality(%)',minimum=0,maximum=100,value=qual,uvalue='QUALITY',units=1,xsize=2)
    
      str_element,out_struct,'quality',qual,/add
    endif else if format eq '.jp2' then begin
      
      if ptr_valid(options) then begin
        lvls = (*options).levels
        lays = (*options).layers
      endif else begin
        lvls = 0
        lays = 1   
      endelse
      
      row3 = widget_base(tlb,/row)
      levels = widget_slider(row3,title='Quality Levels(#)',minimum=0,maximum=15,value=lvls,uvalue='LEVELS',units=1,xsize=2)
      row4 = widget_base(tlb,/row)   
      layers = widget_slider(row4,title='Quality Layers(#)',minimum=1,maximum=224,value=lays,uvalue='LAYERS',units=1,xsize=2)
    
      str_element,out_struct,'levels',lvls,/add
      str_element,out_struct,'layers',lays,/add
      
    endif
  
    rowlast = widget_base(tlb,/row)
  
    ok_button = widget_button(rowlast,value='OK',uvalue='OK')
    canc_button = widget_button(rowlast,value='Cancel',uvalue='CANC')  
 
  
  endelse

  out = ptr_new(out_struct)
  
  historywin->update,'Image options panel opened'
  
  state = {tlb:tlb,  $
           gui_id:gui_id, $
           format:'', $
           out:out, $
           row1:row1,$
           row2:row2,$
           win:win,$
           historywin:historywin $
           }
            
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  
  centerTLB,tlb
  
  Widget_Control, tlb, /Realize
  
  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  XManager, 'spd_ui_image_export_options', tlb, /No_Block
  
  historywin->update,'Image options panel closed'

  return,out
  
end
