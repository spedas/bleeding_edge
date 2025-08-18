;+
;PROCEDURE: thm_part_sphere_interp
;
;PURPOSE: Temporary generalized copy of thm_part_sphere_interpolate  
;  (Interpolate particle data to match the look direcitons of another distribution)
;
;INPUTS:
;  source: The particle distribution to be modified by spherical interpolation.
;  target: The particle distribution to which the sources times have been matched.
;          This distribution will only be used to merge times between modes.
;  
;OUTPUTS:
;   Replaces source with a spherically interpolated version
;
;KEYWORDS: 
;  error: Set to 1 on error, zero otherwise
;  get_error: if set, interpolates scaling factor needed for error propagation
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
;  $LastChangedBy: aaflores $
;  $LastChangedDate: 2013-10-02 10:31:06 -0700 (Wed, 02 Oct 2013) $
;  $LastChangedRevision: 13173 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/themis/spacecraft/particles/thm_part_sphere_interpolate.pro $
;-


pro thm_part_sphere_interp,source,target,regrid=regrid,error=error,get_error=get_error,_extra=ex

  compile_opt idl2

  error = 1
  
  
  ;The total number of dist structures in source & target will match after time interpolation
  ;but the total number of modes will probably be different

  
  ;set up new angle grid
  ;do not duplicate points at phi=0 | 360
  ;do not allow theta=+-90 (degenerate along phi)
  phi0 = interpol([0,360],regrid[0]+1)
  phi = (phi0[0:regrid[0]-1] + phi0[1:*])/2
  theta0 = interpol([-90,90],regrid[1]+1)
  theta = (theta0[0:regrid[1]-1] + theta0[1:*])/2
  
  dphi = 360. / (regrid[0])
  dtheta = 180. / (regrid[1])
  
  phi_list = reform( phi # replicate(1,regrid[1]), regrid[0]*regrid[1] )
  theta_list = reform( theta ## replicate(1,regrid[0]), regrid[0]*regrid[1] )
  
  blankarr = replicate(0,regrid[0]*regrid[1])
  
  
  ;these loops are gonna be awful....need loop variables operating in tandem...not each index will increment during each iteration.
  ;Effectively, they're performing an intersection/merge on the mode data.  
  s = 0
  t = 0

  ;create output, it needs the modes of source, but the angles of target, this means that the output can have more mode ptrs than both the source and the target 
  while (s lt n_elements(source) && t lt n_elements(target)) do begin
    
    
    output_template = (*source[s])[0] 
    source_dim = dimen((*source[s])[0].data) ;energies from source
    target_dim = dimen((*target[t])[0].data) ;energies from source

    
    ;create output arrays
    ;assumes no energy variance...assumption is false...better treatment TBD
    output_theta = (fltarr(source_dim[0])+1) # theta_list
    output_phi = (fltarr(source_dim[0])+1) # phi_list
    output_dtheta = (fltarr(source_dim[0])+1) # (blankarr + dtheta) 
    output_dphi = (fltarr(source_dim[0])+1) # (blankarr + dphi)
    output_data = (fltarr(source_dim[0])) # blankarr
    output_scaling = (fltarr(source_dim[0])) # blankarr ;jmm, 2017-09-28
    output_energy = (fltarr(source_dim[0])) # blankarr
    output_denergy =  (fltarr(source_dim[0])) # blankarr
    output_bins = (fltarr(source_dim[0])) # blankarr
    
    ;add output arrays to template
    str_element,output_template,'theta',output_theta,/add_replace
    str_element,output_template,'phi',output_phi,/add_replace
    str_element,output_template,'dtheta',output_dtheta,/add_replace
    str_element,output_template,'dphi',output_dphi,/add_replace
    str_element,output_template,'data',output_data,/add_replace
    str_element,output_template,'scaling',output_scaling,/add_replace
    str_element,output_template,'energy',output_energy,/add_replace
    str_element,output_template,'denergy',output_denergy,/add_replace  
    str_element,output_template,'bins',output_bins,/add_replace
      
      
    ;find time ranges for current modes
    source_time_range = [min((*source[s]).time),max((*source[s]).end_time)]
    target_time_range = [min((*target[t]).time),max((*target[t]).end_time)]
    
    output_time_range = [source_time_range[0] > target_time_range[0],source_time_range[1] < target_time_range[1]]
    output_time_range = output_time_range+[-0.0001, 0.0001] ;test for bad interpolation    
    
    ;find the indexes for current modes
    source_idx = where((*source[s]).time ge output_time_range[0] and (*source[s]).end_time le output_time_range[1],source_c)
    target_idx = where((*target[t]).time ge output_time_range[0] and (*target[t]).end_time le output_time_range[1],target_c)
    
    
    ;no overlap or mismatched modes and...we've got a problem
    if source_c eq 0 || target_c eq 0 || source_c ne target_c then begin
      message,"WARNING No mode overlap, suggests problem with time interpolation, or absence of time interpolation" ;this will halt the program
    endif

    source_dists = (*source[s])[source_idx]
   
    output_dists = replicate(output_template,target_c)
    output_dists.time = source_dists.time ;copy over times
    output_dists.end_time = source_dists.end_time


    ;TODO: throw out disabled bins?
    
    method = "Linear"
    
    ;Generate interpolated data
    ;Loop over time samples in overlap region of source & target modes.
    for k = 0,target_c-1 do begin
      
      
      ;Create a (required) spherical triangulation
      ;  -for ESA & SST this triangulation is invariant across energy, 
      ;   even if the angles themselves may change across energy
      ;  -this *should* also be invariant across all times for a single mode;
      ;   however, calibrations such as eclipse corrections will change that 
      
      ;can't construct a triangulation over a single point
      if n_elements(source_dists[k].phi[0,*]) gt 1 then begin
        qhull,source_dists[k].phi[0,*],source_dists[k].theta[0,*],triangles,sphere=dummy
      endif
      
      
      ;Loop over energy.
      ;  -This assumes that look directions do not change with energy 
      ;   in a way that would invalidate the triangulation from qhull.
      ;   (e.g. a uniform phi shift is ok)
      for l = 0,source_dim[0]-1 do begin

        ;If griddata is reports triangles not in counterclockwise order:
        ;  -look directions my differ between energies
        ;   (this will require that qhull be called for each energy)
        ;  -there may be duplicate points in the input to qhull
        ;   (check for theta = +-90) 

        if n_elements(source_dists[k].phi[0,*]) gt 1 then begin
          output_dists[k].data[l,*] = griddata(source_dists[k].phi[l,*],source_dists[k].theta[l,*],source_dists[k].data[l,*],/sphere,xout=output_phi[l,*],yout=output_theta[l,*],/degrees,method=method,triangles=triangles) ;the actual spherical interpolation occurs here
          if keyword_set(get_error) then output_dists[k].scaling[l,*] = griddata(source_dists[k].phi[l,*],source_dists[k].theta[l,*],source_dists[k].scaling[l,*],/sphere,xout=output_phi[l,*],yout=output_theta[l,*],/degrees,method=method,triangles=triangles) ;the actual spherical interpolation occurs here
          output_dists[k].bins[l,*] = round(griddata(source_dists[k].phi[l,*],source_dists[k].theta[l,*],source_dists[k].bins[l,*],/sphere,xout=output_phi[l,*],yout=output_theta[l,*],/degrees,method=method,triangles=triangles)) >0<1 ;the actual spherical interpolation occurs here
        endif else begin
          output_dists[k].data[l,*] = source_dists[k].data[l]
          if keyword_set(get_error) then output_dists[k].scaling[l,*] = source_dists[k].scaling[l]
          output_dists[k].bins[l,*] = source_dists[k].bins[l]
        endelse
        
      endfor
      
      ;Populate energy and denergy fields.
      ;This can be done outside the for loop so long as neither field changes 
      ;within a single mode.  This also, assumes that energy and denergy do not 
      ;change with look direction (if energy did the spherical interpolation 
      ;above would be dubious).
      output_dists[k].energy = source_dists[k].energy[*,0] # (blankarr+1)
      output_dists[k].denergy = source_dists[k].denergy[*,0] # (blankarr+1)
      
    endfor

    ;temporary routine bombs on some machines if out_dist is undefined, but not others
    if ~undefined(output) then begin
      ;add new output mode to the output data structure
      output = array_concat(ptr_new(output_dists,/no_copy),temporary(output))
    endif else begin
      output = array_concat(ptr_new(output_dists,/no_copy),output)
    endelse
     
   
    ;increment mode variables based on pattern of the mode overlap
    if (abs(target_time_range[1]-source_time_range[1]) Lt 1.0e-3) then begin ;jmm, 2017-11-09
      s++
      t++
    endif else if (source_time_range[1] lt target_time_range[1]) then begin
      s++
    ;endif else if (target_time_range[1] lt source_time_range[1]) then begin ;last case is implied, this commented line just illustrates the invariant which holds in the else case
    endif else begin 
      t++
    endelse
    
  endwhile  
  
  source = temporary(output)
  heap_gc ; remove pointers whose references were just deleted
  
  error = 0

end
