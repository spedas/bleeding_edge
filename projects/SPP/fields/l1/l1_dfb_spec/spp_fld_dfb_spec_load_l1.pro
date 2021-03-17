pro spp_fld_dfb_spec_load_l1, file, prefix = prefix, varformat = varformat

  if n_elements(file) LT 1 then begin
    print, 'Must provide a CDF file to load"
    return
  endif

  cdf2tplot, /get_support_data, file, prefix = prefix, varnames = varnames

  status_items = ['enable','bin','src_sel','scm_rotate','gain','navg','concat']

  spec_number = fix(strmid(prefix,1,1,/rev))

  case spec_number of
    1: colors = 6 ; red
    2: colors = 4 ; green
    3: colors = 2 ; blue
    4: colors = 1 ; magenta
  endcase

  get_data, prefix + 'navg', data = dat_navg

  if size(/type, dat_navg) NE 8 then begin

    print, 'no DFB spectra loaded'
    return

  endif

  options, prefix + status_items, 'colors', colors
  ;options, prefix + status_items, 'psym', spec_number + 3
  options, prefix + status_items, 'psym_lim', 100
  options, prefix + status_items, 'symsize', 0.75
  options, prefix + status_items, 'panel_size', 0.75
  options, prefix + status_items, 'ysubtitle', ''

  options, prefix + 'spec', 'spec', 1

  options, prefix + 'src_sel', 'yrange', [-0.5,15.5]
  options, prefix + 'src_sel', 'ystyle', 1
  options, prefix + 'src_sel', 'labels', [string(spec_number,format='(I1)')]

  options, prefix + 'enable', 'yrange', [-0.25,1.25]
  options, prefix + 'enable', 'ystyle', 1
  options, prefix + 'enable', 'yticks', 1
  options, prefix + 'enable', 'ytickv', [0,1]
  options, prefix + 'enable', 'yminor', 1
  options, prefix + 'enable', 'ysubtitle', ''
  options, prefix + 'enable', 'panel_size', 0.35

  options, prefix + 'bin', 'yrange', [-0.25,1.25]
  options, prefix + 'bin', 'ystyle', 1
  options, prefix + 'bin', 'yticks', 1
  options, prefix + 'bin', 'ytickv', [0,1]
  options, prefix + 'bin', 'ytickname', ['56','96']
  options, prefix + 'bin', 'yminor', 1
  options, prefix + 'bin', 'ysubtitle', ''
  options, prefix + 'bin', 'panel_size', 0.35

  options, prefix + 'scm_rotate', 'yrange', [-0.25,1.25]
  options, prefix + 'scm_rotate', 'ystyle', 1
  options, prefix + 'scm_rotate', 'yticks', 1
  options, prefix + 'scm_rotate', 'ytickv', [0,1]
  options, prefix + 'scm_rotate', 'yminor', 1
  options, prefix + 'scm_rotate', 'ysubtitle', ''
  options, prefix + 'scm_rotate', 'panel_size', 0.35

  options, prefix + 'gain', 'yrange', [-0.25,1.25]
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'yticks', 1
  options, prefix + 'gain', 'ytickv', [0,1]
  options, prefix + 'gain', 'yminor', 1
  options, prefix + 'gain', 'ysubtitle', ''
  options, prefix + 'gain', 'panel_size', 0.35

  if n_elements(uniq(dat_navg.y)) EQ 1 then begin

    options, prefix + 'navg', 'yrange', dat_navg.y[0] + [-1.0,1.0]
    options, prefix + 'navg', 'yticks', 2
    options, prefix + 'navg', 'ytickv', dat_navg.y[0] + [-1.0,0.0,1.0]
    options, prefix + 'navg', 'yminor', 1
    options, prefix + 'navg', 'ystyle', 1
    options, prefix + 'navg', 'panel_size', 0.5

  endif else begin

    options, prefix + 'navg', 'yrange', [-0.5,15.5]
    options, prefix + 'navg', 'ystyle', 1

  endelse

  get_data, prefix + 'concat', data = dat_concat

  if n_elements(uniq(dat_concat.y)) EQ 1 then begin

    options, prefix + 'concat', 'yrange', dat_concat.y[0] + [-1.0,1.0]
    options, prefix + 'concat', 'yticks', 2
    options, prefix + 'concat', 'ytickv', dat_concat.y[0] + [-1.0,0.0,1.0]
    options, prefix + 'concat', 'yminor', 1
    options, prefix + 'concat', 'ystyle', 1
    options, prefix + 'concat', 'panel_size', 0.5

  endif else begin

    options, prefix + 'concat', 'yrange', [-0.5,15.5]
    options, prefix + 'concat', 'ystyle', 1

  endelse

  options, prefix + 'saturation_flags', 'tplot_routine', 'bitplot'
  options, prefix + 'saturation_flags', 'numbits', 16
  options, prefix + 'saturation_flags', 'yminor', 1
  options, prefix + 'saturation_flags', 'colors', colors
  options, prefix + 'saturation_flags', 'psyms', spec_number + 3

  get_data, prefix + 'spec', data = spec_data

  get_data, prefix + 'src_sel_string', data = src_sel_string_data

  get_data, prefix + 'gain', data = gain_data

  get_data, prefix + 'navg', data = navg_data

  get_data, prefix + 'bin', data = bin_data

  get_data, prefix + 'spec_nelem', data = nelem_data

  get_data, prefix + 'concat', data = concat_data

  get_data, prefix + 'saturation_flags', data = sat_data

  ; TODO: Make this work with all configurations of spectra

  if size(spec_data, /type) EQ 8 then begin

    if n_elements(spec_data.x) GT 1 then begin

      ; Check if all spectra items in the file have the same number of data
      ; elements and concatenated spectra.

      if n_elements(uniq(bin_data.y)) EQ 1 then begin

        if strpos(prefix, 'ac_spec') NE -1 then is_ac = 1 else is_ac = 0

        n_spec = concat_data.y[0] + 1
        n_bins = bin_data.y[0] ? 96 : 56
        n_avg = 2l^(navg_data.y[0])

        if is_ac then begin
          freq_bins = spp_get_fft_bins_04_ac(n_bins)
        endif else begin
          freq_bins = spp_get_fft_bins_04_dc(n_bins)
        endelse

        n_total = n_elements(spec_data.y)

        n_spec = n_total / n_elements(spec_data.x) / n_bins

        ; The spectral data as returned by TMlib are not in order, instead
        ; the order goes like (fs represent increasing frequencies)
        ; [f1, f0, f3, f2, f5, f4, ...]
        ; This reorders the spectra:

        spec_data_y = reform( $
          transpose($
          [[[spec_data.y[*,1:*:2]]], $
          [[spec_data.y[*,0:*:2]]]],[0,2,1]), $
          size(/dim,spec_data.y))

        ; This takes the concatenated spectra array and makes a new array with
        ; one spectra per column

        new_data_y = transpose(reform(reform(transpose(spec_data_y), n_total), $
          n_bins, n_total/n_bins))

  ;; old slow method of loading spectra data

