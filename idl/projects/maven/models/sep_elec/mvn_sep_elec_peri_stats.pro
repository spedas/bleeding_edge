;20171109 Ali
;calculates useful stats related to electron flux dispersions at periapse during the Sep 2017 SEP event

pro mvn_sep_elec_peri_stats,mhd=mhd,xyz=xyz

if keyword_set(mhd) then frame='MSO' else frame='IAU_MARS'
get_data,'mvn_B_1sec_'+frame,data=magdata; magnetic field vector
time=magdata.x
nt=n_elements(time)
mag=magdata.y
scp=transpose(spice_body_pos('MAVEN','MARS',frame=frame,utc=time,check_objects=['MARS','MAVEN'],/force_objects)) ;MAVEN position (km)
magtot=sqrt(total(mag^2,2)) ;nT
scptot=sqrt(total(scp^2,2)) ;km
rhat=scp/rebin(scptot,[nt,3]) ;radial unit vector
phat2=crossp2([0.,0.,1.],rhat)
phat=phat2/rebin(sqrt(total(phat2^2,2)),[nt,3]) ;azimuthal unit vector (phi)
that2=crossp2(phat,rhat)
that=that2/rebin(sqrt(total(that2^2,2)),[nt,3]) ;polar unit vector (theta)
magr=total(mag*rhat,2)
magp=total(mag*phat,2)
magt=total(mag*that,2)
cosmagdip=magr/magtot ;cos of dip angle
magt2=sqrt(1-cosmagdip^2)*magtot ;mag perp to radial (horizontal)
magt3=sqrt(magp^2+magt^2) ;should be equal to magt2
;magdipdeg=!radeg*acos(cosmagdip)
store_data,'mvn_B_cos_dip',data={x:time,y:cosmagdip},lim={yrange:[-1,1],panel_size:.5,constant:0}
store_data,'mvn_Brtp_'+frame+'_(nT)',data={x:time,y:[[magr],[magt],[magp],[magtot]]},lim={colors:'rgbk',labels:['Br','Bt','Bp','Btot'],labflag:1,constant:0,spice_frame:frame}
store_data,'mvn_Bxyz_'+frame+'_(nT)',data={x:time,y:[[mag],[magtot]]},lim={colors:'bgrk',labels:['Bx','By','Bz','Btot'],labflag:1,constant:0,spice_frame:frame}
store_data,'mvn_Rxyz_'+frame+'_(km)',data={x:time,y:[[scp],[scptot]]},lim={colors:'bgrk',labels:['Rx','Ry','Rz','Rtot'],labflag:1,constant:0,spice_frame:frame}

if keyword_set(mhd) then begin
  lowres=1
  mvn_sep_elec_peri_mhd,mhd=mhd,bxyz=b,b1xyz=b1,rxyz=rxyz ;MHD MSO bxyz (nT) and rxyz (km)
  if keyword_set(b1) then b0=b-b1 ;crustal field
endif else begin
  if keyword_set(xyz) then begin
    restore,'/home/rahmati/Desktop/crustalb/bxyziau.dat' ;Bxyz in IAU_MARS
    b=bxyz
  endif else begin
    restore,'/home/rahmati/Desktop/crustalb//Morschhauser_spc_dlat0.25_delon0.25_dalt5.sav' ;crustal field model (nT) in IAU_MARS (Brtp: spherical polar coordinates)
    b=transpose(morschhauser.b,[0,1,3,2]) ;[r,t,p]
  endelse
endelse
bcr=replicate(!values.f_nan,[nt,3])
rcr=bcr
b0r=bcr
for it=0,nt-1 do begin
  x1=reform(scp[it,*])
  bcr[it,*]=mvn_sep_elec_peri_bcrust(x1,b,lowres=lowres,mhd=mhd,t=time[it]) ;crustal field model (nT)
  if keyword_set(b0) then b0r[it,*]=mvn_sep_elec_peri_bcrust(x1,b0,lowres=lowres,mhd=mhd,t=time[it])
  if keyword_set(rxyz) then rcr[it,*]=mvn_sep_elec_peri_bcrust(x1,rxyz,lowres=lowres,mhd=mhd)
