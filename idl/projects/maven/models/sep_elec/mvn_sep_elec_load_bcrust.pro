;20171117 Ali
;load Brtp and get Bxyz in IAU_MARS

function mvn_sep_elec_load_bcrust

  restore,'/home/rahmati/Desktop/crustalb/Morschhauser_spc_dlat0.25_delon0.25_dalt5.sav' ;crustal field model (nT)
  brtp=transpose(morschhauser.b,[0,1,3,2]) ;[r,t,p]
  rad=morschhauser.radius ;r
  lat=morschhauser.latitude ;t
  lon=morschhauser.longitude ;p
  t=!dtor*(90.-lat)
  p=!dtor*lon
  nr=n_elements(rad)
  nt=n_elements(t)
  np=n_elements(p)
  x=sin(t)#cos(p)
  y=sin(t)#sin(p)
  z=cos(t)#replicate(1.,n_elements(p))
  rhat=[[[x]],[[y]],[[z]]]
  ;rtot=sqrt(total(rhat^2,3)) ;check (should be 1)

  dim3=[nt,np,3]
  dim4=[nt,np,3,nr]
  phat2=replicate(0.,dim3)
  that2=phat2
  for it=0,nt-1 do begin
    phat3=crossp2([0.,0.,1.],reform(rhat[it,*,*]))
    that2[it,*,*]=crossp2(phat3,reform(rhat[it,*,*]))
    phat2[it,*,*]=phat3
  endfor
  phattot=sqrt(total(phat2^2,3))
  thattot=sqrt(total(that2^2,3))
  phat=phat2/rebin(phattot,dim3)
  that=that2/rebin(thattot,dim3)

  rhat4=transpose(rebin(rhat,dim4),[2,3,0,1])
  that4=transpose(rebin(that,dim4),[2,3,0,1])
  phat4=transpose(rebin(phat,dim4),[2,3,0,1])

  dim=[3,nr,np,nt]
  br=rebin(brtp[0,*,*,*],dim)
  bt=rebin(brtp[1,*,*,*],dim)
  bp=rebin(brtp[2,*,*,*],dim)
  bxyz=br*rhat4+bt*that4+bp*phat4

  return,bxyz
  end