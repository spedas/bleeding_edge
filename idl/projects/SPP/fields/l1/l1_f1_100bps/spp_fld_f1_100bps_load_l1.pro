pro spp_fld_f1_100bps_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_f1_100bps_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  options, prefix + 'DCB_ARCWRPTR', 'ytickformat', '(I16)'
  options, prefix + 'DCB_ARCWRPTR', 'colors', '6'

  options, prefix + 'VOLT1', 'colors', 6 ; red
  options, prefix + 'VOLT2', 'colors', 4 ; green
  options, prefix + 'VOLT3', 'colors', 2 ; blue
  options, prefix + 'VOLT4', 'colors', 1 ; magenta

  options, prefix + 'VOLT1', 'labels', '1'
  options, prefix + 'VOLT2', 'labels', '  2'
  options, prefix + 'VOLT3', 'labels', '    3'
  options, prefix + 'VOLT4', 'labels', '      4'

  store_data, prefix + 'V_PEAK', $
    data = prefix + 'VOLT?'

  options, prefix + 'MNMX_V1', 'colors', 6 ; red
  options, prefix + 'MNMX_V2', 'colors', 4 ; green
  options, prefix + 'MNMX_V3', 'colors', 2 ; blue
  options, prefix + 'MNMX_V4', 'colors', 1 ; magenta

  options, prefix + 'MNMX_V1', 'labels', '1'
  options, prefix + 'MNMX_V2', 'labels', '  2'
  options, prefix + 'MNMX_V3', 'labels', '    3'
  options, prefix + 'MNMX_V4', 'labels', '      4'

  store_data, prefix + 'V_MNMX', $
    data = prefix + 'MNMX_V?'


  options, prefix + '*BX', 'colors', 2 ; red
  options, prefix + '*BY', 'colors', 4 ; green
  options, prefix + '*BZ', 'colors', 6 ; blue

  options, prefix + '*BX', 'labels', 'X'
  options, prefix + '*BY', 'labels', '  Y'
  options, prefix + '*BZ', 'labels', '    Z'

  store_data, prefix + 'B_PEAK', $
    data = prefix + ['BX', 'BY', 'BZ']

  store_data, prefix + 'B_MNMX', $
    data = prefix + 'MNMX_B?'

  options, prefix + 'CBS_*0', 'colors', 6
  options, prefix + 'CBS_*1', 'colors', 4
  options, prefix + 'CBS_*2', 'colors', 2
  options, prefix + 'CBS_*3', 'colors', 1 ; magenta

  options, prefix + 'CBS_*0', 'labels', '0'
  options, prefix + 'CBS_*1', 'labels', '  1'
  options, prefix + 'CBS_*2', 'labels', '    2'
  options, prefix + 'CBS_*3', 'labels', '      3'

  store_data, prefix + 'CBS_PEAK', $
    data = prefix + 'CBS_PEAK?'

  options, prefix + 'CBS_PEAK', 'yrange', [0,256]
  options, prefix + 'CBS_PEAK', 'ystyle', 1
  options, prefix + 'CBS_PEAK', 'yticks', 4
  options, prefix + 'CBS_PEAK', 'yminor', 4

  store_data, prefix + 'CBS_AVG', $
    data = prefix + 'CBS_AVG?'

  options, prefix + 'CBS_AVG', 'yrange', [0,256]
  options, prefix + 'CBS_AVG', 'ystyle', 1
  options, prefix + 'CBS_AVG', 'yticks', 4
  options, prefix + 'CBS_AVG', 'yminor', 4

  options, prefix + 'DFB_BURST', 'colors', '6'

  options, prefix + ['DFB_V34AC_PEAK', 'DFB_SCM_PEAK'], 'spec', 1
  options, prefix + ['DFB_V34AC_PEAK', 'DFB_SCM_PEAK'], 'no_interp', 1

  options, prefix + ['DFB_V34AC_AVG', 'DFB_SCM_AVG'], 'spec', 1
  options, prefix + ['DFB_V34AC_AVG', 'DFB_SCM_AVG'], 'no_interp', 1

  dfb_bpf_items = prefix + ['DFB_V34AC_PEAK', 'DFB_SCM_PEAK', $
    'DFB_V34AC_AVG', 'DFB_SCM_AVG']

  dfb_bpf_bins = spp_get_bp_bins_04_ac()

  for i = 0, n_elements(dfb_bpf_items) - 1 do begin

    dfb_bpf_item = dfb_bpf_items[i]

    get_data, dfb_bpf_item, data = dfb_bpf_data

    if size(dfb_bpf_data, /type) EQ 8 then begin

      store_data, dfb_bpf_item + '_converted', $
        data = {x:dfb_bpf_data.x, $
        y:spp_fld_dfb_psuedo_log_decompress(dfb_bpf_data.y, type = 'bandpass'), $
        v:dfb_bpf_bins.freq_avg}

      options, dfb_bpf_item + '_converted', 'panel_size', 1.25
      options, dfb_bpf_item + '_converted', 'spec', 1
      options, dfb_bpf_item + '_converted', 'no_interp', 1
      options, dfb_bpf_item + '_converted', 'ylog', 1
      options, dfb_bpf_item + '_converted', 'zlog', 1
      options, dfb_bpf_item + '_converted', 'ystyle', 1
      options, dfb_bpf_item + '_converted', 'yrange', minmax(dfb_bpf_bins.freq_avg)
      options, dfb_bpf_item + '_converted', 'ysubtitle', 'Freq [Hz]'

    endif

  endfor

  options, prefix + ['FLAGS'], 'tplot_routine', 'bitplot'
  options, prefix + ['FLAGS'], 'numbits', 4
  options, prefix + ['FLAGS'], 'psyms', 7
  options, prefix + ['FLAGS'], 'yminor', 1
  options, prefix + ['FLAGS'], 'ytickformat', 'spp_fld_ticks_blank'

  options, prefix + ['FLAGS'], 'labels', $
    ['THRUST', 'AEBHSK', 'SCMCAL', 'SPRTMR']
  options, prefix + ['FLAGS'], 'colors', [1,2,4,6]

  options, prefix + ['RFS*'], 'colors', 6

  options, prefix + ['RFS_HITS'], 'tplot_routine', 'bitplot'
  options, prefix + ['RFS_HITS'], 'numbits', 2
  options, prefix + ['RFS_HITS'], 'psyms', 7
  options, prefix + ['RFS_HITS'], 'yminor', 1
  options, prefix + ['RFS_HITS'], 'yticks', 3
  options, prefix + ['RFS_HITS'], 'ytickformat', 'spp_fld_ticks_blank'

  options, prefix + ['RFS_HITS'], 'labels', $
    ['LO', 'HI']


  f1_100bps_names = tnames(prefix + '*')

  if f1_100bps_names[0] NE '' then begin

    for i = 0, n_elements(f1_100bps_names)-1 do begin

      name = f1_100bps_names[i]

      get_data, name, alim = alim

      options, name, 'ynozero', 1
      ;options, name, 'colors', [6]
      options, name, 'ytitle', '100BPS!C' + $
        strjoin(strsplit($
        strjoin(strsplit($
        name.Remove(0, prefix.Strlen()-1),$
        '_converted', /ex, /reg)),$
        '_', /ex),'!C')

      str_element,alim,'ysubtitle',ysubtitle
      if n_elements(ysubtitle) GT 0 then begin
        if ysubtitle EQ '[None]' then options, name, 'ysubtitle', ' '
      endif

      ;options, name, 'psym', -4
      options, name, 'psym_lim', 50
      options, name, 'symsize', 0.5

    endfor

  endif

  options, '*f1_100*', 'datagap', 300.

;  options, '*f1_100*', 'datagap', 60.


  options, '*f1_100*converted', 'datagap',300.

end