
;+
;Procedure: THM_CAL_FFT
;
;Purpose:  Converts raw FFT (on-board FFT spectra) data into physical quantities.
;keywords:
;  probe = Probe name. The default is 'all', i.e., calibrate data for all
;          available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, 'ffp_16', 'ffp_32',
;  'ffp_64', 'ffw_16', 'ffw_32', or 'ffw_64'.  default is
;          'all', to calibrate all variables.
;  due to some last minute changes it is required that you include
;  both the raw and the calibrated datatype you want for this function
;  to perform properly
;
;  in_suffix =  optional suffix to add to name of input data quantity, which
;          is generated from probe and datatype keywords.
;  out_suffix = optional suffix to add to name for output tplot quantity,
;          which is generated from probe and datatype keywords.
;  /VALID_NAMES; returns the allowable input names in the probe and
;  datatype variables
;   /VERBOSE or VERBOSE=n ; set to enable diagnostic message output.
;		higher values of n produce more and lower-level diagnostic messages.
;
;
;Example:
;   thm_cal_fft
;
;Notes:
;	-- Changes between signal sources are handled;
;		source info from HED data should be used to get actual units of a given spectrum.
;	-- fixed, nominal calibration pars used (gains and frequency
;    responses), rather than proper time-dependent parameters.
;--must include raw types in datatype input for calibration to
;work properly(hopefully will be fixed post-release)
;--support data must be loaded to function properly
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-08-30 17:47:46 -0700 (Tue, 30 Aug 2016) $
; $LastChangedRevision: 21775 $
; $URL $
;-

pro thm_cal_fft, probe=probe, datatype=datatype,trange=trange, in_suffix = in_suffix, $
                 out_suffix = out_suffix, valid_names=valid_names, verbose=verbose

  thm_init

  vprobes = ['a', 'b', 'c', 'd', 'e']
  valid_raw = [ 'fff_16', 'fff_32', 'fff_64', 'ffp_16', 'ffp_32', 'ffp_64', 'ffw_16', 'ffw_32', 'ffw_64' ]

  fft_sel_str = [ 'v1', 'v2', 'v3', 'v4', 'v5', 'v6', $
                  'edc12', 'edc34', 'edc56', $
                  'scm1', 'scm2', 'scm3', $
                  'eac12', 'eac34', 'eac56', $
                  'undef', $
                  'eperp', 'epara', 'dbperp', 'dbpara' ]

  valid_datatypes = array_cross(valid_raw, fft_sel_str)
  
  valid_datatypes = reform(valid_datatypes[0, *] + '_' + valid_datatypes[1, *])

  valid_datatypes = ssl_set_union(valid_datatypes, valid_raw)

  if not keyword_set(in_suffix) then in_suffix = ''
  if not keyword_set(out_suffix) then out_suffix = ''

  if arg_present( valid_names) then begin
    probe = vprobes
    datatype = valid_datatypes
    dprint, string( strjoin( valid_datatypes, ','), format = '( "Valid names:",X,A,".")')
    return
  endif


;probe validation
  if n_elements(probe) eq 1 then if probe eq 'f' then vprobes = ['f']
  if not keyword_set(probe) then probe = vprobes $
  else probe = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all)
  if not keyword_set(probe) then return
  if keyword_set(verbose) then printdat, snames, /value
  ;;;;if keyword_set(verbose) then printdat, snames, /value, type_sname+'s'
  
;datatype validation
  if not keyword_set(datatype) then dts = valid_datatypes $
  else dts = ssl_check_valid_name(strlowcase(datatype), valid_datatypes, /include_all)

  if keyword_set(verbose) then printdat, datatype, /value, 'Datatypes'


  for s = 0L, n_elements(probe)-1L do begin
    sc = probe[s] ;only requested raw datatypes are used in this loop
    dtl = ssl_set_intersection(dts, valid_raw)

    if(size(dtl, /n_dim) eq 0) then return

    for n = 0L, n_elements( dtl)-1L do begin
      name = dtl[ n]
      tplot_var = thm_tplot_var( sc, name)

    ;if data is already calibrated skip this iteration
      if thm_data_calibrated(tplot_var+in_suffix) then continue

      get_data, tplot_var+in_suffix, data = d, limit = l, dlim = dl

      tplot_var_src = tplot_var + '_src'
      get_data, tplot_var_src, data = d_src, limit = l_src, dlim = dl_src
; check that returned data and hed structures are structures (get_data
; returns 0 if no TPLOT variable exists).
      if (size( d, /type) eq 8) and (size( d_src, /type) eq 8) then begin ;need better way to check if type eq struct
; loop over the four FFT spectra in each TPLOT variable, decompressing
; the raw data, converting to physical units (spectral density,
; (unit)^2/Hz), and correcting for sensor response and FFT window.
        nbins = n_elements( d.v2)

        res_size = size( d.y, /dimensions)

        for jj = 0L, 3L do begin
