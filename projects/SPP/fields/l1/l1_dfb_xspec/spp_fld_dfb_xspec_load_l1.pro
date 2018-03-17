pro spp_fld_dfb_xspec_load_l1, file, prefix = prefix

  ; TODO: More X-spectra testing and formatting

  ; TODO: Add saturation flags

  if n_elements(file) LT 1 then begin
    print, 'Must provide a CDF file to load"
    return
  endif

  cdf2tplot, file, prefix = prefix, varnames = varnames

  status_items = ['enable', 'concat', 'src1', 'src2', 'gain', 'navg', 'bin']

  spec_number = fix(strmid(prefix,1,1,/rev))

  case spec_number of
    1: colors = 6 ; red
    2: colors = 4 ; green
    3: colors = 2 ; blue
    4: colors = 1 ; magenta
  endcase

  options, prefix + status_items, 'colors', colors
  options, prefix + status_items, 'psym', spec_number + 3
  options, prefix + status_items, 'panel_size', 0.75
  options, prefix + status_items, 'ysubtitle', ''

  options, prefix + 'concat', 'yrange', [-0.5,2.5]
  options, prefix + 'concat', 'yticks', 3
  options, prefix + 'concat', 'ytickv', [0.,1.,2.]
  options, prefix + 'concat', 'ystyle', 1
  options, prefix + 'concat', 'yminor', 1
  options, prefix + 'concat', 'panel_size', 0.5

  options, prefix + 'src?', 'yrange', [-0.5,3.5]
  options, prefix + 'src?', 'yticks', 4
  options, prefix + 'src?', 'ytickv', [0.,1.,2.,3.]
  options, prefix + 'src?', 'ystyle', 1
  options, prefix + 'src?', 'yminor', 1
  options, prefix + 'src?', 'panel_size', 0.5
  options, prefix + 'src?', 'labels', [string(spec_number,format='(I1)')]

  options, prefix + ['enable','gain','bin'], 'yrange', [-0.25,1.25]
  options, prefix + ['enable','gain','bin'], 'ystyle', 1
  options, prefix + ['enable','gain','bin'], 'yticks', 1
  options, prefix + ['enable','gain','bin'], 'ytickv', [0,1]
  options, prefix + ['enable','gain','bin'], 'yminor', 1
  options, prefix + ['enable','gain','bin'], 'ysubtitle', ''
  options, prefix + ['enable','gain','bin'], 'panel_size', 0.35

  options, prefix + 'navg', 'yrange', [-0.5,10.5]
  options, prefix + 'navg', 'ystyle', 1
  options, prefix + 'navg', 'yminor', 1
  options, prefix + 'navg', 'panel_size', 0.5

  options, prefix + 'xspec_??_s?', 'spec', 1
  options, prefix + 'xspec_??_s?', 'no_interp', 1

  ac_dc_string = strupcase(strmid(prefix,12,2))
  xspec_ind = strmid(prefix, strlen(prefix)-2, 1)

  get_data, prefix + 'navg', data = navg_data

  get_data, prefix + 'bin', data = bin_data

  get_data, prefix + 'concat', data = concat_data

  ; TODO: Make this work with all configurations of cross spectra

  if n_elements(uniq(bin_data.y)) EQ 1 and $
    n_elements(uniq(navg_data.y)) EQ 1 and $
    n_elements(uniq(concat_data.y)) EQ 1 then begin

    xspec_types = ['p1', 'p2', 'rc', 'ic']

    if strpos(prefix, 'ac_xspec') NE -1 then is_ac = 1 else is_ac = 0

    n_spec = concat_data.y[0] + 1
    n_bins = bin_data.y[0] ? 96 : 56
    n_avg = 2l^(navg_data.y[0])

    if is_ac then begin
      freq_bins = spp_get_fft_bins_04_ac(n_bins)
    endif else begin
      freq_bins = spp_get_fft_bins_04_dc(n_bins)
    endelse

    for j = 0, n_elements(xspec_types) - 1 do begin

      xspec_type = xspec_types[j]

      xspec_names = tnames(prefix + 'xspec_' + xspec_type + '_s?', n_xspec)

      xspec_dat_y = []

      for i = 0, n_xspec - 1 do begin

        get_data, xspec_names[i], dat = xspec_dat_i

        if xspec_type EQ 'p1' or xspec_type EQ 'p2' then begin

          xspec_dat_y_i = reform( $
            transpose($
            [[[xspec_dat_i.y[*,1:*:2]]], $
            [[xspec_dat_i.y[*,0:*:2]]]],[0,2,1]), $
            size(/dim,xspec_dat_i.y))

        endif else begin
          
          xspec_dat_y_i = xspec_dat_i.y
          
        endelse

        xspec_dat_y = [[[xspec_dat_y]], [[xspec_dat_y_i]]]

      endfor

      n_total = n_elements(xspec_dat_y)

      ;      xspec_dat_y = transpose(reform(reform(transpose(xspec_dat_y), n_total), $
      ;        n_bins, n_total/n_bins))

      xspec_dat_y = transpose(reform(transpose(xspec_dat_y,[1,2,0]), n_bins, n_total/n_bins))

      xspec_dat_x = []

      if is_ac then begin

        if n_avg LE 16 then delta_x = 2d^17 / 150d3 ;; TODO: verify this
        if n_avg GE 32 then delta_x = 2d^17 / 150d3 * double(floor(n_avg / 16d)) ;; TODO: verify

      endif else begin

        delta_x = double(n_avg) * (1024d / 150d3 * 16d)

      endelse

      for i = 0, n_elements(xspec_dat_i.x) - 1 do begin

        xspec_dat_x = [xspec_dat_x, xspec_dat_i.x[i] + delta_x * dindgen(n_spec)]

      endfor

      data_v = transpose(rebin(freq_bins.freq_avg,$
        n_elements(freq_bins.freq_avg),$
        n_elements(xspec_dat_x)))

      ; TODO: fix for negative numbers (no log)

      if xspec_type EQ 'p1' or xspec_type EQ 'p2' then begin

        store_data, prefix + 'xspec_' + xspec_type + '_converted', $
          data = {x:xspec_dat_x, $
          y:(spp_fld_dfb_psuedo_log_decompress(xspec_dat_y, $
          type = 'spectra', /high_gain)), $
          v:data_v}

        ;options, prefix + 'xspec_' + xspec_type + '_converted', 'ztitle', 'Log Auto [arb.]'

      endif else begin

        store_data, prefix + 'xspec_' + xspec_type + '_converted', $
          data = {x:xspec_dat_x, $
          y:(spp_fld_dfb_psuedo_log_decompress(xspec_dat_y, $
          type = 'xspectra', /high_gain)), $
          v:data_v}

      endelse

      options, prefix + 'xspec_' + xspec_type + '_converted', 'panel_size', 2
      options, prefix + 'xspec_' + xspec_type + '_converted', 'spec', 1
      options, prefix + 'xspec_' + xspec_type + '_converted', 'no_interp', 1
      options, prefix + 'xspec_' + xspec_type + '_converted', 'zlog', strmid(xspec_type,0,1) EQ 'p' ? 1 : 0
      options, prefix + 'xspec_' + xspec_type + '_converted', 'ylog', 1
      options, prefix + 'xspec_' + xspec_type + '_converted', 'ystyle', 1
      options, prefix + 'xspec_' + xspec_type + '_converted', 'yrange', minmax(freq_bins.freq_avg)
      options, prefix + 'xspec_' + xspec_type + '_converted', 'datagap', 300.

    endfor

  end

  get_data, prefix + 'xspec_p1_converted', dat = p1_dat
  get_data, prefix + 'xspec_p2_converted', dat = p2_dat
  get_data, prefix + 'xspec_rc_converted', dat = rc_dat
  get_data, prefix + 'xspec_ic_converted', dat = ic_dat

  if size(/type, p1_dat) EQ 8 OR $
    size(/type, p2_dat) EQ 8 OR $
    size(/type, rc_dat) EQ 8 OR $
    size(/type, ic_dat) EQ 8 then begin

    coh = (rc_dat.y^2 + ic_dat.y^2) / (p1_dat.y * p2_dat.y)

    phase  = atan(Ic_dat.y / Rc_dat.y) * 180d / !PI
    ;    phase[where( finite(coh) EQ 0 )] = !VALUES.F_NAN
    ;    phase[where( coh LT 0.05 )] = !VALUES.F_NAN

    ;    stop

    store_data, prefix + 'coherence', data = {x:p1_dat.x, $
      y:coh, v:data_v}

    options, prefix + 'coherence', 'panel_size', 2
    options, prefix + 'coherence', 'spec', 1
    options, prefix + 'coherence', 'no_interp', 1
    options, prefix + 'coherence', 'zlog', 1
    options, prefix + 'coherence', 'ylog', 1
    options, prefix + 'coherence', 'ystyle', 1
    options, prefix + 'coherence', 'datagap', 300.
    options, prefix + 'coherence', 'yrange', minmax(freq_bins.freq_avg)

    store_data, prefix + 'phase', data = {x:p1_dat.x, $
      y:phase, v:data_v}

    options, prefix + 'phase', 'panel_size', 2
    options, prefix + 'phase', 'spec', 1
    options, prefix + 'phase', 'no_interp', 1
    options, prefix + 'phase', 'ylog', 1
    options, prefix + 'phase', 'ystyle', 1
    options, prefix + 'phase', 'datagap', 300.
    options, prefix + 'phase', 'yrange', minmax(freq_bins.freq_avg)


  endif


  dfb_xspec_names = tnames(prefix + '*')

  if dfb_xspec_names[0] NE '' then begin

    for i = 0, n_elements(dfb_xspec_names) - 1 do begin

      dfb_xspec_name_i = strmid(dfb_xspec_names[i], strlen(prefix))

      if dfb_xspec_name_i EQ 'spec_converted' then begin

        options, prefix + dfb_xspec_name_i, 'ytitle', $
          'SPP DFB!C' + ac_dc_string + ' XSPEC' + $
          string(spec_ind)

        options, prefix + dfb_xspec_name_i, 'ysubtitle', 'Freq [Hz]'

      endif else begin

        if strmid(prefix + dfb_xspec_name_i,6,/rev) EQ '_string' then begin

          options, prefix + dfb_xspec_name_i, 'ysubtitle', ''

          dfb_xspec_name_ytitle = $
            strmid(dfb_xspec_name_i, 0, strlen(dfb_xspec_name_i) - 7)

        endif else begin

          dfb_xspec_name_ytitle = dfb_xspec_name_i

        endelse

        dfb_xspec_name_ytitle = $
          strjoin(strsplit($
          strjoin(strsplit($
          strjoin(strsplit($
          strjoin(strsplit($
          dfb_xspec_name_ytitle,$
          '_converted', /ex, /reg)),$
          'erence$', /ex, /reg)),$     ; coherence -> coh in title
          'se$', /ex, /reg)),$         ; phase -> pha in title
          '_', /ex),'!C')

        options, prefix + dfb_xspec_name_i, 'ytitle', $
          'DFB!C' + ac_dc_string + ' XSP' + $
          string(xspec_ind) + '!C' + strupcase(dfb_xspec_name_ytitle)

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