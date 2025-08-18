function mvn_sep_get_anc_data,sensornum,strformat=strct,mag_tname=mag_tname,time=time,trange=trange,resolution=resolution,dlimits=tplot_dlimits

nan=!values.f_nan
nanx3 = [nan,nan,nan]
dnan = !values.d_nan

strformat = {  $
  time: dnan, $
  f_fov_dir_mso: nanx3, $
  f_sun_angle: nan, $
  f_sun_phi: nan, $
  f_sun_dir: nanx3, $
  f_mars_angle: nan, $
  f_mars_dist: nan, $
  f_mars_dir: nanx3, $
  f_B_angle: nan,  $
  f_ram_angle: nan, $
  f_ram_angle2: nan, $
  f_ram_dir: nanx3 , $
  r_fov_dir_mso: nanx3, $
  r_sun_angle: nan, $
  r_sun_phi: nan, $
  r_sun_dir: nanx3, $
  r_mars_angle: nan, $
  r_mars_dist: nan, $
  r_mars_dir: nanx3, $
  r_B_angle: nan,  $
  r_ram_angle: nan, $
  r_ram_dir: nanx3 , $
  _B : nanx3, $
  vel1 : nanx3, $
  vel2 : nanx3, $
  vel3 : nanx3, $
  vel4 : nanx3, $
  _QROT_MSO:   [nan,nan,nan,nan]   $
  
  }
  
  
      
  if ~keyword_set(sensornum) then return,strformat

  col = (['d','b','r'])[sensornum]
  
  tplot_dlimits = {  $
    f_sun_angle: {yrange:[0,180.],ystyle:1 ,colors:col}, $
    f_mars_angle: {yrange:[0,180.],ystyle:1 ,colors:col}, $
    f_sun_phi:   {yrange:[-180.,180.],ystyle:1 ,colors:col} ,$
    f_sun_dir_mso:  { yrange:[-1.,1. ], ystyle:1, colors:'bgr'}, $
    f_B_angle: {yrange:[0,180.],ystyle:1 ,colors:col }, $
    r_sun_angle: {yrange:[0,180.],ystyle:1  ,colors:col,linestyle:2}, $
    r_mars_angle: {yrange:[0,180.],ystyle:1  ,colors:col,linestyle:2}, $
    r_sun_phi:   {yrange:[-180.,180.],ystyle:1 ,colors:col,linestyle:2} ,$
    r_sun_dir_mso:  { yrange:[-1.,1. ], ystyle:1}, $
    r_B_angle: {yrange:[0,180.],ystyle:1 ,colors:col,linestyle:2 }, $
    _QROT_MSO:  {yrange:[-1,1], ystyle:1,colors:'dbgr' } $
  }

  
  if ~keyword_set(strct) then begin
    if not keyword_set(time) then begin
      time = dgen(range=timerange(trange), res= keyword_set(resolution) ? resolution : 60d)
    endif
    nt = n_elements(time)
    strct = replicate(strformat, nt)
    strct.time = time
  endif else time=strct.time
  
  sensorstr = strtrim(sensornum,2)
  
  time = strct.time
  
t0=systime(1)
  sep_frame = 'MAVEN_SEP'+sensorstr
  sep_qrot_MSO =   spice_body_att(sep_frame, 'MSO',/quaternion,time,check_objects='MAVEN_SPACECRAFT') 
  strct._qrot_mso = sep_qrot_MSO

  mso_qrot_sep = sep_qrot_mso   & mso_qrot_sep[0,*] = -sep_qrot_mso[0,*]

t1=systime(1)
  dir_mso = quaternion_rotation( [ 1.,0,0] , sep_qrot_mso ,/last_ind)
t2=systime(1)
dprint,dlevel=2,t1-t0,t2-t1
  dir_oms = shift(dir_mso,-1,0)   ; rotate into coordinate frame with z pointed at sun
  xyz_to_polar,transpose(dir_oms),theta=theta,phi=phi  ,/co_lat
  strct.f_sun_angle = theta
  strct.f_sun_phi = phi
  strct.f_fov_dir_mso =  dir_mso

  dir_mso = quaternion_rotation( [-1.,0,0] , sep_qrot_mso ,/last_ind)
  dir_oms = shift(dir_mso,-1,0)   ; rotate reverse FOV into coordinate frame with z pointed at sun (cyclic permutation x->z  z->y  y->x)
  xyz_to_polar,transpose(dir_oms),theta=theta,phi=phi  ,/co_lat
  strct.r_sun_angle = theta
  strct.r_sun_phi = phi
  strct.r_fov_dir_mso =  dir_mso

  mars_pos = spice_body_pos('MARS','MAVEN',utc=time,frame=sep_Frame,check_objects = 'MAVEN_SPACECRAFT' )
;  mars_pos1 = spice_body_pos('MARS','MAVEN',utc=time,frame='MMO',check_objects = 'MAVEN_SPACECRAFT' )
  
  dist = sqrt(total(mars_pos^2,1))
  angle = 180/!pi*acos(reform(mars_pos[0,*]) / dist )

  strct.f_mars_angle = angle
  strct.f_mars_dist = dist
  strct.r_mars_angle = 180-angle


 
  mvn_vel = spice_body_vel('MARS','MAVEN',utc=time,frame='IAU_MARS',check_objects = 'MAVEN_SPACECRAFT' )
  strct.vel1 = mvn_vel
  mvn_vel = spice_body_vel('MARS','MAVEN',utc=time,frame='MSO',check_objects = 'MAVEN_SPACECRAFT' )
  strct.vel2 = mvn_vel 

  MSO_QROT_MMO = spice_body_att('MSO','MAVEN_MMO',time,check_objects = 'MAVEN_SPACECRAFT',/quaternion)
  
  velprime = quaternion_rotation(mvn_vel, MSO_QROT_MMO,/last_ind)
  strct.vel3 = velprime

  mvn_vel = spice_body_vel('MARS','MAVEN',utc=time,frame='MAVEN_MMO',check_objects = 'MAVEN_SPACECRAFT' )
  strct.vel4 = mvn_vel

  ; spice_vector_rotate(mvn_vel,time,'IAU_MARS','MAVEN_RAM',check_objects = 'MAVEN_SPACECRAFT' )
  theta = 180/!pi*acos(reform(mvn_vel[0,*]) / sqrt(total(mvn_vel^2,1)) )
  strct.f_ram_angle = theta
  strct.r_ram_angle = 180 - theta

;  strct.f_ram_angle2 = theta2

 
  return, strct
end

