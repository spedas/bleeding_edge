;+
;Procedure:
;  spd_cotrans_update_dlimits
;
;Purpose:
;  This routine will replace coordinate plot labels only in the dlimits.
;  If the coordinate name is clearly delineated, so that it will not 
;  accidentally modify substrings that look like coordinate names  
;
;Notes:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-10-27 12:25:53 -0700 (Thu, 27 Oct 2016) $
;$LastChangedRevision: 22221 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/spd_cotrans_update_dlimits.pro $
;-

pro spd_cotrans_update_dlimits,out_name,in_coord,out_coord

    compile_opt idl2, hidden

get_data, out_name, dlimit = dl

if ~is_struct(dl) then return

if in_set(strlowcase(tag_names(dl)),'ytitle') then begin
  type1 = stregex(dl.ytitle,'[^a-zA-Z]'+in_coord+'[^a-zA-Z]',/fold_case)
  type2 = stregex(dl.ytitle,'^'+in_coord+'[^a-zA-Z]',/fold_case)
  type3 = stregex(dl.ytitle,'[^a-zA-Z]'+in_coord+'$',/fold_case)
  type4 = stregex(dl.ytitle,'^'+in_coord+'$',/fold_case)
  if type1 ne -1 then begin
    dl.ytitle = strmid(dl.ytitle,0,type1+1) + out_coord + strmid(dl.ytitle,type1+strlen(in_coord)+1,strlen(dl.ytitle)-(type1+strlen(in_coord)+1))
  endif else if type2 ne -1 then begin
    dl.ytitle = out_coord + strmid(dl.ytitle,strlen(in_coord),strlen(dl.ytitle)-strlen(in_coord))
  endif else if type3 ne -1 then begin
    dl.ytitle = strmid(dl.ytitle,0,type3+1) + out_coord
  endif else if type4 ne -1 then begin
    dl.ytitle = out_coord
  endif
endif

if in_set(strlowcase(tag_names(dl)),'ysubtitle') then begin
  type1 = stregex(dl.ysubtitle,'[^a-zA-Z]'+in_coord+'[^a-zA-Z]',/fold_case)
  type2 = stregex(dl.ysubtitle,'^'+in_coord+'[^a-zA-Z]',/fold_case)
  type3 = stregex(dl.ysubtitle,'[^a-zA-Z]'+in_coord+'$',/fold_case)
  type4 = stregex(dl.ysubtitle,'^'+in_coord+'$',/fold_case)
  if type1 ne -1 then begin
    dl.ysubtitle = strmid(dl.ysubtitle,0,type1+1) + out_coord + strmid(dl.ysubtitle,type1+strlen(in_coord)+1,strlen(dl.ysubtitle)-(type1+strlen(in_coord)+1))
  endif else if type2 ne -1 then begin
    dl.ysubtitle = out_coord + strmid(dl.ysubtitle,strlen(in_coord),strlen(dl.ysubtitle)-strlen(in_coord))
  endif else if type3 ne -1 then begin
    dl.ysubtitle = strmid(dl.ysubtitle,0,type3+1) + out_coord
  endif else if type4 ne -1 then begin
    dl.ysubtitle = out_coord
  endif
endif

if in_set(strlowcase(tag_names(dl)),'labels') then begin
  nl = n_elements(dl.labels)
  for k = 0, nl-1 do begin
    type1 = stregex(dl.labels[k], '[^a-zA-Z]'+in_coord+'[^a-zA-Z]', /fold_case)
    type2 = stregex(dl.labels[k], '^'+in_coord+'[^a-zA-Z]', /fold_case)
    type3 = stregex(dl.labels[k], '[^a-zA-Z]'+in_coord+'$', /fold_case)
    type4 = stregex(dl.labels[k], '^'+in_coord+'$', /fold_case)
    if type1 ne -1 then begin
      dl.labels[k] = strmid(dl.labels[k], 0, type1+1) + strupcase(out_coord) + strmid(dl.labels[k], type1+strlen(in_coord)+1, strlen(dl.labels[k])-(type1+strlen(in_coord)+1))
    endif else if type2 ne -1 then begin
      dl.labels[k] = strupcase(out_coord) + strmid(dl.labels[k], strlen(in_coord), strlen(dl.labels[k])-strlen(in_coord))
    endif else if type3 ne -1 then begin
      dl.labels[k] = strmid(dl.labels[k], 0, type3+1) + strupcase(out_coord)
    endif else if type4 ne -1 then begin
      dl.labels[k] = strupcase(out_coord)
    endif
  endfor
endif

store_data,out_name,dlimit=dl

end