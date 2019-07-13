pro spp_fld_rfs_rawspectra_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_rfs_rawspectra_'

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_rfs_rawspectra_load_l1', dlevel = 2

    return

  endif

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  n_wf = 32768l
  f_wf = 38.4e6
  n_fft = 4096l

  freq_hfr = spp_fld_rfs_freqs()
  freq_lfr = spp_fld_rfs_freqs(/lfr)

  get_data, 'spp_fld_rfs_rawspectra_ch0', data = dat_ch0

  get_data, 'spp_fld_rfs_rawspectra_ch1', data = dat_ch1

  get_data, 'spp_fld_rfs_rawspectra_algorithm', data = dat_algorithm

  get_data, 'spp_fld_rfs_rawspectra_ch0_gain', data = dat_ch0_gain
  get_data, 'spp_fld_rfs_rawspectra_ch1_gain', data = dat_ch1_gain


  if size(/type, dat_ch0) NE 8 or $
    size(/type, dat_ch1) NE 8 or $
    size(/type, dat_algorithm) NE 8 then begin

    print, 'No RFS raw spectral data'

    return

  end

  options, 'spp_fld_rfs_rawspectra_ch?_??', 'spec', 0

  hfr_ind = where((dat_algorithm.y MOD 2) EQ 0, hfr_count, $
    complement = lfr_ind, ncomplement = lfr_count)

  dat_v = dblarr(n_fft/2,n_elements(dat_algorithm.y))

  if hfr_count GT 0 then dat_v[*, hfr_ind] = rebin(freq_hfr.full_freq[1:*], n_fft/2, hfr_count, /sample)
  if lfr_count GT 0 then dat_v[*, lfr_ind] = rebin(freq_lfr.full_freq[1:*], n_fft/2, lfr_count, /sample)

  get_data, 'spp_fld_rfs_rawspectra_ch0_re', data = dat_ch0_re
  get_data, 'spp_fld_rfs_rawspectra_ch0_im', data = dat_ch0_im

  ch0_comp = dcomplex(dat_ch0_re.y, dat_ch0_im.y)

  ch0_pow = abs(ch0_comp)^2d

  dat_ch0_pow = {x:dat_ch0_re.x, y:ch0_pow, v:transpose(dat_v)}

  store_data, 'spp_fld_rfs_rawspectra_ch0_pow', $
    data = dat_ch0_pow, $
    dlim = {spec:1, ystyle:1, ylog:1, zlog:1, yrange:[1.e3,1.e8], $
    no_interp:1}

  get_data, 'spp_fld_rfs_rawspectra_ch1_re', data = dat_ch1_re
  get_data, 'spp_fld_rfs_rawspectra_ch1_im', data = dat_ch1_im

  ch1_comp = dcomplex(dat_ch1_re.y, dat_ch1_im.y)

  ch1_pow = abs(ch1_comp)^2d

  dat_ch1_pow = {x:dat_ch1_re.x, y:ch1_pow, v:transpose(dat_v)}

  store_data, 'spp_fld_rfs_rawspectra_ch1_pow', $
    data = dat_ch1_pow, $
    dlim = {spec:1, ystyle:1, ylog:1, zlog:1, yrange:[1.e3,1.e8], $
    no_interp:1}


  chs = [0,1]

  algs = [0,1]

  srcs = [0,1,2,3,4,5,6,7]

  foreach ch, chs do begin

    if ch EQ 0 then begin

      src_data = dat_ch0.y
      re_data = dat_ch0_re.y
      im_data = dat_ch0_im.y
      pow_data = ch0_pow
      gain_data = dat_ch0_gain.y

    endif else begin

      src_data = dat_ch1.y
      re_data = dat_ch1_re.y
      im_data = dat_ch1_im.y
      pow_data = ch1_pow
      gain_data = dat_ch1_gain.y

    endelse

    foreach alg, algs do begin

      foreach src, srcs do begin

        alg_match = where((dat_algorithm.y MOD 2) EQ alg, alg_count)
        src_match = where(src_data EQ src, src_count)

        match_t = where(dat_algorithm.y EQ alg and src_data EQ src, match_count)

        if match_count GT 0 then begin

          if alg EQ 0 then begin
            hfr_lfr_str = 'hfr'
            yrange = [8.e3,2.e7]
          endif else begin
            hfr_lfr_str = 'lfr'
            yrange = [8.e2,2.e6]
          endelse

          if ch EQ 0 then begin

            dat_pow = dat_ch0_pow
            case src of
              0: source_txt = 'V1-V2'
              1: source_txt = 'V1-V3'
              2: source_txt = 'V2-V4'
              3: source_txt = 'SCM'
              4: source_txt = 'V1'
              5: source_txt = 'V3'
              6: source_txt = 'GND'
              7: source_txt = 'GND'
            endcase

          endif else begin

            dat_pow = dat_ch1_pow

            case src of
              0: source_txt = 'V3-V4'
              1: source_txt = 'V3-V2'
              2: source_txt = 'V1-V4'
              3: source_txt = 'SCM'
              4: source_txt = 'V2'
              5: source_txt = 'V4'
              6: source_txt = 'GND'
              7: source_txt = 'GND'
            endcase

          endelse

          ; Using definition of power spectral density
          ;  S = 2 * Nfft / fs |x|^2 / Wss where
          ; where |x|^2 is an auto spec value of the PFB/DFT
          ;
          ; 2             : from definition of S_PFB
          ; 4096          : number of FFT points
          ; 38.4e6        : fs in Hz (divide fs by 8 for LFR)
          ; 250           : RFS high gain
          ;               :  (multiply by 50^2 later on if in low gain)
          ;               :  (multiply by 0.042 for SCM)
          ; 2048          : 2048 counts in the ADC = 1 volt
          ; 0.782         : WSS for our implementation of the PFB (see pfb_norm.pdf)
          ; 65536         : factor from integer PFB, equal to (2048./8.)^2

          if source_txt NE 'SCM' then gain0 = 250d else gain0 = 0.042d

          gain = dblarr(match_count) + gain0

          if source_txt NE 'SCM' then begin
            lo_gain = where(gain_data[match_t] EQ 0, n_lo_gain)
            if n_lo_gain GT 0 then gain[lo_gain] = 5d
          endif

          V2_factor = 2d * 4096d / 38.4d6 / ((gain*2048d)^2d * 0.782d * 65536d)

          if hfr_lfr_str EQ 'lfr' then V2_factor *= 8
          dat_pow.y[match_t,*] *= transpose(rebin(V2_factor,n_elements(V2_factor),2048))

          tplot_prefix = 'spp_fld_rfs_rawspectra_' + hfr_lfr_str + $
            '_ch' + string(ch, format='(I1)') + $
            '_src' + string(src, format = '(I1)')

          ytitle = 'RFS!C' + strupcase(hfr_lfr_str) + ' AUTO!C' + $
            'CH' + string(ch, format='(I1)') + ' ' + $
            source_txt

          print, ch, alg, src, match_count, ' ', tplot_prefix, $
            format = '(I2,I2,I2,I6,A,A)'

          if hfr_lfr_str EQ 'lfr' then begin
            freq_div = 1.e3
            freq_div_str = '[kHz]'
            yrange = [1.,3.e3]
            freqs = spp_fld_rfs_freqs(/lfr)
            clean_pfb = where(freqs.full_pfb_db LT -89.5)

          endif else begin
            freq_div = 1.e6
            freq_div_str = '[MHz]'
            yrange = [5.e-3,30.]
            freqs = spp_fld_rfs_freqs()
            clean_pfb = where(freqs.full_pfb_db LT -89.5)
          endelse

          dat_pow_str = {x:dat_pow.x[match_t], $
            y:alog10(dat_pow.y[match_t,*]), $
            v:dat_pow.v[match_t,*]/freq_div}

          store_data, tplot_prefix + '_pow', $
            data = dat_pow_str
            
          dat_pow_str_clean = {x:dat_pow_str.x, $
            y:dat_pow_str.y[*,clean_pfb], $
            v:dat_pow_str.v[*,clean_pfb]}

          store_data, tplot_prefix + '_pow_clean', $
            data = dat_pow_str_clean
            
          options, tplot_prefix + '_*', 'spec', 1
          options, tplot_prefix + '_*', 'ylog', 1
          options, tplot_prefix + '_*', 'zlog', 0
          options, tplot_prefix + '_*', 'no_interp', 1
          options, tplot_prefix + '_*', 'yrange', yrange
          options, tplot_prefix + '_*', 'ystyle', 1
          options, tplot_prefix + '_*', 'panel_size', 2
          options, tplot_prefix + '_pow', 'ytitle', ytitle
          options, tplot_prefix + '_pow_clean', 'ytitle', ytitle + '!CCLEAN'
          options, tplot_prefix + '_pow*', 'ysubtitle', freq_div_str
          options, tplot_prefix + '_*', 'ztitle', 'Log V2/Hz'

        endif else begin
          print, ch, alg, src, match_count, $
            format = '(I2,I2,I2,I6)'
        end

      endforeach

    endforeach

  endforeach

  ; Auto spectra

  options, 'spp_fld_rfs_rawspectra_ch?_pow', 'ysubtitle', '[Hz]'
  options, 'spp_fld_rfs_rawspectra_ch0_pow', 'ytitle', 'RFS!CAUTO!CCH0'
  options, 'spp_fld_rfs_rawspectra_ch1_pow', 'ytitle', 'RFS!CAUTO!CCH1'

  ; Compression

  options, 'spp_fld_rfs_rawspectra_compression', 'psym', -4
  options, 'spp_fld_rfs_rawspectra_compression', 'symsize', 0.65
  options, 'spp_fld_rfs_rawspectra_compression', 'panel_size', 0.35
  options, 'spp_fld_rfs_rawspectra_compression', 'ysubtitle', ''
  options, 'spp_fld_rfs_rawspectra_compression', 'yrange', [-0.1,1.1]
  options, 'spp_fld_rfs_rawspectra_compression', 'yticks', 1
  options, 'spp_fld_rfs_rawspectra_compression', 'ytickv', [0.,1.]
  options, 'spp_fld_rfs_rawspectra_compression', 'ytickname', ['No','Yes']
  options, 'spp_fld_rfs_rawspectra_compression', 'ystyle', 1
  options, 'spp_fld_rfs_rawspectra_compression', 'ytitle', 'RFS!CCompress'

  ; Algorithm

  options, 'spp_fld_rfs_rawspectra_algorithm', 'psym', -4
  options, 'spp_fld_rfs_rawspectra_algorithm', 'symsize', 0.65
  options, 'spp_fld_rfs_rawspectra_algorithm', 'panel_size', 0.35
  options, 'spp_fld_rfs_rawspectra_algorithm', 'ysubtitle', ''
  options, 'spp_fld_rfs_rawspectra_algorithm', 'yrange', [-0.1,1.1]
  options, 'spp_fld_rfs_rawspectra_algorithm', 'yticks', 1
  options, 'spp_fld_rfs_rawspectra_algorithm', 'ytickv', [0.,1.]
  options, 'spp_fld_rfs_rawspectra_algorithm', 'ytickname', ['HFR','LFR']
  options, 'spp_fld_rfs_rawspectra_algorithm', 'ystyle', 1
  options, 'spp_fld_rfs_rawspectra_algorithm', 'ytitle', 'RFS!CAlgorithm'


  ; Raw 2048 bin real and imaginary

  options, 'spp_fld_rfs_rawspectra_ch?_??', 'spec', 1
  options, 'spp_fld_rfs_rawspectra_ch?_??', 'no_interp', 1
  options, 'spp_fld_rfs_rawspectra_ch?_??', 'yrange', [0,2048]
  options, 'spp_fld_rfs_rawspectra_ch?_??', 'ystyle', 1
  options, 'spp_fld_rfs_rawspectra_ch?_??', 'yticks', 8
  options, 'spp_fld_rfs_rawspectra_ch?_??', 'ysubtitle', '[Freq Bin]'
  options, 'spp_fld_rfs_rawspectra_ch0_re', 'ytitle', 'RFS!CRAW RE!CCH0'
  options, 'spp_fld_rfs_rawspectra_ch0_im', 'ytitle', 'RFS!CRAW IM!CCH1'
  options, 'spp_fld_rfs_rawspectra_ch1_re', 'ytitle', 'RFS!CRAW RE!CCH0'
  options, 'spp_fld_rfs_rawspectra_ch1_im', 'ytitle', 'RFS!CRAW IM!CCH1'

  ; Source (integer value, not the string one)

  options, 'spp_fld_rfs_rawspectra_ch?', 'psym', -4
  options, 'spp_fld_rfs_rawspectra_ch?', 'symsize', 0.65
  options, 'spp_fld_rfs_rawspectra_ch?', 'panel_size', 0.75
  options, 'spp_fld_rfs_rawspectra_ch?', 'ysubtitle', ''
  options, 'spp_fld_rfs_rawspectra_ch?', 'yrange', [-0.5,7.5]
  options, 'spp_fld_rfs_rawspectra_ch?', 'ystyle', 1
  options, 'spp_fld_rfs_rawspectra_ch?', 'yminor', 1
  options, 'spp_fld_rfs_rawspectra_ch?', 'yticks', 7
  options, 'spp_fld_rfs_rawspectra_ch?', 'ytickv', findgen(8)

  options, 'spp_fld_rfs_rawspectra_ch0', 'ytickname', ['V1-V2','V1-V3','SCM','GND','V1','V3','GND','GND']
  options, 'spp_fld_rfs_rawspectra_ch1', 'ytickname', ['V3-V4','V3-V2','V1-V2','SCM','V2','V4','GND','GND']
  options, 'spp_fld_rfs_rawspectra_ch0', 'colors', 6
  options, 'spp_fld_rfs_rawspectra_ch1', 'colors', 2
  options, 'spp_fld_rfs_rawspectra_ch?', 'ystyle', 1
  options, 'spp_fld_rfs_rawspectra_ch0', 'ytitle', 'RFS!CCH0!CSRC'
  options, 'spp_fld_rfs_rawspectra_ch1', 'ytitle', 'RFS!CCH1!CSRC'

  ; Gain (integer value, not the string one)

  options, 'spp_fld_rfs_rawspectra_ch?_gain', 'psym', -4
  options, 'spp_fld_rfs_rawspectra_ch?_gain', 'symsize', 0.65
  options, 'spp_fld_rfs_rawspectra_ch?_gain', 'panel_size', 0.35
  options, 'spp_fld_rfs_rawspectra_ch?_gain', 'ysubtitle', ''
  options, 'spp_fld_rfs_rawspectra_ch?_gain', 'yrange', [-0.1,1.1]
  options, 'spp_fld_rfs_rawspectra_ch?_gain', 'yticks', 1
  options, 'spp_fld_rfs_rawspectra_ch?_gain', 'ytickv', [0.,1.]
  options, 'spp_fld_rfs_rawspectra_ch?_gain', 'ytickname', ['Lo','Hi']
  options, 'spp_fld_rfs_rawspectra_ch?_gain', 'ystyle', 1
  options, 'spp_fld_rfs_rawspectra_ch0_gain', 'colors', 6
  options, 'spp_fld_rfs_rawspectra_ch1_gain', 'colors', 2
  options, 'spp_fld_rfs_rawspectra_ch0_gain', 'ytitle', 'RFS!CCH0!CGain'
  options, 'spp_fld_rfs_rawspectra_ch1_gain', 'ytitle', 'RFS!CCH1!CGain'

  ; String options

  options, 'spp_fld_rfs_rawspectra_*_string', 'tplot_routine', 'strplot'
  options, 'spp_fld_rfs_rawspectra_*_string', 'yrange', [-0.1,1.0]
  options, 'spp_fld_rfs_rawspectra_*_string', 'panel_size', 0.35
  options, 'spp_fld_rfs_rawspectra_*_string', 'ystyle', 1
  options, 'spp_fld_rfs_rawspectra_*_string', 'yticks', 1
  options, 'spp_fld_rfs_rawspectra_*_string', 'ytickformat', '(A1)'
  options, 'spp_fld_rfs_rawspectra_*_string', 'ysubtitle', ''
  options, 'spp_fld_rfs_rawspectra_*_string', 'noclip', 0

  options, 'spp_fld_rfs_rawspectra_ch0_gain_string', 'ytitle', $
    'RFS!CCH0!CGain'
  options, 'spp_fld_rfs_rawspectra_ch0_string', 'ytitle', $
    'RFS!CCH0!CSRC'
  options, 'spp_fld_rfs_rawspectra_ch1_gain_string', 'ytitle', $
    'RFS!CCH1!CGain'
  options, 'spp_fld_rfs_rawspectra_ch1_string', 'ytitle', $
    'RFS!CCH1!CSRC'

end