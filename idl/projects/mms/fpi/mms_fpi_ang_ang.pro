;+
; PROCEDURE:
;         mms_fpi_ang_ang
;
; PURPOSE:
;         Creates various plots directly from the
;         FPI distribution functions, including:
;
;         - angle-angle (azimuth vs zenith)
;         - angle-energy (azimuth and zenith vs energy)
;         - pitch angle - energy
;
; INPUT:
;          time: exact time you'd like to see plotted
;
; KEYWORDS:
;          all_energies: generate azimuth vs zenith plots at
;              all energies, one plot for each energy
;
;          probe: probe to plot
;          energy_range: energy range to include in the
;              angle-angle and angle-energy plots (default: 10-30000 eV)
;          data_rate: FPI data rate ('fast' or 'brst')
;          species: FPI species - 'e' for electrons or 'i' for ions (defaults to 'e')
;          subtract_bulk: subtract the bulk velocity prior to 
;              creating the PA-energy figure
;          pa_en_units: units for the PA-energy figure (defaults to 'df_cm')
;          postscript: save the plots as postscript files (can't be set with /png)
;          png: save the plots as PNG files (can't be set with /postscript)
;          center_measurement: shift the data to the center of the 
;              measurement interval
;          xsize: x-size of the figures (default: 550px)
;          ysize: y-size of the figures (default: 450px)
;          filename_suffix: suffix to append to the end of PNG/postscript file names
;          nocontours: disable pitch angle contours on the angle-angle plots
;
; NOTES:
;          Bulk velocity subtraction (via the /subtract_bulk keyword) only 
;          works for PA-energy figures (i.e., angle-angle and angle-energy plots
;          are created as the data exists in the data files)
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-09-17 12:04:17 -0700 (Tue, 17 Sep 2019) $
;$LastChangedRevision: 27764 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_ang_ang.pro $
;-

pro mms_fpi_ang_ang, time, probe=probe, energy_range=energy_range, data_rate=data_rate, $
  species=species, all_energies=all_energies, subtract_bulk=subtract_bulk, pa_en_units = pa_en_units, $
  postscript=postscript, png=png, center_measurement=center_measurement, xsize=xsize, ysize=ysize, $
  filename_suffix = filename_suffix, zrange=zrange, fgm_level=fgm_level, fgm_instrument=fgm_instrument, $
  fgm_data_rate=fgm_data_rate, level=level, nocontours=nocontours

  if undefined(time) then begin
    time = gettime(key='Enter time: ')
    trange = time_double(time) + [-300., 300]
  endif else trange = time_double(time) + [-300., 300]
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  if undefined(species) then species = 'e'
  if undefined(xsize) then xsize = 550
  if undefined(ysize) then ysize = 450
  if undefined(energy_range) then energy_range = [10., 30000] ; eV
  if undefined(data_rate) then data_rate = 'fast'
  if undefined(filename_suffix) then filename_suffix = ''
  if undefined(pa_en_units) then pa_en_units = 'df_cm'
  if undefined(fgm_level) then fgm_level = 'l2'
  if undefined(fgm_instrument) then fgm_instrument='fgm'
  if undefined(fgm_data_rate) and data_rate eq 'brst' then fgm_data_rate='brst' else fgm_data_rate='srvy'
  pa_en_units_str = spd_units_string(pa_en_units)
  
  if ~undefined(postscript) and ~undefined(png) then begin
    dprint, dlevel = 0, 'Error, both PNG and POSTSCRIPT output requested, but can only do one at a time; defaulting to postscript'
    undefine, png
  endif
  
  if ~undefined(zrange) then begin
    if zrange[1] lt zrange[0] then begin
      dprint, dlevel = 0, 'Error, zrange must be in the form [min, max]'
      return
    endif
  endif

  if energy_range[1] lt energy_range[0] then begin
    dprint, dlevel = 0, 'Error, energy range must be in the form [min_energy, max_energy]'
    return
  endif
  
  if ~array_contains(['i', 'e'], species) then begin
    dprint, dlevel = 0, "Error, invalid species specified; valid options are: 'i' (for ions) or 'e' (for electrons)"
    return
  endif
  
  if ~array_contains(['fast', 'brst'], data_rate) then begin
    dprint, dlevel = 0, "Error, invalid data_rate specified; valid options are: 'fast' or 'brst'"
    return
  endif
  
  mms_load_fpi, datatype=['d'+species+'s-dist', 'd'+species+'s-moms'], level=level, data_rate=data_rate, trange=trange, probe=probe, center_measurement=center_measurement, tplotnames=tplotnames
  
  if undefined(tplotnames) then begin
    dprint, dlevel = 0, 'No FPI data found in the requested time range: ', time_string(trange, tformat='YYYY-MM-DD/hh:mm:ss.fff')
    return
  endif
  mms_load_fgm, trange=trange, data_rate=fgm_data_rate, probe=probe, level=fgm_level, instrument=fgm_instrument

  get_data, 'mms'+probe+'_d'+species+'s_dist_'+data_rate, data=d, dlimits=dl

  if ~is_struct(d) then begin
    dprint, dlevel = 0, 'Error, no data found.'
    return
  endif

  closest_time = find_nearest_neighbor(d.X, time_double(time))
  closest_idx = where(d.X eq closest_time)
  closest_idx = closest_idx-1
  
  ; use the time from the data for the trange, to avoid different times 
  ; for angle-angle, angle-energy, and PA-energy figures
  trange_pad = time_double(closest_time)+[0., 0.2]

  data = reform(d.Y[closest_idx, *, *, *])
  phi = reform(d.V1[closest_idx, *])
  theta = d.V2
  energies = reform(d.V3[closest_idx, *])
  energy_axis = minmax(energies)

  idx_of_ens = where(energies ge energy_range[0] and energies le energy_range[1])
  energies = energies[idx_of_ens]
  data_at_ens = data[*, *, idx_of_ens]
  data_summed = total(data_at_ens, 3, /nan)

  distptr = mms_get_dist('mms'+probe+'_d'+species+'s_dist_'+data_rate, single_time=time)
  disterrptr = mms_get_dist('mms'+probe+'_d'+species+'s_disterr_'+data_rate, single_time=time)

  if ~ptr_valid(distptr) then begin
    dprint, dlevel = 4, 'Error, no data found for this time: '+time_string(time)
    return
  endif
  
  dist = *distptr
  ; theta is stored as co-latitude
  theta_colat = reform(dist.theta[0, 0, *])

  ; convert to latitude
  theta_flow_direction = 90-theta_colat
  phi = reform(dist.phi[0, *, 0])

  if undefined(all_energies) then begin
    if ~undefined(postscript) then popen, 'azimuth_vs_zenith'+filename_suffix, /landscape else window, 1, xsize=xsize, ysize=ysize
    
    if fgm_instrument eq 'dfg' and fgm_level eq 'l2pre' then begin
      if tnames('mms'+probe+'_dfg_'+fgm_data_rate+'_l2pre_gse_bvec') ne '' then b_field = 'mms'+probe+'_dfg_'+fgm_data_rate+'_l2pre_gse_bvec' else b_field = 'mms'+probe+'_dfg_b_gse_'+fgm_data_rate+'_l2pre_bvec'
    endif else b_field = 'mms'+probe+'_fgm_b_gse_'+fgm_data_rate+'_'+fgm_level+'_bvec'

    if ~undefined(subtract_bulk) then $
      pad = moka_mms_pad_fpi(*distptr, *disterrptr, time=closest_time, mag_data=b_field, vel_data='mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate, subtract_bulk=subtract_bulk, units=pa_en_units) $
    else $
      pad = moka_mms_pad_fpi(*distptr, *disterrptr, time=closest_time, subtract_bulk=0, units=pa_en_units, mag_data=b_field)

    ; angle-angle over the energy range
    plotxyz, window=1, phi, theta_flow_direction, data_summed, /zlog, /noisotropic, xrange=[0, 360], yrange=[0, 180], zrange=zrange, xsize=xsize, ysize=ysize, $
      xtitle='Az flow angle (deg)', $
      ytitle='Zenith flow angle (deg)', $
      ztitle='f (s!U3!N/cm!U6!N)', $
      title=time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff')+' (' + strcompress(string(energy_range[0]) + '-'+string(energy_range[1]), /rem)+ ' eV)'
      
    if undefined(nocontours) then begin
      num_levels = 16
      contourLevels = 180*indgen(num_levels+1)/num_levels
      c_levels_str = strcompress(string(contourLevels), /rem)
      contour, transpose(pad.pa_azpol, [1, 0]), pad.wpol, pad.waz,YSTYLE=1,  xstyle=1, xmargin=2, ymargin=[7, 2], xrange=[0, 360], yrange=[0, 180], Levels=contourLevels,C_Colors=0, /overplot, c_labels=c_levels_str, c_charsize=1
    endif
    if ~undefined(png) then makepng, 'azimuth_vs_zenith'+filename_suffix
    if ~undefined(postscript) then pclose

    if ~undefined(postscript) then popen, 'zenith_vs_energy'+filename_suffix, /landscape else window, 2, xsize=xsize, ysize=ysize
    theta_en = total(data_at_ens, 1)

    ; Zenith vs. energy
    plotxyz, window=2, energies, theta_flow_direction, transpose(theta_en), /noisotropic, /zlog, xsize=xsize, ysize=ysize, $
      xtitle='Energy (eV)', $
      ytitle='Zenith flow angle (deg)', $
      ztitle='f (s!U3!N/cm!U6!N)', $
      title=time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff'), $
      /xlog, xrange=energy_axis, yrange=[0, 180.], zrange=zrange, yticks=6
    if ~undefined(png) then makepng, 'zenith_vs_energy'+filename_suffix
    if ~undefined(postscript) then pclose

    if ~undefined(postscript) then popen, 'azimuth_vs_energy'+filename_suffix, /landscape else window, 3, xsize=xsize, ysize=ysize
    phi_en = total(data_at_ens, 2)
    ; Azimuth vs. energy
    plotxyz, window=3, energies, phi, transpose(phi_en), /noisotropic, /zlog, xsize=xsize, ysize=ysize, $
      xtitle='Energy (eV)', $
      ytitle='Azimuth flow angle (deg)', $
      ztitle='f (s!U3!N/cm!U6!N)', $
      title=time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff'), $
      /xlog, xrange=energy_axis, yrange=[0, 360.], zrange=zrange, yticks=6
    if ~undefined(png) then makepng, 'azimuth_vs_energy'+filename_suffix
    if ~undefined(postscript) then pclose

    if ~undefined(postscript) then popen, 'pad_vs_energy'+filename_suffix, /landscape else window, 4, xsize=xsize, ysize=ysize

    paendata = transpose(pad.DATA)
    ; apply energy ranges for PAD vs. energy plot
    lowerens = where(pad.EGY lt energy_range[0])
    higherens = where(pad.EGY gt energy_range[1])
    if lowerens[0] ne -1 then paendata[*, lowerens] = !values.d_nan
    if higherens[0] ne -1 then paendata[*, higherens] = !values.d_nan

    plotxyz, pad.PA, pad.EGY, paendata, /noisotropic, /ylog, /zlog, title=time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff'), $
      xrange=[0,180], zrange=zrange, xtitle='Pitch angle (deg)', ytitle='Energy (eV)', ztitle=pa_en_units_str, window=4, xsize=xsize, ysize=ysize

    if ~undefined(png) then makepng, 'pad_vs_energy'+filename_suffix
    if ~undefined(postscript) then pclose
    
  endif else if keyword_set(all_energies) then begin
    for en_idx=0, n_elements(idx_of_ens)-1 do begin
      if ~undefined(postscript) then popen, 'azimuth_vs_zenith_'+strcompress(string(energies[idx_of_ens[en_idx]]), /rem)+filename_suffix, /landscape else window, en_idx, xsize=xsize, ysize=ysize
      data_at_this_en = reform(data[*, *, idx_of_ens[en_idx]])
      plotxyz, window=en_idx, phi, theta_flow_direction, data_at_this_en, /zlog, /noisotropic, xrange=[0, 360], yrange=[0, 180], zrange=zrange, xsize=xsize, ysize=ysize, $
        xtitle='Az flow angle (deg)', $
        ytitle='Zenith flow angle (deg)', $
        ztitle='f (s!U3!N/cm!U6!N)', $
        title=time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff') + ' (' + strcompress(string(energies[idx_of_ens[en_idx]]), /rem) + ' eV)'
      makepng, 'azimuth_vs_zenith_'+strcompress(string(energies[idx_of_ens[en_idx]]), /rem)+filename_suffix
    endfor
  endif

end

