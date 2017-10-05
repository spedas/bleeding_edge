;+
;Procedure:
;  spd_cotrans_validate_transform
;
;Purpose:
;  Helper function to call when moving to/from non-inertial frames.
;  A warning is printed if the variables metadata denotes it as a velocity.
;
;Notes:
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-12-08 21:21:58 -0800 (Tue, 08 Dec 2015) $
;$LastChangedRevision: 19549 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/spd_cotrans_validate_transform.pro $
;-

pro spd_cotrans_validate_transform, in_name, in_coord, out_coord

    compile_opt idl2, hidden

get_data, in_name, dlimit = dl

if is_struct(dl) && in_set(strlowcase(tag_names(dl)),'data_att') && $
   in_set(strlowcase(tag_names(dl.data_att)),'st_type') && $ 
   strlowcase(dl.data_att.st_type) eq 'vel' then begin

  dprint, 'Warning: Transforming '+in_name+' from '+strupcase(in_coord)+' to '+strupcase(out_coord)+' coordinates can produce invalid results'

endif

end