; the keyword 'eflux' loads tplot variables for energy flux also.

pro mvn_sep_load,pathnames=pathnames,trange=trange,files=files,RT=RT,download_only=download_only, $
  mag=mag,pfdpu=pfdpu,sep=sep,lpw=lpw,sta=sta,format=format,use_cache=use_cache,  $
  source=source,verbose=verbose,L1=L1,L0=L0,L2=L2,ancillary=ancillary, anc_structure = anc_structure,$
  pad = pad, eflux = eflux, lowres=lowres,arc=arc,units_name=units_name,basic_tags=basic_tags,full_tags=full_tags

  @mvn_sep_handler_commonblock.pro
  ;common mvn_sep_load_com, last_files

  ; loading the ancillary data.
  if keyword_set(ancillary) then begin
    cdf_format = 'maven/data/sci/sep/anc/cdf/YYYY/MM/mvn_sep_l2_anc_YYYYMMDD_v0?_r??.cdf'
    cdf_files = mvn_pfp_file_retrieve(cdf_format,/daily_names,trange=trange,/valid_only,/last_version)
    if CDF_files[0] eq '' then print, 'Ancillary files do not exist for this time range' else begin
      ;sav_format ='maven/data/sci/sep/anc/sav/YYYY/MM/mvn_sep_anc_YYYYMMDD_v0?_r??.sav'
      ;sav_files = mvn_pfp_file_retrieve(sav_format,/daily_names,trange=trange,/valid_only,/last_version)
      if ~keyword_set(download_only) then begin
        cdf2tplot,cdf_files
        get_data, 'sep_1f_fov_mso', data = FOV_1F
        get_data, 'sep_1r_fov_mso', data = FOV_1R
        get_data, 'sep_2f_fov_mso', data = FOV_2F
        get_data, 'sep_2r_fov_mso', data = FOV_2R
        ; translate to spherical polar coordinates
        cart2spc, FOV_1F.y [*, 0],FOV_1F.y [*, 1],FOV_1F.y [*, 2], r, theta_1F, phi_1F
        cart2spc, FOV_1R.y [*, 0],FOV_1R.y [*, 1],FOV_1R.y [*, 2], r, theta_1R, phi_1R
        cart2spc, FOV_2F.y [*, 0],FOV_2F.y [*, 1],FOV_2F.y [*, 2], r, theta_2F, phi_2F
        cart2spc, FOV_2R.y [*, 0],FOV_2R.y [*, 1],FOV_2R.y [*, 2], r, theta_2R, phi_2R
        ; store the tplot variables
        store_data,'theta_1F',data = {x: FOV_1F.x, y:theta_1F/!dtor}
        store_data,'phi_1F',data = {x: FOV_1F.x, y:phi_1F/!dtor}
        options, 'theta_1F', 'linestyle', 0
        options, 'phi_1F', 'linestyle', 0
        store_data, 'angles_1F', data = ['theta_1F','phi_1F']
        store_data,'theta_1R',data = {x: FOV_1R.x, y:theta_1R/!dtor}
        store_data,'phi_1R',data = {x: FOV_1R.x, y:phi_1R/!dtor}
        options, 'theta_1R', 'linestyle', 0
        options, 'phi_1R', 'linestyle', 0
        store_data, 'angles_1R', data = ['theta_1R','phi_1R']

        store_data,'theta_2F',data = {x: FOV_2F.x, y:theta_2F/!dtor}
        store_data,'phi_2F',data = {x: FOV_2F.x, y:phi_2F/!dtor}
        options, 'theta_2F', 'linestyle', 0
        options, 'phi_2F', 'linestyle', 0
        store_data, 'angles_2F', data = ['theta_2F','phi_2F']
        store_data,'theta_2R',data = {x: FOV_2R.x, y:theta_2R/!dtor}
        store_data,'phi_2R',data = {x: FOV_2R.x, y:phi_2R/!dtor}
        options, 'theta_2R', 'linestyle', 0
        options, 'phi_2R', 'linestyle', 0
        store_data, 'angles_2R', data = ['theta_2R','phi_2R']

        options,'*_1F','colors', 1
        options,'*_1R','colors', 2
        options,'*_2F','colors', 4
        options,'*_2R','colors', 6

        options,'angles_1F', 'colors', 1
        options,'angles_1R', 'colors', 2
        options,'angles_2F', 'colors', 4
        options,'angles_2R', 'colors', 6

        ylim, 'angles_*', 0.0, 360.0
        options,'angles_*', 'ystyle', 1
        options,'angles_*', 'yticks', 4
        options,'angles_*', 'yminor', 9

        options, 'phi_1F', 'labels', '1F'
        options, 'phi_1R', 'labels', '1R'
        options, 'phi_2F', 'labels', '2F'
        options, 'phi_2R', 'labels', '2R'
        store_data, 'MSO_phi', data = ['phi_1F','phi_1R','phi_2F','phi_2R']
        store_data, 'MSO_theta', data = ['theta_1F','theta_1R','theta_2F','theta_2R']
        ylim, 'MSO_phi', 0.0, 360.0
        options, 'MSO_phi','yticks', 4
        options, 'MSO_phi', 'yminor', 9
        ylim, 'MSO_theta', 0.0, 180.0
        options, 'MSO_theta','yticks', 4
        options, 'MSO_theta', 'yminor', 3
        options, ' MSO_theta', 'ystyle',1
        options, 'MSO_phi','labels',['1F','1R','2F','2R']
        options, 'MSO_theta','labels',['1F','1R','2F','2R']
        options,'MSO_*','labflag',1
        store_data, 'Mars_in_FOV', data = ['sep_1f_frac_fov_mars', 'sep_1r_frac_fov_mars',$
          'sep_2f_frac_fov_mars', 'sep_2r_frac_fov_mars']
        options, 'Mars_in_FOV', 'colors', [1, 2, 4, 6]
        options, 'Mars_in_FOV', 'labels',['1F','1R','2F','2R']
        options, 'Mars_in_FOV', 'labflag', 1
        options, 'Mars_in_FOV', 'ytitle', 'Fraction !c FOV Mars'
        store_data, 'Nadir_angles', Data = ['sep_1f_fov_nadir_angle', $
          'sep_1r_fov_nadir_angle', $
          'sep_2f_fov_nadir_angle', $
          'sep_2r_fov_nadir_angle']
        options, 'Nadir_angles', 'colors', [1, 2, 4, 6]
        options, 'Nadir_angles', 'ytitle', 'Angle from !c nadir'
        options, 'Nadir_angles', 'labels',['1F','1R','2F','2R']
        options, 'Nadir_angles', 'labflag', 1
        ylim, 'Nadir_angles', 0.0, 180.0
        options, 'Nadir_angles','yticks', 4
        options, 'Nadir_angles', 'yminor', 3
        options, ' Nadir_angles', 'ystyle',1

        ; get spacecraft altitude,, in
        ; case the user hasn't aalready
        ; loaded it
        get_data, 'mvn_pos_mso', data = MSO
        altitude = SQRT(total (MSO.y^2, 2))-3390.0
        store_data, 'Altitude_geocentric', data = {x:MSO.x,y: altitude}
        ylim,'Altitude_geocentric', 0,7000,0
        options, 'Altitude_geocentric','ytitle', 'Alt, km'

      endif

      if arg_present (anc_structure) then mvn_sep_anc_read_cdf, cdf_files, sep_ancillary = anc_structure
    endelse
    return
  endif

  if keyword_set(pad) then begin
    pad_format = 'maven/data/sci/sep/l2_pad/sav/YYYY/MM/mvn_sep_l2_pad_YYYYMMDD_v0?_r??.sav'
    pad_files = mvn_pfp_file_retrieve(pad_format,/daily_names,trange=trange,/valid_only,/last_version)
    if pad_files[0] eq '' then print, 'PAD files do not exist for this time range' else begin
      restore, pad_files[0]
      npadfiles = n_elements(pad_files)
      pads = pad;rename the pad structure
      if npadfiles gt 1 then begin
        for J = 1, npadfiles-1 do begin
          print,'Restoring '+pad_files[J]
          restore, pad_files[J]
          pads = [pads, pad]
        endfor
      endif
      mvn_sep_pad_load_tplot,pads
      pad = pads
    endelse
    return
  endif

  if keyword_set(L0) then   format = 'L0_RAW'
  if keyword_set(L1) then   format = 'L1_SAV'
  if keyword_set(L2) then   format = 'L2_CDF'

  if ~keyword_set(format) then format='L1_SAV'

  if format eq 'L1_SAV' then begin

    if keyword_set(use_cache) and keyword_set(source_filenames) then begin
      files = mvn_pfp_file_retrieve(/L0,/daily,trange=trange,source=source,verbose=verbose,RT=RT,files=files,pathnames)
      if array_equal(files,source_filenames) then begin
        dprint,dlevel=2,'Using cached common block'
        return
      endif
    endif

    mvn_sep_var_restore,trange=trange,download_only=download_only,verbose=verbose,lowres=lowres,arc=arc,$
      units_name=units_name,basic_tags=basic_tags,full_tags=full_tags
    if ~keyword_set(download_only) then begin
      mvn_sep_cal_to_tplot,sepn=1,lowres=lowres,arc=arc
      mvn_sep_cal_to_tplot,sepn=2,lowres=lowres,arc=arc
    endif
    return
  endif


  if format eq 'L2_CDF' then begin
    for sepnum = 1,2 do begin
      sepstr = 's'+strtrim(sepnum,2)
      data_type = sepstr+'-cal-svy-full'
      L2_fileformat =  'maven/data/sci/sep/l2/YYYY/MM/mvn_sep_l2_'+data_type+'_YYYYMMDD_v0?_r??.cdf'
      ;    if getenv('USER') eq 'davin' then L2_fileformat =  'maven/data/sci/sep/l2_v04/YYYY/MM/mvn_sep_l2_'+data_type+'_YYYYMMDD_v04_r??.cdf'
      filenames = mvn_pfp_file_retrieve(l2_fileformat,/daily_name,trange=trange,verbose=verbose,/valid_only)
      if ~keyword_set(download_only) then cdf2tplot,filenames,prefix = 'mvn_L2_sep'+strtrim(sepnum,2) else return
    endfor

    if keyword_set (eflux) then begin  ; also load Energy flux
      get_data,  'mvn_L2_sep1f_ion_flux', data = ion_1F
      get_data,  'mvn_L2_sep2f_ion_flux', data = ion_2F
      get_data,  'mvn_L2_sep1r_ion_flux', data = ion_1R
      get_data,  'mvn_L2_sep2r_ion_flux', data = ion_2R

      ; make tplot variables for ion energy flux
      store_data,'mvn_L2_sep1f_ion_eflux', data = {x: ion_1f.x, y: ion_1f.y*ion_1f.v, v:ion_1f.v}
      store_data,'mvn_L2_sep1r_ion_eflux', data = {x: ion_1r.x, y: ion_1r.y*ion_1r.v, v:ion_1r.v}
      store_data,'mvn_L2_sep2f_ion_eflux', data = {x: ion_2f.x, y: ion_2f.y*ion_2f.v, v:ion_2f.v}
      store_data,'mvn_L2_sep2r_ion_eflux', data = {x: ion_2r.x, y: ion_2r.y*ion_2r.v, v:ion_2r.v}

      get_data,  'mvn_L2_sep1f_elec_flux', data = electron_1F
      get_data,  'mvn_L2_sep2f_elec_flux', data = electron_2F
      get_data,  'mvn_L2_sep1r_elec_flux', data = electron_1R
      get_data,  'mvn_L2_sep2r_elec_flux', data = electron_2R

      ; make tplot variables for electron energy flux
      store_data,'mvn_L2_sep1f_electron_eflux',data = {x: electron_1f.x, y: electron_1f.y*electron_1f.v, v:electron_1f.v}
      store_data,'mvn_L2_sep1r_electron_eflux',data = {x: electron_1r.x, y: electron_1r.y*electron_1r.v, v:electron_1r.v}
      store_data,'mvn_L2_sep2f_electron_eflux',data = {x: electron_2f.x, y: electron_2f.y*electron_2f.v, v:electron_2f.v}
      store_data,'mvn_L2_sep2r_electron_eflux',data = {x: electron_2r.x, y: electron_2r.y*electron_2r.v, v:electron_2r.v}
    endif

    options,'mvn_L2_sep*flux',spec=1,ylog=1,zlog=1,ztickunits='scientific',ytickunits='scientific',ysubtitle='(keV)'
    options,'mvn_L2_sep*_flux', 'ztitle', 'Diff Flux, !c #/cm2/s/sr/keV'
    options,'mvn_L2_sep*eflux', 'ztitle', 'Diff EFlux, !c keV/cm2/s/sr/keV'

    ; make a tplot variable for both attenuators
    store_data, 'Attenuator', data = ['MVN_SEP1attenuator_state', 'MVN_SEP2attenuator_state']
    options, 'Attenuator', 'colors',[70, 221]
    ylim, 'Attenuator', 0.5, 2.5
    options, 'Attenuator', 'labels',['SEP1', 'SEP2']
    options, 'Attenuator', 'labflag',1
    options, 'Attenuator', 'panel_size', 0.5

    return
  endif

  ;  Use L0 format if it reaches this point.

  files = mvn_pfp_file_retrieve(/L0,/daily,trange=trange,source=source,verbose=verbose,RT=RT,files=files,pathnames)

  if keyword_set(use_cache) and keyword_set(source_filenames) then begin
    if array_equal(files,source_filenames) then begin
      dprint,dlevel=2,'Using cached common block'
      return
    endif
  endif

  tstart=systime(1)
  if n_elements(pfdpu) eq 0 then pfdpu=1
  if n_elements(sep) eq 0 then sep=1
  if n_elements(mag) eq 0 then mag=1

  ;last_files=''
  if ~keyword_set(download_only) then begin
    mvn_pfp_l0_file_read,sep=sep,pfdpu=pfdpu,mag=mag,lpw=lpw,sta=sta ,pathname=pathname,file=files,trange=trange
    mvn_sep_handler,record_filenames = files
    ;  last_files = files
  endif

end

