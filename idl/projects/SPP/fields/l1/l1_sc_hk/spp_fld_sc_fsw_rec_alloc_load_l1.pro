;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2024-08-06 13:31:54 -0700 (Tue, 06 Aug 2024) $
; $LastChangedRevision: 32780 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_sc_hk/spp_fld_sc_fsw_rec_alloc_load_l1.pro $
;
;-

pro spp_fld_sc_fsw_rec_alloc_load_l1, file, prefix = prefix, varformat = varformat
  compile_opt idl2

  clusters_per_gbit = 3890d

  if not keyword_set(prefix) then prefix = 'spp_fld_sc_fsw_rec_alloc_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  instruments = ['epihi', 'epilo', 'fields', 'sweap', 'wispr']
  inst_abb = ['   EH', '     EL', 'F', ' S', '  W']
  inst_colors = [1, 3, 2, 4, 6]

  sc_fsw_rec_alloc_names = tnames(prefix + '*')

  if sc_fsw_rec_alloc_names[0] ne '' then begin
    for i = 0, n_elements(sc_fsw_rec_alloc_names) - 1 do begin
      name = sc_fsw_rec_alloc_names[i]

      options, name, 'ynozero', 1
      ; options, name, 'colors', [2]
      options, name, 'ytitle', name.remove(0, prefix.strlen() - 1)

      ; options, name, 'psym', 4
      options, name, 'psym_lim', 200
      options, name, 'symsize', 0.75
      options, name, 'datagap', 3600d

      if strpos(name, 'alloc_alloc') ne -1 or $
        strpos(name, 'alloc_used') ne -1 and $
        strpos(name, 'Gbit') eq -1 and $
        strpos(name, 'kbps') eq -1 then begin ; prevents kbps from being included if you run this twice

        get_data, name, dat = d

        store_data, name + '_Gbit', data = {x: d.x, y: d.y / clusters_per_gbit}

        options, name + '_Gbit', 'psym_lim', 200
        options, name + '_Gbit', 'symsize', 0.75
        options, name + '_Gbit', 'datagap', 3600d
      end
    endfor
  endif

  store_data, prefix + 'instrument_alloc', $
    data = tnames('*alloc_alloc*' + instruments + '*Gbit')

  options, prefix + 'instrument_alloc', 'ytitle', 'Inst DCP!CAllocations'
  options, prefix + 'instrument_alloc', 'ysubtitle', 'Gbits'
  options, prefix + 'instrument_alloc', 'datagap', 3600d

  store_data, prefix + 'instrument_used', $
    data = tnames('*alloc_used*' + instruments + '*Gbit')

  options, prefix + 'instrument_used', 'ytitle', 'Inst DCP!CUsed'
  options, prefix + 'instrument_used', 'ysubtitle', 'Gbits'
  options, prefix + 'instrument_used', 'datagap', 3600d

  deriv_data, 'spp_fld_sc_fsw_rec_alloc_used_fields_Gbit', nsmooth = 6

  get_data, 'spp_fld_sc_fsw_rec_alloc_used_fields_Gbit_ddt', dat = d_ddt

  if size(/type, d_ddt) eq 8 then begin
    store_data, 'spp_fld_sc_fsw_rec_alloc_used_fields_kbps', $
      dat = {x: d_ddt.x, y: (d_ddt.y * 1e6 > 0d)}
  endif

  ; Testing out code to make smoother 'kbps' lines
  ;
  ; if the number of points is too large, then this takes too long
  ;

  get_data, prefix + 'used_fields_Gbit', $
    data = d_gbit, al = al

  if n_elements(d_gbit.x) lt 50000l then begin
    gbit2 = dblarr(n_elements(d_gbit.x))

    kbit2 = dblarr(n_elements(d_gbit.x))

    for i = 0, n_elements(d_gbit.x) - 1 do begin
      diff = d_gbit.x - d_gbit.x[i]

      ; an hour time scale seems to be a reasonable compromise between getting
      ; a smooth data rate plot in kbps, and catching transitions

      ind_lo = where(diff le 0d and diff gt -3600d, count_lo)
      ind_hi = where(diff ge 0d and diff lt 3600d, count_hi)

      if (count_hi + count_lo) lt 3 then begin
        gbit2[i] = d_gbit.y[i]
      endif else begin
        lf_par = linfit(d_gbit.x[[ind_lo, ind_hi]], d_gbit.y[[ind_lo, ind_hi]])

        gbit2[i] = lf_par[0] + lf_par[1] * d_gbit.x[i]

        kbit2[i] = lf_par[1] * 1d6 > 0d
      endelse
    endfor

    store_data, prefix + 'used_fields_Gbit_smooth', $
      data = {x: d_gbit.x, y: gbit2}, lim = al

    store_data, prefix + 'used_fields_kbps_smooth', $
      data = {x: d_gbit.x, y: kbit2}, lim = al

    ;
    ; an older method that relied on the spedas deriv_data function
    ;
    ; made a smoother line but had more difficulty identifying
    ; sharp transitions (which we want to ID mode changes)
    ;

    ; deriv_data, 'spp_fld_sc_fsw_rec_alloc_used_fields_Gbit_smooth', nsmooth = 6

    ; get_data, 'spp_fld_sc_fsw_rec_alloc_used_fields_Gbit_smooth_ddt', dat = d_ddt

    ; if size(/type, d_ddt) EQ 8 then begin

    ; store_data, 'spp_fld_sc_fsw_rec_alloc_used_fields_kbps_smooth', $
    ; dat = {x:d_ddt.x, y:(d_ddt.y*1e6 > 0d)}

    ; endif
  endif

  options, prefix + 'used_fields_kbps*', 'ylog', 1

  options, prefix + 'used_fields_kbps*', 'yrange', [0.2, 200.]

  options, prefix + 'used_fields_kbps*', 'ystyle', 1
  options, prefix + 'used_fields_kbps*', 'ytitle', 'FIELDS!Ckbps'
  options, prefix + 'used_fields_kbps*', 'datagap', 3600d

  for i = 0, n_elements(instruments) - 1 do begin
    inst = instruments[i]

    inst_names = tnames(prefix + '*' + inst + '*')

    for j = 0, n_elements(inst_names) - 1 do begin
      name = inst_names[j]

      options, name, 'colors', [inst_colors[i]]
      options, name, 'labels', inst_abb[i]
    endfor
  endfor

  ; get_data, 'spp_fld_sc_fsw_rec_alloc_used_fields_Gbit', data = d_gbit
  ;
  ; if size(/type, d_gbit) EQ 8 then begin
  ;
  ; res = 1200d
  ;
  ; int_times = time_intervals(trange = minmax(d_gbit.x), res = res)
  ;
  ; int_gbit = data_cut('spp_fld_sc_fsw_rec_alloc_used_fields_Gbit', int_times)
  ;
  ; dt = 1d
  ;
  ; order = 1
  ; ; Don't forget to normalize the coefficients.
  ; savgolFilter = SAVGOL(16, 16, order, 2)*(FACTORIAL(order)/ $
  ; (dt^order))
  ;
  ; int_gbit2 = CONVOL(int_gbit, savgolFilter, /EDGE_TRUNCATE)
  ;
  ; plot, int_gbit2 * 1d6 / res, /ylog, yrange = [0.1,1000.], psym = 6
  ;
  ; stop
  ;
  ; endif

  options, '*fsw_rec_alloc*', 'xticklen', 1
  options, '*fsw_rec_alloc*', 'yticklen', 1
  options, '*fsw_rec_alloc*', 'xgridstyle', 1
  options, '*fsw_rec_alloc*', 'ygridstyle', 1
end