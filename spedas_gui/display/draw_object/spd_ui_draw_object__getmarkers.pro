;+
;spd_ui_draw_object method: GetMarkers
;
;Returns the marker or list of markers that were created
;by the most recent markeron/markeroff call
;if no markers available, returns 0
;Output:
; an array of structs of the form
;{idx:0,marker:obj_new('spd_ui_marker')}
;idx is index of the panel the marker is on, this is the index into the list of panels in the IDL_Container on the window, not the ID field of the panel
;the object is the marker, with correct default settings and range
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getmarkers.pro $
;-

function spd_ui_draw_object::getMarkers

  compile_opt idl2,hidden
  
  if ~ptr_valid(self.currentMarkers) then return,0
  
  markerStruct = {idx:0,marker:obj_new()}
  
  markers = replicate(markerStruct,n_elements(*self.currentMarkers))
  
  for i = 0,n_elements(markers)-1 do begin
    markers[i].marker = ((*self.currentMarkers)[i])->copy()
  endfor
  
  markers[*].idx = *self.markerIdx
  
  return,[markers]
  
end
