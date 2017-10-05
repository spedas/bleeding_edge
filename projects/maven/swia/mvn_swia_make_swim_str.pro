;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_SWIM_STR
;PURPOSE: 
;	Routine to produce an array of structures containing onboard moment data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_SWIM_STR, Packets, Info, Swim_Str_Array
;INPUTS:
;	Packets: An array of structures containing individual APID85 packets
;	Info: An array of structures containing information needed to convert to physical units
;OUTPUTS
;	Swim_Str_Array: An array of structures containing moments in real units
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-05-11 11:11:08 -0700 (Mon, 11 May 2015) $
; $LastChangedRevision: 17549 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_swim_str.pro $
;
;-

pro mvn_swia_make_swim_str, packets, info, swim_str_array

compile_opt idl2

INTCONST = 7.22457e-7
MASS = 1.67022e-24

met = packets.clock1*65536.d + packets.clock2 + packets.subsec/65536.d

unixt = mvn_spc_met_to_unixtime(met)

swim_str = {time_met: 0.d, $
time_unix: 0.d, $
density: 0., $
velocity: fltarr(3), $
pressure: fltarr(6), $
temperature: fltarr(3), $
heat_flux: fltarr(3), $
swi_mode: 0, $
atten_state: 0., $
info_index: 0, $
coordinates: 'Instrument', $
quality_flag: 1.0, $
decom_flag: 1.0}

n_packet = n_elements(met)
nsamp = n_packet*16L
swim_str_array = replicate(swim_str,nsamp)

momouts = fltarr(nsamp,13)

for i = 0L,n_packet-1 do begin

	swim_str_array[i*16:i*16+15].time_met = met[i] + findgen(16)*4*2.0^packets[i].accumper
	swim_str_array[i*16:i*16+15].time_unix = unixt[i] + findgen(16)*4*2.0^packets[i].accumper
	swim_str_array[i*16:i*16+15].atten_state = packets[i].attenpos
	swim_str_array[i*16:i*16+15].swi_mode = packets[i].swimode

	mom = packets[i].moments
	mvn_swia_moment_decom,mom,momout

	momout = reform(momout,13,16)
	momouts[i*16:i*16+15,*] = transpose(momout)
endfor



s = sort(swim_str_array.time_met)
swim_str_array = swim_str_array[s]
for i = 0,12 do momouts[*,i] = momouts[s,i]

;trim obviously bad data
winr = where(swim_str_array.time_unix ge info[swim_str_array.info_index].valid_time_range[0] and swim_str_array.time_unix le info[swim_str_array.info_index].valid_time_range[1], nsamp)

swim_str_array = swim_str_array[winr]
momouts = momouts[winr,*]

deltat = swim_str_array.time_unix-shift(swim_str_array.time_unix,1)
wt0 = where(deltat gt -0.1 and deltat lt 0.1,nwt0)
wwt0 = where(wt0 ge 2,nwt0)
wt0 = wt0[wwt0]

;fix packets that got flipped in time by sort

if nwt0 gt 0 then begin
	for i = 0,nwt0-1 do begin
		if swim_str_array[wt0[i]-1].swi_mode ne swim_str_array[wt0[i]-2].swi_mode then begin
			temp = swim_str_array[wt0[i]]
			tempmom = momouts[wt0[i],*]
			swim_str_array[wt0[i]] = swim_str_array[wt0[i]-1]
			momouts[wt0[i],*] = momouts[wt0[i]-1,*]
			swim_str_array[wt0[i]-1] = temp
			momouts[wt0[i]-1,*] = tempmom
			swim_str_array[wt0[i]].time_unix = swim_str_array[wt0[i]-1].time_unix + 1e-6
		endif
	endfor
endif
			

mf_c = info[swim_str_array.info_index].mf_coarse
sf_c = info[swim_str_array.info_index].sf_coarse
sf_c_a = info[swim_str_array.info_index].sf_coarse_atten
mf_f = info[swim_str_array.info_index].mf_fine
sf_f = info[swim_str_array.info_index].sf_fine
de_c = info[swim_str_array.info_index].deovere_coarse
de_f = info[swim_str_array.info_index].deovere_fine
dt = info[swim_str_array.info_index].dt_int
geom = info[swim_str_array.info_index].geom

af = info[swim_str_array.info_index].geom_fine_atten/info[swim_str_array.info_index].geom_fine
af = total(af,1)/10


;fix attenuator status

waswitch = where(swim_str_array.atten_state ne shift(swim_str_array.atten_state,1),nw)
if waswitch[0] eq 0 then begin
	nw = nw-1
	if nw gt 0 then waswitch = waswitch[1:nw]
endif	

