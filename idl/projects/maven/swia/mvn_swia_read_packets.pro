;+
;PROCEDURE: 
;	MVN_SWIA_READ_PACKETS
;PURPOSE: 
;	Routine to read in uncompressed SWIA packets from any telemetry file
;	(Not typically used anymore now that we routinely compress packets)
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_READ_PACKETS, File, APID29=APID29, APID80=APID80, APID81=APID81,
;	APID82SHORT=APID82SHORT, APID82LONG=APID82LONG, APID83SHORT=APID83SHORT,
;	APID83LONG=APID83LONG, APID84=APID84, APID85=APID85, APID86=APID86, APID87=APID87
;INPUTS: 
;	File: A filename to read packets from
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
; $LastChangedDate: 2013-03-05 12:01:26 -0800 (Tue, 05 Mar 2013) $
; $LastChangedRevision: 11695 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_read_packets.pro $
;
;-

pro mvn_swia_read_packets,file, apid29 = apid29,apid80 = apid80,apid81=apid81,apid82short = apid82short, apid82long = apid82long,apid83short = apid83short, apid83long = apid83long,apid84 = apid84,apid85 = apid85,apid86 = apid86,apid87 = apid87

alldata = read_binary(file)
nel = n_elements(alldata)

byte1 = alldata(lindgen(nel/2)*2)
byte2 = alldata(lindgen(nel/2)*2+1)
allwords = long(byte1)*256+long(byte2)
nel=nel/2
print,nel


apid = mvn_swia_subword(allwords,bit1 = 10,bit2 = 0)
ccsdslen = mvn_swia_subword(allwords,bit1=15,bit2=0)
ccsdslen = shift(ccsdslen,-2)

print,'Reading APID29'
w = where((apid eq '29'X) and ccsdslen eq 54*2-7,nw)    ;Analog Housekeeping
if nw gt 0 then begin
	mvn_swia_define_apid29, decoder = apid29decoder, data = apid29data
	apid29 = replicate(apid29data,nw)
	length = apid29decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid29decoder,apid29data
		apid29(j) = apid29data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif


print,'Reading APID80'
w = where((apid eq '80'X) and ccsdslen eq 528-7,nw)    ;Coarse Survey
if nw gt 0 then begin
	mvn_swia_define_apid80, decoder = apid80decoder, data = apid80data
	apid80 = replicate(apid80data,nw)
	length = apid80decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid80decoder,apid80data
		apid80(j) = apid80data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif


print,'Reading APID81'
w = where((apid eq '81'X) and ccsdslen eq 528-7,nw)    ;Coarse Survey
if nw gt 0 then begin
	mvn_swia_define_apid81, decoder = apid81decoder, data = apid81data
	apid81 = replicate(apid81data,nw)
	length = apid81decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid81decoder,apid81data
		apid81(j) = apid81data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif

print,'Reading APID82 Short'
w = where((apid eq '82'X) and ccsdslen eq 1552-7,nw)    ;Fine Survey Low-Res
if nw gt 0 then begin
	mvn_swia_define_apid82, decoder = apid82decoder, data = apid82data
	apid82short = replicate(apid82data,nw)
	length = apid82decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid82decoder,apid82data
		apid82short(j) = apid82data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif


print,'Reading APID82 Long'
w = where((apid eq '82'X) and ccsdslen eq 1936-7,nw)    ;Fine Survey High-Res
if nw gt 0 then begin
	mvn_swia_define_apid82, decoder = apid82decoder, data = apid82data,/long
	apid82long = replicate(apid82data,nw)
	length = apid82decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid82decoder,apid82data
		apid82long(j) = apid82data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif

print,'Reading APID83 Short'
w = where((apid eq '83'X) and ccsdslen eq 1552-7,nw)    ;Fine Survey Low-Res
if nw gt 0 then begin
	mvn_swia_define_apid83, decoder = apid83decoder, data = apid83data
	apid83short = replicate(apid83data,nw)
	length = apid83decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid83decoder,apid83data
		apid83short(j) = apid83data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif


print,'Reading APID83 Long'
w = where((apid eq '83'X) and ccsdslen eq 1936-7,nw)    ;Fine Survey High-Res
if nw gt 0 then begin
	mvn_swia_define_apid83, decoder = apid83decoder, data = apid83data,/long
	apid83long = replicate(apid83data,nw)
	length = apid83decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid83decoder,apid83data
		apid83long(j) = apid83data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif

print,'Reading APID84'
w = where((apid eq '84'X) and ccsdslen eq 1168-7,nw)    ;Raw
if nw gt 0 then begin
	mvn_swia_define_apid84, decoder = apid84decoder, data = apid84data
	apid84 = replicate(apid84data,nw)
	length = apid84decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid84decoder,apid84data
		apid84(j) = apid84data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif


print,'Reading APID85'
w = where((apid eq '85'X) and ccsdslen eq 432-7,nw)    ;Moments
if nw gt 0 then begin
	mvn_swia_define_apid85, decoder = apid85decoder, data = apid85data
	apid85 = replicate(apid85data,nw)
	length = apid85decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid85decoder,apid85data
		apid85(j) = apid85data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif


print,'Reading APID86'
w = where((apid eq '86'X) and ccsdslen eq 784-7,nw)    ;Spectra
if nw gt 0 then begin
	mvn_swia_define_apid86, decoder = apid86decoder, data = apid86data
	apid86 = replicate(apid86data,nw)
	length = apid86decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid86decoder,apid86data
		apid86(j) = apid86data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif


print,'Reading APID87'
w = where((apid eq '87'X) and ccsdslen eq 2320-7,nw)    ;Fast Housekeeping
if nw gt 0 then begin
	mvn_swia_define_apid87, decoder = apid87decoder, data = apid87data
	apid87 = replicate(apid87data,nw)
	length = apid87decoder.length
	
	for j = 0L,nw-1 do begin
		startword = w(j)
		message = allwords(startword:startword+length-1)
		mvn_swia_packet_decode,message,apid87decoder,apid87data
		apid87(j) = apid87data
		if (j mod 5000) eq 0 then print,j,'/',nw
	endfor
endif


end