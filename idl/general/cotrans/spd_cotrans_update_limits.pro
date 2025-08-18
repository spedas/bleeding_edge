;Procedure:
;  spd_cotrans_update_limits
;
;Purpose:
;  This routine will replace coordinate plot labels only in the limits.
;  If the coordinate name is clearly delineated, so that it will not 
;  accidentally modify substrings that look like coordinate names.  
;
;Notes:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-10-27 12:25:53 -0700 (Thu, 27 Oct 2016) $
;$LastChangedRevision: 22221 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/spd_cotrans_update_limits.pro $
;-

pro spd_cotrans_update_limits,out_name,in_coord,out_coord

    compile_opt idl2, hidden

get_data, out_name, limit = al

if ~is_struct(al) then return

if in_set(strlowcase(tag_names(al)),'labels') then begin
  nl = n_elements(al.labels)
  for k = 0, nl-1 do begin
    type1 = stregex(al.labels[k], '[^a-zA-Z]'+in_coord+'[^a-zA-Z]', /fold_case)
    type2 = stregex(al.labels[k], '^'+in_coord+'[^a-zA-Z]', /fold_case)
    type3 = stregex(al.labels[k], '[^a-zA-Z]'+in_coord+'$', /fold_case)
    type4 = stregex(al.labels[k], '^'+in_coord+'$', /fold_case)
    if type1 ne -1 then begin
      al.labels[k] = strmid(al.labels[k], 0, type1+1) + strupcase(out_coord) + strmid(al.labels[k], type1+strlen(in_coord)+1, strlen(al.labels[k])-(type1+strlen(in_coord)+1))
    endif else if type2 ne -1 then begin
      al.labels[k] = strupcase(out_coord) + strmid(al.labels[k], strlen(in_coord), strlen(al.labels[k])-strlen(in_coord))
    endif else if type3 ne -1 then begin
      al.labels[k] = strmid(al.labels[k], 0, type3+1) + strupcase(out_coord)
    endif else if type4 ne -1 then begin
      al.labels[k] = strupcase(out_coord)
    endif
  endfor
endif

store_data, out_name, limit = al

end
