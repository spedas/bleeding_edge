;+ 
;NAME: 
; spd_ui_window__define
;
;PURPOSE:  
; window object, created each time a new window is opened
;
;CALLING SEQUENCE:
; window = Obj_New("SPD_UI_WINDOW")
;
;INPUT:
; none
;
;ATTRIBUTES:
; name        name for this window
; id          unique identifier for this window
; nRows       number of rows
; nCols       number of columns
; isActive    flag set if window is displayed
; panels      pointer to panel objects on this window
; settings    A list of settings for this window
; panelId     Current value of panelId
; tracking    flag set if tracking is on
;
;OUTPUT:
; window object reference
;
;METHODS:
; GetProperty
; GetAll
; SetProperty
; Copy
; getMargins
; repack
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are now managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_window, and
;  call them in the same way as before
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-13 15:01:15 -0700 (Mon, 13 Jul 2015) $
;$LastChangedRevision: 18111 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_window__define.pro $
;-----------------------------------------------------------------------------------

;This function returns an array that
;contains all the panels within a particular column
;arranged in ascending order by row, if a panels spans multiple rows
;or columns, its reference will be repeated.  If panels overlap,
;the behavior of this routine is undefined
;It returns 0 if there are no panels, or no panels
;in the requested column
;This method originally created for use with spd_ui_lock_axes
function spd_ui_window::getColumn,in_col


  if ~obj_valid(self.panels) || $
     self.panels->count() eq 0 then begin
     return,0
  endif
  
  panels = self.panels->get(/all)
  
  grid = objarr(self.nrows,self.ncols)
  
  for i = 0,n_elements(panels)-1 do begin
  
    panels[i]->getProperty,settings=settings
    settings->getProperty,row=row,col=col,rspan=rspan,cspan=cspan

    for j = 0,rspan-1 do begin
      for k = 0,cspan-1 do begin
        ;NOTE: this may actually constitute an error, the rowspan may need to
        ;be subtracted....        
        if row-1+j lt self.nrows && col-1+k lt self.ncols then begin
          grid[row-1+j,col-1+k] = panels[i]
        endif
      endfor
    endfor
    
  endfor
  
  out = 0
  
  for i = 0,self.nrows-1 do begin
  
    if obj_valid(grid[i,in_col-1]) then begin
      if keyword_set(out) then begin
        out = [out,grid[i,in_col-1]]
      endif else begin
        out = [grid[i,in_col-1]]
      endelse
    endif  
  endfor
  
  return,out
  
end

;Indicates where the panel is in the vertical layout of the panel
;the bottom, top, or middle, or top & bottom of the layout
;-1; error
;0: top & bottom
;1: bottom
;2: middle
;3: top
function spd_ui_window::getPanelPos,panel

  panel->getProperty,settings=settings
  settings->getProperty,col=col,cspan=cspan
  
  above = 0
  below = 0
  
  for i = 0,cspan-1 do begin
  
    column = self->getColumn(col+cspan-1)
    
    if n_elements(column) eq 1 then continue
          
    idx = where(panel eq column,c)
    
    if c eq 0 then begin
     ; ok = error_message('Problem evaluating layout',/traceback)
      return,-1
    endif else begin
      if max(idx) lt n_elements(column)-1 then below = 1
      if min(idx) gt 0 then above = 1
    endelse
       
  endfor
  
  if above eq 0 && below eq 0 then return,0
  if above eq 1 && below eq 1 then return,2
  if above eq 1 then return,1
  if below eq 1 then return,3
 
end

