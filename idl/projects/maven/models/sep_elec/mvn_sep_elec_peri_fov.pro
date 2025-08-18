;20171117 Ali
;SEP FOV elements in IAU_MARS

function mvn_sep_elec_peri_fov,times,frame=frame

dfov=tan(!dtor*20.) ;20 degrees from sep fov center
nt=n_elements(times)
xdir=[1.,0.,0.]#replicate(1.,nt) ;X-direction (SEP front FOV)
sep1fov=transpose(float(spice_vector_rotate(xdir,times,'MAVEN_SEP1',frame,check_objects='MAVEN_SPACECRAFT',/force_objects))); sep1 look direction
sep2fov=transpose(float(spice_vector_rotate(xdir,times,'MAVEN_SEP2',frame,check_objects='MAVEN_SPACECRAFT',/force_objects))); sep2 look direction
sepyfov=crossp2(sep1fov,sep2fov)
sep11fov=sep1fov+dfov*sep2fov
sep13fov=sep1fov-dfov*sep2fov
sep12fov=sep1fov+dfov*sepyfov
sep14fov=sep1fov-dfov*sepyfov
sep21fov=sep2fov-dfov*sep1fov
sep23fov=sep2fov+dfov*sep1fov
sep22fov=sep2fov+dfov*sepyfov
sep24fov=sep2fov-dfov*sepyfov

fov1=[sep1fov,sep11fov,sep12fov,sep13fov,sep14fov]
fov2=[sep2fov,sep21fov,sep22fov,sep23fov,sep24fov]
fov3=[fov1,-fov1,fov2,-fov2] ;['1A','1B','2A','2B']
dim=[nt,5,4,3] ;[nt,nfov,nsep,3]
fov4=reform(fov3,dim)
fov4tot=sqrt(total(fov4^2,4))
fov=fov4/rebin(fov4tot,dim)
;fovtot=sqrt(total(fov^2,4)) ;test

return,fov

end