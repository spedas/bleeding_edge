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
;  $LastChangedDate: 2019-01-30 21:11:34 -0800 (Wed, 30 Jan 2019) $
;  $LastChangedRevision: 26522 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_dfb_wf/spp_fld_dfb_wf_load_l1.pro $
;

pro spp_fld_dfb_wf_load_l1, file, prefix = prefix, compressed = compressed

  ; Check for existence of file

  if typename(file) EQ 'UNDEFINED' then begin

    dprint, 'No file provided to spp_fld_dfb_wf_load_l1', dlevel = 2

    return

  endif

  ; Load files into TPLOT variables with cdf2tplot

  cdf2tplot, /get_support_data, file, prefix = prefix, varnames = varnames

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
  options, prefix + 'wav_tap', 'ynozero', 1
  options, prefix + 'wav_tap', 'colors', [6]
  options, prefix + 'wav_tap', 'psym_lim', 100
  options, prefix + 'wav_tap', 'ytitle', $
    'DFB WF ' + strmid(prefix,15,2) + compressed_str + '!CTap'

  options, prefix + 'compression', 'yrange', [-0.25,1.25]
  options, prefix + 'compression', 'ystyle', 1
  options, prefix + 'compression', 'psym_lim', 100
  options, prefix + 'compression', 'symsize', 0.5
  options, prefix + 'compression', 'panel_size', 0.5
  options, prefix + 'compression', 'ytitle', $
    'DFB WF ' + strmid(prefix,15,2) + compressed_str + '!CCompression'

  options, prefix + 'wav_enable', 'yrange', [-0.25,1.25]
  options, prefix + 'wav_enable', 'ystyle', 1
  options, prefix + 'wav_enable', 'psym_lim', 100
  options, prefix + 'wav_enable', 'symsize', 0.5
  options, prefix + 'wav_enable', 'panel_size', 0.5
  options, prefix + 'wav_enable', 'ytitle', $
    'DFB WF ' +  strmid(prefix,15,2) + compressed_str + '!CEnable'

  options, prefix + 'wav_sel', 'yrange', [-1,16]
  options, prefix + 'wav_sel', 'ystyle', 1
  options, prefix + 'wav_sel', 'psym_lim', 4
  options, prefix + 'wav_sel', 'symsize', 0.5

  options, prefix + '*string', 'tplot_routine', 'strplot'
  options, prefix + '*string', 'yrange', [-0.1,1.0]
  options, prefix + '*string', 'ystyle', 1
  options, prefix + '*string', 'yticks', 1
  options, prefix + '*string', 'ytickformat', '(A1)'
  options, prefix + '*string', 'noclip', 0

  ;
  ; End plot options
  ;

  ;
  ; Store waveform data in useful tplot variables
  ;

  get_data, prefix + 'wf_pkt_data', data = d
  get_data, prefix + 'wf_pkt_data_v', data = d_v
  get_data, prefix + 'wav_tap', data = d_tap

  ; The L1 files contain the waveform data as it is stored in the packets,
  ; with up to 2106 samples per packet.  When the files are loaded into
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
  ; TODO: Improve speed of loading DFB L1 WF data.
  ; (It would be even faster to just do the whole thing with array
  ; operations, as is done in SPP_FLD_MAG_SURVEY_LOAD_L1.)

  all_wf_time_list = LIST()
  all_wf_decompressed_list = LIST()
  all_wf_decompressed_v_list = LIST()

  ; Compute the ideal delay from the DFB digital filter.  Note that this only
  ; applies for DFB V or E data.  The delay depends on the cadence of the
  ; measurement, contained in the 'tap' metadata.

  Ideal_delay = !null
  delay_loc = 0d
  print, 'Sample Rate      ', 'Ideal Cumulative delay (s) - V or E DC only'
  for index = 0, 15, 1 do begin
    if index EQ 0 then delay_loc += (4d / 18750d)
    if index GT 0 then begin
      delay_loc += (3d / (18750d/ 2d^(index)) + 1d / (18750d/ 2d^(index - 1d)))
      Ideal_delay = [Ideal_delay, delay_loc]
      print, 18750d/ 2d^(index), delay_loc
    endif
  endfor

  if size(d, /type) EQ 8 then begin

    ; Step through each packet of waveform data.  wf_i and wf_i_v are the
    ; valid count and voltage measurements from each packet (valid = non
    ; fill values.

    for i = 0, n_elements(d.x) - 1 do begin

      wf_i0 = reform(d.y[i,*])
      wf_i = wf_i0[where(wf_i0 GT -2147483647l)]

      if size(d_v, /type) EQ 8 then begin

        wf_i0_v = reform(d_v.y[i,*])
        wf_i_v = wf_i0_v[where(wf_i0 GT -2147483647l)]

      endif

      ; Decompress data if compressed (see note in doclib header)

      if keyword_set(compressed) then begin
        wf_i = decompress(uint(wf_i))
      end

      ; Add waveform counts from the packet to the overall list of counts.
      all_wf_decompressed_list.Add, wf_i

      ; Add waveform voltages from the packet to the overall list of voltages.
      if size(d_v, /type) EQ 8 then all_wf_decompressed_v_list.Add, wf_i_v

      ; Compute the time delay, then compute the time series based on the
      ; packet time, the cadence (tap), and the delay.  Add the time
      ; to the overall list of times.

      ideal_delay_i = ideal_delay[d_tap.y[i]]
      delay_i = ideal_delay_i + 0.5/(18750d / (2d^d_tap.y[i]))

      wf_time = d_tap.x[i] + $
        (dindgen(n_elements(wf_i))) / $
        (18750d / (2d^d_tap.y[i])) - delay_i

      all_wf_time_list.Add, wf_time

      dprint, i, n_elements(d.x), dwait = 5

    endfor

    ; Once we're through all of the packets, we have three IDL LIST variables,
    ; with each element in each LIST containing a packet's worth of DFB L1
    ; waveform counts, voltages, or time stamps.  These steps turn those LISTs
    ; into 1D vectors.

    all_wf_time = (spp_fld_square_list(all_wf_time_list)).ToArray()
    all_wf_decompressed = $
      (spp_fld_square_list(all_wf_decompressed_list)).ToArray()
    if size(d_v, /type) EQ 8 then $
      all_wf_decompressed_v = $
      (spp_fld_square_list(all_wf_decompressed_v_list)).ToArray()

    all_wf_time = reform(transpose(all_wf_time), n_elements(all_wf_time))
    all_wf_decompressed = $
      reform(transpose(all_wf_decompressed), n_elements(all_wf_time))
    if size(d_v, /type) EQ 8 then $
      all_wf_decompressed_v = $
      reform(transpose(all_wf_decompressed_v), n_elements(all_wf_time))

    wf_valid_ind = where(finite(all_wf_time), wf_valid_count)

    if wf_valid_count GT 0 then begin
      all_wf_time = all_wf_time[wf_valid_ind]
      all_wf_decompressed = all_wf_decompressed[wf_valid_ind]
      if size(d_v, /type) EQ 8 then $
        all_wf_decompressed_v = all_wf_decompressed_v[wf_valid_ind]
    endif

    ; Store the counts data in a tplot variable.

    store_data, prefix + 'wav_data', $
      dat = {x:all_wf_time, y:all_wf_decompressed}, $
      dlim = {panel_size:2}

    ; Store the voltage data in a tplot variable.

    if size(d_v, /type) EQ 8 then $
      store_data, prefix + 'wav_data_v', $
      dat = {x:all_wf_time, y:all_wf_decompressed_v}, $
      dlim = {panel_size:2}

    ; Set plot options for the waveform data

    options, prefix + 'wav_data*', 'ynozero', 1
    options, prefix + 'wav_data*', 'max_points', 40000l
    options, prefix + 'wav_data*', 'psym_lim', 200
    options, prefix + 'wav_data', 'ysubtitle', '[Counts]'
    options, prefix + 'wav_data_v', 'ysubtitle', '[V]'
    options, prefix + 'wav_data_v', 'datagap', 60d

    ; Set the ytitle for the DFB waveform tplot variable.
    ; 
    ; TODO: Improve this by splitting non-unique waveform sources into
    ; separate tplot variables and labeling them accordingly.

    if tnames(prefix + 'wav_sel_string') EQ '' then begin

      ; If the metadata doesn't contain 'string' quantities (as was the case
      ; for early versions of the DFB L1 files) then use the wav_sel variable
      ; to determine the source of the waveform.  If there was only a single
      ; unique source, then add it to the ytitle of the waveform tplot
      ; variable.

      get_data, prefix + 'wav_sel', data = wav_sel_dat

      if n_elements(uniq(wav_sel_dat.y)) EQ 1 then $
        options, prefix + 'wav_data*', 'ytitle', $
        'DFB WF '+ strmid(prefix,15,2) + compressed_str + $
        '!CSRC:' + strcompress(string(wav_sel_dat.y[0]))

    endif else begin

      ; If the metadata contains 'string' quantities, get the string values
      ; of the selected source and the cadence (tap).  If there is only one
      ; unique source or cadence, then add that source and cadence information
      ; to the ytitle of the waveform tplot variable.

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

end