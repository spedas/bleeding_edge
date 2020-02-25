pro spp_fld_dfb_dbm_load_l1, file, prefix = prefix, varformat = varformat

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  dbm_number = fix(strmid(prefix,1,1,/rev))

  options, prefix + 'compression', 'yrange', [-0.5, 1.5]
  ;options, prefix + 'compression', 'psym', -4
  ;options, prefix + 'compression', 'symsize', 0.5

  options, prefix + 'acdc', 'yrange', [-0.5, 1.5]
  ;options, prefix + 'acdc', 'psym', -4
  ;options, prefix + 'acdc', 'symsize', 0.5

  options, prefix + 'ftap', 'yrange', [-0.5, 6.5]
  ;options, prefix + 'ftap', 'psym', -4
  ;options, prefix + 'ftap', 'symsize', 0.5

  options, prefix + 'src_sel', 'yrange', [-0.5, 15.5]
  ;options, prefix + 'src_sel', 'psym', -4
  ;options, prefix + 'src_sel', 'symsize', 0.5

  options, prefix + 'gswapenb', 'yrange', [-0.5, 1.5]
  ;options, prefix + 'gswapenb', 'psym', -4
  ;options, prefix + 'gswapenb', 'symsize', 0.5

  options, prefix + 'gswapped', 'yrange', [-0.5, 1.5]
  ;options, prefix + 'gswapped', 'psym', -4
  ;options, prefix + 'gswapped', 'symsize', 0.5

  dbm_color = dbm_number

  if dbm_color EQ 5 then dbm_color = 0 ; can't see yellow

  dbm_meta = ['compression','acdc','ftap',$
    'src_sel','gswapenb','gswapped']

  options, prefix + dbm_meta, $
    'ystyle', 1

  options, prefix + dbm_meta, $
    'psym', -2

  options, prefix + dbm_meta, $
    'colors', dbm_color

  options, prefix + dbm_meta, $
    'labels', strmid('      ',0,dbm_number) + $
    strcompress(string(dbm_number),/rem)

  for i = 0, n_elements(dbm_meta) - 1 do begin

    items = tnames('spp_fld_dfb_dbm*' + dbm_meta[i])

    if items[0] NE '' then begin

      store_data, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        data = items

      get_data, items[0], al = al

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'ytitle', 'DFB!CDBM!C' + dbm_meta[i]

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'ystyle', 1
        
      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'yrange', al.yrange


    endif


  endfor


end