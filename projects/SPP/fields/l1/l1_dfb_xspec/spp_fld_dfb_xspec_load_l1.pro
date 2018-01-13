pro spp_fld_dfb_xspec_load_l1, file, prefix = prefix

  ; TODO: More X-spectra testing and formatting

  cdf2tplot, file, prefix = prefix, varnames = varnames

  status_items = ['enable', 'concat', 'src1', 'src2', 'gain', 'navg']

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

  options, prefix + ['enable','gain'], 'yrange', [-0.25,1.25]
  options, prefix + ['enable','gain'], 'ystyle', 1
  options, prefix + ['enable','gain'], 'yticks', 1
  options, prefix + ['enable','gain'], 'ytickv', [0,1]
  options, prefix + ['enable','gain'], 'yminor', 1
  options, prefix + ['enable','gain'], 'ysubtitle', ''
  options, prefix + ['enable','gain'], 'panel_size', 0.35

  options, prefix + 'navg', 'yrange', [-0.5,10.5]
  options, prefix + 'navg', 'ystyle', 1
  options, prefix + 'navg', 'yminor', 1
  options, prefix + 'navg', 'panel_size', 0.5


  ac_dc_string = strupcase(strmid(prefix,12,2))
  xspec_ind = strmid(prefix, strlen(prefix)-2, 1)

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