pro spp_fld_dfb_dbm_load_l1, file, prefix = prefix, varformat = varformat

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  dbm_number = fix(strmid(prefix,1,1,/rev))

  options, prefix + 'compression', 'yrange', [-0.25, 1.25]

  options, prefix + 'acdc', 'yrange', [-0.25, 1.25]
  options, prefix + 'acdc', 'ytickname', ['AC','DC']

  options, prefix + 'ftap', 'yrange', [-0.5, 6.5]

  options, prefix + 'src_sel', 'yrange', [-0.5, 15.5]

  options, prefix + 'gswapenb', 'yrange', [-0.25, 1.25]

  options, prefix + 'gswapped', 'yrange', [-0.25, 1.25]


  dbm_colors = [0, 144, 112, 16, 208, 128]
  
  dbm_color = dbm_colors[dbm_number - 1]

  if dbm_color EQ 5 then dbm_color = 0 ; can't see yellow

  dbm_meta = ['compression','acdc','ftap',$
    'src_sel','gswapenb','gswapped']

  options, prefix + dbm_meta, 'ystyle', 1
  options, prefix + dbm_meta, 'psym', 2
  options, prefix + dbm_meta, 'color_table', 12
  options, prefix + dbm_meta, 'colors', dbm_color
  options, prefix + dbm_meta, 'ysubtitle'
  options, prefix + dbm_meta, 'yticks', 1
  options, prefix + dbm_meta, 'ytickv', [0,1]
  options, prefix + dbm_meta, 'panel_size', 1
  options, prefix + dbm_meta, 'yticklen', 1
  options, prefix + dbm_meta, 'ygridstyle', 1

  options, prefix + 'ftap', 'yticks', 7
  options, prefix + 'ftap', 'ytickv', indgen(8)
  options, prefix + 'ftap', 'panel_size', 2

  options, prefix + 'src_sel', 'yticks', 15
  options, prefix + 'src_sel', 'ytickv', indgen(16)
  options, prefix + 'src_sel', 'panel_size', 3


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
        'ysubtitle', ''

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'yrange', al.yrange

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'panel_size', al.panel_size
        
        
      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'yticks', al.yticks

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'ytickv', al.ytickv

      options, 'spp_fld_dfb_dbm_' + dbm_meta[i] + '_all', $
        'ygridstyle', al.ygridstyle

    endif

  endfor


end