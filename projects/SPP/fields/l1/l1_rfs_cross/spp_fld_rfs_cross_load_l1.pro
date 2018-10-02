pro spp_fld_rfs_cross_load_l1, file, prefix = prefix, color = color

  ; TODO improve this check for valid CDF file and add to other routines
  if n_elements(file) LT 1 or file[0] EQ '' then return

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
  options, prefix + 'compression', 'ytitle', receiver_str + ' Cross!CCmprs'

  options, prefix + 'gain', 'yrange', [0, 1]
  options, prefix + 'gain', 'yticks', 1
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'colors', color
  options, prefix + 'gain', 'yminor', 1
  options, prefix + 'gain', 'psym', 4
  options, prefix + 'gain', 'symsize', 0.5
  options, prefix + 'gain', 'panel_size', 0.35
  options, prefix + 'gain', 'ytitle', receiver_str + ' Cross!CGain'

  options, prefix + 'hl', 'yrange', [0, 3]
  options, prefix + 'hl', 'yticks', 3
  options, prefix + 'hl', 'ystyle', 1
  options, prefix + 'hl', 'colors', color
  options, prefix + 'hl', 'yminor', 1
  options, prefix + 'hl', 'psym', 4
  options, prefix + 'hl', 'symsize', 0.5
  options, prefix + 'hl', 'panel_size', 0.5
  options, prefix + 'hl', 'ytitle', receiver_str + ' Cross!CHL'

  options, prefix + 'nsum', 'yrange', [0, 128]
  options, prefix + 'nsum', 'ystyle', 1
  options, prefix + 'nsum', 'yminor', 1
  options, prefix + 'nsum', 'colors', color
  options, prefix + 'nsum', 'psym', 4
  options, prefix + 'nsum', 'symsize', 0.5
  options, prefix + 'nsum', 'ytitle', receiver_str + ' Cross!CNSUM'

  options, prefix + 'ch?', 'yrange', [0, 7]
  options, prefix + 'ch?', 'ystyle', 1
  options, prefix + 'ch?', 'yminor', 1
  options, prefix + 'ch?', 'colors', color
  options, prefix + 'ch?', 'psym', 4
  options, prefix + 'ch?', 'symsize', 0.5
  options, prefix + 'ch0', 'ytitle', receiver_str + ' Cross!CCH0 Source'
  options, prefix + 'ch1', 'ytitle', receiver_str + ' Cross!CCH1 Source'

  options, prefix + 'xspec_??', 'spec', 1
  options, prefix + 'xspec_??', 'no_interp', 1
  options, prefix + 'xspec_??', 'yrange', [0,64]
  options, prefix + 'xspec_??', 'ystyle', 1
  options, prefix + 'xspec_??', 'datagap', 60

  options, prefix + 'xspec_re', 'ytitle', receiver_str + ' Cross!CReal Raw'
  options, prefix + 'xspec_im', 'ytitle', receiver_str + ' Cross!CImag Raw'

  get_data, prefix + 'gain', data = rfs_gain_dat
  get_data, prefix + 'nsum', data = rfs_nsum

  lo_gain = where(rfs_gain_dat.y EQ 0, n_lo_gain)

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


  get_data, prefix + 'xspec_re', data = rfs_dat_xspec_re

  converted_data_xspec_re = rfs_float(rfs_dat_xspec_re.y, /cross)

  ; TODO replace hard coded gain value w/calibrated

  converted_data_xspec_re *= V2_factor
  
  if n_lo_gain GT 0 then converted_data_xspec_re[lo_gain, *] *= 2500.d

  converted_data_xspec_re /= rebin(rfs_nsum.y,$
    n_elements(rfs_nsum.x),$
    n_elements(rfs_freqs.reduced_freq))

  store_data, prefix + 'xspec_re_converted', $
    data = {x:rfs_dat_xspec_re.x, y:converted_data_xspec_re, $
    v:rfs_freqs.reduced_freq}

  get_data, prefix + 'xspec_im', data = rfs_dat_xspec_im

  converted_data_xspec_im = spp_fld_rfs_float(rfs_dat_xspec_im.y, /cross)

  ; TODO replace hard coded gain value w/calibrated

  converted_data_xspec_im *= V2_factor

  if n_lo_gain GT 0 then converted_data_xspec_im[lo_gain, *] *= 2500.d

  converted_data_xspec_im /= rebin(rfs_nsum.y,$
    n_elements(rfs_nsum.x),$
    n_elements(rfs_freqs.reduced_freq))

  store_data, prefix + 'xspec_im_converted', $
    data = {x:rfs_dat_xspec_im.x, y:converted_data_xspec_im, $
    v:rfs_freqs.reduced_freq}

  options, prefix + 'xspec_??_converted', 'spec', 1
  options, prefix + 'xspec_??_converted', 'no_interp', 1
  options, prefix + 'xspec_??_converted', 'ylog', 1
  options, prefix + 'xspec_??_converted', 'zlog', 0
  options, prefix + 'xspec_??_converted', 'ztitle', '[V2/Hz]'
  options, prefix + 'xspec_??_converted', 'yrange', [min(rfs_freqs.reduced_freq), max(rfs_freqs.reduced_freq)]
  options, prefix + 'xspec_??_converted', 'ystyle', 1
  options, prefix + 'xspec_??_converted', 'datagap', 60
  options, prefix + 'xspec_??_converted', 'panel_size', 2.

  options, prefix + 'xspec_re_converted', 'ytitle', receiver_str + ' Cross!CReal Raw'
  options, prefix + 'xspec_im_converted', 'ytitle', receiver_str + ' Cross!CImag Raw'

  get_data, prefix + 'ch0', dat = ch0_src_dat
  get_data, prefix + 'ch1', dat = ch1_src_dat

  if n_elements(uniq(ch0_src_dat.y) EQ 1) and $
    n_elements(uniq(ch1_src_dat.y) EQ 1)then $
    options, prefix + 'xspec_??_converted', 'ysubtitle', $
    'SRC ' + $
    strcompress(string(ch0_src_dat.y[0]), /rem) + '-' + $
    strcompress(string(ch1_src_dat.y[0]), /rem)

end