;        t0_old = systime(/sec)
;
;        new_data_x = []
;        new_data_sat_y = []
;        new_data_gain = []
;        new_data_src_string = []
;
;
;        for i = 0, n_elements(spec_data.x)-1 do begin
;
;          dprint, i, n_elements(spec_data.x), dwait = 5
;
;          gain = gain_data.y[i]
;          src_string = src_sel_string_data.y[i]
;
;          if is_ac then begin
;
;            n_avg_i = 2l^(navg_data.y[i])
;
;            if n_avg_i LE 16 then delta_x = 2d^17 / 150d3   ;; base dt is 1 PPC
;            if n_avg_i GE 32 then delta_x = 2d^17 / 150d3 * double(floor(n_avg_i / 16d))  ;; base dt is N PPC
;
;          endif else begin
;
;            n_avg_i = 2l^(navg_data.y[i])
;
;            delta_x = (2d^17 / 150d3 / 8d) * n_avg_i
;
;          endelse
;
;          new_data_gain = [new_data_gain, lonarr(n_spec) + gain]
;
;          new_data_src_string = [new_data_src_string, strarr(n_spec) + src_string]
;
;
;          new_data_x = [new_data_x,spec_data.x[i] + $
;            delta_x * dindgen(n_spec)]
;
;          if sat_data.y[i] NE 4294967295 then begin ; fill value
;
;            new_data_sat_y = [new_data_sat_y, $
;              (sat_data.y[i] / 2l^lindgen(16) MOD 2)[0:n_spec-1]]
;
;          endif else begin
;
;            ; Currently does not account for partial packets with
;            ; fewer spectra than specified in the CONCAT item
;
;            new_data_sat_y = [new_data_sat_y, lonarr(16)]
;
;          endelse
;
;        endfor

        ; code for validating the new loading method by comparing to old


