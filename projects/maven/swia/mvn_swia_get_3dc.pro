;+
;FUNCTION: 
;	MVN_SWIA_GET_3DC
;PURPOSE: 
;	Construct a standard 3-d data structure for SWIA coarse data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE: 
;	Result = MVN_SWIA_GET_3DC(Time, INDEX=INDEX, /ARCHIVE)
;OPTIONAL INPUTS: 
;	Time: A double unix_time to return a packet for - otherwise uses index or clicks
;KEYWORDS:
;	INDEX: Gets data at this index value in the common block (useful for looping)
;	ARCHIVE: Returns archive distribution instead of survey
;	START: Gets data at the first point in the common block (useful for looping)
;OUTPUTS:
;	Returns a standard 3-d data structure that will work with plot3d, spec3d, n_3d, etc.
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-10-10 06:40:29 -0700 (Fri, 10 Oct 2014) $
; $LastChangedRevision: 15971 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_get_3dc.pro $
;
;-

function mvn_swia_get_3dc, time, index = index, start = start, archive = archive

compile_opt idl2

common mvn_swia_data

if keyword_set(archive) then ut = swica.time_unix else ut = swics.time_unix

if (n_elements(time) eq 0) and (not keyword_set(start)) and (not keyword_set(index)) then ctime,time,npoints = 1

if keyword_set(start) then index = 0L

if (keyword_set(index) or keyword_set(start)) then index = index else mindt = min(abs(ut-time),index)

if keyword_set(archive) then begin
	startt = swica[index].time_unix
	data = swica[index].data
	num_accum = swica[index].num_accum
	units = swica[index].units
	atten = swica[index].atten_state
	infind = swica[index].info_index
	str_element,swica,'magf',value, success = success
	if success then magf = swica[index].magf else magf = [1.,0,0]
endif else begin
	startt = swics[index].time_unix
	data = swics[index].data
	num_accum = swics[index].num_accum
	units = swics[index].units
	atten = swics[index].atten_state
	infind = swics[index].info_index
	str_element,swics,'magf',value, success = success
	if success then magf = swics[index].magf else magf = [1.,0,0]
endelse

nanode = 16
ndeflect = 4
nbins = nanode*ndeflect
nenergy = 48

data = reform(data,nenergy,nbins)

dt_int  = info_str[infind].dt_int 
dt_arr = num_accum*12*replicate(1,nenergy,nbins)	; All of the summing of energy/angle/time bins is in this factor

energy= info_str[infind].energy_coarse # replicate(1,nbins)
denergy = energy * info_str[infind].deovere_coarse

phi = reform(replicate(1,ndeflect)#info_str[infind].phi_coarse,nbins)
phi = replicate(1,nenergy)#phi
dphi = replicate(22.5,nenergy,nbins)

if atten le 1 then begin
	theta_0 = info_str[infind].theta_coarse
	g_th_0 = info_str[infind].g_th_coarse
	gf_0 = info_str[infind].geom_coarse 
endif else begin
	theta_0 = info_str[infind].theta_coarse_atten
	g_th_0 = info_str[infind].g_th_coarse_atten
	gf_0 = info_str[infind].geom_coarse_atten 
endelse	

dtheta_0 = (shift(theta_0,0,-1) - shift(theta_0,0,1))/2.
dtheta_0[*,0] = (theta_0[*,1]-theta_0[*,0])
dtheta_0[*,ndeflect-1] = (theta_0[*,ndeflect-1]-theta_0[*,ndeflect-2])

geom_factor = info_str[infind].geom

gf = reform(replicate(1,ndeflect)#gf_0,nbins)
gf = replicate(1,nenergy)#gf

theta = fltarr(nenergy,ndeflect,nanode)
dtheta = fltarr(nenergy,ndeflect,nanode)
eff = fltarr(nenergy,ndeflect,nanode)

for k = 0,nanode-1 do begin
	theta[*,*,k] = theta_0
	dtheta[*,*,k] = dtheta_0
	eff[*,*,k] = g_th_0
endfor

theta = reform(theta,nenergy,nbins)
dtheta = reform(dtheta,nenergy,nbins)
eff = reform(eff,nenergy,nbins)

domega=2.*(dphi/!radeg)*cos(theta/!radeg)*sin(.5*dtheta/!radeg)

scpot = 0.

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
	nbins: 			nbins, 				$
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
	dead:			100e-9,				$
	bins: 			replicate(1,nenergy,nbins)	$
}

return,dat
	
end
