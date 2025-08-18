;To kill rubberbanding and markers and reset tracking in cases
;where opteration(s) is undesired or poorly defined 
PRO SPD_UI_RESET_TRACKING, info
       if info.rubberbanding GE 0 or info.marking GE 0 then begin
          info.marking=0
          info.rubberbanding=0
          info.markers = [0.0,0.0]
          info.drawObject->markerOff
          info.drawObject->rubberBandOff 
          legend = Widget_Info(info.showPositionMenu, /Button_Set)
          vBar = widget_info(info.trackVMenu,/button_set)
          if vBar eq 1 then begin
            info.drawObject->vBarOn,all=info.trackAll
          endif
         
         hBar = widget_info(info.trackhMenu,/button_set)
         if hBar eq 1 then begin
         ;  IF info.trackAll EQ 1 THEN info.drawObject->hBarOn, /all ELSE info.drawObject->hBarOn
           info.drawObject->hBarOn
         endif   
         
         legend = Widget_Info(info.showPositionMenu, /Button_Set)
         IF legend EQ 1 THEN BEGIN
           info.drawObject->legendOn,all = info.trackAll
         ENDIF 
        endif
        info.drawObject->Update,info.windowStorage,info.loadedData 
        info.drawObject->Draw
END
