;+
;
; NAME:
;   spp_fld_rfs_cross_load_l1
;
; $LastChangedBy: pulupa $
; $LastChangedDate: 2023-09-28 13:18:16 -0700 (Thu, 28 Sep 2023) $
; $LastChangedRevision: 32147 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_rfs_cross/spp_fld_rfs_cross_load_l1.pro $
;
;-

pro spp_fld_rfs_cross_load_l1_metadata_options, prefix, receiver_str, color = color
  compile_opt idl2

  options, prefix + 'compression', 'yrange', [0, 1]
  options, prefix + 'compression', 'ystyle', 1
  options, prefix + 'compression', 'colors', color
  options, prefix + 'compression', 'yminor', 1
  ; options, prefix + 'compression', 'psym', 4
  options, prefix + 'compression', 'psym_lim', 100
  options, prefix + 'compression', 'symsize', 0.5
  options, prefix + 'compression', 'panel_size', 0.35
  options, prefix + 'compression', 'ytitle', receiver_str + ' Cross!CCmprs'
  options, prefix + 'compression', 'datagap', 120

  options, prefix + 'gain', 'yrange', [-0.25, 1.25]
  options, prefix + 'gain', 'yticks', 1
  options, prefix + 'gain', 'ytickv', [0, 1]
  options, prefix + 'gain', 'ytickname', ['Lo', 'Hi']
  options, prefix + 'gain', 'ystyle', 1
  options, prefix + 'gain', 'colors', color
  options, prefix + 'gain', 'yminor', 1
  ; options, prefix + 'gain', 'psym', 4
  options, prefix + 'gain', 'psym_lim', 100
  options, prefix + 'gain', 'symsize', 0.5
  options, prefix + 'gain', 'panel_size', 0.35
  options, prefix + 'gain', 'ysubtitle', ''
  options, prefix + 'gain', 'ytitle', receiver_str + ' Cross!CGain'
  options, prefix + 'gain', 'datagap', 120

  options, prefix + 'hl', 'yrange', [0, 3]
  options, prefix + 'hl', 'yticks', 3
  options, prefix + 'hl', 'ystyle', 1
  options, prefix + 'hl', 'colors', color
  options, prefix + 'hl', 'yminor', 1
  ; options, prefix + 'hl', 'psym', 4
  options, prefix + 'hl', 'psym_lim', 100
  options, prefix + 'hl', 'symsize', 0.5
  options, prefix + 'hl', 'panel_size', 0.5
  options, prefix + 'hl', 'ytitle', receiver_str + ' Cross!CHL'
  options, prefix + 'hl', 'datagap', 120

  options, prefix + 'nsum', 'yrange', [0, 100]
  options, prefix + 'nsum', 'ystyle', 1
  options, prefix + 'nsum', 'yminor', 1
  options, prefix + 'nsum', 'colors', color
  ; options, prefix + 'nsum', 'psym', 4
  options, prefix + 'nsum', 'psym_lim', 100
  options, prefix + 'nsum', 'symsize', 0.5
  options, prefix + 'nsum', 'ytitle', receiver_str + ' Cross!CNSUM'
  options, prefix + 'nsum', 'datagap', 120

  options, prefix + 'ch?', 'yrange', [0, 7]
  options, prefix + 'ch?', 'ystyle', 1
  options, prefix + 'ch?', 'yminor', 1
  options, prefix + 'ch?', 'colors', color
  ; options, prefix + 'ch?', 'psym', 4
  options, prefix + 'ch?', 'psym_lim', 100
  options, prefix + 'ch?', 'symsize', 0.5
  options, prefix + 'ch?', 'datagap', 120
  options, prefix + 'ch0', 'ytitle', receiver_str + ' Cross!CCH0 Source'
  options, prefix + 'ch1', 'ytitle', receiver_str + ' Cross!CCH1 Source'

  options, prefix + 'xspec_??', 'spec', 1
  options, prefix + 'xspec_??', 'no_interp', 1
  options, prefix + 'xspec_??', 'yrange', [0, 64]
  options, prefix + 'xspec_??', 'ystyle', 1
  options, prefix + 'xspec_??', 'datagap', 120

  options, prefix + 'ch?_string', 'tplot_routine', 'strplot'
  options, prefix + 'ch?_string', 'yrange', [-0.1, 1.0]
  options, prefix + 'ch?_string', 'ystyle', 1
  options, prefix + 'ch?_string', 'yticks', 1
  options, prefix + 'ch?_string', 'ytickformat', '(A1)'
  options, prefix + 'ch?_string', 'noclip', 0
  options, prefix + 'ch?_string', 'ysubtitle', ''
  options, prefix + 'ch0_string', 'ytitle', receiver_str + '!CCROSS!CAUTO!CCH0 SRC'
  options, prefix + 'ch1_string', 'ytitle', receiver_str + '!CCROSS!CAUTO!CCH1 SRC'

  options, prefix + 'xspec_re', 'ytitle', receiver_str + ' Cross!CReal Raw'
  options, prefix + 'xspec_im', 'ytitle', receiver_str + ' Cross!CImag Raw'