endfor
if keyword_set(mhd) then begin  
  store_data,'Bxyz_MHD_'+frame+'_(nT)',data={x:time,y:[[bcr],[sqrt(total(bcr^2,2))]]},lim={colors:'bgrk',labels:['Bx','By','Bz','Btot'],labflag:1,constant:0,linestyle:2,spice_frame:frame}
  store_data,'Rxyz_MHD_'+frame+'_(km)',data={x:time,y:[[rcr],[sqrt(total(rcr^2,2))]]},lim={colors:'bgrk',labels:['Rx','Ry','Rz','Rtot'],labflag:1,constant:0,linestyle:2,spice_frame:frame}
  store_data,'mvn_B_data_model_'+frame+'_(nT)',data='mvn_Bxyz_'+frame+'_(nT) Bxyz_MHD_'+frame+'_(nT)',dlim={panel_size:1.5,spice_frame:frame}
  store_data,'mvn_R_data_model_'+frame+'_(km)',data='mvn_Rxyz_'+frame+'_(km) Rxyz_MHD_'+frame+'_(km)',dlim={panel_size:1.5,spice_frame:frame}
  if keyword_set(b0) then store_data,'Bxyz_MHD_crustal_'+frame+'_(nT)',data={x:time,y:[[b0r],[sqrt(total(b0r^2,2))]]},lim={colors:'bgrk',labels:['Bx','By','Bz','Btot'],labflag:1,constant:0,linestyle:2,spice_frame:frame}
endif else begin
  if keyword_set(xyz) then begin
    store_data,'Bxyz_crustal_model_'+frame+'_(nT)',data={x:time,y:[[bcr],[sqrt(total(bcr^2,2))]]},lim={colors:'bgrk',labels:['Bx','By','Bz','Btot'],labflag:1,constant:0,linestyle:2,spice_frame:frame}
    spice_vector_rotate_tplot,'Bxyz_crustal_model_'+frame+'_(nT)','MSO'
    get_data,'Bxyz_crustal_model_IAU_MARS_(nT)_MSO',data=bxyzmso,alim=alim
    store_data,'Bxyz_crustal_model_MSO_(nT)',data={x:time,y:[[bxyzmso.y],[sqrt(total(bxyzmso.y^2,2))]]},lim=alim
    store_data,'mvn_B_data_model_'+frame+'_(nT)',data='mvn_Bxyz_'+frame+'_(nT) Bxyz_crustal_model_'+frame+'_(nT)',dlim={panel_size:1.5}
  endif else begin
    store_data,'Brtp_crustal_model_'+frame+'_(nT)',data={x:time,y:[[bcr],[sqrt(total(bcr^2,2))]]},lim={colors:'rgbk',labels:['Br','Bt','Bp','Btot'],labflag:1,constant:0,linestyle:2,spice_frame:frame}
    store_data,'mvn_B_data_model_'+frame+'_(nT)',data='mvn_Brtp_'+frame+'_(nT) Brtp_crustal_model_'+frame+'_(nT)',dlim={panel_size:1.5}
  endelse
endelse

