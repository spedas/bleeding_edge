;+ SetButtonActive
;NAME: 
; spd_ui_windows__define
;
;PURPOSE:
; This is an array of window objects and represents all the data that has been loaded
; for this session.
;
;CALLING SEQUENCE:
;
;OUTPUT:
; reference to window object array
;
;ATTRIBUTES:
; array of window objects
;
;METHODS:
; SetProperty     
; GetProperty     
; Add             creates a new window object and adds it to the array
; GetActive       returns active window object
; SetActive       makes a window object active given a windowID
; GetSelected     returns the selected window object
; SetSelected     makes a window object selected
; 
; NOTE: These 3 methods do not appear to exist
; GetDefaultTitle returns a title, if the user has provided a default one
; AskForTitle     return 1=if user wants to be asked each time, 0=don't ask, use default
; ClearActive     resets active windows to inactive (must provide a window ID)

; ClearAll        clears either selected or active windows (must use a keyword)
; AddObject       adds a new object to the array (method for internal use)   
; RemoveObject    removes an object from the array (routine for internal use) 
; GetObjects      returns an array of all data objects, can also take a name or group name (method for internal use)
;
;  NOTE:
;  
;  Markers can be active and/or selected. 
;  ACTIVE:  If a window is 'active' then it is currently displayed on a window. 
;  If the window is no longer active, then the window is no longer
;  active and must be deactivated. To make a window inactive the user must provide a windowID. 
;  SELECTED: If a window is 'selected' then it is either a new window (which automatically 
;  by default, becomes the selected window) or the user has clicked on a specific 
;  window to select it. There can only be one 'selected' window at a time.
;  
;HISTORY:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-13 09:37:27 -0700 (Mon, 13 Jul 2015) $
;$LastChangedRevision: 18098 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_windows__define.pro $
;-----------------------------------------------------------------------------------


FUNCTION SPD_UI_WINDOWS::Add,  $
      Name=name,               $ ; name for this window
      IsActive=isactive,       $ ; flag set if this window is displayed
      NRows=nrows,             $ ; number of rows in this  window 
      NCols=ncols,             $ ; number of columns in this window
      Panels=panels,           $ ; ptr to array of panels displayed on this window
      Settings=settings,       $ ; object for page settings
      Locked=locked,           $ ; set if x axes are locked
      Tracking=tracking          ; flag set if tracking is on
      
   compile_opt idl2
     
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message('An error occured while adding pages. See console for details.',/noname)
      ;spd_ui_error
      RETURN, 0
   ENDIF
   
      ; Check that all parameters have values
   IF N_Elements(name) EQ 0 THEN name='Page: ' + strtrim(string(self.id),2)
   IF N_Elements(isactive) EQ 0 THEN isactive = 1
   IF N_Elements(nrows) EQ 0 THEN nrows=2
   IF N_Elements(ncols) EQ 0 THEN ncols=1
   IF N_Elements(locked) EQ 0 THEN locked=0 ELSE locked=locked
 
   if obj_valid(settings) then begin
     newsettings=settings->copy()
   endif

   if obj_valid(self.template) then begin
     self.template->getProperty,page=page
     if obj_valid(page) then begin
       newsettings = page->copy()
     endif
   endif

   IF NOT Obj_Valid(panels) THEN Begin 
     panels = Obj_New('IDL_Container')
   endif else begin     
     if ~obj_isa(panels,'IDL_Container') then begin
       ok=error_message('Non container object passed where one expected',/traceback,/noname)
       return,0
     endif   
     panelObjs = panels->get(/all)
     for i = 0,n_elements(panelObjs)-1L do begin
       if obj_valid(panelObjs[i]) then panelObjs[i]->setProperty,windowID=self.id     
     endfor
   endelse       
   IF N_Elements(tracking) EQ 0 THEN tracking = 1
   
   IF isactive EQ 1 THEN self->clearAllActive
   
   newWindow = Obj_New("SPD_UI_WINDOW", self.id, Name=name, $
      IsActive=isactive, NRows=nrows, NCols=ncols, Settings=newsettings, $
      Tracking=tracking, Locked=locked, Panels=panels)   
   IF NOT Obj_Valid(newWindow) THEN RETURN, 0 
   result=self->AddObject(newWindow)
   IF result EQ 0 THEN RETURN, 0
   
   if keyword_set(isActive) then self->setActive,id=self.id
   
   ;now handled in layout panel
