;+
;	Function: COTRANS_SET_COORD
;
;	Purpose:  set the coordinate system of data by 
;                 setting the data_att structure of its DLIMIT structure.
;
;	Calling Sequence:
;		tplot_var = 'tha_eff'
;		get_data, tplot_var, data=d, limit=l, dlimit=dl
;		coord = cotrans_set_coord, dl, 'gei'
;		store_data, tplot_var, data=d, limit=l, dlimit=dl
;
;	Arguements:
;		DL, Anonymous STRUCT.
;
;	Notes:
;		None.
;
; $LastChangedBy: kenb-mac $
; $LastChangedDate: 2007-08-01 22:08:30 -0700 (Wed, 01 Aug 2007) $
; $LastChangedRevision: 1318 $
; $URL $
;-

pro cotrans_set_coord, dl, coord

if n_params() eq 1 then coord = 'unknown'

if (size( dl, /type) eq 8) then begin
   ;; set tag dl.data_att.coord_sys without bombing if data_att does not exist
   str_element, dl, 'data_att', data_att, success=has_data_att
   if has_data_att then begin
      str_element, data_att, 'coord_sys', coord, /add
   endif else data_att = { coord_sys:coord}
   str_element, dl, 'data_att', data_att, /add
endif else dl={data_att:{coord_sys:coord}}

end
