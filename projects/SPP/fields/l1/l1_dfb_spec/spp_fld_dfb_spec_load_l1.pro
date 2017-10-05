pro spp_fld_dfb_spec_load_l1, file, prefix = prefix

  cdf2tplot, file, prefix = prefix, varnames = varnames

  status_items = ['enable','bin','src_sel','scm_rotate','gain','navg','concat']

  options, prefix + status_items, 'colors', 6
  options, prefix + status_items, 'psym', 4
  options, prefix + status_items, 'panel_size', 0.75
  options, prefix + status_items, 'ysubtitle', ''

  options, prefix + 'spec', 'spec', 1

  options, prefix + 'src_sel', 'yrange', [-0.5,15.5]
  options, prefix + 'src_sel', 'ystyle', 1

  options, prefix + 'enable', 'yrange', [-0.25,1.25]
  options, prefix + 'enable', 'ystyle', 1
  options, prefix + 'enable', 'yticks', 2
  options, prefix + 'enable', 'ytickv', [0,1]
  options, prefix + 'enable', 'yminor', 1
  options, prefix + 'enable', 'ysubtitle', ''
  options, prefix + 'enable', 'panel_size', 0.35

  options, prefix + 'bin', 'yrange', [-0.25,1.25]
  options, prefix + 'bin', 'ystyle', 1
  options, prefix + 'bin', 'yticks', 2
  options, prefix + 'bin', 'ytickv', [0,1]
  options, prefix + 'bin', 'yminor', 1
  options, prefix + 'bin', 'ysubtitle', ''
  options, prefix + 'bin', 'panel_size', 0.35

  options, prefix + 'scm_rotate', 'yrange', [-0.25,1.25]
  options, prefix + 'scm_rotate', 'ystyle', 1
  options, prefix + 'scm_rotate', 'yticks', 2
  options, prefix + 'scm_rotate', 'ytickv', [0,1]
  options, prefix + 'scm_rotate', 'yminor', 1
  options, prefix + 'scm_rotate', 'ysubtitle', ''
  options, prefix + 'scm_rotate', 'panel_size', 0.35

  options, prefix + 'gain', 'yrange', [-0.25,1.25]
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'yticks', 2
  options, prefix + 'gain', 'ytickv', [0,1]
  options, prefix + 'gain', 'yminor', 1
  options, prefix + 'gain', 'ysubtitle', ''
  options, prefix + 'gain', 'panel_size', 0.35

  options, prefix + 'navg', 'yrange', [-0.5,15.5]
  options, prefix + 'navg', 'ystyle', 1

  options, prefix + 'concat', 'yrange', [-0.5,15.5]
  options, prefix + 'concat', 'ystyle', 1

  get_data, prefix + 'spec', data = spec_data

  get_data, prefix + 'bin', data = bin_data

  get_data, prefix + 'spec_nelem', data = nelem_data

  get_data, prefix + 'concat', data = concat_data

  ; TODO: Make this work with all configurations of spectra

  if size(spec_data, /type) EQ 8 then begin

    if n_elements(spec_data.x) GT 1 then begin

      ; TODO: Make this work when the number of elements in the spectrum change

      n_spec = concat_data.y[0] + 1
      n_bins = nelem_data.y[0] / n_spec

      if strpos(prefix, 'ac_spec') NE -1 then begin
        freq_bins = spp_get_fft_bins_04_ac(n_bins)
      endif else begin
        freq_bins = spp_get_fft_bins_04_dc(n_bins)
      endelse

      n_total = n_elements(spec_data.y)

      ;spec_data_y = reform(transpose([[spec_data.y[*,1:*:2]],[spec_data.y[*,0:*:2]]],size(spec_data.y,/dim)))

      spec_data_y = reform(transpose([[[spec_data.y[*,1:*:2]]],[[spec_data.y[*,0:*:2]]]],[0,2,1]), size(/dim,spec_data.y))

      ;print, spec_data_y[0,0:3]

      new_data_y = transpose(reform(reform(transpose(spec_data_y), n_total), $
        n_bins, n_total/n_bins))

      ; TODO: Make this more precise using TMlib time

      new_data_x = []
      delta_x = (spec_data.x[1] - spec_data.x[0]) / n_spec

      for i = 0, n_elements(spec_data.x)-1 do begin
        new_data_x = [new_data_x,spec_data.x[i] + delta_x * dindgen(n_spec)]
      endfor

      data_v = transpose(rebin(freq_bins.freq_avg,$
        n_elements(freq_bins.freq_avg),$
        n_elements(new_data_x)))

      store_data, prefix + 'spec_converted', $
        data = {x:new_data_x, $
        y:alog10(spp_fld_dfb_psuedo_log_decompress(new_data_y, type = 'spectra')), $
        v:data_v}

      options, prefix + 'spec_converted', 'panel_size', 2
      options, prefix + 'spec_converted', 'spec', 1
      options, prefix + 'spec_converted', 'no_interp', 1
      options, prefix + 'spec_converted', 'zlog', 0
      options, prefix + 'spec_converted', 'ylog', 1
      options, prefix + 'spec_converted', 'ztitle', 'Log Auto [arb.]'
      options, prefix + 'spec_converted', 'ystyle', 1
      options, prefix + 'spec_converted', 'yrange', minmax(freq_bins.freq_avg)

    endif

  endif

  ; Clean up some formatting

  ac_dc_string = strupcase(strmid(prefix,12,2))
  spec_ind = strmid(prefix, strlen(prefix)-2, 1)

  dfb_spec_names = tnames(prefix + '*')

  if dfb_spec_names[0] NE '' then begin

    for i = 0, n_elements(dfb_spec_names) - 1 do begin

      dfb_spec_name_i = strmid(dfb_spec_names[i], strlen(prefix))

      if dfb_spec_name_i EQ 'spec_converted' then begin

        options, prefix + dfb_spec_name_i, 'ytitle', 'SPP DFB!C' + ac_dc_string + ' SPEC' + $
          string(spec_ind)

        options, prefix + dfb_spec_name_i, 'ysubtitle', 'Freq [Hz]'

      endif else begin

        if strmid(prefix + dfb_spec_name_i,6,/rev) EQ '_string' then begin

          options, prefix + dfb_spec_name_i, 'ysubtitle', ''

          dfb_spec_name_ytitle = strmid(dfb_spec_name_i, 0, strlen(dfb_spec_name_i) - 7)

        endif else begin

          dfb_spec_name_ytitle = dfb_spec_name_i

        endelse

        options, prefix + dfb_spec_name_i, 'ytitle', 'SPP DFB!C' + ac_dc_string + ' SPEC' + $
          string(spec_ind) + '!C' + strupcase(dfb_spec_name_ytitle)

      endelse

    endfor

  endif

  options, prefix + '*string', 'tplot_routine', 'strplot'
  options, prefix + '*string', 'yrange', [-0.1,1.0]
  options, prefix + '*string', 'ystyle', 1
  options, prefix + '*string', 'yticks', 1
  options, prefix + '*string', 'ytickformat', '(A1)'
  options, prefix + '*string', 'noclip', 0

end