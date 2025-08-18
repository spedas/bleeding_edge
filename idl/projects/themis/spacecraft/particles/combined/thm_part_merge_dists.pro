;+
;
;Procedure:
;  thm_part_merge_dists.pro
;
;Purpose:
;  Merge ESA/SST particle distributions once they have been 
;  altered to match in time, energy, angle, and mode transition. 
;
;Inputs:
;  esa_dist:  esa distribution array
;  sst_dist:  sst distribution array
;  sst_only:  flag to only return SST + new energies
;  probe:  probe designation
;  esa_datatype:  esa data type, e.g. 'peif'
;  sst_datatype:  sst data type, e.g. 'psif'
;
;
;Outputs:
;  out_dist:  combined distributions, fresh and ready for unit conversion
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-09-26 18:59:57 -0700 (Thu, 26 Sep 2013) $
;$LastChangedRevision: 13157 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/themis/spacecraft/particles/thm_part_combine.pro $
;
;-

pro thm_part_merge_dists, esa_dist, sst_dist, out_dist=out_dist, probe=probe, esa_datatype=esa_datatype, sst_datatype=sst_datatype,only_sst=only_sst

  compile_opt idl2, hidden

  error = 1

  if n_elements(esa_dist) ne n_elements(sst_dist) then begin
    ;should already be separated into unique combinations instrument modes
    message, 'Incorrect mode matching' ;this shouldn't happen
    return
  endif 
  
  ;init output
  out_dist = replicate(ptr_new(),n_elements(esa_dist))
  
  ;create data name
  species = strmid(esa_datatype,2,1)
  esa_type = strmid(esa_datatype,3,1)
  sst_type = strmid(sst_datatype,3,1)
  
  if ~keyword_set(only_sst) then begin
    data_name = 'pt' + species + esa_type + sst_type
  endif else begin
    data_name = 'ps' + species + sst_type
  endelse
  
 
  ;loop over combined modes
  for i=0, n_elements(out_dist)-1 do begin
  
    ;extract dist structures for this mode 
    esa_str = temporary(*esa_dist[i])
    sst_str = temporary(*sst_dist[i])
    
    ;get input dimensions
    dim_esa = size(esa_str.data,/dim)
    dim_sst = size(sst_str.data,/dim)
    
    ;angle and energy dimensions should be the same
    if ~array_equal(dim_esa[1:*],dim_sst[1:*]) then begin
      message, 'Incorrect dimensions for current mode' ;this also shouldn't happen
      return
    endif
    
    ;ensure third dimension pressent in case of single sample
    if n_elements(dim_esa) eq 2 then begin
      dim_esa = [dim_esa,1]
      dim_sst = [dim_sst,1]
    endif
    
    ;get output dimensions
    
    if ~keyword_set(only_sst) then begin
      dim_out = [dim_esa[0] + dim_sst[0], dim_esa[1], dim_esa[2]]
    endif else begin
      dim_out = dim_sst
    endelse

    ;dummy array to be copied
    comb_arr = fltarr(dim_out[0:1])

    ;basic template structure
    template = {  $
                project_name: 'THEMIS', $
                spacecraft: probe, $
                data_name: data_name, $
                units_name: 'flux', $
                units_procedure: 'thm_convert_cmb_units', $
                apid: 0, $ ;placeholder
                valid: 1b, $ ;invalid dists should probably be filtered prior to this
                
                charge: esa_str[0].charge, $
                mass: esa_str[0].mass, $
                sc_pot: 0., $ ;placeholder for moments
                magf: replicate(!values.f_nan,3), $ ;placeholder for moments
                velocity: replicate(!values.f_nan,3), $ ;placeholder for slices
                sun_vector: replicate(!values.f_nan,3), $ ;placeholder for slices
                
                time: 0d, $
                end_time: 0d, $
                
                data: comb_arr, $
                scaling: comb_arr, $ ;placeholder for spectra/moments,
                bins: comb_arr, $
;                nenergy: dim_out[0], $
                
                energy: comb_arr, $
                denergy: comb_arr, $
                phi: comb_arr, $
                dphi: comb_arr, $
                theta: comb_arr, $
                dtheta: comb_arr $
                }
    
    ;replicate template struct
    ; TODO: This will probably cause the largest memory spike during
    ;       any given run.  A clever way of allocating memory for this
    ;       var while freeing that used by the input would be preferable.
    out_str = replicate(template,dim_out[2])
    

    if ~keyword_set(only_sst) then begin
      ;copy values
      out_str.data = [esa_str.data, sst_str.data]
      out_str.scaling = [esa_str.scaling, sst_str.scaling]
      out_str.bins = [esa_str.bins, sst_str.bins]
      
      out_str.energy = [esa_str.energy, sst_str.energy]
      out_str.denergy = [esa_str.denergy, sst_str.denergy]
      out_str.phi = [esa_str.phi, sst_str.phi]
      out_str.dphi = [esa_str.dphi, sst_str.dphi]
      out_str.theta = [esa_str.theta, sst_str.theta]
      out_str.dtheta = [esa_str.dtheta, sst_str.dtheta]  
    endif else begin
      ;copy values
      out_str.data = sst_str.data
      out_str.scaling = sst_str.scaling
      out_str.bins = sst_str.bins
      
      out_str.energy = sst_str.energy
      out_str.denergy = sst_str.denergy
      out_str.phi = sst_str.phi
      out_str.dphi = sst_str.dphi
      out_str.theta = sst_str.theta
      out_str.dtheta = sst_str.dtheta
      
    endelse
      
    out_str.time = esa_str.time  ;times should be identical
    out_str.end_time = esa_str.end_time
  
    
    ;set pointer
    out_dist[i] = ptr_new(out_str, /no_copy)
     
  endfor
  
  
  error = 0
  
  return
  
end
