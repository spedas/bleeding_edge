;+ 
;NAME:  
; spd_ui_draw_event
;
;PURPOSE:
; This routine handles all events that occur in the draw window
;
;CALLING SEQUENCE:
; info=spd_ui_draw_event(event, info)
;
;INPUT:
; event - the structure from the draw window event
; info - the main information structure from splash_gui
;
;OUTPUT:
; info - the updated main information structure
; 
;HISTORY:
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/spd_ui_draw_event.pro $
;-

FUNCTION spd_ui_draw_event, event, info

      ; Catch errors here
      
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=1)
      RETURN, info
   ENDIF
   
   ;to desensitize to erroneous events that occur during panels
   if info.drawDisabled then return,info
   
   ;to desensitize to erroneous events that occur after panels
   if systime(/seconds) - info.drawDisableTimer lt .5 then return,info
 
   if info.draw_select eq 1 then begin
     widget_control,info.drawId,/input_focus
   endif

    ; fixing issue with the click flag getting stuck if the user
    ; clicks inside the draw object and drags the cursor outside
    if (info.click eq 1 && info.ctrl eq 0) then info.click = 0

    ; Convert cursor location from device to normalized values
    info.drawWin->GetProperty, Dimensions=windowDimensions
    info.cursorPosition = [event.x/windowDimensions[0], event.y/windowDimensions[1]]
            
    if event.type eq 0 && event.clicks gt 0 && event.press eq 1 then begin
      info.click = 1
      info.historyWin->update,'Click On'
    endif
      
    if event.type eq 1 && event.release eq 1 then begin
      info.click = 0
      info.historyWin->update,'Click Off'
      info.contextMenuOn = 0
    endif
    
    if info.contextMenuOn then return,info
        
    IF Size(event.release, /Type) ne 0 && event.release EQ 4 THEN BEGIN
   ;   Print, 'Right Click - display context menu'
      
      ;Reset tracking and return if the user is rubberbanding or creating a marker 
      if info.marking ne 0 or info.rubberbanding ne 0 then begin
        spd_ui_reset_tracking, info
        RETURN, info
      endif
      
      Widget_DisplayContextMenu, info.drawID, event.x, event.y, info.drawContextBase
      info.contextMenuOn = 1
      info.prevEvent='RIGHTCLICK'
      info.marking=0
      RETURN, info
    ENDIF

    ;help,event,/str
       
    ;turn marking on
    IF event.ch NE 0 OR event.key NE 0 THEN BEGIN
    
      if event.key eq 2 && event.press then begin
        info.ctrl = 1
        info.historyWin->update,'Ctrl On'
      endif
      
      if event.key eq 2 && event.release then begin
        info.ctrl = 0
        info.historyWin->update,'Ctrl Off'
      endif
    endif
    
    if info.marking eq 0 && info.ctrl && info.click then begin
    
      info.marking = 1
      info.markers[0] = info.cursorposition[0]
      
      info.historyWin->update,'Turning Marking On'

      IF info.rubberbanding EQ 1 THEN BEGIN
         info.rubberbanding=0
         info.rubberBandTimer=0D
         info.drawObject->rubberBandOff
         legend = Widget_Info(info.showPositionMenu, /Button_Set)
         
         if info.tracking && legend then begin
           if info.trackAll then info.drawObject->legendOn,/all else info.drawObject->legendOn 
         endif
          
      ENDIF
    
      if info.trackall eq 1 then begin 
        info.drawObject->markerOn,/all,fail=fail
      endif else begin
        info.drawObject->markerOn,fail=fail
      endelse
      
      IF fail EQ 1 && info.markerfail eq 0 THEN BEGIN
      
         info.statusBar->Update, 'Failed to create marker. Cursor was outside panel area'
         info.marking=0
         info.markers=[0.0,0.0]
         info.markerfail=1 ;this flag prevents many copies of the message being printed and crudding things up.  Also, prevents marker title query from popping up when a marker error has already occurred.
         spd_ui_reset_tracking,info

      ENDIF ELSE BEGIN
        FOR i=0,N_Elements(info.markerButtons)-1 DO Widget_Control, info.markerButtons[i], sensitive=1   
      ENDELSE
    endif
    
    ;turn marking off
    if info.marking eq 1 && (~info.ctrl || ~info.click) then begin
    
      info.historyWin->update,'Turning Marking Off'
    
      info.drawObject->markerOff
      info.markers[1]=info.cursorPosition[0]
      
      ;only allow selection for markers that have width greater than or equal to 1 pixel 
      ;this prevents markers that are too small for the user to select.  We may be able to remove this
      ;check in the future if we implement a menu that allows selection of markers without an on-screen 
      ;selection on-screen
           
      ;info.markerTitle->GetProperty, UseDefault=useDefault