;If panels are added/removed/moved, the number of rows/cols in the window may be 
;in correct.  This routine will modify them appropriately. If nodecrease is not set,
;It will shift the panels/nrows/ncols such that any wasted space on any side is removed.
;If the keyword 'nodecrease' is set, it will only increase the nrows/ncols, if they are
;too small(and thus would produce an error).
;**If the window doesn't have any panels it will not change the current values 
pro spd_ui_window::repack,nodecrease=nodecrease

  compile_opt idl2
  
   maxrow = !VALUES.F_NAN
  maxcol = !VALUES.F_NAN
  minrow = !VALUES.F_NAN
  mincol = !VALUES.F_NAN

  if ~obj_valid(self.panels) then return
  
  panels = self.panels->get(/all)
  
  if ~obj_valid(panels[0]) then return
  
  ;a check to see if every panel spans the entire row
  spanning_all = 1
  
  ;get row initial settings for spanning test
  panels[0]->getProperty,settings=settings
  
  if ~obj_valid(settings) || ~obj_isa(settings,'spd_ui_panel_settings') then begin
    ok = error_message('Panel found invalid settings',/traceback)
    return
  endif  
  
  settings->getProperty,row=row,col=col,rSpan=rSpan,cSpan=cSpan

  base_low_row = row
  base_high_row = rspan + row

  for i = 0,n_elements(panels)-1 do begin ;loop through panels and figure out practical dimensions of current layout
  
    panels[i]->getProperty,settings=settings
    
    if ~obj_valid(settings) || ~obj_isa(settings,'spd_ui_panel_settings') then begin
      ok = error_message('Panel found invalid settings',/traceback)
      return
    endif 
    
    settings->getProperty,row=row,col=col,rSpan=rSpan,cSpan=cSpan
    
    maxrow = max([maxrow,row+rSpan-1],/nan)
    maxcol = max([maxcol,col+cSpan-1],/nan)
    minrow = min([minrow,row],/nan)
    mincol = min([mincol,col],/nan)
  
    ;test to see if test is invalidated
    ;by different position information
    if row ne base_low_row then begin
      spanning_all = 0
    endif
    
    if row+rspan ne base_high_row then begin
      spanning_all = 0
    endif
  
  endfor
  
  if keyword_set(nodecrease) then begin ;if no decrease is set, then just increase nRows/nCols, if needed
    self.nRows = max([self.nRows,maxrow],/nan)
    self.nCols = max([self.nCols,maxcol],/nan)
  endif else begin
  
    rowsub = minrow - 1
    colsub = mincol - 1
  
    ;This is a fix to make sure that the panels only occupy
    ;half the visible space, when there is only one 
    ;effective row.
    if spanning_all then begin
      self.nRows = (maxrow - rowsub)*2
    endif else begin
      self.nRows = maxrow - rowsub
    endelse
    
    self.ncols = maxcol - colsub
    
    ;if there is no top or left unused space, then we don't need to shift panels
    if rowsub eq 0 && colsub eq 0 then begin
      return
    endif else begin ; this code shifts panels to remove wasted space
    
      for i = 0,n_elements(panels)-1 do begin
      
        panels[i]->getProperty,settings=settings
        settings->getProperty,row=row,col=col
        settings->setProperty,row=row-rowsub,col=col-colsub
      
      endfor
    
    endelse
  endelse
  
;  
;  maxrow = !VALUES.F_NAN
;  maxcol = !VALUES.F_NAN
;  minrow = !VALUES.F_NAN
;  mincol = !VALUES.F_NAN
;
;  if ~obj_valid(self.panels) then return
;  
;  panels = self.panels->get(/all)
;  
;  if ~obj_valid(panels[0]) then return
;  
;  for i = 0,n_elements(panels)-1 do begin ;loop through panels and figure out practical dimensions of current layout
;  
;    panels[i]->getProperty,settings=settings
;    
;    if ~obj_valid(settings) || ~obj_isa(settings,'spd_ui_panel_settings') then begin
;      ok = error_message('Panel found invalid settings',/traceback)
;      return
;    endif 
;    
;    settings->getProperty,row=row,col=col,rSpan=rSpan,cSpan=cSpan
;    
;    maxrow = max([maxrow,row+rSpan-1],/nan)
;    maxcol = max([maxcol,col+cSpan-1],/nan)
;    minrow = min([minrow,row],/nan)
;    mincol = min([mincol,col],/nan)
;  
;  endfor
;  
;  if keyword_set(nodecrease) then begin ;if no decrease is set, then just increase nRows/nCols, if needed
;    self.nRows = max([self.nRows,maxrow],/nan)
;    self.nCols = max([self.nCols,maxcol],/nan)
;  endif else begin
;  
;    rowsub = minrow - 1
;    colsub = mincol - 1
;    
;    self.nRows = max([maxrow - rowsub,2])
;    
;    self.ncols = maxcol - colsub
;    
;    ;if there is no top or left unused space, then we don't need to shift panels
;    if rowsub eq 0 && colsub eq 0 then begin
;      return
;    endif else begin ; this code shifts panels to remove wasted space
;    
;      for i = 0,n_elements(panels)-1 do begin
;      
;        panels[i]->getProperty,settings=settings
;        settings->getProperty,row=row,col=col
;        settings->setProperty,row=row-rowsub,col=col-colsub
;      
;      endfor
;    
;    endelse
;  endelse

