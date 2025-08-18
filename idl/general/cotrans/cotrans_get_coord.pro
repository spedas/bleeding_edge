;+
;	Function: COTRANS_GET_COORD
;
;	Purpose:  determine the coordinate system of data by 
;                 examining the contents of it's DLIMIT structure.
;
;	Calling Sequence:
;		tplot_var = 'tha_eff'
;		get_data, tplot_var, data=d, limit=l, dlimit=dl
;		coord = cotrans_get_coord( dl) 
;               ; -- or --
;               coord = cotrans_get_coord('tha_eff')
;
;	Arguements:
;		DL, Anonymous STRUCT, or tplot variable name.
;
;	Notes:
;		None.
;
; $LastChangedBy: kenb-mac $
; $LastChangedDate: 2007-05-01 15:11:55 -0700 (Tue, 01 May 2007) $
; $LastChangedRevision: 622 $
; $URL $
;-

function cotrans_get_coord, dl

mydl=dl

res = 'unknown'
if (size(dl, /type) eq 7) then begin
   dl_name = dl
   get_data, dl_name, dl=mydl
endif

if (size( mydl, /type) eq 8) then begin
   ; read tag dl.data_att.data_type without bombing if tag does not exist!
   str_element, mydl, 'data_att', data_att, success=has_data_att
   if has_data_att then begin
      str_element, data_att, 'coord_sys', res, success=has_coord_sys
      if has_coord_sys then begin
         res = strlowcase(res)
      endif 
   endif
endif

return, res
end
