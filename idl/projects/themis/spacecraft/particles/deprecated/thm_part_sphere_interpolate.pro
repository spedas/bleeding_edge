;+
;PROCEDURE: thm_part_sphere_interpolate
;PURPOSE:  Interpolate particle data to match the look direcitons of another distribution
;
;INPUTS:
;  source: A particle dist_data structure to be modified by interpolation to match target
;  target: A particle dist_data structure whose look directions will be matched
;  
;OUTPUTS:
;   Replaces source with a spherically interpolated target
;
;KEYWORDS: 
;  error: Set to 1 on error, zero otherwise
;  
; NOTES:
;   #1 Interpolation done using IDL library routine "griddata"
;   
;   #2 This code assumes that source & target have been time interpolated to match each other 
;   
;   This has a ton of TBDs, we need to come back and fix them when time is available.  With TBDs this code will not have general purpose utility...
; SEE ALSO:
;   thm_part_dist_array, thm_part_smooth, thm_part_subtract,thm_part_omni_convert,thm_part_time_interpolate.pro
;
;  $LastChangedBy: jimm $
;  $LastChangedDate: 2017-10-02 11:19:09 -0700 (Mon, 02 Oct 2017) $
;  $LastChangedRevision: 24078 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/deprecated/thm_part_sphere_interpolate.pro $
;-