;      if info.markerTitleOn then spd_ui_marker_title, info.master, info.markerTitle, info.historywin, info.statusbar $
;         else info.markerTitle=obj_new('SPD_UI_MARKER_TITLE')
      ;info.markerTitle->GetProperty, Cancelled=cancelled      
      spd_ui_create_marker, info  ; updates history and status bar internally
   
      ; since marking is done, reset everything
      info.markers=[0.0,0.0]
      info.marking= 2
      info.drawObject->Update, info.windowStorage, info.loadedData
      info.drawObject->Draw
      info.click = 0
      info.ctrl = 0
      ; lphilpott 5-mar-2012
      ; On windows we have a problem where holding down the ctrl key after the mouse 
      ; button is released in marker creation causes a flood of ctrl on events after the 
      ; Query for marker title dialog is closed. This means that the next thing the user tries 
      ; to do acts as if ctrl is pressed. 
      ; Clearing all these backed up ctrl events is a possible solution.
      widget_control, event.top, /clear_events
    endif

      ; Done with special cases, check button event type to determine what happened
      ; Button Press - marking in progress, draw rubberband box, or display options panel
      ; Button Release - end marking, drawing box, or displaying panel
      ; Motion Event - draw tracking line, marking or drawing box
      
    CASE event.type OF
    
       ; Button Press
       ; set the coordinates and event information, wait for a button release 
  
      0:BEGIN
      
        ; NOTE: if marking was not on then this is either a press to display options 
        ; panel or the start of a click-drag event. Do nothing for now since we will 
        ; not know which of the two options it is until the button is released                  
            
            
        if event.press eq 1 then begin
          info.lastclick[0] = event.x
          info.lastclick[1] = event.y
          info.prevEventX = event.x
          info.prevEvent='PRESS'
        
          info.drawObject->setCursor, info.cursorPosition
        endif
     ;   tmp = info.drawObject->getClick()
  
       ; print,'Got Click.'
       ; if ~is_struct(tmp) then begin
          ;print,'Clicked Page'
       ; endif else begin
        ;  print,'Clicked Panel: ' + strtrim(string(tmp.panelidx),2)
        
        ;  if tmp.component eq 0 then print,'Component: Panel'
        ;  if tmp.component eq 1 then print,'Component: Xaxis'
         ; if tmp.component eq 2 then print,'Component: Yaxis'
         ; if tmp.component eq 3 then print,'Component: Zaxis'
         ; if tmp.component eq 4 then print,'Component: Variables'
          
         ; print,"marker:",tmp.marker
          
        ;endelse 

        RETURN, info

      END

        ; Button Release, either
        ; 1)marking done, 
        ; 2)rubberband box done, or 
        ; 3)display options panel 
      
      1: BEGIN
        ; Print, 'Button release'  
            ; display options
            
        IF info.marking EQ 0 && info.prevEvent EQ 'PRESS' && event.release eq 1 THEN BEGIN
        
           info.historyWin->update,'Options Click'
          ; print, 'display options'
           spd_ui_display_options, info
           info.marking=0
           info.prevEventX = event.x
           info.prevEvent='RELEASE'
           info.drawingBox=0
           info.rubberBanding=0
           info.drawObject->rubberBandOff
           info.drawObject->markerOff
           RETURN, info
        ENDIF
        
            ; rubber band box
            
        IF info.rubberBanding EQ 1 && info.prevEvent EQ 'MOTION' THEN BEGIN
        ;   print, 'rubber band off'
        
           info.historyWin->update,'Turning Rubber Band Off'
        
           info.drawObject->setCursor, info.cursorPosition
           info.drawObject->rubberBandOff
      
           vBar = widget_info(info.trackVMenu,/button_set)
           if vBar eq 1 then begin
             IF info.trackAll EQ 1 THEN info.drawObject->vBarOn, /all ELSE info.drawObject->vBarOn
           endif
           
           hBar = widget_info(info.trackhMenu,/button_set)
           if hBar eq 1 then begin
           ;  IF info.trackAll EQ 1 THEN info.drawObject->hBarOn, /all ELSE info.drawObject->hBarOn
             info.drawObject->hBarOn
           endif   
         
           legend = Widget_Info(info.showPositionMenu, /Button_Set)
           IF legend EQ 1 && info.tracking THEN BEGIN
              IF info.trackAll EQ 1 THEN info.drawObject->legendOn, /all ELSE info.drawObject->legendOn
           ENDIF 
           
           ; If rubber band time or distance is too short then treat as normal click. 
           ; This prevents clicks from getting lost if user drags the mouse bit while clicking.
           tm = sysTime(/seconds)
           IF tm - info.rubberBandTimer GT 0.18 || $ 
             sqrt( abs(info.lastclick[0] - event.x)^2 + abs(info.lastclick[1] - event.y)^2 ) gt 15 then begin
             spd_ui_rubber_band_box, info
             spd_ui_update_title, info
           endif else begin
             spd_ui_display_options, info
           endelse
                      
           
           info.drawObject->draw
           
           info.drawingBox=0
           info.marking=0
           info.rubberBanding=0
           info.rubberBandTimer=0D
           info.prevEventX = event.x
           info.prevEvent='RELEASE'
           RETURN, info
        ENDIF
        
      END      

         ; Motion Event
         ; 1)If marking is on -> draw line
         ; 2)If marking is just finishing -> reset marking params and draw line
         ; 3)draw rubberbsand box
      
      2: BEGIN
        ;print, 'motion event'      
        info.prevEventX = event.x
        info.prevEventType = event.type
        
            ; marking is on, draw line

        IF info.marking EQ 1 && (info.prevEvent EQ 'CTRL' OR info.prevEvent EQ 'MOTION') THEN BEGIN
        ;   print, 'marking on'
           info.drawObject->setCursor, info.cursorPosition
           info.prevEvent='MOTION'
           RETURN, info
        ENDIF
        
            ; marking was on and just turned off - needed to wait for cursor 
            ; motion to reset marking variables 

        IF info.marking EQ 2 THEN BEGIN
         ;  print, 'marking officially off'
           info.marking=0
           info.markerfail=0
           info.drawObject->setCursor, info.cursorPosition
           info.prevEvent='MOTION'
           RETURN, info
        ENDIF
        
            ; marking was not on, but button was pressed then start drawing box 
            
        IF info.marking EQ 0 && info.prevEvent EQ 'PRESS' THEN BEGIN
        ;   print, 'starting rubber band box'
           info.drawingBox=1 
           info.drawObject->setCursor, info.cursorPosition
           info.drawObject->rubberBandOn
           info.rubberBandTimer=sysTime(/seconds)
           info.drawObject->vBarOff
           info.drawObject->hBarOff
           info.drawObject->legendOff
           info.marking=0
           info.markerfail=0
           info.rubberBanding=1
           info.prevEvent='MOTION'
           RETURN, info
        ENDIF
        
           ; drawing box
           
        IF info.drawingBox EQ 1 && info.prevEvent EQ 'MOTION' THEN BEGIN
          ; print, 'drawing box'
           info.drawObject->setCursor, info.cursorPosition
           info.marking=0
           info.markerfail=0
           info.prevEvent='MOTION'
           RETURN, info
        ENDIF
        
           ; just tracking
           
        IF info.marking EQ 0 && info.drawingBox EQ 0 THEN BEGIN
        ;   print, 'just tracking'
           info.drawObject->setCursor, info.cursorPosition
           info.marking=0
           info.markerfail=0
           info.prevEvent='MOTION'
           RETURN, info
        ENDIF
        
        info.prevEvent='MOTION'
        RETURN, info
      END
      5: BEGIN 
        
