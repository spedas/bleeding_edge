;+
;PROCEDURE: 
;	MVN_SWIA_INST2MSO
;PURPOSE: 
;	Routine to rotate SWIA velocity and temperature moments from instrument
;	coordinates to MS0 
;	This routine is in the process of being modified to use Davin's routines
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_INST2MSO
;INPUTS:
;KEYWORDS:
;	LOAD: if set, load (and unload) the spice kernels
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2017-02-01 18:41:41 -0800 (Wed, 01 Feb 2017) $
; $LastChangedRevision: 22714 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_inst2mso.pro $
;
;-

pro mvn_swia_inst2mso, load = load

compile_opt idl2

common mvn_swia_data


unixt = swim.time_unix
trange = [min(unixt),max(unixt)]

if keyword_set(load) then kernels = mvn_spice_kernels(trange=trange,/load)


et = time_ephemeris(unixt)
nt = n_elements(et)

crmat = replicate(!values.d_nan,nt,3,3)

for i = 0,nt-1 do begin
	cspice_sce2t,-202,et[i],sclkdp
	cspice_ckgp,-202000,sclkdp,0,'IAU_SUN', cmat, clkout, found

	if found then begin
		cspice_sxform,'MAVEN_MSO','MAVEN_SWIA',et[i],xform 
		crmat[i,*,*] = xform[0:2,0:2]
	endif
endfor


if keyword_set(load) then cspice_unload, kernels

store_data,'crmat',data = {x:swim.time_unix,y:crmat}


tvector_rotate,'crmat','mvn_swim_velocity',suffix = '_mso',/vector_skip,/matrix_skip

get_data,'mvn_swim_pressure',data = pr
get_data,'mvn_swim_density',data = dens

ntemp = fltarr(nt,3)

for i = 0,nt-1 do begin

	cmati = reform(crmat[i,*,*])

	pmatrix = [[pr.y[i,0],pr.y[i,3],pr.y[i,4]],[pr.y[i,3],pr.y[i,1],pr.y[i,5]],[pr.y[i,4],pr.y[i,5],pr.y[i,2]]]

	npmatrix = cmati # pmatrix # transpose(cmati)


	ntemp[i,0] = npmatrix[0,0]/dens.y[i]
	ntemp[i,1] = npmatrix[1,1]/dens.y[i]
	ntemp[i,2] = npmatrix[2,2]/dens.y[i]
endfor

store_data,'mvn_swim_temperature_mso',data = {x:pr.x,y:ntemp}

end