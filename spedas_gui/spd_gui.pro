;+  
;NAME:
;
; spd_gui
;
;PURPOSE:
; GUI for SPEDAS data analysis
;
;CALLING SEQUENCE:
; spd_gui
;
;INPUT:
; none
; 
; Keywords:
;   Reset - If set will reset all internal settings.  
;           Otherwise, it will try to load the state of the previous call.
;   template_filename - The file name of a previously saved spedas template document,
;                   can be used to store user preferences and defaults.
;
;OUTPUT:
; none
;
;HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-07-31 14:34:33 -0700 (Tue, 31 Jul 2018) $
;$LastChangedRevision: 25534 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/spd_gui.pro $
;-----------------------------------------------------------------------------------


PRO spd_gui_event, event

  COMPILE_OPT hidden

  err_xxx = 0
  catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    catch, /cancel
    help, /last_message, output = err_msg
    For j = 0, n_elements(err_msg)-1 Do begin
      if is_struct(info) && obj_valid(info.historywin) then begin
        info.historywin->update,err_msg[j]
      endif
      print, err_msg[j]
    endfor
    If(is_struct(info)) Then Begin
      ; allow for cursor events again after crash
      info.drawDisabled = 0
      x=info.master
 
      if obj_valid(info.historywin) then begin
        spd_gui_error,x,info.historywin
      endif
 
      if widget_valid(event.top) then begin
        ;this call unsets info, you can't use it again after this line
        widget_control, event.top, set_uval = info, /no_copy
      endif else begin
        print,'Potentially catastrophic error.  You may want to terminate the gui by selecting run->terminate'
      endelse
      
    
    Endif else begin
      print,'Potentially catastrophic error.  You may want to terminate the gui by selecting run->terminate'
    endelse

    return

  Endif
  
  ;kill request block

  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
    spd_ui_exit,event,info=info
    return
  ENDIF

  ; Get the info structure from the top level widget

  Widget_Control, event.top, Get_UValue=info
  if ~is_struct(info) then begin
    t = error_message('Unset info in Event Handler',/Traceback, /center, title='Error in GUI')
    Widget_control,event.top,/destroy
    return
  endif

  ; check whether we should turn off the context menu
  if info.contextMenuOn then begin
    IF(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_DRAW') && ~event.press && ~event.release && event.type eq 2  THEN BEGIN
      info.contextMenuOn = 1; stay set
    endif else info.contextMenuOn = 0
  endif

    ;resize event
    
  IF(tag_names(event,/structure_name) eq 'WIDGET_BASE') then begin
  
    tm = systime(/seconds)
  
    ;can get a series of resizes in quick succession
    ;this code will ignore all resizes after the first 
    ;for a short time
    if tm - info.resizetime gt .25 then begin
    
      newx = event.x - info.interface_size[0]
      newy = event.y - info.interface_size[1]
  
      charSize = ceil(newx/!d.x_ch_size)
      mincharsize = ceil(info.toolbar_xsize/!d.x_ch_size)
      
      widget_control,info.master,update=0
      if strlowcase(!version.os_family) eq 'windows' then begin
        ; These are empirical numbers that fix a sizing problem in MS Windows
        newx = newx + 19
        newy = newy + 2
        widget_control,info.drawID,scr_xsize=newx > info.toolbar_xsize,scr_ysize=newy>1
      endif else begin
        widget_control,info.drawID,xsize=newx > info.toolbar_xsize,ysize=newy>1
      endelse
      
      
      info.scrollbar->setProperty,xsize=newx > info.toolbar_xsize

      res = info.statusBar->GetState() 
      if res EQ 0 then begin
         info.statusBar->Delete
      endif else begin
         info.statusBar->setProperty,xsize=charsize > mincharsize,/refresh
         info.statusBar->Draw
      endelse
      ;info.pathBar->setProperty,xsize=charsize,/refresh
      widget_control,info.master,update=1

     info.screenSize=[newx > info.toolbar_xsize,newy>1]
     info.resizetime = systime(/seconds)
     
     info.drawObject->draw
    
    endif
    
    Widget_Control, event.top, Set_UValue=info, /No_Copy
    RETURN
    
  endif

  ; Handle all events in the draw window first
 
  
  IF tag_names(event, /structure_name) eq 'WIDGET_TRACKING' then begin
    info.draw_select = event.enter
    
    if info.marking ne 0 or info.rubberbanding ne 0 then begin
      if event.enter EQ 0 then spd_ui_reset_tracking, info
    endif
    
    Widget_Control, event.top, Set_UValue=info, /No_Copy
    return  
  endif
  
  IF(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_DRAW') THEN BEGIN
    ; main handler for all events that occur in the draw window (cursor movement,
    ; button presses, and keyboard events)
    info=spd_ui_draw_event(event, info)
    
    ;handle an exit code
    if ~is_struct(info) then return

    ;this code redraws the window if manual redraw & expose events are enabled
    if event.type eq 4 then begin
      info.drawObject->draw
    endif

    Widget_Control, event.top, Set_UValue=info, /No_Copy
    RETURN
  ENDIF

  ; Check for keyboard events

  IF (TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KBRD_FOCUS') THEN BEGIN
    Widget_Control, event.top, Set_UValue=info, /No_Copy
    RETURN
  ENDIF

  ; Handle plugins
  
  uname = widget_info(event.id, /uname)
  
  if uname eq 'GUI_PLUGIN' then begin
    
    spd_ui_call_plugin, event, info
    
    widget_control, event.top, set_uvalue=info, /no_copy
    
    return
    
  endif

  ; Handle events from standard GUI widgets

  ;identify widget by string stored in uvalue
  Widget_Control, event.id, Get_UValue=userValue

  ;disable cursor events during panels
  info.drawDisabled = 1
  Widget_Control, event.TOP, Set_UValue=info

  ;event will turn off context menu
  ;Putting this here should be okay, even
  ;though not all events below are context events
  info.contextMenuOn = 0

  CASE userValue OF
  
    'EXIT': BEGIN
      spd_ui_exit,event,info=info
      return
    end

    'OPEN': BEGIN
      spd_ui_open,info
    END

    'SAVE': BEGIN
      spd_ui_save,info
    END

    'SAVEAS': BEGIN      
      spd_ui_saveas,info
    END
    
   'OPEN_TEMPLATE': BEGIN
      spd_ui_open_template,info
    END

    'SAVE_TEMPLATE': BEGIN
      spd_ui_save_template,info
    END

    'SAVEAS_TEMPLATE': BEGIN      
      spd_ui_saveas_template,info
    END
    
    'SAVEDATAAS': BEGIN
       data = info.loadedData->GetAll()
       IF Is_Num(data) THEN info.statusBar->Update, 'There is no data to save. Please load data using the Load Data option under the File pull down menu.' $
         ELSE BEGIN 
         spd_ui_save_data_as, info.master, info.loadedData, info.historywin,info.guiTree, info.saveDataDirPtr, info.statusbar
         ENDELSE
    END

;    'SAVEWITH': BEGIN
;      spd_ui_save_data, info.master, info.historywin
;      saveWith=1
;      IF  EQ 1 THEN BEGIN
;        xt = Time_String(Systime(/sec))
;        timeString = Strmid(xt, 0, 4)+Strmid(xt, 5, 2)+Strmid(xt, 8, 2)+$
;          '_'+Strmid(xt,11,2)+Strmid(xt,14,2)+Strmid(xt,17,2)
;        fileString = 'spedas_saved_'+timeString
;        fileName = Dialog_Pickfile(Title = 'Save With Data SPEDAS Document:', $
;          Filter = '*.tgd', File = fileName, /Write, Dialog_Parent=info.master)
;        IF (Is_String(fileName)) THEN BEGIN
;          statusMessage = 'Successfully saved SPEDAS document with data as: '+fileName
;          info.statusBar->Update, statusMessage
;        ENDIF ELSE BEGIN
;          info.statusBar->Update, 'Operation Cancelled'
;        ENDELSE
;      ENDIF
;    END

    'CLOSE': BEGIN
        spd_ui_close_window, info
	 END

    'LOAD': BEGIN
       loadDataTabs = info.pluginManager->getLoadDataPanels()
       
       dataLoadSelectPtr = info.dataLoadSelectPtr
       spd_ui_init_load_window, info.master, info.windowStorage, info.loadedData, $
                                info.historyWin, $
                                info.loadtr,info.guiTree,dataLoadSelectPtr, loadDataTabs
       info.dataLoadSelectPtr = dataLoadSelectPtr
     
       info.drawObject->Update,info.windowStorage,info.loadedData 
       info.drawObject->Draw
       info.scrollbar->update
    END
     
    'LOADHAPI': BEGIN
      spd_ui_load_hapi, info.master, info.historyWin, info.statusBar, timeRangeObj=timeRangeObj
    END
  
    'LOADCDAWEB': BEGIN
      if cdf_version_test() ne 0 then begin
          info.windowStorage->getProperty,callsequence=callsequence
          spd_ui_spdfcdawebchooser, historyWin=info.historyWin, GROUP_LEADER = info.master,timeRangeObj=info.loadtr,callsequence=callsequence
      endif else begin
          spd_ui_message, 'The CDF library is out-of-date. To install the required patch, see: http://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html', hw=info.historyWin, sb=info.statusBar, /dialog
      endelse
    END
    
    'LOADCDF': BEGIN
      spd_ui_load_spedas_cdf, info
    END
    
    'LOADASCII': BEGIN
      ;
      ; todo: HGS
      spd_ui_load_spedas_ascii, info, event
    END

    'MANAGEDATA': BEGIN
       spd_ui_manage_data, info.master, info.loadedData, info.windowStorage, info.historywin,info.guiTree
       info.drawObject->Update,info.windowStorage,info.loadedData 
       info.drawObject->Draw
    END
    
    'EXPORTMETA': BEGIN
      info.drawObject->draw
   
      saveObj = obj_new('spd_ui_draw_save',info.drawObject,info.loadedData,info.windowStorage)
      fileStruct = spd_ui_image_export(info.master,info.drawObject,info.historywin,info.statusBar,info.imageOptions)
      
      IF(Is_String(fileStruct.name)) THEN BEGIN
      
  ;      saveObj = obj_new('spd_ui_draw_save',info.drawObject)
        
        if obj_valid(saveObj) && saveObj->write(fileStruct) then begin
          statusMessage = 'Successfully saved file: '+ fileStruct.name
          info.statusBar->Update, statusMessage
          info.historyWin->update,statusMessage
          ptr_free,info.imageOptions
          info.imageOptions = ptr_new(fileStruct)
        endif else begin
          info.statusBar->Update, 'Image Save Failed'
          info.historyWin->Update,'Image Save Failed'
        endelse
        
        obj_destroy,saveObj
        
      ENDIF ELSE BEGIN
        info.statusBar->Update, 'Image Save Cancelled'
      ENDELSE
    END

    'LOADTHEME': BEGIN
      fileName = Dialog_Pickfile(Title='Open SPEDAS Theme File:', $
        Filter='*.thm', Dialog_Parent=info.master)
      IF(Is_String(fileName)) THEN BEGIN
        statusMessage = 'Successfully opened SPEDAS Theme File: '+fileName
        info.statusBar->Update, statusMessage
      ENDIF ELSE BEGIN
        statusMessage = 'Invalid Filename: '+fileName
        info.statusBar->Update, statusMessage
      ENDELSE
    END

    'SAVETHEME': BEGIN
      fileName = Dialog_Pickfile(Title='Save SPEDAS Theme File:', $
        Filter='*.thm', /Write, Dialog_Parent=info.master)
      IF(Is_String(fileName)) THEN BEGIN
        statusMessage = 'Successfully saved SPEDAS Theme File: '+fileName
        info.statusBar->Update, statusMessage
      ENDIF ELSE BEGIN
        statusMessage = 'Invalid Filename: '+fileName
        info.statusBar->Update, statusMessage
      ENDELSE
    END

    'IMPORTM': BEGIN
      dummy=dialog_message('Import Marker List not yet implemented',/ERROR,/CENTER, title='Error in GUI')
    END

    'EXPORTM': spd_ui_export_markers, info.master

    'EXPORTML': BEGIN
      fileName = Dialog_Pickfile(Title='Export SPEDAS Marker List:', $
        Filter='*.mrk', /Write, Dialog_Parent=info.master)
      IF(Is_String(fileName)) THEN BEGIN
         save_marker_list,windowstorage=info.windowstorage,filename=fileName,$
             statusmsg=statusmsg,statuscode=statuscode
         IF (statuscode LT 0) THEN BEGIN
              info.statusBar->Update, statusmsg
              dummy=dialog_message(statusmsg,/ERROR,/CENTER, title='Error in GUI')
         ENDIF ELSE BEGIN
              info.statusBar->Update, statusmsg
         ENDELSE
      ENDIF
 
    END

    'PRINT': BEGIN
      info.ctrl=0
      spd_ui_print,info
    END
    
    'PSETUP': BEGIN
      if info.printWarning eq 0 then begin
        ok = dialog_message("IDL printer support can be unreliable." + ssl_newline() + $
                            'If you have trouble, try exporting from the "File->Export to Image File" menu.' + ssl_newline() + $
                            '"File->Export to Image File" supports eps, png, and numerous other image formats.',$
                            dialog_parent=info.master) 
        info.printwarning=1  
      endif
      
      info.statusbar->update,'Warning: IDL printer support can be unreliable, if you have trouble try exporting to via the "File->Export to Image File" menu.'  
      
      info.printObj = Obj_New("IDLgrPRINTER", Print_Quality=2, Quality=2)
      result=Dialog_Printersetup(info.printObj, Dialog_Parent=info.master)
      IF result NE 0 THEN spd_ui_print,info
    END

    'COPY': spd_ui_copy, info
    
    'DELETEM': spd_ui_delete_marker, info
    
    'SUBPAGE': BEGIN
       oldWindow = info.windowStorage->GetActive()
       newWindow = oldWindow->Copy()
;       newWindow->GetProperty, NRows=nrows, NCols=ncols, Panels=panels, Settings=settings, $
;        Tracking=tracking, Locked=locked
;       result = info.windowStorage->Add(NRows=nrows, NCols=ncols, Panels=panels, Settings=settings, $
;        Tracking=tracking, Locked=locked)
       result = info.windowStorage->AddNewObject(newWindow)
       activeWindow = info.windowStorage->GetActive()
       oldWindow->getProperty,settings=settings  ;override any defaults which may be set by template
       activeWindow->setProperty,settings=settings->copy()
       activeWindow->GetProperty, Name=name 
       info.windowMenus->Add, name
       info.windowMenus->Update, info.windowStorage
       info.drawObject->update,info.windowStorage, info.loadedData
       info.drawObject->draw
       info.scrollbar->update
       info.statusbar->update,'Subset page finished.  New window displayed.'
    END
    
    'SUBMARKER': spd_ui_subset_marker, info
    
    'SUBMARKERMULTI': spd_ui_subset_marker_multi,info
    
;    'EXMD': BEGIN
;
;     result = Widget_Info(event.id, /Button_Set)
;     IF result EQ 0 THEN BEGIN
;
;       example_data,info
;
;       info.statusBar->Update, 'Example window displayed'
;     ENDIF ELSE BEGIN
;       info.statusBar->Update, 'Example window not displayed'
;     ENDELSE
;     FOR i=0, N_Elements(info.panelButtons)-1 DO Widget_Control, info.panelButtons[i], sensitive=1
;     FOR i=0, N_Elements(info.markerButtons)-1 DO Widget_Control, info.markerButtons[i], sensitive=1
;     
;    END
    
    'TEST': BEGIN
      spd_ui_widget_tree_test,info.master,info.loadedData, info.historywin
      
     END
    'CONF': BEGIN
;      Do Not erase in case graphic buttons are reinstalled
;      info.drawObject->draw
;      drawID = info.drawId
;      drawWin = info.drawWin
       fileconfig_panels = info.pluginManager->getFileConfigPanels()
       spd_ui_init_fileconfig, info.master, info.historyWin, fileconfig_panels

;      do not erase in case graphcs are reinstalled
;      spd_ui_init_fileconfig, info.master, drawId, drawWin, $ 
;                               info.drawObject, $
;                               info.screenSize, info.graphBase, info.historyWin
;      info.drawId = drawId
;      info.drawWin =  drawWin
;      info.drawObject->Update,info.windowStorage,info.loadedData 
;      info.drawObject->Draw
;      info.scrollbar->update
;      info.drawId = drawId
;      info.drawWin = drawWin
;      info.drawDisableTimer = systime(/seconds)
       
      ; update the references in info to template
      info.template_filename = !spedas.templatepath
      
      ; only update the template object if there is a window storage object
      ; NOTE: I only come across this case (no windowStorage object) when resetting 
      ;       the !spedas system variable via configuration settings - egrimes, 6/8/2015
      if obj_valid(!spedas.windowstorage) then begin
          !spedas.windowstorage->GetProperty,template = templateobj
          info.template_object = templateobj 
      endif

    ;  print,info.drawDisableTimer                         
    END

    'JUMP': spd_ui_jump, info.master, info.historywin

    'JOURNAL': BEGIN
      result = Widget_Info(event.id, /Button_Set)
      IF result EQ 0 THEN BEGIN
         Widget_Control, event.id, Set_Button=1
         Journal,'spd_ui_idlsave.pro'
         info.statusBar->Update, 'Journaling has been turned on'
         info.historyWin->Update, 'Journaling has been turned on'
      ENDIF ELSE BEGIN
         Widget_Control, event.id, Set_Button=0
         Journal
         info.statusBar->Update, 'Journaling has been turned off'
         info.historyWin->Update, 'Journaling has been turned off'
      ENDELSE
    END
   
    'REFRESH': BEGIN
      info.ctrl=0
      spd_ui_refresh,info
    END

    'SCROLLF':BEGIN

      spd_ui_scrollf,info

    END

    'SCROLLB':BEGIN
    
       spd_ui_scrollb,info
    
    END

    'EXPAND':BEGIN
      spd_ui_expand,info
    END

    'REDUCE':BEGIN
      spd_ui_reduce,info
    END

    'HISTORYW': BEGIN
      result = Widget_Info(event.id, /Button_Set)
      IF result EQ 0 THEN BEGIN
        Widget_Control, event.id, Set_Button=1
        info.historyWin->Draw
      ENDIF ELSE BEGIN
        Widget_Control, event.id, Set_Button=0
        info.historyWin->Delete
      ENDELSE
    END

    'PATHBAR': BEGIN
      result = Widget_Info(event.id, /Button_Set)
      IF result EQ 0 THEN BEGIN
        Widget_Control, event.id, Set_Button=1
        info.pathBar->Draw
      ENDIF ELSE BEGIN
        Widget_Control, event.id, Set_Button=0
        info.pathBar->Delete
      ENDELSE
    END

    ;Note on code related to various tracking switches
    ;Because events and clicks can be unreliable this code goes a little bit
    ;overboard in guaranteeing valid state and restoring state even when an
    ;invariant should guarantee state.
    ;Concretely, (1) It tries to check the widget values, rather than rely on the internal info.* flag
    ;            (2) It tries not to flip flags via newval = ~oldval logic, but instead sets value exactly, ie newval = 1 -or- newval = 0
    ;            (3) It resets the info.* flags whenever it can be certain of what a value should be
    ;In the long run we should try to eliminate the number of flags. So we can rely primarily on widget state
    'POSITIONBAR': BEGIN
      result = Widget_Info(event.id, /Button_Set)
 
      ;change legend from off to on 
      if result eq 0 then begin

        info.legendOn = 1
        info.tracking = 1
        widget_control,info.showPositionMenu,set_button=1
        widget_control,info.trackMenu,set_button=1
        
        ;this trackone/trackall section is identical to a case in the vertical bar code
        if info.trackAll then begin
          info.trackOne = 0
          info.trackAll = 1
          widget_control,info.trackAllMenu,set_button=1
          widget_control,info.trackOneMenu,set_button=0
          
          all = 1
        endif else begin
          info.trackOne = 1
          info.trackAll = 0
          widget_control,info.trackAllMenu,set_button=0
          widget_control,info.trackOneMenu,set_button=1
          
          all = 0
        endelse
        
        info.drawObject->LegendOn,all=all
        
        if info.trackingv then begin
          info.trackingv = 1
          widget_control,info.trackvMenu,set_button=1
          info.drawObject->vBarOn,all=all
        endif else begin
          info.trackingv = 0
          widget_control,info.trackvMenu,set_button=0
          info.drawObject->vBarOff
        endelse
        
        if info.trackingh then begin
          info.trackingh = 1
          widget_control,info.trackhMenu,set_button=1
         ; info.drawObject->hBarOn,all=all
          info.drawObject->hBarOn 
        endif else begin
          info.trackingh = 0
          widget_control,info.trackhMenu,set_button=0
          info.drawObject->hBarOff
        endelse
        
        activeWindow=info.windowStorage->GetActive()
        if n_elements(activeWindow) gt 0 && $
          obj_valid(activeWindow[0]) then begin
          activeWindow[0]->SetProperty, Tracking=1
        endif
        
        ;whenever tracking is turned on a update/redraw needs to be done
        ;this is because the zoom may have been changed between tracking
        ;this leads to an incorrectly sized legend if not redrawn
        info.drawObject->Update,info.windowStorage,info.loadedData 
        info.drawObject->Draw
        
        info.statusBar->Update, 'Legend tracking turned on'
        
      ;change legend from on to off
      endif else begin

        info.legendOn = 0
        widget_control,info.showPositionMenu,set_button=0
        info.drawObject->legendOff

        ;if vBar && hBar are also off, then turn other tracking switches off
        resultv = widget_info(info.trackvMenu,/button_set)
        resulth = widget_info(info.trackhMenu,/button_set)
        if ~resultv && ~resulth then begin
          info.tracking = 0
          info.trackingv = 0
          info.trackingh = 0
          widget_control,info.trackMenu,set_button=0
          widget_control,info.trackAllMenu,set_button=0
          widget_control,info.trackOneMenu,set_button=0
          info.drawObject->vBarOff
          info.drawObject->hBarOff
          activeWindow=info.windowStorage->GetActive()
          if n_elements(activeWindow) gt 0 && $
            obj_valid(activeWindow[0]) then begin
            activeWindow[0]->SetProperty, Tracking=0
          endif
        endif
        
        info.statusBar->Update, 'Legend tracking turned off'
      
      endelse
 
    END

;    'STATUSBAR': BEGIN
;      result = Widget_Info(event.id, /Button_Set)
;      IF result EQ 0 THEN BEGIN
;        Widget_Control, event.id, Set_Button=1
;        info.statusBar->Draw
;      ENDIF ELSE BEGIN
;        Widget_Control, event.id, Set_Button=0
;        info.statusBar->Delete
;      ENDELSE
;    END

;Note on code related to various tracking switches
    ;Because events and clicks can be unreliable this code goes a little bit
    ;overboard in guaranteeing valid state and restoring state even when an
    ;invariant should guarantee state.
    ;Concretely, (1) It tries to check the widget values, rather than rely on the internal info.* flag
    ;            (2) It tries not to flip flags via newval = ~oldval logic, but instead sets value exactly, ie newval = 1 -or- newval = 0
    ;            (3) It resets the info.* flags whenever it can be certain of what a value should be
    ;In the long run we should try to eliminate the number of flags. So we can rely primarily on widget state
    'TRACK': BEGIN
      result = Widget_Info(event.id, /Button_Set)
      ;if tracking is off, then we turn it on
      IF result EQ 0 THEN BEGIN
      
        ;if tracking is turned on then turn on the appropriate trackOne or trackAll setting
        if ~info.trackAll && info.trackOne then begin
          Widget_Control, info.trackAllMenu, Set_Button=0
          Widget_Control, info.trackOneMenu, Set_Button=1
          info.trackAll=0
          info.trackOne=1
        endif else if info.trackAll && ~info.trackOne then begin
          Widget_Control, info.trackAllMenu, Set_Button=1
          Widget_Control, info.trackOneMenu, Set_Button=0
          info.trackOne=0
          info.trackAll=1
        endif else begin
          Widget_Control, info.trackAllMenu, Set_Button=1
          Widget_Control, info.trackOneMenu, Set_Button=0
          info.trackOne=0
          info.trackAll=1
          info.statusBar->update,'Tracking in unexpected or illegal internal state'
        endelse
        
        ;if all tracking is off, then turn them all on
        if (~info.trackingv && ~info.legendOn && ~info.trackingh) then begin
          widget_control,info.showPositionMenu,set_button=1
          widget_control,info.trackvMenu,set_button=1
          widget_control,info.trackhMenu,set_button=1
          info.drawObject->vBarOn,all=info.trackAll
          ;info.drawObject->hBarOn,all=info.trackAll
          info.drawObject->hBarOn
          info.drawObject->legendOn,all=info.trackAll
          info.trackingv = 1
          info.trackingh = 1
          info.legendOn = 1
        endif else begin
        
          if info.trackingv then begin
            widget_control,info.trackvMenu,set_button=1
            info.drawObject->vBarOn,all=info.trackAll
          endif else begin
            widget_control,info.trackvMenu,set_button=0
            info.drawObject->vBarOff
          endelse
          
          if info.trackingh then begin
            widget_control,info.trackhMenu,set_button=1
          ;  info.drawObject->hBarOn,all=info.trackAll
            info.drawObject->hBarOn
          endif else begin
            widget_control,info.trackhMenu,set_button=0
            info.drawObject->hBarOff
          endelse
          
          if info.legendOn then begin
            widget_control,info.showPositionMenu,set_button=1
            info.drawObject->legendOn,all=info.trackAll
          endif else begin
            widget_control,info.showPositionMenu,set_button=0
            info.drawObject->legendOff
          endelse
        
        endelse
        
        activeWindow=info.windowStorage->GetActive()
        if n_elements(activeWindow) gt 0 && $
           obj_valid(activeWindow[0]) then begin
           activeWindow[0]->SetProperty, Tracking=1
        endif
        
        widget_control,event.id,set_button=1
        info.tracking = 1
        info.statusBar->Update, 'Tracking turned on'
        
        ;whenever tracking is turned on a update/redraw needs to be done
        ;this is because the zoom may have been changed between tracking
        ;this leads to an incorrectly sized legend if not redrawn
        info.drawObject->Update,info.windowStorage,info.loadedData 
        info.drawObject->Draw
      
      endif else begin
        
        Widget_Control, info.trackhMenu, Set_Button=0
        Widget_Control, info.trackvMenu, Set_Button=0
        Widget_Control, info.trackAllMenu, Set_Button=0
        Widget_Control, info.trackOneMenu, Set_Button=0
        widget_control, info.showPositionMenu,set_button=0
        Widget_Control, event.id, Set_Button=0
      
        activeWindow=info.windowStorage->GetActive()
        if n_elements(activeWindow) gt 0 && $
           obj_valid(activeWindow[0]) then begin
           activeWindow[0]->SetProperty, Tracking=0
        endif
            
        info.drawObject->vBarOff
        info.drawObject->hBarOff
        info.drawObject->legendOff
        
        info.tracking = 0
        info.statusBar->Update, 'Tracking turned off'
           
      endelse
      
    end
      
    ;Note on code related to various tracking switches
    ;Because events and clicks can be unreliable this code goes a little bit
    ;overboard in guaranteeing valid state and restoring state even when an
    ;invariant should guarantee state.
    ;Concretely, (1) It tries to check the widget values, rather than rely on the internal info.* flag
    ;            (2) It tries not to flip flags via newval = ~oldval logic, but instead sets value exactly, ie newval = 1 -or- newval = 0
    ;            (3) It resets the info.* flags whenever it can be certain of what a value should be
    ;In the long run we should try to eliminate the number of flags. So we can rely primarily on widget state
    ;Also, note that this case is symmetrical to the trackall case 
    'TRACKALL': BEGIN
      result = Widget_Info(event.id, /Button_Set)
      
      ;switching from track one to track all
      IF result EQ 0 THEN BEGIN
        info.trackAll = 1
        info.trackOne = 0
        info.tracking = 1
        Widget_Control, info.trackAllMenu, Set_Button=1
        Widget_Control, info.trackOneMenu, Set_Button=0
        Widget_Control, info.trackMenu, Set_Button=1

        all = 1

      ;switching from track all to track one
      ENDIF ELSE BEGIN
      
        info.trackall = 0
        info.trackOne = 1
        info.tracking = 1
        Widget_Control, info.trackAllMenu, Set_Button=0
        Widget_Control, info.trackOneMenu, Set_Button=1
        Widget_Control, info.trackMenu, Set_Button=1
        
        all = 0
      
      ENDELSE
      
     if info.trackingv then begin
       widget_control,info.trackvMenu,set_button=1
       info.drawObject->vBarOn, all=all
     endif
    
     if info.legendOn then begin
       widget_control,info.showPositionMenu,set_button=1
       info.drawObject->legendOn,all=all
     endif
     
     if info.trackingh then begin
       widget_control,info.trackhMenu,set_button=1
    ;   info.drawObject->hBarOn, all=all
       info.drawObject->hBarOn
     endif
    
     ;if they are all off turn them on so we get some visible result
     if ~info.trackingv && ~info.legendOn && ~info.trackingh then begin
       info.trackingv = 1
       info.trackingh = 1
       info.legendOn = 1
       widget_control,info.trackvMenu,set_button=1
       info.drawObject->vBarOn, all=all
       widget_control,info.trackhMenu,set_button=1
      ; info.drawObject->hBarOn, all=all
       info.drawObject->hBarOn
       widget_control,info.showPositionMenu,set_button=1
       info.drawObject->legendOn,all=all
     endif
      
     activeWindow=info.windowStorage->GetActive()
     if n_elements(activeWindow) gt 0 && $
        obj_valid(activeWindow[0]) then begin
        activeWindow[0]->SetProperty, Tracking=1
     endif

    ;whenever tracking is turned on a update/redraw needs to be done
    ;this is because the zoom may have been changed between tracking
    ;this leads to an incorrectly sized legend if not redrawn
    info.drawObject->Update,info.windowStorage,info.loadedData 
    info.drawObject->Draw

     if all then begin
       info.statusBar->Update, 'Tracking turned on for all panels'
     endif else begin
       info.statusBar->Update, 'Tracking turned on for single panel'
     endelse
         
    END
    
    ;Note on code related to various tracking switches
    ;Because events and clicks can be unreliable this code goes a little bit
    ;overboard in guaranteeing valid state and restoring state even when an
    ;invariant should guarantee state.
    ;Concretely, (1) It tries to check the widget values, rather than rely on the internal info.* flag
    ;            (2) It tries not to flip flags via newval = ~oldval logic, but instead sets value exactly, ie newval = 1 -or- newval = 0
    ;            (3) It resets the info.* flags whenever it can be certain of what a value should be
    ;In the long run we should try to eliminate the number of flags. So we can rely primarily on widget state
    ;Also, Note that this case is symmetrical to the trackall case
    'TRACKONE': BEGIN
    
      result = Widget_Info(event.id, /Button_Set)
          
      ;switching from track one to track all
      IF result EQ 1 THEN BEGIN
        info.trackAll = 1
        info.trackOne = 0
        info.tracking = 1
        Widget_Control, info.trackAllMenu, Set_Button=1
        Widget_Control, info.trackOneMenu, Set_Button=0
        Widget_Control, info.trackMenu, Set_Button=1

        all = 1

      ;switching from track all to track one
      ENDIF ELSE BEGIN
      
        info.trackall = 0
        info.trackOne = 1
        info.tracking = 1
        Widget_Control, info.trackAllMenu, Set_Button=0
        Widget_Control, info.trackOneMenu, Set_Button=1
        Widget_Control, info.trackMenu, Set_Button=1
        
        all = 0
      
      ENDELSE
      
     if info.trackingv then begin
       widget_control,info.trackvMenu,set_button=1
       info.drawObject->vBarOn, all=all
     endif
     
     if info.trackingh then begin
       widget_control,info.trackhMenu,set_button=1
      ; info.drawObject->hBarOn, all=all
       info.drawObject->hBarOn
     endif
    
     if info.legendOn then begin
       widget_control,info.showPositionMenu,set_button=1
       info.drawObject->legendOn,all=all
     endif
    
     ;if they are all off turn them on so we get some visible result
     if ~info.trackingv && ~info.legendOn && ~info.trackingh then begin
       info.trackingv = 1
       info.trackingh = 1
       info.legendOn = 1
       widget_control,info.trackvMenu,set_button=1
       info.drawObject->vBarOn, all=all
       widget_control,info.trackhMenu,set_button=1
     ; info.drawObject->hBarOn, all=all
       info.drawObject->hBarOn
       widget_control,info.showPositionMenu,set_button=1
       info.drawObject->legendOn,all=all
     endif
      
     activeWindow=info.windowStorage->GetActive()
     if n_elements(activeWindow) gt 0 && $
        obj_valid(activeWindow[0]) then begin
        activeWindow[0]->SetProperty, Tracking=1
     endif
     
     ;whenever tracking is turned on a update/redraw needs to be done
     ;this is because the zoom may have been changed between tracking
     ;this leads to an incorrectly sized legend if not redrawn
     info.drawObject->Update,info.windowStorage,info.loadedData 
     info.drawObject->Draw 

     if all then begin
       info.statusBar->Update, 'Tracking turned on for all panels'
     endif else begin
       info.statusBar->Update, 'Tracking turned on for single panel'
     endelse
    END
    
    ;Note on code related to various tracking switches
    ;Because events and clicks can be unreliable this code goes a little bit
    ;overboard in guaranteeing valid state and restoring state even when an
    ;invariant should guarantee state.
    ;Concretely, (1) It tries to check the widget values, rather than rely on the internal info.* flag
    ;            (2) It tries not to flip flags via newval = ~oldval logic, but instead sets value exactly, ie newval = 1 -or- newval = 0
    ;            (3) It resets the info.* flags whenever it can be certain of what a value should be
    ;In the long run we should try to eliminate the number of flags. So we can rely primarily on widget state
   'TRACKV': BEGIN
      result = Widget_Info(event.id, /Button_Set)
      
      ;going from vbarOff to vbarOn
      if result eq 0 then begin
      
        ;if vBarOn is selected, turn tracking settings on
        info.trackingv = 1
        info.tracking = 1
        widget_control,info.trackvMenu,set_button=1
        widget_control,info.trackMenu,set_button=1
        
        ;this trackone/trackall section is identical to a case in the postion bar code
        if info.trackAll then begin
          info.trackOne = 0
          info.trackAll = 1
          widget_control,info.trackAllMenu,set_button=1
          widget_control,info.trackOneMenu,set_button=0
          
          all = 1
        endif else begin
          info.trackOne = 1
          info.trackAll = 0
          widget_control,info.trackAllMenu,set_button=0
          widget_control,info.trackOneMenu,set_button=1
          
          all = 0
        endelse
        
        info.drawObject->vBarOn,all=all
        
        if info.legendOn then begin
          info.legendOn = 1
          widget_control,info.showPositionMenu,set_button=1
          info.drawObject->legendOn,all=all
        endif else begin
          info.legendOn = 0
          widget_control,info.showPositionMenu,set_button=0
          info.drawObject->legendOff
        endelse
        
        if info.trackingh then begin
          info.trackingh = 1
          widget_control,info.trackhMenu,set_button=1
          ;info.drawObject->hBarOn,all=all
          info.drawObject->hBarOn
        endif else begin
          info.trackingh = 0
          widget_control,info.trackhMenu,set_button=0
          info.drawObject->hBarOff
        endelse
        
        activeWindow=info.windowStorage->GetActive()
        if n_elements(activeWindow) gt 0 && $
          obj_valid(activeWindow[0]) then begin
          activeWindow[0]->SetProperty, Tracking=1
        endif
        
        ;whenever tracking is turned on a update/redraw needs to be done
        ;this is because the zoom may have been changed between tracking
        ;this leads to an incorrectly sized legend if not redrawn
        info.drawObject->Update,info.windowStorage,info.loadedData 
        info.drawObject->Draw 
        
        info.statusBar->Update, 'Vertical tracking turned on'
        
      ;going from vbarOn to vbarOff 
      endif else begin
        ;if vBarOff is selected, turn tracking settings off
        info.trackingv = 0
        widget_control,info.trackvMenu,set_button=0
        
        info.drawObject->vBarOff
        
        ;if legend && horizontal tracking are also off, then turn other tracking switches off
        resultL = widget_info(info.showPositionMenu,/button_set)
        resultH = widget_info(info.trackHMenu,/button_set)
        if ~resultL && ~resultH then begin
          info.tracking = 0
          info.legendOn = 0
          info.trackingh = 0
          widget_control,info.trackMenu,set_button=0
          widget_control,info.trackAllMenu,set_button=0
          widget_control,info.trackOneMenu,set_button=0
          widget_control,info.trackHMenu,set_button=0
          info.drawObject->legendOff
          info.drawObject->hBarOff
          activeWindow=info.windowStorage->GetActive()
          if n_elements(activeWindow) gt 0 && $
            obj_valid(activeWindow[0]) then begin
            activeWindow[0]->SetProperty, Tracking=0
          endif
        endif
              
        info.statusBar->Update, 'Vertical tracking turned off'
      
      endelse
      
    END
    
      ;Note on code related to various tracking switches
    ;Because events and clicks can be unreliable this code goes a little bit
    ;overboard in guaranteeing valid state and restoring state even when an
    ;invariant should guarantee state.
    ;Concretely, (1) It tries to check the widget values, rather than rely on the internal info.* flag
    ;            (2) It tries not to flip flags via newval = ~oldval logic, but instead sets value exactly, ie newval = 1 -or- newval = 0
    ;            (3) It resets the info.* flags whenever it can be certain of what a value should be
    ;In the long run we should try to eliminate the number of flags. So we can rely primarily on widget state 
   'TRACKH': BEGIN
        result = Widget_Info(event.id, /Button_Set)
      
      ;going from hbarOff to hbarOn
      if result eq 0 then begin
      
        ;if hBarOn is selected, turn tracking settings on
        info.trackingh = 1
        info.tracking = 1
        widget_control,info.trackhMenu,set_button=1
        widget_control,info.trackMenu,set_button=1
        
        ;this trackone/trackall section is identical to a case in the postion bar code
        if info.trackAll then begin
          info.trackOne = 0
          info.trackAll = 1
          widget_control,info.trackAllMenu,set_button=1
          widget_control,info.trackOneMenu,set_button=0
          
          all = 1
        endif else begin
          info.trackOne = 1
          info.trackAll = 0
          widget_control,info.trackAllMenu,set_button=0
          widget_control,info.trackOneMenu,set_button=1
          
          all = 0
        endelse
        
      ;  info.drawObject->hBarOn,all=all
        info.drawObject->hBarOn
        
        if info.legendOn then begin
          info.legendOn = 1
          widget_control,info.showPositionMenu,set_button=1
          info.drawObject->legendOn,all=all
        endif else begin
          info.legendOn = 0
          widget_control,info.showPositionMenu,set_button=0
          info.drawObject->legendOff
        endelse
        
        if info.trackingv then begin
          info.trackingv = 1
          widget_control,info.trackvMenu,set_button=1
          info.drawObject->vBarOn,all=all
        endif else begin
          info.trackingv = 0
          widget_control,info.trackvMenu,set_button=0
          info.drawObject->vBarOff
        endelse
        
        activeWindow=info.windowStorage->GetActive()
        if n_elements(activeWindow) gt 0 && $
          obj_valid(activeWindow[0]) then begin
          activeWindow[0]->SetProperty, Tracking=1
        endif
        
        ;whenever tracking is turned on a update/redraw needs to be done
        ;this is because the zoom may have been changed between tracking
        ;this leads to an incorrectly sized legend if not redrawn
        info.drawObject->Update,info.windowStorage,info.loadedData 
        info.drawObject->Draw 
        
        info.statusBar->Update, 'Vertical tracking turned on'
        
      ;going from hbarOn to hbarOff 
      endif else begin
        ;if hBarOff is selected, turn tracking settings off
        info.trackingh = 0
        widget_control,info.trackhMenu,set_button=0
        
        info.drawObject->hBarOff
        
        ;if legend && horizontal tracking are also off, then turn other tracking switches off
        resultL = widget_info(info.showPositionMenu,/button_set)
        resultV = widget_info(info.trackVMenu,/button_set)
        if ~resultL && ~resultV then begin
          info.tracking = 0
          info.legendOn = 0
          info.trackingv = 0
          widget_control,info.trackMenu,set_button=0
          widget_control,info.trackAllMenu,set_button=0
          widget_control,info.trackOneMenu,set_button=0
          widget_control,info.trackVMenu,set_button=0
          info.drawObject->legendOff
          info.drawObject->vBarOff
          activeWindow=info.windowStorage->GetActive()
          if n_elements(activeWindow) gt 0 && $
            obj_valid(activeWindow[0]) then begin
            activeWindow[0]->SetProperty, Tracking=0
          endif
        endif
              
        info.statusBar->Update, 'Horizontal tracking turned off'
      
      endelse
      
    END
    
    'RUBBERBANDX': BEGIN
      controlid = widget_info(event.top,find_by_uname='RUBBERBANDX')
      isset = widget_info(controlid,/button_set)
      widget_control,controlid,set_button=~isset
        ;no action required
    END
    
    'MARKER': BEGIN
      result = widget_info(event.id, /button_set)
      IF result EQ 0 THEN BEGIN
         Widget_Control, event.id, Set_Button=1
         info.markerTitleOn=1
      ENDIF ELSE BEGIN
         Widget_Control, event.id, Set_Button=0
         info.markerTitleOn=0
      ENDELSE
    END
    
    'PAGE': spd_ui_page_options, info

    'PANEL': spd_ui_panel_options, info.master, info.windowStorage, info.loadedData, info.historyWin, $
                                   info.drawObject,info.template_object, info.statusBar
                                   
    'LINE': spd_ui_line_options, info.master, info.windowStorage, info.loadedData, info.historyWin, $
                                   info.drawObject,info.template_object, info.statusBar
    
    'LEGEND': spd_ui_legend_options, info, tlb_statusbar=info.statusBar
    
    'LAYOUT': spd_ui_layout_options, info

    'XAXIS': spd_ui_axis_options, info.master, info.windowStorage, info.loadedData, $
                                  info.drawObject, info.historyWin, $
                                  'X Axis Options', 0, $  ;"0" for x.
                                   info.scrollbar,info.template_object, info.statusBar

    'YAXIS': spd_ui_axis_options, info.master, info.windowStorage, info.loadedData, $
                                  info.drawObject, info.historyWin,  $
                                  'Y Axis Options', 1, $  ;"1" for y.
                                  info.scrollbar,info.template_object, info.statusBar

    'ZAXIS': spd_ui_zaxis_options, info.master, info.windowStorage, info.zAxisSettings, info.drawObject, info.loadedData, info.historywin,info.template_object, info.statusBar

    'MARKERP': spd_ui_marker_options, info.master, info.historywin

    'VARIABLE': begin
      spd_ui_variable_options, info.master, info.loadeddata, info.windowstorage, info.drawobject, info.historywin,info.template_object,info.guiTree
    end
    

    'NUDGE': BEGIN
      info.windowStorage->getProperty,callSequence=callSequence
      spd_ui_nudge_options, info.master, info,callSequence
    END
    
    'CALCULATE': BEGIN
      info.windowStorage->getProperty,callSequence=callSequence
      spd_ui_calculate, info.master,info.loadedData,info.calcSettings, info.historywin,info.guiTree,callSequence, $
                        info.drawObject, info.windowStorage, info.scrollbar, info.statusBar
     END

    'DPROC': spd_ui_dproc_panel, info
      
    'ZOOM': BEGIN
    
      widget_control,info.zoom,get_value=zoomval
      
      if ~finite(zoomval,/nan) then begin
        if obj_isa(info.drawWin,'IDLgrWindow') then begin
          if ~event.valid && zoomval eq 200 then begin
            info.statusBar->Update,"Maximum zoom is 200%"
          endif else if ~event.valid && zoomval le 10 then begin ;increment value is 10 so zooms 10 or below won't decrease with down button
            info.statusBar->Update, "Minimum zoom is 1%"
          endif 
          if zoomval gt 200 then begin
            info.statusBar->Update,"Maximum zoom is 200%"
          endif else if zoomval lt 1 then begin
            info.statusBar->Update,"Minimum zoom is 1%"
          endif else begin
              info.drawobject->setzoom,double(zoomval)/100
              if event.valid then info.statusbar->update,"Zoom updated."
              if strlowcase(!version.os_family) eq 'windows' then begin
                ; This solves an issue where top of image disappears when zoom decreases
                info.scrollbar->getproperty, xsize=sb_xsize
                info.scrollbar->setproperty, xsize=sb_xsize
              endif
          endelse
        
        endif else begin
       
          zoomval = 100
          widget_control,info.zoom,set_value=zoomval
          
        endelse
      endif else info.statusbar->update,'Invalid Zoom value, please re-enter.'

    END

    'NEWWIN':BEGIN
       info.ctrl=0
       spd_ui_window, info
;       result=info.windowStorage->Add(Settings=info.pageSettings)
;       activeWindow=info.windowStorage->GetActive()
;       activeWindow[0]->GetProperty, Name=name
;       info.windowMenus->Add, name
;       info.windowMenus->Update, info.windowStorage
;       info.drawObject->update,info.windowStorage, info.loadedData
;       info.drawObject->draw
    END

; The following is for the various Pages
; created by SPD_UI_WINDOW_MENUS__DEFINE
    'WINBUTTON': BEGIN
      result = Widget_Info(event.id, /Button_Set)
      info.windowMenus->Clear
      IF result EQ 0 THEN Widget_Control, event.id, Set_Button=1 $
        ELSE Widget_Control, event.id, Set_Button=0
      ids=info.windowMenus->GetIds()
      names=info.windowMenus->GetNames()
      IF N_Elements(ids) EQ 1 THEN index=0 ELSE index = Where(ids EQ event.id)
      IF index GE 0 THEN BEGIN
        windowObjs=info.windowStorage->GetObjects()
        IF N_Elements(windowObjs) GT 0 THEN BEGIN
           FOR i=0,N_Elements(windowObjs)-1 DO BEGIN
              windowObjs[i]->GetProperty, Name=name, Id=id
              IF name EQ names[index] THEN BEGIN
                 IF result EQ 0 THEN begin
                   info.windowStorage->SetActive, Id=id
                   spd_ui_orientation_update,info.drawObject,info.windowStorage;, rezoom=rezoom

                   info.drawObject->Update,info.windowStorage, info.loadedData
                   info.drawObject->Draw    
                   info.scrollbar->update             
                 endif 
              ENDIF
           ENDFOR
        ENDIF
      ENDIF
	    Widget_Control, event.id, Set_Button=1

      ;re-apply zoom to keep some plots from being clipped on windows
;      if keyword_set(rezoom) then begin
;        cz = info.drawobject->getzoom()
;        info.drawobject->setzoom, cz
;      endif
    END 
    
    'HELP': BEGIN
      spd_ui_help_window, info.historyWin, info.master
;      help_arr = ["Please see User's Guide at: http://www.testme.edu/asdf;j/"]
;      result = dialog_message(help_arr, title = 'SPEDAS: GUI Help', /information)
    END
    
    'HELPFORM': spd_gui_error, info.master, info.historyWin
    'HELPABOUT': spd_ui_help_about, info.master, info.historyWin
    
    
    ;doesn't destroy object, leaves it to the garbage collector
    'RESET_PAGE_TEMPLATE':info.template_object->setProperty,page=obj_new()
    'RESET_LEGEND_TEMPLATE':info.template_object->setProperty,legend=obj_new()
    'RESET_PANEL_TEMPLATE': info.template_object->setProperty,panel=obj_new()
    'RESET_XAXIS_TEMPLATE': info.template_object->setProperty,x_axis=obj_new()
    'RESET_YAXIS_TEMPLATE': info.template_object->setProperty,y_axis=obj_new()
    'RESET_ZAXIS_TEMPLATE': info.template_object->setProperty,z_axis=obj_new()
    'RESET_LINE_TEMPLATE': info.template_object->setProperty,line=obj_new()
    'RESET_VARIABLE_TEMPLATE': info.template_object->setProperty,variable=obj_new()
 
    ; magnetic field models widget
    'FIELDMODELS': begin
        spd_ui_field_models, info
    end
      
    ; neutral sheet models widget
    'NEUTRALSHEETMODELS': begin
      spd_ui_neutral_sheet_models, info
    end
    
    ELSE: info.statusBar->Update, 'Feature Not Yet Implemented: ' + uservalue

  ENDCASE
 
  ;Update the GUI title.
  ;Having this here should catch all non-draw events that change the current 
  ;file or page number.  Draw events are caught separately. 
  spd_ui_update_title, info
 
  info.drawDisabled = 0
  
  Widget_Control, event.TOP, Set_UValue=info, /No_Copy
  if double(!version.release) lt 8.0 then heap_gc
  RETURN

END ;--------------------------------------------------------------------------------



PRO spd_gui,reset=reset,template_filename=template_filename

 ;Return if there is already a spd_gui widget running
  If(xregistered('spd_gui') Ne 0) Then Begin
    message, /info, 'You are already running spd_gui'
    Return
  Endif
  
  splash_widget = spd_ui_splash_widget()

  ;thm_init
  spedas_init
  spd_graphics_config
  ;spd_gui_init
  cdf_leap_second_init
  
  spd_ui_fix_performance, !spedas.linux_fix
  
  ;stop reporting of floating point errors(which will get annoying)
  !EXCEPT=0

  getresourcepath,rpath
  ;use spedas bitmap as toolbar icon for newer versions
  if double(!version.release) ge 6.4d then begin
    palettebmp = read_bmp(rpath + 'spedas_logo.bmp', /rgb)
    palettebmp = transpose(palettebmp, [1,2,0])
    _extra = {bitmap:palettebmp}
  endif
  
  ; load the plugin manager
  pluginManager = obj_new('spd_ui_plugin_manager')

  ; top level and main bases
  gui_title = 'Space Physics Environment Data Analysis Software (SPEDAS)'
  master = Widget_Base(Title=gui_title, MBar=bar, /TLB_Kill_Request_Events, $
                     /Col, XPad=10, /Kbrd_Focus_Events,tlb_size_events=1, _extra=_extra, TAB_MODE=1)
  toolBarBase = Widget_Base(master, /Row)
  scrollbase = widget_base(master, /row, xpad=0, ypad=0, space=0)
  pathBase = Widget_Base(master, /Col, /Align_Left)
  graphBase = Widget_Base(master, /Row)
  statusBase = Widget_Base(master, /Row)

  ; widgets

  ; File Pull Down Menu

  fileMenu= Widget_Button(bar, Value='File ', /Menu)
  ;documentMenu = widget_button(fileMenu,value='Document ',/menu)
;  newMenu = Widget_Button(fileMenu, Value='New SPEDAS Document...   ', UValue='NEW', $
;    Accelerator="Ctrl+N")
  openMenu = Widget_Button(fileMenu, Value='Open SPEDAS Document...  ', UValue='OPEN', $
    Accelerator="Ctrl+O")
  saveMenu = Widget_Button(fileMenu, Value='Save SPEDAS Document... ', UValue='SAVE', $
    Accelerator="Ctrl+S")
  saveAsMenu = Widget_Button(fileMenu, Value='Save SPEDAS Document As... ', UValue='SAVEAS')
;  saveWithMenu = Widget_Button(fileMenu, Value='Save With Data... ', UValue='SAVEWITH', $
;    Sensitive=0)
  templateMenu = Widget_Button(fileMenu, Value='Graph Options Template ',/menu)
  openTemplate = Widget_Button(templateMenu, Value='Open Template...  ', UValue='OPEN_TEMPLATE' )
  saveTemplate = Widget_Button(templateMenu, Value='Save Template... ', UValue='SAVE_TEMPLATE' )
  saveAsTemplate = Widget_Button(templateMenu, Value='Save Template As... ', UValue='SAVEAS_TEMPLATE')
  resetTemplateMenu =  Widget_Button(templateMenu, Value='Reset Template ',/menu)
  
  resetPageTemplate = Widget_Button(resetTemplateMenu, Value='Reset Page Template', UValue='RESET_PAGE_TEMPLATE')
  resetPanelTemplate = Widget_Button(resetTemplateMenu, Value='Reset Panel Template', UValue='RESET_PANEL_TEMPLATE')
  resetLegendTemplate = Widget_Button(resetTemplateMenu, Value='Reset Legend Template', UValue='RESET_LEGEND_TEMPLATE')
  resetXAxisTemplate = Widget_Button(resetTemplateMenu, Value='Reset X-Axis Template', UValue='RESET_XAXIS_TEMPLATE')
  resetYAxisTemplate = Widget_Button(resetTemplateMenu, Value='Reset Y-Axis Template', UValue='RESET_YAXIS_TEMPLATE')
  resetZAxisTemplate = Widget_Button(resetTemplateMenu, Value='Reset Z-Axis Template', UValue='RESET_ZAXIS_TEMPLATE')
  resetLineTemplate = Widget_Button(resetTemplateMenu, Value='Reset Line Template', UValue='RESET_LINE_TEMPLATE')
  resetVariableTemplate = Widget_Button(resetTemplateMenu, Value='Reset Variable Template', UValue='RESET_VARIABLE_TEMPLATE')
  
  ;resetPageTemplate = Widget_Button(templateMenu, Value='Reset Page Template', UValue='RESET_PAGE_TEMPLATE')
  ;resetPanelTemplate = Widget_Button(templateMenu, Value='Reset Panel Template', UValue='RESET_PANEL_TEMPLATE')
  ;resetXAxisTemplate = Widget_Button(templateMenu, Value='Reset X-Axis Template', UValue='RESET_XAXIS_TEMPLATE')
  ;resetYAxisTemplate = Widget_Button(templateMenu, Value='Reset Y-Axis Template', UValue='RESET_YAXIS_TEMPLATE')
  ;resetZAxisTemplate = Widget_Button(templateMenu, Value='Reset Z-Axis Template', UValue='RESET_ZAXIS_TEMPLATE')
  ;resetLineTemplate = Widget_Button(templateMenu, Value='Reset Line Template', UValue='RESET_LINE_TEMPLATE')
  ;resetVariableTemplate = Widget_Button(templateMenu, Value='Reset Variable Template', UValue='RESET_VARIABLE_TEMPLATE')
    
  loadMenu = Widget_Button(fileMenu, Value='Load Data ', UValue='LOAD', /Separator)
  loadHAPIMenu = Widget_Button(fileMenu, Value='Load Data using HAPI', UValue='LOADHAPI')
  loadCDAWebMenu = Widget_Button(fileMenu, Value='Load Data using CDAWeb', UValue='LOADCDAWEB')

  loadYourDataMenu = Widget_Button(fileMenu, Value='Load Your Data',/menu)
  loadCDFMenu = Widget_Button(loadYourDataMenu, Value='Load CDF', UValue='LOADCDF')
  loadAsciiMenu = Widget_Button(loadYourDataMenu, Value='Load ASCII', UValue='LOADASCII')

;  loadCDFMenu = Widget_Button(fileMenu, Value='Load CDF', UValue='LOADCDF')
;  loadAsciiMenu = Widget_Button(fileMenu, Value='Load ASCII', UValue='LOADASCII')

  saveDataAsMenu = Widget_Button(fileMenu, Value='Save Data As... ', UValue='SAVEDATAAS')
  importExportMenu = Widget_button(fileMenu, Value='Manage Data and Import/Export Tplot Variables...', UValue='MANAGEDATA')
  exportMetaMenu = Widget_Button(fileMenu, Value='Export To Image File... ', $
    UValue='EXPORTMETA', Sensitive=1, /Separator)
;  markerMenu = Widget_Button(fileMenu, Value='Markers ', UValue='MARKERS', /menu, $
;    Sensitive=0)
;  impMarkerMenu = Widget_Button(markerMenu, Value='Import Marker List... ', $
;    UValue='IMPORTM', Sensitive=0)
;  expMarkerMenu = Widget_Button(markerMenu, Value='Export Marker Data... ', $
;      UValue='EXPORTM',Sensitive=0)
;  expMarkerlMenu = Widget_Button(markerMenu, Value='Export Marker List... ', $
;    UValue='EXPORTML', Sensitive=0)
;  journalMenu = Widget_Button(fileMenu, Value='Journal ', UValue='JOURNAL', /Separator, /Checked_Menu)
;  Widget_Control, journalMenu, Set_Button=1
  printMenu = Widget_Button(fileMenu, Value='Print... ', UValue='PRINT', /Separator, $
    Accelerator="Ctrl+P")
;  previewMenu = Widget_Button(fileMenu, Value='Print Preview ', UValue='PREVIEW', $
;    Sensitive=0)
;  printmMenu = Widget_Button(fileMenu, Value='Print Multiple Files... ', uval='PRINTM', $
;    Sensitive=0)
  psetupMenu = Widget_Button(fileMenu, Value='Print Setup ', UValue='PSETUP')
  propertiesMenu = Widget_Button(fileMenu, Value='Configuration Settings... ', UValue='CONF', $
    /Separator)
;  prototypeMenu = Widget_Button(fileMenu, Value='Prototype ', UValue='PROT', /Menu, $
;    /Separator)
;  testButton = Widget_Button(prototypeMenu, Value='Test Widget', UValue='TEST',sensitive=0)
;  exmdButton = Widget_Button(prototypeMenu, Value='Example Data ', UValue='EXMD',sensitive=0)
  exitMenu = Widget_Button(fileMenu, value='Exit ',UValue='EXIT', /Separator, Accelerator="Ctrl+Q")

  ; Edit Pull Down Menu

  editMenu = Widget_Button(bar, Value='Edit ', /Menu)
;  undoMenu = Widget_Button(editMenu, Value='Undo  ', UValue='UNDO', Sensitive=0)
;  redoMenu = Widget_Button(editMenu, Value='Redo  ', UValue='REDO', Sensitive=0)
  copyMenu = Widget_Button(editMenu, Value='Copy  ', UValue='COPY', $
    Accelerator="Ctrl+C")
  deletemMenu = Widget_Button(editMenu, Value='Delete Marker ', UValue='DELETEM', $
    Sensitive=1)
  subSetMenu = Widget_Button(editMenu, Value= 'Subset ', /menu, /Separator)
  subPageMenu = Widget_Button(subSetMenu, Value='Page ', UValue='SUBPAGE')
  subMarkerMenu = Widget_Button(subSetMenu, Value='Marker (Single Panel) ', UValue='SUBMARKER', $
    Sensitive=1)
    
  subMarkerMenu = Widget_Button(subSetMenu, Value='Marker (All Panels) ', UValue='SUBMARKERMULTI', $
    Sensitive=1)

  ; View Pull Down Menu

  viewMenu=Widget_Button(bar, Value='View ', /Menu)
;  nextpMenu = Widget_Button(viewMenu, Value='Next Page ', UValue='NEXTP', Sensitive=0)
;  prevpMenu = Widget_Button(viewMenu, Value='Previous Page  ', UValue='PREVP', $
;    Sensitive=0)
;  nextsMenu = Widget_Button(viewMenu, Value='Page Up ', UValue='NEXTS', Sensitive=0)
;  prevsMenu = Widget_Button(viewMenu, Value='Page Down  ', UValue='PREVS', Sensitive=0)
;  layoutMenu = Widget_Button(viewMenu, Value='Layout ', UValue='LAYOUT', /Separator, $
;    /Menu)
;  up1Menu = Widget_Button(layoutMenu, Value='1 Up ', UValue='ONEUP')
;  up2Menu = Widget_Button(layoutMenu, Value='2 Up ', UValue='TWOUP')
;  up4Menu = Widget_Button(layoutMenu, Value='4 Up ', UValue='FOURUP')
;  refreshMenu = Widget_Button(viewMenu, Value='Refresh ', UValue='REFRESH', /Separator, $
;    Accelerator="Ctrl+R")
  refreshMenu = Widget_Button(viewMenu, Value='Refresh ', UValue='REFRESH', Accelerator="Ctrl+R")
;  jumpMenu = Widget_Button(viewMenu, Value='Jump ', UValue='JUMP', /Separator, $
;    Sensitive=0)
  scrollfMenu = Widget_Button(viewMenu, Value='Scroll Forward (Right)', UValue='SCROLLF', $
     /separator)
  scrollbMenu = Widget_Button(viewMenu, Value='Scroll Backward (Left)', UValue='SCROLLB')
  expandMenu = Widget_Button(viewMenu, Value='Expand (Tab)', UValue='EXPAND', $
    /Separator)
  reduceMenu = Widget_Button(viewMenu, Value='Reduce (Backspace)', UValue='REDUCE')
  historyMenu = Widget_Button(viewMenu, Value='History Window', /Checked_Menu, $
    UValue='HISTORYW', /Separator)
;  showPathMenu = Widget_Button(viewMenu, Value='Path Bar', /Checked_Menu, UValue='PATHBAR')
;  Widget_Control, showPathMenu, Set_Button=1
  showPositionMenu = Widget_Button(viewMenu, Value='Legend', /Checked_Menu, $
    UValue='POSITIONBAR')
  Widget_Control, showPositionMenu, Set_Button=1

  ; Graph Pull Down Menus

  graphMenu = Widget_Button(bar, Value='Graph ', /Menu)
  trackMenu = Widget_Button(graphMenu, Value='Panel Tracking', /Checked_Menu, $
    UValue='TRACK')
  trackOneMenu = Widget_Button(graphMenu, Value='Track One Panel', /Checked_Menu, $
    UValue='TRACKONE')
  trackAllMenu = Widget_Button(graphMenu, Value='Track All', /Checked_Menu, $
    UValue='TRACKALL')
  Widget_Control, trackMenu, Set_Button=1
  Widget_Control, trackallMenu, Set_Button=1
  trackHMenu = Widget_Button(graphMenu, Value='Show Horizontal Tracking', $
    /Checked_Menu, UValue='TRACKH', /Separator)
  widget_control,trackHMenu,set_button=1
  trackVMenu = Widget_Button(graphMenu, Value='Show Vertical Tracking', $
    /Checked_Menu, UValue='TRACKV')
  Widget_Control, trackVMenu, Set_Button=1
;  trackAddMenu = Widget_Button(graphMenu, Value='Track Additional Variables', $
;    /Checked_Menu, UValue='TRACKADD', Sensitive=0)
  rubberBandX = Widget_button(graphMenu, value='Rubber Band for X-Only',/checked_menu,uname='RUBBERBANDX',uvalue='RUBBERBANDX')  
  Widget_Control, rubberBandX, Set_Button=1
   
;  panelFPMenu = Widget_Button(graphMenu, Value='Panel Format Painter', $
;    UValue='PANELFP', /Separator, Sensitive=0)
  markerTitleMenu = Widget_Button(graphMenu, Value='Query for Marker Title', /checked_menu, $
    Uvalue='MARKER', /separator)
  Widget_Control, markerTitleMenu, set_button=1
  layoutOptMenu = Widget_Button(graphMenu, Value='Plot/Layout Options... ', UValue='LAYOUT', /separator)
  pageMenu = Widget_Button(graphMenu, Value='Page Options... ', UValue='PAGE')
  panelMenu = Widget_Button(graphMenu, Value='Panel Options... ', UValue='PANEL')
  lineMenu = Widget_Button(graphMenu, Value='Line Options... ', UValue='LINE')
  legendMenu = Widget_Button(graphMenu, Value='Legend Options...', UValue='LEGEND')
  xaxisMenu = Widget_Button(graphMenu, Value='X Axis Options... ', UValue='XAXIS')
  yaxisMenu = Widget_Button(graphMenu, Value='Y Axis Options... ', UValue='YAXIS')
  zaxisMenu = Widget_Button(graphMenu, Value='Z Axis Options... ', UValue='ZAXIS')
;  markerPMenu = Widget_Button(graphMenu, Value='Marker Options... ', UValue='MARKERP')
  variableMenu = Widget_Button(graphMenu, Value='Variable Options... ', $
    UValue='VARIABLE')

  ; Analysis Pull Down Menus

  analysisMenu=Widget_Button(bar, Value='Analysis ', /Menu)
  calculateMenu = Widget_Button(analysisMenu, Value='Calculate... ', UValue='CALCULATE')
  nudgeMenu = Widget_Button(analysisMenu, Value='Nudge Traces ', UValue='NUDGE')
  dprocMenu = Widget_Button(analysisMenu, Value = 'Data Processing... ', UValue = 'DPROC', $
                            sensitive = 1)
  tsyMenu = widget_button(analysisMenu, value='Magnetic Field Models...', uval='FIELDMODELS')
  tsyMenu = widget_button(analysisMenu, value='Neutral Sheet Models...', uval='NEUTRALSHEETMODELS')
  
  ; Tools Pull Down Menu (general plugins)
  
  toolsMenu = widget_button(bar, value='Tools ', /menu)
  
  tools_menu_items = pluginManager->getPluginMenus()
 
  spd_ui_plugin_menu, toolsMenu, tools_menu_items
  
; Window Pull Down Menu window

  windowMenu = Widget_Button(bar, Value='Pages ', /Menu, UValue=0)
  newWinMenu = Widget_Button(windowMenu, Value='New ', UValue='NEWWIN',Accelerator="Ctrl+N")
  closeWinMenu = Widget_Button(windowMenu, Value='Close ', UValue='CLOSE', Accelerator="Ctrl+Z")

  ; Help Pull Down Menu

  helpMenu = Widget_Button(bar, Value='Help ', /Menu)
  helpButton = Widget_Button(helpMenu, Value='Help Window...', uValue='HELP')
  helpRequestButton = Widget_Button(helpMenu, Value='Help Request Form...', uValue='HELPFORM')
  helpAboutButton = Widget_Button(helpMenu, Value='About...', uValue='HELPABOUT') ;nikos: new button
  
  ; Start of Toolbar Buttons

  ; First get the bitmap full path name
  
 ; getresourcepath,rpath
  openBMP = read_bmp(rpath + 'folder_horizontal_open.bmp',/rgb)
  saveBMP = read_bmp(rpath + 'disk.bmp',/rgb)
  printBMP = read_bmp(rpath + 'printer.bmp',/rgb)
  copyBMP = read_bmp(rpath + 'copy.bmp',/rgb)
;  undoBMP = read_bmp(rpath + 'arrow_turn_180_left.bmp',/rgb)
;  redoBMP = read_bmp(rpath + 'arrow_turn.bmp',/rgb)
  zoomInBMP = read_bmp(rpath + 'double_arrows_in.bmp',/rgb)
  zoomOutBMP = read_bmp(rpath + 'double_arrows_out.bmp',/rgb)
;  zoomInBMP = rpath + 'magnifier_zoom.bmp'
;  zoomOutBMP = rpath + 'magnifier_zoom_out.bmp'
  plotBMP = read_bmp(rpath + 'np_icon.bmp',/rgb)
  shiftRBMP = read_bmp(rpath + 'control_180.bmp',/rgb)
  shiftLBMP = read_bmp(rpath + 'control.bmp',/rgb)
 ; plusBMP = read_bmp(rpath + 'plus.bmp',/rgb)
 ; minusBMP = read_bmp(rpath + 'minus.bmp',/rgb)
  windowBMP = read_bmp(rpath + 'new_page.bmp',/rgb)
  helpBMP = read_bmp(rpath + 'question.bmp',/rgb)
  manageBMP = read_bmp(rpath + 'wrench_screwdriver.bmp',/rgb)
  loadBMP = read_bmp(rpath + 'folder_open_image.bmp',/rgb)

  spd_ui_match_background, master, openBMP
  spd_ui_match_background, master, saveBMP
  spd_ui_match_background, master, printBMP
  spd_ui_match_background, master, copyBMP
;  spd_ui_match_background, master, undoBMP
;  spd_ui_match_background, master, redoBMP
  spd_ui_match_background, master, zoomInBMP
  spd_ui_match_background, master, zoomOutBMP
  spd_ui_match_background, master, plotBMP
  spd_ui_match_background, master, shiftRBMP
  spd_ui_match_background, master, shiftLBMP
;  spd_ui_match_background, master, plusBMP
;  spd_ui_match_background, master, minusBMP
  spd_ui_match_background, master, windowBMP
  spd_ui_match_background, master, helpBMP
  spd_ui_match_background, master, manageBMP
  spd_ui_match_background, master, loadBMP

;  openBMP = FilePath('open.bmp', SubDir=['resource', 'bitmaps'])
;  saveBMP = FilePath('save.bmp', SubDir=['resource', 'bitmaps'])
;  printBMP = FilePath('print1.bmp', SubDir=['resource', 'bitmaps'])
;  copyBMP = FilePath('copy.bmp', SubDir=['resource', 'bitmaps'])
;  undoBMP = FilePath('undo.bmp', SubDir=['resource', 'bitmaps'])
;  redoBMP = FilePath('redo.bmp', SubDir=['resource', 'bitmaps'])
;  zoomInBMP = FilePath('zoom_in.bmp', SubDir=['resource', 'bitmaps'])
;  zoomOutBMP = FilePath('zoom_out.bmp', SubDir=['resource', 'bitmaps'])
;  windowBMP = FilePath('view.bmp', SubDir=['resource', 'bitmaps'])
;  shiftRBMP = FilePath('shift_left.bmp', SubDir=['resource', 'bitmaps'])
;  shiftLBMP = FilePath('shift_right.bmp', SubDir=['resource', 'bitmaps'])
;  plusBMP = FilePath('plus.bmp', SubDir=['resource', 'bitmaps'])
;  minusBMP = FilePath('minus.bmp', SubDir=['resource', 'bitmaps'])
;  helpBMP = FilePath('help.bmp', SubDir=['resource', 'bitmaps'])
;  plotBMP = FilePath('plot.bmp', SubDir=['resource', 'bitmaps'])

  ; Toolbar bases to help cluster icons by type (annoying IDL thing)

  fileToolBase = Widget_Base(toolBarBase, /Row, XPad=2)
;  printToolBase = Widget_Base(toolBarBase, /Row, XPad=2)
  editToolBase = Widget_Base(toolBarBase, /Row, XPad=2)
  moveToolBase = Widget_Base(toolBarBase, /Row, XPad=2)
  shiftToolBase = Widget_base(toolBarBase, /Row, Xpad=2)
  dataToolBase = Widget_base(toolBarBase, /Row, Xpad=2)
  plotToolBase = Widget_Base(toolBarBase, /Row, XPad=2)
  helpToolBase = Widget_Base(toolBarBase, /Row, XPad=2)
  zoomBase = Widget_Base(toolBarBase, /Row, XPad=2)
  ; Toolbar icon buttons

  openBmpButton = Widget_Button(fileToolBase, Value=openbmp, /Bitmap, UValue='OPEN', $
    ToolTip='Open File')
  saveBmpButton = Widget_Button(fileToolBase, Value=savebmp, /Bitmap, UValue='SAVE', $
    ToolTip='Save File')
  printBmpButton = Widget_Button(fileToolBase, Value=printbmp, /Bitmap, $
    ToolTip='Print', UValue='PRINT')
;  undoBmpButton = Widget_Button(editToolBase, Value=undobmp, /Bitmap, ToolTip='Undo', $
;    Sensitive=0, UValue='UNDO')
;  redoBmpButton = Widget_Button(editToolBase, Value=redobmp, /Bitmap, ToolTip='Redo', $
;    Sensitive=0, UValue='REDO')
  copyBmpButton = Widget_Button(editToolBase, Value=copybmp, /Bitmap, ToolTip='Copy to clipboard', $
    UValue='COPY')
  zoomInBmpButton = Widget_Button(moveToolBase, Value=zoominbmp, /Bitmap,  $
    ToolTip='Reduces X range by major tick mark', UValue='REDUCE')
  zoomOutBmpButton = Widget_Button(moveToolBase, Value=zoomoutbmp, /Bitmap, $
    ToolTip='Expands X range by major tick mark', UValue='EXPAND')
  shiftLBmpButton = Widget_Button(moveToolBase, Value=shiftrbmp, /Bitmap, $
    ToolTip='Shift Left by major tick mark', UValue='SCROLLB')
  shiftRBmpButton = Widget_Button(moveToolBase, Value=shiftlbmp, /Bitmap, $
    ToolTip='Shift Right by major tick mark', UValue='SCROLLF')
  plotBmpButton = Widget_Button(plotToolBase, Value=plotbmp, /Bitmap, $
    ToolTip='Plot data', UValue='LAYOUT')
  windowBmpButton = Widget_Button(plotToolBase, Value=windowbmp, /Bitmap, $
    ToolTip='Create New Page', UValue='NEWWIN')
  helpBmpButton = Widget_Button(helpToolBase, Value=helpbmp, /Bitmap, ToolTip='Help', $
    UValue='HELP')
  loadBmpButton = Widget_Button(dataToolBase, Value=loadBMP, /Bitmap, ToolTip='Load Data', $
    UValue='LOAD')
  manageBmpButton = Widget_Button(dataToolBase, Value=manageBMP, /Bitmap, ToolTip='Manage GUI Data and Import and Export Tplot data', $
    UValue='MANAGEDATA')
  ; Note: 'disable_all_events' causes the zoom spinner widget to only update when a) up/down is pressed or b) enter is pressed
  zoomSpinner = spd_ui_spinner(zoomBase, Increment=10, Value=100, uval='ZOOM',UNITS='%', min_value=1, max_value=200, /disable_all_events)

  ; Get screen size so that we can set the bar and draw areas the right size

  dev = !d.name
  plot_var = !P
  ;In case some other device is set, switch to screen, then reset when done with screen size query.
  if strlowcase(!version.os_family) eq 'windows' then begin
    set_plot,'WIN'
  endif else begin
    set_plot,'X'
  endelse
  

  ;get device dimensions (with margin) 
  Device, get_screen_size=gss
  x_scr_size=gss[0]-gss[0]*.25
  y_scr_size=gss[1]-gss[1]*.35

  ;get default page dimensions
  defaultxsize = !D.X_PX_CM * 2.54 * 8.5
  defaultysize = !D.Y_PX_CM * 2.54 * 11
  xsize = defaultxsize
  ysize = defaultysize
  
  defsysv,'!spedas',exists=spd_exists

  ;these blocks determine whether to reload old state from memory
  ;or to restart with new settings
  if spd_exists && in_set(strlowcase(tag_names(!spedas)),'loadeddata') && obj_valid(!spedas.loadeddata) then begin
    if keyword_set(reset) then begin
      obj_destroy,!spedas.loadedData
      loadedData = Obj_New('SPD_UI_LOADED_DATA')
    endif else begin
      loadedData = !spedas.loadedData
    endelse
  endif else begin
    loadedData = Obj_New('SPD_UI_LOADED_DATA')
  endelse
  
  template_file = ''
  
  ;read template from file, if requested or read template if stored in !spedas.templatepath (obtained from config file) - give priority to keyword if passed in
  if keyword_set(template_filename) then begin
    open_spedas_template,template=template,filename=template_filename,$
        statusmsg=statusmsg,statuscode=statuscode
    if statuscode lt 0 then begin
      ok = dialog_message(statusmsg,/error,/center)
      template=obj_new()
    endif else begin
      template_file = template_filename
    endelse
  endif else if spd_exists && in_set(strlowcase(tag_names(!spedas)),'templatepath') && (size(!spedas.templatepath,/type) eq 7) then begin
    if !spedas.templatepath ne '' then begin
      open_spedas_template,template=template,filename=!spedas.templatepath,$
        statusmsg=statusmsg,statuscode=statuscode
      if statuscode lt 0 then begin
        ok = dialog_message(statusmsg,/error,/center)
        template=obj_new()
      endif else begin
        template_file = !spedas.templatepath
      endelse
    endif
  endif
  
  if spd_exists && in_set(strlowcase(tag_names(!spedas)),'windowstorage') && obj_valid(!spedas.windowstorage) then begin
    if keyword_set(reset) then begin
      obj_destroy,!spedas.windowStorage
      windowStorage = obj_new('spd_ui_windows',loadedData)
    endif else begin
      windowStorage = !spedas.windowStorage
    endelse
  endif else begin
    windowStorage = obj_new('spd_ui_windows',loadedData)
  endelse
  
  ;store template that was loaded via template_filename keyword
  if obj_valid(template) then begin
    windowStorage->setProperty,template=template
  endif
  
  ;whether loaded or not, make sure an accurate copy is available
  windowStorage->getProperty,template=template
  
  ;get dimensions of current page if one exists
  current_window = windowstorage->getactive()
  if obj_valid(current_window) then begin
    current_window->getproperty, settings=cwsettings
    if obj_valid(cwsettings) then begin
      cwsettings->GetProperty,canvassize=canvassize
      xsize=canvasSize[0]*2.54*!D.X_PX_CM
      ysize=canvasSize[1]*2.54*!D.Y_PX_CM
    endif
  endif
  
  ;ensure that the page size does not cause the gui go off screen 
  ; lphilpott feb-16-2012: Setting gui to always be default size as if page size is small it doesn't look good
  ; Could set to be page size if page size > defaultxsize but <x_scr_size if users prefer
  x_scr_size = min([defaultxSize,x_scr_size])
  
  
  charSize = ceil(x_scr_size/!d.x_ch_size)
  
  ; Create Path Bar, but don't show for now (it is not used in Phase I or II)
 ; pathBar = Obj_New('SPD_UI_MESSAGE_BAR', pathBase, XSize=charSize, YSize=2, Value='Path Name')
 ; pathBar->Delete
    
  ; Draw Area
  ;NOTE any changes in the following call to widget draw should be mirrored by changes
  ;in the call to WIDGET_DRAW in spd_ui_fileconfig that occurs when changing rendering
  ;mode

  if !spedas.renderer eq 0 && strlowcase(!VERSION.os_family) eq 'windows' then begin
    retain = 2
  endif else begin
    retain = 1
  endelse
  
  ; toolbargeom gets the size of the toolbar across the top of the gui. This helps when resizing.
  ; This call to widget_info is placed here because on X11 the widget_draw changes both the toolbargeom xsize
  ; and x_scr_size rather than just the x_scr_size (as on windows). 
  toolbarGeom = Widget_Info(toolbarbase, /Geometry)
  drawID = WIDGET_DRAW(graphBase,/scroll,xsize=xsize,ysize=ysize,x_scroll_size=x_scr_size,y_scroll_size=y_scr_size,Frame=3, Motion_Event=1, $
    /Button_Event,keyboard_events=2,graphics_level=2,renderer=!spedas.renderer,retain=retain,/expose_events,/tracking_events,/viewport_events)

 ; Create Context Menu (Right Click)

  drawContextBase = Widget_Base(drawID, /Context_Menu)
  contextPanelButton = Widget_Button(drawContextBase, Value='Panel Options...', $
    UValue='PANEL')
  contextLayoutButton = Widget_Button(drawContextBase, Value='Layout Options...', $
    UValue='LAYOUT')
  contextLegendButton = Widget_Button(drawContextBase, Value='Legend Options...', $
    UVAlue='LEGEND')
;  contextMarkerButton = Widget_Button(drawContextBase, Value='Marker Options...', $
;    UValue='MARKERP')
  contextNudgeButton = Widget_Button(drawContextBase, Value='Nudge Traces', $
    UValue='NUDGE')
  contextSubSetButton = Widget_Button(drawContextBase, Value='Subset', UValue='SUBSET', $
    /Menu, /Separator)
  contextSubPageButton = Widget_Button(contextSubSetButton, Value='Page', UValue='SUBPAGE')
  contextSubMarkButton = Widget_Button(contextSubSetButton, Value='Marker', UValue='SUBMARKER')
  contextCalculateButton = Widget_Button(drawContextBase, Value='Calculate...', UValue='CALCULATE',/Separator)
  contextDprocButton = Widget_Button(drawContextBase, Value='Data Processing...', UValue='DPROC')  

  ; Create Status Bar Object

  statusBar = Obj_New('SPD_UI_MESSAGE_BAR', statusBase, XSize=charSize, YSize=1)

  ; And FINALLY Create the Position Area

  positionBase = Widget_Base(graphBase, /Col, ypad=5)

  ; DONE Creating widgets!!!

  ; Create objects or templates (that haven't already been initialized)
  
  loadtr = Obj_New('SPD_UI_TIME_RANGE', starttime=0d)
  historyWin = Obj_New('SPD_UI_HISTORY', historyMenu, master)
  pageSettings = Obj_New('SPD_UI_PAGE_SETTINGS',backgroundcolor=[255,255,255])
  markerSettings = Obj_New('SPD_UI_MARKER_SETTINGS')
  panelSettings = Obj_New('SPD_UI_PANEL_SETTINGS')
  lineSettings = Obj_New('SPD_UI_LINE_SETTINGS')
  spectraSettings = Obj_New('SPD_UI_SPECTRA_SETTINGS')
  xAxisSettings = Obj_New('SPD_UI_AXIS_SETTINGS')
  yAxisSettings = Obj_New('SPD_UI_AXIS_SETTINGS')
  zAxisSettings = Obj_New('SPD_UI_ZAXIS_SETTINGS')
  fieldModelSettings = obj_new('SPD_UI_FIELDMODELS_SETTINGS')
  neutralSheetSettings = obj_new('SPD_UI_NEUTRALSHEET_SETTINGS')

  ; Make sure that the device and color table are always loaded and the same
 ; Device, decomposed=0
 ; LoadCT, 39
 ; gray=GetColor('Dark Gray', !d.table_size-2)
 ; red=GetColor('red', !d.table_size-3)
  
;  ;Turn journaling on
;   if ~!journal then Journal,'spd_ui_idlsave.pro'
  
  markerButtons = [subMarkerMenu, deletemMenu]
  panelButtons = [xaxisMenu, yaxisMenu, variableMenu]

  
  ; Main information structure for SPEDAS GUI
  ; NOTE TO PROGRAMMERS:
  ; All the elements of this structure should be commented.
  ; If you notice something that isn't commented and 
  ; you know its purpose, please add a comment
  ; Ideally, we should also remove the obsolete members
  info = {master:master,$ ;The ID of the top widget base for the entire GUI
          gui_title:gui_title, $   ;Base title to be displayed
          tracking:0,$
          marking:0, $
          markerFail:0, $ ;indicates whether a failure message has been sent to the user so that duplicate messages are not generated  
          markers:[0.0, 0.0], $
          drawID:drawID, $ ;widget ID of the draw window
          draw_select:1, $
          drawWin:OBJ_NEW(), $  ;draw window object
          prevEvent:'NODATA', $
          screenSize:[x_scr_size,y_scr_size], $
          drawDisabled:0,$
          drawDisableTimer:0D,$
          data:0, $
          nWindows:0,$
          mainFileName:'', $
          lastClick: [0d,0], $
          prevEventType:-1, $
          statusBar:statusBar, $ ;the status message bar for the main window
         ; pathBar:pathBar, $ ; not implemented? commented out 3/5/15
          trackingv:0, $ ;indicates whether vertical tracking is on
          trackingh:0, $ ;indicates whether horizontal tracking is on
          trackvMenu:trackvMenu, $  ;widget id of vertical tracking menu item
          trackhMenu:trackhMenu,  $ ;widget id of horizontal tracking menu item
          markerButtons:markerButtons, $
          trackMenu:trackMenu, $
          prevEventX:0, $
          drawingBox:0, $
          windowMenu:windowMenu, $
          viewPort:0, $
          examButton:0, $
          pageSettings:pageSettings, $
          lineSettings:lineSettings, $
          xAxisSettings:xAxisSettings, $
          legendOn:0,$
          cursorPosition:[0.0, 0.0], $
          yAxisSettings:yAxisSettings, $
          drawContextBase:drawContextBase, $
          graphBase:graphBase,$
          showPositionMenu:showPositionMenu, $
          historyWin:historyWin, $  ; The history window object
          loadedData:obj_new(), $ ; The loaded data object, manages all loaded quantities
          loadtr:loadtr, $ 
          drawObject:OBJ_NEW(), $ ;The draw object, maintains window state
          windowStorage:obj_new(), $ ;Stores state of various pages, this is the top level of the plot representation hierarchy
          printObj:OBJ_NEW(), $ ;IDLgrPrint object stores print settings
          rubberBandTimer:0D, $
          spectraSettings:spectraSettings, $
          windowMenus:obj_new(), $
          panelButtons:panelButtons, $
          zAxisSettings:zAxisSettings, $
          trackOneMenu:trackOneMenu, $ ;Widget ID of the menu item that allows single panel tracking
          trackAllMenu:trackAllMenu, $ ;Widget ID of the menu item that allows multi panel tracking
          markerSettings:markerSettings, $
          resizetime:0D, $ ;Time of last resize, used to prevent flicker during resize
          interface_size:[0.0,0.0], $ ; Estimated size of the interface used for resizing calculations
          markerTitleOn:1, $
          rubberBanding:0, $
          trackAll:1, $
          trackOne:0,$
          calcSettings:obj_new('spd_ui_calculate_settings'),$ ;Settings for the calculate panel, ensures that the same code that was in the calculate buffer when you last used it, is still present
          zoom:zoomSpinner,$
          dimRatio:[1D,1D],$
          ctrl:0,$
          click:0,$
          rubberBandBox:[0.0, 0.0, 0.0, 0.0],$
          imageOptions:ptr_new(), $
          oplot_calls:!spedas.oplot_calls,$
          contextMenuOn:0,$
          guiTree:ptr_new(0l), $ ;Stores a copy of the widget tree, so that each panel can be expanded to the same place as the last one when opened
          scrollbar:obj_new(), $
          printWarning:0B, $ ;indicates whether a popup warning has already been issued for non-windows printing during this session
          template_object:template, $ ; stores a template object, which contains default settings for common displayable objects
          template_filename:template_file, $ ;stores the name of a file in which a template can be stored
          dataLoadSelectPtr:ptr_new(), $ ; stores users selections from the load data window so that they don't have to re-click every time they open the window.
          saveDataDirPtr:ptr_new(''),$; stores path to last directory data was save to so user doesn't have to renavigate 
          fieldModelSettings:fieldModelSettings, $ ; used to keep track of field model inputs
          neutralSheetSettings:neutralSheetSettings, $ ; used to keep track of neutral sheet model inputs
          pluginManager: pluginManager, $ ; the plugin manager
          toolbar_ysize:0,$; store the size of the toolbar along top of gui
          toolbar_xsize:0 $; store the x size of the toolbar along top of gui
          } 
          
  info.tracking = 1
  info.trackingv = 1
  info.trackingh = 1
  info.legendon = 1
  
  ; Find out how much space is required for the toolbar (to prevent resizing smaller than space needed for buttons)

  ;toolbarGeom = Widget_Info(toolbarbase, /Geometry)
  info.toolbar_ysize = toolbarGeom.ysize
  info.toolbar_xsize = toolbarGeom.xsize

    ;All the initial set up is done, display the widgets

  Widget_Control, master, Set_UValue=info, /No_Copy
  Widget_Control, master, /Realize
  
  ;get a pointer to the graphics window

  Widget_Control, master, Get_UValue=info, /No_Copy
  
  info.loadedData=loadedData
  
  Widget_Control, drawID, Get_Value=drawWin 
  info.drawWin = drawWin
  
  if spd_exists && in_set(strlowcase(tag_names(!spedas)),'drawobject') && obj_valid(!spedas.drawObject) then begin
    if keyword_set(reset) then begin
      obj_destroy,!spedas.drawObject
      drawObj = OBJ_NEW('spd_ui_draw_object',drawWin,statusbar,historyWin)
    endif else begin
      drawObj = !spedas.drawObject
      drawObj->setProperty,historyWin=historyWin,destination=drawWin,statusBar=statusBar
    endelse
  endif else begin
    drawObj = OBJ_NEW('spd_ui_draw_object',drawWin,statusbar,historyWin)
  endelse

  windowObjects = windowStorage->getObjects()
  
  ;add an initial window, if none is currently present
  if ~obj_valid(windowObjects[0]) then begin
    if ~windowStorage->add(settings=pageSettings, isactive=1) then begin
      out = error_message('Error initializing default window',/traceback, /center, title='Error in GUI')
      widget_control,master,/destroy
      return
    endif
  endif

  ;add scroll bar at the to of the draw window
  scrollbar = obj_new('SPD_UI_SCROLL_BAR', scrollbase, x_scr_size, $
                      windowStorage, loadedData, drawObj, statusbar, $
                      value=500, range=[0,1000])

  
  ;create the window menus object and synchronize it with the window storage object
  windowMenus = Obj_New("SPD_UI_WINDOW_MENUS", windowMenu)
;  windowStorage->reloadWindowMenus,windowMenus
;  windowMenus->Update, windowStorage
  windowMenus->sync, windowstorage
  
  drawWin->setProperty,units=1
  drawWin->getProperty,dimensions=dim
  drawWin->setProperty,units=0
  ;drawWin->setCurrentCursor,'ARROW'
  
  
  ;The draw area dimensions that match closely to particular
  ;dimensions on the screen aren't the dimensions that IDL
  ;considers to have that measurement.  For example, if the
  ;draw area measures ~8.5x11 inches on the screen, IDL will
  ;list the size to be 11.5x14.9 on my computer.  Different
  ;computers should have different measurements, ratios
  ;of IDL measurements to true measurements.  By recording this
  ;ratio, we can guarantee near accurate screen sizing, while
  ;also maintaining absolutely accurate output sizing.
  
  ;ratio of output inches to screen inches
  info.dimRatio = [xsize / 2.54*!D.X_PX_CM, $
                   ysize / 2.54*!D.X_PX_CM   ] / dim  
  
  master_geo = widget_info(master,/geometry)
  draw_geo = widget_info(drawid,/geometry)
  
  ;measuring the interface size needed to calculate resize.  Differences in OS apply.
  if strlowcase(!version.os_family) eq 'windows' then begin
    interface_size = [master_geo.xsize-draw_geo.xsize,master_geo.ysize-draw_geo.ysize]
  endif else begin
    interface_size = [master_geo.scr_xsize-draw_geo.xsize,master_geo.scr_ysize-draw_geo.ysize]
  endelse
  
  info.interface_size=interface_size

  ;replace the cursor on non-windows system
  ;The cursor also needs to be reset when a new window is created.
  ;ATM This only happens here  & when switching between hardware & software render modes.
  if strlowcase(!version.os_family) ne 'windows' then begin
    spd_ui_set_cursor,drawWin
  endif

  drawObj->update,windowStorage,info.loadedData
  drawObj->draw
  drawObj->vBarOn, /All
 ; drawObj->hBarOn, /All
  drawObj->hBarOn
  drawObj->legendOn, /All
  scrollbar->update

  info.drawObject = drawObj
  info.windowStorage=windowStorage
  info.windowMenus=windowMenus
  info.scrollbar=scrollbar

  ;Initialize the title.
  spd_ui_update_title, info
  
  ;store relevant variables inside system variable, so that we 
  ;can integrate command line and gui
  !spedas.drawObject = drawObj
  !spedas.windowStorage = windowStorage
  !spedas.loadedData = loadedData
  !spedas.windowmenus = windowmenus
  !spedas.historyWin = historyWin
  !spedas.guiId = master
  
  Widget_Control, master, set_UValue=info, /No_Copy
  
  ;reset the direct graphics plot device to whatever it was before the gui was started
  set_plot,dev
  !P=plot_var
  
  ; close the splash screen
  widget_control, splash_widget, /destroy
  
  XManager, 'spd_gui', master, /No_Block
  if double(!version.release) lt 8.0 then heap_gc
  

RETURN

END ;--------------------------------------------------------------------------------

