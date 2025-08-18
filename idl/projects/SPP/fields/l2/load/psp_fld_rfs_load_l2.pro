;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2023-12-18 16:02:04 -0800 (Mon, 18 Dec 2023) $
; $LastChangedRevision: 32305 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l2/load/psp_fld_rfs_load_l2.pro $
;
;-

pro psp_fld_rfs_load_l2, files, hfr_only = hfr_only, lfr_only = lfr_only, $
  varformat = vars_fmt, level = level
  compile_opt idl2

  if n_elements(level) eq 0 then level = 2

  if strpos(files[0], '_l3_') gt -1 then level = 3

  if n_elements(files) eq 0 and n_elements(hfr_only) eq 0 and n_elements(lfr_only) eq 0 then begin
    psp_fld_rfs_load_l2, /hfr_only
    psp_fld_rfs_load_l2, /lfr_only

    return
  endif else if n_elements(files) eq 0 then begin
    if keyword_set(hfr_only) then rec = 'hfr' else rec = 'lfr'

    spp_fld_load, type = 'rfs_' + rec, /no_load, files = files

    valid_files = where(file_test(files) eq 1, valid_count)

    if valid_count gt 0 then begin
      filenames = files[valid_files]
      psp_fld_rfs_load_l2, filenames
    end

    return
  endif

  if ~keyword_set(vars_fmt) then begin
    vars_fmt = []
    for i = 0, n_elements(files) - 1 do begin
      file = files[i]

      cdf_id = cdf_open(file)

      info = cdf_info(cdf_id, verbose = verbose)

      for j = 0, info.nv - 1 do begin
        name = info.vars[j].name
        if strmid(name, 0, 7) eq 'psp_fld' then begin
          cdf_control, cdf_id, variable = name, get_var_info = vinfo
          ; print, name, vinfo.maxrecs, vinfo.maxrec, file
          if vinfo.maxrec ge 0 and where(vars_fmt eq name) eq -1 then vars_fmt = [vars_fmt, name]
        endif
      endfor

      cdf_close, cdf_id
    endfor
  endif

  cdf2tplot, files, varformat = vars_fmt, varnames = varnames, tplotnames = tn

  meta_end = ['averages', 'peaks', 'ch0', 'ch1', 'string', $
    'nsum', 'gain', 'hl', 'J2000', 'RTN', 'JUPITER', 'bias']

  meta = ['averages', 'peaks', 'ch0', 'ch0_string', 'ch1', 'ch1_string', $
    'nsum', 'gain', 'hl', 'J2000', 'SPP_RTN', 'IAU_JUPITER', 'bias']

  types = ['auto_averages', 'auto_peaks', 'cross_im', 'cross_re', 'coher', 'phase']

  if file_basename(getenv('IDL_CT_FILE')) eq 'spp_fld_colors.tbl' then set_colors = 1 else set_colors = 0

  for i = 0, n_elements(varnames) - 1 do begin
    var = varnames[i]

    if (strpos(var, 'position') eq -1) and $
      (strpos(var, 'temperature') eq -1) and $
      (strpos(var, 'distance') eq -1) then begin
      if tnames(var) eq var and var ne 'psp_fld_l2_quality_flags' $
        and var ne 'psp_fld_l3_quality_flags' then begin
        split = strsplit(var, '_', /extract)

        rec = ''
        type = ''

        if strpos(var, '_hfr_') gt 0 then rec = 'HFR'
        if strpos(var, '_lfr_') gt 0 then rec = 'LFR'

        if rec eq 'HFR' then colors = [2] else colors = [6]

        is_meta = (where(meta_end eq split[-1]) gt -1)

        if is_meta then begin
          options, var, 'colors', colors
          options, var, 'ysubtitle', ''
          options, var, 'psym_lim', 100

          if strpos(var, '_string') gt 0 then begin
            options, var, 'tplot_routine', 'strplot'
            options, var, 'noclip', 0
            options, var, 'ytickformat', 'spp_fld_ticks_blank'
            type = split[-2]
          endif else begin
            type = split[-1]

            get_data, var, dat = d

            if type eq 'ch0' or type eq 'ch1' then begin
              options, var, 'yrange', [-1, 8]
              options, var, 'yticks', 7
              options, var, 'yminor', 0
              options, var, 'ytickv', [0, 1, 2, 3, 4, 5, 6, 7]
              options, var, 'panel_size', 1.0
            endif else if type eq 'nsum' then begin
              options, var, 'yrange', [0, 100]
            endif else if type eq 'hl' then begin
              options, var, 'yrange', [-0.5, 3.5]
              options, var, 'yticks', 3
              options, var, 'yminor', 0
              options, var, 'ytickv', [0, 1, 2, 3]
              options, var, 'panel_size', 0.5
            endif else begin
              if min(d.y) ge 0 and max(d.y) le 1 then begin
                options, var, 'yticks', 1
                options, var, 'yminor', 0
                options, var, 'yrange', [-0.25, 1.25]
                options, var, 'ystyle', 1
                options, var, 'ytickv', [0, 1]
                options, var, 'psym_lim', 100
                options, var, 'panel_size', 0.5
              endif
            endelse
          endelse

          ytitle = rec + '!C' + strupcase(type)

          ytitle = str_sub(ytitle, 'AVERAGES', 'AV')
          ytitle = str_sub(ytitle, 'PEAKS', 'PK')

          ; don't reset the title if it's already set with a source appended

          get_data, var, lim = l

          str_element, l, 'ytitle', ytitle0, success = ytitle_found

          if ytitle_found ne 0 then begin
            if ytitle0.startsWith(ytitle) then begin
              ytitle = ytitle0
            endif else begin
              ytitle = ytitle + ytitle0
            endelse
          end

          options, var, 'ytitle', ytitle

          ; Special options for Level 3 metadata

          if level eq 3 and type eq 'RTN' or type eq 'J2000' or $
            type eq 'JUPITER' or type eq 'bias' then begin
            type = split[-1]

            src = split[6]

            if type eq 'RTN' or type eq 'J2000' or type eq 'JUPITER' then begin
              if type eq 'RTN' then $
                labels = ['R', 'T', 'N'] else $
                labels = ['X', 'Y', 'Z']

              options, var, 'ytitle', $
                strupcase(rec) + '!C' + src + '!C' + type
              options, var, 'labels', labels
              ; options, var, 'colors', 'bgr'
              options, var, 'colors', [2, 3, 6] ; 'bgr'
              options, var, 'line_colors', 10
              options, var, 'yrange', [-1.0, 1.0]
              options, var, 'ystyle', 1
              options, var, 'yticklen', 1
              options, var, 'ygridstyle', 1
              options, var, 'psym_lim', 100
              options, var, 'datagap', 180d
            endif else if type eq 'bias' then begin
              options, var, 'ytitle', $
                strupcase(rec) + '!C' + src + '!C' + 'BIAS'
              options, var, 'ysubtitle', $
                '[uA]'
              options, var, 'tplot_routine', 'psp_fld_aeb_mplot'
              options, var, 'datagap', 180d
            endif
          endif
        endif else begin
          print, var

          src = ''

          if strpos(var, '_auto_') gt 0 then begin
            if strpos(var, '_auto_averages_') gt 0 then type = 'AV'
            if strpos(var, '_auto_peaks_') gt 0 then type = 'PK'
            if set_colors then options, var, 'color_table', 129
            options, var, 'zlog', 1
            options, var, 'auto_downsample', 1
            if strpos(var, 'flux') lt 0 then begin
              src = split[-1]
              options, var, 'ztitle', '[V^2/Hz]'
            endif else begin
              src = split[-2]
              ; options, var, 'ztitle', '[W/m^2/Hz]''
            endelse
          endif

          if strpos(var, '_hires_') gt 0 then begin
            if strpos(var, '_hires_averages_') gt 0 then type = 'HR AV'
            if strpos(var, '_hires_peaks_') gt 0 then type = 'HR PK'
            src = split[-1]
            if set_colors then options, var, 'color_table', 129
            options, var, 'zlog', 1
            options, var, 'ylog', 0
            options, var, 'auto_downsample', 1
            options, var, 'ztitle', '[V^2/Hz]'
          endif

          if strpos(var, '_coher_') gt 0 then begin
            type = 'COH'
            src = split[-2] + '-' + split[-1]
            if set_colors then options, var, 'color_table', 117
            options, var, 'zlog', 1
            options, var, 'zrange', [0.001, 1]
            options, var, 'ztitle', ''
          endif

          if strpos(var, '_phase_') gt 0 then begin
            type = 'PHA'
            src = split[-2] + '-' + split[-1]
            if set_colors then options, var, 'color_table', 75
            options, var, 'zlog', 0
            options, var, 'zrange', [-180, 180]
            options, var, 'ztickv', [-180, -90, 0, 90, 180]
            options, var, 'zticks', 4
            options, var, 'ztitle', '[Deg]'
          endif

          if strpos(var, '_cross_') gt 0 then begin
            if strpos(var, '_cross_im_') gt 0 then type = 'X IM'
            if strpos(var, '_cross_re_') gt 0 then type = 'X RE'
            src = split[-2] + '-' + split[-1]
            if set_colors then options, var, 'color_table', 129
            options, var, 'zlog', 0
            options, var, 'ztitle', '[V^2/Hz]'
          endif

          if var.endsWith('sfu') then options, var, 'ztitle', '[sfu]'

          get_data, var, data = d

          if keyword_set(d) then begin
            options, var, 'yrange', minmax(d.v)
            options, var, 'datagap', 180d
            options, var, 'ystyle', 1
            if strpos(var, '_hires_') eq 0 then options, var, 'ylog', 1
            options, var, 'no_interp', 1
            options, var, 'panel_size', 2

            options, var, 'ysubtitle', '[Hz]'

            ytitle = rec + '!C' + strupcase(type) + '!C' + src

            options, var, 'ytitle', ytitle
          endif

          ; add source information to metavariables

          related_meta_vars = tnames(var + '_*')

          foreach rm_var, related_meta_vars do begin
            get_data, rm_var, lim = lim

            str_element, lim, 'ytitle', ytitle0, success = ytitle_found

            if ytitle_found ne 0 then begin
              options, rm_var, 'ytitle', ytitle0 + '!C' + src
            endif else begin
              options, rm_var, 'ytitle', '!C' + src
            endelse
          endforeach

          ; stop
        endelse
      endif
    endif
  endfor

  if level eq 3 then begin
    l3_new_names = tnames('psp_fld_l3_rfs_' + strlowcase(rec) + '_' + $
      ['PSD_FLUX', 'PSD_SFU', 'STOKES_V'])

    foreach name, l3_new_names do begin
      ytitle = strjoin(strupcase((strsplit(name, '_', /ex))[-3 : -1]), '!C')

      options, name, 'ytitle', ytitle

      if ytitle.contains('STOKES') then begin
        options, name, 'zrange', [-1, 1]
        options, name, 'ztitle', 'V/I'
        if set_colors then begin
          options, name, 'color_table', 98
          options, name, 'reverse_color_table', 1
        endif
      endif else begin
        if set_colors then options, name, 'color_table', 129
      endelse
    endforeach

    l3_pos_tnames = tnames('psp_fld_l3_rfs_?fr_position*')

    foreach name, l3_pos_tnames do begin
      frame = name.remove(0, 27)

      options, name, 'ytitle', 'PSP!Cpos' + '!C' + frame
      options, name, 'ysubtitle', '[km]'

      options, name, 'yrange'

      options, name, 'colors', [2, 3, 6] ; 'bgr'
      options, name, 'line_colors', 10

      if name.contains('RTN') then begin
        options, name, 'labels', ['R', 'T', 'N']
        options, name, 'bins', [1, 0, 0]
      endif else begin
        options, name, 'labels', ['X', 'Y', 'Z']
      endelse

      options, name, 'yticklen', 1
      options, name, 'ygridstyle', 1
      options, name, 'psym_lim', 100
      options, name, 'panel_size'
    endforeach

    l3_temp_tnames = tnames('psp_fld_l3_rfs_' + strlowcase(rec) + '_temperature_*')

    foreach name, l3_temp_tnames, l3_temp_tnames_i do begin
      sensor = name.remove(0, 30)

      options, name, 'ytitle', sensor + ' Temp'
      options, name, 'ysubtitle', '[C]'

      options, name, 'yrange'
      options, name, 'line_colors', 8

      if name.endsWith('DCB') then color = 0 else $
        color = fix(name.subString(-1))

      if color ge 4 then color += 1

      options, name, 'colors', [color]
      options, name, 'labels', [sensor]

      options, name, 'ynozero', 1
      options, name, 'yticklen', 1
      options, name, 'ygridstyle', 1
      options, name, 'psym_lim', 100
      options, name, 'panel_size'
    endforeach

    store_data, l3_temp_tnames[0].subString(0, 29), data = l3_temp_tnames

    options, l3_temp_tnames[0].subString(0, 29), 'ytitle', 'Temp'
  endif

  ; For quality flag filtering support
  r = where(tn.matches('quality_flag'))
  qf_root = tn[r[0]]
  options, tn, /def, qf_root = qf_root
end