;+
;spd_ui_draw_object method: Update
;
;This function updates the entire display, it will be pretty
;slow so it should only be called after panel applies, but not
;during common widget events.
;
;WindowStorage:
; the spd_ui_windows object that stores the windows for the scene that is being updated
;
;LoadedData: 
; thm spd_ui_loaded_data object that stores the data used in the scene that is being drawn
;
;Postscript=postscript:
; set this keyword when postscripts are being drawn.  Special kluges for dealing with
; postscript transparency and layering issues are turned on.
; 
; Error=error:
; Pass a named variable in via this keyword when updates are being drawn.  After completion
; It will return a 1 if there was an error and a 0 if there was no error.
; 
; errmsg=errmsg:
; Pass a named variable in via this keyword when updates are being drawn (optional). If a draw object
; error occurs for which an error message has been defined, errmsg will return an anonymous struct with fields 
; describing the error. errmsg does not exist for all cases where error=1, nor is it guaranteed than error=1
; if errmsg exists. This keyword is intended to return error information to calling routines where messages
; may need to be issued to the user (eg. pop up messages).
; It is intended that developers make use of errmsg & add it to procedures/functions as they need it.
; Note that when handling error messages in the calling routine it is necessary to always check the relevant
; fields in the errmsg struct exist before using them as the routine may pick up errors that you don't
; anticipate defined in other areas of the code, with different fields in the struct.
; Note: if no error occurs for which an error message has been defined errmsg is simply not set. It is necessary
; to check if errmsg has been set before handling any messages in the calling routine.
; Note: update itself does not currently produce any errmsg, errmsg is simply passed on to other routines (currently updatePanels).  
; 
; 
; NOTES:
;  1.  Slowness depends on complexity of displayed layout.(number of panels, size of data)
;      It can range from 1/10th of a second to 10 or more seconds
;      
;  2.  Memory usage can spike moderately during this function, but memory usage between
;      calls should be minimal because lookup tables are used for cursor functions.
;      Memory will max out at ~2x the memory of the largest panel being plotted, because data
;      must be copied to process it without corrupting the main data store. 
;      In other words O(N*M), where N is the time resolution of the data on your largest
;      panel, and M is the number of dimensions on this panel.
;   
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__update.pro $
;-

pro spd_ui_draw_object::update,windowStorage,loadedData,postscript=postscript,error=error, errmsg=errmsg

  compile_opt idl2,hidden
  
  ;Assume an error until told otherwise
  error = 1

  
 ; t1 = systime(/seconds)
  
  ;This constant controls the space between locked panels
  ;All locked panels will have at most this many points of vertical spacing
  ;But they can have less.
  ;lockedVerticalSpacing = 5
  
  ;Turn on hourglass, in case it takes awhile
  widget_control,/hourglass
  
 ; self.statusBar->update,'Beginning Update'
 ; self.historyWin->update,'Beginning Update'
  
  ;Remove all of the old display 
  self.staticViews->remove,/all
  self.dynamicViews->remove,/all
  
  ;Garbage collect any heap variables that might be floating around.
  if double(!version.release) lt 8.0d then heap_gc
  
  ;Adds the view that rubber band will exist on
  self.dynamicViews->add,self.rubberView
  
  ;Set the internal postscript flag(it is global to the update operation)
  if keyword_set(postscript) then begin
    self.postscript=1
  endif else begin
    self.postscript=0
  endelse
  
  originalWindow = windowStorage->getActive()
  
  ;use copy to prevent mutation of input settings
  activeWindow = originalWindow->copy()
  
  activeWindow->getProperty,settings=pageSettings,panels=panels,nRows=nRows,nCols=nCols,locked=locked
  
  ;pageSettings->getProperty,ypanelspacing=yverticalspacing
  
  ;override default spacing, if panel locked and page value bigger than constant
;  if locked ne -1 && yverticalspacing ge lockedVerticalSpacing then begin
;  
;    pageSettings->setProperty,ypanelspacing=lockedVerticalSpacing
;    
;  endif
  
  ;This draws the page.  Which includes things like background coloring, and page titles
  if ~self->updatePage(pageSettings) then begin
    self.statusbar->update,'Draw Object Error: Invalid page settings when drawing page'
    self.historyWin->update,'Draw Object Error: Invalid page settings when drawing page'
        
    ;If we fail this call returns us to a pristine state, so that this
    ;object will interact correctly with parent routines without error
    self->nukeDraw
    ;Creating instances allows much quicker operation between updates,
    ;At the cost of slightly slower updates 
    self->createInstance
    return
  endif
  
  ;needed for creating the illusion of transparent ticks, without using true transparency
  pageSettings->getProperty,backgroundcolor=backgroundcolor
  
  margins = activeWindow->getMargins()
  
  panelObjs = panels->get(/ALL)
  
  ;If we don't have a pre-existing view group for panels
  ;This adds one
  if ~obj_valid(self.panelViews) then begin
    self.panelViews = obj_new('IDLgrViewGroup')
    self.scene->add,self.panelViews
  endif
  
  ;Remove old panel info structs
  ptr_free,self.panelInfo
  
  ;Remove old IDLgr panel representations
  self.panelViews->remove,/all
  
  ;No panels in the current display.  Terminate without error.
  ;This is a blank panel.
  if ~obj_valid(panelObjs[0]) then begin
  
    ;Creating instances allows much quicker operation between updates,
    ;At the cost of slightly slower updates
    self->createInstance
    error = 0
    return
  endif
  
  layoutDims = [nRows,nCols]
  ;This routine does the bulk of the detailed updating.
  ;It renders each individual panel, and everything in it
  if ~self->updatePanels(layoutDims,margins,panelObjs,loadedData,backgroundcolor,locked,activeWindow, errmsg=errmsg) then begin
    self.statusbar->update,'Draw Object Error: Updating panels, Please check History'
    self.historyWin->update,'Draw Object Error: Updating panels, Please check History'
    
    ;If we fail this call returns us to a pristine state, so that this
    ;object will interact correctly with parent routines without error
    self->nukeDraw
    
    ;Creating instances allows much quicker operation between updates,
    ;At the cost of slightly slower updates
    self->createInstance
    return
  endif
  
  ;Creating instances allows much quicker operation between updates,
 ;At the cost of slightly slower updates
  self->createInstance
  
  error = 0
  
 ; print,'RUNTIME: ' + string((systime(/seconds) - t1))
  
end