evel=velocity(50e3,/elec,/true) ;50 keV electron speed (km/s)
xdir=[1.,0.,0.]#replicate(1.,nt) ;X-direction (SEP front FOV)
sep1fov=transpose(spice_vector_rotate(xdir,time,'MAVEN_SEP1',frame,check_objects='MAVEN_SPACECRAFT',/force_objects)); sep1 look direction
sep2fov=transpose(spice_vector_rotate(xdir,time,'MAVEN_SEP2',frame,check_objects='MAVEN_SPACECRAFT',/force_objects)); sep2 look direction
cosvb=[[total(mag*sep1fov,2)/magtot],[total(mag*sep2fov,2)/magtot]]
vpara=evel*cosvb ;parallel speed (km/s) Note: can be negative! meaning direction is opposite of mag
vperp=sqrt(evel^2-vpara^2) ;perpendicular speed (km/s)
vparahat=mag/rebin(magtot,[nt,3]) ;parallel velocity unit vector
vparadir1=rebin(vpara[*,0],[nt,3])*vparahat ;parallel velocity direction (km/s)
vparadir2=rebin(vpara[*,1],[nt,3])*vparahat
vperpdir1=evel*sep1fov-vparadir1 ;perpendicular velocity direction (km/s)
vperpdir2=evel*sep2fov-vparadir2
vperptot1=sqrt(total(vperpdir1^2,2)) ;should be equal to vperp[*,0]

me=!const.me ;electron mass (kg)
qe=!const.e ;electron charge (C)
cc=float(!const.c/1e3) ;speed of light (km/s)
rmars=3390.; mars radius (km)
gama=1./sqrt(1.-(evel/cc)^2) ;relativistic gamma
gyroperiod=gama*me/qe/(1e-9*magtot) ;gyro-period/2pi (s)
gyrofreq=1./gyroperiod ;gyro-frequency (rad/s)
gyroradius1=gyroperiod*vperp[*,0] ;gyro-radius (km)
gyroradius2=gyroperiod*vperp[*,1]
store_data,'mvn_electron_gyroperiod_(s)',data={x:time,y:2.*!pi*gyroperiod},lim={ylog:1,ytickunits:'scientific'}
store_data,'mvn_50keV_electron_gyroradius_(km)',data={x:time,y:[[gyroradius1],[gyroradius2]]},lim={ylog:1,colors:'br',labels:['SEP1','SEP2'],labflag:-1,ytickunits:'scientific'}
store_data,'mvn_cos_B_FOV',data={x:time,y:cosvb},lim={yrange:[-1,1],colors:'br',labels:['SEP1A','SEP2A'],labflag:-1,constant:0}

force1=crossp2(sep1fov,mag) ;centripetal force acting on an electron going backward in time!
force2=crossp2(sep2fov,mag)
forcehat1=force1/rebin(sqrt(total(force1^2,2)),[nt,3]) ;force unit vector
forcehat2=force2/rebin(sqrt(total(force2^2,2)),[nt,3])
gyrocenter1a=scp+(rebin(gyroradius1,[nt,3])*forcehat1) ;position of gyro-center for front detector (A) (km)
gyrocenter1b=scp-(rebin(gyroradius1,[nt,3])*forcehat1) ;position of gyro-center for reverse detector (B) (km)
gyrocenter2a=scp+(rebin(gyroradius2,[nt,3])*forcehat2)
gyrocenter2b=scp-(rebin(gyroradius2,[nt,3])*forcehat2)
gyrocenalt1a=sqrt(total(gyrocenter1a^2,2))-rmars ;gyro-center altitude (km)
gyrocenalt1b=sqrt(total(gyrocenter1b^2,2))-rmars
gyrocenalt2a=sqrt(total(gyrocenter2a^2,2))-rmars
gyrocenalt2b=sqrt(total(gyrocenter2b^2,2))-rmars
store_data,'mvn_50keV_electron_gyrocenter_altitude_(km)',data={x:time,y:[[gyrocenalt1a],[gyrocenalt1b],[gyrocenalt2a],[gyrocenalt2b]]},lim={ylog:1,colors:'bcrm',labels:['SEP1A','SEP1B','SEP2A','SEP2B'],labflag:-1}
store_data,'mvn_50keV_electron_gyrocntr_alt_(km)',data='mvn_50keV_electron_gyrocenter_altitude_(km) mvn_alt',lim={yrange:[10,2000],ystyle:1}

end