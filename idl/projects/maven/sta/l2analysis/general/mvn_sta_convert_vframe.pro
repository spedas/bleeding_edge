;+
;NAME:	
;	mvn_sta_transform_velocity
;	
;	NOTES: 2020-03-26: The routine converts the STATIC energy table to velocities, using the mass value in the data structure. The routine then 
;	calculates the vx, vy and vz components of each energy step, in the STATIC instrument frame. The sc velocity components (vx, vy, vz) are then
;	subtracted from these. The routine then re-calculates phi and theta, so that "rammed ions" in the ram direction are moved to the back end of the 
;	instrument, once the sc velocity is accounted for. The total velocity is then re-calculated for each energy step. This then means that the minimum
;	velocity obseved in the RAM direction is the (spacecraft velocity - min original energy table). In the anti-ram direction, the minimum velocity is
;	(spacecraft velocity + min original energy table). 
;	This means that instead of the total velocity descending each sweep, there is a minimum for the RAM direction, and the velocity increases 
;	again at the lowest energies. The velocities remain descending in the anti-ram direction, where the sc velocity acts to "increase" the energy
;	of observed ions. This can cause weird things when plotting, because plots typically compress across the phi and theta directions, leading to
;	weird looking energy tables.
;	
;	Notes:
;	This is based on convert_vframe, which is written for electrons. This routine will work for ions, and will use the data.mass_arr
;	structure when calculating velocities so that they are mass dependent. 
;	
;	
;	Note - for the above case when the sc velocity is greater than the ion energy (eg at periapsis), this code should be not be used 
;	- uncertainties are large.
;
;EXAMPLE:
;- Routine is currently being tested by CMF. Use in the following way:
;
;timespan, '2018-03-03', 1. ;set timespan
;kk = mvn_spice_kernels(/load)  ;load SPICE kernels. mvn_sta_frame_transform will also do this if no kernels are loaded, but it
;                               ;doesn't check the time range of loaded kernels - it goes on the last timerange set by timespan.
;mvn_sta_l2_load, sta_apid='d0' ;load STATIC data that has 3D information (ce, cf, d0 or d1).
;mvn_sta_l2_tplot               ;put into tplot
;dat = mvn_sta_get_d0()         ;use ctime to pick a timestamp to look at. dat is now the STATIC data structure at that time.
;
;result = mvn_sta_frame_transform(dat, /sc_vector)  ;apply sc velocity correction to dat structure.
;                                                   ;result is the new STATIC data structure, with updated theta, phi and energy arrays.
;
;-


;+
;Calculate ion velocity using mass and energy.
;
;INPUTS:
;energy: data.energy array from a STATIC data structure. Units of eV.
;mass: data.mass_arr from a STATIC data structure. Units of AMU. Matching dimensions to energy.
;
;
;OUTPUT:
;Total velocity (from E=0.5*m*v^2) in the same array dimension as data.energy. Units of km/s.
;
;
;KEYWORDS:
;reverse: if set, provide velocities as the "energy" input, and routine will return the corresponding energies in eV. In this
;         case, input velocities in units of km/s.
;-

function mvn_sta_velocity, energy, mass, reverse=reverse

;E=0.5 * m * v^2
qq=1.6E-19
mp = 1.67E-27

if keyword_set(reverse) then vv = (0.5 * (mass*mp) * energy * energy * 1E6) / qq else $  ;calculate energy in eV
                             vv = sqrt(2.*energy*qq/(mass*mp)) / 1000.  ;km/s

return, vv

end