; Determine what signal sources were selected over the given time interval,
; and apply the appropriate RAW->PHYS conversion factors.
          fft_sel = reform( d_src.y[ *, jj])
          find_const_intervals, fft_sel, nint = nint, ibeg = ibeg, iend = iend

          if(nint gt 0) then begin
            ;an array holding the data from each interval
            res_arr = fltarr([res_size[0:1], nint]) + !values.f_nan

            ;a list of the sources for each interval
            sel_list = fltarr(nint)

            ;this call just gets the definition of cal_pars.
            ; JWB, 13 June 2008 - replaced 16 with NBINS.
            ;thm_get_fft_cal_pars,0,0,0,16,cal_pars=cp_def
            thm_get_fft_cal_pars, 0, 0, 0, nbins, cal_pars = cp_def

            ;this constructs an array of cal pars structs
            cp_list = replicate(cp_def, nint)

          endif

          for ii = 0L, nint-1L do begin
            t_hdr = [ d_src.x, !values.d_infinity]
            tbeg = t_hdr[ ibeg[ ii]]
            tend = t_hdr[ iend[ ii] + 1L]
; find all the spectra from the beginning of the first packet of the
; interval, to the end of the last packet of the interval (actually
; just before the beginning of the first packet of the next interval).
            idx = where( d.x ge tbeg and d.x lt tend, icnt)
            if icnt gt 0 then begin
              thm_get_fft_cal_pars, tbeg, tend, fft_sel[ ibeg[ ii]], nbins, cal_pars = cp
              res_arr[idx, *, ii] = cp.gain*((1.0 + fltarr( icnt))#cp.freq_resp[ *])*(thm_fft_decompress(d.y[ idx, *, jj]))
              sel_list[ii] = fft_sel[ibeg[ii]]
              cp_list[ii] = cp
            endif
          endfor                ; loop over constant source intervals

          ;interval collation handles a very rare case of instrument
          ;reconfiguration
          out_data = thm_collate_intervals(res_arr, sel_list)

          sel = thm_get_unique_sel(sel_list, fft_sel_str)

          cp = thm_get_unique_cp(sel_list, fbk_sel_str, cp_list)

          ;here create the output variables
          for i = 0, n_elements(sel)-1L do begin

            ;output name
            dqd = tplot_var + '_' + sel[i] + out_suffix
            dqd_orig = tplot_var + '_' + sel[i] 
            
            ;update the DLIMIT elements to reflect
            ;RAW->PHYS transformation, coordinate
            ;system, etc.


            str_element, dl, 'data_att', data_att, success = has_data_att
            if has_data_att then begin
              str_element, data_att, 'data_type', 'calibrated', /add
            endif else data_att = { data_type: 'calibrated' }
            str_element, data_att, 'coord_sys', 'sensor', /add
            str_element, data_att, 'cal_par_time', cp[i].cal_par_time, /add
            str_element, data_att, 'units', cp[i].units, /add
            str_element, data_att, 'source_var', tplot_var, /add
            str_element, data_att, 'source_num', jj, /add
            str_element, dl, 'data_att', data_att, /add
            str_element, dl, 'ytitle', string( dqd_orig, format = '(A,"!C!C[Hz]")'), /add
            str_element, dl, 'spec', 1, /add
            str_element, dl, 'ztitle', string( cp[i].units, format = '(A)'), /add
            str_element, dl, 'zlog', 1, /add
            str_element, dl, 'x_no_interp', 1, /add
            str_element, dl, 'y_no_interp', 1, /add
            str_element, dl, 'ysubtitle', /delete
;- Don't cut off top and bottom of frequency bands
            str_element, dl, 'overlay', 0, /add

            ; store the transformed spectra back into the original TPLOT variable.

            foo = where(dts eq (name+'_'+sel[i]), bar)

            if(bar eq 1) then begin
              store_data, dqd, $
                data = { x:d.x, y:out_data[*, *, i], v:cp[i].ff }, $
                lim = l, dlim = dl
              ;set additional plotting options
              options, dqd, 'zlog', 1
              options, dqd, 'ylog', 1
              if strcmp(sel[i], 'eac', 3) then options, dqd, 'yrange', [ 10., 8192.] $ ;jmm, 2-jul-2008, changed sel to sel[i] 
              else options, dqd, 'yrange', [ 10., 4096.]
              options, dqd, 'ystyle', 1

            endif

          endfor
        endfor                  ; loop over FFT spectra.

      endif else begin        ; necessary TPLOT variables not present.
        if keyword_set(verbose) then $
          dprint, $
          string( tplot_var+in_suffix, tplot_var_src, $
                  format = '("necessary TPLOT variables (",A,X,A,") not present for RAW->PHYS transformation.")')
      endelse

    endfor                      ; loop over datatype.
  endfor                        ; loop over spacecraft.

end

