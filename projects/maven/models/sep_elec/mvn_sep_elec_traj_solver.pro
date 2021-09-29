;20171114 Ali
;analytic electron trajectory solver
;inputs: mag,v0,drmax
;outputs:v1,dr,drpara
;
pro mvn_sep_elec_traj_solver,mag,v0,drmax,v1,dr,dt,drpara,drperp,dtminsub

  magtot=sqrt(total(mag^2)) ;nT
  if magtot eq 0. then magtot=1e-7 ;very small mag (nT) to prevent div by 0
  vtot=sqrt(total(v0^2)) ;km/s
  vparahat=mag/magtot ;parallel velocity unit vector
  vpara=total(vparahat*v0) ;parallel speed (km/s) Note: can be negative! meaning direction is opposite of mag
  vperp=sqrt(vtot^2-vpara^2) ;perpendicular speed (km/s)
  if vperp eq 0. then vperp=1e-7 ;very small speed (km/s) to prevent div by 0
  vparadir=vpara*vparahat ;parallel velocity direction (km/s)
  vperpdir=v0-vparadir ;perp velocity direction (km/s)
  vperphat=vperpdir/vperp ;perp velocity unit vector
  vperptot=sqrt(total(vperpdir^2)) ;should be equal to vperp (check)

  me=float(!const.me) ;electron mass (kg)
  qe=float(!const.e) ;electron charge (C)
  cc=float(!const.c/1e3) ;speed of light (km/s)
  gama=1./sqrt(1.-(vtot/cc)^2) ;relativistic gamma
  gyroperiod2pi=gama*me/qe/(1e-9*magtot) ;gyro-period/2pi (s)
  gyrofreq=1./gyroperiod2pi ;gyro-frequency (rad/s)
  gyroradius=gyroperiod2pi*vperp ;gyro-radius (km)

  force=crossp(v0,mag) ;centripetal force acting on an electron going backward in time!
  forcetot=sqrt(total(force^2)) ;total force
  if forcetot eq 0. then forcetot=1e-7 ;to prevent div by 0
  forcehat=force/forcetot ;force unit vector

;  drmax=10. ;maximum displacement (km)
  dtpara=drmax/abs(vpara) ;para dt (s)
  dtperp=drmax/abs(vperp) ;perp dt (s)
  dt=min([dtpara,dtperp,gyroperiod2pi/3.],dtminsub,/nan) ;smallest dt (s)
  theta=gyrofreq*dt ;omega*t (rad)
  vperpr=vperp*sin(theta) ;perp speed in the force (radial) direction (km/s)
  vperpt=vperp*cos(theta) ;perp speed in the tangential (initial vperp) direction
  drpara=vpara*dt ;para displacement along the field line (km)
  drperp=vperp*dt ;~perp displacement (km)
  drperpr=gyroradius*(1-cos(theta)) ;perp displacement in the force (radial) direction (km)
  drperpt=gyroradius*sin(theta) ;perp displacement in the tangential (initial vperp) direction (km)
  v1=vparadir+vperpr*forcehat+vperpt*vperphat ;final velocity (km/s)
  dr=drpara*vparahat+drperpr*forcehat+drperpt*vperphat ;displacement (km)

end