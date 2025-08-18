pro spp_fld_sc_hk_1df_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_sc_hk_1df_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  mags = ['spp_fld_sc_hk_1df_FIELDS1_MAGO_ACTION', $
    'spp_fld_sc_hk_1df_FIELDS2_MAGI_ACTION']

  foreach mag, mags do begin

    get_data, mag, data = d

    if size(/type, d) EQ 8 then begin

      mag_comp = long(d.y)

      exp_mod = 2l^7
      exp_div = 2l^4

      ; Calculate the sign, exponent, and mantissa from the input

      sgn = ((mag_comp/exp_mod GE 1ll) * (-2)) + 1
      exp = (mag_comp MOD exp_mod) / exp_div

      exp0 = where(exp EQ 0, exp0_count, comp = exp_no0, ncomp = exp_no0_count)

      man = mag_comp MOD exp_div

      if exp_no0_count GT 0 then man[exp_no0] += exp_div
      if exp_no0_count GT 0 then exp[exp_no0] -= 1

      mag_decomp = sgn * man * 2l^(exp)

      store_data, mag + '_decompressed', $
        dat = {x:d.x, y:mag_decomp}

    end

  endforeach

  sc_hk_1df_names = tnames(prefix + '*')

  if sc_hk_1df_names[0] NE '' then begin

    for i = 0, n_elements(sc_hk_1df_names) - 1 do begin

      name = sc_hk_1df_names[i]

      ytitle = name

      ytitle = ytitle.Remove(0, prefix.Strlen()-1)

      ytitle = ytitle.Replace('_','!C')

      options, name, 'ynozero', 1
      options, name, 'colors', [2]
      options, name, 'ytitle', ytitle

      options, name, 'psym_lim', 200
      options, name, 'symsize', 0.5

    endfor

  endif




  get_data, prefix + 'sc_hk_subseconds', data = d_hk_ss

end