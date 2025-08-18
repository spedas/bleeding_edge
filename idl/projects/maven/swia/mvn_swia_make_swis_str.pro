;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_SWIS_STR
;PURPOSE: 
;	Routine to produce an array of structures containing spectra data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_SWIS_STR, Packets, Info, Swis_Str_Array
;INPUTS:
;	Packets: An array of structures containing individual APID86 packets
;	Info: An array of structures containing information needed to convert to physical units
;OUTPUTS
;	Swis_Str_Array: An array of structures containing energy spectra
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-05-11 11:11:08 -0700 (Mon, 11 May 2015) $
; $LastChangedRevision: 17549 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_swis_str.pro $
;
;-

pro mvn_swia_make_swis_str, packets, info, swis_str_array

compile_opt idl2

met = packets.clock1*65536.d + packets.clock2 + packets.subsec/65536.d

unixt = mvn_spc_met_to_unixtime(met)

swis_str = {time_met: 0.d, $
time_unix: 0.d, $
data: fltarr(48), $
atten_state: 0., $
num_accum: 0, $
info_index: 0, $
units: 'Counts', $
decom_flag: 1.0}

n_packet = n_elements(met)
nsamp = n_packet*16L
swis_str_array = replicate(swis_str,nsamp)

for i = 0L,n_packet-1 do begin

	swis_str_array[i*16:i*16+15].time_met = met[i] + findgen(16)*4*2.0^packets[i].accumper
	swis_str_array[i*16:i*16+15].time_unix = unixt[i] + findgen(16)*4*2.0^packets[i].accumper
	swis_str_array[i*16:i*16+15].atten_state = packets[i].attenpos
	swis_str_array[i*16:i*16+15].num_accum = packets[i].numaccum

	cprod = packets[i].spectra
	prod = mvn_pfp_log_decomp(cprod,0)

	iprod = reform(prod,48,16)
	
	swis_str_array[i*16:i*16+15].data = iprod

endfor

s = sort(swis_str_array.time_met)
swis_str_array = swis_str_array[s]


;trim obviously bad data
swis_str_array = swis_str_array[where(swis_str_array.time_unix ge info[swis_str_array.info_index].valid_time_range[0] and swis_str_array.time_unix le info[swis_str_array.info_index].valid_time_range[1])]

;fix attenuator status

waswitch = where(swis_str_array.atten_state ne shift(swis_str_array.atten_state,1),nw)
if waswitch[0] eq 0 then begin
	nw = nw-1
	if nw gt 0 then waswitch = waswitch[1:nw]
endif	

if nw gt 0 then begin
	for i = 0,nw-1 do begin
		sample = swis_str_array[waswitch[i]-16:waswitch[i]+1].data
		scounts = total(sample,1)
		af = info[swis_str_array[waswitch[i]].info_index].geom_fine_atten/info[swis_str_array[waswitch[i]].info_index].geom_fine
		af = total(af,1)/10
		if swis_str_array[waswitch[i]].atten_state eq 2 then ratio = af else ratio = 1.0/af

		mvn_swia_fit_step,scounts,ratio,ind
		if ind lt 16 then swis_str_array[waswitch[i]-16+ind:waswitch[i]-1].atten_state = 3-swis_str_array[waswitch[i]-16+ind:waswitch[i]-1].atten_state
		if ind eq 17 then swis_str_array[waswitch[i]].atten_state = 3-swis_str_array[waswitch[i]].atten_state

		swis_str_array[waswitch[i]-16:waswitch[i]+1].decom_flag = 0.5
		swis_str_array[waswitch[i]-16+ind-1:waswitch[i]-16+ind].decom_flag = 0.25

	endfor
endif

end
