;+
;PROCEDURE: 
;	MVN_SWIA_READ_COMPRESSED_PACKETS
;PURPOSE: 
;	Routine to read in compressed SWIA packets from any telemetry file
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_READ_COMPRESSED_PACKETS, File, /SYNC, /R29, /R80, /R81, /R82S, /R82L, 
;	/R83S, /R83L, /R84, /R85, /R86, /R87, APID29=APID29, APID80=APID80, APID81=APID81,
;	APID82SHORT=APID82SHORT, APID82LONG=APID82LONG, APID83SHORT=APID83SHORT,
;	APID83LONG=APID83LONG, APID84=APID84, APID85=APID85, APID86=APID86, APID87=APID87
;INPUTS: 
;	File: A filename to read packets from
;KEYWORDS: 
;	R29-R87: Set to one to read in each type of packet (saves time if not set)
;	SYNC: Synchronize on spacecraft header and checksum (saves lots of time)
;OPTIONAL OUTPUTS:
;	APID29: Housekeeping
;	APID80: Coarse Survey
;	APID81: Coarse Archive
;	APID82SHORT: Fine Survey (small version)
;	APID82LONG: Fine Survey(large version)
;	APID83SHORT: Fine Archive (small version)
;	APID83LONG: Fine Archive(large version)
;	APID84: Raw Survey
;	APID85: Moments
;	APID86: Spectra
;	APID87: Fast Housekeeping
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-12-12 06:21:37 -0800 (Fri, 12 Dec 2014) $
; $LastChangedRevision: 16476 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_read_compressed_packets.pro $
;
;-

pro mvn_swia_read_compressed_packets,file, apid29 = apid29,apid80 = apid80,apid81=apid81,apid82short = apid82short, $
	apid82long = apid82long,apid83short = apid83short, apid83long = apid83long,apid84 = apid84,apid85 = apid85, $
	apid86 = apid86,apid87 = apid87, r29 = r29, r80 = r80, r81 = r81, r82s = r82s, r82l = r82l, r83s = r83s, $
	r83l = r83l, r84 = r84, r85 = r85, r86= r86, r87= r87, sync = sync

compile_opt idl2

alldata = read_binary(file)
alldata = [alldata, replicate(0, 4096)]		; Pad array so nothing fails at the end
nel = n_elements(alldata)


apidhi = alldata
apidlo = shift(alldata,-1)
apid = apidhi*256L + apidlo
packlen1 = shift(alldata,-4)
packlen2 = shift(alldata,-5)
ccsdslen = packlen1*256L + packlen2


print,'Reading APID29 (Housekeeping)'
mvn_swia_define_apid29, decoder = apid29decoder, data = apid29data
apid29length = apid29decoder.length*2

w = where((apid eq '0829'X) and ccsdslen eq apid29length-7,nw)    
if nw gt 0 and keyword_set(r29) then begin
	apid29 = replicate(apid29data,nw)
	
	for j = 0L,nw-1 do begin
		startbyte = w[j]
		message = alldata[startbyte:startbyte+apid29length-1]
		messagewords = lonarr(apid29length/2)
		ind = indgen(apid29length/2)
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid29decoder,apid29data
		apid29[j] = apid29data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif


print,'Reading APID80 (Coarse Survey)'
mvn_swia_define_apid80, decoder = apid80decoder, data = apid80data
apid80length = apid80decoder.length*2

w = where((apid eq '0880'X) and ccsdslen le apid80length-7 and ccsdslen gt 9,nw)    
if nw gt 0 and keyword_set(r80) then begin
	decomdata = bytarr(apid80length*nw)
	ngood = 0L

	for j = 0L,nw-1 do begin
		startbyte = w[j]
		comlength = (ccsdslen[w[j]]+7)

		if keyword_set(sync) then synced = (alldata[startbyte+comlength+2] eq '08'X and $
		((alldata[startbyte+comlength+3] eq '50'X) or (alldata[startbyte+comlength+3] eq '51'X) or $
		(alldata[startbyte+comlength+3] eq '53'X) or (alldata[startbyte+comlength+3] eq '62'X))) else synced = 1

		if synced then begin
			combytes = alldata[startbyte:startbyte+comlength-1]
			if ccsdslen[w[j]] eq apid80length-7 then decombytes = combytes else decombytes = mvn_swia_packet_decompress(combytes)
		
			nlen = decombytes[4]*256+decombytes[5] 
		
			if nlen eq apid80length-7 and synced then begin
				decomdata[ngood*apid80length:ngood*apid80length+apid80length-1] = decombytes
				ngood = ngood+1
			endif
		endif
	endfor
		

	if ngood gt 0 then apid80 = replicate(apid80data,ngood)

	messagewords = lonarr(apid80length/2)
	ind = indgen(apid80length/2)
	
	for j = 0L,ngood-1 do begin
		startbyte = j*apid80length
		message = decomdata[startbyte:startbyte+apid80length-1]
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid80decoder,apid80data
		apid80[j] = apid80data
		if (j mod 5000) eq 0 then print,j,'/',ngood
	endfor
