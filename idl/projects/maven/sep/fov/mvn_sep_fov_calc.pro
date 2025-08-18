;20180419 Ali
;calculates a bunch of parameters for mvn_sep_fov
;nospice: skips slow spice calculations

pro mvn_sep_fov_calc,times,nospice=nospice

  @mvn_sep_fov_common.pro
  @mvn_sep_handler_commonblock.pro

  objects=mvn_sep_fov0.objects
  toframe=mvn_sep_fov0.toframe
  rmars=mvn_sep_fov0.rmars

  t1=systime(1)
  nt=n_elements(times)
  nobj=n_elements(objects)
  fnan=!values.d_nan ;dnan really! Using double to keep higher precision for dot products.
  pos=replicate({sun:fnan,ear:fnan,mar:fnan,pho:fnan,dem:fnan,cm1:fnan,sx1:fnan,ram:fnan},[3,nt])
  tal=pos ;tangent altitude (km) ['sphere','ellipsoid','areoid']
  pdm=reform(pos[0,*]) ;position dot mars (for occultation)
  rad=pdm ;radial distance from the center of the object (km)
  occ=pdm ;occultation flag

  observer='maven'
  check_maven=toframe eq 'maven_sep1' ? 'maven_spacecraft':'maven'
  if ~keyword_set(nospice) then begin
    for iobj=0,nobj-1 do begin
      pos.(iobj)=spice_body_pos(objects[iobj],observer,frame=toframe,utc=times,check_objects=[objects[iobj],observer,check_maven],/force_objects) ;position (km)
      rad.(iobj)=sqrt(total(pos.(iobj)^2,1)) ;distance (km)
      pos.(iobj)/=replicate(1.d,3)#rad.(iobj)
    endfor
    from_frame='j2000'
    pos.ram=spice_body_vel('mars',observer,frame=from_frame,utc=times,check_objects=['mars',observer,check_maven],/force_objects) ;maven velocity wrt Mars in J2000 (km/s)
    rad.ram=sqrt(total(pos.ram^2,1)) ;maven speed (km/s)
    pos.ram/=-replicate(1.d,3)#rad.ram ;MAVEN velocity unit vector wrt Mars in J2000

    qrot=spice_body_att(from_frame,toframe,times,/quaternion,check_objects=check_maven,/force_objects)
    qrot_iau=spice_body_att(toframe,'IAU_MARS',times,/quaternion,check_objects=check_maven,/force_objects)
    mvn_sep_fov=replicate({pos:pos[*,0],rad:rad[0],pdm:pdm[0],occ:occ[0],tal:tal[*,0],qrot:qrot[*,0],qrot_iau:qrot_iau[*,0],time:times[0],att:[0.,0.],crl:fltarr(2,6),crh:fltarr(2,6),sur:fltarr(3,4)},nt) ;saving results to common block
  endif else begin
    pos=mvn_sep_fov.pos
    rad=mvn_sep_fov.rad
    qrot=mvn_sep_fov.qrot
    qrot_iau=mvn_sep_fov.qrot_iau
  endelse
  from_frame='IAU_MARS'
  zdir=[0.,0.,1.] ;Mars North pole in IAU_MARS (oblate spheroid symmetry axis)
  posmnp=spice_vector_rotate(zdir,times,from_frame,toframe,check_objects=check_maven,/force_objects) ;Mars North pole in sep1 coordinates

  posmar=(replicate(1.,3)#rad.mar)*pos.mar
  sur=mvn_sep_fov_mars_incidence(rmars,posmar,[[1.,0,0],[0,0,1],[-1,0,0],[0,0,-1]]) ;mars surface coordinates intercepting centers of fov of sep[1f,2f,1r,2r]

  ;m1=[0.102810,0.921371,0.374841] ;crab nebula coordinates in J2000 from NAIF
  ;cbnm1rd=[05h 34m 31.94s , +22° 00′ 52.2″] ;Crab Nebula (M1) Right Ascention/Declination
  ;scox1rd=[16h 19m 55.07s , −15° 38' 24.8"] ;Scorpius X-1 (from wiki)
  ;cygx1rd=[19h 58m 21.67s , +35° 12′ 05.8″] ;Cygnus X-1
  cm1r=!const.pi*[360.*(5.0+34./60.+31.94/60./60.)/24.,+(22.+00./60.+52.2/60./60.)]/180. ;radians
  ;cm1r=!const.pi*[360.*(19.+13./60.+03.48/60./60.)/24.,+(19.+46./60.+24.6/60./60.)]/180. ;GRB221009A
  sx1r=!const.pi*[360.*(16.+19./60.+55.07/60./60.)/24.,-(15.+38./60.+24.8/60./60.)]/180.
  cx1r=!const.pi*[360.*(19.+58./60.+21.67/60./60.)/24.,+(35.+12./60.+05.8/60./60.)]/180.
  cm1=[cos(cm1r[0])*cos(cm1r[1]),sin(cm1r[0])*cos(cm1r[1]),sin(cm1r[1])] ;should be equal to m1 above
  sx1=[cos(sx1r[0])*cos(sx1r[1]),sin(sx1r[0])*cos(sx1r[1]),sin(sx1r[1])]
  cx1=[cos(cx1r[0])*cos(cx1r[1]),sin(cx1r[0])*cos(cx1r[1]),sin(cx1r[1])]
  pos.cm1=quaternion_rotation(cm1,qrot,/last_ind)
  pos.sx1=quaternion_rotation(sx1,qrot,/last_ind)
  pos.ram=quaternion_rotation(pos.ram,qrot,/last_ind) ;MAVEN velocity unit vector wrt Mars in SEP1 frame
  ;  pos.cx1=quaternion_rotation(cx1,qrot,/last_ind)

  if keyword_set(sep1_svy) then begin
    map1=mvn_sep_get_bmap(9,1)
    if mvn_sep_fov0.arc then begin
      sep1=*(sep1_arc.x)
      sep2=*(sep2_arc.x)
    endif else begin
      sep1=*(sep1_svy.x)
      sep2=*(sep2_svy.x)
    endelse
    ndet=n_elements(mvn_sep_fov0.detlab)
      for idet=0,ndet-1 do begin
        ind=where(map1.name eq mvn_sep_fov0.detlab[idet])
        mvn_sep_fov.crl[0,idet]=interpol(total(sep1.data[ind[0]+0:ind[0]+5],1)/sep2.delta_time,sep1.time,times,/nan) ;low  energy count rate
        mvn_sep_fov.crh[0,idet]=interpol(total(sep1.data[ind[0]+6:ind[0]+9],1)/sep1.delta_time,sep1.time,times,/nan) ;high energy count rate (for hi background elimination)
        mvn_sep_fov.crl[1,idet]=interpol(total(sep2.data[ind[0]+0:ind[0]+5],1)/sep2.delta_time,sep2.time,times,/nan)
        mvn_sep_fov.crh[1,idet]=interpol(total(sep2.data[ind[0]+6:ind[0]+9],1)/sep2.delta_time,sep2.time,times,/nan)
      endfor
    sep1_att=exp(interpol(alog(sep1.att),sep1.time,times,/nan))
    sep2_att=exp(interpol(alog(sep2.att),sep2.time,times,/nan))
    att=transpose([[sep1_att],[sep2_att]])
  endif else att=replicate(1.,[2,nt])

  occalt=mvn_sep_fov0.occalt ;crossing altitude (km) maximum altitude for along path integration
  occos=cos(!dtor*15.) ;within 15 degrees of detector fov center
  alt=rad.mar-rmars ;altitude (km)
  npos=n_tags(pos)
  for ipos=0,npos-1 do begin
    pdm.(ipos)=total(pos.(ipos)*pos.mar,1)
    tal[0,*].(ipos)=transpose(rad.mar*sqrt(1.d0-pdm.(ipos)^2)-rmars) ;temporary inaccurate tangent altitude
    wpdmlt0=where(pdm.(ipos) lt 0.,/null) ;where line of sight away from Mars
    if n_elements(wpdmlt0) gt 0 then tal[0,wpdmlt0].(ipos)=transpose(alt[wpdmlt0]) ;set tangent altitude equal to altitude
    horcro=((tal[0,*].(ipos)-occalt[1])*shift((tal[0,*].(ipos)-occalt[1]),1)) lt 0. ;crossed the occalt
    ;horcro=tal[0,*].(ipos) gt occalt[0] and tal[0,*].(ipos) lt occalt[1] ;within the occalt
    occ.(ipos)=0
    occ[where((pos[0,*].(ipos) gt +occos) and horcro and att[0,*] eq 1.,/null)].(ipos)=1 ;sep1f
    occ[where((pos[2,*].(ipos) gt +occos) and horcro and att[1,*] eq 1.,/null)].(ipos)=2 ;sep2f
    occ[where((pos[0,*].(ipos) lt -occos) and horcro and att[0,*] eq 1.,/null)].(ipos)=3 ;sep1r
    occ[where((pos[2,*].(ipos) lt -occos) and horcro and att[1,*] eq 1.,/null)].(ipos)=4 ;sep2r
  endfor
  pdm.mar=sqrt(1.-(rmars/rad.mar)^2) ;dot product of mars surface by mars center
  pdm.ram=sqrt(1.-((rmars+occalt[1])/rad.mar)^2) ;dot product of mars occalt by mars center
  ;tal.mar=alt
  ;occtimes=where(occ.sx1 ne 0,/null)

  ones3=replicate(1d,3)
  talsx1=(ones3#rad.mar)*((ones3#pdm.sx1)*pos.sx1-pos.mar) ;sco x-1 tangent altitude vector from Mars center (km)
  wpdmlt0=where(pdm.sx1 lt 0.,/null) ;where line of sight away from Mars
  if n_elements(wpdmlt0) gt 0 then talsx1[*,wpdmlt0]=-posmar[*,wpdmlt0] ;set tangent altitude equal to altitude

  talsza=total(talsx1*pos.sun,1)/sqrt(total(talsx1^2,1)) ;cosine of solar zenith angle of tangent altitude
  tdz=total(talsx1*posmnp,1)/sqrt(total(talsx1^2,1)) ;cosine of polar angle (90-latitude) of tangent altitude
  posdawn=transpose(crossp2(transpose(posmnp),transpose(pos.sun)))
  posdawn/=replicate(1.,3)#sqrt(total(posdawn^2,1))
  lst=12.+12./!pi*atan(-total(talsx1*posdawn,1),total(talsx1*pos.sun,1)) ;!pi+atan(-y,-x) = atan(y,x)
  store_data,'mvn_sep_xray_tanalt_sza',times,!radeg*acos(talsza)
  store_data,'mvn_sep_xray_tanalt_lat',times,90.-!radeg*acos(tdz)
  store_data,'mvn_sep_xray_tanalt_lst',times,lst

  ;cspice_bodvrd, 'MARS', 'RADII', 3, radii ;rmars=[3396.2,3396.2,3376.2] km
  ;re = total(radii[0:1])/2. ;equatorial radius (km)
  ;rp = radii[2] ;polar radius (km)
  ;mdz=-total(pos.mar*posmnp,1) ;maven dot mars north pole (cosine of polar angle)
  ;radmnp=sqrt((re^4*(1.-mdz^2)+rp^4*mdz^2)/(re^2*(1.-mdz^2)+rp^2*mdz^2)) ;radius of sub-maven surface point (km)
  ;talmnp=sqrt((re^4*(1.-tdz^2)+rp^4*tdz^2)/(re^2*(1.-tdz^2)+rp^2*tdz^2)) ;radius of sub-tangent altitude point (km)

  posmar_iau=quaternion_rotation(-pos.mar,qrot_iau,/last_ind)*(ones3#rad.mar) ;MAVEN position from Mars center in IAU_MARS
  talsx1_iau=quaternion_rotation(  talsx1,qrot_iau,/last_ind)
  mvn_altitude,cart=posmar_iau,datum='sphere',result=adat
  tal[0,*].mar=transpose(adat.alt)
  mvn_altitude,cart=posmar_iau,datum='ellips',result=adat
  tal[1,*].mar=transpose(adat.alt)
  mvn_altitude,cart=posmar_iau,datum='areoid',result=adat
  tal[2,*].mar=transpose(adat.alt)
  mvn_altitude,cart=talsx1_iau,datum='sphere',result=adat
  tal[0,*].sx1=transpose(adat.alt)
  mvn_altitude,cart=talsx1_iau,datum='ellips',result=adat
  tal[1,*].sx1=transpose(adat.alt)
  mvn_altitude,cart=talsx1_iau,datum='areoid',result=adat
  tal[2,*].sx1=transpose(adat.alt)
  store_data,'mvn_sep_xray_tanalt_lat2',times,adat.lat
  store_data,'mvn_sep_xray_tanalt_lon',times,adat.lon

  mvn_sep_fov.pos=pos
  mvn_sep_fov.tal=tal
  mvn_sep_fov.pdm=pdm
  mvn_sep_fov.rad=rad
  mvn_sep_fov.occ=occ
  mvn_sep_fov.att=att
  mvn_sep_fov.qrot=qrot
  mvn_sep_fov.qrot_iau=qrot_iau
  mvn_sep_fov.time=times
  mvn_sep_fov.sur=sur

  dprint,'successfully saved sep fov data to mvn_sep_fov common block'
  dprint,'elapsed time (s):',systime(1)-t1

end