;   if locked then begin
;     self.axisObject->lock,windowid=self.id
;   endif
   
      ; All went well, so increment id for the next new panel
      
   self.id = self.id + 1

RETURN, 1
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_WINDOWS::AddNewObject, windowObj
   compile_opt idl2
     
   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message('An error occured while adding pages. See console for details.',/traceback,/noname)
      ;spd_ui_error
      RETURN, 0
   ENDIF
   
   IF ~Obj_Valid(windowObj) THEN RETURN, 0
   windowObj->GetProperty, Name=name,Id=id,NRows=nrows, NCols=ncols, $
      IsActive=isactive,Locked=locked,Panels=panels,Settings=settings, $
      PanelId=panelid,Tracking=tracking

      ; Check that all parameters have values
   ; Disregard window name from windowObj, to force uniqueness
   name='Page: ' + strtrim(string(self.id),2)
   ; Clobber the incoming name too while we're at it...
   windowObj->SetProperty,name=name
   IF N_Elements(id) EQ 0 THEN id = 0
   IF N_Elements(nrows) EQ 0 THEN nrows=1
   IF N_Elements(ncols) EQ 0 THEN ncols=1
   IF N_Elements(isactive) EQ 0 THEN isactive = 1
   IF N_Elements(panelid) EQ 0 THEN panelid = 0
   IF N_Elements(tracking) EQ 0 THEN tracking = 1
   IF N_Elements(locked) EQ 0 THEN locked = 1
 
   if obj_valid(settings) then begin
     newsettings=settings->copy()
   endif

   if obj_valid(self.template) then begin
     self.template->getProperty,page=page
     if obj_valid(page) then begin
       newsettings = page->copy()
     endif
   endif

   IF NOT Obj_Valid(panels) THEN Begin 
     panels = Obj_New('IDL_Container')
   endif else begin     
     if ~obj_isa(panels,'IDL_Container') then begin
       ok=error_message('Non container object passed where one expected',/traceback,/noname)
       return,0
     endif     
     panelObjs = panels->get(/all) 
     IF Obj_Valid(panelObjs[0]) THEN BEGIN    
       for i = 0,n_elements(panelObjs)-1L do begin     
         panelObjs[i]->setProperty,windowID=self.id     
       endfor 
     ENDIF    
   endelse       
   
   IF isactive EQ 1 THEN self->clearAllActive
   
   newWindow = Obj_New("SPD_UI_WINDOW", self.id, Name=name, $
      IsActive=isactive, NRows=nrows, NCols=ncols, Settings=newsettings, $
      Tracking=tracking, Panels=panels,Locked=locked, Panelid=panelid)   
   IF NOT Obj_Valid(newWindow) THEN RETURN, 0 
   result=self->AddObject(newWindow)
   IF result EQ 0 THEN RETURN, 0
   
   if keyword_set(isActive) then self->setActive,id=self.id
     
      ; All went well, so increment id for the next new panel
      
   self.id = self.id + 1

RETURN, 1
END ;--------------------------------------------------------------------------------


;WARNING: This method is not like the other copy methods
;Rather than copying all the windows and settings that it
;contains,  This method makes a copy of its active window
;and adds it to the list of windows.
PRO SPD_UI_WINDOWS::Copy
   activeWindow=self->GetActive() 
   newWindow=activeWindow[0]->Copy()
   newWindow->GetProperty,       $
        NRows=nrows,             $ ; number of rows
        NCols=ncols,             $ ; number of columns
        Panels=panels,           $ ; panel objects on this window
        Settings=settings,       $ ; properties of this window
        Tracking=tracking          ; flag set if tracking is on
        result=self->Add( $
        NRows=nrows, $ 
        NCols=ncols, $ 
        Panels=panels, $ 
        Settings=settings, $ 
        Tracking=tracking)         
END ;--------------------------------------------------------------------------------



PRO SPD_UI_WINDOWS::Remove
   
END ;--------------------------------------------------------------------------------

