pro spp_fld_rfs_burst_load_l1, file, prefix = prefix, varformat = varformat
  compile_opt idl2

  if n_elements(file) lt 1 or file[0] eq '' then return

  receiver_str = 'BURST'

  if file[0].Contains('lusee') then lusee = 1 else lusee = 0
  rfs_freqs = spp_fld_rfs_freqs(lusee = lusee)

  burst_freqs0 = rfs_freqs.reduced_freq

  burst_freqs = [burst_freqs0 - 9375d, burst_freqs0, burst_freqs0 + 9375d]

  burst_freqs = burst_freqs[sort(burst_freqs)]

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  options, prefix + 'spec?_??', 'spec', 1
  options, prefix + 'spec?_??', 'no_interp', 1

  get_data, prefix + 'spec0_re', data = spec0_re
  get_data, prefix + 'spec0_im', data = spec0_im
  get_data, prefix + 'spec1_re', data = spec1_re
  get_data, prefix + 'spec1_im', data = spec1_im

  if size(/type, spec0_re) ne 8 then return

  t = spec0_re.x

  store_data, prefix + 'spec0_auto', $
    data = {x: t, y: (spec0_re.y ^ 2. + spec0_im.y ^ 2.)}

  store_data, prefix + 'spec1_auto', $
    data = {x: t, y: (spec1_re.y ^ 2. + spec1_im.y ^ 2.)}

  xspec = complex(spec0_re.y, spec0_im.y) * $
    complex(spec1_re.y, -spec1_im.y)

  store_data, prefix + 'xspec_re', $
    data = {x: t, y: real_part(xspec)}

  store_data, prefix + 'xspec_im', $
    data = {x: t, y: imaginary(xspec)}

  store_data, prefix + 'xspec_phase', $
    data = {x: t, y: atan(imaginary(xspec), real_part(xspec)) * 180d / !pi}

  options, prefix + 'xspec*', 'spec', 1
  options, prefix + 'xspec*', 'no_interp', 1

  options, prefix + 'xspec_phase', 'zrange', [-180., 180.]
  options, prefix + 'xspec_phase', 'zstyle', 1
  options, prefix + 'xspec_phase', 'panel_size', 2

  options, prefix + 'spec?_auto', 'spec', 1

  options, prefix + 'spec?_auto', 'no_interp', 1
  options, prefix + 'spec?_auto', 'zlog', 1

  options, prefix + 'spec?_auto', 'panel_size', 2

  options, prefix + 'spec0_auto', 'ytitle', 'RFS Burst!CCh0 Auto'
  options, prefix + 'spec1_auto', 'ytitle', 'RFS Burst!CCh1 Auto'

  options, prefix + 'xspec_phase', 'ytitle', 'RFS Burst!CCross Phase'

  ; Metadata tplot options

  color = 'b'

  options, prefix + 'gain', 'yrange', [-0.25, 1.25]
  options, prefix + 'gain', 'yticks', 1
  options, prefix + 'gain', 'ytickv', [0, 1]
  options, prefix + 'gain', 'yminor', 1
  options, prefix + 'gain', 'ytickname', ['Lo', 'Hi']
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'colors', color
  options, prefix + 'gain', 'psym_lim', 100
  options, prefix + 'gain', 'symsize', 0.5
  options, prefix + 'gain', 'panel_size', 0.35
  options, prefix + 'gain', 'ytitle', receiver_str + '!CGain'
  options, prefix + 'gain', 'ysubtitle', ''
  options, prefix + 'gain', 'datagap', 120

  options, prefix + 'nsum', 'yrange', [0, 100]
  options, prefix + 'nsum', 'ystyle', 1
  options, prefix + 'nsum', 'yminor', 1
  options, prefix + 'nsum', 'colors', color
  options, prefix + 'nsum', 'psym_lim', 100
  options, prefix + 'nsum', 'symsize', 0.5
  options, prefix + 'nsum', 'ytitle', receiver_str + '!CNSUM'
  options, prefix + 'nsum', 'ysubtitle', ''
  options, prefix + 'nsum', 'datagap', 120

  if file_basename(getenv('IDL_CT_FILE')) eq 'spp_fld_colors.tbl' then $
    set_colors = 1 else set_colors = 0

  if set_colors then options, prefix + 'xspec_phase', 'color_table', 78

  ; Get relevant info for correction and processing of spectra

  get_data, prefix + 'ch0_string', dat = ch0_src_dat
  get_data, prefix + 'ch1_string', dat = ch1_src_dat

  if size(/type, ch0_src_dat) ne 8 then $
    get_data, prefix + 'ch0', dat = ch0_src_dat
  if size(/type, ch1_src_dat) ne 8 then $
    get_data, prefix + 'ch1', dat = ch1_src_dat

  ch0_src_values = ch0_src_dat.y[uniq(ch0_src_dat.y, sort(ch0_src_dat.y))]
  ch1_src_values = ch1_src_dat.y[uniq(ch1_src_dat.y, sort(ch1_src_dat.y))]

  get_data, prefix + 'gain', data = rfs_gain_dat
  get_data, prefix + 'nsum', data = rfs_nsum

  options, prefix + 'nsum', 'yrange', [0, max(rfs_nsum.y) + 1]

  if max(rfs_nsum.y) gt 1 then stop

  lo_gain = where(rfs_gain_dat.y eq 0, n_lo_gain)

  ; raw_spectra = ['spec0_re','spec0_im','spec1_re','spec1_im', $
  ; 'spec0_auto', 'spec1_auto', 'xspec_re', 'xspec_im']

  stored_names = []

  raw_spectra = ['spec0_auto', 'spec1_auto', 'xspec_re', 'xspec_im']

  for i = 0, n_elements(raw_spectra) - 1 do begin
    raw_spec_i = raw_spectra[i]

    get_data, prefix + raw_spec_i, data = raw_spec_data

    if size(raw_spec_data, /type) eq 8 then begin
      ; Note: RFS burst data is not compressed like the HFR / LFR spectra!

      converted_spec_data = double(raw_spec_data.y)

      ; Using definition of power spectral density
      ; S = 2 * Nfft / fs |x|^2 / Wss where
      ; where |x|^2 is an auto spec value of the PFB/DFT
      ;
      ; 2             : from definition of S_PFB
      ; 1             : # spectral bins summed (Note: burst has no summing!)
      ; 4096          : number of FFT points
      ; 38.4e6        : fs in Hz (divide fs by 8 for LFR)
      ; 250           : RFS high gain (multiply by 50^2 later on if in low gain)
      ; 2048          : 2048 counts in the ADC = 1 volt
      ; 0.782         : WSS for our implementation of the PFB (see pfb_norm.pdf)
      ; 65536         : factor from integer PFB, equal to (2048./8.)^2

      ; TODO: Correct this for SCM data

      V2_factor = (2d / 1d) * 4096d / 38.4d6 / ((250d * 2048d) ^ 2d * 0.782d * 65536d)

      V_factor = sqrt(V2_factor)

      if raw_spec_i.StartsWith('spec') and $
        (raw_spec_i.EndsWith('re') or raw_spec_i.EndsWith('im')) then $
        re_im = 1 else re_im = 0

      if re_im then converted_spec_data *= V_factor else $
        converted_spec_data *= V2_factor

      if n_lo_gain gt 0 then begin
        if re_im then converted_spec_data[lo_gain, *] *= 50.d else $
          converted_spec_data[lo_gain, *] *= 2500.d
      endif

      store_data, prefix + raw_spec_i + '_converted', $
        data = {x: raw_spec_data.x, y: converted_spec_data, $
          v: burst_freqs}

      options, prefix + raw_spec_i + '_converted', 'spec', 1
      options, prefix + raw_spec_i + '_converted', 'no_interp', 1
      options, prefix + raw_spec_i + '_converted', 'ylog', 1

      if raw_spec_i.EndsWith('auto') then begin
        options, prefix + raw_spec_i + '_converted', 'zlog', 1
      end

      if re_im then $
        options, prefix + raw_spec_i + '_converted', 'ztitle', '[V/Hz^(1/2)]' else $
        options, prefix + raw_spec_i + '_converted', 'ztitle', '[V2/Hz]'
    endif

    options, prefix + raw_spec_i + '_converted', 'ystyle', 1
    options, prefix + raw_spec_i + '_converted', 'datagap', 60
    options, prefix + raw_spec_i + '_converted', 'panel_size', 2.
    options, prefix + raw_spec_i + '_converted', 'ysubtitle', 'Freq [Hz]'

    ch_src_values = []

    if raw_spec_i eq 'spec0_auto' then begin
      ch_src_values = ch0_src_values
      ch_src_dat = ch0_src_dat
      ch_str = 'ch0'
      ch_type = 'auto'
    endif else if raw_spec_i eq 'spec1_auto' then begin
      ch_src_values = ch1_src_values
      ch_src_dat = ch1_src_dat
      ch_str = 'ch1'
      ch_type = 'auto'
    endif else begin
      foreach ch0_src_value, ch0_src_values do begin
        foreach ch1_src_value, ch1_src_values do begin
          ch_src_values = [ch_src_values, [[ch0_src_value], [ch1_src_value]]]
        endforeach
      endforeach
      ch_src_dat = ch0_src_dat
      ch_str = strmid(raw_spec_i, 1, 2, /rev)
      ch_type = 'cross'
    endelse

    if ch_type ne 'cross' then n_j = n_elements(ch_src_values) else $
      n_j = n_elements(ch_src_values) / 2

    for j = 0, n_j - 1 do begin
      if ch_type ne 'cross' then begin
        ch_j = ch_src_values[j]

        inds = where(ch_src_dat.y eq ch_j, count)

        src_string = strcompress(string(ch_j), /remove_all)
      endif else begin
        ch0_j = ch_src_values[j, 0]
        ch1_j = ch_src_values[j, 1]

        inds = where((ch0_src_dat.y eq ch0_j) and (ch1_src_dat.y eq ch1_j), $
          count)

        src_string = strcompress(string(ch0_j + '_' + ch1_j), /remove_all)
      endelse

      if count gt 0 then begin
        ; Remove dashes–do this twice in case of cross spectra w/two sources

        for k = 0, 1 do begin
          dash_pos = strpos(src_string, '-')

          if dash_pos ge 0 then src_string = strmid(src_string, 0, dash_pos) + $
            strmid(src_string, dash_pos + 1)
        endfor

        src_name = prefix + ch_type + '_' + ch_str + '_converted_' + src_string

        src_data = converted_spec_data[inds, *]

        store_data, src_name, $
          data = {x: ch0_src_dat.x[inds], $
            y: src_data, v: burst_freqs}

        options, src_name, 'spec', 1
        options, src_name, 'no_interp', 1
        options, src_name, 'ylog', 1
        if ch_type ne 'cross' then options, src_name, 'zlog', 1
        options, src_name, 'ztitle', '[V2/Hz]'
        options, src_name, 'ystyle', 1
        options, src_name, 'datagap', 60
        options, src_name, 'panel_size', 2.
        options, src_name, 'ytitle', 'BURST ' + ch_str + '!C' + src_string
        ; options, src_name, 'color_table', 39

        options, src_name, 'ysubtitle', 'Freq [Hz]'

        hk_items = prefix + ['CCSDS_MET_Seconds', $
          'CCSDS_MET_SubSeconds', $
          'CCSDS_Sequence_Number', $
          'compression', 'peaks', 'averages', $
          'hl', 'ch0', 'ch1', $
          'ch0_string', 'ch1_string', 'gain', 'nsum']

        for k = 0, n_elements(hk_items) - 1 do begin
          item = hk_items[k]

          if tnames(item) ne '' then begin
            get_data, item, data = data, lim = lim

            new_item = item + '_' + src_string

            if size(/type, lim) eq 8 then begin
              str_element, lim, 'ytitle', success = ytitle_found

              if ytitle_found then begin
                ytitle = lim.ytitle

                ytitle = ytitle + '!C' + src_string

                lim.ytitle = ytitle
              endif
            end

            if (array_union(new_item, stored_names))[0] eq -1 then begin
              store_data, new_item, $
                data = {x: data.x[inds], y: data.y[inds, *]}, dlim = lim

              stored_names = [stored_names, new_item]
            end
          end
        endfor
      endif
    endfor
  endfor
end