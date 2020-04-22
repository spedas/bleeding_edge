;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2020-04-21 16:24:51 -0700 (Tue, 21 Apr 2020) $
;  $LastChangedRevision: 28596 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_aeb2_hk/spp_fld_aeb2_hk_load_l1.pro $
;

pro spp_fld_aeb2_hk_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_aeb2_hk_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  rbiases = [49.9e6,99e3,2.89e6]

  aeb2_sensors = ['3','4']

  foreach sens, aeb2_sensors do begin

    imped = prefix + 'v' + sens + '_imped'
    biasv = prefix + 'BIAS' + sens + 'V'

    get_data, imped, data = dat_imped
    get_data, biasv, data = dat_biasv

    if size(dat_imped, /type) EQ 8 and size(dat_biasv, /type) EQ 8 then begin

      rb = dblarr(n_elements(dat_imped.y))

      foreach r, rbiases, i do begin

        ind = where(dat_imped.y EQ i, count)

        if count GT 0 then rb[ind] = r

      endforeach

      biasi_y = dat_biasv.y / rb * 1e6

      biasi = prefix + 'BIAS' + sens + 'I'

      store_data, biasi, data = {x:dat_biasv.x, y:biasi_y}

      options, biasi, 'ytitle', 'BIAS1I'
      options, biasi, 'ysubtitle', '[uA]'
      ;options, biasi, 'yrange', [-5,0]

      options, imped, 'yrange', [-0.5,2.5]
      options, imped, 'yminor', 1
      options, imped, 'ystyle', 1
      options, imped, 'ytickformat', '(I1)'
      options, imped, 'yticks', 2
      options, imped, 'ytickv', [0,1,2]
      options, imped, 'panel_size', 0.5

    end

  endforeach

  aeb_hk_names = tnames(prefix + '*')

  if aeb_hk_names[0] NE '' then begin

    foreach name, aeb_hk_names do begin

      name_no_prefix = name.Remove(0, prefix.Strlen()-1)

      options, name, 'ynozero', 1
      options, name, 'horizontal_ytitle', 1

      if strpos(name_no_prefix, 'AEB') NE -1 then begin
        colors = [0]
        labels = ''
      endif else if strpos(name_no_prefix, '3') NE -1 then begin
        colors = [2]
        labels = '    3'
      endif else if strpos(name_no_prefix, '4') NE -1 then begin
        colors = [1]
        labels = '      4'
      endif else begin
        colors = [0]
        labels = ''
      endelse

      options, name, 'colors', colors
      options, name, 'labels', labels
      options, name, 'ytitle', name.Remove(0, prefix.Strlen()-1)

      options, name, 'psym_lim', 400
      options, name, 'datagap', 3600d
      options, name, 'symsize', 0.5

    endforeach

  endif

end