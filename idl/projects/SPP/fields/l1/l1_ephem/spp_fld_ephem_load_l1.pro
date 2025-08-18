pro spp_fld_ephem_load_l1, file, prefix = prefix, varformat = varformat

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  frame = strjoin((strsplit(/ex, prefix, '_'))[3:*],'_')

  rs = 695508d
  re = 6371d
  rv = 6052d
  rm = 2440d

  ;  options, prefix + 'position', 'colors', 'bgr'

  get_data, prefix + 'position', data = pos_dat
  get_data, prefix + 'velocity', data = vel_dat

  store_data, prefix + 'position_rs', $
    data = {x:pos_dat.x, y:pos_dat.y/rs}

  options, prefix + 'position_rs', 'ysubtitle', '[Rs]'

  options, prefix + 'reconstructed', 'yrange', [-0.2,1.2]
  options, prefix + 'reconstructed', 'ystyle', 1
  options, prefix + 'reconstructed', 'yticks', 1
  options, prefix + 'reconstructed', 'ytickv', [0,1]
  options, prefix + 'reconstructed', 'colors', 6

  if frame EQ 'spp_rtn' or frame EQ 'spp_hertn' or frame EQ 'solo_rtn' then begin

    store_data, prefix + 'radial_distance', $
      data = {x:pos_dat.x, y:total(pos_dat.y,2)}

    store_data, prefix + 'radial_distance_rs', $
      data = {x:pos_dat.x, y:total(pos_dat.y,2)/rs}

    options, '*radial_distance*', 'ynozero', 1

    store_data, prefix + 'radial_velocity', $
      data = {x:vel_dat.x, y:total(vel_dat.y,2)}

    options, prefix + 'radial_distance', 'ysubtitle', '[km]'
    options, prefix + 'radial_velocity', 'ysubtitle', '[km/s]'
    options, prefix + 'radial_distance_rs', 'ysubtitle', '[Rs]'

    store_data, prefix + 'radial_distance_label', $
      data = {x:pos_dat.x, y:total(pos_dat.y,2)/rs}

    options, prefix + 'radial_distance_label', 'ytitle', 'Rad. Dist. [Rs]'

  endif

  if frame EQ 'spp_vso' or frame EQ 'solo_vso' then begin

    store_data, prefix + 'position_rv', $
      data = {x:pos_dat.x, y:pos_dat.y/rv}

    store_data, prefix + 'radial_distance', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))}

    store_data, prefix + 'radial_distance_rv', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))/rv}

    options, '*radial_distance*', 'ynozero', 1
    options, prefix + 'position_rv', 'ysubtitle', '[Rv]'
    options, prefix + 'radial_distance', 'ysubtitle', '[km]'
    options, prefix + 'radial_distance_rv', 'ysubtitle', '[Rv]'

  endif

  if frame EQ 'spp_mso' then begin

    store_data, prefix + 'position_rm', $
      data = {x:pos_dat.x, y:pos_dat.y/rv}

    store_data, prefix + 'radial_distance', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))}

    store_data, prefix + 'radial_distance_rm', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))/rv}

    options, '*radial_distance*', 'ynozero', 1
    options, prefix + 'position_rm', 'ysubtitle', '[Rm]'
    options, prefix + 'radial_distance', 'ysubtitle', '[km]'
    options, prefix + 'radial_distance_rm', 'ysubtitle', '[Rm]'

  endif

  if frame EQ 'spp_gse' then begin

    store_data, prefix + 'position_re', $
      data = {x:pos_dat.x, y:pos_dat.y/rv}

    store_data, prefix + 'radial_distance', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))}

    store_data, prefix + 'radial_distance_re', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))/rv}

    options, '*radial_distance*', 'ynozero', 1
    options, prefix + 'position_re', 'ysubtitle', '[Re]'
    options, prefix + 'radial_distance', 'ysubtitle', '[km]'
    options, prefix + 'radial_distance_re', 'ysubtitle', '[Re]'

  endif

  if (tnames('*vector*'))[0] NE '' then begin

    options, prefix + '*vector*', 'ysubtitle', ''

    options, prefix + '*vector*', 'yrange', [-1.0,1.0]
    options, prefix + '*vector*', 'ystyle', 1
    options, prefix + '*vector*', 'yticklen', 1
    options, prefix + '*vector*', 'ygridstyle', 1

  endif

  ephem_names = tnames(prefix + '*')

  if ephem_names[0] NE '' then begin

    if (frame EQ 'spp_rtn' or frame EQ 'spp_hertn') then $
      labels = ['R', 'T', 'N'] else labels = ['X', 'Y', 'Z']

    foreach name, ephem_names do begin

      name_no_prefix = name.Remove(0, prefix.Strlen()-1)

      rs_strpos = strpos(name_no_prefix, '_rs')

      if rs_strpos GT 0 then name_no_prefix = strmid(name_no_prefix,0,rs_strpos)

      get_data, name, data = d

      if size(/type, d) EQ 8 then begin

        ndims = size(d.y, /n_dimensions)
        dims = size(d.y, /dimensions)

        if ndims EQ 2 then begin
          if dims[1] EQ 3 then begin
            options, name, 'colors', 'bgr'

            options, name, 'labels', labels

            if strpos(name, 'vector') NE -1 then begin

              options, name, 'labels', 'SC' + $
                strupcase(strmid(name_no_prefix, 3, 1)) + '-' + labels

            endif

          endif
        endif

        options, name, 'ynozero', 1

        if strpos(name, '_label') LT 0 then begin

          options, name, 'ytitle', $
            'PSP!C' + strupcase(frame) + '!C' + name_no_prefix

        end

        if n_elements(d.x) GT 1 then begin
          options, name, 'psym_lim', 100
          ; don't set data gap for the full orbit plots
          if d.x[-1] - d.x[0] LT 1200d then options, name, 'datagap', 600d
        endif

        options, name, 'symsize', 0.75

      end

    endforeach

  endif

  ; Calculate tangential velocity

  if frame EQ 'eclipj2000' or frame EQ 'spp_hg' or frame EQ 'solo_hg' then begin

    n_points = n_elements(pos_dat.x)

    v_uv0 = vel_dat.y

    r_uv0 = pos_dat.y

    ; two approaches here for defining the n unit vector.  First approach
    ; is to simply let the n vector be in the ecliptic (for eclipj2000) or
    ; the solar rotation axis (spp_hg).  This ignores motion out of this plane
    ; in the calculation (usually a decent approximation for PSP)

    n_uv0 = [[dblarr(n_points)], [dblarr(n_points)], [dblarr(n_points) + 1d]]

    ; we could also define the n vector as being the cross of the r vector
    ; and the v vector - so, essentially using a vector normal to the orbital
    ; plane of PSP.  This works well except when we use a co-rotating frame -
    ; when we transition to super-rotational velocities in such a frame the
    ; 'orbital plane' becomes ill defined.

    ;    n_uv0 = [[r_uv0[*,1] * v_uv0[*,2] - r_uv0[*,2] * v_uv0[*,1]], $
    ;      [r_uv0[*,2] * v_uv0[*,0] - r_uv0[*,0] * v_uv0[*,2]], $
    ;      [r_uv0[*,0] * v_uv0[*,1] - r_uv0[*,1] * v_uv0[*,0]]]
    ;
    ;    n_uv0_negative = where(n_uv0[*,2] LT 0, n_uv0_negative_count)
    ;
    ;    if n_uv0_negative_count GT 0 then $
    ;      n_uv0[n_uv0_negative,*] *= -1

    t_uv0 = -[[r_uv0[*,1] * n_uv0[*,2] - r_uv0[*,2] * n_uv0[*,1]], $
      [r_uv0[*,2] * n_uv0[*,0] - r_uv0[*,0] * n_uv0[*,2]], $
      [r_uv0[*,0] * n_uv0[*,1] - r_uv0[*,1] * n_uv0[*,0]]]

    r_mag = sqrt(total(r_uv0^2, 2))
    t_mag = sqrt(total(t_uv0^2, 2))
    n_mag = sqrt(total(n_uv0^2, 2))

    r_uv = r_uv0 / [[r_mag],[r_mag],[r_mag]]
    t_uv = t_uv0 / [[t_mag],[t_mag],[t_mag]]
    n_uv = n_uv0 / [[n_mag],[n_mag],[n_mag]]

    store_data, prefix + 'tangential_velocity', $
      data = {x:pos_dat.x, y:total(v_uv0 * t_uv,2)}

    options, prefix + 'tangential_velocity', 'ysubtitle', '[km/s]'

  endif

  ;stop

end