pro thm_part_sphere_interpolate,source,target,error=error,_extra=ex

  compile_opt idl2

  error = 1
  
  ;input validation TBD
  
  ;The total number of dist structures in source & target will match after time interpolation
  ;but the total number of modes will probably be different
  
  ;Check to verify statement above TBD
   
  ;these loops are gonna be awful....need loop variables operating in tandem...not each index will increment during each iteration.
  ;Effectively, they're performing an intersection/merge on the mode data.  
  s = 0
  t= 0

  ;create output, it needs the modes of source, but the angles of target, this means that the output can have more mode ptrs than both the source and the target 
  while (s lt n_elements(source) && t lt n_elements(target)) do begin
    output_template = (*source[s])[0] 
    source_dim = dimen((*source[s])[0].data) ;energies from source
    target_dim = dimen((*target[t])[0].data) ;angles from target
    
    ;create output arrays
    ;assumes no energy variance...assumption is false...better treatment TBD
    output_theta = (fltarr(source_dim[0])+1)# (*target[t])[0].theta[0,*]
    output_phi = (fltarr(source_dim[0])+1) # (*target[t])[0].phi[0,*]
    output_dtheta = (fltarr(source_dim[0])) # (*target[t])[0].dtheta[0,*]
    output_dphi = (fltarr(source_dim[0])+1) # (*target[t])[0].dphi[0,*]
    output_data = (fltarr(source_dim[0])) # (*target[t])[0].data[0,*]
    output_energy = (fltarr(source_dim[0])) # (*target[t])[0].energy[0,*]
    output_denergy =  (fltarr(source_dim[0])) # (*target[t])[0].denergy[0,*]
    output_bins = (fltarr(source_dim[0])) # (*target[t])[0].bins[0,*]
    
    ;need to grid bins
    
    ;other multi-dim parameters in dist TBD
    
    ;add output arrays to template
    str_element,output_template,'theta',output_theta,/add_replace
    str_element,output_template,'phi',output_phi,/add_replace
    str_element,output_template,'dtheta',output_dtheta,/add_replace
    str_element,output_template,'dphi',output_dphi,/add_replace
    str_element,output_template,'data',output_data,/add_replace
    str_element,output_template,'energy',output_energy,/add_replace
    str_element,output_template,'denergy',output_denergy,/add_replace  
    str_element,output_template,'bins',output_bins,/add_replace
      
    ;find time ranges for current modes
    source_time_range = [min((*source[s]).time),max((*source[s]).end_time)]
    target_time_range = [min((*target[t]).time),max((*target[t]).end_time)]
    
    output_time_range = [source_time_range[0] > target_time_range[0],source_time_range[1] < target_time_range[1]]
    
    ;find the indexes for current modes
    source_idx = where((*source[s]).time ge output_time_range[0] and (*source[s]).end_time le output_time_range[1],source_c)
    target_idx = where((*target[t]).time ge output_time_range[0] and (*target[t]).end_time le output_time_range[1],target_c)
    
    ;no overlap or mismatched modes and...we've got a problem
    if source_c eq 0 || target_c eq 0 || source_c ne target_c then begin
      message,"WARNING No mode overlap, suggests problem with time interpolation, or absence of time interpolation" ;this will halt the program
      ;TBD: non-halting error mode
      ;dprint,"WARNING No mode overlap, suggests problem with time interpolation, or absence of time interpolation",dlevel=1
      ;return
    endif

    source_dists = (*source[s])[source_idx]
    target_dists = (*target[t])[target_idx]
   
    output_dists = replicate(output_template,target_c)
    output_dists.time = source_dists.time ;copy over times
    output_dists.end_time = source_dists.end_time

    ;TBD throw out disabled bins?
    
    method = "Linear"
    
    ;generate interpolated data
    for k = 0,target_c-1 do begin ;loop over time samples in overlap region of source & target modes
      
      ;Create a (required) spherical triangulation
      ;for ESA & SST this triangulation is invariant across energy, even if the angles themselves may change across energy
      
      ;can't construct a triangulation over a single point
      if n_elements(source_dists[k].phi[0,*]) gt 1 then begin
        qhull,source_dists[k].phi[0,*],source_dists[k].theta[0,*],triangles,sphere=dummy
      endif
      
      for l = 0,source_dim[0]-1 do begin ; loop over energy
        if n_elements(source_dists[k].phi[0,*]) gt 1 then begin
          output_dists[k].data[l,*] = griddata(source_dists[k].phi[l,*],source_dists[k].theta[l,*],source_dists[k].data[l,*],/sphere,xout=output_phi[l,*],yout=output_theta[l,*],/degrees,method=method,triangles=triangles) ;the actual spherical interpolation occurs here
          output_dists[k].energy[l,*] = griddata(source_dists[k].phi[l,*],source_dists[k].theta[l,*],source_dists[k].energy[l,*],/sphere,xout=output_phi[l,*],yout=output_theta[l,*],/degrees,method=method,triangles=triangles) ;the actual spherical interpolation occurs here
          output_dists[k].bins[l,*] = round(griddata(source_dists[k].phi[l,*],source_dists[k].theta[l,*],source_dists[k].bins[l,*],/sphere,xout=output_phi[l,*],yout=output_theta[l,*],/degrees,method=method,triangles=triangles)) >0<1 ;the actual spherical interpolation occurs here
        endif else begin
          output_dists[k].data[l,*] = source_dists[k].data[l]
          output_dists[k].energy[l,*] = source_dists[k].energy[l]
          output_dists[k].bins[l,*] = source_dists[k].bins[l]
        endelse
      endfor
      ;generate d-energy at new angles
      for l = 0,target_dim[1]-1 do begin
        output_dists[k].denergy[0,l] = output_dists[k].denergy[0,l] ;special case from retrace bin...TBD, this is not general...needs to happen elsewhere
        output_dists[k].denergy[1:source_dim[0]-1,l] = deriv(output_dists[k].energy[1:source_dim[0]-1,l]) ;deriv without retrace bin...TBD, this is not general...needs to happen elsewhere
      endfor 
    endfor

    ;temporary routine bombs on some machines if out_dist is undefined, but not others
    if ~undefined(output) then begin
      ;add new output mode to the output data structure
      output = array_concat(ptr_new(output_dists,/no_copy),temporary(output))
    endif else begin
      output = array_concat(ptr_new(output_dists,/no_copy),output)
    endelse
     
;TBD, use something like this:
;less stringent version of overlap checking(works off range instead of overlap indexes)  
;    ;determine if/how the modes overlap
;    if (source_time_range[1] lt target_time_range[0]) then begin
;      s++
;      dprint,"WARNING No mode overlap, suggests problem with time interpolation, or absence of time interpolation",dlevel=1
;      continue
;    endif else if (target_time_range[1] lt source_time_range[0]) then begin
;      t++
;      dprint,"WARNING No mode overlap, suggests problem with time interpolation, or absence of time interpolation",dlevel=1
;      continue
;    endif else 
    
    ;increment mode variables based on pattern of the mode overlap
    if (target_time_range[1] eq source_time_range[1]) then begin
      s++
      t++
    endif else if (source_time_range[1] lt target_time_range[1]) then begin
      s++
    ;endif else if (target_time_range lt source_time_range[1]) then begin ;last case is implied, this commented line just illustrates the invariant which holds in the else case
    endif else begin 
      t++
    endelse
    
  endwhile  
  
  source = temporary(output)
  heap_gc ; remove pointers whose references were just deleted
  
  error = 0

end