end

;;Sets the autotick property of its panels to the specified value
;pro spd_ui_window::setAutoTicks,val,xaxis=xaxis,yaxis=yaxis,zaxis=zaxis
;
;  compile_opt idl2
;  
;  if obj_valid(self.panels) && $
;     (count = self.panels->count()) gt 0 then begin
;     
;     for i = 0,count-1 do begin
;       panel = self.panels->get(position=i)
;       panel->setAutoTicks,val,xaxis=xaxis,yaxis=yaxis,zaxis=zaxis
;     endfor
;     
;  endif
;    
;
;end
;
;;synchronizes the tick settings of this object and a copy
;;used by the draw object to selectively mutate the tick settings
;;of the window
;pro spd_ui_window::syncTicks,copy
;
;  compile_opt idl2
;  
;  copy->getProperty,panels=panels
;  
;  if obj_valid(self.panels) && $
;     (count = self.panels->count()) gt 0 && $
;     obj_valid(panels) && $
;     panels->count() eq count then begin
;     
;     for i = 0,count-1 do begin
;     
;       myPanel = self.panels->get(position=i)
;       copyPanel = panels->get(position=i)
;     
;       myPanel->syncTicks,copyPanel
;     
;     endfor
;     
;   endif
;     
;end

;this routine will update references to a data quantity
;This should be used if a name has changed while traces are
;already in existence .
pro spd_ui_window::updatedatareference,oldnames,newnames

  compile_opt idl2
  
  self->getProperty,panels=panels
  
  if ~obj_valid(panels) then return
  
  panel_list = panels->get(/all)
  
  if ~obj_valid(panel_list[0]) then return
  
  for i = 0,n_elements(panel_list)-1 do begin
    panel_list[i]->updatedatareference,oldnames,newnames
  endfor
  
end

;returns a list of margins information from its settings, 
;the returned array has the following elements:
;[left,right,top,bottom,internal] in points

function spd_ui_window::getMargins

  compile_opt idl2
  
  self.settings->getProperty,leftPrintMargin=left, $
                             rightPrintMargin=right, $
                             topPrintMargin=top, $
                             bottomPrintMargin=bottom, $
                             xpanelSpacing=xinternal,$
                             ypanelSpacing=yinternal
                             
  in2cm = 2.54D
  cm2mm = 10D
  mm2pt = 360D/127D
  
  left *= in2cm * cm2mm * mm2pt
  right *= in2cm * cm2mm * mm2pt
   
  top *= in2cm * cm2mm * mm2pt
  bottom *= in2cm * cm2mm * mm2pt

  return,[left,right,top,bottom,xinternal,yinternal]

end



FUNCTION SPD_UI_WINDOW::Copy
   out = Obj_New("SPD_UI_WINDOW", 1)
   Struct_Assign, self, out
   ; copy page settings
   newSettings=self.Settings->Copy()
   out->SetProperty, Settings=newSettings
   ; copy panels
   newPanels=Obj_New("IDL_Container")
   IF Obj_Valid(self.panels) THEN origPanels=self.panels->Get(/all)
   nPanels = N_Elements(origPanels)
   IF nPanels GT 0 THEN BEGIN
      FOR i=0, nPanels-1 DO BEGIN
         IF Obj_Valid(origPanels[i]) THEN BEGIN
            newPanel=origPanels[i]->Copy()
            newPanels->Add, newPanel
         ENDIF 
      ENDFOR
   ENDIF
   out->SetProperty, Panels=newPanels
   RETURN, out
END ;--------------------------------------------------------------------------------


