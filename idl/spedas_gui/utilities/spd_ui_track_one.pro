;+
;Procedure:
;  spd_ui_track_one
;
;Purpose:
;  Switches on single-panel tracking by setting the appropriate flags
;  in the GUI's main storage structure.  This is a temporary solution
;  until the tracking options can be re-worked. 
;
;Calling Sequence:
;  spd_ui_track_one, info_struct
;
;Input:
;  info_struct:  The GUI's main storage structure.
;
;Output:
;  none
;
;Notes:
;  Moved from call sequence object.
;    5/5/2014: Changed input argument from pointer to the main GUI's info struct to the actual struct. 
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;
;-
pro spd_ui_track_one, info_struct

  if ~undefined(info_struct) && is_struct(info_struct) then begin
      info_struct.tracking = 1
      info_struct.trackall = 0
      info_struct.trackone = 1
      info_struct.trackingv = 1
      info_struct.trackingh = 1
      info_struct.drawObject->vBarOn
      info_struct.drawObject->hBarOn
      info_struct.drawObject->legendOn
      widget_control, info_struct.trackhmenu, set_button=1
      widget_control, info_struct.trackvmenu, set_button=1
      widget_control, info_struct.trackallmenu, set_button=0
      widget_control, info_struct.trackonemenu, set_button=1
      widget_control, info_struct.showpositionmenu,set_button=1
      widget_control, info_struct.trackMenu,set_button=1
  endif

end