endif


print,'Reading APID81 (Coarse Archive)'
mvn_swia_define_apid81, decoder = apid81decoder, data = apid81data
apid81length = apid81decoder.length*2

w = where((apid eq '0881'X) and ccsdslen le apid81length-7 and ccsdslen gt 9,nw)    
if nw gt 0 and keyword_set(r81) then begin
	decomdata = bytarr(apid81length*nw)
	ngood = 0L

	for j = 0L,nw-1 do begin
		startbyte = w[j]
		comlength = (ccsdslen[w[j]]+7)

		if keyword_set(sync) then synced = (alldata[startbyte+comlength+2] eq '08'X and $
		((alldata[startbyte+comlength+3] eq '50'X) or (alldata[startbyte+comlength+3] eq '51'X) or $
		(alldata[startbyte+comlength+3] eq '53'X)  or (alldata[startbyte+comlength+3] eq '62'X))) else synced = 1

		if synced then begin
			combytes = alldata[startbyte:startbyte+comlength-1]
			if ccsdslen[w[j]] eq apid81length-7 then decombytes = combytes else decombytes = mvn_swia_packet_decompress(combytes)
		
			nlen = decombytes[4]*256+decombytes[5] 
		
			if nlen eq apid81length-7 and synced then begin
				decomdata[ngood*apid81length:ngood*apid81length+apid81length-1] = decombytes
				ngood = ngood+1
			endif
		endif
	endfor
		

	if ngood gt 0 then apid81 = replicate(apid81data,ngood)

	messagewords = lonarr(apid81length/2)
	ind = indgen(apid81length/2)
	
	for j = 0L,ngood-1 do begin
		startbyte = j*apid81length
		message = decomdata[startbyte:startbyte+apid81length-1]
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid81decoder,apid81data
		apid81[j] = apid81data
		if (j mod 5000) eq 0 then print,j,'/',ngood
	endfor
endif


print,'Reading APID82 Short (Fine Survey)'
mvn_swia_define_apid82, decoder = apid82decoder, data = apid82data
apid82length = apid82decoder.length*2

w = where((apid eq '0882'X) and ccsdslen le apid82length-7 and ccsdslen gt 9,nw)    
if nw gt 0 and keyword_set(r82s) then begin
	decomdata = bytarr(apid82length*nw)
	ngood = 0L

	for j = 0L,nw-1 do begin
		startbyte = w[j]
		comlength = (ccsdslen[w[j]]+7)

		if keyword_set(sync) then synced = (alldata[startbyte+comlength+2] eq '08'X and $
		((alldata[startbyte+comlength+3] eq '50'X) or (alldata[startbyte+comlength+3] eq '51'X) or $
		(alldata[startbyte+comlength+3] eq '53'X)  or (alldata[startbyte+comlength+3] eq '62'X))) else synced = 1

		if synced then begin
			combytes = alldata[startbyte:startbyte+comlength-1]
			if ccsdslen[w[j]] eq apid82length-7 then decombytes = combytes else decombytes = mvn_swia_packet_decompress(combytes)
		
			nlen = decombytes[4]*256+decombytes[5] 
		
			if nlen eq apid82length-7 and synced then begin
				decomdata[ngood*apid82length:ngood*apid82length+apid82length-1] = decombytes
				ngood = ngood+1
			endif
		endif
	endfor
		

	if ngood gt 0 then apid82short = replicate(apid82data,ngood)

	messagewords = lonarr(apid82length/2)
	ind = indgen(apid82length/2)
	
	for j = 0L,ngood-1 do begin
		startbyte = j*apid82length
		message = decomdata[startbyte:startbyte+apid82length-1]
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid82decoder,apid82data
		apid82short[j] = apid82data
		if (j mod 5000) eq 0 then print,j,'/',ngood
	endfor
endif


