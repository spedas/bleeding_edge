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

  if keyword_set(compressed) then compressed_str = '(Comp)' else $
    compressed_str = ''

  options, prefix + 'wav_tap', 'yrange', [-1.,16.]
  options, prefix + 'wav_tap', 'ystyle', 1
  options, prefix + 'wav_tap', 'psym', 4
  options, prefix + 'wav_tap', 'ytitle', $
    'DFB WF ' + strmid(prefix,15,2) + compressed_str + '!CTap'

  options, prefix + 'compression', 'yrange', [-0.25,1.25]
  options, prefix + 'compression', 'ystyle', 1
  options, prefix + 'compression', 'psym', 4
  options, prefix + 'compression', 'symsize', 0.5
  options, prefix + 'compression', 'panel_size', 0.5
  options, prefix + 'compression', 'ytitle', $
    'DFB WF ' + strmid(prefix,15,2) + compressed_str + '!CCompression'

  options, prefix + 'wav_enable', 'yrange', [-0.25,1.25]
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
  get_data, prefix + 'wf_pkt_data_v', data = d_v
  get_data, prefix + 'wav_tap', data = d_tap

  all_wf_time_list = LIST()
  ;  all_wf_time = []
  ;  all_wf_decompressed = []
  ;  all_wf_decompressed_v = []
  all_wf_decompressed_list = LIST()
  all_wf_decompressed_v_list = LIST()

  ; TODO: Correct delays below for SCM data as well as V/E data

  Ideal_delay = !null
  delay_loc = 0d
  print, 'Sample Rate      ', 'Ideal Cumulative delay (s) - V or E DC only'
  for index = 0, 15, 1 do begin &$
    if index EQ 0 then delay_loc += (4d / 18750d) &$
    if index GT 0 then delay_loc += (3d / (18750d/ 2d^(index)) + 1d / (18750d/ 2d^(index - 1d)) ) &$
    Ideal_delay = [Ideal_delay, delay_loc] &$
    print, 18750d/ 2d^(index), delay_loc &$
  endfor

; TODO: Make this faster by having TMlib get the time

if size(d, /type) EQ 8 then begin

  for i = 0, n_elements(d.x) - 1 do begin

    wf_i0 = reform(d.y[i,*])

    wf_i = wf_i0[where(wf_i0 GT -2147483647l)]

    if size(d_v, /type) EQ 8 then begin

      wf_i0_v = reform(d_v.y[i,*])

      wf_i_v = wf_i0_v[where(wf_i0 GT -2147483647l)]

    endif


    if keyword_set(compressed) then begin

      wf_i = decompress(uint(wf_i))

    end

    ;      all_wf_decompressed = [all_wf_decompressed, wf_i]
    ;      all_wf_decompressed_v = [all_wf_decompressed_v, wf_i_v]
    all_wf_decompressed_list.Add, wf_i
    if size(d_v, /type) EQ 8 then all_wf_decompressed_v_list.Add, wf_i_v

    ideal_delay_i = ideal_delay[d_tap.y[i]]

    delay_i = ideal_delay_i + 0.5/(18750d / (2d^d_tap.y[i]))

    wf_time = d_tap.x[i] + $
      (dindgen(n_elements(wf_i))) / $
      (18750d / (2d^d_tap.y[i])) - delay_i

    dprint, i, n_elements(d.x), dwait = 5

    ;all_wf_time = [all_wf_time, wf_time]
    all_wf_time_list.Add, wf_time

  endfor

  all_wf_time = (spp_fld_square_list(all_wf_time_list)).ToArray()
  all_wf_decompressed = (spp_fld_square_list(all_wf_decompressed_list)).ToArray()
  if size(d_v, /type) EQ 8 then $
    all_wf_decompressed_v = (spp_fld_square_list(all_wf_decompressed_v_list)).ToArray()

  all_wf_time = reform(transpose(all_wf_time), n_elements(all_wf_time))
  all_wf_decompressed = reform(transpose(all_wf_decompressed), n_elements(all_wf_time))
  if size(d_v, /type) EQ 8 then $
    all_wf_decompressed_v = reform(transpose(all_wf_decompressed_v), n_elements(all_wf_time))

  wf_valid_ind = where(finite(all_wf_time), wf_valid_count)

  if wf_valid_count GT 0 then begin
    all_wf_time = all_wf_time[wf_valid_ind]
    all_wf_decompressed = all_wf_decompressed[wf_valid_ind]
    if size(d_v, /type) EQ 8 then $
      all_wf_decompressed_v = all_wf_decompressed_v[wf_valid_ind]
  endif

  store_data, prefix + 'wav_data', $
    dat = {x:all_wf_time, y:all_wf_decompressed}, $
    dlim = {panel_size:2}

  if size(d_v, /type) EQ 8 then $
    store_data, prefix + 'wav_data_v', $
    dat = {x:all_wf_time, y:all_wf_decompressed_v}, $
    dlim = {panel_size:2}

  options, prefix + 'wav_data*', 'ynozero', 1
  options, prefix + 'wav_data*', 'max_points', 40000l
  options, prefix + 'wav_data*', 'psym_lim', 200
  options, prefix + 'wav_data', 'ysubtitle', '[Counts]'
  options, prefix + 'wav_data_v', 'ysubtitle', '[V]'

  if tnames(prefix + 'wav_sel_string') EQ '' then begin

    get_data, prefix + 'wav_sel', data = wav_sel_dat

    if n_elements(uniq(wav_sel_dat.y)) EQ 1 then $
      options, prefix + 'wav_data*', 'ytitle', $
      'DFB WF '+ strmid(prefix,15,2) + compressed_str + $
      '!CSRC:' + strcompress(string(wav_sel_dat.y[0]))

  endif else begin

    get_data, prefix + 'wav_sel_string', data = wav_sel_dat
    get_data, prefix + 'wav_tap_string', data = wav_tap_dat

    ytitle = 'DFB WF '+ strmid(prefix,15,2) + compressed_str

    if n_elements(uniq(wav_sel_dat.y)) EQ 1 then $
      ytitle = ytitle + '!C' + strcompress(wav_sel_dat.y[0], /remove_all)

    if n_elements(uniq(wav_tap_dat.y)) EQ 1 then $
      ytitle = ytitle + '!C' + $
      strsplit(strcompress(wav_tap_dat.y[0], /remove_all), $
      'samples/s', /ex) + ' Hz'

    options, prefix + 'wav_data*', 'ytitle', ytitle

  endelse

end

options, prefix + '*string', 'tplot_routine', 'strplot'
options, prefix + '*string', 'yrange', [-0.1,1.0]
options, prefix + '*string', 'ystyle', 1
options, prefix + '*string', 'yticks', 1
options, prefix + '*string', 'ytickformat', '(A1)'
options, prefix + '*string', 'noclip', 0

end