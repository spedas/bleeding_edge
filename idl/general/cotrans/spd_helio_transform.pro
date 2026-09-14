;+
;procedure: spd_helio_transform_array
;Purpose: numerical core for the dedicated geocentric/heliocentric routines.
;-
pro spd_helio_transform_array, time, vectors, output, system, INVERSE=inverse, $
  POSITION=position
  compile_opt idl2

  need_epv = keyword_set(position) || strlowcase(system) eq 'heeq'
  if need_epv then begin
    spd_epv00, time, earth, earth_velocity, status=epv_status
    ; SPEDAS state positions conventionally use km; EPV00 returns AU.
    earth *= 149597870.7d
    if total(epv_status) gt 0 then $
      dprint, 'WARNING: EPV00 date outside its nominal 1900-2100 range.'
  endif

  case strlowcase(system) of
    'hee': begin
      output = vectors
      output[*,0] = -vectors[*,0]
      output[*,1] = -vectors[*,1]
      output[*,2] =  vectors[*,2]
      if keyword_set(position) then begin
        distance = sqrt(total(earth^2, 2))
        output[*,0] = distance-vectors[*,0]
      endif
    end

    'hae': begin
      ; The EPV00 orientation matrix maps its dynamical J2000 ecliptic model
      ; into BCRS.  Its transpose therefore supplies a consistent HAE basis.
      if keyword_set(inverse) then begin
        absolute = vectors
        bx = vectors[*,0] + 0.000000211284d*vectors[*,1] - $
          0.000000091603d*vectors[*,2]
        by = -0.000000230286d*vectors[*,0] + 0.917482137087d*vectors[*,1] - $
          0.397776982902d*vectors[*,2]
        bz = 0.397776982902d*vectors[*,1] + 0.917482137087d*vectors[*,2]
        absolute = [[bx], [by], [bz]]
        if keyword_set(position) then absolute -= earth
        subJ20002GEI, time, absolute, output
      endif else begin
        subGEI2J2000, time, vectors, relative
        if keyword_set(position) then relative += earth
        output = relative
        output[*,0] = relative[*,0] - 0.000000230286d*relative[*,1]
        output[*,1] = 0.000000211284d*relative[*,0] + $
          0.917482137087d*relative[*,1] + 0.397776982902d*relative[*,2]
        output[*,2] = -0.000000091603d*relative[*,0] - $
          0.397776982902d*relative[*,1] + 0.917482137087d*relative[*,2]
      endelse
    end

    'heeq': begin
      n = n_elements(time)
      ehat = earth
      enorm = sqrt(total(earth^2, 2))
      ehat[*,0] /= enorm
      ehat[*,1] /= enorm
      ehat[*,2] /= enorm
      ra_p = 286.13d*!dpi/180d
      dec_p = 63.87d*!dpi/180d
      pole = dblarr(n,3)
      pole[*,0] = cos(ra_p)*cos(dec_p)
      pole[*,1] = sin(ra_p)*cos(dec_p)
      pole[*,2] = sin(dec_p)

      ; Reproduce the cotrans GSEQ basis, then express it in J2000/BCRS.
      ts = time_struct(time)
      csundir_vect, ts.year, ts.doy, ts.hour, ts.min, $
        double(ts.sec)+ts.fsec, gst, slong, sra, sdec, obliq
      gx_gei = [[cos(sra)*cos(sdec)], [sin(sra)*cos(sdec)], [sin(sdec)]]
      subJ20002GEI, time, pole, pole_gei
      gy_gei = dblarr(n,3)
      gy_gei[*,0] = pole_gei[*,1]*gx_gei[*,2] - pole_gei[*,2]*gx_gei[*,1]
      gy_gei[*,1] = pole_gei[*,2]*gx_gei[*,0] - pole_gei[*,0]*gx_gei[*,2]
      gy_gei[*,2] = pole_gei[*,0]*gx_gei[*,1] - pole_gei[*,1]*gx_gei[*,0]
      gnorm = sqrt(total(gy_gei^2,2))
      gy_gei[*,0] /= gnorm
      gy_gei[*,1] /= gnorm
      gy_gei[*,2] /= gnorm
      gz_gei = dblarr(n,3)
      gz_gei[*,0] = gx_gei[*,1]*gy_gei[*,2] - gx_gei[*,2]*gy_gei[*,1]
      gz_gei[*,1] = gx_gei[*,2]*gy_gei[*,0] - gx_gei[*,0]*gy_gei[*,2]
      gz_gei[*,2] = gx_gei[*,0]*gy_gei[*,1] - gx_gei[*,1]*gy_gei[*,0]
      subGEI2J2000, time, gx_gei, gx
      subGEI2J2000, time, gy_gei, gy
      subGEI2J2000, time, gz_gei, gz
      gnorm = sqrt(total(gy^2,2))
      gy[*,0] /= gnorm
      gy[*,1] /= gnorm
      gy[*,2] /= gnorm
      gz = dblarr(n,3)
      gz[*,0] = gx[*,1]*gy[*,2] - gx[*,2]*gy[*,1]
      gz[*,1] = gx[*,2]*gy[*,0] - gx[*,0]*gy[*,2]
      gz[*,2] = gx[*,0]*gy[*,1] - gx[*,1]*gy[*,0]

      ; HEEQ basis: Z is solar north and X is the Earth direction projected
      ; into the solar equatorial plane.
      edotp = total(ehat*pole,2)
      hx = ehat
      hx[*,0] -= edotp*pole[*,0]
      hx[*,1] -= edotp*pole[*,1]
      hx[*,2] -= edotp*pole[*,2]
      hnorm = sqrt(total(hx^2,2))
      hx[*,0] /= hnorm
      hx[*,1] /= hnorm
      hx[*,2] /= hnorm
      hz = pole
      hy = dblarr(n,3)
      hy[*,0] = hz[*,1]*hx[*,2] - hz[*,2]*hx[*,1]
      hy[*,1] = hz[*,2]*hx[*,0] - hz[*,0]*hx[*,2]
      hy[*,2] = hz[*,0]*hx[*,1] - hz[*,1]*hx[*,0]

      if keyword_set(inverse) then begin
        absolute = hx
        absolute[*,0] = vectors[*,0]*hx[*,0] + vectors[*,1]*hy[*,0] + $
          vectors[*,2]*hz[*,0]
        absolute[*,1] = vectors[*,0]*hx[*,1] + vectors[*,1]*hy[*,1] + $
          vectors[*,2]*hz[*,1]
        absolute[*,2] = vectors[*,0]*hx[*,2] + vectors[*,1]*hy[*,2] + $
          vectors[*,2]*hz[*,2]
        if keyword_set(position) then absolute -= earth
        output = [[total(absolute*gx,2)], [total(absolute*gy,2)], $
          [total(absolute*gz,2)]]
      endif else begin
        relative = gx
        relative[*,0] = vectors[*,0]*gx[*,0] + vectors[*,1]*gy[*,0] + $
          vectors[*,2]*gz[*,0]
        relative[*,1] = vectors[*,0]*gx[*,1] + vectors[*,1]*gy[*,1] + $
          vectors[*,2]*gz[*,1]
        relative[*,2] = vectors[*,0]*gx[*,2] + vectors[*,1]*gy[*,2] + $
          vectors[*,2]*gz[*,2]
        if keyword_set(position) then relative += earth
        output = [[total(relative*hx,2)], [total(relative*hy,2)], $
          [total(relative*hz,2)]]
      endelse
    end

    else: message, 'Unknown heliocentric coordinate system: '+system
  endcase
