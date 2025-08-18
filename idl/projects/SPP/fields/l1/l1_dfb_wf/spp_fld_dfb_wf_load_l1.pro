;+
; NAME:
;   SPP_FLD_DFB_WF_LOAD_L1
;
; PURPOSE:
;   Loads a L1 FIELDS DFB Waveform CDF file into TPLOT variables.
;
; CALLING SEQUENCE:
;   spp_fld_dfb_wf_load_l1, file, prefix = prefix
;
; INPUTS:
;   FILE: The name of the FIELDS Level 1 CDF file to be loaded.
;   PREFIX: The standard input is 'spp_fld_magi_survey_' or
;     'spp_fld_mago_survey_'
;   COMPRESSED: Set this keyword if the data contained in the
;     CDF file is compressed.  Note: this keyword is kept for backwards
;     compatibility, but all L1 CDF files produced since launch do
;     not contain compressed packets.  (The CDF files themselves are
;     gzip compressed.)
;
; OUTPUTS: No outputs returned.  TPLOT variables containing DFB WF data from
;   the specified CDF file will be created.
;
; EXAMPLE:
;   spp_fld_dfb_wf_load_l1, file, prefix = 'dfb_wf_01_'
;
; CREATED BY:
;   pulupa
;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2023-02-02 15:06:08 -0800 (Thu, 02 Feb 2023) $
;  $LastChangedRevision: 31464 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_dfb_wf/spp_fld_dfb_wf_load_l1.pro $
;

