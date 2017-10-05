;+
;Purpose:
;  Helper function to store single array from specified
;  structure tag as tplot variable(s)
;
;Arguments:
;  ptr:  pointer to array of data structures
;  name:  string of structure tag to use
;  prefix:  string prefix of tplot var(s) to be created  
;
;-
pro thm_esa_dump_tplot, ptr, name, prefix, _extra=_extra

    compile_opt idl2, hidden

  ;get copy of data from specified tag
  str_element, *ptr, name, data

  dim = size(data,/dim)

  ; use single tplot var if possible 
  ; otherwise, make var for each energy
  if n_elements(dim) le 2 then begin
    
    ; time must be first dimension
    if n_elements(dim) eq 2 then begin
      data = transpose(data)
    endif
    
    store_data, prefix+strlowcase(name), data = {x:(*ptr).time, y:data}

  endif else begin

    ; time must be first dimension
    data = transpose(data)
    
    ;energy should still be 2nd dimension
    for i=0, dim[1]-1 do begin
      store_data, prefix+strlowcase(name)+'_e'+strtrim(i+1,2), $
                  data = { x:(*ptr).time, y:reform(data[*,i,*]) }
    endfor
  
  endelse

end



;+
;Procedure:
;  thm_esa_dump
;
;Purpose: (FOR TESTING ONLY)
;  Load ESA packet data then retrieve 3D structures and 
;  dump raw data into tplot variables.  Each structure 
;  tag containting numerical data will be placed in a 
;  unique tplot variable.  Arrays with >2 dimensions 
;  (including time) will be split into multiple variables
;  across energy.
;  
;  Created tplot variable names will be of the form:
;  "<datatype>_<custom tag>_<mode change index>_<variable/structure tag>_<energy index>"
;
;    e.g. peer_control_0_phi_e1   (peer phi bins for first energy, no mode changes) 
;
;
;Input Keywords:
;  probe:  string denoting probe (e.g. 'a', 'b')
;  trange:  two element array containing the numerical time range (double)
;  datatype:  string denoting data type (e.g. 'peer', 'peif')
;  tags:  string array of particular tags to use, 
;           all tags not matched to this list will be ignored
;  prefix:  string inserted into tplot var to tag variables from a 
;        particular run
;
;Output Keywords:
;  pa:  pointer array to data that was loaded
;
;+
pro thm_esa_dump, probe=probe, trange=trange, datatype=datatype, $
                  tags=tags, prefix=prefix, pa=pa

    compile_opt idl2


  ;allow data to be tagged with keyword
  prefix = keyword_set(prefix) ? prefix:''
  
  
  ;get pointer array to distribution arrays 
  ;this will automatically load the packet data
  pa = thm_part_dist_array(probe=probe, trange=trange, datatype=datatype)

  if ~ptr_valid(pa[0]) then begin
    print, 'ERROR: No data returned!'
    return
  endif
  
  ;loop over mode changes (new element in ptr array for each mode change)
  for i=0, n_elements(pa)-1 do begin
  
  
    pfx = prefix + datatype + '_' + strtrim(i,2) + '_' ;naming prefix
  
    tn = strlowcase(tag_names(*pa[i])) ;get tags from structure

    
    ;dump all numerical tags to tplot vars
    for j=0, n_elements(tn)-1 do begin
    
      ; data types should all be float, hence this coarse check
      if size( (*pa[i]).(j), /type ) ge 6 then continue
    
      ; use only specified tags
      if keyword_set(tags) then begin
        if ~in_set(tn[j],tags) then continue        
      endif
    
      ; call helper to creat tplot var(s)
      thm_esa_dump_tplot, pa[i], tn[j], pfx
    
    endfor    

  
  endfor
  
end

