;20180205 Ali
;change reference frame for crustal field model
;
pro mvn_sep_elec_rotate_bcrust

  restore,'/home/rahmati/Desktop/crustalb/bxyziau.dat' ;Bxyz in IAU_MARS

  ut=time_double('2017-9-13/3:00')
  from_frame='MSO'
  to_frame='IAU_MARS'
  qrot1=spice_body_att(from_frame,to_frame,ut,/quaternion,check_object=check_objects,force_objects=force_objects,verbose=verbose)
  qrot2=spice_body_att(to_frame,from_frame,ut,/quaternion,check_object=check_objects,force_objects=force_objects,verbose=verbose)
  rmars=3390 ;km
  np=360 ;phi
  nt=180 ;theta
  bcr=replicate(0.,[3,np,nt])
  for ip=0,np-1 do begin
    for it=0,nt-1 do begin
      x0=[ip,it-90.,rmars+150.] ;150 km altitude [longitude:-180 to 180,latitude: -90 to 90,radius] or [p,t,r]
      x1=cv_coord(from_sphere=x0,/to_rect,/degrees) ;to rectangular coordinates
      x2=quaternion_rotation(x1,qrot1,/last_ind) ;from MSO to IAU_MARS
      b1=mvn_sep_elec_peri_bcrust(x2,bxyz,lowres=lowres,mhd=mhd) ;crustal field model (nT) in IAU_MARS
      b2=quaternion_rotation(b1,qrot2,/last_ind) ;from IAU_MARS to MSO
      bcr[*,ip,it]=b2
    endfor
  endfor
  p=image(reform(bcr[0,*,*]),rgb=colortable(70,/reverse),margin=0,min=-100,max=100)
  p=colorbar('Crustal Field (nT) at 150 km')

stop
end