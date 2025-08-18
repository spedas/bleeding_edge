
if ~keyword_set(init) then begin
  timespan,'2014-4-16',2  ;  Mag rolls
  mvn_sep_load,sep=1,/mag
  mk = mvn_spice_kernels(/load)

; mvn_mag_handler,svy_tags='*'   ; Create all the tplot variables for Survey
;  mvn_mag_handler,hkp_tags='*'   ; Create all the tplot variables for HKP
  mvn_mag_handler,svy_tags='BRAW'
  mvn_mag_handler,hkp_tags='*TEMP'   ; Create all the tplot variables with TEMP in the name
 
  options,'mvn_mag1_hkp_*',colors='b'
  options,'mvn_mag2_hkp_*',colors='r'
  
  store_data,'TEMPS',data='*_TEMP'
  spice_qrot_to_tplot,'MAVEN_MAG1','MAVEN_SSO',check_objects='MAVEN_SPACECRAFT',get_omega=3,name=qname
  
if 0 then begin
  options,'mvn_mag2_svy_BRAW',spice_frame='MAVEN_MAG2' ,colors='bgr'  ; specify what frame the data is currently in.
  options,'mvn_mag1_svy_BRAW',spice_frame='MAVEN_MAG1' ,colors='bgr'
  spice_vector_rotate_tplot,'mvn_mag2_svy_BRAW','MAVEN_MAG1'
  
  split_vec,'mvn_mag1_svy_BRAW mvn_mag2_svy_BRAW_MAVEN_MAG1'
  
  store_data,'B1_x',data='mvn_mag1_svy_BRAW_x mvn_mag2_svy_BRAW_MAVEN_MAG1_x'
  store_data,'B1_y',data='mvn_mag1_svy_BRAW_y mvn_mag2_svy_BRAW_MAVEN_MAG1_y'
  store_data,'B1_z',data='mvn_mag1_svy_BRAW_z mvn_mag2_svy_BRAW_MAVEN_MAG1_z'
  
  dif_data,'mvn_mag1_svy_BRAW','mvn_mag2_svy_BRAW_MAVEN_MAG1'
endif else begin  
  options,'mvn_mag2_svy_BAVG',spice_frame='MAVEN_MAG2' ,colors='bgr'  ; specify what frame the data is currently in.
  options,'mvn_mag1_svy_BAVG',spice_frame='MAVEN_MAG1' ,colors='bgr'
  spice_vector_rotate_tplot,'mvn_mag2_svy_BAVG','MAVEN_MAG1'
  
  split_vec,'mvn_mag1_svy_BAVG mvn_mag2_svy_BAVG_MAVEN_MAG1'
  
  store_data,'B1_x',data='mvn_mag1_svy_BAVG_x mvn_mag2_svy_BAVG_MAVEN_MAG1_x'
  store_data,'B1_y',data='mvn_mag1_svy_BAVG_y mvn_mag2_svy_BAVG_MAVEN_MAG1_y'
  store_data,'B1_z',data='mvn_mag1_svy_BAVG_z mvn_mag2_svy_BAVG_MAVEN_MAG1_z'
  dif_data,'mvn_mag1_svy_BAVG','mvn_mag2_svy_BAVG_MAVEN_MAG1'
endelse

  tplot,'B1_? mvn_mag*-*
  init = 1
  
endif

mvn_mag_handler,mag1_svy = mag
tr = time_double( ['2014-04-16/20:32:40', '2014-04-16/21:18:45'])

timebar,tr

w = where( mag.time gt tr[0] and mag.time lt tr[1] )

braw = mag[w].braw
ut = mag[w].time
dt = ut-shift(ut,1)
dt[0]=dt[1]
printdat,minmax(dt),median(dt)
dt = median(dt)

qrot = spice_body_att('MAVEN_MAG1','MAVEN_SSO',ut,/quaternion) ;  get the rotation quaterion

matrix_2_1= spice_body_att('MAVEN_MAG2','MAVEN_MAG1',ut[0])    ; single rotation matrix

offset = [0.3,-1.6,-1.]  ;* 0.
one = replicate(1,n_elements(ut) )
bvec = quaternion_rotation( braw + offset # one , qrot ,/last_index )

fft_bvec = fft2(bvec[0,*],dt,/double,f)






mvn_mag_handler,/offset1
spice_vector_rotate_tplot,'mvn_mag1_svy_Bcor','MSO'



end
