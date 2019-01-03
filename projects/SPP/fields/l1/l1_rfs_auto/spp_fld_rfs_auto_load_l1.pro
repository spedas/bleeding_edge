pro spp_fld_rfs_auto_load_l1, file, prefix = prefix, color = color

  if n_elements(file) LT 1 or file[0] EQ '' then return

  lfr_flag = strpos(prefix, 'lfr') NE -1
  if lfr_flag then receiver_str = 'LFR' else receiver_str = 'HFR'

;  receiver_str = strupcase(strmid(prefix, 12, 3))
;  if receiver_str EQ 'LFR' then lfr_flag = 1 else lfr_flag = 0

  rfs_freqs = spp_fld_rfs_freqs(lfr = lfr_flag)

  cdf2tplot, file, prefix = prefix

  options, prefix + 'compression', 'yrange', [0, 1]
  options, prefix + 'compression', 'ystyle', 1
  options, prefix + 'compression', 'colors', color
  options, prefix + 'compression', 'yminor', 1
  ;options, prefix + 'compression', 'psym', 4
  options, prefix + 'compression', 'psym_lim', 100
  options, prefix + 'compression', 'symsize', 0.5
  options, prefix + 'compression', 'panel_size', 0.35
  options, prefix + 'compression', 'ytitle', receiver_str + '!CAUTO!CCmprs'
  options, prefix + 'compression', 'ysubtitle', ''

  options, prefix + 'peaks', 'yrange', [0, 1]
  options, prefix + 'peaks', 'ystyle', 1
  options, prefix + 'peaks', 'colors', color
  options, prefix + 'peaks', 'yminor', 1
;  options, prefix + 'peaks', 'psym', 4
  options, prefix + 'peaks', 'psym_lim', 100
  options, prefix + 'peaks', 'symsize', 0.5
  options, prefix + 'peaks', 'panel_size', 0.35
  options, prefix + 'peaks', 'ytitle', receiver_str + '!CAUTO!CPks En'
  options, prefix + 'peaks', 'ysubtitle', ''

  options, prefix + 'averages', 'yrange', [0, 1]
  options, prefix + 'averages', 'ystyle', 1
  options, prefix + 'averages', 'colors', color
  options, prefix + 'averages', 'yminor', 1
;  options, prefix + 'averages', 'psym', 4
  options, prefix + 'averages', 'psym_lim', 100
  options, prefix + 'averages', 'symsize', 0.5
  options, prefix + 'averages', 'panel_size', 0.35
  options, prefix + 'averages', 'ytitle', receiver_str + '!CAUTO!CAvg En'
  options, prefix + 'averages', 'ysubtitle', ''

  options, prefix + 'gain', 'yrange', [-0.25, 1.25]
  options, prefix + 'gain', 'yticks', 1
  options, prefix + 'gain', 'ytickv', [0,1]
  options, prefix + 'gain', 'ytickname', ['Lo','Hi']
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'colors', color
  options, prefix + 'gain', 'yminor', 1
;  options, prefix + 'gain', 'psym', 4
  options, prefix + 'gain', 'psym_lim', 100
  options, prefix + 'gain', 'symsize', 0.5
  options, prefix + 'gain', 'panel_size', 0.35
  options, prefix + 'gain', 'ytitle', receiver_str + '!CAUTO!CGain'
  options, prefix + 'gain', 'ysubtitle', ''

  options, prefix + 'hl', 'yrange', [0, 3]
  options, prefix + 'hl', 'yticks', 3
  options, prefix + 'hl', 'ystyle', 1
  options, prefix + 'hl', 'colors', color
  options, prefix + 'hl', 'yminor', 1
;  options, prefix + 'hl', 'psym', 4
  options, prefix + 'hl', 'psym_lim', 100
  options, prefix + 'hl', 'symsize', 0.5
  options, prefix + 'hl', 'panel_size', 0.5
  options, prefix + 'hl', 'ytitle', receiver_str + '!CAUTO!CHL'
  options, prefix + 'hl', 'ysubtitle', ''

  options, prefix + 'nsum', 'yrange', [0, 80]
  options, prefix + 'nsum', 'ystyle', 1
  options, prefix + 'nsum', 'yminor', 1
  options, prefix + 'nsum', 'colors', color