end

pro spp_fld_rfs_cross_load_l1, file, prefix = prefix, color = color, varformat = varformat
  compile_opt idl2

  if n_elements(file) lt 1 or file[0] eq '' then return

  ; receiver_str = strupcase(strmid(prefix, 12, 3))
  ; if receiver_str EQ 'LFR' then lfr_flag = 1 else lfr_flag = 0

  hfr_pos = strpos(prefix, 'hfr_')
  if hfr_pos gt 0 then prefix = strmid(prefix, 0, hfr_pos) + strmid(prefix, hfr_pos + 4)

  receiver_str = 'RFS'

  if file[0].Contains('lusee') then lusee = 1 else lusee = 0
  rfs_freqs = spp_fld_rfs_freqs(lfr = lfr_flag, lusee = lusee)

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  spp_fld_rfs_cross_load_l1_metadata_options, prefix, 'RFS', color = 0

  get_data, prefix + 'gain', data = rfs_gain_dat
  get_data, prefix + 'nsum', data = rfs_nsum

  lo_gain = where(rfs_gain_dat.y eq 0, n_lo_gain)

  ; Using definition of power spectral density
  ; S = 2 * Nfft / fs |x|^2 / Wss where
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

  V2_factor = (2d / 3d) * 4096d / 38.4d6 / ((250d * 2048d) ^ 2d * 0.782d * 65536d)

  get_data, prefix + 'xspec_re', data = rfs_dat_xspec_re

  ; See spp_fld_rfs_float for notes on 'zero_fix'

  if min(rfs_dat_xspec_re.x) gt time_double('2022-10-11/00:00:00') then $
    zero_fix = 0 else zero_fix = 1

  converted_data_xspec_re = spp_fld_rfs_float(rfs_dat_xspec_re.y, $
    /cross, zero_fix = zero_fix)

  converted_data_xspec_re *= V2_factor

  if n_lo_gain gt 0 then converted_data_xspec_re[lo_gain, *] *= 2500.d

  converted_data_xspec_re /= rebin(rfs_nsum.y, $
    n_elements(rfs_nsum.x), $
    n_elements(rfs_freqs.reduced_freq))

  ; store_data, prefix + 'xspec_re_converted', $
  ; data = {x:rfs_dat_xspec_re.x, y:converted_data_xspec_re, $
  ; v:rfs_freqs.reduced_freq}

  get_data, prefix + 'xspec_im', data = rfs_dat_xspec_im

  ; See spp_fld_rfs_float for notes on 'zero_fix'

  converted_data_xspec_im = spp_fld_rfs_float(rfs_dat_xspec_im.y, $
    /cross, zero_fix = zero_fix)

  ; See "Notes on RFS Polarization" for source of the -1

  converted_data_xspec_im *= -1d * V2_factor

  if n_lo_gain gt 0 then converted_data_xspec_im[lo_gain, *] *= 2500.d

  converted_data_xspec_im /= rebin(rfs_nsum.y, $
    n_elements(rfs_nsum.x), $
    n_elements(rfs_freqs.reduced_freq))

  ; store_data, prefix + 'xspec_im_converted', $
  ; data = {x:rfs_dat_xspec_im.x, y:converted_data_xspec_im, $
  ; v:rfs_freqs.reduced_freq}

  ; options, prefix + 'xspec_??_converted', 'spec', 1
  ; options, prefix + 'xspec_??_converted', 'no_interp', 1
  ; options, prefix + 'xspec_??_converted', 'ylog', 1
  ; options, prefix + 'xspec_??_converted', 'zlog', 0
  ; options, prefix + 'xspec_??_converted', 'ztitle', '[V2/Hz]'
  ; options, prefix + 'xspec_??_converted', 'yrange', [min(rfs_freqs.reduced_freq), max(rfs_freqs.reduced_freq)]
  ; options, prefix + 'xspec_??_converted', 'ystyle', 1
  ; options, prefix + 'xspec_??_converted', 'datagap', 60
  ; options, prefix + 'xspec_??_converted', 'panel_size', 2.

  ; options, prefix + 'xspec_re_converted', 'ytitle', receiver_str + ' Cross!CReal Raw'
  ; options, prefix + 'xspec_im_converted', 'ytitle', receiver_str + ' Cross!CImag Raw'

  get_data, prefix + 'ch0_string', dat = ch0_src_dat
  get_data, prefix + 'ch1_string', dat = ch1_src_dat

  if size(/type, ch0_src_dat) ne 8 then $
    get_data, prefix + 'ch0', dat = ch0_src_dat
  if size(/type, ch1_src_dat) ne 8 then $
    get_data, prefix + 'ch1', dat = ch1_src_dat

  ch0_src_values = ch0_src_dat.y[uniq(ch0_src_dat.y, sort(ch0_src_dat.y))]
  ch1_src_values = ch1_src_dat.y[uniq(ch1_src_dat.y, sort(ch1_src_dat.y))]

  receivers = ['', 'hfr', 'lfr']

  for rec_i = 0, n_elements(receivers) - 1 do begin
    rec = receivers[rec_i]

    case rec of
      '': begin
        auto_match = ''
        prefix2 = prefix ; + 'cross_';prefix.Replace('hfr_', '')
      end
      'lfr': begin
        auto_match = prefix.Replace('_cross', '') + 'lfr_auto_averages_ch0'
        prefix2 = prefix.Replace('_cross', '_lfr_cross')
      end
      'hfr': begin
        auto_match = prefix.Replace('_cross', '') + 'hfr_auto_averages_ch0'
        prefix2 = prefix.Replace('_cross', '_hfr_cross')
      end
    endcase

    if auto_match ne '' then begin
      get_data, auto_match, data = d_auto_match
      get_data, prefix + 'ch0', data = d_cross_match

      if size(/type, d_auto_match) eq 8 then begin
        ; union_auto = array_union(d_auto_match.x, d_cross_match.x)
        union_auto = cmset_op(ch0_src_dat.x, 'AND', d_auto_match.x, /index)

        ind_auto = where(union_auto ge 0, count_auto)
        ind_cross = union_auto[where(union_auto ge 0, count_cross)]

        if count_cross gt 0 then begin
          cross_items = prefix + ['CCSDS_MET_Seconds', $
            'CCSDS_MET_SubSeconds', $
            'CCSDS_Sequence_Number', $
            'compression', 'hl', 'ch0', 'ch1', $
            'ch0_string', 'ch1_string', 'gain', 'nsum', 'xspec_re', 'xspec_im']

          for i = 0, n_elements(cross_items) - 1 do begin
            item = cross_items[i]

            get_data, item, data = data, lim = lim

            cross_pos = strpos(item, 'cross_')
            if cross_pos gt 0 then new_item = strmid(item, 0, cross_pos) + $
              rec + '_' + strmid(item, cross_pos)

            store_data, new_item, $
              data = {x: data.x[ind_cross], y: data.y[ind_cross, *]}, dlim = lim
          endfor

          if rec eq 'lfr' then $
            spp_fld_rfs_cross_load_l1_metadata_options, $
            prefix.Replace('_cross', '_lfr_cross'), 'LFR', color = 6
          if rec eq 'hfr' then $
            spp_fld_rfs_cross_load_l1_metadata_options, $
            prefix.Replace('_cross', '_hfr_cross'), 'HFR', color = 2
        endif else begin
          count = 0
        endelse
      endif else begin
        count = 0
      endelse
    endif

    for i = 0, n_elements(ch0_src_values) - 1 do begin
      for j = 0, n_elements(ch1_src_values) - 1 do begin
        ch0_ij = ch0_src_values[i]
        ch1_ij = ch1_src_values[j]

        inds = where(ch0_src_dat.y eq ch0_ij and ch1_src_dat.y eq ch1_ij, count)

        if auto_match ne '' and count gt 0 then begin
          get_data, auto_match, data = d_auto_match

          if size(/type, d_auto_match) eq 8 then begin
            ; t0 = systime(/seconds)

            ; union_auto = array_union(d_auto_match.x, ch0_src_dat.x[inds])
            union_auto = cmset_op(ch0_src_dat.x[inds], 'AND', d_auto_match.x, /index)

            ; print, 'array_union', systime(/seconds) - t0

            ind_auto = where(union_auto ge 0, count_auto)
            ind_cross = union_auto[where(union_auto ge 0, count_cross)]

            t1 = systime(/seconds)

            ; print, 'cmset_op', systime(/seconds) - t1

            ; stop

            if count_cross gt 0 then begin
              count = count_cross
              inds = inds[ind_cross]
            endif else begin
              count = 0
            endelse
          endif else begin
            count = 0
          endelse
        endif

        if count gt 0 then begin
          src0_string = strcompress(string(ch0_ij), /remove_all)

          dash_pos0 = strpos(src0_string, '-')

          if dash_pos0 ge 0 then src0_string = strmid(src0_string, 0, dash_pos0) + strmid(src0_string, dash_pos0 + 1)

          src1_string = strcompress(string(ch1_ij), /remove_all)

          dash_pos1 = strpos(src1_string, '-')

          if dash_pos1 ge 0 then src1_string = strmid(src1_string, 0, dash_pos1) + strmid(src1_string, dash_pos1 + 1)

          src_name_im = prefix2 + 'im_converted_' + src0_string + '_' + src1_string

          im_data_y = converted_data_xspec_im[inds, *]
          re_data_y = converted_data_xspec_re[inds, *]

          if rec eq 'lfr' then begin
            size_spec = size(im_data_y, /dim)

            if n_elements(size_spec) eq 2 then begin
              cic_r = 8ll
              cic_n = 4ll
              cic_m = 1ll

              rfs_freqs = spp_fld_rfs_freqs(/lfr, lusee = lusee)

              data_v = rfs_freqs.reduced_freq

              ; TODO: Check for when CIC M = 2

              cic_factor = $
                rebin( $
                  transpose((sin(!dpi * cic_m * data_v / 4.8e6) / $
                    sin(!dpi * data_v / 4.8d6 / cic_r)) ^ (2 * cic_n) / $
                    (cic_r * cic_m) ^ (2 * cic_n)), $
                  size(im_data_y, /dim))

              im_data_y /= (cic_factor)
              re_data_y /= (cic_factor)

              im_data_y *= 8 ; LFR
              re_data_y *= 8 ; LFR
            endif
          endif else begin
            cic_factor = 1d

            rfs_freqs = spp_fld_rfs_freqs(lusee = lusee)

            data_v = rfs_freqs.reduced_freq
          endelse

          store_data, src_name_im, $
            data = {x: (rfs_dat_xspec_im.x)[inds], $
              y: im_data_y, $
              v: data_v}

          src_name_re = prefix2 + 're_converted_' + src0_string + '_' + src1_string

          store_data, src_name_re, $
            data = {x: (rfs_dat_xspec_re.x)[inds], $
              y: re_data_y, $
              v: data_v}

          src_name = prefix2 + '??_converted_' + src0_string + '_' + src1_string

          if rec eq '' then title_rec = 'RFS' else title_rec = strupcase(rec)

          ytitle_re = title_rec + ' XRE!C' + src0_string + '!C' + src1_string
          ytitle_im = title_rec + ' XIM!C' + src0_string + '!C' + src1_string

          options, src_name, 'spec', 1
          options, src_name, 'no_interp', 1
          options, src_name, 'ylog', 1
          options, src_name, 'zlog', 0
          options, src_name, 'ztitle', '[V2/Hz]'
          options, src_name, 'ystyle', 1
          options, src_name, 'datagap', 60
          options, src_name, 'panel_size', 2.
          options, src_name_re, 'ytitle', ytitle_re
          options, src_name_im, 'ytitle', ytitle_im
          ; options, src_name, 'color_table', 39

          cross_items = prefix + ['CCSDS_MET_Seconds', $
            'CCSDS_MET_SubSeconds', $
            'CCSDS_Sequence_Number', $
            'compression', 'hl', 'ch0', 'ch1', $
            'ch0_string', 'ch1_string', 'gain', 'nsum', 'xspec_re', 'xspec_im']

          for k = 0, n_elements(cross_items) - 1 do begin
            item = cross_items[k]

            if tnames(item) ne '' then begin
              get_data, item, data = data, lim = lim

              if rec ne '' then $
                get_data, item.Replace('cross_', rec + '_cross_'), data = dummy, lim = lim

              ; cross_pos = strpos(item, 'cross_')
              ; if cross_pos GT 0 then new_item = strmid(item, 0, cross_pos) + $
              ; rec_str + strmid(item, cross_pos) + '_' + src0_string + '_' + src1_string

              if rec ne '' then $
                new_item = item.Replace('cross_', rec + '_cross_') else $
                new_item = item

              new_item = new_item + '_' + src0_string + '_' + src1_string

              if size(/type, lim) eq 8 then begin
                ytitle = lim.ytitle

                if rec ne '' then ytitle = ytitle.Replace('RFS', strupcase(rec))

                ytitle = ytitle + '!C' + src0_string + '!C' + src1_string

                lim.ytitle = ytitle
              end

              store_data, new_item, $
                data = {x: data.x[inds], y: data.y[inds, *]}, dlim = lim
            end
          endfor

          ; print, ch0_ij, ch1_ij, count, src_name
        endif
      endfor
    endfor
  endfor

  ; if n_elements(uniq(ch0_src_dat.y) EQ 1) and $
  ; n_elements(uniq(ch1_src_dat.y) EQ 1)then $
  ; options, prefix + 'xspec_??_converted', 'ysubtitle', $
  ; 'SRC ' + $
  ; strcompress(string(ch0_src_dat.y[0]), /rem) + '-' + $
  ; strcompress(string(ch1_src_dat.y[0]), /rem)
end