pro spd_ui_zoom_update_panel,panelObj,drawObject,direction,index

  compile_opt idl2,hidden
  
     panelObj->GetProperty, XAxis=xaxis
     panelStruc = drawObject->GetPanelInfo(index)
     range=panelStruc.xRange[1]-panelStruc.xRange[0]
     inc=range*0.15 ;how big is our zoom step(fraction of current range)
     if inc eq 0 then inc++ ;just in case
     
     ; direction is zoomin=0, zoomout=1
     IF direction EQ 0 THEN BEGIN
    
       newmin = panelStruc.XRange[0] - inc
       newmax = panelStruc.XRange[1] + inc
 ;Changing the way that zoom is calculated to make it work sanely, PRC(old code below)      
        ; Expand minumum
;        inc = panelstruc.xmajorsize
;        if inc eq 0 then inc++
;        while (panelStruc.XRange[0] - inc) - panelStruc.XRange[0] eq 0 do inc = 2*inc
;        newmin = panelStruc.XRange[0] - inc
;        ; Expand maximum
;        inc = panelstruc.xmajorsize
;        if inc eq 0 then inc++
;        while (panelStruc.XRange[1] + inc) - panelStruc.XRange[1] eq 0 do inc = 2*inc
;        newmax = panelStruc.XRange[1] + inc
     ENDIF ELSE BEGIN
    
       newmin = panelStruc.XRange[0] + inc
       newmax = panelStruc.XRange[1] - inc
       
;Changing the way that zoom is calculated to make it work sanely, PRC(old code below)     
;        newMin=panelStruc.XRange[0] + panelStruc.xMajorSize
;        newMax=panelStruc.XRange[1] - panelStruc.xMajorSize
;        if newmin gt newmax then begin
;          ok = error_message('Major tick size too large, cannot further zoom in on panel ' $
;                              +strtrim(index+1,2)+ '.',/center,traceback=0,title="Warning: Zoom")
;          return
;        endif
     ENDELSE
     IF panelStruc.xScale EQ 1 THEN BEGIN
        newMin = 10^newMin
        newMax = 10^newMax
     ENDIF 
     IF panelStruc.xScale EQ 2 THEN BEGIN
        newMin = exp(newMin)
        newMax = exp(newMax)
     ENDIF 
     if newmin ge newmax then begin
       ok = error_message('Panel ' + strtrim(index+1,2) + $
                          ' has zero range and cannot zoom any further.', /center,traceback=0,title="Warning: Zoom")
       return
     endif
                          
     if ~finite(newMin) || ~finite(newMax) then begin
       ok = error_message('Panel ' + strtrim(index+1,2) + $
                          ' has undefined range and cannot zoom any further.', /center,traceback=0,title="Warning: Zoom")
       return
     endif
     ;xx = xaxis->getall()
     ;print, 'Old Range: ' + strtrim(xx.maxfixedrange-xx.minfixedrange,2)
     ;print, 'New Range: ' + strtrim(newmax-newmin,2)
     ;print, '----------------------------'
     
     xaxis->SetProperty, RangeOption=2               
     xaxis->UpdateRange, [newMin, newMax]               
  
end

PRO spd_ui_zoom, windowStorage, drawObject, direction
 
   compile_opt idl2,hidden
 
   IF ~Obj_Valid(windowStorage) THEN RETURN
   
   activeWindow=windowStorage->GetActive()
   newPanels=Obj_New('IDL_CONTAINER')
   IF N_Elements(activeWindow) GT 0 && Obj_Valid(activeWindow[0]) THEN BEGIN
      activeWindow[0]->GetProperty, Panels=panels,locked=locked
    ;  print,locked
      IF Obj_Valid(panels) THEN BEGIN
         panelObjs = panels->Get(/all)
         IF NOT Is_Num(panelObjs) THEN BEGIN
          
            ;If we're locked to a panel, then only modify locked panel
            if locked ge 0 && locked lt n_elements(panelObjs) then begin
              spd_ui_zoom_update_panel,panelObjs[locked],drawObject,direction,locked
            endif else begin
              ; for each panel get it info from the draw object and
              ; update the range
              FOR i=0, N_Elements(panelObjs)-1 DO BEGIN
                spd_ui_zoom_update_panel,panelObjs[i],drawObject,direction,i
              ENDFOR
            endelse
         ENDIF
      ENDIF
   ENDIF 
   
END
