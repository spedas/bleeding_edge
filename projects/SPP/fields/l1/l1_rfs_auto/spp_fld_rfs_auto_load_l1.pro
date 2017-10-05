pro spp_fld_rfs_auto_load_l1, file, prefix = prefix, color = color

  if n_elements(file) NE 1 or file EQ '' then return

  receiver_str = strupcase(strmid(prefix, 12, 3))

  if receiver_str EQ 'LFR' then lfr_flag = 1 else lfr_flag = 0

  rfs_freqs = spp_fld_rfs_freqs(lfr = lfr_flag)

  cdf2tplot, file, prefix = prefix

  options, prefix + 'compression', 'yrange', [0, 1]
  options, prefix + 'compression', 'ystyle', 1
  options, prefix + 'compression', 'colors', color
  options, prefix + 'compression', 'yminor', 1
  options, prefix + 'compression', 'psym', 4
  options, prefix + 'compression', 'symsize', 0.5
  options, prefix + 'compression', 'panel_size', 0.35
  options, prefix + 'compression', 'ytitle', receiver_str + ' Auto!CCmprs'

  options, prefix + 'peaks', 'yrange', [0, 1]
  options, prefix + 'peaks', 'ystyle', 1
  options, prefix + 'peaks', 'colors', color
  options, prefix + 'peaks', 'yminor', 1
  options, prefix + 'peaks', 'psym', 4
  options, prefix + 'peaks', 'symsize', 0.5
  options, prefix + 'peaks', 'panel_size', 0.35
  options, prefix + 'peaks', 'ytitle', receiver_str + ' Auto!CPks En'

  options, prefix + 'averages', 'yrange', [0, 1]
  options, prefix + 'averages', 'ystyle', 1
  options, prefix + 'averages', 'colors', color
  options, prefix + 'averages', 'yminor', 1
  options, prefix + 'averages', 'psym', 4
  options, prefix + 'averages', 'symsize', 0.5
  options, prefix + 'averages', 'panel_size', 0.35
  options, prefix + 'averages', 'ytitle', receiver_str + ' Auto!CAvg En'

  options, prefix + 'gain', 'yrange', [0, 1]
  options, prefix + 'gain', 'yticks', 1
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'colors', color
  options, prefix + 'gain', 'yminor', 1
  options, prefix + 'gain', 'psym', 4
  options, prefix + 'gain', 'symsize', 0.5
  options, prefix + 'gain', 'panel_size', 0.35
  options, prefix + 'gain', 'ytitle', receiver_str + ' Auto!CGain'

  options, prefix + 'hl', 'yrange', [0, 3]
  options, prefix + 'hl', 'yticks', 3
  options, prefix + 'hl', 'ystyle', 1
  options, prefix + 'hl', 'colors', color
  options, prefix + 'hl', 'yminor', 1
  options, prefix + 'hl', 'psym', 4
  options, prefix + 'hl', 'symsize', 0.5
  options, prefix + 'hl', 'panel_size', 0.5
  options, prefix + 'hl', 'ytitle', receiver_str + ' Auto!CHL'

  options, prefix + 'nsum', 'yrange', [0, 128]
  options, prefix + 'nsum', 'ystyle', 1
  options, prefix + 'nsum', 'yminor', 1
  options, prefix + 'nsum', 'colors', color
  options, prefix + 'nsum', 'psym', 4
  options, prefix + 'nsum', 'symsize', 0.5
  options, prefix + 'nsum', 'ytitle', receiver_str + ' Auto!CNSUM'

  options, prefix + 'ch?', 'yrange', [0, 7]
  options, prefix + 'ch?', 'ystyle', 1
  options, prefix + 'ch?', 'yminor', 1
  options, prefix + 'ch?', 'colors', color
  options, prefix + 'ch?', 'psym', 4
  options, prefix + 'ch?', 'symsize', 0.5
  options, prefix + 'ch0', 'ytitle', receiver_str + ' Auto!CCH0 Source'
  options, prefix + 'ch1', 'ytitle', receiver_str + ' Auto!CCH1 Source'

  options, prefix + 'spec?_ch?', 'spec', 1
  options, prefix + 'spec?_ch?', 'no_interp', 1
  options, prefix + 'spec?_ch?', 'yrange', [0,64]
  options, prefix + 'spec?_ch?', 'ystyle', 1
  options, prefix + 'spec?_ch?', 'datagap', 60

  options, prefix + 'peaks_ch?', 'spec', 1
  options, prefix + 'peaks_ch?', 'no_interp', 1
  options, prefix + 'peaks_ch?', 'yrange', [0,64]
  options, prefix + 'peaks_ch?', 'ystyle', 1
  options, prefix + 'peaks_ch?', 'datagap', 60

  options, prefix + 'averages_ch?', 'spec', 1
  options, prefix + 'averages_ch?', 'no_interp', 1
  options, prefix + 'averages_ch?', 'yrange', [0,64]
  options, prefix + 'averages_ch?', 'ystyle', 1
  options, prefix + 'averages_ch?', 'datagap', 60

  options, prefix + 'spec0_ch0', 'ytitle', receiver_str + ' Auto!CSpec0 Ch0 Raw'
  options, prefix + 'spec0_ch1', 'ytitle', receiver_str + ' Auto!CSpec0 Ch1 Raw'

  options, prefix + 'spec1_ch0', 'ytitle', receiver_str + ' Auto!CSpec1 Ch0 Raw'
  options, prefix + 'spec1_ch1', 'ytitle', receiver_str + ' Auto!CSpec1 Ch1 Raw'

  options, prefix + 'peaks_ch0', 'ytitle', receiver_str + ' Auto!CPeaks Ch0 Raw'
  options, prefix + 'peaks_ch1', 'ytitle', receiver_str + ' Auto!CPeaks Ch1 Raw'

  options, prefix + 'averages_ch0', 'ytitle', receiver_str + ' Auto!CAverages Ch0 Raw'
  options, prefix + 'averages_ch1', 'ytitle', receiver_str + ' Auto!CAverages Ch1 Raw'


  get_data, prefix + 'gain', data = rfs_gain_dat
  get_data, prefix + 'nsum', data = rfs_nsum

  lo_gain = where(rfs_gain_dat.y EQ 0, n_lo_gain)

  raw_spectra = ['peaks_ch0', 'peaks_ch1', $
    'averages_ch0', 'averages_ch1', $
    'spec0_ch0', 'spec0_ch1', $
    'spec1_ch0', 'spec1_ch1']

  for i = 0, n_elements(raw_spectra) - 1 do begin

    raw_spec_i = raw_spectra[i]

    get_data, prefix + raw_spec_i, data = raw_spec_data

    converted_spec_data = spp_fld_rfs_float(raw_spec_data.y)

    ; Using definition of power spectral density
    ;  S = 2 * Nfft / fs |x|^2 / Wss where
    ; where |x|^2 is an auto spec value of the PFB/DFT
    ;
    ; 2             : from definition of S_PFB
    ; 3             : number of spectral bins summed together
    ; 4096          : number of FFT points
    ; 38.4e6        : fs in Hz (divide fs by 8 for LFR)
    ; 250           : RFS high gain (multiply by 50^2 later on if in low gain)
    ; 2048          : 2048 counts in the ADC = 1 volt
    ; 0.782         : WSS for our implementation of the PFB (see pfb_norm.pdf)
    ; 65536         : factor from integer PFB, equal to (2048./8.)^2

    ; TODO: Correct this for SCM data

    V2_factor = (2d/3d) * 4096d / 38.4d6 / ((250d*2048d)^2d * 0.782d * 65536d)

    if lfr_flag then V2_factor *= 8

    converted_spec_data *= V2_factor

    if n_lo_gain GT 0 then converted_spec_data[lo_gain, *] *= 2500.d

    converted_spec_data /= rebin(rfs_nsum.y,$
      n_elements(rfs_nsum.x),$
      n_elements(rfs_freqs.reduced_freq))

    store_data, prefix + raw_spec_i + '_converted', $
      data = {x:raw_spec_data.x, y:converted_spec_data, $
      v:rfs_freqs.reduced_freq}

    options, prefix + raw_spec_i + '_converted', 'spec', 1
    options, prefix + raw_spec_i + '_converted', 'no_interp', 1
    options, prefix + raw_spec_i + '_converted', 'ylog', 1
    options, prefix + raw_spec_i + '_converted', 'zlog', 1
    options, prefix + raw_spec_i + '_converted', 'ztitle', '[V2/Hz]'
    options, prefix + raw_spec_i + '_converted', 'yrange', $
      [min(rfs_freqs.reduced_freq), max(rfs_freqs.reduced_freq)]
    options, prefix + raw_spec_i + '_converted', 'ystyle', 1
    options, prefix + raw_spec_i + '_converted', 'datagap', 60
    options, prefix + raw_spec_i + '_converted', 'panel_size', 2.

    ytitle = receiver_str + ' AUTO!C' + strupcase(raw_spec_i)

    ch_str = strmid(raw_spec_i,strlen(raw_spec_i) - 3, 3)

    get_data, prefix + ch_str, dat = ch_src_dat

    if size(ch_src_dat, /type) EQ 8 then $
      if n_elements(uniq(ch_src_dat.y) EQ 1) then $
      ;options, prefix + raw_spec_i + '_converted', 'ysubtitle', $
      ;'SRC:' + strcompress(string(ch_src_dat.y[0]))
      ytitle = ytitle + '!C' + 'SRC' + strcompress(string(ch_src_dat.y[0]))

    options, prefix + raw_spec_i + '_converted', 'ytitle', $
      ytitle

    options, prefix + raw_spec_i + '_converted', 'ysubtitle', $
      'Freq [Hz]'

  endfor

  ;  get_data, prefix + 'spec0_ch0', data = rfs_dat_spec0_ch0
  ;
  ;  converted_data_spec0_ch0 = rfs_float(rfs_dat_spec0_ch0.y)
  ;
  ;  ; TODO replace hard coded gain value w/calibrated
  ;
  ;  if n_lo_gain GT 0 then converted_data_spec0_ch0[lo_gain, *] *= 2500.d
  ;
  ;  store_data, prefix + 'spec0_ch0_converted', $
  ;    data = {x:rfs_dat_spec0_ch0.x, y:converted_data_spec0_ch0, $
  ;    v:rfs_freqs.reduced_freq}
  ;
  ;  get_data, prefix + 'spec0_ch1', data = rfs_dat_spec0_ch1
  ;
  ;  converted_data_spec0_ch1 = rfs_float(rfs_dat_spec0_ch1.y)
  ;
  ;  if n_lo_gain GT 0 then converted_data_spec0_ch1[lo_gain, *] *= 2500.d
  ;
  ;  store_data, prefix + 'spec0_ch1_converted', $
  ;    data = {x:rfs_dat_spec0_ch1.x, y:converted_data_spec0_ch1, $
  ;    v:rfs_freqs.reduced_freq}
  ;
  ;  options, prefix + 'spec0_ch?_converted', 'spec', 1
  ;  options, prefix + 'spec0_ch?_converted', 'no_interp', 1
  ;  options, prefix + 'spec0_ch?_converted', 'ylog', 1
  ;  options, prefix + 'spec0_ch?_converted', 'zlog', 1
  ;  options, prefix + 'spec0_ch?_converted', 'yrange', [min(rfs_freqs.reduced_freq), max(rfs_freqs.reduced_freq)]
  ;  options, prefix + 'spec0_ch?_converted', 'ystyle', 1
  ;  options, prefix + 'spec0_ch?_converted', 'datagap', 60
  ;  options, prefix + 'spec0_ch?_converted', 'panel_size', 2.
  ;
  ;  options, prefix + 'spec0_ch0_converted', 'ytitle', receiver_str + ' Auto!CSpec0 Ch0'
  ;  options, prefix + 'spec0_ch1_converted', 'ytitle', receiver_str + ' Auto!CSpec0 Ch1'
  ;
  ;  get_data, prefix + 'ch0', dat = ch0_src_dat
  ;  if n_elements(uniq(ch0_src_dat.y) EQ 1) then $
  ;    options, prefix + 'spec0_ch0_converted', 'ysubtitle', $
  ;    'SRC:' + strcompress(string(ch0_src_dat.y[0]))
  ;
  ;  get_data, prefix + 'ch1', dat = ch1_src_dat
  ;  if n_elements(uniq(ch1_src_dat.y) EQ 1) then $
  ;    options, prefix + 'spec0_ch1_converted', 'ysubtitle', $
  ;    'SRC:' + strcompress(string(ch1_src_dat.y[0]))


end