;        print, 'new method took: ',  systime(/sec) - t0_old, ' seconds'
;
;        new_data_x_old = new_data_x
;        new_data_src_string_old = new_data_src_string
;        new_data_gain_old = new_data_gain
;        new_data_sat_y_old = new_data_sat_y
;        t0_new = systime(/sec)

;; new faster method

        n_pkt = n_elements(spec_data.x)

        indices = rebin(lindgen(1,n_spec),n_pkt,n_spec)
        dindices = rebin(dindgen(1,n_spec),n_pkt,n_spec)

        if is_ac then begin

          delta_x = dblarr(n_pkt)

          dx_ind1 = where(2l^(navg_data.y) LE 16, dx_ind1_count)
          dx_ind2 = where(2l^(navg_data.y) GT 16, dx_ind2_count)

          if dx_ind1_count GT 0 then $
            delta_x[dx_ind1] = 2d^17 / 150d3

          if dx_ind2_count GT 0 then $
            delta_x[dx_ind2] = 2d^17 / 150d3 * $
            double(floor(2l^(navg_data.y[dx_ind2]) / 16d))

        endif else begin

          delta_x = (2d^17 / 150d3 / 8d) * 2l^(navg_data.y)

        endelse

        new_data_x_2d = rebin(spec_data.x, n_pkt, n_spec)
        new_data_x_2d += dindices * rebin(delta_x, n_pkt, n_spec)

        new_data_x = reform(transpose(new_data_x_2d), n_elements(new_data_x_2d))

        sat_ind_2d = (rebin(sat_data.y, n_pkt, n_spec) / 2l^indices) MOD 2

        new_data_sat_y = reform(transpose(sat_ind_2d), n_elements(sat_ind_2d))

        new_data_gain = reform(transpose(rebin(gain_data.y, n_pkt, n_spec)), n_pkt * n_spec)

        new_data_src_string = strarr(n_pkt, n_spec)

        src_strings = src_sel_string_data.y[uniq(src_sel_string_data.y, sort(src_sel_string_data.y))]

        foreach s, src_strings do begin

          src_string_ind = where(src_sel_string_data.y EQ s, src_string_count)

          if src_string_count GT 0 then $
            new_data_src_string[src_string_ind, *] = s

        endforeach

        new_data_src_string = reform(transpose(new_data_src_string), n_elements(new_data_src_string))

        ; code for validating the new loading method by comparing to old

        ;print, 'new method took: ',  systime(/sec) - t0_new, ' seconds'

