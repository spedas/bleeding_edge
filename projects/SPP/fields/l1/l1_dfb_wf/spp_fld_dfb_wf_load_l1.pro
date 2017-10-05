pro spp_fld_dfb_wf_load_l1, file, prefix = prefix, compressed = compressed

  ; TODO: Check compression bit, wav_tap, etc

  ; TODO fix gap at packet boundaries (see wf_10 in mops_test_3 crib)

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_dfb_wf_load_l1', dlevel = 2

    return

  endif

  cdf2tplot, file, prefix = prefix, varnames = varnames

  if varnames[0] EQ '' then begin

    dprint, 'No variables found in file ' + file, dlevel = 2

    return

  endif

  if keyword_set(compressed) then compressed_str = '(Comp)' else compressed_str = ''

  options, prefix + 'wav_tap', 'yrange', [-1.,16.]
  options, prefix + 'wav_tap', 'ystyle', 1
  options, prefix + 'wav_tap', 'psym', 4
  options, prefix + 'wav_tap', 'ytitle', $
    'DFB WF ' + strmid(prefix,15,2) + compressed_str + '!CTap'

  options, prefix + 'compression', 'yrange', [-0.5,1.5]
  options, prefix + 'compression', 'ystyle', 1
  options, prefix + 'compression', 'psym', 4
  options, prefix + 'compression', 'symsize', 0.5
  options, prefix + 'compression', 'panel_size', 0.5
  options, prefix + 'compression', 'ytitle', $
    'DFB WF ' + strmid(prefix,15,2) + compressed_str + '!CCompression'

  options, prefix + 'wav_enable', 'yrange', [-0.5,1.5]
  options, prefix + 'wav_enable', 'ystyle', 1
  options, prefix + 'wav_enable', 'psym', 4
  options, prefix + 'wav_enable', 'symsize', 0.5
  options, prefix + 'wav_enable', 'panel_size', 0.5
  options, prefix + 'wav_enable', 'ytitle', $
    'DFB WF ' +  strmid(prefix,15,2) + compressed_str + '!CEnable'

  options, prefix + 'wav_sel', 'yrange', [-1,16]
  options, prefix + 'wav_sel', 'ystyle', 1

  options, prefix + 'wav_sel', 'psym', 4
  options, prefix + 'wav_sel', 'symsize', 0.5

  get_data, prefix + 'wf_pkt_data', data = d
  get_data, prefix + 'wav_tap', data = d_tap

  all_wf_time = []
  all_wf_decompressed = []

  ; TODO: Make this faster by having TMlib get the time

  if size(d, /type) EQ 8 then begin

    for i = 0, n_elements(d.x) - 1 do begin

      wf_i0 = reform(d.y[i,*])

      wf_i = wf_i0[where(wf_i0 GT -2147483647l)]

      if keyword_set(compressed) then begin

        wf_i = decompress(uint(wf_i))

      end

      all_wf_decompressed = [all_wf_decompressed, wf_i]

      wf_time = d_tap.x[i] + dindgen(n_elements(wf_i)) / (18750d / (2d^d_tap.y[i]))

      all_wf_time = [all_wf_time, wf_time]

    endfor

    store_data, prefix + 'wav_data', dat = {x:all_wf_time, y:all_wf_decompressed}, $
      dlim = {panel_size:2}

    options, prefix + 'wav_data', 'ynozero', 1

    get_data, prefix + 'wav_sel', data = wav_sel_dat

    if n_elements(uniq(wav_sel_dat.y)) EQ 1 then $
      options, prefix + 'wav_data', 'ytitle', 'DFB WF '+ strmid(prefix,15,2) + compressed_str + $
      '!CSRC:' + strcompress(string(wav_sel_dat.y[0]))

  end

  ;stop

end