;
;
;PRO SPD_UI_WINDOWS::GetProperty, $
;    WindowObjs=windowobjs,         $ ; window array
;    callSequence=callSequence,     $ ; object stores the sequence of data operation functions that have been called
;    Id=id                            ; current value of id
;    
;   Catch, theError
;   IF theError NE 0 THEN BEGIN
;      Catch, /Cancel
;      ok = Error_Message('An error occured while retrieving page properties. See console for details.', $
;                         /traceback, /noname)
;      ;spd_ui_error
;      RETURN
;   ENDIF
;
;   IF Arg_Present(windowobjs) THEN BEGIN
;      IF Ptr_Valid(self.windowObjs) THEN windowobjs = self.windowObjs $
;         ELSE windowobjs = 0
;   ENDIF
;   
;   if arg_present(callSequence) then callSequence = self.callSequence
;   
;   IF Arg_Present(id) THEN id = self.id
;   
;   
;RETURN
;END ;--------------------------------------------------------------------------------
;
; 
    
PRO SPD_UI_WINDOWS::SetActive, Id=id

    compile_opt idl2

   IF Ptr_Valid(self.windowObjs) EQ 0 THEN RETURN 
   numObjects = N_Elements(*self.windowObjs)
   IF numObjects LT 1 THEN RETURN  
   dataArr=*self.windowObjs
   
   self->clearAllActive
   
   FOR i=0, numObjects-1 DO BEGIN
      dataObj=dataArr[i]
      dataObj->GetProperty, Id=thisID 
      IF id EQ thisID THEN BEGIN
         dataObj->SetProperty, IsActive=1
         return
      ENDIF
   ENDFOR
                     
END ;--------------------------------------------------------------------------------



PRO SPD_UI_WINDOWS::SetButtonActive, ID=id

    compile_opt idl2
 
   ; set the button active on the pulldown menu

   IF Ptr_Valid(self.windowButtons) EQ 0 THEN RETURN 
   numObjects = N_Elements(self.windowButtons)
   IF numObjects LT 1 THEN RETURN  
   FOR i=0, numObjects-1 DO BEGIN
      IF id EQ self.windowButtons[i] THEN BEGIN
         name = self.windowNames[i]
         Widget_Control, id, Set_Button=1
      ENDIF ELSE BEGIN 
         Widget_Control, self.windowButtons[i], Set_Button=1
      ENDELSE
   ENDFOR 
   
      ; set the window to active
      
   self->clearAllActive
   
   IF Ptr_Valid(self.windowObjs) EQ 0 THEN RETURN 
   numObjects = N_Elements(self.windowObjs)
   IF numObjects LT 1 THEN RETURN  
   dataArr=*self.windowObjs   
   FOR i=0, numObjects-1 DO BEGIN
      dataObj=dataArr[i]
      dataObj->GetProperty, Name=thisName 
      IF N_Elements(name) GT 0 && name EQ thisName THEN BEGIN
         dataObj->GetProperty, Id=id
         self->SetActive, id
         return
      ENDIF
   ENDFOR
END ;--------------------------------------------------------------------------------

 

FUNCTION SPD_UI_WINDOWS::GetActive

    compile_opt idl2

   IF Ptr_Valid(self.windowObjs) EQ 0 THEN RETURN,0 
   numObjects = N_Elements(*self.windowObjs)
   IF numObjects LT 1 THEN RETURN, 0  
   dataArr=*self.windowObjs
   
   FOR i=0, numObjects-1 DO BEGIN
      dataObj=dataArr[i]
      dataObj->GetProperty, IsActive=isactive
      IF isactive EQ 1 THEN BEGIN
         IF N_Elements(activeArr) EQ 0 THEN activeArr = [dataObj] $
            ELSE activeArr = [activeArr, dataObj]
      ENDIF
   ENDFOR

   IF N_Elements(activeArr) EQ 0 THEN RETURN, 0 ELSE RETURN, activeArr
                   
END ;--------------------------------------------------------------------------------

pro spd_ui_windows::Reset, callSequence=callSequence
    ptr_free,self.windowObjs
    self.windowObjs=ptr_new()

    ptr_free,self.windowButtons
    self.windowButtons=ptr_new()

    ptr_free,self.windowNames
    self.windowNames=ptr_new()

    obj_destroy,self.callSequence
    self.callSequence = callSequence

    self.id = 1L  ; not sure this is necessary?
