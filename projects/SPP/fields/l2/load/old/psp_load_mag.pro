pro psp_load_mag, files = files

  if n_elements(files) GT 0 then begin

    cdf2tplot, files, prefix = 'psp_fld_mag_', verbose=4, /get_support

    options, 'psp_fld_mag_B_SC', 'colors', 'rgb'
    options, 'psp_fld_mag_B_SC', 'labels', ['X','Y','Z']
    options, 'psp_fld_mag_B_SC', 'max_points', 10000

    options, 'psp_fld_mag_B_RTN', 'colors', 'rgb'
    options, 'psp_fld_mag_B_RTN', 'labels', ['R','T','N']
    options, 'psp_fld_mag_B_RTN', 'max_points', 10000

    ;tplot, 'psp_fld_mag_B_SC'

    options, 'psp_fld_mag_B_SC', 'max_points', 10000
    options, 'psp_fld_mag_B_RTN', 'max_points', 10000

    ;tplot, 'psp_fld_mag_B_SC'

  end

end