print,'Reading APID82 Long (Fine Survey)'
mvn_swia_define_apid82, decoder = apid82decoder, data = apid82data,/long
apid82length = apid82decoder.length*2

w = where((apid eq '0882'X) and ccsdslen le apid82length-7 and ccsdslen gt 9,nw)    
if nw gt 0 and keyword_set(r82l) then begin
	decomdata = bytarr(apid82length*nw)
	ngood = 0L

	for j = 0L,nw-1 do begin
		startbyte = w[j]
		comlength = (ccsdslen[w[j]]+7)

		if keyword_set(sync) then synced = (alldata[startbyte+comlength+2] eq '08'X and $
		((alldata[startbyte+comlength+3] eq '50'X) or (alldata[startbyte+comlength+3] eq '51'X) or $
		(alldata[startbyte+comlength+3] eq '53'X)  or (alldata[startbyte+comlength+3] eq '62'X))) else synced = 1
	
		if synced then begin
			combytes = alldata[startbyte:startbyte+comlength-1]
			if ccsdslen[w[j]] eq apid82length-7 then decombytes = combytes else decombytes = mvn_swia_packet_decompress(combytes)
		
			nlen = decombytes[4]*256+decombytes[5] 
		
			if nlen eq apid82length-7 and synced then begin
				decomdata[ngood*apid82length:ngood*apid82length+apid82length-1] = decombytes
				ngood = ngood+1
			endif
		endif
	endfor
		

	if ngood gt 0 then apid82long = replicate(apid82data,ngood)

	messagewords = lonarr(apid82length/2)
	ind = indgen(apid82length/2)
	
	for j = 0L,ngood-1 do begin
		startbyte = j*apid82length
		message = decomdata[startbyte:startbyte+apid82length-1]
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid82decoder,apid82data
		apid82long[j] = apid82data
		if (j mod 5000) eq 0 then print,j,'/',ngood
	endfor
endif


print,'Reading APID83 Short (Fine Archive)'
mvn_swia_define_apid83, decoder = apid83decoder, data = apid83data
apid83length = apid83decoder.length*2

w = where((apid eq '0883'X) and ccsdslen le apid83length-7 and ccsdslen gt 9,nw)    
if nw gt 0 and keyword_set(r83s) then begin
	decomdata = bytarr(apid83length*nw)
	ngood = 0L

	for j = 0L,nw-1 do begin
		startbyte = w[j]
		comlength = (ccsdslen[w[j]]+7)

		if keyword_set(sync) then synced = (alldata[startbyte+comlength+2] eq '08'X and $
		((alldata[startbyte+comlength+3] eq '50'X) or (alldata[startbyte+comlength+3] eq '51'X) or $
		(alldata[startbyte+comlength+3] eq '53'X)  or (alldata[startbyte+comlength+3] eq '62'X))) else synced = 1

		if synced then begin
			combytes = alldata[startbyte:startbyte+comlength-1]
			if ccsdslen[w[j]] eq apid83length-7 then decombytes = combytes else decombytes = mvn_swia_packet_decompress(combytes)
		
			nlen = decombytes[4]*256+decombytes[5] 

			if nlen eq apid83length-7 and synced then begin
				decomdata[ngood*apid83length:ngood*apid83length+apid83length-1] = decombytes
				ngood = ngood+1
			endif
		endif
	endfor
		

	if ngood gt 0 then apid83short = replicate(apid83data,ngood)

	messagewords = lonarr(apid83length/2)
	ind = indgen(apid83length/2)

	for j = 0L,ngood-1 do begin
		startbyte = j*apid83length
		message = decomdata[startbyte:startbyte+apid83length-1]
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid83decoder,apid83data
		apid83short[j] = apid83data
		if (j mod 5000) eq 0 then print,j,'/',ngood
	endfor
endif


print,'Reading APID83 Long (Fine Archive)'
mvn_swia_define_apid83, decoder = apid83decoder, data = apid83data,/long
apid83length = apid83decoder.length*2

