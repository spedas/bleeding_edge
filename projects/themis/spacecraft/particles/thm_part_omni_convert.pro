;+
;PROCEDURE: thm_part_omni_convert
;PURPOSE:  Converts a particle distribution to omni directional by summing over angle.
;
;INPUTS:
;  dist_data:
;   A single particle distribution structure, or a particle distribution array from thm_part_dist_array
;OUTPUTS:
;   Replaces dat with an omni summed particle distribution structure, or a particle distribution array from thm_part_dist_array
;
;Keywords: 
;  error: Set to 1 on error, zero otherwise
;
; NOTES:
;
;  $LastChangedBy: pcruce $
;  $LastChangedDate: 2013-02-20 15:26:03 -0800 (Wed, 20 Feb 2013) $
;  $LastChangedRevision: 11594 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_omni_convert.pro $
;-


;helper function performs transformation for a single structure
function thm_part_omni_convert_struct,dist_data_in

  compile_opt idl2,hidden
     
  dist_data_out=dist_data_in
  
  if dist_data_in.nbins le 1 then return,dist_data_out
  
  tg_names = tag_names(dist_data_out)
  
  str_element,dist_data_out,'data',dblarr(dimen(dist_data_in.data)),/add_replace
  
  if strlowcase(dist_data_in.units_name) eq 'eflux' then begin
    scale = dist_data_in.bins
  endif else if strlowcase(dist_data_in.units_name) eq 'counts' then begin
    ;calculation should capture angle varying components of the calculation...maybe
    if in_set('atten',strlowcase(tg_names)) then begin ;sst
      scale = 1d/(thm_sst_atten_scale(dist_data_in.atten,dimen(dist_data_in.data))*dist_data_in.gf*dist_data_in.geom_factor*dist_data_in.eff*dist_data_in.bins)
  
    endif else begin ;esa
  
      scale = 1d/(dist_data_in.gf*dist_data_in.geom_factor*dist_data_in.eff*dist_data_in.bins)
       
    endelse
  endif else begin
    message,'ERROR: omni conversion only works with eflux or counts'
  endelse
  
  dist_data_out.data = (total(dist_data_in.data*scale,2,/nan)/(total(scale,2,/nan)))#(dblarr(dist_data_in.nbins)+1)

  
  return, dist_data_out
  
end

;helper function performs transformation for an array of structures
function thm_part_omni_convert_array,dist_data_array_in

  compile_opt idl2,hidden
  
  dist_data_out=ptrarr(n_elements(dist_data_array_in))
  
  for i = 0,n_elements(dist_data_array_in)-1 do begin
    dist_data_template = thm_part_omni_convert_struct((*dist_data_array_in[i])[0])
    if ~is_struct(dist_data_template) then return,0
    dist_data_out[i] = ptr_new(replicate(dist_data_template,n_elements(*dist_data_array_in[i])))
    for j = 0,n_elements(*dist_data_array_in[i])-1 do begin
      (*dist_data_out[i])[j] = thm_part_omni_convert_struct((*dist_data_array_in[i])[j])
    endfor  
  endfor

  return, dist_data_out

end

;main routine
pro thm_part_omni_convert,dist_data,error=error

  compile_opt idl2
  
  error=1
  
  if is_struct(dist_data) then begin
    dist_data=thm_part_omni_convert_struct(dist_data)
  endif else if size(dist_data,/type) eq 10 then begin
    dist_data=thm_part_omni_convert_array(dist_data)
  endif else begin
    dprint, 'ERROR: Incorrect type passed to thm_part_omni_convert',dlevel=0
    return
  endelse
  
  heap_gc ; remove pointers whose references were deleted
  if ~is_struct(dist_data) then return
  
  error=0
  
  return
  
end