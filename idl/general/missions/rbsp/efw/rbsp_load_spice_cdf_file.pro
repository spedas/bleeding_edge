;Load SPICE cdf files at
;http://rbsp.space.umn.edu/rbsp_efw/data/rbsp/spice_product/rbsp?/
;e.g. 2015/rbspa_spice_products_2015_0101_v04.cdf

;These have the tplot variables:
;rbsp?_r_gse  (RE)
;rbsp?_v_gse  (km/s)
;rbsp?_q_uvw2gse
;rbsp?_wsc_gse
;rbsp?_mlt  (hr)
;rbsp?_mlat (deg)
;rbsp?_lshell
;rbsp?_sphase_ssha
;rbsp?_spin_period
;rbsp?_spin_phase


;These CDF files were created by Sheng Tian, 2020.


;This program outputs tplot variables that are meant to replace time-consuming calls to
;rbsp_efw_position_velocity_crib.pro and rbsp_load_state.pro

;Note that I've done a close comparison b/t Sheng's values, my values
;from rbsp_efw_position_velocity_crib.pro, and SSCWeb values. They're all
;very close, with the max difference in velocity and position during the
;test day of no more than 0.1%.  (see  ephemeris_comparison.pro)

;Sheng gets positions from SPICE and takes derivative to calculate
;velocities. We've found that this is more consistent with SSCWeb than getting both positions and
;velocities from SPICE, or by using cotrans to go from one coord system to another.


pro rbsp_load_spice_cdf_file,sc,testing=testing


  rbsp_efw_init
  tr = timerange()
  datetime = strmid(time_string(tr[0]),0,10)


  year = strmid(datetime,0,4)
  mn = strmid(datetime,5,2)
  dy = strmid(datetime,8,2)


  fn = 'rbsp'+sc+'_spice_products_'+year+'_'+mn+dy+'_v08.cdf'

  if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
                                       'rbsp' + strlowcase(sc[0]) + path_sep() + $
                                       'spice_cdfs' + path_sep() + $
                                       year + path_sep()



;this will change to rbsp_efw from kersten soon
;  url = 'http://rbsp.space.umn.edu/kersten/data/rbsp/spice_product/rbsp'+sc+'/'
  url = 'http://rbsp.space.umn.edu/rbsp_efw/spice_product/rbsp'+sc+'/'

  path = year+'/'+fn


  file_loaded = spd_download(remote_file=url+path,$
                local_path=folder,$
                /last_version)


  if ~KEYWORD_SET(testing) then $
    cdf2tplot,file_loaded else $
    cdf2tplot,'~/Desktop/rbspa_spice_products_2014_0101_v08.cdf'




  ;Change location from RE to km
  get_data,'rbsp'+sc+'_r_gse',data=d
  d.y *= 6378.
  store_data,'rbsp'+sc+'_r_gse',data=d



  ;Calculate radial distance variable
  get_data,'rbsp'+sc+'_r_gse',data=dgse
  rv = sqrt(dgse.y[*,0]^2 + dgse.y[*,1]^2 + dgse.y[*,2]^2)
  store_data,'rbsp'+sc+'_state_radius',dgse.x,rv



  ;Shift Sheng's MLT values from -12 to 12 to 0 to 24.
  get_data,'rbsp'+sc+'_mlt',data=d
  d.y += 12.
  store_data,'rbsp'+sc+'_mlt',data=d



  ;---------------------------------------
  ;Create the spinaxis direction in GSE

;  get_data,'rbsp'+sc+'_q_uvw2gse',data=q_uvw2gse
;
;  ;Interpolate to the new time base
;  qnew = qslerp(q_uvw2gse.y, q_uvw2gse.x, d.x)
;
;  ;Rotation matrix
;  m = qtom(qnew)

;  ;Define the spinaxis direction in UVW coord.
;  v = fltarr(n_elements(d.x),3)
;  v[*,0] = 0.
;  v[*,1] = 0.
;  v[*,2] = 1.
;
;  wgse = fltarr(n_elements(d.x),3)
;  wgse[*,0] = v[*,0]*m[*,0,0] + v[*,1]*m[*,0,1] + v[*,2]*m[*,0,2]
;  wgse[*,1] = v[*,0]*m[*,1,0] + v[*,1]*m[*,1,1] + v[*,2]*m[*,1,2]
;  wgse[*,2] = v[*,0]*m[*,2,0] + v[*,1]*m[*,2,1] + v[*,2]*m[*,2,2]
;
;  store_data,'rbsp'+sc+'_spinaxis_direction_gse',d.x,wgse





;   To do the inverse rotation, do a transpose. m_prime then rotates w back to v.
;   for ii=0, nrec-1 do m_prime[ii,*,*] = transpose(m[ii,*,*])
;
;   To preserve accuracy, always interpolate first then convert to matrices.
;


  ;Rename variables to correspond with output from rbsp_efw_position_velocity_crib.pro,
  ;which is what I previously used.


;--------------------------------------------


  copy_data,'rbsp'+sc+'_wsc_gse','rbsp'+sc+'_spinaxis_direction_gse'
  store_data,'rbsp'+sc+'_wsc_gse',/del



  vars = 'rbsp'+sc+'_'+$
    ['r_gsm','r_gse',$
     'v_gsm','v_gse',$
     'mlat','mlt','lshell',$
     'spin_period','spin_phase']
  newvars = 'rbsp'+sc+'_'+$
    ['state_pos_gsm','state_pos_gse',$
     'state_vel_gsm','state_vel_gse',$
     'state_mlat','state_mlt','state_lshell',$
     'spinper','spinphase']


;if ~KEYWORD_SET(testing) then begin

  for i=0,n_elements(vars)-1 do copy_data,vars[i],newvars[i]
  store_data,vars,/del


  get_data,'rbsp'+sc+'_spinaxis_direction_gse',data=d
  wgse = d.y

  ;Get MGSE values
  rbsp_gse2mgse,'rbsp'+sc+'_state_vel_gse',reform(wgse),$
    newname='rbsp'+sc+'_state_vel_mgse'





end
