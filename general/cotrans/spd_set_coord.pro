;+
;Procedure:
;  spd_set_coord
;
;Purpose:
;  Set coordinates of tplot variable
;
;Calling Sequence:
;  spd_set_coord, tplotnames, coord
;
;Input:
;  tplotnames:  List of tplot variables
;  coord:  New coordinate system, e.g. 'gse', 'gsm'
;          If not defined "unknown" will be used
;
;Output:
;  none, alters dlimits.data_att.coord_sys
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-25 18:14:39 -0700 (Wed, 25 May 2016) $
;$LastChangedRevision: 21213 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/spd_set_coord.pro $
;-
pro spd_set_coord, tplotnames, coord_in

    compile_opt idl2, hidden


;don't change everything!
if undefined(tplotnames) then return

;set explicitly, otherwise will be set in loop anyway
coord = undefined(coord_in) ? 'unknown' : coord_in

names = tnames(tplotnames)

for i=0, n_elements(names)-1 do begin

  if names[i] eq '' then continue

  get_data, names[i], dlim=dl

  cotrans_set_coord, dl, coord

  store_data, names[i], dlim=dl

endfor

end
