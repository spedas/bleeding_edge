;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_SWIC_STR
;PURPOSE: 
;	Routine to produce an array of structures containing coarse data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_SWIC_STR, Packets, Info, Swic_Str_Array
;INPUTS:
;	Packets: An array of structures containing individual APID80/81 packets
;	Info: An array of structures containing information needed to convert to physical units
;OUTPUTS
;	Swic_Str_Array: An array of structures containing coarse 3d products
;		(Note that for products with 16 or 24 energy steps, the 
;		counts are distributed evenly over 2 or 3 steps to produce
;		a product that always has 48 energy steps)
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-06-18 21:19:24 -0700 (Tue, 18 Jun 2013) $
; $LastChangedRevision: 12551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_swic_str.pro $
;
;-

pro mvn_swia_make_swic_str, packets, info, swic_str_array

compile_opt idl2

met = packets.clock1*65536.d + packets.clock2 + packets.subsec/65536.d

unixt = mvn_spc_met_to_unixtime(met)

swic_str = {time_met: 0.d, $
time_unix: 0.d, $
data: fltarr(48,4,16), $
atten_state: 0., $
grouping: 0, $
num_accum: 0, $
info_index: 0, $
units: 'Counts'}

s = sort(met)
met = met[s]
unixt = unixt[s]
packets = packets[s]

u = uniq(round(met))
met_uniq = round(met[u])
nsamp = n_elements(u)

swic_str_array = replicate(swic_str,nsamp)


swic_str_array.time_met = met[u]
swic_str_array.time_unix = unixt[u]
swic_str_array.atten_state = packets[u].attenpos
swic_str_array.grouping = packets[u].grouping
swic_str_array.num_accum = packets[u].numaccum


w = where(packets.grouping eq 0,nw)
if nw gt 0 then begin
	for i = 0L,nw-1 do begin
		cprod = packets[w[i]].counts
	       prod = mvn_pfp_log_decomp(cprod,0)

		ind = where(abs(met_uniq-met[w[i]]) le 1)

		iprod = reform(prod,16,4,8)
		iprod = transpose(iprod)	

		step = packets[w[i]].packetseq < 5
		swic_str_array[ind].data[step*8:(step+1)*8-1,*,*] = iprod

	endfor
endif

w = where(packets.grouping eq 1,nw)
if nw gt 0 then begin
	for i = 0L,nw-1 do begin
		cprod = packets[w[i]].counts
	       prod = mvn_pfp_log_decomp(cprod,0)

		ind = where(abs(met_uniq-met[w[i]]) le 1)

		iprod = reform(prod,16,4,8)
		iprod = transpose(iprod)
		iprod = rebin(iprod,16,4,16,/sample)/2.	

		step = packets[w[i]].packetseq < 2
		swic_str_array[ind].data[step*16:(step+1)*16-1,*,*] = iprod
	endfor
endif


w = where(packets.grouping eq 2,nw)
if nw gt 0 then begin
	for i = 0L,nw-1 do begin
		cprod = packets[w[i]].counts
	       prod = mvn_pfp_log_decomp(cprod,0)

		ind = where(abs(met_uniq-met[w[i]]) le 1) 

		iprod = reform(prod,16,4,8)
		iprod = transpose(iprod)
		iprod = rebin(iprod,24,4,16,/sample)/3.	

		step = packets[w[i]].packetseq < 1
		swic_str_array[ind].data[step*24:(step+1)*24-1,*,*] = iprod
	endfor
endif

s = sort(swic_str_array.time_met)
swic_str_array = swic_str_array[s]


;trim obviously bad data
swic_str_array = swic_str_array[where(swic_str_array.time_unix ge info[swic_str_array.info_index].valid_time_range[0] and swic_str_array.time_unix le info[swic_str_array.info_index].valid_time_range[1])]

end
