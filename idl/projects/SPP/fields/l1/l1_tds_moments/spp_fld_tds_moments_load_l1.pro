pro spp_fld_tds_moments_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_tds_moments_'

  cdf2tplot, /get_support_data, file, prefix = prefix

  options, '*tds_moments*', 'datagap', 30.


  mom_items = tnames(prefix + 'v_max_ch?')
  
  get_data, 'spp_fld_tds_moments_sampling_cadence', data = d_cad
  
  for i = 0, n_elements(mom_items) - 1 do begin
    
    item = mom_items[i]
    
    get_data, item, data = d
    
    dx_new = []
    dy_new = []
    
    for j = 0, n_elements(d.x) - 1 do begin
    
      cadence = d_cad.y[j]
      
      n_mom = 8
      
      dx_new = [dx_new, d.x[j] + dindgen(n_mom) * cadence * 2l^25/38.4e6]
      
      dy_new = [dy_new, reform(d.y[j,*])]
      
    endfor
    
    store_data, item + '_conv', data = {x:dx_new, y:dy_new}
    
  endfor

  ;stop

end