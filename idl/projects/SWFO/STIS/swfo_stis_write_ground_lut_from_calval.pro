pro swfo_stis_write_ground_lut_from_calval, calval, template_dir, template_name, lut_dir, lut_name

  n_counters = 672
  size_fto = size(calval.names_fto)
  n_logic_combos = size_fto[2]
  n_event_type = fix(n_logic_combos * 2)
  n_energies_per_type = fix(n_counters / n_event_type)
  n_active_regions = 2
  
  ; some quantities that currently are not in 'calval'

  dead_time = 8.0e-6   ; from 'swfo_stis_response_plot_simflux'
  ; create 14-element vector for LUT
  dead_time_vector = replicate(dead_time, n_event_type)
  
  epam_ion_edge_energies = [47., 68., 115., 195., 315., 583., 1060., 1900., 4800.]
  epam_electron_edge_energies = [45., 62., 102., 175., 315.]
  
  ; access quantities from 'calval'
  tid = byte(calval.responses['Proton'].bmap[0:n_counters-1].tid)
  fto = byte(calval.responses['Proton'].bmap[0:n_counters-1].fto)
  who1 = where((tid eq 0) and (fto eq 1))
  who3 = where((tid eq 0) and (fto eq 4))  
  whf1 = where((tid eq 1) and (fto eq 1))
  whf3 = where((tid eq 1) and (fto eq 4))
    
  ; calval.geoms_tid_fto and calval.responses['Proton'].bmap.geom and calval.responses['Electron'].bmap.geom are the same
  gf_o1_pro = calval.geoms_tid_fto[where(calval.names_fto eq 'O-1')]
  gf_o3_pro = calval.geoms_tid_fto[where(calval.names_fto eq 'O-3')]
  gf_f1_pro = calval.geoms_tid_fto[where(calval.names_fto eq 'F-1')]
  gf_f3_pro = calval.geoms_tid_fto[where(calval.names_fto eq 'F-3')]
  
  ; ion quantities
  ion_geometric_factors = dblarr(n_active_regions, n_energies_per_type)
  ion_geometric_factors[0, *] = gf_o1_pro
  ion_geometric_factors[1, *] = gf_o3_pro  
  
  ion_energy_centers = dblarr(n_active_regions, n_energies_per_type)
  ion_energy_centers[0, *] = calval.responses['Proton'].bmap[who1].nrg_inc
  ion_energy_centers[1, *] = calval.responses['Proton'].bmap[who3].nrg_inc

  ion_energy_widths = dblarr(n_active_regions, n_energies_per_type)
  ion_energy_widths[0, *] = calval.responses['Proton'].bmap[who1].nrg_inc_delta
  ion_energy_widths[1, *] = calval.responses['Proton'].bmap[who3].nrg_inc_delta
  
  ion_maps = bytarr(n_active_regions, n_counters)*0
  ion_maps[0, who1] = 1
  ion_maps[1, who3] = 1
  
  ion_response_matrix = calval.responses['Proton'].Mde[*, 0:n_counters-1]
  
  ; electron quantities
  electron_geometric_factors = dblarr(n_active_regions, n_energies_per_type)
  electron_geometric_factors[0, *] = gf_f1_pro
  electron_geometric_factors[1, *] = gf_f3_pro
  
  electron_energy_centers = dblarr(n_active_regions, n_energies_per_type)
  electron_energy_centers[0, *] = calval.responses['Electron'].bmap[whf1].nrg_inc
  electron_energy_centers[1, *] = calval.responses['Electron'].bmap[whf3].nrg_inc

  electron_energy_widths = dblarr(n_active_regions, n_energies_per_type)
  electron_energy_widths[0, *] = calval.responses['Electron'].bmap[whf1].nrg_inc_delta
  electron_energy_widths[1, *] = calval.responses['Electron'].bmap[whf3].nrg_inc_delta
  
  electron_maps = bytarr(n_active_regions, n_counters)*0
  electron_maps[0, whf1] = 1
  electron_maps[1, whf3] = 1

  electron_response_matrix = calval.responses['Electron'].Mde[*, 0:n_counters-1]
  
  ; copy template to new name
  template_path = template_dir + template_name
  lut_path = lut_dir + lut_name
  
  file_copy, template_path, lut_path, /overwrite  ; caution, this overwrite may not work?
  
  fid = ncdf_open(lut_path, /write)
  
  ncdf_varput, fid, 'dead_time', dead_time_vector
  ncdf_varput, fid, 'epam_ion_edge_energies', epam_ion_edge_energies
  ncdf_varput, fid, 'epam_electron_edge_energies', epam_electron_edge_energies
  ncdf_varput, fid, 'ion_geometric_factors', ion_geometric_factors
  ncdf_varput, fid, 'ion_energy_centers', ion_energy_centers
  ncdf_varput, fid, 'ion_energy_widths', ion_energy_widths
  ncdf_varput, fid, 'ion_response_matrix', ion_response_matrix
  ncdf_varput, fid, 'ion_maps', ion_maps
  ncdf_varput, fid, 'electron_geometric_factors', electron_geometric_factors
  ncdf_varput, fid, 'electron_energy_centers', electron_energy_centers  
  ncdf_varput, fid, 'electron_energy_widths', electron_energy_widths 
  ncdf_varput, fid, 'electron_response_matrix', electron_response_matrix
  ncdf_varput, fid, 'electron_maps', electron_maps
  ncdf_varput, fid, 'telescope_id_map', tid
  ncdf_varput, fid, 'fto_logic_id_map', fto
      
  ncdf_close, fid
end