;+
;PROCEDURE: thm_sst_energy_extrapolate
;PURPOSE:  Performs linear extrapolation of sst data to a new set of lower energies
;
;INPUTS:
;  dist_data:
;    The sst data structure on which the extrapolation should be performed.  (loaded by thm_part_dist_array)
;KEYWORDS:
;
;  add_energy=add_energy : Adds these energies to the current set of energies for the particle data when extrapolating.  
;  lin_energy=lin_energy : Set this keyword to perform extrapolation on energy, not logarithmic.
;  lin_counts=lin_counts: Set this keyword to perform extrapolation on counts, not logarithmic
;  lsquadratic=lsquadratic: Set this keyword to perform least square quadratic extrapolation of count data(see interpol documentation in IDL help.)
;  quadratic=quadratic: Set this keyword to perform quadratic extrapolation of count data.(see interpol documentation in IDL help.)
;  lsquares=lsquares: Set this keyword to the number of bins that you want to use for least squares extrapolation of the count data(Uses poly_fit)
;  spline=spline: Set this keyword to perform spline extrapolation of count data.(see interpol documentation in IDL help.)
;  trange=trange: Set this keyword to a two element array specifying a subset of the data that the operation should be performed on.(Don't need to modify the whole thing with the same parameters)
;  error=error:  Returns 1 if an error occurred.  Returns 0 if operation completed successfully.
;  
;  
;  bin_select: set the bin numbers that you want to use in the extrapolation
;EXAMPLES:
; dist_data = thm_part_dist_array(probe='a',type='psef',trange=time_double(['2012-02-08/09','2012-02-08/12']))
; thm_part_conv_units,dist_data,error=e
; thm_esa_energy_extrapolate,dist_data,add_energy=[5000,7000,10000]
;
; NOTES:
;
;  $LastChangedBy: pcruce $
;  $LastChangedDate: 2012-12-13 16:23:14 -0800 (Thu, 13 Dec 2012) $
;  $LastChangedRevision: 11355 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_energy_extrapolate.pro $
;-

pro thm_sst_energy_extrapolate,dist_data,add_energy,lin_energy=lin_energy,lin_counts=lin_counts,lsquadratic=lsquadratic,quadratic=quadratic,spline=spline,lsquares=lsquares,error=error,bin_select=bin_select

  error = 1

  if size(dist_data,/type) ne 10 then begin
    dprint,dlevel=1,"ERROR: dist_data undefined or has wrong type"
    return
  endif

  if keyword_set(lsquares) && ~is_num(lsquares) then begin
    dprint,dlevel=1,"ERROR: lsquares is set but is not of type number"
    return
  endif

  for i = 0,n_elements(dist_data)-1 do begin
    str_template=(*dist_data[i])[0]
    
    str_energy_dim = dimen(str_template.energy)
   
   
    ;create source target
    energy_target = str_template.energy[0:str_energy_dim[0]-1,0]
    energy_source = str_template.energy[0:str_energy_dim[0]-1,*]
   
    energy_target = [add_energy[bsort(add_energy)],energy_target]
      
    ;Just uses a trick, uses the matrix multiply with an array of ones to create a two dim array with repeated rows(or cols, depending on your notation) from the linear array
    new_energy_arr = energy_target#(dblarr(str_energy_dim[1])+1)
    new_denergy_arr = [(abs(deriv(energy_target)))[0:n_elements(add_energy)-1],str_template.denergy[0:str_energy_dim[0]-1,0]]#(dblarr(str_energy_dim[1])+1) ;very quick and very dirty delta-energies
    
    new_energy_dim = dimen(new_energy_arr)
    str_template.nenergy = new_energy_dim[0]
  
    str_element,str_template,'energy',new_energy_arr,/add_replace
    str_element,str_template,'denergy',new_denergy_arr,/add_replace
   
    tag_names=tag_names(str_template)
  
    for j=0,n_elements(tag_names)-1 do begin
    
      ;these are special cases, so we skip them. 
      if strlowcase(tag_names[j]) ne 'energy' and $
         strlowcase(tag_names[j]) ne 'denergy'and $
         strlowcase(tag_names[j]) ne 'nenergy' then begin
         
         tag_dimen=dimen(str_template.(j))
         
         if array_equal(tag_dimen,str_energy_dim) then begin
         
           new_data_arr = dblarr(new_energy_dim)
           str_element,str_template,tag_names[j],new_data_arr,/add_replace
         endif else begin
           str_element,str_template,tag_names[j],(*dist_data[i])[0].(j)
         endelse
      endif
    endfor
    
    out_data = replicate(str_template,n_elements(*dist_data[i]))
    
    ;take log of target & source data if requested, makes subsequent fitting code a little easier
    if ~keyword_set(lin_energy) then begin
      energy_target=alog(energy_target)
      energy_source=alog(energy_source)
    endif
  
  
    ;loop over distributions
    for j = 0,n_elements(out_data)-1 do begin
    
       for k=0,n_elements(tag_names)-1 do begin
    
        ;these are special cases, so we skip them. 
        if strlowcase(tag_names[k]) ne 'energy' and $
           strlowcase(tag_names[k]) ne 'denergy'and $
           strlowcase(tag_names[k]) ne 'nenergy'and $
           strlowcase(tag_names[k]) ne 'data' then begin
           
           tag_dimen=dimen(str_template.(k))
           
           if array_equal(tag_dimen,new_energy_dim) then begin
           
             new_data_arr = dblarr(new_energy_dim)
             new_data_arr[n_elements(add_energy):new_energy_dim[0]-1,*] = (*dist_data[i])[j].(k)[0:str_energy_dim[0]-1,*]
             new_data_arr[0:n_elements(add_energy)-1,*] = (dblarr(n_elements(add_energy))+1)#(*dist_data[i])[j].(k)[0,*]
             out_data[j].(k) = new_data_arr
           endif else begin
             out_data[j].(k) = (*dist_data[i])[j].(k)
           endelse
        endif
      endfor
      
      source_data = (*dist_data[i])[j].data[0:str_energy_dim[0]-1,*]
      source_bins = (*dist_data[i])[j].bins[0:str_energy_dim[0]-1,*]        
        
      for k = 0,str_energy_dim[1]-1 do begin
        source_dim = dimen(source_data)
        if ~keyword_set(lsquares) then begin
          if ~keyword_set(lin_counts) then begin
            ;throw out disabled bins and zero bins during log extrapolation
            idx = where(source_bins[*,k] and source_data[*,k] gt 0,c) 
            if c eq 0 then continue
             
            out_data[j].data[*,k] = exp(interpol(alog(source_data[idx,k]),energy_source[idx,k],energy_target,lsquadratic=lsquadratic,quadratic=quadratic,spline=spline))
          endif else begin
            ;throw out disabled bins during extrapolation
            idx = where(source_bins[*,k],c) 
            if c eq 0 then continue 
            
            out_data[j].data[*,k] = interpol(source_data[idx,k],energy_source[idx,k],energy_target,lsquadratic=lsquadratic,quadratic=quadratic,spline=spline)
          endelse
        endif else begin
          fit_use_bins=dindgen(lsquares < source_dim[0])
          if ~keyword_set(lin_counts) then begin
            idx = where(source_bins[fit_use_bins,k] and source_data[fit_use_bins,k] gt 0,c)
            if c eq 0 then continue
            ;note that status keyword needs to be set, even if unused, so that singular matrixes will not cause program halt
            fit = poly_fit(energy_source[fit_use_bins[idx],k],alog(source_data[fit_use_bins[idx],k]),1,/double,status=s)
            if s ne 0 then continue
            out_data[j].data[dindgen(n_elements(add_energy)),k] = exp(fit[0]+fit[1]*energy_target[dindgen(n_elements(add_energy))])
          endif else begin
            idx = where(source_bins[fit_use_bins,k],c)
            if c eq 0 then continue
            ;note that status keyword needs to be set, even if unused, so that singular matrixes will not cause program halt
            fit = poly_fit(energy_source[fit_use_bins[idx],k],source_data[fit_use_bins[idx],k],1,/double,status=s)
            if s ne 0 then continue
            out_data[j].data[dindgen(n_elements(add_energy)),k] = fit[0]+fit[1]*energy_target[dindgen(n_elements(add_energy))]
          endelse
        endelse  
        out_data[j].data[dindgen(source_dim[0])+n_elements(add_energy),k] = source_data[*,k]
      endfor
    endfor
    *dist_data[i] = out_data
  endfor

end