end

PRO SPD_UI_WINDOWS::ClearActive, Id=id

   compile_opt idl2

   IF Ptr_Valid(self.windowObjs) EQ 0 THEN RETURN 
   IF N_Elements(id) EQ 0 THEN RETURN
   numObjects = N_Elements(*self.windowObjs)
   IF numObjects LT 1 THEN RETURN  
   dataArr=*self.windowObjs
      
   FOR i=0, numObjects-1 DO BEGIN
      dataObj=dataArr[i]
      dataObj->GetProperty, Id=thisId
      IF id EQ thisId THEN BEGIN
         dataObj->SetProperty, IsActive=0
      ENDIF
   ENDFOR
                          
END ;--------------------------------------------------------------------------------



PRO SPD_UI_WINDOWS::ClearAllActive

   IF Ptr_Valid(self.windowObjs) EQ 0 THEN RETURN
   numObjects = N_Elements(*self.windowObjs)
   IF numObjects LT 1 THEN RETURN  
   dataArr=*self.windowObjs
   
   FOR i=0L, numObjects-1L DO BEGIN
      dataObj=dataArr[i]
      dataObj->SetProperty, IsActive=0 
   ENDFOR
                     
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_WINDOWS::AddObject, dataObject 

   compile_opt idl2

      ; check for validity
      
   IF NOT Obj_Valid(dataObject) THEN RETURN, 0 

      ; If this the first data object create array and add this to it
      ; otherwise just add to the existing array

   IF NOT Ptr_Valid(self.windowObjs) THEN BEGIN
      temp = ObjArr(1)
      temp[0] = dataObject
      Ptr_Free, self.windowObjs
      self.windowObjs = Ptr_New(temp)
   ENDIF ELSE BEGIN
      numObjects = N_Elements(*self.windowObjs)
      temp = Objarr(numObjects)
      temp = [*self.windowObjs, dataObject]
      Ptr_Free, self.windowObjs
      self.windowObjs = Ptr_New(temp)
   ENDELSE
    
   RETURN, 1
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_WINDOWS::RemoveObject, dataObject

   compile_opt idl2
   
       ; check for validity
      
   IF NOT Obj_Valid(dataObject) THEN RETURN, -1 
   
       ; invalid ptr not necessarily an error, just no data
       
   IF NOT Ptr_Valid(self.windowObjs) THEN RETURN, 1
   
   numObjects = N_Elements(*self.windowObjs)
   IF numObjects LT 1 THEN RETURN, 1 ELSE dataArr=*self.windowObjs
   
       ; get the data object id and use it to find the object in the array
                 
   dataObject->GetProperty, ID=removeId, IsActive=isactive
   index=-1

   FOR i=0, numObjects-1 DO BEGIN
      thisObj=dataArr[i]
      thisObj->GetProperty, ID=thisId
      IF thisId EQ removeId THEN BEGIN
         index=i
         BREAK
      ENDIF
   ENDFOR
   
       ; Deal with special cases first
       ; ID not found (not necessarily an error)
   
   IF index EQ -1 THEN RETURN, 1 
   
       ; Only one object in the array
           
   IF index EQ 0 && numObjects EQ 1 THEN BEGIN
      Ptr_Free, self.windowObjs
      self.id = 1
      RETURN, 1
   ENDIF 
   
       ; remove first last and middle elements
       
   temp = ObjArr(numObjects-1)     
   IF index EQ 0 THEN temp = dataArr[1:numObjects-1]
   IF index EQ numObjects-1 THEN temp = dataArr[0:numObjects-2]
   IF index GT 0 && index LT numObjects-1 THEN temp = [dataArr[0:index-1],dataArr[index+1:numObjects-1]]
   
       ; if object removed was active, reset active window to the first one
       ; and create new pointer
       
   IF isActive EQ 1 THEN BEGIN
     if index eq 0 then begin
       temp[0]->SetProperty, IsActive=1
     endif else begin
       temp[index-1]->setProperty, isactive=1
     endelse
   endif
   
   Ptr_Free, self.windowObjs
   self.windowObjs = Ptr_New(temp)
   
   self->renumber

   RETURN, 1  
   
