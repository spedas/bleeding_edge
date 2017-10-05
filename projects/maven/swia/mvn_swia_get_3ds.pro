;+
;FUNCTION: 
;	MVN_SWIA_GET_3DS
;PURPOSE: 
;	Construct a standard 3-d data structure for SWIA spectra data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE: 
;	Result = MVN_SWIA_GET_3DS(Time, INDEX=INDEX)
;OPTIONAL INPUTS: 
;	Time: A double unix_time to return a packet for - otherwise uses index or clicks
;KEYWORDS:
;	INDEX: Gets data at this index value in the common block (useful for looping)
;	START: Gets data at the first point in the common block (useful for looping)
;OUTPUTS:
;	Returns a standard 3-d data structure that will work with plot3d, spec3d, n_3d, etc.
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-04-17 14:32:39 -0700 (Thu, 17 Apr 2014) $
; $LastChangedRevision: 14853 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_get_3ds.pro $
;
;-

function mvn_swia_get_3ds, time, index = index, start = start

compile_opt idl2

common mvn_swia_data

ut = swis.time_unix

if (n_elements(time) eq 0) and (not keyword_set(start)) and (not keyword_set(index)) then ctime,time,npoints = 1

if keyword_set(start) then index = 0L

if (keyword_set(index) or keyword_set(start)) then index = index else mindt = min(abs(ut-time),index)

startt = swis[index].time_unix
data = swis[index].data
num_accum = swis[index].num_accum
units = swis[index].units
atten = swis[index].atten_state
infind = swis[index].info_index

nenergy = 48

dt_int  = info_str[infind].dt_int 
dt_arr = num_accum*12*4*16*replicate(1,nenergy)	; All of the summing of energy/angle/time bins is in this factor

energy= info_str[infind].energy_coarse 
denergy = energy * info_str[infind].deovere_coarse

phi = replicate(180,nenergy)
dphi = replicate(360,nenergy)

if atten le 1 then begin
	theta_0 = info_str[infind].theta_coarse
	g_th_0 = info_str[infind].g_th_coarse
	gf_0 = info_str[infind].geom_coarse 
endif else begin
	theta_0 = info_str[infind].theta_coarse_atten
	g_th_0 = info_str[infind].g_th_coarse_atten
	gf_0 = info_str[infind].geom_coarse_atten 
endelse	

theta = replicate(0,nenergy)

dtheta_0 = (shift(theta_0,0,-1) - shift(theta_0,0,1))/2.
dtheta_0[*,0] = (theta_0[*,1]-theta_0[*,0])
dtheta_0[*,3] = (theta_0[*,3]-theta_0[*,2])

dtheta = total(dtheta_0,2)

geom_factor = info_str[infind].geom


if atten gt 1 then gf_total = (gf_0[14] + gf_0[15])/2. else gf_total = total(gf_0)/16.0

; If attenuator is in, assume all the counts are in the attenuated region
; Should be a good assumption for most realistic cases


gf = replicate(gf_total,nenergy)

g_th_total = total(g_th_0,2)/4.0

eff = g_th_total

domega=2.*(dphi/!radeg)*cos(theta/!radeg)*sin(.5*dtheta/!radeg)

scpot = 0.
magf = [1.,0,0]

dat = 	{data_name:		'SWIA Coarse', 			$
	valid: 			1, 				$
	project_name:		'MAVEN', 			$
	units_name: 		units,		 		$
	units_procedure: 	'mvn_swia_convert_units',	$
	time: 			startt,				$
	end_time: 		startt+4.0*num_accum, 		$
	integ_t: 		dt_int,				$
	dt: 			4.0*num_accum,			$
	dt_arr:			dt_arr,				$
	nbins: 			1, 				$
	nenergy: 		nenergy, 			$
	data: 			data,		 		$
	energy: 		energy,		 		$
	theta: 			theta,  			$
	phi:			phi,				$
	denergy: 		denergy,    		   	$
	dtheta: 		dtheta, 			$
	dphi:			dphi,				$
	domega:			domega,				$
	eff: 			eff,				$
	charge:			1.,				$
	sc_pot:			scpot,		 		$
	magf:			magf,			 	$
	mass: 			5.68566e-06*1836.,	 	$
	geom_factor: 		geom_factor,			$
	gf: 			gf,				$
	dead:			100e-9 ,			$  
	bins: 			replicate(1,nenergy)	$
}

return,dat
	
end
