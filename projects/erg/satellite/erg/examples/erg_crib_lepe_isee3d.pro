pro erg_crib_lepe_isee3d, $
   trange=trange, $
   debug=debug, $
   noload=noload, $
   lis=lis

  if undefined(debug) then debug = 0

  
  if undefined(trange) then trange = '2017-04-12/'+['16:00', '17:30']

  timespan, trange

  if ~keyword_set(noload) then begin
    erg_load_lepe, datatype='3dflux', varf='FEDU', /no_sort_enebin, /l2new
    erg_load_mgf
    set_erg_var_label
  endif

  part_vn = 'erg_lepe_l2_3dflux_FEDU'
  mag_vn = 'erg_mgf_l2_mag_8sec_dsi'
  vel_vn = 'erg_mgf_l2_mag_8sec_gse' ;; dummy

  dists = erg_lepe_get_dist( part_vn, /struc, trange=trange )

  dist_ptrs = replicate( ptr_new(), n_elements(dists) )

  for i=0, n_elements(dists)-1 do begin

    dist = dists[i]
    erg_convert_flux_units, dist, output=dist_df, units='df'

    ene_id = where( finite( dist_df.energy[*, 0, 0] ), nene )
    if dist_df.nenergy ne nene then begin
      str_element, dist_df, 'data', dist_df.data[ene_id, *, *], /add_rep
      str_element, dist_df, 'bins', dist_df.bins[ene_id, *, *], /add_rep
      str_element, dist_df, 'energy', dist_df.energy[ene_id, *, *], /add_rep
      str_element, dist_df, 'denergy', dist_df.denergy[ene_id, *, *], /add_rep
      dist_df.nenergy = nene
      str_element, dist_df, 'phi', dist_df.phi[ene_id, *, *], /add_rep
      str_element, dist_df, 'dphi', dist_df.dphi[ene_id, *, *], /add_rep
      str_element, dist_df, 'theta', dist_df.theta[ene_id, *, *], /add_rep
      str_element, dist_df, 'dtheta', dist_df.dtheta[ene_id, *, *], /add_rep
    endif

    id = where( ~finite(dist_df.data) or dist_df.data lt 0, nid )
    if nid then dist_df.data[id] = 0.

    dist_ptrs[i] = ptr_new(dist_df, /no_copy) 
    if debug then help, dist_ptrs[i]
    
  endfor

  if debug then help, dist_ptrs
  data = spd_dist_to_hash( dist_ptrs )

  if debug then help, data
  if debug then begin
    lis = data.keys()
    
  endif

  ;; run the ISEE3D main program 
  isee_3d, data=data, trange=trange, bfield=mag_vn, velocity=vel_vn
  
  ;; clean up internally used data arrays and pointers
  undefine, dist_ptrs


  return

end
