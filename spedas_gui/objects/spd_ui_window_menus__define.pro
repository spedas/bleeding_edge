;+
;
;  Name: SPD_UI_WINDOW_MENUS
;  
;  Purpose: Manages window menu
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-12-18 13:19:05 -0800 (Thu, 18 Dec 2014) $
;$LastChangedRevision: 16510 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_window_menus__define.pro $
;-

PRO SPD_UI_WINDOW_MENUS::Add, name

    IF Ptr_Valid(self.names) THEN BEGIN
       numNames=N_Elements(*self.names)
       menuNames=*self.names
       IF numNames EQ 0 THEN menuNames=[name] ELSE menuNames=[menuNames, name]
    ENDIF ELSE BEGIN
       menuNames=[name]
    ENDELSE  
    self.names=Ptr_New(menuNames) 

    IF N_Elements(menuNames) EQ 1 THEN BEGIN
       newButton = Widget_Button(self.windowMenu, value=name, UValue='WINBUTTON', /checked_menu, /separator)
       self.ids=Ptr_New([newButton])
    ENDIF ELSE BEGIN
       newButton = Widget_Button(self.windowMenu, value=name, /checked_menu, UValue='WINBUTTON')
       menuIds=*self.ids
       menuIds=[menuIds, newButton]
       self.ids=Ptr_New(menuIds)
    ENDELSE 
    
END ;--------------------------------------------------------------------------------



PRO SPD_UI_WINDOW_MENUS::Remove, name

    IF Ptr_Valid(self.names) THEN BEGIN
       numNames=N_Elements(*self.names)
       menuNames=*self.names
       numIds=N_Elements(*self.ids)
       menuIds=*self.ids
       IF numIds NE numNames THEN RETURN
       IF numNames GT 0 THEN BEGIN
          FOR i=0,numNames-1 DO BEGIN
             IF menuNames[i] EQ name THEN BEGIN
                index=i
                Widget_Control, menuIds[i], /Destroy 
                BREAK
             ENDIF
          ENDFOR
          
          ; first one in array, remove first element 
          ; also need to add the separator bar to the new first item
          IF Is_Num(index) && index EQ 0 THEN BEGIN
             IF numNames LE 1 THEN BEGIN
                Ptr_Free, self.names
                Ptr_Free, self.ids
                self.names=Ptr_New()
                self.ids=Ptr_New()
             ENDIF ELSE BEGIN
                newNames = menuNames[1:numNames-1]
                newIds = menuIds[1:numNames-1]
                FOR i=0,N_Elements(newIds)-1 DO BEGIN
                  Widget_Control, newIds[i], /Destroy
                  IF i EQ 0 THEN BEGIN
                     newButton = Widget_Button(self.windowMenu, value=newNames[i], /checked_menu, UValue='WINBUTTON', /separator)
                     Widget_Control, newButton, Set_Button=1
                  ENDIF ELSE BEGIN  
                     newButton = Widget_Button(self.windowMenu, value=newNames[i], /checked_menu, UValue='WINBUTTON')
                  ENDELSE 
                  newIds[i]=newButton
                ENDFOR
                Ptr_Free, self.names
                Ptr_Free, self.ids
                self.names=Ptr_New(newNames) 
                self.ids=Ptr_New(newIds) 
             ENDELSE
          ENDIF
          
          ; in middle of array
          IF Is_Num(index) && index GT 0 && index LT numNames-1 THEN BEGIN
             newNames = [menuNames[0:index-1],menuNames[index+1:numNames-1]]
             newIds = [menuIds[0:index-1],menuIds[index+1:numNames-1]]
             Ptr_Free, self.names
             Ptr_Free, self.ids
             self.names=Ptr_New(newNames)
             self.ids=Ptr_New(newIds)
          ENDIF 
          
          ; last one in array
          IF Is_Num(index) && index EQ numNames-1 THEN BEGIN
             IF numNames LE 1 THEN BEGIN
             Ptr_Free, self.names
             Ptr_Free, self.ids
             self.names=Ptr_New()
             self.ids=Ptr_New()
             ENDIF ELSE BEGIN
                newNames = menuNames[0:numNames-2]
                newIds = menuIds[0:numNames-2]
                Ptr_Free, self.names
                Ptr_Free, self.ids
                self.names=Ptr_New(newNames) 
                self.ids=Ptr_New(newIds) 
             ENDELSE
          ENDIF
           
       ENDIF
    ENDIF  
           
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_WINDOW_MENUS::GetIds
  RETURN, *self.ids
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_WINDOW_MENUS::GetNames
  RETURN, *self.names
