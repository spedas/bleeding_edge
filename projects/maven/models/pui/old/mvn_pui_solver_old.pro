;20160404 Ali
;solves pickup ion trajectories analytically
;to be called by mvn_pui_model

pro mvn_pui_solver_old,mamu=mamu,np=np,ntg=ntg,msub=msub,savetraj=savetraj

@mvn_pui_commonblock.pro ;common mvn_pui_common

inn=pui0.time_steps
onesnp=replicate(1.,np)

mag=transpose(pui.data.mag.mso) ;magnetic field in MSO (T)
vsw=1e3*transpose(pui.data.swi.swim.velocity_mso) ;solar wind velocity in MSO (m/s)
usw=sqrt(total(vsw^2,2)) ; solar wind speed (m/s)
scp=transpose(pui.data.scp) ;spacecraft position (m)

magx=mag[*,0]#onesnp
magy=mag[*,1]#onesnp
magz=mag[*,2]#onesnp
vswx=vsw[*,0]#onesnp
vswy=vsw[*,1]#onesnp
vswz=vsw[*,2]#onesnp
scpx=scp[*,0]#onesnp
scpy=scp[*,1]#onesnp
scpz=scp[*,2]#onesnp
uswn=usw#onesnp

;rotate coordinates so that Usw becomes anti-sunward (align Usw with -X)
bx=-[vswx*magx+vswy*magy+vswz*magz]/uswn
by=-[vswx*magy-vswy*magx+vswz*(vswy*magz-vswz*magy)/(uswn-vswx)]/uswn
bz=-[vswx*magz-vswz*magx-vswy*(vswy*magz-vswz*magy)/(uswn-vswx)]/uswn
Btot=sqrt(bx^2+by^2+bz^2); magnetic field magnitude (T)
;dbtot=btot[*,0]-pui.data.mag.tot ;error in Btot from rotation (should be negligible, otherwise something's wrong!)
tub=acos(-bx/Btot); theta Usw,B (radians) angle between Usw and B (cone angle)
phiub=atan(by,bz); phi Usw,B (radians) solar wind magnetic field clock angle
tez=atan(-bz,by); theta E,z (radians) solar wind electric filed clock angle

sintub=sin(tub)
costub=cos(tub)
sintez=sin(tez)
costez=cos(tez)

qe=1.602e-19; %electron charge (C or J/eV)
mp=1.67e-27; %proton mass (kg)
;mamu=16; %mass of [H=1 C=12 N=14 O=16] (amu)
mi=mamu*mp; %pickup ion mass (kg)
fg=qe*Btot/mi; %gyro-frequency (rad/s)
tg=2.*!pi/fg; %gyro-period (s)
rg=uswn*sintub/fg; %gyro-radius (m)
kemax=.5*mi*((2.*usw*sintub[*,0])^2)/qe; %pickup ion maximum energy (eV)

;ntg=0.999; number of gyro-periods to be simulated
dt=ntg*tg/np; %time increment (s)
t=dt*(replicate(1.,inn)#findgen(np)); %time (s)

omegat=fg*t ;omega*t (radians)
sinomt=sin(omegat) ;sin(omega*t)
cosomt=cos(omegat) ;cos(omega*t)
rgfg=rg*fg ;r*omega (m/s)
axyz=rg*fg*fg; ;r*omega2 or acceleration (m/s2)

;solving trajectories assuming the electric field E is aligned with +Z
r1x=-rg*sintub*(sinomt-omegat); starting point of pickup ions (m)
r1y=-rg*costub*(sinomt-omegat);
r1z=-rg*(1-cosomt);
v1x=+rgfg*sintub*(cosomt-1); %velocity when reaching detector (m/s)
v1y=+rgfg*costub*(cosomt-1);
v1z=+rgfg*sinomt
a1x=-axyz*sintub*sinomt; %acceleration when reaching detectotr (m/s2)
a1y=-axyz*costub*sinomt
a1z=+axyz*cosomt

;rotate the coordinates about the x-axis by tez (bring E back to its original direction)
r2x=r1x
r2y=+r1y*costez+r1z*sintez
r2z=-r1y*sintez+r1z*costez
v2x=v1x
v2y=+v1y*costez+v1z*sintez
v2z=-v1y*sintez+v1z*costez

;rotate the coordinates back to vsw (inverse of what was done to B at the beginning)
r3x=scpx-(vswx*r2x-vswy*r2y-vswz*r2z)/uswn
r3y=scpy-(vswx*r2y+vswy*r2x+vswz*(vswy*r2z-vswz*r2y)/(uswn-vswx))/uswn
r3z=scpz-(vswx*r2z+vswz*r2x-vswy*(vswy*r2z-vswz*r2y)/(uswn-vswx))/uswn
v3x=    -(vswx*v2x-vswy*v2y-vswz*v2z)/uswn
v3y=    -(vswx*v2y+vswy*v2x+vswz*(vswy*v2z-vswz*v2y)/(uswn-vswx))/uswn
v3z=    -(vswx*v2z+vswz*v2x-vswy*(vswy*v2z-vswz*v2y)/(uswn-vswx))/uswn

rxyz=sqrt(r3x^2+r3y^2+r3z^2); %radial distance of pickup ions from the center of Mars (m)
vxyz=sqrt(v3x^2+v3y^2+v3z^2); %velocity of pickup ions (m/s)
pui2.drxyz=vxyz*dt ;pickup ion distance increment (m)
dvxyz=axyz*dt ;pickup ion velocity increment (m/s)
pui2.ke=.5*mi/qe*(vxyz^2); %kinetic energy of pickup ions at detector (eV)
pui2.de=mi/qe*(v1x*a1x+v1y*a1y+v1z*a1z)*dt ;energy increment (eV)
pui2.mv=mi*vxyz; momentum of pickup ions at detector (kg m/s)

;saving the results into arrays of structures
pui.model[msub].params.fg=fg[*,0]
pui.model[msub].params.tg=tg[*,0]
pui.model[msub].params.rg=rg[*,0]
pui.model[msub].params.kemax=kemax

if keyword_set(savetraj) then begin
  pui.model[msub].rv[0]=transpose(r3x)
  pui.model[msub].rv[1]=transpose(r3y)
  pui.model[msub].rv[2]=transpose(r3z)
  pui.model[msub].rv[3]=transpose(v3x)
  pui.model[msub].rv[4]=transpose(v3y)
  pui.model[msub].rv[5]=transpose(v3z)
endif

pui2.rv[0]=r3x
pui2.rv[1]=r3y
pui2.rv[2]=r3z
pui2.rv[3]=v3x
pui2.rv[4]=v3y
pui2.rv[5]=v3z
pui2.rxyz=rxyz
pui2.vxyz=vxyz


;stop
end