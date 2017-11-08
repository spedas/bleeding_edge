;20160404 Ali
;solves pickup ion trajectories analytically
;to be called by mvn_pui_model

pro mvn_pui_solver

@mvn_pui_commonblock.pro ;common mvn_pui_common

onesnp=replicate(1.,pui0.np)

mag=pui.data.mag.mso ;magnetic field in MSO (T)
vsw=1e3*pui.data.swi.swim.velocity_mso ;solar wind velocity in MSO (m/s)
usw=sqrt(total(vsw^2,1)) ; solar wind speed (m/s)
scp=pui.data.scp ;spacecraft position (m)

magx=onesnp#mag[0,*]
magy=onesnp#mag[1,*]
magz=onesnp#mag[2,*]
vswx=onesnp#vsw[0,*]
vswy=onesnp#vsw[1,*]
vswz=onesnp#vsw[2,*]
scpx=onesnp#scp[0,*]
scpy=onesnp#scp[1,*]
scpz=onesnp#scp[2,*]
uswn=onesnp#usw

;rotate coordinates so that Usw becomes anti-sunward (align Usw with -X)
bx=-[vswx*magx+vswy*magy+vswz*magz]/uswn
by=-[vswx*magy-vswy*magx+vswz*(vswy*magz-vswz*magy)/(uswn-vswx)]/uswn
bz=-[vswx*magz-vswz*magx-vswy*(vswy*magz-vswz*magy)/(uswn-vswx)]/uswn
Btot=sqrt(bx^2+by^2+bz^2); magnetic field magnitude (T)
;dbtot=btot-pui.data.mag.tot ;error in Btot from rotation (should be negligible, otherwise something's wrong!)
tub=acos(-bx/Btot); theta Usw,B (radians) angle between Usw and B (cone angle)
phiub=atan(by,bz); phi Usw,B (radians) solar wind magnetic field clock angle
tez=atan(-bz,by); theta E,z  (radians) solar wind electric field clock angle

sintub=sin(tub)
costub=cos(tub)
sintez=sin(tez)
costez=cos(tez)

qe=1.602e-19; electron charge (C or J/eV)
mp=1.67e-27; proton mass (kg)
;mamu=16; mass of [H=1 C=12 N=14 O=16] (amu)
mi=pui0.mamu[pui0.msub]*mp; pickup ion mass (kg)
fg=qe*Btot/mi; gyro-frequency (rad/s)
tg=2.*!pi/fg; gyro-period (s)
rg=uswn*sintub/fg; gyro-radius (m)
kemax=.5*mi*((2.*usw*sintub[0,*])^2)/qe; pickup ion maximum energy (eV)

;ngps=0.999; number of gyro-periods to be simulated
dt=pui0.ngps[pui0.msub]*tg/pui0.np; time increment (s)
t=dt*(findgen(pui0.np)#replicate(1.,pui0.nt)); time (s)

omegat=fg*t ;omega*t (radians)
sinomt=sin(omegat) ;sin(omega*t)
cosomt=cos(omegat) ;cos(omega*t)
rgfg=rg*fg ;r*omega (m/s)
atot=rg*fg*fg; ;r*omega2 or acceleration (m/s2)

;solving trajectories assuming the electric field E is aligned with +Z
r1x=-rg*sintub*(sinomt-omegat); starting point of pickup ions (m)
r1y=-rg*costub*(sinomt-omegat);
r1z=-rg*(1-cosomt);
v1x=+rgfg*sintub*(cosomt-1); velocity when reaching detector (m/s)
v1y=+rgfg*costub*(cosomt-1);
v1z=+rgfg*sinomt
a1x=-atot*sintub*sinomt; acceleration when reaching detectotr (m/s2)
a1y=-atot*costub*sinomt
a1z=+atot*cosomt

;rotate the coordinates about the x-axis by tez (bring E back to its original direction)
r2x=+r1x
r2y=+r1y*costez+r1z*sintez
r2z=-r1y*sintez+r1z*costez
v2x=+v1x
v2y=+v1y*costez+v1z*sintez
v2z=-v1y*sintez+v1z*costez

;rotate the coordinates back to vsw (inverse of what was done to B at the beginning)
r3x=scpx-(vswx*r2x-vswy*r2y-vswz*r2z)/uswn
r3y=scpy-(vswx*r2y+vswy*r2x+vswz*(vswy*r2z-vswz*r2y)/(uswn-vswx))/uswn
r3z=scpz-(vswx*r2z+vswz*r2x-vswy*(vswy*r2z-vswz*r2y)/(uswn-vswx))/uswn
v3x=    -(vswx*v2x-vswy*v2y-vswz*v2z)/uswn
v3y=    -(vswx*v2y+vswy*v2x+vswz*(vswy*v2z-vswz*v2y)/(uswn-vswx))/uswn
v3z=    -(vswx*v2z+vswz*v2x-vswy*(vswy*v2z-vswz*v2y)/(uswn-vswx))/uswn

rtot=sqrt(r3x^2+r3y^2+r3z^2); radial distance of pickup ions from the center of Mars (m)
vtot=sqrt(v3x^2+v3y^2+v3z^2); velocity of pickup ions (m/s)
dv=atot*dt ;pickup ion velocity increment (m/s)
pui2.dr=vtot*dt ;pickup ion distance increment (m)
pui2.ke=.5*mi/qe*(vtot^2); kinetic energy of pickup ions at detector (eV)
pui2.de=mi/qe*(v1x*a1x+v1y*a1y+v1z*a1z)*dt ;energy increment (eV)
pui2.mv=mi*vtot; momentum of pickup ions at detector (kg m/s)
pui2.rtot=rtot
pui2.vtot=vtot

;saving the results into arrays of structures
pui.model[pui0.msub].params.fg=reform(fg[0,*])
pui.model[pui0.msub].params.tg=reform(tg[0,*])
pui.model[pui0.msub].params.rg=reform(rg[0,*])
pui.model[pui0.msub].params.kemax=kemax
pui.model[pui0.msub].rv=transpose(reform([r3x,r3y,r3z,v3x,v3y,v3z],[pui0.np,6,pui0.nt]),[1,0,2])
;stop
end