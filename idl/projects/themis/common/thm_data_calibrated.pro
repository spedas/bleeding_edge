;+
;	Function: THM_DATA_CALIBRATED
;
;	Purpose:  Determine whether the data stored in a particular TPLOT variable has already been calibrated by examining the contents of it's DLIMIT structure.
;
;	Calling Sequence:
;		tplot_var = 'tha_eff'
;		get_data, tplot_var, data=d, limit=l, dlimit=dl
;		if thm_data_calibrated( dl) then return
;               ; -- or --
;               if thm_data_calibrated('tha_eff') then return
;
;	Arguements:
;		DL, Anonymous STRUCT or tplot varaible name
;
;	Notes:
;		None.
;
; $LastChangedBy: kenb-mac $
; $LastChangedDate: 2007-05-02 17:25:43 -0700 (Wed, 02 May 2007) $
; $LastChangedRevision: 629 $
; $URL $
;-

function thm_data_calibrated, dl

res = 0b
if (size(dl, /type) eq 7) then begin
   dl_name = dl
   get_data, dl_name, dl=mydl
endif else mydl=dl

if (size( mydl, /type) eq 8) then begin
   ; read tag mydl.data_att.data_type without bombing if tag does not exist!
   str_element, mydl, 'data_att', data_att, success=has_data_att
   if has_data_att then begin
      str_element, data_att, 'data_type', data_type, success=has_data_type
      if has_data_type then begin
         if data_type eq 'calibrated' then res = 1b
      endif 
   endif
endif

return, res
end
