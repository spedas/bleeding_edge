;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_SWIF_STR
;PURPOSE: 
;	Routine to produce an array of structures containing fine data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_SWIF_STR, ShortPackets=ShortPackets, LongPackets=LongPackets, Info, 
;	Swif_Str_Array
;OPTIONAL INPUTS:
;	ShortPackets: An array of structures containing short APID82/83 packets
;	LongPackets: An array of structures containing long APID82/83 packets
;	Info: An array of structures containing information needed to convert to physical units
;OUTPUTS
;	Swif_Str_Array: An array of structures containing coarse 3d products
;		(Note that for 32Ex8Dx6A mode the products are padded with zeros 
;		to produce a product that always has 48x12x10 elements)
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-01-06 11:51:10 -0800 (Mon, 06 Jan 2014) $
; $LastChangedRevision: 13743 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_swif_str.pro $
;
;-

pro mvn_swia_make_swif_str, shortpackets = shortpackets, longpackets = longpackets, info, swif_str_array

compile_opt idl2

packets = [keyword_set(shortpackets),keyword_set(longpackets)]

swif_str = {time_met: 0.d, $
time_unix: 0.d, $
data: fltarr(48,12,10), $
estep_first: 0, $
dstep_first: 0, $
atten_state: 0., $
grouping: 0, $
info_index: 0, $
units: 'Counts'}

if packets[0] then begin
	npackets = n_elements(shortpackets)
	met = shortpackets.clock1*65536.d + shortpackets.clock2 + shortpackets.subsec/65536.d ; - 4.0 shift for delay before FSW fix

	unixt = mvn_spc_met_to_unixtime(met)

	swifshort = replicate(swif_str,npackets)


	swifshort.time_met = met
	swifshort.time_unix = unixt
	swifshort.atten_state = shortpackets.atten
	swifshort.grouping = 1

	for i = 0L,npackets-1 do begin
		cprod = shortpackets[i].counts
		prod = mvn_pfp_log_decomp(cprod,0)
		
		iprod = reform(prod,6,8,32)
		iprod = transpose(iprod)
		swifshort[i].estep_first = (shortpackets[i].estepfirst > 0) < 48
		swifshort[i].dstep_first = (shortpackets[i].dstepfirst > 0) < 12
		swifshort[i].data[8:39,2:9,2:7] = iprod
	endfor	
endif


if packets[1] then begin
	npackets = n_elements(longpackets)

	met = longpackets.clock1*65536.d + longpackets.clock2 + longpackets.subsec/65536.d ; - 4.0 shift for delay before FSW fix

	unixt = mvn_spc_met_to_unixtime(met)

	s = sort(met)
	met = met[s]
	unixt = unixt[s]
	longpackets = longpackets[s]
	u = uniq(round(met))
	met_uniq = round(met[u])
	nsamp = n_elements(u)

	swiflong = replicate(swif_str,nsamp)


	swiflong.time_met = met[u]
	swiflong.time_unix = unixt[u]
	swiflong.atten_state = longpackets[u].atten
	swiflong.grouping = 0
	swiflong.estep_first = (longpackets[u].estepfirst > 0) < 48
	swiflong.dstep_first = (longpackets[u].dstepfirst > 0) < 12

	packet_order = fltarr(npackets)

	for i = 0L,npackets-1 do begin
		w = where(abs(met-met[i]) lt 0.01)
		ww = where(longpackets[w].seqcount lt longpackets[i].seqcount,nww)
		packet_order[i] = (nww > 0) < 2
	endfor


	for i = 0L,npackets-1 do begin
		step = packet_order[i]

		cprod = longpackets[i].counts
	       prod = mvn_pfp_log_decomp(cprod,0)
		
		ind = where(abs(met_uniq-met[i]) le 1)
		iprod = reform(prod,10,12,16)
		iprod = transpose(iprod)
		swiflong[ind].data[step*16:(step+1)*16-1,*,*] = iprod
	endfor	
endif

if total(packets) eq 2 then swif_str_array = [swifshort, swiflong] else begin
	if packets[0] then swif_str_array = swifshort else swif_str_array = swiflong
endelse

s = sort(swif_str_array.time_met)
swif_str_array = swif_str_array[s]

;trim obviously bad data
swif_str_array = swif_str_array[where(swif_str_array.time_unix ge info[swif_str_array.info_index].valid_time_range[0] and swif_str_array.time_unix le info[swif_str_array.info_index].valid_time_range[1])]

end
