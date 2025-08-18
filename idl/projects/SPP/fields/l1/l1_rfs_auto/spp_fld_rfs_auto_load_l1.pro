;+
;
; NAME:
;   spp_fld_rfs_auto_load_l1
;
; $LastChangedBy: pulupa $
; $LastChangedDate: 2023-09-28 13:18:16 -0700 (Thu, 28 Sep 2023) $
; $LastChangedRevision: 32147 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_rfs_auto/spp_fld_rfs_auto_load_l1.pro $
;
;-

pro spp_fld_rfs_auto_load_l1, file, prefix = prefix, color = color, varformat = varformat
  compile_opt idl2

  if n_elements(file) lt 1 or file[0] eq '' then return

  lfr_flag = strpos(prefix, 'lfr') ne -1
  if lfr_flag then receiver_str = 'LFR' else receiver_str = 'HFR'

  ; receiver_str = strupcase(strmid(prefix, 12, 3))
  ; if receiver_str EQ 'LFR' then lfr_flag = 1 else lfr_flag = 0

  if file[0].Contains('lusee') then lusee = 1 else lusee = 0
  rfs_freqs = spp_fld_rfs_freqs(lfr = lfr_flag, lusee = lusee)

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  options, prefix + 'compression', 'yrange', [0, 1]
  options, prefix + 'compression', 'ystyle', 1
  options, prefix + 'compression', 'colors', color
  options, prefix + 'compression', 'yminor', 1
  ; options, prefix + 'compression', 'psym', 4
  options, prefix + 'compression', 'psym_lim', 100
  options, prefix + 'compression', 'symsize', 0.5
  options, prefix + 'compression', 'panel_size', 0.35
  options, prefix + 'compression', 'ytitle', receiver_str + '!CAUTO!CCmprs'
  options, prefix + 'compression', 'ysubtitle', ''
  options, prefix + 'compression', 'datagap', 120

  options, prefix + 'peaks', 'yrange', [-0.25, 1.25]
  options, prefix + 'peaks', 'yticks', 1
  options, prefix + 'peaks', 'ytickv', [0, 1]
  options, prefix + 'peaks', 'yminor', 1
  options, prefix + 'peaks', 'colors', color
  options, prefix + 'peaks', 'yminor', 1
  ; options, prefix + 'peaks', 'psym', 4
  options, prefix + 'peaks', 'psym_lim', 100
  options, prefix + 'peaks', 'symsize', 0.5
  options, prefix + 'peaks', 'panel_size', 0.35
  options, prefix + 'peaks', 'ytitle', receiver_str + '!CAUTO!CPks En'
  options, prefix + 'peaks', 'ysubtitle', ''
  options, prefix + 'peaks', 'datagap', 120

  options, prefix + 'averages', 'yrange', [-0.25, 1.25]
  options, prefix + 'averages', 'yticks', 1
  options, prefix + 'averages', 'ytickv', [0, 1]
  options, prefix + 'averages', 'yminor', 1
  options, prefix + 'averages', 'colors', color
  options, prefix + 'averages', 'yminor', 1
  ; options, prefix + 'averages', 'psym', 4
  options, prefix + 'averages', 'psym_lim', 100
  options, prefix + 'averages', 'symsize', 0.5
  options, prefix + 'averages', 'panel_size', 0.35
  options, prefix + 'averages', 'ytitle', receiver_str + '!CAUTO!CAvg En'
  options, prefix + 'averages', 'ysubtitle', ''
  options, prefix + 'averages', 'datagap', 120

  options, prefix + 'gain', 'yrange', [-0.25, 1.25]
  options, prefix + 'gain', 'yticks', 1
  options, prefix + 'gain', 'ytickv', [0, 1]
  options, prefix + 'gain', 'yminor', 1
  options, prefix + 'gain', 'ytickname', ['Lo', 'Hi']
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'colors', color
  ; options, prefix + 'gain', 'psym', 4
  options, prefix + 'gain', 'psym_lim', 100
  options, prefix + 'gain', 'symsize', 0.5
  options, prefix + 'gain', 'panel_size', 0.35
  options, prefix + 'gain', 'ytitle', receiver_str + '!CAUTO!CGain'
  options, prefix + 'gain', 'ysubtitle', ''
  options, prefix + 'gain', 'datagap', 120

  options, prefix + 'hl', 'yrange', [0, 3]
  options, prefix + 'hl', 'yticks', 3
  options, prefix + 'hl', 'ystyle', 1
  options, prefix + 'hl', 'colors', color
  options, prefix + 'hl', 'yminor', 1
  ; options, prefix + 'hl', 'psym', 4
  options, prefix + 'hl', 'psym_lim', 100
  options, prefix + 'hl', 'symsize', 0.5
  options, prefix + 'hl', 'panel_size', 0.5
  options, prefix + 'hl', 'ytitle', receiver_str + '!CAUTO!CHL'
  options, prefix + 'hl', 'ysubtitle', ''
  options, prefix + 'hl', 'datagap', 120

  options, prefix + 'nsum', 'yrange', [0, 100]
  options, prefix + 'nsum', 'ystyle', 1
  options, prefix + 'nsum', 'yminor', 1
  options, prefix + 'nsum', 'colors', color
  ; options, prefix + 'nsum', 'psym', 4
  options, prefix + 'nsum', 'psym_lim', 100
  options, prefix + 'nsum', 'symsize', 0.5
  options, prefix + 'nsum', 'ytitle', receiver_str + '!CAUTO!CNSUM'
  options, prefix + 'nsum', 'ysubtitle', ''
  options, prefix + 'nsum', 'datagap', 120

  options, prefix + 'ch?', 'yrange', [0, 7]
  options, prefix + 'ch?', 'ystyle', 1
  options, prefix + 'ch?', 'yminor', 1
  options, prefix + 'ch?', 'colors', color
  ; options, prefix + 'ch?', 'psym', 4
  options, prefix + 'ch?', 'psym_lim', 100
  options, prefix + 'ch?', 'symsize', 0.5
  options, prefix + 'ch0', 'ytitle', receiver_str + '!CAUTO!CCH0 SRC'
  options, prefix + 'ch1', 'ytitle', receiver_str + '!CAUTO!CCH1 SRC'
  options, prefix + 'ch?', 'ysubtitle', ''
  options, prefix + 'ch?', 'datagap', 120

  options, prefix + 'ch?_string', 'tplot_routine', 'strplot'
  options, prefix + 'ch?_string', 'yrange', [-0.1, 1.0]
  options, prefix + 'ch?_string', 'ystyle', 1
  options, prefix + 'ch?_string', 'yticks', 1
  options, prefix + 'ch?_string', 'ytickformat', '(A1)'
  options, prefix + 'ch?_string', 'noclip', 0
  options, prefix + 'ch?_string', 'ysubtitle', ''
  options, prefix + 'ch0_string', 'ytitle', receiver_str + '!CAUTO!CCH0 SRC'
  options, prefix + 'ch1_string', 'ytitle', receiver_str + '!CAUTO!CCH1 SRC'

  options, prefix + 'spec?_ch?', 'spec', 1
  options, prefix + 'spec?_ch?', 'no_interp', 1
  options, prefix + 'spec?_ch?', 'yrange', [0, 64]
  options, prefix + 'spec?_ch?', 'ystyle', 1
  options, prefix + 'spec?_ch?', 'datagap', 120

  options, prefix + 'peaks_ch?', 'spec', 1
  options, prefix + 'peaks_ch?', 'no_interp', 1
  options, prefix + 'peaks_ch?', 'yrange', [0, 64]
  options, prefix + 'peaks_ch?', 'ystyle', 1
  options, prefix + 'peaks_ch?', 'datagap', 120

  options, prefix + 'averages_ch?', 'spec', 1
  options, prefix + 'averages_ch?', 'no_interp', 1
  options, prefix + 'averages_ch?', 'yrange', [0, 64]
  options, prefix + 'averages_ch?', 'ystyle', 1
  options, prefix + 'averages_ch?', 'datagap', 120

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

  lo_gain = where(rfs_gain_dat.y eq 0, n_lo_gain, $
    complement = hi_gain, ncomplement = n_hi_gain)

  ; TODO: fix loading when peaks = 0

  raw_spectra = ['peaks_ch0', 'peaks_ch1', $
    'averages_ch0', 'averages_ch1']

  stored_names = []

  for i = 0, n_elements(raw_spectra) - 1 do begin
    raw_spec_i = raw_spectra[i]

    get_data, prefix + raw_spec_i, data = raw_spec_data

    if size(raw_spec_data, /type) eq 8 then begin
      ; See spp_fld_rfs_float for notes on 'zero_fix'

      converted_spec_data = spp_fld_rfs_float(raw_spec_data.y, /zero_fix)

      ; Below section is experimental code for correcting RFS
      ; data for low gain/high gain mismatch, by subtracting offset
      ; due to noise from the ADC. Not useful for most users at this
      ; point, will be added to a future version of processing.

      if getenv('SPP_FLD_RFS_LO_GAIN_CORRECT') ne '' then begin
        local_data_dir = '~/Desktop/spp_fld_test/EM_ucb/2020/10/' + $
          'rfs_hi_lo_test/'

        rec = strlowcase(receiver_str)

        lo_gain_file = local_data_dir + 'rfs_' + rec + '_lo_counts2perhz.sav'
        hi_gain_file = local_data_dir + 'rfs_' + rec + '_hi_counts2perhz.sav'

        if n_lo_gain gt 0 then begin
          restore, lo_gain_file

          background = transpose(rebin(ch0_pow_red, 64, n_lo_gain))

          converted_spec_data[lo_gain, *] -= background * 80d * 3d

          ; if (where(finite(converted_spec_data)))[0] GE 0 then stop
        endif

        if n_hi_gain gt 0 then begin
          restore, hi_gain_file

          background = transpose(rebin(ch0_pow_red, 64, n_hi_gain))

          converted_spec_data[hi_gain, *] -= background * 80d * 3d

          ; if (where(finite(converted_spec_data)))[0] GE 0 then stop
        endif
      endif

      ; Using definition of power spectral density
      ; S = 2 * Nfft / fs |x|^2 / Wss where
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

      V2_factor = (2d / 3d) * 4096d / 38.4d6 / ((250d * 2048d) ^ 2d * 0.782d * 65536d)

      if lfr_flag then V2_factor *= 8

      converted_spec_data *= V2_factor

      if lfr_flag then begin
        size_spec = size(converted_spec_data, /dim)

        if n_elements(size_spec) eq 2 then begin
          cic_r = 8ll
          cic_n = 4ll
          cic_m = 1ll

          ; TODO: Check for when CIC M = 2

          cic_factor = $
            rebin( $
              transpose((sin(!dpi * cic_m * rfs_freqs.reduced_freq / 4.8e6) / $
                sin(!dpi * rfs_freqs.reduced_freq / 4.8d6 / cic_r)) ^ (2 * cic_n) / $
                (cic_r * cic_m) ^ (2 * cic_n)), $
              size(converted_spec_data, /dim))

          converted_spec_data /= cic_factor
        endif
      endif else begin
        cic_factor = 1d
      endelse

      if n_lo_gain gt 0 then converted_spec_data[lo_gain, *] *= 2500.d

      if raw_spec_i eq 'averages_ch0' or raw_spec_i eq 'averages_ch1' then $
        converted_spec_data /= rebin(rfs_nsum.y, $
          n_elements(rfs_nsum.x), $
          n_elements(rfs_freqs.reduced_freq))

      store_data, prefix + raw_spec_i + '_converted', $
        data = {x: raw_spec_data.x, y: converted_spec_data, $
          v: rfs_freqs.reduced_freq}

      options, prefix + raw_spec_i + '_converted', 'spec', 1
      options, prefix + raw_spec_i + '_converted', 'no_interp', 1
      options, prefix + raw_spec_i + '_converted', 'ylog', 1
      options, prefix + raw_spec_i + '_converted', 'zlog', 1
      options, prefix + raw_spec_i + '_converted', 'ztitle', '[V2/Hz]'

      ; options, prefix + raw_spec_i + '_converted', 'yrange', $
      ; [min(rfs_freqs.reduced_freq), max(rfs_freqs.reduced_freq)]
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

      if avg_pos ge 0 then ytitle = strmid(ytitle, 0, avg_pos) + 'AVGS' + strmid(ytitle, avg_pos + 8)

      ; Get information on the source of the spectra.  Return as a string
      ; if available, if not as a number (retained for backwards compatibility
      ; with early I&T files which only had a number and no string)

      ch_str = strmid(raw_spec_i, strlen(raw_spec_i) - 3, 3)

      get_data, prefix + ch_str + '_string', dat = ch_src_dat

      if size(ch_src_dat, /type) ne 8 then $
        get_data, prefix + ch_str, dat = ch_src_dat

      if size(ch_src_dat, /type) eq 8 then begin
        if size(ch_src_dat.y[0], /type) ne 7 then src_string = 'SRC ' else $
          src_string = ''

        ; Get the source again, as an integer this time.

        get_data, prefix + ch_str, dat = ch_src_dat_int

        ; Split the spectra into individual tplot items by source.
        ; For example, if the above commands load data into the tplot item
        ;
        ; spp_fld_rfs_hfr_auto_averages_ch0_converted
        ;
        ; and that item has some spectra from each of V1-V2, V1, and V3, this
        ; code will create three separate items
        ;
        ; spp_fld_rfs_hfr_auto_averages_ch0_converted_V1V2
        ; spp_fld_rfs_hfr_auto_averages_ch0_converted_V1
        ; spp_fld_rfs_hfr_auto_averages_ch0_converted_V3
        ;
        ; with the appropriate titles

        src_hist = histogram(ch_src_dat_int.y, rev = src_rev, locations = src_loc)

        for j = 0, n_elements(src_loc) do begin
          if src_rev[j + 1] gt src_rev[j] then begin
            inds = src_rev[src_rev[j] : src_rev[j + 1] - 1]

            src_string2 = strcompress(string(ch_src_dat.y[inds[0]]), /remove_all)

            ytitle2 = receiver_str + ' AUTO!C' + strupcase(raw_spec_i) + '!C' + $
              src_string + src_string2

            dash_pos = strpos(src_string2, '-')

            if dash_pos ge 0 then src_string2 = strmid(src_string2, 0, dash_pos) + strmid(src_string2, dash_pos + 1)

            src_name = prefix + raw_spec_i + '_converted_' + src_string2

            avg_pos = strpos(ytitle2, 'AVERAGES')

            if avg_pos ge 0 then ytitle2 = strmid(ytitle2, 0, avg_pos) + 'AVGS' + strmid(ytitle2, avg_pos + 8)

            ; if avg_pos GE 0 then stop
            ; stop

            ; if i EQ 0 then begin

            auto_items = prefix + ['CCSDS_MET_Seconds', $
              'CCSDS_MET_SubSeconds', $
              'CCSDS_Sequence_Number', $
              'compression', 'peaks', 'averages', $
              'hl', 'ch0', 'ch1', $
              'ch0_string', 'ch1_string', 'gain', 'nsum']

            for k = 0, n_elements(auto_items) - 1 do begin
              item = auto_items[k]

              if tnames(item) ne '' then begin
                get_data, item, data = data, lim = lim

                new_item = item + '_' + src_string2

                if size(/type, lim) eq 8 then begin
                  ytitle = lim.ytitle

                  ytitle = ytitle + '!C' + src_string2

                  lim.ytitle = ytitle
                end

                if (array_union(new_item, stored_names))[0] eq -1 then begin
                  store_data, new_item, $
                    data = {x: data.x[inds], y: data.y[inds, *]}, dlim = lim

                  stored_names = [stored_names, new_item]
                end
              end
            endfor

            ; end

            store_data, src_name, $
              data = {x: (raw_spec_data.x)[inds], y: converted_spec_data[inds, *], $
                v: rfs_freqs.reduced_freq}

            options, src_name, 'spec', 1
            options, src_name, 'no_interp', 1
            options, src_name, 'ylog', 1
            options, src_name, 'zlog', 1
            options, src_name, 'ztitle', '[V2/Hz]'
            options, src_name, 'ystyle', 1
            options, src_name, 'datagap', 60
            options, src_name, 'panel_size', 2.
            options, src_name, 'ytitle', ytitle2
            ; options, src_name, 'color_table', 39

            options, src_name, 'ysubtitle', 'Freq [Hz]'
          endif
        endfor
      endif

      options, prefix + raw_spec_i + '_converted', 'ytitle', $
        ytitle

      options, prefix + raw_spec_i + '_converted', 'ysubtitle', $
        'Freq [Hz]'
    end
  endfor
end