pro spp_fld_dfb_wf_load_l1, file, prefix = prefix, compressed = compressed, varformat = varformat, $
  record = record, number_records = number_records

  if prefix.StartsWith('lusee') then prefix_len = 13 else prefix_len = 15

  ; Some special cases for the varformat keyword, used in L1 -> L1b processing.

  load_wf_v = 1
  load_meta_only = 0
  load_for_scam = 0

  if n_elements(varformat) GT 0 then begin

    ; Loading metadata only

    if array_equal(['compression', 'wav_enable', 'wav_sel', $
      'wav_sel_string', 'wav_tap'], varformat) then load_meta_only = 1

    ; Not loading approximate voltage (to reduce memory usage)

    if array_equal(['CCSDS_MET_Seconds', 'CCSDS_MET_SubSeconds', $
      'compression', 'wav_enable', 'wav_sel', $
      'wav_sel_string', 'wav_tap', 'wav_tap_string', 'wf_pkt_data'], varformat) then $
      load_wf_v = 0

    ; load only what is needed for SCaM

    if array_equal(['CCSDS_MET_Seconds', 'CCSDS_MET_SubSeconds', $
      'wav_sel', 'wav_sel_string', 'wav_tap', 'wf_pkt_data'], varformat) then begin
      load_wf_v = 0
      load_for_scam = 1
    endif

  endif

  ; Check for existence of file

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_dfb_wf_load_l1', dlevel = 2

    return

  endif

  ; Load files into TPLOT variables with cdf2tplot
  ;
  ; We use the variant of cdf2tplot which allows the number_records keyword.
  ; Not used in standard processing, but useful for examining only a small
  ; portion of a very large CDF file.

  if n_elements(varformat) GT 0 then begin

    spd_cdf2tplot, file, prefix = prefix, varnames = varnames, $
      varformat = varformat, $
      record = record, number_records = number_records

  endif else begin

    spd_cdf2tplot, /get_support, file, prefix = prefix, varnames = varnames, $
      varformat = varformat, $
      record = record, number_records = number_records

  endelse

  if varnames[0] EQ '' then begin

    dprint, 'No variables found in file ' + file, dlevel = 2

    return

  endif

  ; Note if DFB WF data is compressed-this option is kept for backwards
  ; compatibility, but all L1 CDF files produced since launch do
  ; not contain compressed packets.

  if keyword_set(compressed) then compressed_str = '(Comp)' else $
    compressed_str = ''

  ; Plot options for DFB WF metadata

  get_data, prefix + 'wav_tap', data = d_wav_tap

  if size(/type, d_wav_tap) EQ 8 then begin

    options, prefix + 'wav_tap', 'ynozero', 1
    options, prefix + 'wav_tap', 'colors', [6]
    options, prefix + 'wav_tap', 'psym_lim', 100
    options, prefix + 'wav_tap', 'ytitle', $
      'DFB WF ' + strmid(prefix,prefix_len,2) + compressed_str + '!CTap'

    options, prefix + 'wav_tap', 'yrange', [min(d_wav_tap.y) - 1, max(d_wav_tap.y) + 1]
    options, prefix + 'wav_tap', 'ystyle', 1

  endif

  get_data, prefix + 'wav_sel', data = d_wav_sel

  if size(/type, d_wav_sel) EQ 8 then begin

    options, prefix + 'wav_sel', 'ynozero', 1
    options, prefix + 'wav_sel', 'colors', [6]
    options, prefix + 'wav_sel', 'psym_lim', 100
    options, prefix + 'wav_sel', 'ytitle', $
      'DFB WF ' + strmid(prefix,prefix_len,2) + compressed_str + '!CSelect'

    options, prefix + 'wav_sel', 'yrange', [min(d_wav_sel.y) - 1, max(d_wav_sel.y) + 1]
    options, prefix + 'wav_sel', 'ystyle', 1

  endif

  if (tnames(prefix + 'compression'))[0] NE '' then begin

    options, prefix + 'compression', 'yrange', [-0.25,1.25]
    options, prefix + 'compression', 'ystyle', 1
    options, prefix + 'compression', 'psym_lim', 100
    options, prefix + 'compression', 'symsize', 0.5
    options, prefix + 'compression', 'panel_size', 0.5
    options, prefix + 'compression', 'ytitle', $
      'DFB WF ' + strmid(prefix,prefix_len,2) + compressed_str + '!CCompression'

  endif

  if (tnames(prefix + 'wav_enable'))[0] NE '' then begin

    options, prefix + 'wav_enable', 'yrange', [-0.25,1.25]
    options, prefix + 'wav_enable', 'ystyle', 1
    options, prefix + 'wav_enable', 'psym_lim', 100
    options, prefix + 'wav_enable', 'symsize', 0.5
    options, prefix + 'wav_enable', 'panel_size', 0.5
    options, prefix + 'wav_enable', 'ytitle', $
      'DFB WF ' +  strmid(prefix,prefix_len,2) + compressed_str + '!CEnable'

  endif

  if (tnames(prefix + 'wav_sel'))[0] NE '' then begin

    options, prefix + 'wav_sel', 'yrange', [-1,16]
    options, prefix + 'wav_sel', 'ystyle', 1
    options, prefix + 'wav_sel', 'psym_lim', 4
    options, prefix + 'wav_sel', 'symsize', 0.5

  endif

  if (tnames(prefix + '*string'))[0] NE '' then begin

    options, prefix + '*string', 'tplot_routine', 'strplot'
    options, prefix + '*string', 'yrange', [-0.1,1.0]
    options, prefix + '*string', 'ystyle', 1
    options, prefix + '*string', 'yticks', 1
    options, prefix + '*string', 'ytickformat', '(A1)'
    options, prefix + '*string', 'noclip', 0

  endif

  ;
  ; End plot options
  ;

  if load_meta_only EQ 1 then return

  ;
  ; Store waveform data in useful tplot variables
  ;

  get_data, prefix + 'wf_pkt_data', data = d

  if load_wf_v EQ 1 then get_data, prefix + 'wf_pkt_data_v', data = d_v

  if size(/type, d) NE 8 then return

  get_data, prefix + 'wav_tap', data = d_tap
  get_data, prefix + 'wav_sel', data = d_sel
  get_data, prefix + 'wav_sel_string', data = d_sel_str

  ; The L1 files contain the waveform data as it is stored in the packets,
  ; with up to 2016 samples per packet.  When the files are loaded into
  ; tplot variables, they are loaded into a 2D array, (n packets * 2016).  For
  ; plotting as a time series, we have to reform the data into a 1D vector.
  ;
  ; From each packet, we will:
  ;  - generate a time series, based on the time tag and the cadence
  ;  - select the valid WF counts (each packet has up to 2016 valid samples
  ;    within, but if only N samples are contained in the packet then
  ;    valid data is in indices [0:N-1] and indices [N:2015] contain
  ;    fill values of -2147483647l.
  ;  - select the valid voltages.  These are in an array of the same size
  ;    as the count array.  Note that voltages in the L1 DFB files are
  ;    approximate–only rough scalar corrections are applied without
  ;    accurate phase and gain correction.
  ;
  ; The vectors generated in the above steps are added to lists, instead of
  ; simply adding to arrays, because adding to lists is significantly faster
  ; in IDL than array concatenation operations.
  ;
  ; Note: Early version of the DFB L1 CDF files did not contain the rough
  ; conversion into volts.  The line:
  ;
  ;   if size(d_v, /type) EQ 8
  ;
  ; which appears several times below, checks for the presence of the voltage
  ; data.  It should be present in any file created since launch.
  ;

  if size(d, /type) EQ 8 then begin

    times_2d = d.x

    n_times_2d = n_elements(times_2d)

    ;
    ; When debugging, note that if number_records is enabled,
    ; then the 2D waveform packet data come back as transposed arrays so
    ; we have to transpose them again here. Not needed in standard
    ; usage.
    ;

    if n_elements(number_records) GT 0 then d = {x:transpose(d.x), y:transpose(d.y)}

    max_samples = (size(d.y))[2]

    times_1d = rebin(times_2d, n_times_2d, max_samples)

    rate = 18750d / (2d^d_tap.y)

    rate_arr = rebin(rate, n_times_2d, max_samples)
    tap_arr = rebin(d_tap.y, n_times_2d, max_samples)
    sel_arr = rebin([d_sel.y], n_times_2d, max_samples)

    sel_uniq = d_sel.y[uniq(d_sel.y, sort(d_sel.y))]

    sel_str_arr = strarr(size(/dim, sel_arr))

    foreach sel, sel_uniq do begin

      sel_ind = where(sel_arr EQ sel, sel_count)

      if sel_count GT 0 then begin

        sel_str = d_sel_str.y[sel_ind[0]]

        sel_str_arr[sel_ind] = sel_str

      endif

    endforeach

    ;    stop

    indices = rebin(indgen(1,max_samples), n_times_2d, max_samples)
    indices_1d = reform(transpose(indices), n_elements(indices))

    times_1d += double(indices) / rate_arr
    times_1d = reform(transpose(times_1d), n_elements(times_1d))

    wf_1d = reform(transpose(d.y), n_elements(d.y))

    if load_wf_v EQ 1 then wf_v_1d = reform(transpose(d_v.y), n_elements(d.y))

    valid = where(wf_1d GT -2147483647l, n_valid)

    tap_arr_1d = reform(transpose(tap_arr), n_elements(times_1d))
    if load_for_scam EQ 0 then $
      sel_str_arr_1d = reform(transpose(sel_str_arr), n_elements(times_1d))

    if n_valid GT 0 then begin

      indices_1d = indices_1d[valid]

      times_1d = times_1d[valid]
      wf_1d = wf_1d[valid]
      if load_wf_v EQ 1 then wf_v_1d = wf_v_1d[valid]

      tap_arr_1d = tap_arr_1d[valid]
      if load_for_scam EQ 0 then $
        sel_str_arr_1d = sel_str_arr_1d[valid]

    endif

    ; Store the counts data in a tplot variable.

    store_data, prefix + 'wav_data', $
      dat = {x:times_1d, y:wf_1d}, $
      dlim = {panel_size:2}

    ; Store the voltage data in a tplot variable.

    if load_wf_v EQ 1 then begin
      if size(d_v, /type) EQ 8 then $
        store_data, prefix + 'wav_data_v', $
        dat = {x:times_1d, y:wf_v_1d}, $
        dlim = {panel_size:2}
    end

    if load_for_scam EQ 0 then store_data, prefix + 'wav_pkt_index', $
      dat = {x:times_1d, y:indices_1d}

    if load_for_scam EQ 0 then store_data, prefix + 'wav_sel_string_all', $
      dat = {x:times_1d, y:sel_str_arr_1d}

    if load_for_scam EQ 0 then store_data, prefix + 'wav_tap_all', $
      dat = {x:times_1d, y:tap_arr_1d}

    ; Set plot options for the waveform data

    options, prefix + 'wav_data*', 'ynozero', 1
    options, prefix + 'wav_data*', 'max_points', 40000l
    options, prefix + 'wav_data*', 'psym_lim', 200
    options, prefix + 'wav_data', 'ysubtitle', '[Counts]'

    if load_wf_v EQ 1 then begin

      options, prefix + 'wav_data_v', 'ysubtitle', '[V]'
      options, prefix + 'wav_data_v', 'datagap', 60d

    end

    ; Set the ytitle for the DFB waveform tplot variable.
    ;
    ; TODO: Improve this by splitting non-unique waveform sources into
    ; separate tplot variables and labeling them accordingly.

    if load_for_scam EQ 0 then begin

      if tnames(prefix + 'wav_sel_string') EQ '' then begin

        ; If the metadata doesn't contain 'string' quantities (as was the case
        ; for early versions of the DFB L1 files) then use the wav_sel variable
        ; to determine the source of the waveform.  If there was only a single
        ; unique source, then add it to the ytitle of the waveform tplot
        ; variable.

        get_data, prefix + 'wav_sel', data = wav_sel_dat

        if n_elements(uniq(wav_sel_dat.y)) EQ 1 then $
          options, prefix + 'wav_data*', 'ytitle', $
          'DFB WF '+ strmid(prefix,prefix_len,2) + compressed_str + $
          '!CSRC:' + strcompress(string(wav_sel_dat.y[0]))

      endif else begin

        ; If the metadata contains 'string' quantities, get the string values
        ; of the selected source and the cadence (tap).  If there is only one
        ; unique source or cadence, then add that source and cadence information
        ; to the ytitle of the waveform tplot variable.

        get_data, prefix + 'wav_sel_string', data = wav_sel_dat
        get_data, prefix + 'wav_tap_string', data = wav_tap_dat

        ytitle = 'DFB WF '+ strmid(prefix,prefix_len,2) + compressed_str

        if n_elements(uniq(wav_sel_dat.y)) EQ 1 then $
          ytitle = ytitle + '!C' + strcompress(wav_sel_dat.y[0], /remove_all)

        if n_elements(uniq(wav_tap_dat.y)) EQ 1 then $
          ytitle = ytitle + '!C' + $
          strsplit(strcompress(wav_tap_dat.y[0], /remove_all), $
          'samples/s', /ex) + ' Hz'

        options, prefix + 'wav_data*', 'ytitle', ytitle

      endelse

    endif

  end

end