END ;--------------------------------------------------------------------------------



PRO SPD_UI_WINDOW_MENUS::Clear
    IF Ptr_Valid(self.ids) THEN BEGIN
       numButtons=N_Elements(*self.ids)
       buttons=*self.ids
       IF numButtons GT 0 THEN BEGIN
          FOR i=0,numButtons-1 DO Widget_Control, buttons[i], Set_Button=0
       ENDIF   
    ENDIF
END ;--------------------------------------------------------------------------------



;This function will crash if the number of names in the list of names is less than the number of windowobjs in the windowStorage object.
;A good solution would be to redesign this object to automatically manage the names list, rather than require manual adds & removes.
; ^ added sync function below 2014-03-18
PRO SPD_UI_WINDOW_MENUS::Update, windowStorage
    self->Clear
    IF Ptr_Valid(self.names) THEN BEGIN
       numNames=N_Elements(*self.names)
       menuNames=*self.names
       menuIds=*self.ids
       IF numNames GT 0 && Obj_Valid(windowStorage) THEN BEGIN
          windowObj=windowStorage->GetActive()
          IF N_Elements(windowObj) GT 0 && Obj_Valid(windowObj) THEN BEGIN
             windowObj[0]->GetProperty, Name=activeName
             windowObjs=windowStorage->GetObjects()
             IF N_Elements(windowObjs) GT 0 THEN BEGIN
                FOR i=0,N_Elements(windowObjs)-1 DO BEGIN
                   windowObjs[i]->GetProperty, Name=thisName
                   menuNames[i] = thisname
                   IF thisName EQ activeName THEN Widget_Control, menuIds[i], set_button=1 $
                      ELSE Widget_Control, menuIds[i], set_button=0
                   widget_control, menuIDs[i], set_value=thisName
                ENDFOR
                ptr_free, self.names
                self.names = ptr_new(menuNames)
             ENDIF
          ENDIF
       ENDIF      
    ENDIF
END ;--------------------------------------------------------------------------------



; This will clear the current menu and synchronize it to the window storage object.
PRO SPD_UI_WINDOW_MENUS::sync, windowStorage
  
  ;check objects
  if ~obj_valid(windowstorage) then return
  windows = windowstorage->getobjects()
  if ~obj_valid(windows[0]) then return

  ;clear previous page list
  if ptr_valid(self.ids) then begin
    for i=0, n_elements(*self.ids)-1 do begin
      widget_control, (*self.ids)[i], /destroy
    endfor
  endif

  ;clear internal vars
  ; -apparently IDL reserves "Cleanup" as an object destruction method
  ;  and will not allow a method with that name to be called internally
  ptr_free, self.names
  ptr_free, self.ids
  
  ;add existing pages
  for i=0, n_elements(windows)-1 do begin
    windows[i]->getproperty, name=name, isactive=active
    self->add, name
    if active then widget_control, (*self.ids)[i], set_button=1 
  endfor
  
END ;--------------------------------------------------------------------------------



PRO SPD_UI_WINDOW_MENUS::Cleanup
Ptr_Free, self.names
Ptr_Free, self.ids
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_WINDOW_MENUS::Init,   $
        windowmenu,            $ ; widget id for the window menu pull down
        Name=name,             $ ; name of window menu      
        ID=id                    ; widget id of window menu
        
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=1)
      RETURN, 0
   ENDIF

   IF N_Elements(windowmenu) EQ 0 OR windowmenu EQ 0 THEN RETURN, -1 ELSE $
      self.windowMenu = windowmenu
   IF N_Elements(name) NE 0 THEN self.names=Ptr_New(name) ELSE self.names=Ptr_New()
   IF N_Elements(id) NE 0 THEN self.ids=Ptr_New([id]) ELSE self.ids=Ptr_New()
       
RETURN, 1
END ;--------------------------------------------------------------------------------



PRO SPD_UI_WINDOW_MENUS__DEFINE

   struct = { SPD_UI_WINDOW_MENUS,$

              names: Ptr_New(),   $ ; array of window menu names
              ids: Ptr_New(),     $ ; array of window menu widget ids 
              windowMenu: 0L      $
}

END
