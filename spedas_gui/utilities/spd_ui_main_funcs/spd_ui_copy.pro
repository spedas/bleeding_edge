;+
;
;  Name: SPD_UI_COPY
;
;  Purpose: Copies the current page to the clipboard. 
;           Should also work with Ctrl+C. 
;           It can also be called from spd_ui_draw_event
;
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_copy.pro $
;-


pro spd_ui_copy, info

  if info.marking eq 0 && info.rubberbanding eq 0 then begin
    info.ctrl=0
    dataNames = info.loadedData->GetAll()
    IF Is_Num(dataNames) THEN BEGIN
      info.statusBar->Update, 'The copy operation is not functional until data has been loaded'
    ENDIF ELSE BEGIN
      info.drawObject->vbaroff
      info.drawObject->hBaroff
      info.drawobject->legendoff
      
      ;disable legends so they will not be shown in copy-paste operations
      cWindow = info.windowStorage->getActive()
      if obj_valid(cWindow) then begin
        cWindow->getProperty, Panels=panels
        if obj_valid(panels) then begin
          panelssave = panels
          panelObjs = panels->Get(/all)
          if obj_valid(panelObjs[0]) then begin
            old_enabled_values = intarr(n_elements(panelObjs))
            for i=0, n_elements(panelObjs)-1 do begin
              panelObjs[i]->getProperty, legendSettings=legendSettings
              legendsettings->getProperty, enabled=enabled
              old_enabled_values[i] = enabled
              legendsettings->disable
            endfor
          endif
        endif
      endif
      
      ;quick fix by prc to make this thing work for presentation.  It originally used the call:
      ;info.drawWin->getProperty,units=units,original_virtual_dimensions=virtual_dimensions
      ;but original_virtual_dimensions is not actually a keyword for IDLgrWindow->getProperty
      info.drawWin->getProperty,units=units,virtual_dimensions=virtual_dimensions
      myClipboard=Obj_New('IDLgrClipboard', Quality=2, Dimensions=virtual_dimensions,units=units)
      info.drawObject->SetProperty,destination=myclipboard
      info.drawObject->update,info.windowStorage,info.loadedData
      info.drawObject->Draw,vector=0,postscript=0
      
      ;reset disabled legends to their perious values
      if obj_valid(panelObjs[0]) then begin
        for i=0, n_elements(panelObjs)-1 do begin
          if old_enabled_values[i] then begin
            panelObjs[i]->getProperty, legendSettings=legendSettings
            legendsettings->setProperty, enabled=1
          endif
        endfor
      endif
      
      ;redraw old window
      info.drawObject->setProperty, destination=info.drawWin
      info.drawObject->update,info.windowStorage,info.loadedData
      info.drawObject->Draw
      
      result = widget_info(info.trackvMenu,/button_set)
      if result eq 1 then begin
        result = widget_info(info.trackAllMenu,/button_set)
        IF result eq 1 THEN info.drawObject->vBarOn, /all ELSE info.drawObject->vBarOn
      endif
      
      result = widget_info(info.trackhMenu,/button_set)
      if result eq 1 then begin
        result = widget_info(info.trackAllMenu,/button_set)
        ; IF result eq 1 THEN info.drawObject->hBarOn, /all ELSE info.drawObject->hBarOn
        info.drawObject->hBarOn
      endif
      
      result = Widget_Info(info.showPositionMenu, /button_set)
      IF result EQ 1 THEN BEGIN
        IF info.trackAll EQ 1 THEN info.drawObject->legendOn, /All ELSE info.drawObject->legendOn
      ENDIF
    ENDELSE
  endif
  
end