if nw gt 0 then begin
	for i = 0,nw-1 do begin
		rawdensity = momouts[waswitch[i]-16:waswitch[i]+1,0]

		if swim_str_array[waswitch[i]].swi_mode eq 1 then begin
			caf = sf_c_a[waswitch[i]] / sf_c[waswitch[i]]
			 if swim_str_array[waswitch[i]].atten_state eq 2 then ratio = caf else ratio = 1.0/caf

		endif else begin		
			if swim_str_array[waswitch[i]].atten_state eq 2 then ratio = af[waswitch[i]] else ratio = 1.0/af[waswitch[i]]
		endelse

		mvn_swia_fit_step,rawdensity,ratio,ind
		if ind lt 16 then swim_str_array[waswitch[i]-16+ind:waswitch[i]-1].atten_state = 3-swim_str_array[waswitch[i]-16+ind:waswitch[i]-1].atten_state
		if ind eq 17 then swim_str_array[waswitch[i]].atten_state = 3-swim_str_array[waswitch[i]].atten_state

		swim_str_array[waswitch[i]-16:waswitch[i]+1].decom_flag = 0.5
		swim_str_array[waswitch[i]-16+ind-1:waswitch[i]-16+ind].decom_flag = 0.25
	endfor
endif


;fix mode

waswitch = where(swim_str_array.swi_mode ne shift(swim_str_array.swi_mode,1),nw)
if waswitch[0] eq 0 then begin
	nw = nw-1
	if nw gt 0 then waswitch = waswitch[1:nw]
endif	

if nw gt 0 then begin
	for i = 0,nw-1 do begin
		rawdensity = momouts[waswitch[i]-16:waswitch[i]+1,0]

		if swim_str_array[waswitch[i]].atten_state eq 1 then begin
			caf = ( sf_c[waswitch[i]] * mf_c[0,waswitch[i]] ) / ( sf_f[waswitch[i]] * mf_f[0,waswitch[i]] )
			 if swim_str_array[waswitch[i]].swi_mode eq 1 then ratio = caf else ratio = 1.0/caf

		endif else begin		
			caf = ( sf_c_a[waswitch[i]] * mf_c[0,waswitch[i]] ) / ( af[waswitch[i]]*sf_f[waswitch[i]] * mf_f[0,waswitch[i]] )
			 if swim_str_array[waswitch[i]].swi_mode eq 1 then ratio = caf else ratio = 1.0/caf

		endelse

		mvn_swia_fit_step,rawdensity,ratio,ind
		if ind lt 16 then swim_str_array[waswitch[i]-16+ind:waswitch[i]-1].swi_mode = 1-swim_str_array[waswitch[i]-16+ind:waswitch[i]-1].swi_mode
		if ind eq 17 then swim_str_array[waswitch[i]].swi_mode = 1-swim_str_array[waswitch[i]].swi_mode

		swim_str_array[waswitch[i]-16:waswitch[i]+1].decom_flag = swim_str_array[waswitch[i]-16:waswitch[i]+1].decom_flag*0.5
		swim_str_array[waswitch[i]-16+ind-1:waswitch[i]-16+ind].decom_flag = swim_str_array[waswitch[i]-16+ind-1:waswitch[i]-16+ind].decom_flag*0.5
	endfor
endif



mf = fltarr(nsamp,4)
sf = fltarr(nsamp)
de = fltarr(nsamp)
dang = fltarr(nsamp)

w = where(swim_str_array.swi_mode eq 1 and swim_str_array.atten_state le 1)
if w[0] ne -1 then begin
	dt[w] = dt[w]*12
	mf[w,*] = transpose(mf_c[*,w])
	sf[w] = sf_c[w]
	de[w] = de_c[w]
	dang[w] = 2*!pi/16
endif

w = where(swim_str_array.swi_mode eq 1 and swim_str_array.atten_state gt 1)
if w[0] ne -1 then begin
	dt[w] = dt[w]*12
	mf[w,*] = transpose(mf_c[*,w])
	sf[w] = sf_c_a[w]
	de[w] = de_c[w]
	dang[w] = 2*!pi/16
endif
	
w = where(swim_str_array.swi_mode eq 0 and swim_str_array.atten_state le 1)
if w[0] ne -1 then begin
	mf[w,*] = transpose(mf_f[*,w])
	sf[w] = sf_f[w]
	de[w] = de_f[w]
	dang[w] = 3.75*!pi/180
endif

w = where(swim_str_array.swi_mode eq 0 and swim_str_array.atten_state gt 1)
if w[0] ne -1 then begin
	mf[w,*] = transpose(mf_f[*,w])
	sf[w] = sf_f[w] * af[w]
	de[w] = de_f[w]
	dang[w] = 3.75*!pi/180
endif


swim_str_array.density = momouts[*,0]/(mf[*,0]*sf) * dang*de * 2*!pi/(dt*geom) * INTCONST 

