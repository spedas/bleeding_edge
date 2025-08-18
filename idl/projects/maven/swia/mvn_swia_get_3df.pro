;+
;FUNCTION: 
;	MVN_SWIA_GET_3DF
;PURPOSE: 
;	Construct a standard 3-d data structure for SWIA fine data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE: 
;	Result = MVN_SWIA_GET_3DF(Time, INDEX=INDEX, /ARCHIVE)
;OPTIONAL INPUTS: 
;	Time: A double unix_time to return a packet for - otherwise uses index or clicks
;KEYWORDS:
;	INDEX: Gets data at this index value in the common block (useful for looping)
;	START: Gets data at the first point in the common block (useful for looping)
;	ARCHIVE: Returns archive distribution instead of survey
;OUTPUTS:
;	Returns a standard 3-d data structure that will work with plot3d, spec3d, n_3d, etc.
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-10-10 06:40:29 -0700 (Fri, 10 Oct 2014) $
; $LastChangedRevision: 15971 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_get_3df.pro $
;
;-

function mvn_swia_get_3df, time, index = index, start = start, archive = archive

compile_opt idl2

common mvn_swia_data

if keyword_set(archive) then ut = swifa.time_unix else ut = swifs.time_unix

if (n_elements(time) eq 0) and (not keyword_set(start)) and (not keyword_set(index)) then ctime,time,npoints = 1

if keyword_set(start) then index = 0L

if (keyword_set(index) or keyword_set(start)) then index = index else mindt = min(abs(ut-time),index)

if keyword_set(archive) then begin
	startt = swifa[index].time_unix
	data = swifa[index].data
	units = swifa[index].units
	atten = swifa[index].atten_state
	infind = swifa[index].info_index
	estepf = swifa[index].estep_first
	dstepf = swifa[index].dstep_first

	str_element,swifa,'magf',value, success = success
	if success then magf = swifa[index].magf else magf = [1.,0,0]
endif else begin
	startt = swifs[index].time_unix
	data = swifs[index].data
	units = swifs[index].units
	atten = swifs[index].atten_state
	infind = swifs[index].info_index
	estepf = swifs[index].estep_first
	dstepf = swifs[index].dstep_first
	str_element,swifs,'magf',value, success = success
	if success then magf = swifs[index].magf else magf = [1.,0,0]
endelse

nanode = 10
ndeflect = 12
nbins = nanode*ndeflect
nenergy = 48

data = reform(data,nenergy,nbins)

dt_int  = info_str[infind].dt_int 
dt_arr = replicate(1,nenergy,nbins)

energy= info_str[infind].energy_fine[estepf:estepf+47] # replicate(1,nbins)
denergy = energy * info_str[infind].deovere_fine

phi = reform(replicate(1,ndeflect)#info_str[infind].phi_fine,nbins)
phi = replicate(1,nenergy)#phi
dphi = replicate(4.5,nenergy,nbins)

if atten le 1 then begin
	theta_0 = info_str[infind].theta_fine[estepf:estepf+47, dstepf:dstepf+11]
	g_th_0 = info_str[infind].g_th_fine[estepf:estepf+47, dstepf:dstepf+11]
	gf_0 = info_str[infind].geom_fine 
endif else begin
	theta_0 = info_str[infind].theta_fine_atten[estepf:estepf+47, dstepf:dstepf+11]
	g_th_0 = info_str[infind].g_th_fine_atten[estepf:estepf+47, dstepf:dstepf+11]
	gf_0 = info_str[infind].geom_fine_atten 
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

dat = 	{data_name:		'SWIA Fine', 			$
	valid: 			1, 				$
	project_name:		'MAVEN', 			$
	units_name: 		units,		 		$
	units_procedure: 	'mvn_swia_convert_units',	$
	time: 			startt,				$
	end_time: 		startt+4.0, 			$
	integ_t: 		dt_int,				$
	dt: 			4.0,				$
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
