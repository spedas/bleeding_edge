;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2022-02-16 22:00:46 -0800 (Wed, 16 Feb 2022) $
;  $LastChangedRevision: 30594 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_aeb1_hk/spp_fld_aeb1_hk_load_l1.pro $
;

pro spp_fld_aeb1_hk_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_aeb1_hk_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  rbiases = [49.9e6,99e3,2.89e6]

  aeb1_sensors = ['1','2','5']

  foreach sens, aeb1_sensors do begin

    imped = prefix + 'v' + sens + '_imped'
    biasv = prefix + 'BIAS' + sens + 'V'
    biasd = prefix + 'BIAS' + sens + '_DAC'

    get_data, imped, data = dat_imped
    get_data, biasv, data = dat_biasv
    get_data, biasd, data = dat_biasd

    if (size(dat_imped, /type) EQ 8) and $
      (size(dat_biasv, /type) EQ 8) and $
      (size(dat_biasd, /type) EQ 8) then begin

      rb = dblarr(n_elements(dat_imped.y))

      foreach r, rbiases, i do begin

        ind = where(dat_imped.y EQ i, count)

        if count GT 0 then rb[ind] = r

      endforeach

      options, imped, 'yrange', [-0.5,2.5]
      options, imped, 'yminor', 1
      options, imped, 'ystyle', 1
      options, imped, 'ytickformat', '(I1)'
      options, imped, 'yticks', 2
      options, imped, 'ytickv', [0,1,2]
      options, imped, 'panel_size', 0.5

    endif else begin

      if size(dat_biasv, /type) EQ 8 then rb = 49.9e6 else rb = !values.f_nan

    endelse

    biasi_y = dat_biasv.y / rb * 1e6
    biasdi_y = dat_biasd.y / rb * 1e6

    biasi = prefix + 'BIAS' + sens + 'I'
    biasdi = prefix + 'BIAS' + sens + '_DAC_I'

    store_data, biasi, data = {x:dat_biasv.x, y:biasi_y}
    store_data, biasdi, data = {x:dat_biasd.x, y:biasdi_y}

    options, biasi, 'ytitle', 'BIAS' + sens + 'I'
    options, biasi, 'ysubtitle', '[uA]'
    ;options, biasi, 'yrange', [-5,0]

    options, biasdi, 'ytitle', 'BIAS' + sens + 'I DAC'
    options, biasdi, 'ysubtitle', '[uA]'

  endforeach


  aeb_hk_names = tnames(prefix + '*')

  if aeb_hk_names[0] NE '' then begin

    foreach name, aeb_hk_names do begin

      name_no_prefix = name.Remove(0, prefix.Strlen()-1)

      options, name, 'ynozero', 1

      if strpos(name_no_prefix, 'AEB') NE -1 then begin
        colors = [0]
        labels = ''
      endif else if strpos(name_no_prefix, '1') NE -1 then begin
        colors = [6]
        labels = '1'
      endif else if strpos(name_no_prefix, '2') NE -1 then begin
        colors = [4]
        labels = '  2'
      endif else if strpos(name_no_prefix, '5') NE -1 then begin
        colors = [3]
        labels = '        5'
      endif else begin
        colors = [0]
        labels = ''
      endelse

      options, name, 'colors', colors
      options, name, 'labels', labels
      options, name, 'ytitle', name_no_prefix

      options, name, 'psym_lim', 400
      options, name, 'datagap', 3600d
      options, name, 'symsize', 0.5

    endforeach

  endif

end