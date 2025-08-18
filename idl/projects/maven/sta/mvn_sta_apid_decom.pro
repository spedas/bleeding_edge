function mvn_sta_apid_decom,ccsds,lastpkt=lastpkt,apid=apid,pcyc=pcyc,len=len

;return, {time:ccsds.time, mode:1}

;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
data = mvn_pfdpu_part_decompress_data(ccsds)
;data = ccsds.data

if not keyword_set(lastpkt) then nolstpkt = 0 else nolstpkt=1
if not keyword_set(lastpkt) then lastpkt = ccsds
;last = mvn_pfdpu_part_decompress_data(lastpkt)
last = lastpkt.data


	subsec1 = data[0]/256.d 
	subsec2 = data[1]/(256.d)^2
	lstsub1 = last[0]/256.d 
	lstsub2 = last[1]/(256.d)^2
	time = ccsds.time + subsec1 + subsec2
	met  = ccsds.met  + subsec1 + subsec2
	lasttime = lastpkt.time + lstsub1 + lstsub2

	nn = 2^(7 and data[3])
	ss = (8 and data[3])/2^3
	if ss eq 0 then n2=1 else n2=nn
	lstnn = 2^(7 and last[3])
	pp = (15 and data[5])
	lpcyc=pcyc

	if time lt time_double('2013-07-01') then offset = 4.d	else offset=0.d		; this adjusts for a DWC software fix
	if apid eq 'DA' then begin 
		offset=0.d  
		pp = 0
		gg=[64,128,256,1024]
		nd = gg[(48 and data[3])/2^4]
		nm = 1024/nd
;		n2 = n2*nm
		n2 = 0									; this is easier than trying to plot center time 
		ld = gg[(48 and last[3])/2^4]
		lm = 1024/ld
		lstnn = lstnn*lm
		lpcyc=lastpkt.size-16
;		lpcyc=n_elements(last) - 6
	endif
	if apid eq 'D9' or apid eq 'D8' then offset=0.d


; 	printdat,ccsds
;	print,time-lasttime,' ',time_string(time),' ',time_string(lasttime),

;	npts=ccsds.size-16
	npts=n_elements(data) - 6
	lpts=lastpkt.size-16
;	lpts=n_elements(last) - 6

	ncyc = npts/pcyc
	lcyc = lpts/lpcyc


;	if abs(time-lasttime-4.*lcyc*lstnn) gt 0.01 and nolstpkt and (pp eq 0) then print,'Error: ',apid,' pkt time jump ',time-lasttime,' ',time_string(time),' ',time_string(lasttime)
;	if abs(time-lasttime-4.*lcyc*lstnn) gt 0.01 and nolstpkt and (pp eq 0) then print,'Error: ',apid,' pkt time jump ',time-lasttime
;	if npts ne len then print,'Error in APID ',apid,' - length: ',npts,'  Should be ',len,'  ', time_string(ccsds.time)
;	if npts ne len then print,'Error in APID ',apid,' - length: ',npts,'  Should be ',len
	if (npts mod pcyc) ne 0 then begin
;		print,'Error in APID ',apid,' - length: ',npts,' pts_cyc= ',pcyc,'  ', time_string(ccsds.time)
;		print,'Error in APID ',apid,' - length: ',npts,' pts_cyc= ',pcyc
		if apid eq 'DA' then begin
			pad = bytarr(len - npts) & pad(*)=255
			data = [data,pad]
			ncyc=1
;			data[6+npts:1029] = !values.f_nan
;			if npts eq 0 then return, {time:ccsds.time,valid: 0}
		endif else begin
			npts=npts - (npts mod pcyc)
			ncyc = npts/pcyc
			if npts eq 0 then return, {time:ccsds.time,valid: 0}
		endelse
	endif


;print,apid,' ',ccsds.seq_cntr,'  ',npts,'  ',nn,'  ',lstnn,'  ',time-lasttime-4.*lcyc*lstnn,'   ',time_string(time),'  ',time_string(lasttime)

if 0 then begin
str = {time: time - offset + 2.d*n2 + 4.d*nn*findgen(ncyc),$
;       subsec1:  subsec1,$
;       subsec2:  subsec2,$
;       subsec1b:  data[0],$
;       subsec2b:  data[1],$
;       dtime:  time - lasttime,$
	met: met - offset + 2.d*n2 + 4.d*nn*findgen(ncyc),$
	seq_cntr:  ccsds.seq_cntr#replicate(1,ncyc)   ,$
;       seq_dcntr:  fix( ccsds.seq_cntr - lastpkt.seq_cntr )   ,$
	valid: 1#replicate(1,ncyc)  ,$
;       mode: data[2]#replicate(1,ncyc)  ,$
	mode: byte((data[2] and 127)#replicate(1,ncyc))  ,$
	avg:  byte(data[3]#replicate(1,ncyc))  ,$
	atten: byte(data[4]#replicate(1,ncyc))  ,$
	diag: byte(data[5]#replicate(1,ncyc))  ,$
	data : reform(data[6:pcyc*ncyc+5],pcyc,ncyc) }
endif

str2 = {time: 0.d ,$
	met: 0.d, $
       seq_cntr:  ccsds.seq_cntr ,$
;       seq_dcntr:  fix( ccsds.seq_cntr - lastpkt.seq_cntr )   ,$
       valid: 1 ,$
;       mode: data[2] ,$
       mode: byte(data[2] and 127) ,$
       avg:  byte(data[3])  ,$
       atten: byte(data[4])  ,$
       diag: byte(data[5])  ,$
       data : bytarr(pcyc) }

	str = replicate(str2,ncyc)
	str.time = time - offset + 2.d*n2 + 4.d*nn*findgen(ncyc)
	str.met  = met  - offset + 2.d*n2 + 4.d*nn*findgen(ncyc)
	str.data = reform(data[6:pcyc*ncyc+5],pcyc,ncyc)

lastpkt = ccsds

return, str
end