;        print, array_equal(new_data_x, new_data_x_old)
;        print, array_equal(new_data_src_string, new_data_src_string_old)
;        print, array_equal(new_data_gain, new_data_gain_old)
;        print, array_equal(new_data_sat_y, new_data_sat_y_old)

                ;stop

        ; In addition to the ADC saturation set in the packet, we also
        ; set the 'soft' saturation flag when a gain boosted DFB spectrum
        ; has a value of 255 (max value).  See below for interpretation of
        ; saturation indicator

        soft_sat_y = ulong(max(new_data_y[*,2:*], dim = 2) EQ 255) * 2

        new_data_sat_y += soft_sat_y

        ; stop

        data_v = transpose(rebin(freq_bins.freq_avg,$
          n_elements(freq_bins.freq_avg),$
          n_elements(new_data_x)))

        valid_spec_ind = where(total(abs(new_data_y),2) GT 0, valid_spec_count)

        if valid_spec_count GT 0 then begin

          new_data_x = new_data_x[valid_spec_ind]
          new_data_y = new_data_y[valid_spec_ind,*]
          data_v = data_v[valid_spec_ind,*]
          new_data_gain = new_data_gain[valid_spec_ind]
          new_data_src_string = new_data_src_string[valid_spec_ind]
          new_data_sat_y = new_data_sat_y[valid_spec_ind]

        endif

        store_data, prefix + 'spec_converted', $
          data = {x:new_data_x, $
          y:alog10(spp_fld_dfb_psuedo_log_decompress(new_data_y, $
          type = 'spectra', high_gain = new_data_gain)), $
          v:data_v}

        store_data, prefix + 'src_string_all', $
          data = {x:new_data_x, $
          y:new_data_src_string}

        store_data, prefix + 'gain_all', $
          data = {x:new_data_x, $
          y:new_data_gain}

        options, prefix + 'spec_converted', 'panel_size', 2
        options, prefix + 'spec_converted', 'spec', 1
        options, prefix + 'spec_converted', 'no_interp', 1
        options, prefix + 'spec_converted', 'zlog', 0
        options, prefix + 'spec_converted', 'ylog', 1
        options, prefix + 'spec_converted', 'ztitle', 'Log Auto [arb.]'
        options, prefix + 'spec_converted', 'ystyle', 1
        options, prefix + 'spec_converted', 'yrange', minmax(freq_bins.freq_avg)

        ; Indicator of saturation.  This variable plots the saturation of
        ; the DFB (0 = unsaturated, 1 = ADC saturated, 2 = soft saturated,
        ; 3 = ADC and soft saturated)

        store_data, prefix + 'sat', $
          data = {x:new_data_x, y:new_data_sat_y}

        options, prefix + 'sat', 'psym', spec_number + 3
        options, prefix + 'sat', 'yrange', [-0.25,3.25]
        options, prefix + 'sat', 'ystyle', 1
        options, prefix + 'sat', 'yticks', 3
        options, prefix + 'sat', 'ytickv', [0,1,2,3]
        options, prefix + 'sat', 'yminor', 1
        options, prefix + 'sat', 'ysubtitle', ''
        options, prefix + 'sat', 'panel_size', 0.35
        options, prefix + 'sat', 'colors', colors

        ; Alternate indicator of saturation.  This is the same data in a slightly
        ; different format, made to make it easy to plot all saturation indicators
        ; for AC or DC spectra in a single panel.  Only saturation is shown,
        ; non-saturated data is left blank

        sat_indicator = float(new_data_sat_y GT 0)

        non_saturated = where(sat_indicator EQ 0, non_sat_count)

        if non_sat_count GT 0 then sat_indicator[non_saturated] = !values.f_nan

        store_data, prefix + 'sat_indicator', $
          data = {x:new_data_x, y:sat_indicator + spec_number - 1}

        options, prefix + 'sat_indicator', 'psym', spec_number + 3
        options, prefix + 'sat_indicator', 'colors', colors
        options, prefix + 'sat_indicator', 'symsize', 0.75
        options, prefix + 'sat_indicator', 'labels', [string(spec_number,format='(I1)')]

      endif else begin

        print, 'Currently this routine does not load files with 56 bin spectra and 96 bin spectra in the same CDF file'

      endelse

    endif

  endif

  ; Clean up some formatting

  ac_dc_string = strupcase(strmid(prefix,12,2))
  spec_ind = strmid(prefix, strlen(prefix)-2, 1)

  dfb_spec_names = tnames(prefix + '*')

  if dfb_spec_names[0] NE '' then begin

    for i = 0, n_elements(dfb_spec_names) - 1 do begin

      dfb_spec_name_i = strmid(dfb_spec_names[i], strlen(prefix))

      if dfb_spec_name_i EQ 'spec_converted' then begin

        ; For the converted spectra: set the title, and add the source
        ; (as a string) to the title if the source is consistent for
        ; all of the loaded data.

        dfb_spec_name_ytitle = ''

        options, prefix + dfb_spec_name_i, 'ysubtitle', 'Freq [Hz]'

        if is_ac then options, prefix + dfb_spec_name_i, 'datagap', 600d else $
          options, prefix + dfb_spec_name_i, 'datagap', 600d

        if tnames(prefix + 'src_sel_string') NE '' then begin

          get_data, prefix + 'src_sel_string', data = src_sel_dat

          if n_elements(uniq(src_sel_dat.y)) EQ 1 then begin

            dfb_spec_name_ytitle += strcompress(src_sel_dat.y[0], /remove_all)

          endif

        endif

      endif else begin

        ; For string items only–remove subtitle and remove '_string' from the
        ; default ytitle

        if strmid(prefix + dfb_spec_name_i,6,/rev) EQ '_string' then begin

          options, prefix + dfb_spec_name_i, 'ysubtitle', ''

          dfb_spec_name_ytitle = $
            strmid(dfb_spec_name_i, 0, strlen(dfb_spec_name_i) - 7)

        endif else begin

          dfb_spec_name_ytitle = dfb_spec_name_i

          if dfb_spec_name_i EQ 'scm_rotate' then dfb_spec_name_ytitle = 'scmrot'

        endelse

      endelse

      ; Set ytitle of TPLOT variable

      options, prefix + dfb_spec_name_i, 'ytitle', $
        ac_dc_string + '!CSP' + $
        string(spec_ind) + '!C' + strupcase(dfb_spec_name_ytitle)

    endfor

  endif

  options, prefix + '*string', 'tplot_routine', 'strplot'
  options, prefix + '*string', 'yrange', [-0.1,1.0]
  options, prefix + '*string', 'ystyle', 1
  options, prefix + '*string', 'yticks', 1
  options, prefix + '*string', 'ytickformat', '(A1)'
  options, prefix + '*string', 'noclip', 0

  ; This makes a composite TPLOT variable with all of the source information
  ; for all of the DC or AC spectra that have been loaded so far

  all_prefix = strmid(prefix, 0, strlen(prefix) - 2)

  src_names = tnames(all_prefix + '?_src_sel')

  store_data, all_prefix + 'all_src_sel', data = src_names

  options, all_prefix + 'all_src_sel', 'yrange', [-0.5,15.5]
  options, all_prefix + 'all_src_sel', 'ystyle', 1
  options, all_prefix + 'all_src_sel', 'panel_size', 2.0

  ; Composite TPLOT variable that shows saturation indicator for all data

  sat_indicator_names = tnames(all_prefix + '?_sat_indicator')

  store_data, all_prefix + 'all_sat_indicator', data = sat_indicator_names

  options, all_prefix + 'all_sat_indicator', 'yrange', [0.5,4.5]
  options, all_prefix + 'all_sat_indicator', 'ystyle', 1
  options, all_prefix + 'all_sat_indicator', 'yminor', 1
  options, all_prefix + 'all_sat_indicator', 'panel_size', 1.0
  options, all_prefix + 'all_sat_indicator', 'ytitle', 'DFB!C' + ac_dc_string + ' SP!CSAT'

end