end


;+
;procedure: spd_helio_transform
;Purpose: shared tplot/array handling for dedicated heliocentric transforms.
;-
pro spd_helio_transform, name_in, name_out, system, geo_coord, $
  INVERSE=inverse, POSITION=position, ROTATION_ONLY=rotation_only, $
  IGNORE_DLIMITS=ignore_dlimits
  compile_opt idl2

  if n_params() ne 4 then message, 'Internal error: invalid spd_helio_transform call.'
  helio_coord = strlowcase(system)
  input_coord = keyword_set(inverse) ? helio_coord : strlowcase(geo_coord)
  output_coord = keyword_set(inverse) ? strlowcase(geo_coord) : helio_coord
  is_tplot = size(name_in, /type) eq 7

  if is_tplot then begin
    get_data, name_in, data=data_in, dlimits=dl_in, limits=l_in
    if ~is_struct(data_in) then message, 'Input tplot variable not found: '+name_in
    coord = cotrans_get_coord(dl_in)
    if ~keyword_set(ignore_dlimits) && coord ne 'unknown' && coord ne input_coord then $
      message, 'Input coordinate system must be '+strupcase(input_coord)+'.'

    st_type = ''
    str_element, dl_in, 'data_att.st_type', st_type
    translate = strlowcase(st_type) eq 'pos'
    if keyword_set(rotation_only) then translate=0
    spd_helio_transform_array, data_in.x, data_in.y, transformed, system, $
      INVERSE=inverse, POSITION=translate
    data_out = data_in
    data_out.y = transformed
    dl_out = dl_in
    cotrans_set_coord, dl_out, output_coord
    str_element, dl_out, 'ytitle', /delete
    str_element, l_in, 'ytitle', /delete
    store_data, name_out, data=data_out, dlimits=dl_out, limits=l_in
  endif else begin
    dims = size(name_in, /dimensions)
    if n_elements(dims) ne 2 || dims[1] ne 4 then $
      message, 'Array input must have dimensions [n,4]: time,x,y,z.'
    translate = keyword_set(position) && ~keyword_set(rotation_only)
    spd_helio_transform_array, name_in[*,0], name_in[*,1:3], transformed, $
      system, INVERSE=inverse, POSITION=translate
    name_out = name_in
    name_out[*,1:3] = transformed
  endelse
end
