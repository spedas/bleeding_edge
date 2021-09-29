pro psp_fld_dfb_spec_load_l2, files

  if n_elements(files) EQ 0 then begin
    
    print, 'No input files!'
    
    return
    
  endif

  dfb_spec_types = []

  dfb_spec_uniq_types = []

  for i = 0, n_elements(files) - 1 do begin

    type = strjoin((strsplit(file_basename(files[i]),'_',/ex))[4:6],'_')

    dfb_spec_types = [dfb_spec_types, type]

    dummy = where(dfb_spec_uniq_types EQ type, count)

    if count EQ 0 then dfb_spec_uniq_types = [dfb_spec_uniq_types, type]

  endfor

  if n_elements(dfb_spec_uniq_types) GT 1 then begin

    for i = 0, n_elements(dfb_spec_uniq_types)-1 do begin

      files_of_type_ind = where(dfb_spec_types EQ dfb_spec_uniq_types[i])

      files_of_type = files[files_of_type_ind]

      psp_fld_dfb_spec_load_l2, files_of_type

    endfor

    return

  endif else begin

    print, type

    print, files

    cdf2tplot, files, /get_support

    get_data, 'psp_fld_l2_dfb_' + type, data = d, al = al

    if size(/type, al) EQ 8 then $
      options, 'psp_fld_l2_dfb_' + type, 'ztitle', al.ysubtitle

    options, 'psp_fld_l2_dfb_' + type, 'zlog', 1
    options, 'psp_fld_l2_dfb_' + type, 'ylog', 1

    options, 'psp_fld_l2_dfb_' + type, 'ytitle', $
      strmid(type,8)

    options, 'psp_fld_l2_dfb_' + type + '_saturation_flags', 'ytitle', $
      strmid(type,8) + '!CSat Flag'

    if size(/type, d) EQ 8 then $
      options, 'psp_fld_l2_dfb_' + type, 'yrange', minmax(d.v)
    options, 'psp_fld_l2_dfb_' + type, 'ystyle', 1
    options, 'psp_fld_l2_dfb_' + type, 'ysubtitle', '[Hz]'

    options, 'psp_fld_l2_dfb_' + type, 'panel_size', 2
    options, 'psp_fld_l2_dfb_' + type, 'no_interp', 1
    options, 'psp_fld_l2_dfb_' + type, 'datagap', 3600d

  endelse

  ;  stop

end