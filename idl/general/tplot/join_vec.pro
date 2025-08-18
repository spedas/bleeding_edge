
;+
;NAME: join_vec.pro
;
;PURPOSE: Take a series of similar variables and store as a single vector;
;         e.g. one dimensional variables Vp_x, Vp_y, vp_z can be combined to
;         form a three dimensional variable Vp. 
;
;CALLING SEQUENCE:
;  join_vec, 'thm_state_pos'+['_x','_y','_z'], 'thm_state_pos_new' 
;
;ARGUMENTS:
;  NAMES: Array of tplot variable names to be joined into single variable
;  NEW_NAME: Single string containing the name of the tplot variable to be created 
;  IGNORE_DLIMITS: Set this flag to ignore warnings about dlimits (meta data)  
;
;KEYWORDS
;  display_object = Object reference to be passed to dprint for output.
;
;NOTES: Meant to compliment split_vec.pro
;
;
;-

pro join_vec, names, new_name, display_object=display_object, fail=fail, ignore_dlimits=ignore_dlimits

     compile_opt idl2


fail = 1b

if n_elements(names) lt 2 then begin
  dprint, 'Must specify at least two valid variables', display_object=display_object
  return
endif

if ~keyword_set(new_name) then begin
  dprint, 'Must specify either new name or suffix to be stripped from input names', display_object=display_object
  return
endif

nnames = n_elements(names)
missing_dl = bytarr(nnames)
missing_l = bytarr(nnames)


;simplest way to determine if data structures are compatable
catch, err
if err ne 0 then begin
  catch, /cancel
  help, /last_message, output=msg
  if stregex(msg[0],'(conflicting|structures)',/bool,/fold_case) then begin
    dprint, 'Error: Data structures do not match, variables cannot be concatenated.', display_object=display_object
    return 
  endif else begin
    message, /reissue_last
    return
  endelse
endif


;loop over variables to get data/metadata
for i=0, nnames-1 do begin

  get_data, names[i], data = d, dlimits = dl, limits=l
  
  if is_struct(d) then begin
    ds = i eq 0 ? d:[ds,d]
  endif else begin
    dprint, 'Error: "'+names[i]+'" has no valid data.', display_object=display_object
    return
  endelse
  
  if is_struct(dl) then begin
    dls = keyword_set(dls) ? [dls,dl]:dl
  endif else begin
    missing_dl[i] = 1b
  endelse
  
  if is_struct(l) then begin
    ls = keyword_set(ls) ? [ls,l]:l
  endif else begin
    missing_l[i] = 1b
  endelse

  if i gt 0 then begin
    if ~array_equal(d.x, ds[0].x) then begin
      dprint, 'Error: "'+names[i]+'" and "'+names[0]+'" have conflicting abscissa.", display_object=display_object
      return 
    endif
  endif

endfor

new_dl = 0
new_l = 0

;check and copy dlimits
if keyword_set(dls) then begin
  if n_elements(dls) eq nnames then begin
    new_dl = dls[0]

    dl_tags = strlowcase(tag_names(dls))

    if in_set(dl_tags,'labels') then begin
      str_element, new_dl, 'labels', dls.labels, /add_replace
    endif
    
    if in_set(dl_tags,'colors') then begin
      str_element, new_dl, 'colors', dls.colors, /add_replace
    endif
    
    if in_set(dl_tags,'data_att') && ~keyword_set(ignore_dlimits) then begin
      att_tags = strlowcase(tag_names(dls.data_att))
      if in_set(att_tags,'coord_sys') then begin
        if total(strlowcase(new_dl.data_att.coord_sys) eq strlowcase(dls.data_att.coord_sys)) lt nnames then begin
          dprint, 'Error: Variables have conflicting coordinate system tags.', display_object=display_object
          return
        endif
      endif
      if in_set(att_tags,'units') then begin
        if total(strlowcase(new_dl.data_att.units) eq strlowcase(dls.data_att.units)) lt nnames then begin
          dprint, 'Error: Variables have conflicting units tags.', display_object=display_object
          return
        endif
      endif
    endif
    
  endif else begin
    dprint, 'One or more variables are missing dlimits structure, dlimits will be left blank.', display_object=display_object
  endelse
endif

;check and copy limits
if keyword_set(ls) then begin
  if n_elements(ls) eq nnames then begin
    new_l = ls[0]

    l_tags = strlowcase(tag_names(ls))

    if in_set(l_tags,'labels') then begin
      str_element, new_l, 'labels', ls.labels, /add_replace
    endif
    
    if in_set(l_tags,'colors') then begin
      str_element, new_l, 'colors', ls.colors, /add_replace
    endif
  endif else begin
    dprint, 'One or more variables are missing limits structure, limits will be left blank.', display_object=display_object
  endelse
endif    

;in case of d.V element
d_tags = strlowcase(tag_names(ds))
if in_set(d_tags,'v') then begin
  new_d = {x: ds[0].x, y:ds.y, v: ds.v}
endif else begin
  new_d = {x: ds[0].x, y:ds.y}
endelse 

;store new data to tplot
store_data, new_name, data = temporary(new_d), dlimits=new_dl, limits=new_l 

fail = 0b

end