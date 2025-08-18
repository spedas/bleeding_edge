pro erg_part_en_pa_spec_plot, $
   dists, $                     ; 3-D distribution structure
   time=time, $                 ; a single time or time range in decimal unix time
   units=units, $               ; physical unit to which the given flux data are converted 
   with_contour=with_contour, $ ; draw contours with black solid curves
   zrange=zrange, $             ; the lower/upper limit for the flux map
   npabin=npabin, $             ; # of PA bins (default: 19)
   rslt=rslt, $                 ; if set, the resultant PA-energy-binned flux is given
   noplot=noplot, $             ; Set to suppress plotting
   transposed_plot=transposed_plot, $ ; Set to draw an energy v.s. PA plot
   fac_type=fac_type, $               ; type of the FA coordinates (default: mphism)
   debug=debug


  if undefined(debug) then debug = 0
  if ~is_struct(dists) then return

  if undefined(npabin) then npabin = 19
  if undefined(fac_type) then factype = 'mphism' else factype = fac_type
  
  ;; Load the necessary data
  if tnames('erg_mgf_l2_mag_8sec_dsi') eq '' then erg_load_mgf
  if tnames('erg_orb_l2_pos_gse') eq '' then erg_load_orb 

  
  if undefined(time) then time = mean( dists.time )
  
  if n_elements(time) eq 1 then begin
    ts = time_double(time) & te = ts
    id = nn2( dists.time, time )
  endif else begin
    ts = time_double(time[0]) & te = time_double(time[1])
    id = where( dists.time ge ts and dists.time lt te, nid )
    if nid eq 0 then begin
      dprint, 'No data is included in the given time range!'
      return
    endif
  endelse

  dist_fac = dists[ id ]
  trange = minmax( dist_fac.time )

  ;; Convert to the given unit
  if keyword_set(units) then begin
    supported_unit_names = [ 'flux', 'eflux', 'df', 'df_km', 'psd', 'df_cm' ]
    unit_name = ssl_check_valid_name( units[0], supported_unit_names, /no_warning )
    if unit_name ne '' then begin
      for i=0L, n_elements(dist_fac)-1 do begin
        erg_convert_flux_units, dist_fac[i], units=unit_name, output=tmp
        dist_fac[i] = temporary( tmp )
      endfor
    endif
  endif
  
  ;; Convert to the magnetic coordinates
  erg_pgs_make_fac, dist_fac.time, 'erg_mgf_l2_mag_8sec_dsi', 'erg_orb_l2_pos_gse', $
                    fac_output=fac_mat, fac_type=factype
  for i=0L, n_elements(dist_fac.time)-1 do begin
    spd_pgs_do_fac, dist_fac[i], reform( fac_mat[i, *, *], [3, 3] ), $
                    output=dist_tmp,   error=error
    dist_fac[i] = dist_tmp
  endfor

  if debug then dprint, minmax(dist_fac.theta)
  dist_fac.theta = 90. - dist_fac.theta  ;; colat. in FAC = pitch angle

  ;; Prepare data arrays for a selected energy channel
  if ndimen( dist_fac[0].data ) eq 3 then begin ;; for LEPs, MEPs, and HEP
    pa_arr = reform( dist_fac.theta[ *, *, * ] )
    en_arr = reform( dist_fac.energy[ *, *, *] ) 
    log_en_arr = alog10( reform( dist_fac.energy[ *, *, *] ) )
    dat_arr = reform( dist_fac.data[ *, *, *] )
  endif else if ndimen( dist_fac[0].data ) eq 2 then begin ;; only for XEP
    pa_arr = reform( dist_fac.theta[ *, * ] )
    en_arr = reform( dist_fac.energy[ *, * ] ) 
    log_en_arr = alog10( reform( dist_fac.energy[ *, * ] ) )
    dat_arr = reform( dist_fac.data[ *, * ] )
  endif
  
  en_list = spd_uniq( en_arr )
  id = where( finite(en_list), nid ) & en_levels = en_list[id]
  en_ids = value_locate( en_levels-0.1, en_arr )

  if debug then help, en_levels, en_ids
  if debug then help, pa_arr,  log_en_arr, dat_arr
  
  ;; Use a generic routine "bin2d" to calculate average fluxes for the energy x pitch-angle bins
  id = where( finite(dat_arr) and finite(pa_arr) and finite(en_arr) ) ;;To exclude NaN and Inf from the averaging with bin2d
  bin2d, en_ids[id], pa_arr[id], dat_arr[id], $
         xrange=[-0.5, n_elements(en_levels)-0.5], yrange=[0., 180.], binum=[n_elements(en_levels), npabin], $
         xc=en_ids_c, yc=pa_c, ave=aveflux, binhist=binnm 

  id =  where( aveflux lt 0. or binnm eq 0, nid ) & if nid gt 0 then aveflux[id] = !values.f_nan

  ;; Save the resultant arrays
  rslt = { x_energy:en_levels, y_pitchangle:pa_c, z_hist:aveflux }
  
  
  ;; Plot!
  if ~keyword_set(noplot) then begin
    
    tr = minmax( dist_fac.time )
    if n_elements(dist_fac) gt 1 then begin
      title = time_string(tr[0]) + '--' + time_string(tr[1], tfor='hh:mm:ss')
    endif else title = time_string(tr[0])

    ;; For transposed_plot option
    if undefined( transposed_plot ) then begin
      xarr = en_levels & yarr = pa_c
      zarr = aveflux
      yrange = [0., 180.] & ytitle = 'Pitch angle [deg]'
      ytickint = 45 & ylog = 0
      xrange = minmax( en_levels ) & xtitle = 'Energy [eV]'
      xtickint = '' & xlog = 1
    endif else begin
      yarr = en_levels & xarr = pa_c
      zarr = transpose( aveflux )
      xrange = [0., 180.] & xtitle = 'Pitch angle [deg]'
      xtickint = 45 & xlog = 0
      yrange = minmax( en_levels ) & ytitle = 'Energy [eV]'
      ytickint = '' & ylog = 1
    endelse
    
    plotxyz, xarr, yarr, zarr, /noiso, $
             title=title $
             , xtitle=xtitle, ytitle=ytitle $
             , xlog=xlog, ylog=ylog $
             , yrange=yrange, ystyle=1, ytickinterval=ytickint $
             , xrange=xrange, xstyle=1, xtickinterval=xtickint $
             , zlog=1, zticklen=-0.3, ztitle=erg_units_string(dist_fac[0].units_name), zrange=zrange $
             , ztickunits='scientific' $
             , extend_y_edges=1 
    ;; , position:[0.1, 0.1, 0.9, 0.95] $
    foreach palev, [45, 90, 135] do begin
      if undefined(transposed_plot) then oplot, [1., 1e+8], [palev, palev], linestyle=1, color=spd_get_color('black') $
      else oplot, [palev, palev], [1., 1e+8], linestyle=1, color=spd_get_color('black')
    endforeach
    
    if keyword_set(with_contour) then begin
      if defined(zrange) then edges = minmax(alog10(zrange)) else edges = minmax(alog10(zarr))
      levels = ceil(edges[0]) + 0.5*findgen( 2*( floor(edges[1]) - ceil(edges[0]) ) + 1 )
      contour, alog10(zarr), xarr, yarr, /over, xlog=xlog, ylog=ylog, levels=levels
    endif
    
  endif
  
  if debug then dprint, 'minmax(dat_arr): ', minmax(dat_arr)
  if debug then dprint, 'minmax(aveflux): ', minmax(aveflux)
  
  
  
  
  
  
  
  return
end

    

  









  