swim_str_array.velocity[0] = momouts[*,1]/(mf[*,1]*sf) * dang*de * 2*!pi/(dt*geom) * 1e-5/(swim_str_array.density > 1e-4)
swim_str_array.velocity[1] = momouts[*,2]/(mf[*,1]*sf) * dang*de * 2*!pi/(dt*geom) * 1e-5/(swim_str_array.density > 1e-4)
swim_str_array.velocity[2] = momouts[*,3]/(mf[*,1]*sf) * dang*de * 2*!pi/(dt*geom) * 1e-5/(swim_str_array.density > 1e-4)

swim_str_array.pressure[0] = (momouts[*,4]/(mf[*,2]*sf) * dang*de * 2*!pi/(dt*geom) * MASS/INTCONST - MASS*swim_str_array.velocity[0]*swim_str_array.velocity[0] * 1e10 * swim_str_array.density)/1.6e-12
swim_str_array.pressure[1] = (momouts[*,5]/(mf[*,2]*sf) * dang*de * 2*!pi/(dt*geom) * MASS/INTCONST - MASS*swim_str_array.velocity[1]*swim_str_array.velocity[1] * 1e10 * swim_str_array.density)/1.6e-12
swim_str_array.pressure[2] = (momouts[*,6]/(mf[*,2]*sf) * dang*de * 2*!pi/(dt*geom) * MASS/INTCONST - MASS*swim_str_array.velocity[2]*swim_str_array.velocity[2] * 1e10 * swim_str_array.density)/1.6e-12
swim_str_array.pressure[3] = (momouts[*,7]/(mf[*,2]*sf) * dang*de * 2*!pi/(dt*geom) * MASS/INTCONST - MASS*swim_str_array.velocity[0]*swim_str_array.velocity[1] * 1e10 * swim_str_array.density)/1.6e-12
swim_str_array.pressure[4] = (momouts[*,8]/(mf[*,2]*sf) * dang*de * 2*!pi/(dt*geom) * MASS/INTCONST - MASS*swim_str_array.velocity[0]*swim_str_array.velocity[2] * 1e10 * swim_str_array.density)/1.6e-12
swim_str_array.pressure[5] = (momouts[*,9]/(mf[*,2]*sf) * dang*de * 2*!pi/(dt*geom) * MASS/INTCONST - MASS*swim_str_array.velocity[1]*swim_str_array.velocity[2] * 1e10 * swim_str_array.density)/1.6e-12

swim_str_array.temperature[0] = swim_str_array.pressure[0]/(swim_str_array.density > 1e-4)
swim_str_array.temperature[1] = swim_str_array.pressure[1]/(swim_str_array.density > 1e-4)
swim_str_array.temperature[2] = swim_str_array.pressure[2]/(swim_str_array.density > 1e-4)

swim_str_array.heat_flux[0] = momouts[*,10]/(mf[*,3]*sf) * dang*de * 2*!pi/(dt*geom) * 1.6e-12
swim_str_array.heat_flux[1] = momouts[*,11]/(mf[*,3]*sf) * dang*de * 2*!pi/(dt*geom) * 1.6e-12
swim_str_array.heat_flux[2] = momouts[*,12]/(mf[*,3]*sf) * dang*de * 2*!pi/(dt*geom) * 1.6e-12


;Calculate Quality Flags

temp = total(swim_str_array.temperature,1)/3.
vel = sqrt(total(swim_str_array.velocity^2,1))
vthermal = sqrt(2*temp*1.6e-19/1.67e-27)/1e3
vang = atan(vthermal/vel)*180/!pi
vphi = atan(swim_str_array.velocity[1],swim_str_array.velocity[0])*180/!pi
vphi = (vphi+360) mod 360
vtheta = atan(swim_str_array.velocity[2],sqrt(vel^2-swim_str_array.velocity[2]^2))*180/!pi

w = where(swim_str_array.swi_mode eq 0,nw)
if nw gt 1 then begin
	ww = where(vang[w] gt 45 or (vphi[w] + vang[w]) gt 202.5 or (vphi[w]-vang[w]) lt 157.5 or (vtheta[w]+vang[w]) gt 45 or (vtheta[w]-vang[w]) lt -45 or (vel[w]+vthermal[w]) gt 2e3 or (vel[w] - vthermal[w]) lt 30,nww)
	if nww gt 0 then swim_str_array[w[ww]].quality_flag = 0.25
endif

w = where(swim_str_array.swi_mode eq 1,nw)
if nw gt 1 then begin
	ww = where(vang[w] gt 45 or (vtheta[w]+vang[w]) gt 45 or (vtheta[w]-vang[w]) lt -45 or (vel[w]+vthermal[w]) gt 2e3 or (vel[w] - vthermal[w]) lt 30,nww)
	if nww gt 0 then swim_str_array[w[ww]].quality_flag = 0.25
endif


end