w = where((apid eq '0883'X) and ccsdslen le apid83length-7 and ccsdslen gt 9,nw)    
if nw gt 0 and keyword_set(r83l) then begin
	decomdata = bytarr(apid83length*nw)
	ngood = 0L

	for j = 0L,nw-1 do begin
		startbyte = w[j]
		comlength = (ccsdslen[w[j]]+7)

		if keyword_set(sync) then synced = (alldata[startbyte+comlength+2] eq '08'X and $
		((alldata[startbyte+comlength+3] eq '50'X) or (alldata[startbyte+comlength+3] eq '51'X) or $
		(alldata[startbyte+comlength+3] eq '53'X)  or (alldata[startbyte+comlength+3] eq '62'X))) else synced = 1
	
		if synced then begin
			combytes = alldata[startbyte:startbyte+comlength-1]
			if ccsdslen[w[j]] eq apid83length-7 then decombytes = combytes else decombytes = mvn_swia_packet_decompress(combytes)
		
			nlen = decombytes[4]*256+decombytes[5] 
		
			if nlen eq apid83length-7 and synced then begin
				decomdata[ngood*apid83length:ngood*apid83length+apid83length-1] = decombytes
				ngood = ngood+1
			endif
		endif
	endfor
		

	if ngood gt 0 then apid83long = replicate(apid83data,ngood)

	messagewords = lonarr(apid83length/2)
	ind = indgen(apid83length/2)
	
	for j = 0L,ngood-1 do begin
		startbyte = j*apid83length
		message = decomdata[startbyte:startbyte+apid83length-1]
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid83decoder,apid83data
		apid83long[j] = apid83data
		if (j mod 5000) eq 0 then print,j,'/',ngood
	endfor
endif

print,'Reading APID84 (Raw Distributions)'
mvn_swia_define_apid84, decoder = apid84decoder, data = apid84data
apid84length = apid84decoder.length*2

w = where((apid eq '0884'X) and ccsdslen le apid84length-7 and ccsdslen gt 9,nw)    
if nw gt 0 and keyword_set(r84) then begin
	decomdata = bytarr(apid84length*nw)
	ngood = 0L

	for j = 0L,nw-1 do begin
		startbyte = w[j]
		comlength = (ccsdslen[w[j]]+7)
		
		if keyword_set(sync) then synced = (alldata[startbyte+comlength+2] eq '08'X and $
		((alldata[startbyte+comlength+3] eq '50'X) or (alldata[startbyte+comlength+3] eq '51'X) or $
		(alldata[startbyte+comlength+3] eq '53'X)  or (alldata[startbyte+comlength+3] eq '62'X))) else synced = 1

		if synced then begin
			combytes = alldata[startbyte:startbyte+comlength-1]
			if ccsdslen[w[j]] eq apid84length-7 then decombytes = combytes else decombytes = mvn_swia_packet_decompress(combytes)
		
			nlen = decombytes[4]*256+decombytes[5] 
		
			if nlen eq apid84length-7 and synced then begin
				decomdata[ngood*apid84length:ngood*apid84length+apid84length-1] = decombytes
				ngood = ngood+1
			endif
		endif
	endfor
		

	if ngood gt 0 then apid84 = replicate(apid84data,ngood)

	messagewords = lonarr(apid84length/2)
	ind = indgen(apid84length/2)
	
	for j = 0L,ngood-1 do begin
		startbyte = j*apid84length
		message = decomdata[startbyte:startbyte+apid84length-1]
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid84decoder,apid84data
		apid84[j] = apid84data
		if (j mod 5000) eq 0 then print,j,'/',ngood
	endfor
endif


print,'Reading APID85 (Moments)'
mvn_swia_define_apid85, decoder = apid85decoder, data = apid85data
apid85length = apid85decoder.length*2

w = where((apid eq '0885'X) and ccsdslen le apid85length-7 and ccsdslen gt 9,nw)    
if nw gt 0 and keyword_set(r85) then begin
	decomdata = bytarr(apid85length*nw)
	ngood = 0L

	for j = 0L,nw-1 do begin
		startbyte = w[j]
		comlength = (ccsdslen[w[j]]+7)
		
		if keyword_set(sync) then synced = (alldata[startbyte+comlength+2] eq '08'X and $
		((alldata[startbyte+comlength+3] eq '50'X) or (alldata[startbyte+comlength+3] eq '51'X) or $
		(alldata[startbyte+comlength+3] eq '53'X)  or (alldata[startbyte+comlength+3] eq '62'X))) else synced = 1

		if synced then begin
			combytes = alldata[startbyte:startbyte+comlength-1]
			if ccsdslen[w[j]] eq apid85length-7 then decombytes = combytes else decombytes = mvn_swia_packet_decompress(combytes)
			
			nlen = decombytes[4]*256+decombytes[5] 

			if nlen eq apid85length-7 and synced then begin	
				decomdata[ngood*apid85length:ngood*apid85length+apid85length-1] = decombytes
				ngood = ngood+1
			endif
		endif
	endfor
		

	if ngood gt 0 then apid85 = replicate(apid85data,ngood)

	messagewords = lonarr(apid85length/2)
	ind = indgen(apid85length/2)
	
	for j = 0L,ngood-1 do begin
		startbyte = j*apid85length
		message = decomdata[startbyte:startbyte+apid85length-1]
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid85decoder,apid85data
		apid85[j] = apid85data
		if (j mod 5000) eq 0 then print,j,'/',ngood
	endfor
