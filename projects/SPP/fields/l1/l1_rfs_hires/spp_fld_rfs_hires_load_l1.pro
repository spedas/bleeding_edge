pro spp_fld_rfs_hires_load_l1, file, prefix = prefix, color = color

  ; TODO improve this check for valid CDF file and add to other routines
  if n_elements(file) LT 1 or file[0] EQ '' then return

  rfs_freqs = spp_fld_rfs_freqs(/lfr, plasma = rfs_plasma)

  lfr_flag = strpos(prefix, 'lfr') NE -1
  if lfr_flag then receiver_str = 'LFR' else receiver_str = 'HFR'

;  receiver_str = strupcase(strmid(prefix, 12, 3))
;  if receiver_str EQ 'LFR' then lfr_flag = 1 else lfr_flag = 0

  ; TODO: RFS HiRes frequencies and conversions
  ;rfs_freqs = spp_fld_rfs_freqs(lfr = lfr_flag)

  cdf2tplot, file, prefix = prefix

  options, prefix + 'compression', 'yrange', [0, 1]
  options, prefix + 'compression', 'ystyle', 1
  options, prefix + 'compression', 'colors', color
  options, prefix + 'compression', 'yminor', 1
  options, prefix + 'compression', 'psym', 4
  options, prefix + 'compression', 'symsize', 0.5
  options, prefix + 'compression', 'panel_size', 0.35
  options, prefix + 'compression', 'ytitle', receiver_str + ' HiRes!CCmprs'

  options, prefix + 'peaks', 'yrange', [0, 1]
  options, prefix + 'peaks', 'ystyle', 1
  options, prefix + 'peaks', 'colors', color
  options, prefix + 'peaks', 'yminor', 1
  options, prefix + 'peaks', 'psym', 4
  options, prefix + 'peaks', 'symsize', 0.5
  options, prefix + 'peaks', 'panel_size', 0.35
  options, prefix + 'peaks', 'ytitle', receiver_str + ' HiRes!CPks En'

  options, prefix + 'averages', 'yrange', [0, 1]
  options, prefix + 'averages', 'ystyle', 1
  options, prefix + 'averages', 'colors', color
  options, prefix + 'averages', 'yminor', 1
  options, prefix + 'averages', 'psym', 4
  options, prefix + 'averages', 'symsize', 0.5
  options, prefix + 'averages', 'panel_size', 0.35
  options, prefix + 'averages', 'ytitle', receiver_str + ' HiRes!CAvg En'

  options, prefix + 'gain', 'yrange', [0, 1]
  options, prefix + 'gain', 'yticks', 1
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'colors', color
  options, prefix + 'gain', 'yminor', 1
  options, prefix + 'gain', 'psym', 4
  options, prefix + 'gain', 'symsize', 0.5
  options, prefix + 'gain', 'panel_size', 0.35
  options, prefix + 'gain', 'ytitle', receiver_str + ' HiRes!CGain'

  options, prefix + 'hl', 'yrange', [0, 3]
  options, prefix + 'hl', 'yticks', 3
  options, prefix + 'hl', 'ystyle', 1
  options, prefix + 'hl', 'colors', color
  options, prefix + 'hl', 'yminor', 1
  options, prefix + 'hl', 'psym', 4
  options, prefix + 'hl', 'symsize', 0.5
  options, prefix + 'hl', 'panel_size', 0.5
  options, prefix + 'hl', 'ytitle', receiver_str + ' HiRes!CHL'

  options, prefix + 'nsum', 'yrange', [0, 128]
  options, prefix + 'nsum', 'ystyle', 1
  options, prefix + 'nsum', 'yminor', 1
  options, prefix + 'nsum', 'colors', color
  options, prefix + 'nsum', 'psym', 4
  options, prefix + 'nsum', 'symsize', 0.5
  options, prefix + 'nsum', 'ytitle', receiver_str + ' HiRes!CNSUM'

  options, prefix + 'peakmode', 'yrange', [0, 3]
  options, prefix + 'peakmode', 'ystyle', 1
  options, prefix + 'peakmode', 'yminor', 1
  options, prefix + 'peakmode', 'colors', color
  options, prefix + 'peakmode', 'psym', 4
  options, prefix + 'peakmode', 'symsize', 0.5
  options, prefix + 'peakmode', 'panel_size', 0.5
  options, prefix + 'peakmode', 'ytitle', receiver_str + ' HiRes!CPeakMode'

  options, prefix + 'peak_location', 'yrange', [0, 64]
  options, prefix + 'peak_location', 'ystyle', 1
  options, prefix + 'peak_location', 'yminor', 1
  options, prefix + 'peak_location', 'colors', color
  options, prefix + 'peak_location', 'psym', 4
  options, prefix + 'peak_location', 'symsize', 0.5
  options, prefix + 'peak_location', 'ytitle', receiver_str + ' HiRes!CPeak_location'

  options, prefix + 'ch?', 'yrange', [0, 7]
  options, prefix + 'ch?', 'ystyle', 1
  options, prefix + 'ch?', 'yminor', 1
  options, prefix + 'ch?', 'colors', color
  options, prefix + 'ch?', 'psym', 4
  options, prefix + 'ch?', 'symsize', 0.5
  options, prefix + 'ch0', 'ytitle', receiver_str + ' HiRes!CCH0 Source'
  options, prefix + 'ch1', 'ytitle', receiver_str + ' HiRes!CCH1 Source'

  options, prefix + 'spec0_ch?', 'spec', 1
  options, prefix + 'spec0_ch?', 'no_interp', 1
  options, prefix + 'spec0_ch?', 'yrange', [0,32]
  options, prefix + 'spec0_ch?', 'ystyle', 1
  options, prefix + 'spec0_ch?', 'datagap', 60

  options, prefix + 'spec0_ch0', 'ytitle', receiver_str + ' HiRes!CSpec0 Ch0 Raw'
  options, prefix + 'spec0_ch1', 'ytitle', receiver_str + ' HiRes!CSpec0 Ch1 Raw'


  get_data, prefix + 'nsum', data = rfs_nsum
  get_data, prefix + 'gain', data = rfs_gain_dat
  ;
  lo_gain = where(rfs_gain_dat.y EQ 0, n_lo_gain)
  ;
  ;  get_data, prefix + 'spec0_ch0', data = rfs_dat_spec0_ch0
  ;
  ;  ; TODO: Replace x3 (now it's in there to compare with LFR which is summed
  ;  ; across 3 bins / smoothed
  ;
  ;  converted_data_spec0_ch0 = spp_fld_rfs_float(rfs_dat_spec0_ch0.y) * 3
  ;
  ;  ; TODO replace hard coded gain value w/calibrated
  ;
  ;  if n_lo_gain GT 0 then converted_data_spec0_ch0[lo_gain, *] *= 2500.d
  ;
  ;  store_data, prefix + 'spec0_ch0_converted', $
  ;    data = {x:rfs_dat_spec0_ch0.x, y:converted_data_spec0_ch0}
  ;
  ;  get_data, prefix + 'spec0_ch1', data = rfs_dat_spec0_ch1
  ;
  ;  ; TODO: Replace x3 (now it's in there to compare with LFR which is summed
  ;  ; across 3 bins / smoothed
  ;
  ;  converted_data_spec0_ch1 = spp_fld_rfs_float(rfs_dat_spec0_ch1.y) * 3
  ;
  ;  if n_lo_gain GT 0 then converted_data_spec0_ch1[lo_gain, *] *= 2500.d
  ;
  ;  store_data, prefix + 'spec0_ch1_converted', $
  ;    data = {x:rfs_dat_spec0_ch0.x, y:converted_data_spec0_ch0}
  ;
  ;  options, prefix + 'spec0_ch?_converted', 'spec', 1
  ;  options, prefix + 'spec0_ch?_converted', 'no_interp', 1
  ;  options, prefix + 'spec0_ch?_converted', 'ylog', 0
  ;  options, prefix + 'spec0_ch?_converted', 'zlog', 0
  ;  options, prefix + 'spec0_ch?_converted', 'yrange', [0,32]
  ;  options, prefix + 'spec0_ch?_converted', 'ystyle', 1
  ;  options, prefix + 'spec0_ch?_converted', 'datagap', 60
  ;  options, prefix + 'spec0_ch?_converted', 'panel_size', 2.
  ;
  ;  options, prefix + 'spec0_ch0_converted', 'ytitle', receiver_str + ' HiRes!CSpec0 Ch0'
  ;  options, prefix + 'spec0_ch1_converted', 'ytitle', receiver_str + ' HiRes!CSpec0 Ch1'
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

  raw_spectra = ['peaks_ch0', 'peaks_ch1', $
    'averages_ch0', 'averages_ch1', $
    'spec0_ch0', 'spec0_ch1', $
    'spec1_ch0', 'spec1_ch1']

  lfr_flag = 1

  get_data, 'spp_fld_rfs_lfr_hires_peak_location', data = hires_loc

  hr_ind = []
  hr_freq = []
  hr_freq_max = []
  hr_freq_min = []
  hr_freq_all = []

  hr_ind = hires_loc.y - 8

  hr_freq = (rfs_plasma['LFR_FREQ'])[hr_ind]
  
  hr_freq_all = (rfs_plasma['PLASMA_SEL'])[hr_ind,*] * 1171.875d

  hr_freq_max = max(hr_freq_all,dim=2)
  hr_freq_min = min(hr_freq_all,dim=2)

;  for i = 0, n_elements(hires_loc.y)-1 do begin
;
;    hr_i = hires_loc.y[i]
;
;    hr_ind_i = where(rfs_plasma['LFR_IND'] EQ hr_i)
;
;    hr_freq_i = (rfs_plasma['LFR_FREQ'])[hr_ind_i]
;
;    hr_freq_all_i = (rfs_plasma['PLASMA_SEL'])[hr_ind_i,*] * 1171.875d
;
;    hr_freq_max_i = max(hr_freq_all_i)
;
;    hr_freq_min_i = min(hr_freq_all_i)
;
;    hr_ind = [hr_ind, hr_ind_i]
;
;    hr_freq = [hr_freq, hr_freq_i]
;    hr_freq_max = [hr_freq_max, hr_freq_max_i]
;    hr_freq_min = [hr_freq_min, hr_freq_min_i]
;
;    hr_freq_all = [hr_freq_all, hr_freq_all_i]
;
;  end
;
  store_data, 'spp_fld_rfs_lfr_hires_freq', $
    data = {x:hires_loc.x, y:hr_freq}

  store_data, 'spp_fld_rfs_lfr_hires_freq_max', $
    data = {x:hires_loc.x, y:hr_freq_max}

  store_data, 'spp_fld_rfs_lfr_hires_freq_min', $
    data = {x:hires_loc.x, y:hr_freq_min}

  options, 'spp_fld_rfs_lfr_hires_freq*', 'linestyle', 2
  options, 'spp_fld_rfs_lfr_hires_freq*', 'thick', 1
  options, 'spp_fld_rfs_lfr_hires_freq*', 'colors', 0


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
      ; 1             : number of spectral bins summed together (Note: this is
      ;               ; different for the RFS HiRes (1 instead of 3)
      ; 4096          : number of FFT points
      ; 38.4e6        : fs in Hz (divide fs by 8 for LFR)
      ; 250           : RFS high gain (multiply by 50^2 later on if in low gain)
      ; 2048          : 2048 counts in the ADC = 1 volt
      ; 0.782         : WSS for our implementation of the PFB (see pfb_norm.pdf)
      ; 65536         : factor from integer PFB, equal to (2048./8.)^2

      ; TODO: Correct this for SCM data

      V2_factor = (2d/1d) * 4096d / 38.4d6 / ((250d*2048d)^2d * 0.782d * 65536d)

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
            ((sin(!DPI * cic_m * hr_freq_all / 4.8e6) / $
            sin(!DPI * hr_freq_all / 4.8d6 / cic_r))^(2 * cic_n) / $
            (cic_r * cic_m)^(2 * cic_n))

          converted_spec_data /= cic_factor

        endif

      endif else begin

        cic_factor = 1d

      endelse

      if n_lo_gain GT 0 then converted_spec_data[lo_gain, *] *= 2500.d

      converted_spec_data /= rebin(rfs_nsum.y,$
        n_elements(rfs_nsum.x),32)

      store_data, prefix + raw_spec_i + '_converted', $
        data = {x:raw_spec_data.x, y:converted_spec_data, $
        v:hr_freq_all}

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

            ytitle2 = receiver_str + ' HiRes!C' + strupcase(raw_spec_i) + '!C' + $
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
              v:hr_freq_all}

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
  
;options, '*hires*' + ['peaks', 'averages'] + '*converted', 'yrange', [5e4,5e5]
;tplot, '*hires*' + ['peaks', 'averages'] + '*converted'


end