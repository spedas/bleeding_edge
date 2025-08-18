PRO spd_ui_display_options, info

      ; Catch any errors here
      
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=1)
      RETURN
   ENDIF

    ; Get the component that was clicked on 
    
   clickStruct = info.drawObject->GetClick()
   info.drawObject->setClick,clickStruct

    ; check that it's a valid structure, if not just display the page options panel 
   IF Is_Num(clickStruct) && clickStruct EQ 0 THEN BEGIN
      spd_ui_page_options, info
      RETURN
   ENDIF
  
   CASE clickStruct.component OF   
     0: BEGIN 
       ; print,clickStruct.marker
     ;   print,clickStruct.panelIdx
     
        ; if the marker component is not -1 then a marker was clicked
        IF clickStruct.marker NE -1 THEN BEGIN
         
              ; get the active window, it's panels, then the panels markers
          activeWindow = info.windowStorage->GetActive()
          IF ~Obj_Valid(activeWindow) THEN RETURN
          activeWindow->GetProperty, Panels=panels
          IF ~Obj_Valid(panels) THEN RETURN
          if panels->count() eq 0 then return
          panelObjs = panels->Get(/all)
          ;0 all the marker flags
          FOR i=0, N_Elements(panelObjs)-1 DO BEGIN
             panelObjs[i]->GetProperty, Id=id, Markers=markers
             IF ~Obj_Valid(markers) THEN continue
             IF markers->count() GE 1 THEN BEGIN
               markerObjs = markers->Get(/All)
               FOR j=0,N_Elements(markerObjs)-1 DO BEGIN
                 if i eq clickStruct.panelIdx && $
                    j eq clickStruct.marker then begin
                    markerObjs[j]->getProperty, isSelected=is
                    markerObjs[j]->setProperty, isSelected=~is
                 endif else begin
                   markerObjs[j]->SetProperty, IsSelected=0
                 endelse    
               ENDFOR 
             ENDIF
          ENDFOR
          
          return
          
        ENDIF ELSE BEGIN
           panel_select = Ptr_New(clickStruct.panelidx)
           spd_ui_panel_options, info.master, info.windowStorage, info.loadedData, $ 
             info.historyWin, info.drawObject,info.template_object, panel_select=panel_select, info.statusbar
        ENDELSE    
     END

     1: spd_ui_axis_options, info.master, info.windowStorage, info.loadedData, $
                                  info.drawObject, info.historyWin, $
                                  'SPEDAS - X Axis Options', 0, $  ;"0" for x.
                                  info.scrollbar, info.template_object,panel_select=clickStruct.panelidx, info.statusBar     
     2: spd_ui_axis_options, info.master, info.windowStorage, info.loadedData, $
                                  info.drawObject, info.historyWin, $
                                  'SPEDAS - Y Axis Options', 1, $  ;"1" for y.
                                  info.scrollbar,info.template_object,panel_select=clickStruct.panelidx, info.statusBar    
     3: spd_ui_zaxis_options, info.master, info.windowStorage, info.zAxisSettings, info.drawObject, info.loadedData, info.historywin, info.template_object, info.statusBar, clickStruct.panelidx
;     3: spd_ui_zaxis_options, info.master, info.windowStorage, info.zAxisSettings, info.drawObject, info.loadedData, info.historywin
     4: spd_ui_variable_options, info.master, info.loadedData, info.windowStorage, info.drawObject, info.historywin,info.template_object,info.guiTree,panel_select=clickStruct.panelidx
     5: spd_ui_legend_options, info, tlb_statusbar=info.statusBar, panel_select=ptr_new(clickStruct.panelidx)
   ENDCASE
   
RETURN
END
