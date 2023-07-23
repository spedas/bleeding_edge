;+
; Procedure:
;         goesr_overview_plot
;
; Purpose:
;         Generates daily overview plots for GOES-R data (goes16-17)
;
; Keywords:
;         date: start date for the overview plot
;         duration: duration of the overview plot, in days; defaults to 1-day
;         directory: local directory to save the overview plots to (should end with '/' or '\')
;         makepng: generate png files
;         device: change the plot device for cron plotting (for cron use device = 'z')
;         geopack_lshell: calculate L-shell by tracing field lines
;             to the equator instead of using the dipole assumption
;         skip_ae_idx: set this keyword to skip downloading/plotting AE data
;         error: 1 indicates an error, 0 for no error
;
; Keywords specific to creating overview plots in the GUI:
;         gui_overplot: overview plot was created in the GUI
;         oplot_calls: pointer to an int for tracking calls to overview plots - for
;             avoiding overwriting tplot data already loaded during this session
;         import_only: Used to make this routine import the data into the gui, but not plot it.
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2022-03-18 12:52:44 -0700 (Fri, 18 Mar 2022) $
; $LastChangedRevision: 30691 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goesr/goesr_overview_plot.pro $
;-

pro goesr_overview_plot, date = date, probe = probe_in, directory = directory, device = device, makepng=makepng, $
  geopack_lshell = geopack_lshell, duration = duration, gui_overplot = gui_overplot, $
  oplot_calls = oplot_calls, error = error, skip_ae_idx = skip_ae_idx, import_only=import_only, $
  _extra=_extra

  compile_opt idl2

  goesr_init

  ; Catch errors and return
  error = 0
  catch, errstats
  if errstats ne 0 then begin
    error = 1
    dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

  ; Defaults for GOES-R overview plot
  if undefined(probe_in) then probe = '16' else probe=probe_in[0]
  if undefined(date) then overviewdate = '2021-02-01' else overviewdate = time_string(date)
  if undefined(duration) then duration = 1 ; days
  if undefined(oplot_calls) then suffix = '' else suffix = strcompress('_op'+string(oplot_calls[0]), /rem)

  timespan, overviewdate, duration, /day
  time = time_struct(overviewdate)
  tr = timerange(/current)
  prefix = 'goes'+probe

  ; Remove previous data.
  store_data, prefix+'*', /delete

  earth_radius = 6371.
  window_xsize = 750
  window_ysize = 800
  if undefined(directory) then dir = path_sep() + 'g'+probe+path_sep() else dir = directory

  if ~undefined(device) then begin
    set_plot, device
    device, set_resolution = [window_xsize, window_ysize]
  endif

  ;;=============================================================================
  ;; Panel 1: Kyoto and THEMIS AE
  if undefined(skip_ae_idx) then begin
    spd_gen_overplot_ae_panel, suffix=suffix

  endif
  panel_1 = 'kyoto_thm_combined_ae'+suffix

  ;;=============================================================================
  ; Panel 2: bfield, magnetic field components in SM coordinates
  ; Start with GSM field, perform GSM2SM transformation

  goesr_load_data, datatype='mag', probes = probe, suffix = suffix

  magfield = prefix + '_b_gsm' + suffix
  magtotal = prefix + '_b_total' + suffix
  b_field_tvarname = '_H_sm'+suffix
  panel_2 = prefix+b_field_tvarname

  if tnames(magfield) ne '' && tnames(magtotal) ne '' then begin
    ; Perform GSM->SM
    cotrans, magfield, magfield + '_sm' , /GSM2SM

    get_data, magfield + '_sm', dlimits = b_sm_dlimits, data=b_sm_data
    get_data, magtotal, data=b_total_data

    bvec_with_mag = [[b_sm_data.Y], [b_total_data.Y]]
    if is_struct(b_sm_data) && is_struct(b_total_data) then begin
      store_data, panel_2, dlimits = b_sm_dlimits, data={x: b_sm_data.X, y: bvec_with_mag}
    endif else begin
      filler=fltarr(2,4)
      filler[*,*]=float('NaN')
      store_data,panel_2,data={x:time_double(overviewdate)+findgen(2),y:filler}
    endelse
  endif else begin
    filler=fltarr(2,4)
    filler[*,*]=float('NaN')
    store_data,panel_2,data={x:time_double(overviewdate)+findgen(2),y:filler}
  endelse

  ; Plot options
  options, panel_2, 'labels', ['Bx','By','Bz', 'Bmag']
  options, panel_2, 'colors', [2,4,6,0]
  options, panel_2, 'labflag', -1
  options, panel_2, 'ytitle', 'B (SM)'
  options, panel_2, 'ysubtitle', '[nT]'

  ;;=============================================================================
  ; Panel 3: igrf_delta, magnetic field components subtracted from IGRF
  panel_3 = prefix+'_delta_b_sm'+suffix

  ; Load the ephemeris data in GEI coordinates.
  ephem = goes_load_pos(trange = time_string(tr), probe = probe, coord_sys='geij2000')
  if is_struct(ephem) then begin
    ; store the data attributes structure
    data_att = {project: 'GOES', observatory: (strsplit(prefix,'_', /extra))[0], $
      instrument: 'ephem', units: 'km', coord_sys: 'gei', st_type: 'pos'}
    dlimits = {data_att: data_att, colors: [2,4,6], labels: ['x','y','z']+'_gei', ysubtitle: '[km]'}
    store_data, prefix + '_pos_gei' + suffix, data={x: ephem.time, y: ephem.pos_values}, dlimits=dlimits
  endif else begin
    dprint, dlevel=1, 'Error loading ephemeris data. No data returned from goes_load_pos()'
    filler=fltarr(2,3)
    filler[*,*]=float('NaN')
    store_data,prefix + '_pos_gei' + suffix,data={x:time_double(overviewdate)+findgen(2),y:filler}
  endelse

  if tnames(magfield) ne '' && igp_test() eq 1 then begin

    cotrans, prefix+'_pos_gei'+suffix, prefix+'_pos_gse'+suffix, /GEI2GSE
    cotrans, prefix+'_pos_gse'+suffix, prefix+'_pos_gsm'+suffix, /GSE2GSM

    get_data, prefix+'_pos_gsm'+suffix, data=pos_data

    igrf_bx = fltarr(n_elements(pos_data.y[*,0]))
    igrf_by = fltarr(n_elements(pos_data.y[*,1]))
    igrf_bz = fltarr(n_elements(pos_data.y[*,2]))

    ; find the IGRF in GSM for each point
    for i=0, n_elements(pos_data.X)-1 do begin
      timestr = time_struct(pos_data.X[i])
      geopack_recalc, timestr.year, timestr.doy, timestr.hour, timestr.min, timestr.sec, tilt=tilt
      ; input position units should be in Re
      geopack_igrf_gsm, pos_data.Y[i,0]/earth_radius, pos_data.Y[i,1]/earth_radius, pos_data.Y[i,2]/earth_radius, dummy_bx, dummy_by, dummy_bz
      igrf_bx[i] = dummy_bx
      igrf_by[i] = dummy_by
      igrf_bz[i] = dummy_bz
    endfor

    igrf_b_gsm = fltarr(n_elements(pos_data.Y[*,2]),3)
    igrf_b_gsm[*,0] = igrf_bx
    igrf_b_gsm[*,1] = igrf_by
    igrf_b_gsm[*,2] = igrf_bz
    store_data, prefix+'_igrf_b_gsm'+suffix, data={x: pos_data.X, y: igrf_b_gsm}

    ; transform the IGRF to SM coordinates
    cotrans, prefix+'_igrf_b_gsm'+suffix, prefix+'_igrf_b_sm'+suffix, /GSM2SM

    get_data, prefix+'_igrf_b_sm'+suffix, data=igrf_b_sm
    get_data, prefix+'_H_sm'+suffix, data=goes_h_sm

    deltaB = fltarr(n_elements(goes_h_sm.X), 3)
    for i=0l, n_elements(goes_h_sm.X)-1 do begin
      igrf_nearest_neighbor = find_nearest_neighbor(igrf_b_sm.X, goes_h_sm.X[i])
      if igrf_nearest_neighbor ne -1 then begin
        deltaB[i,0] = goes_h_sm.Y[i,0]-igrf_b_sm.Y[where(igrf_b_sm.X eq igrf_nearest_neighbor),0]
        deltaB[i,1] = goes_h_sm.Y[i,1]-igrf_b_sm.Y[where(igrf_b_sm.X eq igrf_nearest_neighbor),1]
        deltaB[i,2] = goes_h_sm.Y[i,2]-igrf_b_sm.Y[where(igrf_b_sm.X eq igrf_nearest_neighbor),2]
      endif else begin
        deltaB[i,0] = !values.f_nan
        deltaB[i,1] = !values.f_nan
        deltaB[i,2] = !values.f_nan
      endelse
    endfor
  endif

  if is_struct(goes_h_sm) && n_elements(deltaB) gt 0 then begin
    store_data, panel_3, data={x: goes_h_sm.X, y: deltaB}, dlimits=b_sm_dlimits
  endif else begin
    filler=fltarr(2,3)
    filler[*,*]=float('NaN')
    store_data,panel_3,data={x:time_double(overviewdate)+findgen(2),y:filler}
  endelse

  ; Plot options
  options, panel_3, 'labels', ['Bx','By','Bz']
  options, panel_3, 'labflag', -1
  options, panel_3, 'colors', [2,4,6]
  options, panel_3, 'ytitle', 'B (SM)-IGRF (SM)'
  options, panel_3, 'ysubtitle', '[nT]'

  ;=============================================================================
  ; Panel 4a, 4b: MPSH, protons, L2 SEISS/MPS-HI - 5-minute Flux Averages
  ; Proton flux, 5 telescopes, 11 energy bands
  ; Show telescopes 1,2 for protons
  goesr_load_data, datatype='mpsh', probes = probe, suffix = suffix

  panel_4a = prefix+'_AvgDiffProtonFlux'+suffix + '_0'
  get_data, panel_4a, data=d
  if ~is_struct(d) then begin
    filler=fltarr(2,11)
    filler[*,*]=float('NaN')
    store_data,panel_4a,data={x:time_double(overviewdate)+findgen(2),y:filler}
  endif
  ; plotting options, panel_4a
  options, /def, panel_4a, 'ylog', 1
  options, /def, panel_4a, 'labels', ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'P9', 'P10', 'P11']
  options, /def, panel_4a, 'labflag', -1
  options, /def, panel_4a, 'ytitle', 'Protons!CNorth T1!C '
  options, /def, panel_4a, 'ysubtitle', ''
  options, /def, panel_4a, 'psym', 0

  panel_4b = prefix+'_AvgDiffProtonFlux'+suffix + '_2'
  get_data, panel_4b, data=d_4b
  if ~is_struct(d_4b) then begin
    filler=fltarr(2,11)
    filler[*,*]=float('NaN')
    store_data,panel_4b,data={x:time_double(overviewdate)+findgen(2),y:filler}
  endif
  ; plotting options, panel_4b
  options, /def, panel_4b, 'ylog', 1
  options, /def, panel_4b, 'labels', ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'P9', 'P10', 'P11']
  options, /def, panel_4b, 'labflag', -1
  options, /def, panel_4b, 'ytitle', 'Protons!CEquator T2!C[p/(cm!U2!N-s-sr-keV)]'
  options, /def, panel_4b, 'ysubtitle', ''
  options, /def, panel_4b, 'psym', 0

  panel_4 = [panel_4a, panel_4b]

  ;=============================================================================
  ; Panel 5a, 5b: MPSH, electrons, L2 SEISS/MPS-HI - 5-minute Flux Averages
  ; Electron flux, 5 telescopes, 10 energy bands
  ; Show telescopes 3,4 for electrons

  panel_5a = prefix+'_AvgDiffElectronFlux'+suffix + '_0'
  get_data, panel_5a, data=d_5a
  if ~is_struct(d_5a) then begin
    filler=fltarr(2,10)
    filler[*,*]=float('NaN')
    store_data,panel_5a,data={x:time_double(overviewdate)+findgen(2),y:filler}
  endif
  ; plotting options, panel_5a
  options, /def, panel_5a, 'ylog', 1
  options, /def, panel_5a, 'labels', ['E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7', 'E8', 'E9', 'E10']
  options, /def, panel_5a, 'labflag', -1
  options, /def, panel_5a, 'ytitle', 'Electrons!CNorth T3!C '
  options, /def, panel_5a, 'ysubtitle', ''
  options, /def, panel_5a, 'psym', 0

  panel_5b = prefix+'_AvgDiffElectronFlux'+suffix + '_2'
  get_data, panel_5b, data=d_5b
  if ~is_struct(d_5b) then begin
    filler=fltarr(2,10)
    filler[*,*]=float('NaN')
    store_data,panel_5b,data={x:time_double(overviewdate)+findgen(2),y:filler}
  endif
  ; plotting options, panel_5b
  options, /def, panel_5b, 'ylog', 1
  options, /def, panel_5b, 'labels', ['E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7', 'E8', 'E9', 'E10']
  options, /def, panel_5b, 'labflag', -1
  options, /def, panel_5b, 'ytitle', 'Electrons!CEquator T4!C[e/(cm!U2!N-s-sr-keV)]'
  options, /def, panel_5b, 'ysubtitle', ''
  options, /def, panel_5b, 'psym', 0

  panel_5 = [panel_5a, panel_5b]

  ;=============================================================================
  ; Panel 6: XRS xrsf-l2-avg1m
  ; XRS-A, XRS-B primary average flux. Electron contamination has been removed.
  ; 0.05 to 0.4 nm and 0.1 to 0.8 nm (Channel B)
  xrsa = 'goes' + probe +'_xrsa_flux' + suffix
  xrsb = 'goes' + probe +'_xrsb_flux' + suffix
  panel_6 = 'goes' + probe +'_xrsab_flux' + suffix
  goesr_load_data, datatype = 'xrs', probes = probe, suffix = suffix
  if tnames(xrsa) ne '' && tnames(xrsb) ne '' then begin
    get_data, xrsa, data=dxa, dl=dlxa
    get_data, xrsb, data=dxb, dl=dlxb
  endif

  if is_struct(dxa) && is_struct(dxb) then begin
    store_data, panel_6, data={x:dxa.x, y:[[dxa.y],[dxb.y]]}, dl=dlxa
  endif else begin
    filler=fltarr(2,2)
    filler[*,*]=float('NaN')
    store_data, panel_6,data={x:time_double(overviewdate)+findgen(2),y:filler}
  endelse

  ; plotting options, panel_6
  options, /def, panel_6, 'ylog', 1
  options, /def, panel_6, 'labels', ['0.05-0.4 nm', '0.1-0.8 nm']
  options, /def, panel_6, 'colors', [2,6]
  options, /def, panel_6, 'labflag', 1
  options, /def, panel_6, 'ytitle', 'Xray flux!C[W/m^2]'
  options, /def, panel_6, 'ysubtitle', ''

  ; no errors up to this point
  error = 0

  ;=============================================================================
  ; Panel below X-Axis: Spacecraft position, only for GOES-R
  outnames = ''
  outnamesi = ''
  if probe ge 16 then begin
    gprefix = 'goes' + probe
    outnames = gprefix + '_pos_gsm_' + ['x', 'y', 'z']
    outnamesi = gprefix + '_pos_gsm_' + ['z', 'y', 'x'] ; tplot needs inverse order from tplot_gui
    goesr_load_data, datatype = 'mag', probes = probe, suffix = suffix
    get_data, gprefix+'_b_total'+suffix, data=d_b_total ;use this to find NaN values
    get_data, gprefix+'_orbit_llr_geo' + suffix, data=d_geo, dl=dl_geo, limits=l_geo
    if is_struct(d_geo) && is_struct(d_b_total) then begin
      idx = where(~finite(d_b_total.y), countnan)
      if countnan gt 0 then begin
        d_geo.y[idx, *] = !VALUES.F_NAN
      endif
      lat = d_geo.y[*, 0]
      lon = d_geo.y[*, 1]
      r = d_geo.y[*, 2]/6371000.2
      xx = r * cos(lat) * cos(lon)
      yy = r * cos(lat) * sin(lon)
      zz = r * sin(lat)
      loc_geo = gprefix + '_location' + suffix
      loc_gsm = loc_geo + '_gsm'

      store_data, loc_geo, data={x:d_geo.x, y:[[xx], [yy], [zz]]}, dlimits=dl
      thm_cotrans, loc_geo, in_coord='geo', out_suf='_gsm', out_coord='gsm'
      get_data, loc_gsm, data=tmp_gsm

      if is_struct(tmp_gsm) then begin
        data_att = {project:'GOES', observatory:'g'+probe, instrument:'mag', units:'km', coord_sys:'gsm', st_type:'pos'}
        dlimits = {data_att: data_att, colors: [2,4,6], labels: ['x','y','z']+'_gsm', ytitle:'GSM'}
        store_data, outnames[0], data={x:tmp_gsm.x, y:tmp_gsm.y[*,0]}, dlimits=dlimits
        options, outnames[0], ytitle='X-GSM', /add
        store_data, outnames[1], data={x:tmp_gsm.x, y:tmp_gsm.y[*,1]}, dlimits=dlimits
        options, outnames[1], ytitle='Y-GSM', /add
        store_data, outnames[2], data={x:tmp_gsm.x, y:tmp_gsm.y[*,2]}, dlimits=dlimits
        options, outnames[2], ytitle='Z-GSM', /add
        time_clip, outnames, tr[0], tr[1], replace=1, error=error      
      endif else begin
        dprint,'No GSM position data found'
      endelse
    end
  end

  ;=============================================================================
  ; Plot options
  all_panels = [panel_1, panel_2, panel_3, panel_4, panel_5, panel_6]
  time_clip, all_panels, tr[0], tr[1], replace=1, error=error

  !p.background=255.
  !p.color=0.
  time_stamp,/off
  loadct2,43
  !p.charsize=0.8

  tplot_options, 'title', 'GOES-'+probe+' Overview ('+overviewdate+')'

  if undefined(gui_overplot) then begin
    if ~undefined(device) then begin
      tplot, all_panels, var_label=outnamesi
    endif else begin
      window, 1, xsize=window_xsize, ysize=window_ysize
      tplot, all_panels, window=1, var_label=outnamesi
    endelse
    if keyword_set(makepng) then begin
      thm_gen_multipngplot, 'goes_goes'+probe, overviewdate, directory = dir, /mkdir
    endif
  endif else begin
    tplot_gui, all_panels, var_label=outnames, /no_verify, /add_panel, import_only=import_only
  endelse

  ; turn off the variable labels
  tplot_options, var_label=''
end

