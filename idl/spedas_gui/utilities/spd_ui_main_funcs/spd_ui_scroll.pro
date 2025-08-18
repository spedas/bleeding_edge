 pro spd_ui_scroll_update_panel,panelObj,drawObject,direction,index
  
   compile_opt idl2,hidden
 
   panelObj->GetProperty, XAxis=xaxis,yAxis=yaxis
   panelStruc = drawObject->GetPanelInfo(index)
   ; direction is zoomin=0, zoomout=1
   IF direction EQ 0 THEN newXRange=panelStruc.XRange + panelStruc.xMajorSize $
     ELSE newXRange=panelStruc.XRange - panelStruc.xMajorSize
   IF panelStruc.xScale EQ 1 THEN newXRange = 10.^(newXRange)
   IF panelStruc.xScale EQ 2 THEN newXRange = exp(newXRange)
                        
  ;   I'm commenting out this code, so that the yrange can autoscale
  ;   during scrolling if the user wants it to.  We should keep an eye
  ;   on this during testing to see if there is a good reason for
  ;   explicit range setting.
  ;   yrange = panelStruc.yrange
  ;   if panelstruc.yscale eq 1 then yrange = 10.^(yrange)
  ;   if panelstruc.yscale eq 2 then yrange = exp(yrange)
     
   xaxis->setProperty,rangeoption=2
   xaxis->UpdateRange, newXRange               
  ;   yaxis->setProperty,rangeoption=2
  ;   yaxis->updaterange,yrange
           
end

PRO spd_ui_scroll, windowStorage, drawObject, direction

  compile_opt idl2,hidden

   IF ~Obj_Valid(windowStorage) THEN RETURN
   
   activeWindow=windowStorage->GetActive()
   IF N_Elements(activeWindow) GT 0 && Obj_Valid(activeWindow[0]) THEN BEGIN
      activeWindow[0]->GetProperty, Panels=panels,locked=locked
      IF Obj_Valid(panels) THEN BEGIN
         panelObjs = panels->Get(/all)
         IF NOT Is_Num(panelObjs) THEN BEGIN
            ;If we're locked to a panel, then only modify locked panel
            if locked ge 0 && locked lt n_elements(panelObjs) then begin
            
              spd_ui_scroll_update_panel,panelObjs[locked],drawObject,direction,locked
            
            endif else begin
              ; for each panel get it info from the draw object and
              ; update the range     
              FOR i=0, N_Elements(panelObjs)-1 DO BEGIN
                spd_ui_scroll_update_panel,panelObjs[i],drawObject,direction,i             
              ENDFOR
            endelse
         ENDIF
      ENDIF
   ENDIF
END
