;+
;
;spd_ui_draw_object method: setProperty
;
;Set a couple of properties related to drawing
;Mainly used to perform output to other devices
;
;Destination:
;  The target to which draws will be made.  
;  Some parameters used in updated are also drawn from the destination.
;  This should be some sort of IDLgr* destination object.
;
;LineRes: 
;  The resolution at which lines will be drawn.  
;  Ideally, this is a scalar multiple of the current screen resolution.
;  (ie plot with 500 pixel width, and lineRes 2 will send 1000 points to the output destination)
;  Line resolution modification is currently limited by aliasing issues. So it is ignored in the current version
;  and all line plots send every point to the output destination.
;  
;SpecRes:
;  The resolution at which spectral plots will be drawn. 
;  SpecRes is a multiple of screen resolution.  If specRes is 2
;  and a plot has a screen resolution of 400x300 pixels, a spectral
;  plot of 800x600 will be output to the destination.
;  
;HistoryWin:
;  The history object that the draw object sends its history output to.
;
;statusBar:
;  The status bar object that the draw object sends status messages to.
;  
;fancompressionfactor:
;  The percentage error to be applied to the fancompression algorithm during postscript plotting.
;  0 = No compression
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__setproperty.pro $
;-
pro spd_ui_draw_object::setProperty,destination=destination,lineres=lineres,specres=specres,historyWin=historyWin,statusBar=statusBar,fancompressionfactor=fancompressionfactor

  compile_opt idl2,hidden
  
  if n_elements(destination) gt 0 then begin
    if ~obj_valid(destination) then begin
      self.statusBar->update,'Error: Invalid destination object passed to spd_ui_draw_object'
      ;t=error_message('Invalid destination object passed to spd_ui_draw_object',/traceback)
      return
    endif else begin
      ;self->removeInstance
      self.destination = destination
      ;self->createInstance
    endelse
  endif
  
  if n_elements(lineres) gt 0 then begin
    self.lineres=lineres
  endif
  
  if n_elements(specres) gt 0 then begin
    self.specres = specres
  endif

  if n_elements(historyWin) && obj_valid(historyWin) then begin
    self.historyWin = historyWin
  endif

  if n_elements(statusBar) && obj_valid(statusBar) then begin
    self.statusBar = statusBar
  endif
  
  if n_elements(fancompressionfactor) gt 0 then begin
    self.fancompressionfactor = fancompressionfactor
  endif
end