END ;--------------------------------------------------------------------------------

PRO SPD_UI_WINDOWS::Renumber

  compile_opt idl2
  
  if ~ptr_valid(self.windowObjs) then return
  
  dataArr = *self.windowObjs
  valids = where(obj_valid(dataArr), count, complement=invalids)
  
  if count lt 1 then return else begin
    for i=0, count-1 do begin
      dataArr[valids[i]]->SetProperty, ID=i+1
      name='Page: ' + strtrim(string(i+1),2)
      dataArr[valids[i]]->SetProperty, Name=name
    endfor
  endelse
  
  self.id = count+1

  Ptr_Free, self.windowObjs
  self.windowObjs = Ptr_New(dataArr)

END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_WINDOWS::GetObjects, Id=id

  compile_opt idl2
  
  IF Ptr_Valid(self.windowObjs) EQ 0 THEN RETURN, 0 

  IF ~keyword_Set(id) then begin
    RETURN, *self.windowObjs
  endif else begin
    numObjects = N_Elements(*self.windowObjs)
    IF numObjects LT 1 THEN RETURN, 0   
    
    dataArr=*self.windowObjs
 
    FOR i=0, numObjects-1 DO BEGIN
     dataObj=dataArr[i]
     dataObj->GetProperty, Id=thisId 
     if id eq thisId then begin
       if n_elements(objList) eq 0 then begin
         objList = [dataObj]
       endif else begin
         objList = [objList,dataObj]
       endelse
     endif
    endfor
    
  endelse
  
  if n_elements(objList) eq 0 then begin
    return,0
  endif else begin
    return,objList
  endelse 
    
END ;--------------------------------------------------------------------------------

;adds the current windows to a newly created window menus object
pro spd_ui_windows::reloadWindowMenus,windowMenus

  compile_opt idl2

  windows = self->getObjects()

  if obj_valid(windows[0]) then begin
    for i = 0,n_elements(windows)-1 do begin
      windows[i]->getProperty,name=name
      windowMenus->add,name
    endfor
  endif

end

;this routine will update references to a data quantity
;This should be used if a name has changed while traces are
;already in existence .
pro spd_ui_windows::updatedatareference,oldnames,newnames

  compile_opt idl2
  
  windows = self->getObjects()
  
  if ~obj_valid(windows[0]) then return
  
  for i = 0,n_elements(windows)-1 do begin
    windows[i]->updatedatareference,oldnames,newnames
  endfor

end

PRO SPD_UI_WINDOWS::Cleanup
    Ptr_Free, self.windowObjs
    Ptr_Free, self.windowButtons
    Ptr_Free, self.windowNames
    obj_destroy, self.template
    obj_destroy, self.callSequence
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_WINDOWS::Init,loadedData

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message('Error initializing window storage object.  See console output for details.',/traceback,/noname)
      ;spd_ui_error
      RETURN, 0
   ENDIF

   if ~obj_valid(loadedData) then begin
     ok = error_message('Loaded Data must be valid to create window storage object',/traceback,/noname)
     
     return,0
   endif

   self.windowObjs = Ptr_New()
   self.windowButtons = Ptr_New()
   self.windowNames = Ptr_New()
   self.callSequence = obj_new('spd_ui_call_sequence',loadedData)
   self.template = obj_new('spd_ui_template')
   
   self.id = 1
       
RETURN, 1
END ;--------------------------------------------------------------------------------



PRO SPD_UI_WINDOWS__DEFINE

   struct = { SPD_UI_WINDOWS,    $

              windowObjs: Ptr_New(),    $ ; array of objects for windows
              windowButtons: Ptr_New(), $ ; array of widget ids for pull down menu
              windowNames: Ptr_New(),   $ ; array of window names for pull down menu
              callSequence:obj_new(),   $ ; sequence of calls to data routines, used for save without data
              template:obj_new(),       $ ; template object used when creating settings for new windows
              id: 0L,                   $ ; value that will be assigned to next window                                        ; values start counting at 1 not 0
              inherits spd_ui_getset    $ ; provides generate getProperty, setProperty,getAll,setAll methods

}

END