endif


print,'Reading APID86 (Spectra)'
mvn_swia_define_apid86, decoder = apid86decoder, data = apid86data
apid86length = apid86decoder.length*2

w = where((apid eq '0886'X) and ccsdslen le apid86length-7 and ccsdslen gt 9,nw)    
if nw gt 0 and keyword_set(r86) then begin
	decomdata = bytarr(apid86length*nw)
	ngood = 0L

	for j = 0L,nw-1 do begin
		startbyte = w[j]
		comlength = (ccsdslen[w[j]]+7)

		if keyword_set(sync) then synced = (alldata[startbyte+comlength+2] eq '08'X and $
		((alldata[startbyte+comlength+3] eq '50'X) or (alldata[startbyte+comlength+3] eq '51'X) or $
		(alldata[startbyte+comlength+3] eq '53'X)  or (alldata[startbyte+comlength+3] eq '62'X))) else synced = 1


		if synced then begin
			combytes = alldata[startbyte:startbyte+comlength-1]
			if ccsdslen[w[j]] eq apid86length-7 then decombytes = combytes else decombytes = mvn_swia_packet_decompress(combytes)
		
			nlen = decombytes[4]*256+decombytes[5] 
		
			if nlen eq apid86length-7 and synced then begin
				decomdata[ngood*apid86length:ngood*apid86length+apid86length-1] = decombytes
				ngood = ngood+1
			endif
		endif
	endfor
		

	if ngood gt 0 then apid86 = replicate(apid86data,ngood)

	messagewords = lonarr(apid86length/2)
	ind = indgen(apid86length/2)
	
	for j = 0L,ngood-1 do begin
		startbyte = j*apid86length
		message = decomdata[startbyte:startbyte+apid86length-1]
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid86decoder,apid86data
		apid86[j] = apid86data
		if (j mod 5000) eq 0 then print,j,'/',ngood
	endfor
endif


print,'Reading APID87 (Fast Housekeeping)'
mvn_swia_define_apid87, decoder = apid87decoder, data = apid87data
apid87length = apid87decoder.length*2

w = where((apid eq '0887'X) and ccsdslen le apid87length-7 and ccsdslen gt 9,nw)    
if nw gt 0 and keyword_set(r87) then begin
	decomdata = bytarr(apid87length*nw)
	ngood = 0L

	for j = 0L,nw-1 do begin
		startbyte = w[j]
		comlength = (ccsdslen[w[j]]+7)
		
		if keyword_set(sync) then synced = (alldata[startbyte+comlength+2] eq '08'X and $
		((alldata[startbyte+comlength+3] eq '50'X) or (alldata[startbyte+comlength+3] eq '51'X) or $
		(alldata[startbyte+comlength+3] eq '53'X)  or (alldata[startbyte+comlength+3] eq '62'X))) else synced = 1

		if synced then begin
			combytes = alldata[startbyte:startbyte+comlength-1]
			if ccsdslen[w[j]] eq apid87length-7 then decombytes = combytes else decombytes = mvn_swia_packet_decompress(combytes)
		
			nlen = decombytes[4]*256+decombytes[5] 
		
			if nlen eq apid87length-7 and synced then begin
				decomdata[ngood*apid87length:ngood*apid87length+apid87length-1] = decombytes
				ngood = ngood+1
			endif
		endif
	endfor
		

	if ngood gt 0 then apid87 = replicate(apid87data,ngood)

	messagewords = lonarr(apid87length/2)
	ind = indgen(apid87length/2)
	
	for j = 0L,ngood-1 do begin
		startbyte = j*apid87length
		message = decomdata[startbyte:startbyte+apid87length-1]
		messagewords = 256L*message[ind*2] + message[ind*2+1]
		mvn_swia_packet_decode,messagewords,apid87decoder,apid87data
		apid87[j] = apid87data
		if (j mod 5000) eq 0 then print,j,'/',ngood
	endfor
endif


end