;  options, prefix + 'nsum', 'psym', 4
  options, prefix + 'nsum', 'psym_lim', 100
  options, prefix + 'nsum', 'symsize', 0.5
  options, prefix + 'nsum', 'ytitle', receiver_str + '!CAUTO!CNSUM'
  options, prefix + 'nsum', 'ysubtitle', ''

  options, prefix + 'ch?', 'yrange', [0, 7]
  options, prefix + 'ch?', 'ystyle', 1
  options, prefix + 'ch?', 'yminor', 1
  options, prefix + 'ch?', 'colors', color
;  options, prefix + 'ch?', 'psym', 4
  options, prefix + 'ch?', 'psym_lim', 100
  options, prefix + 'ch?', 'symsize', 0.5
  options, prefix + 'ch0', 'ytitle', receiver_str + '!CAUTO!CCH0 SRC'
  options, prefix + 'ch1', 'ytitle', receiver_str + '!CAUTO!CCH1 SRC'
  options, prefix + 'ch?', 'ysubtitle', ''

  options, prefix + 'ch?_string', 'tplot_routine', 'strplot'
  options, prefix + 'ch?_string', 'yrange', [-0.1,1.0]
  options, prefix + 'ch?_string', 'ystyle', 1
  options, prefix + 'ch?_string', 'yticks', 1
  options, prefix + 'ch?_string', 'ytickformat', '(A1)'
  options, prefix + 'ch?_string', 'noclip', 0
  options, prefix + 'ch?_string', 'ysubtitle', ''
  options, prefix + 'ch0_string', 'ytitle', receiver_str + '!CAUTO!CCH0 SRC'
  options, prefix + 'ch1_string', 'ytitle', receiver_str + '!CAUTO!CCH1 SRC'

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

  options, prefix + 'spec0_ch0', 'ytitle', receiver_str + '!CAUTO!CSPEC0 CH0 RAW'
  options, prefix + 'spec0_ch1', 'ytitle', receiver_str + '!CAUTO!CSPEC0 CH1 RAW'

  options, prefix + 'spec1_ch0', 'ytitle', receiver_str + '!CAUTO!CSPEC1 CH0 RAW'
  options, prefix + 'spec1_ch1', 'ytitle', receiver_str + '!CAUTO!CSPEC1 CH1 RAW'

  options, prefix + 'peaks_ch0', 'ytitle', receiver_str + '!CAUTO!CPEAKS CH0 RAW'
  options, prefix + 'peaks_ch1', 'ytitle', receiver_str + '!CAUTO!CPEAKS CH1 RAW'

  options, prefix + 'averages_ch0', 'ytitle', receiver_str + '!CAUTO!CAVERAGES CH0 RAW'
  options, prefix + 'averages_ch1', 'ytitle', receiver_str + '!CAUTO!CAVERAGES CH1 RAW'


  get_data, prefix + 'gain', data = rfs_gain_dat
  get_data, prefix + 'nsum', data = rfs_nsum

  lo_gain = where(rfs_gain_dat.y EQ 0, n_lo_gain)

  ; TODO: fix loading when peaks = 0

  raw_spectra = ['peaks_ch0', 'peaks_ch1', $
    'averages_ch0', 'averages_ch1', $
    'spec0_ch0', 'spec0_ch1', $
    'spec1_ch0', 'spec1_ch1']

  for i = 0, n_elements(raw_spectra) - 1 do begin

    raw_spec_i = raw_spectra[i]

    get_data, prefix + raw_spec_i, data = raw_spec_data

    if size(raw_spec_data, /type) EQ 8 then begin

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

      if lfr_flag then begin

        size_spec = size(converted_spec_data, /dim)

        if n_elements(size_spec) EQ 2 then begin

          cic_r = 8ll
          cic_n = 4ll
          cic_m = 1ll

          ; TODO: Check for when CIC M = 2

          cic_factor = $
            rebin($
            transpose((sin(!DPI * cic_m * rfs_freqs.reduced_freq / 4.8e6) / $
            sin(!DPI * rfs_freqs.reduced_freq / 4.8d6 / cic_r))^(2 * cic_n) / $
            (cic_r * cic_m)^(2 * cic_n)), $
            size(converted_spec_data,/dim))

          converted_spec_data /= cic_factor

        endif

      endif else begin

        cic_factor = 1d

      endelse

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

      ;      options, prefix + raw_spec_i + '_converted', 'yrange', $
      ;        [min(rfs_freqs.reduced_freq), max(rfs_freqs.reduced_freq)]
      if lfr_flag then begin
        options, prefix + raw_spec_i + '_converted', $
          'yrange', [1.e4, 2.e6]
      endif else begin
        options, prefix + raw_spec_i + '_converted', $
          'yrange', [1.e6, 2.e7]
      endelse

      options, prefix + raw_spec_i + '_converted', 'ystyle', 1
      options, prefix + raw_spec_i + '_converted', 'datagap', 60
      options, prefix + raw_spec_i + '_converted', 'panel_size', 2.

      ytitle = receiver_str + ' AUTO!C' + strupcase(raw_spec_i)

      avg_pos = strpos(ytitle, 'AVERAGES')

      if avg_pos GE 0 then ytitle = strmid(ytitle, 0, avg_pos) + 'AVGS' + strmid(ytitle, avg_pos+8)

      ch_str = strmid(raw_spec_i,strlen(raw_spec_i) - 3, 3)

      get_data, prefix + ch_str + '_string', dat = ch_src_dat

      if size(ch_src_dat, /type) NE 8 then $
        get_data, prefix + ch_str, dat = ch_src_dat

      if size(ch_src_dat, /type) EQ 8 then begin

        if size(ch_src_dat.y[0], /type) NE 7 then src_string = 'SRC ' else $
          src_string = ''

        if n_elements(uniq(ch_src_dat.y) EQ 1) then begin
          ;options, prefix + raw_spec_i + '_converted', 'ysubtitle', $
          ;'SRC:' + strcompress(string(ch_src_dat.y[0]))

          ytitle = ytitle + '!C' + src_string + strcompress(string(ch_src_dat.y[0]))


        endif

        get_data, prefix + ch_str, dat = ch_src_dat_int

        src_hist = histogram(ch_src_dat_int.y, rev = src_rev, locations = src_loc)

        for j = 0, n_elements(src_loc) do begin

          if src_rev[j+1] GT src_rev[j] then begin

            inds = src_rev[src_rev[j]:src_rev[j+1]-1]


            src_string2 = strcompress(string(ch_src_dat.y[inds[0]]), /remove_all)

            ytitle2 = receiver_str + ' AUTO!C' + strupcase(raw_spec_i) + '!C' + $
              src_string + src_string2

            dash_pos = strpos(src_string2, '-')

            if dash_pos GE 0 then src_string2 = strmid(src_string2, 0, dash_pos) + strmid(src_string2, dash_pos+1)

            src_name = prefix + raw_spec_i + '_converted_' + src_string2

            avg_pos = strpos(ytitle2, 'AVERAGES')

            if avg_pos GE 0 then ytitle2 = strmid(ytitle2, 0, avg_pos) + 'AVGS' + strmid(ytitle2, avg_pos+8)

            ;if avg_pos GE 0 then stop
            ;stop


            store_data, src_name, $
              data = {x:(raw_spec_data.x)[inds], y:converted_spec_data[inds,*], $
              v:rfs_freqs.reduced_freq}

            options, src_name, 'spec', 1
            options, src_name, 'no_interp', 1
            options, src_name, 'ylog', 1
            options, src_name, 'zlog', 1
            options, src_name, 'ztitle', '[V2/Hz]'
            options, src_name, 'ystyle', 1
            options, src_name, 'datagap', 60
            options, src_name, 'panel_size', 2.
            options, src_name, 'ytitle', ytitle2

            options, src_name,  'ysubtitle', 'Freq [Hz]'

          endif

        endfor

        ;         stop

      endif

      options, prefix + raw_spec_i + '_converted', 'ytitle', $
        ytitle

      options, prefix + raw_spec_i + '_converted', 'ysubtitle', $
        'Freq [Hz]'

    end

  endfor

end