;        print,event.ch
        
        ;this code block manually implements accelerator keys on platforms without accelerator support
        if info.ctrl && event.press && info.marking eq 0 && info.rubberBanding eq 0 then begin
          info.ctrl=0
          if event.ch eq 3 then begin ; Ctrl+C
            spd_ui_copy, info
          endif else if event.ch eq 26 then begin
            spd_ui_close_window,info
          endif else if event.ch eq 14 then begin
            spd_ui_window,info
          endif else if event.ch eq 15 then begin
            spd_ui_open,info
          endif else if event.ch eq 19 then begin
            spd_ui_save,info
          endif else if event.ch eq 16 then begin
            spd_ui_print,info
          endif else if event.ch eq 17 then begin
            spd_ui_exit,event,info=info
            return,0
          endif else if event.ch eq 18 then begin
            spd_ui_refresh,info
          endif
        endif 
        
        if event.press then begin
          if event.ch eq 9 then begin
            spd_ui_expand,info
          endif else if event.ch eq 8 then begin
            spd_ui_reduce,info
          endif else begin 
;            print,event.ch
          endelse
        endif
      
      END
      6: BEGIN
  
       if event.press && event.key eq 5 then begin
          spd_ui_scrollb,info  ;move the displayed data in back in time/left along x-axis
        endif else if event.press && event.key eq 6 then begin
          spd_ui_scrollf,info  ;move the displayed data in forward in time/right along x-axis
        endif else if event.press && event.key eq 7 then begin
          spd_ui_scroll_view,info.drawID,1 ;moves the displayed region of the view up(shortcut for clicking the vertical scroll bar)
        endif else if event.press && event.key eq 8 then begin
          spd_ui_scroll_view,info.drawID,0 ;moves the displayed region of the view down(shortcur for clicking the vertical scroll bar)
        endif
             
      END
      
      ELSE: BEGIN
      END
      
    ENDCASE
    
  RETURN, info
  END
