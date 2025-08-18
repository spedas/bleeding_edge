; Created by Rob Lillis
; $LastChangedBy: ali $
; $LastChangedDate: 2022-07-06 12:19:01 -0700 (Wed, 06 Jul 2022) $
; $LastChangedRevision: 30900 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_anc_load.pro $
; $ID: $

pro mvn_sep_anc_load,trange=trange,download_only=download_only,anc_structure=anc_structure,prefix=prefix

  cdf_format = 'maven/data/sci/sep/anc/cdf/YYYY/MM/mvn_sep_l2_anc_YYYYMMDD_v0?_r??.cdf'
  cdf_files = mvn_pfp_file_retrieve(cdf_format,/daily_names,trange=trange,/valid_only,/last_version)
  if CDF_files[0] eq '' then print, 'Ancillary files do not exist for this time range' else begin
    ;sav_format ='maven/data/sci/sep/anc/sav/YYYY/MM/mvn_sep_anc_YYYYMMDD_v0?_r??.sav'
    ;sav_files = mvn_pfp_file_retrieve(sav_format,/daily_names,trange=trange,/valid_only,/last_version)
    if ~keyword_set(download_only) then begin
      cdf2tplot,cdf_files,prefix=prefix
      if ~keyword_set(prefix) then prefix=''
      get_data, prefix+'sep_1f_fov_mso', data = FOV_1F
      get_data, prefix+'sep_1r_fov_mso', data = FOV_1R
      get_data, prefix+'sep_2f_fov_mso', data = FOV_2F
      get_data, prefix+'sep_2r_fov_mso', data = FOV_2R
      ; translate to spherical polar coordinates
      cart2spc, FOV_1F.y [*, 0],FOV_1F.y [*, 1],FOV_1F.y [*, 2], r, theta_1F, phi_1F
      cart2spc, FOV_1R.y [*, 0],FOV_1R.y [*, 1],FOV_1R.y [*, 2], r, theta_1R, phi_1R
      cart2spc, FOV_2F.y [*, 0],FOV_2F.y [*, 1],FOV_2F.y [*, 2], r, theta_2F, phi_2F
      cart2spc, FOV_2R.y [*, 0],FOV_2R.y [*, 1],FOV_2R.y [*, 2], r, theta_2R, phi_2R
      ; store the tplot variables
      store_data,prefix+'theta_1F',data = {x: FOV_1F.x, y:theta_1F/!dtor}
      store_data,prefix+'phi_1F',data = {x: FOV_1F.x, y:phi_1F/!dtor}
      options,prefix+'theta_1F','linestyle', 0
      options,prefix+'phi_1F','linestyle', 0
      store_data,prefix+'angles_1F',data = prefix+['theta_1F','phi_1F']
      store_data,prefix+'theta_1R',data = {x: FOV_1R.x, y:theta_1R/!dtor}
      store_data,prefix+'phi_1R',data = {x: FOV_1R.x, y:phi_1R/!dtor}
      options,prefix+'theta_1R', 'linestyle', 0
      options,prefix+'phi_1R', 'linestyle', 0
      store_data,prefix+'angles_1R',data = prefix+['theta_1R','phi_1R']

      store_data,prefix+'theta_2F',data = {x: FOV_2F.x, y:theta_2F/!dtor}
      store_data,prefix+'phi_2F',data = {x: FOV_2F.x, y:phi_2F/!dtor}
      options,prefix+'theta_2F','linestyle', 0
      options,prefix+'phi_2F','linestyle', 0
      store_data,prefix+'angles_2F',data = prefix+['theta_2F','phi_2F']
      store_data,prefix+'theta_2R',data = {x: FOV_2R.x, y:theta_2R/!dtor}
      store_data,prefix+'phi_2R',data = {x: FOV_2R.x, y:phi_2R/!dtor}
      options,'theta_2R', 'linestyle', 0
      options,'phi_2R', 'linestyle', 0
      store_data,prefix+'angles_2R',data = prefix+['theta_2R','phi_2R']

      options,'*_1F','colors',1
      options,'*_1R','colors',2
      options,'*_2F','colors',4
      options,'*_2R','colors',6

      options,prefix+'angles_1F','colors',1
      options,prefix+'angles_1R','colors',2
      options,prefix+'angles_2F','colors',4
      options,prefix+'angles_2R','colors',6

      ylim,prefix+'angles_*',0.0,360.0
      options,prefix+'angles_*','ystyle',1
      options,prefix+'angles_*','yticks',4
      options,prefix+'angles_*','yminor',9

      options,prefix+'phi_1F','labels','1F'
      options,prefix+'phi_1R','labels','1R'
      options,prefix+'phi_2F','labels','2F'
      options,prefix+'phi_2R','labels','2R'
      store_data,prefix+'MSO_phi',data = prefix+['phi_1F','phi_1R','phi_2F','phi_2R']
      store_data,prefix+'MSO_theta',data = prefix+['theta_1F','theta_1R','theta_2F','theta_2R']
      ylim,prefix+'MSO_phi',0.0,360.0
      options,prefix+'MSO_phi','yticks',4
      options,prefix+'MSO_phi','yminor',9
      ylim,prefix+'MSO_theta',0.0,180.0
      options,prefix+'MSO_theta','yticks',4
      options,prefix+'MSO_theta','yminor',3
      options,prefix+'MSO_theta','ystyle',1
      options,prefix+'MSO_phi','labels',['1F','1R','2F','2R']
      options,prefix+'MSO_theta','labels',['1F','1R','2F','2R']
      options,prefix+'MSO_*','labflag',1
      store_data, prefix+'Mars_in_FOV', data = prefix+['sep_1f_frac_fov_mars', 'sep_1r_frac_fov_mars',$
        'sep_2f_frac_fov_mars', 'sep_2r_frac_fov_mars']
      options,prefix+'Mars_in_FOV','colors',[1, 2, 4, 6]
      options,prefix+'Mars_in_FOV','labels',['1F','1R','2F','2R']
      options,prefix+'Mars_in_FOV','labflag',1
      options,prefix+'Mars_in_FOV', 'ytitle','Fraction !c FOV Mars'
      store_data, prefix+'Nadir_angles', Data = prefix+['sep_1f_fov_nadir_angle', $
        'sep_1r_fov_nadir_angle', $
        'sep_2f_fov_nadir_angle', $
        'sep_2r_fov_nadir_angle']
      options,prefix+'Nadir_angles','colors',[1, 2, 4, 6]
      options,prefix+'Nadir_angles','ytitle','Angle from !c nadir'
      options,prefix+'Nadir_angles','labels',['1F','1R','2F','2R']
      options,prefix+'Nadir_angles','labflag',1
      ylim,prefix+'Nadir_angles', 0.0, 180.0
      options,prefix+'Nadir_angles','yticks',4
      options,prefix+'Nadir_angles','yminor',3
      options,prefix+'Nadir_angles','ystyle',1

      ; get spacecraft altitude,, in
      ; case the user hasn't aalready
      ; loaded it
      get_data, prefix+'mvn_pos_mso', data = MSO
      altitude = SQRT(total (MSO.y^2, 2))-3390.0
      store_data, prefix+'Altitude_geocentric', data = {x:MSO.x,y: altitude}
      ylim,prefix+'Altitude_geocentric', 0,7000,0
      options,prefix+'Altitude_geocentric','ytitle', 'Alt, km'

    endif

    if arg_present (anc_structure) then mvn_sep_anc_read_cdf, cdf_files, sep_ancillary = anc_structure
  endelse
end