FUNCTION SPD_UI_WINDOW::GetPanelId
RETURN, self.panelId
END ;--------------------------------------------------------------------------------

PRO SPD_UI_WINDOW::IncrementPanelId
self.panelId = self.panelId + 1
END ;--------------------------------------------------------------------------------

pro spd_ui_window::save

  obj = self->copy()
  if ptr_valid(self.origsettings) then begin
    ptr_free,self.origsettings
  endif
  self.origsettings = ptr_new(obj->getall())
  
  return
end

pro spd_ui_window::reset

  if ptr_valid(self.origsettings) then begin
    ; idl 8.1 fix - removed in favour of fix to spd_ui_getset__define: SetAll
    ;str = *self.origsettings
    ;self->SetAll, str
    self->SetAll,*self.origsettings
    self->save
  endif

end

pro spd_ui_window::setProperty,locked=locked,_extra=ex

  self->spd_ui_getset::setProperty,_extra=ex

  if n_elements(locked) gt 0 then begin
    self.settings->setProperty,parentlocked=locked
    self.locked=locked
  endif

end

;PRO SPD_UI_WINDOW::Cleanup 
;   Obj_Destroy, self.settings
;   Obj_Destroy, self.panels     
;RETURN    
;END ;--------------------------------------------------------------------------------


  
FUNCTION SPD_UI_WINDOW::Init,    $ ; The INIT method of the line style object
        id,                      $ ; unique identifier for this window (required)
        Name=name,               $ ; name for this window
        NRows=nrows,             $ ; number of rows 
        NCols=ncols,             $ ; number of columns         
        IsActive=isactive,       $ ; flag if window is displayed
        locked=locked,           $ ; Indicates which panel the window is locked to
        Panels=panels,           $ ; panel objects on this window
        Settings=settings,       $ ; properties of this window
        PanelId=panelid,         $ ; current value of panel id
        Tracking=tracking,       $ ; flag set if tracking is on
        Debug=debug                ; flag to debug

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF
  
   ; Check that all parameters have values
   
   IF N_Elements(id) EQ 0 THEN id = -1 
   IF N_Elements(name) EQ 0 THEN name = '' 
   IF N_Elements(nrows) EQ 0 THEN nrows = 2 
   IF N_Elements(ncols) EQ 0 THEN ncols = 1 
   IF N_Elements(isactive) EQ 0 THEN isactive = 1 
   if n_elements(locked) eq 0 then locked = 0
   IF NOT Obj_Valid(panels) THEN panels = Obj_New('IDL_Container')
   IF NOT Obj_Valid(settings) THEN settings = Obj_New('SPD_UI_PAGE_SETTINGS')
   IF N_Elements(panelid) EQ 0 THEN panelid = 0 
   IF N_Elements(tracking) EQ 0 THEN tracking = 1 

  ; Set all parameters

   settings->setProperty,parentlocked=locked

   self.id = id
   self.name = name
   self.nRows = nrows
   self.nCols = ncols
   self.isActive = isactive
   self.locked = locked
   self.panels = panels
   self.settings = settings
   self.panelId = panelid
   self.tracking = tracking
  
   RETURN, 1
END ;--------------------------------------------------------------------------------                 

PRO SPD_UI_WINDOW__DEFINE

   struct = { SPD_UI_WINDOW,          $

              name: '',               $ ; name for this window
              id: 0,                  $ ; unique identifier for this window
              nRows: 0,               $ ; number of rows
              nCols: 0,               $ ; number of columns
              isActive: 0,            $ ; flag if window is displayed
              locked:0,               $ ; Indicates which panel the window is locked to
              panels: Obj_New(),      $ ; panel objects on this window
              settings: Obj_New(),    $ ; properties of this window
              panelId: 0,             $ ; current value of panelId
              varOptionsPanel: 0,  $ ; currently selected panel in var options
              tracking: 0,            $ ; flag set if tracking is on
              origsettings:ptr_new(), $ ; private field used by the save/reset methods
              INHERITS SPD_UI_READWRITE, $; generalized read/write methods
              inherits spd_ui_getset $ ; generalized setProperty/getProperty/getAll/setAll methods
                                     
}

END