;+
;
;PROCEDURE:   transform_velocity,  vel, theta, phi,  deltav
;PURPOSE:  used by the convert_vframe routine to transform arrays of velocity
;    thetas and phis by the offset deltav
;INPUT:
;  vel:  array of velocities
;  theta: array of theta values
;  phi:   array of phi values
;  deltav: [vx,vy,vz]  (transformation velocity)
;KEYWORDS:
;	vx,vy,vz:	return vx,vy,vz separately as well as in vector form
;
;CREATED BY:	Davin Larson
;LAST MODIFICATION:	2020-03-26 CMF
;-
pro mvn_sta_transform_velocity, vel,theta,phi,deltav, $
   VX=vx,VY=vy,VZ=vz,sx=sx,sy=sy,sz=sz

vel_in = vel  ;make a copy for checking
theta_in = theta
phi_in = phi

c = cos(!dpi/180.*theta)
sx = c * cos(!dpi/180.*phi)
sy = c * sin(!dpi/180.*phi)
sz = sin(!dpi/180.*theta)

vx = (vel*sx) - deltav(0)
vy = (vel*sy) - deltav(1)
vz = (vel*sz) - deltav(2)

vxxyy = vx*vx + vy*vy
vel = sqrt(vxxyy + vz*vz)
phi = 180./!dpi*atan(vy,vx)
phi = phi + 360.d*(phi lt 0)
theta = 180./!dpi*atan(vz/sqrt(vxxyy))

return
end

;+
;NAME:	
;	mvn_sta_convert_vframe: based on convert_vframe, which is for electrons. mvn_sta_convert_vframe is modified for ions. Some
;	of the fancy bells and whistles have been removed to keep things simple.
;	
;	Notes: the routine will convert the input data structure to units of df to do the frame conversion. The routine will then
;	convert units back to the inputs ones on output.
;
;FUNCTION:  convert_vframe ,  dat,  velocity
;PURPOSE:   Change velocity frames 
;INPUT: 
;  tdata: 3d STATIC data structure, from eg mvn_sta_get_d0() (must be ce, cf, d0, d1)
;  velocity: velocity vector in the STATIC isntrument frame, to be used in the frame transformation [VX,VY,VZ]. 
;            This can be the spacecraft velocity, the plasma flow velocity, or both combined. Units of km/s.
;OUTPUT:  3d data structure.  Data will be in the coordinate frame based upon the input vframe.
;         - The Mars frame if spacecraft velocity is used.
;         - The plasma frame if spacecraft velocity and plasma bulk flow velocity are used.
;    (frame transform is done in units of df, but the output is put back to the input units)
;    
;KEYWORDS:
;
;CREATED BY:	Davin Larson, edited by CMF
;
;-

function  mvn_sta_convert_vframe, tdata, vframe  

if tdata.valid eq 0 then  begin
   dprint, 'Invalid Data' 
   return,tdata
endif

data = tdata  ;make a copy

oldunits = tdata.units_name  ;record input units

mvn_sta_convert_units, data,'df'   ;use STATIC routine to convert to df

energy = data.energy + data.sc_pot    ;NOTE: this is +ve for ions: a negative sc pot accelerates ion, so their true energy is less.
bad = where(data.energy lt 0.,nbad)   ;find negative energies
;bad = where(data.energy lt sc_pot*1.3,nbad)
if nbad gt 0 then data.data[bad] = 0.  ;remove negative energies - use 0 rather than NaN to avoid breaking anything further on?

vel = mvn_sta_velocity(energy, data.mass_arr)   ;velocity at each energy/mass step, in km/s
;vel = velocity(energy,data.mass)
theta = data.theta
phi = data.phi

vel_old = vel ;copy
theta_old = theta
phi_old = phi

mvn_sta_transform_velocity,vel,theta,phi,vframe,sx=sx,sy=sy,sz=sz

;code won't change dtheta or dphi. I think this is ok? Use 2018-03-03 for testing

data.energy = mvn_sta_velocity(/reverse,vel,data.mass_arr)  ;update energy table with new velocities, in eV.
data.theta = theta  ;update new theta and phi values 
data.phi = phi

mvn_sta_convert_units, data, oldunits  ;convert back to original units

return,data
end

;%%%%% separate all routines into separate .pro files once working



