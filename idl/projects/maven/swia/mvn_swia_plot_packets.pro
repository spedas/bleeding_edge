;+
;PROCEDURE: 
;	MVN_SWIA_PLOT_PACKETS
;PURPOSE: 
;	Routine to generate Tplot variables from SWIA packets (arrays of structures)
;	(Will not be typically used once I have everything stored in common blocks)
;	(Does not work well when modes change)
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_PLOT_PACKETS, /DECOMP, APID29=APID29, APID80=APID80, APID82SHORT=APID82SHORT, 
;	APID82LONG=APID82LONG, APID84=APID84, APID85=APID85, APID86=APID86, APID87=APID87
;KEYWORDS: 
;	DECOMP: Log-decompress all counts
;OPTIONAL INPUTS:
;	APID29: Housekeeping packets 
;	APID80: Coarse Archive/Survey packets
;	APID82SHORT: Fine Archive/Survey packets (small version)
;	APID82LONG: Fine Archive/Survey packets (large version)
;	APID84: Raw Survey
;	APID85: Moments
;	APID86: Spectra
;	APID87: Fast Housekeeping
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-03-05 12:01:26 -0800 (Tue, 05 Mar 2013) $
; $LastChangedRevision: 11695 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_plot_packets.pro $
;
;-

pro mvn_swia_plot_packets, apid29=apid29, apid80=apid80, apid82short=apid82short, apid82long=apid82long, apid84 = apid84, apid85=apid85, apid86=apid86, apid87 = apid87, decomp = decomp

e0 = 5.0                        ;start of energy sweep
deovere = 0.094                 ;spacing of energy steps

energy = e0*(1+deovere)^(95-findgen(96))
phi1 = [-146.25,-123.75,-101.25,-78.75,-56.25,-33.75,-11.25,11.25,33.75,56.25,78.75,101.25,123.75,146.25,168.75,-168.75+360]
phi2=[-20.25,-15.75,-11.25,-6.75,-2.25,2.25,6.75,11.25,15.75,20.25]
phi2 = phi2 + 180

if keyword_set(apid29) then begin

	nel = n_elements(apid29)
	
	time = apid29.clock1*65536.d + apid29.clock2+time_double('2000-01-01/12:00')
	
	sk = apid29.lpvst*1.0
	ltemp = 165+sk*3.94e-2+sk*sk*5.68e-6+sk^3*4.43e-10+sk^4*1.67e-14+sk^5*2.42e-19
	sk = apid29.digt*1.0
	dtemp = 165+sk*3.94e-2+sk*sk*5.68e-6+sk^3*4.43e-10+sk^4*1.67e-14+sk^5*2.42e-19

	imon_mcp = apid29.mcphvi*(-5.0/32678/.051)
	vmon_mcp = apid29.mcphv*(-5.0/32678/.00133)
	defrawi = apid29.defrawi*(-5.0/32678/.2)
	defrawv = apid29.defrawv*(-5.0/32678/.000805)
	swprawv = apid29.swprawv*(-5.0/32678/.000805)
	vmon_swp = apid29.analhv*(-5.0/32678/(-0.001))
	vmon_def1 = apid29.def1hv*(-5.0/32678/0.001)
	vmon_def2 = apid29.def2hv*(-5.0/32678/0.001)
	v25d = apid29.p2p5dv*(-5.0/32678/0.901)
	v5d = apid29.p5dv*(-5.0/32678/0.801)
	v33d = apid29.p3p3dv*(-5.0/32678/0.901)
	v5a = apid29.p5av*(-5.0/32678/0.801)
	vn5a = apid29.n5av*(-5.0/32678/0.801)
	v28 = apid29.p28v*(-5.0/32678/0.145)
	v12 = apid29.p12v*(-5.0/32678/0.332)
	
	store_data,'lvspt',data = {x:time,y:ltemp}
	store_data,'digt',data = {x:time,y:dtemp}
	store_data,'imon_mcp',data = {x:time,y:imon_mcp}
	store_data,'vmon_mcp',data = {x:time,y:vmon_mcp}
	store_data,'imon_swp_raw',data = {x:time,y:defrawi}
	store_data,'vmon_def_raw',data = {x:time,y:defrawv}
	store_data,'vmon_def_swp',data = {x:time,y:swprawv}
	store_data,'vmon_swp',data = {x:time,y:vmon_swp}
	store_data,'vmon_def1',data = {x:time,y:vmon_def1}
	store_data,'vmon_def2',data = {x:time,y:vmon_def2}
	store_data,'v25d',data = {x:time,y:v25d}
	store_data,'v5d',data = {x:time,y:v5d}
	store_data,'v33d',data = {x:time,y:v33d}
	store_data,'v5a',data = {x:time,y:v5a}
	store_data,'vn5a',data = {x:time,y:vn5a}
	store_data,'v28',data = {x:time,y:v28}
	store_data,'v12',data = {x:time,y:v12}
	store_data,'modexy',data = {x:time,y:[[apid29.modex],[apid29.modey]],psym:10,v:[0,1]}
	store_data,'att',data = {x:time,y:[[apid29.attt1],[apid29.attt2]],psym:10,v:[0,1]}
	store_data,'dighsk',data = {x:time,y:[[mvn_swia_subword(apid29.dighsk,bit1=7,bit2=7)],[mvn_swia_subword(apid29.dighsk,bit1=3,bit2=3)],[mvn_swia_subword(apid29.dighsk,bit1=2,bit2=2)]],v:[0,1,2],spec:1,no_interp:1}
	store_data,'trates',data = {x:time,y:[[apid29.csvy],[apid29.carc],[apid29.fsvy],[apid29.farc],[apid29.msvy],[apid29.ssvy]],labels:['CS','CA','FS','FA','MS','SS'],v:[0,1,2,3,4,5],labflag:1,psym:10}
	store_data,'diagdata',data = {x:time,y:[[mvn_swia_subword(apid29.diagdata,bit1=15,bit2=15)],[mvn_swia_subword(apid29.diagdata,bit1=14,bit2=12)],[mvn_swia_subword(apid29.diagdata,bit1=11,bit2=11)],[mvn_swia_subword(apid29.diagdata,bit1=10,bit2=10)],[mvn_swia_subword(apid29.diagdata,bit1=9,bit2=0)]],v:[0,1,2,3,4],labels:['slut','diag','enbswp','p1mode','mask'],labflag:1,psym:10}
endif

if keyword_set(apid80) then begin
	nel = n_elements(apid80)
	time = apid80.clock1*65536.d + apid80.clock2 + apid80.subsec/65536.d + time_double('2000-01-01/12:00')
	
	w = where(apid80.grouping eq 0,nw)
	if nw gt 0 then begin
		ww = where(apid80(w).packetseq eq 0,nww)
		if ww(0) ne -1 then begin
			w = w(ww(0):nw-1)
			nw = n_elements(w)
			nprod0 = floor(nw/6)
			if nprod0 gt 0 then begin
				w = w(0:nprod0*6-1)
				time0 = time(w(indgen(nprod0)*6))
				timep = time0+2^apid80(w).grouping*2
				prod0 = apid80(w).counts
				if keyword_set(decomp) then mvn_swia_log_decomp,prod0
				
				espec = fltarr(nprod0,48)
				aspec = fltarr(16,nprod0*192)
				
				time1 = rebin(time0,nprod0*192)
				
				for i = 0L,nprod0-1 do begin
					iprod0 = reform(prod0(*,i*6:i*6+5),16,4,48)
					espec(i,*) = transpose(total(total(iprod0,1),1))
					
					iprod1 = reform(prod0(*,i*6:i*6+5),16,192)
					aspec(*,i*192.:i*192.+191) = iprod1
				endfor
				
				store_data,'apid80espec2',data = {x:timep,y:espec,v:rebin(energy,48),spec:1,no_interp:1,ylog:1}
				store_data,'apid80aspec2',data = {x:time1,y:transpose(aspec),v:phi1,spec:1,no_interp:1}
	
			endif
		endif
	endif

	w = where(apid80.grouping eq 1,nw)
	if nw gt 0 then begin
		ww = where(apid80(w).packetseq eq 0,nww)
		if ww(0) ne -1 then begin
			w = w(ww(0):nw-1)
			nw = n_elements(w)
			nprod0 = floor(nw/3)
			if nprod0 gt 0 then begin
				w = w(0:nprod0*3-1)
				time0 = time(w(indgen(nprod0)*3))
				timep = time0+2^apid80(w).grouping*2
				prod0 = apid80(w).counts
				if keyword_set(decomp) then mvn_swia_log_decomp,prod0
		
				espec = fltarr(nprod0,24)
				aspec = fltarr(16,nprod0*96)
				
				time1 = rebin(time0,nprod0*96)
				
				for i = 0L,nprod0-1 do begin
					iprod0 = reform(prod0(*,i*3:i*3+2),16,4,24)
					espec(i,*) = transpose(total(total(iprod0,1),1))
					
					iprod1 = reform(prod0(*,i*3:i*3+2),16,96)
					aspec(*,i*96.:i*96.+95) = iprod1
				endfor
				
				store_data,'apid80espec2',data = {x:timep,y:espec,v:rebin(energy,24),spec:1,no_interp:1,ylog:1}
				store_data,'apid80aspec2',data = {x:time1,y:transpose(aspec),v:phi1,spec:1,no_interp:1}
	
			endif
		endif
	endif

	w = where(apid80.grouping eq 2,nw)
	if nw gt 0 then begin
		ww = where(apid80(w).packetseq eq 0,nww)
		if ww(0) ne -1 then begin
			w = w(ww(0):nw-1)
			nw = n_elements(w)
			nprod0 = floor(nw/2)
			if nprod0 gt 0 then begin
				w = w(0:nprod0*2-1)
				time0 = time(w(indgen(nprod0)*2))
				timep = time0+2^apid80(w).grouping*2
				prod0 = apid80(w).counts
				if keyword_set(decomp) then mvn_swia_log_decomp,prod0
	
				espec = fltarr(nprod0,16)
				aspec = fltarr(16,nprod0*64)
				
				time1 = rebin(time0,nprod0*64)
				
				for i = 0L,nprod0-1 do begin
					iprod0 = reform(prod0(*,i*2:i*2+1),16,4,16)
					espec(i,*) = transpose(total(total(iprod0,1),1))
					
					iprod1 = reform(prod0(*,i*2:i*2+1),16,64)
					aspec(*,i*64.:i*64.+63) = iprod1
				endfor
				
				store_data,'apid80espec2',data = {x:timep,y:espec,v:rebin(energy,16),spec:1,no_interp:1,ylog:1}
				store_data,'apid80aspec2',data = {x:time1,y:transpose(aspec),v:phi1,spec:1,no_interp:1}
	
			endif
		endif
	endif


endif

if keyword_set(apid82short) then begin

	nel = n_elements(apid82short)
	time = apid82short.clock1*65536.d + apid82short.clock2 + apid82short.subsec/65536.d + time_double('2000-01-01/12:00') -4.0 ;one cycle shift
	timep = time + 2^apid82short.accumper*2

	cc = apid82short.counts
	if keyword_set(decomp) then mvn_swia_log_decomp,cc
	
	espec = fltarr(nel,32)
	aspec = fltarr(6,nel*256)
	
	time1 = rebin(time,nel*256)

	for i = 0L,nel-1 do begin
		iprod0 = reform(cc(*,i),6,8,32)
		espec(i,*) = transpose(total(total(iprod0,1),1))
		
		iprod1 = reform(cc(*,i),6,256)
		aspec(*,i*256.:i*256.+255) = iprod1
	endfor

	efull = fltarr(nel,96)
	esf = fltarr(nel)
	
	for i = 0,nel-1 do begin
		esf(i) = (apid82short(i).estepfirst >0) <48
		efull(i,esf(i)+8:esf(i)+39) = espec(i,*)
	endfor
	
	store_data,'apid82espec1',data = {x:timep,y:espec,v:findgen(32),spec:1,no_interp:1}
	store_data,'apid82espec1f',data = {x:timep,y:efull,v:energy,spec:1,no_interp:1,ylog:1}
	store_data,'estepfirst',data = {x:timep,y:energy(esf),psym:10}
	store_data,'apid82espec1fc',data = "apid82espec1f estepfirst"
	options,'apid82espec1fc','yrange',[5,25000]
	store_data,'apid82aspec1',data = {x:time1,y:transpose(aspec),v:phi2(2:7),spec:1,no_interp:1}
	
endif

if keyword_set(apid82long) then begin
	w = where(apid82long.seqcount mod 3 eq 0)
	shift = w(0)
	nel = n_elements(apid82long)-shift
	nel = nel-(nel mod 3)
	time = apid82long.clock1*65536.d + apid82long.clock2 + apid82long.subsec/65536.d + time_double('2000-01-01/12:00') -4.0 ;one cycle shift



	cc = apid82long.counts
	if keyword_set(decomp) then mvn_swia_log_decomp,cc
	
	espec = fltarr(floor(nel/3),48)
	aspec = fltarr(10,floor(nel/3)*576)
	
	time0 = time(shift+indgen(floor(nel/3))*3)
	timep = time0 + 2^apid82long.accumper*2
	time1 = rebin(time(shift:nel+shift-1),floor(nel/3)*576)

	for i = 0L,floor(nel/3)-1 do begin
		iprod0 = reform(cc(*,i*3+shift:i*3+2+shift),10,12,48)
		espec(i,*) = transpose(total(total(iprod0,1),1))
		
		iprod1 = reform(cc(*,i*3+shift:i*3+2+shift),10,576)
		aspec(*,i*576.:i*576.+575) = iprod1
	endfor

	efull = fltarr(nel,96)
	esf = fltarr(nel/3)
	
	for i = 0,nel/3-1 do begin
		esf(i) = (apid82long(i*3+shift).estepfirst > 0) <48
		efull(i,esf(i):esf(i)+47) = espec(i,*)
	endfor
	
	store_data,'apid82espec2',data = {x:timep,y:espec,v:findgen(48),spec:1,no_interp:1}
	store_data,'apid82espec2f',data = {x:timep,y:efull,v:energy,spec:1,no_interp:1,ylog:1}
	store_data,'estepfirst2',data = {x:timep,y:energy(esf),psym:10}
	store_data,'apid82espec2fc',data = "apid82espec2f estepfirst2"
	options,'apid82espec2fc','yrange',[5,25000]
	store_data,'apid82aspec2',data = {x:time1,y:transpose(aspec),v:phi2,spec:1,no_interp:1}
	
endif

if keyword_set(apid84) then begin
	nel = n_elements(apid84)
	time = apid84.clock1*65536.d + apid84.clock2 + apid84.subsec/65536.d + time_double('2000-01-01/12:00')

	counts = reform(apid84.counts,24,nel*48)
	if keyword_set(decomp) then mvn_swia_log_decomp,counts
	
	time1 = rebin(time,nel*48)
	
	store_data,'apid84',data = {x:time1,y:transpose(counts),v:[phi1(0:13),phi2],spec:1,no_interp:1}
endif

if keyword_set(apid85) then begin
	
	nel = n_elements(apid85)
	time = apid85.clock1*65536.d + apid85.clock2 + apid85.subsec/65536.d + time_double('2000-01-01/12:00')

	if n_elements(time) eq 1 then begin
		time1 = time(0)+findgen(16)*4*2.0^apid85(0).accumper
	endif else begin
		time1 = dblarr(nel*16L)
		for i = 0L,nel-1 do begin
			time1(i*16:i*16+15) = time(i)+findgen(16)*4*2.0^apid85(i).accumper + 2.0^apid85(0).accumper*2.0
		endfor
	endelse

	mom = fltarr(nel*16,13)
	
	for i = 0,nel-1 do begin
		for j = 0,15 do begin
			mom(i*16+j,*) = apid85(i).moments(j*13:j*13+12)
		endfor
	endfor
	
	mvn_swia_moment_decom,mom,momout
	

	store_data,'apid85',data = {x:time1,y:momout,v:indgen(13),spec:0,no_interp:1,labels:['N','NVx','Nvy','Nvz','NPxx','Npyy','Npzz','Npxy','Npxz','Npyz','NHx','NHy','NHz'],labflag:1}
	
	
	
	mf0 = fltarr(nel)
	mf1 = fltarr(nel)
	mf2 = fltarr(nel)
	mf3 = fltarr(nel)
	sf = fltarr(nel)
	dt = fltarr(nel)
	deovere = fltarr(nel)
	dang = fltarr(nel)
	
	w = where(apid85.swimode eq 1 and apid85.attenpos eq 1)
	if w(0) ne -1 then begin
		dt(w) = 0.0204
		mf0(w) = 1.0698e8
		mf1(w) = 1.1185e7
		mf2(w) = 2.9962e5
		mf3(w) = 3.6264e3
		sf(w) = 1899.59
		deovere(w) = 0.188
		dang(w) = 2*!pi/16
	endif 
	
	w = where(apid85.swimode eq 1 and (apid85.attenpos eq 2 or apid85.attenpos eq 3))
	if w(0) ne -1 then begin
		dt(w) = 0.0204
		mf0(w) = 1.0698e8
		mf1(w) = 1.1185e7
		mf2(w) = 2.9962e5
		mf3(w) = 3.6264e3
		sf(w) = 518.33
		deovere(w) = 0.188
		dang(w) = 2*!pi/16
	endif
	
	w = where(apid85.swimode eq 0)
	if w(0) ne -1 then begin
		dt(w) = 0.0017
		mf0(w) = 5.3837e9
		mf1(w) = 4.4739e7
		mf2(w) = 3.0099e5
		mf3(w) = 2.2071e3
		sf(w) = 3276.80
		deovere(w) = 0.094
		dang(w) = 3.75*!pi/180
	endif
	
	
	mf0 = rebin(mf0,nel*16,/sample)
	mf1 = rebin(mf1,nel*16,/sample)
	mf2 = rebin(mf2,nel*16,/sample)
	mf3 = rebin(mf3,nel*16,/sample)
	sf = rebin(sf,nel*16,/sample)
	dt = rebin(dt,nel*16,/sample)
	deovere = rebin(deovere,nel*16,/sample)
	dang = rebin(dang,nel*16,/sample)
	intconst = replicate(7.22457e-7,nel*16)
	geom  = replicate(0.0056,nel*16)
	mass  = replicate(1.67022e-24,nel*16)

	dens = momout(*,0) / mf0 /sf * dang * deovere * 2*!pi/dt/geom * intconst
	store_data,'densmom',data = {x:time1,y:dens,ylog:1,psym:-4,yrange:[1e-2,1e4]}
	
	vx = momout(*,1) / mf1 /sf * dang * deovere * 2*!pi/dt/geom * 1e-5/(dens>1e-4)
	vy = momout(*,2) / mf1 /sf * dang * deovere * 2*!pi/dt/geom * 1e-5/(dens>1e-4)
	vz = momout(*,3) / mf1 /sf * dang * deovere * 2*!pi/dt/geom * 1e-5/(dens>1e-4)

	store_data,'velmom',data = {x:time1,y:[[vx],[vy],[vz]],v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,psym:-4}
	
	pxx = (momout(*,4) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vx*vx*1e10*dens)/1.6e-12
	pyy = (momout(*,5) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vy*vy*1e10*dens)/1.6e-12
	pzz = (momout(*,6) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vz*vz*1e10*dens)/1.6e-12
	pxy = (momout(*,7) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vx*vy*1e10*dens)/1.6e-12
	pxz = (momout(*,8) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vx*vz*1e10*dens)/1.6e-12
	pyz = (momout(*,9) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vy*vz*1e10*dens)/1.6e-12

	
	store_data,'pmom',data = {x:time1,y:[[pxx],[pyy],[pzz],[pxy],[pxz],[pyz]],labels:['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'],psym:-4,labflag:1}
	
	tx = pxx/(dens>1e-4)
	ty = pyy/(dens>1e-4)
	tz = pzz/(dens>1e-4)
	
	store_data,'tmom',data = {x:time1,y:[[tx],[ty],[tz]],labels:['Tx','Ty','Tz'],labflag:1,psym:-4}
	
	qx = momout(*,10) / mf3 /sf * dang * deovere * 2*!pi/dt/geom * 1.6e-12
	qy = momout(*,11) / mf3 /sf * dang * deovere * 2*!pi/dt/geom * 1.6e-12
	qz = momout(*,12) / mf3 /sf * dang * deovere * 2*!pi/dt/geom * 1.6e-12

	store_data,'qmom',data = {x:time1,y:[[qx],[qy],[qz]],labels:['Qx','Qy','Qz'],labflag:1,psym:-4}

endif

if keyword_set(apid86) then begin
	
	nel = n_elements(apid86)
	time = apid86.clock1*65536.d + apid86.clock2 + apid86.subsec/65536.d + time_double('2000-01-01/12:00')

	if n_elements(time) eq 1 then begin
		time1 = time(0)+findgen(16)*4*2.0^apid86(0).accumper
	endif else begin
		time1 = dblarr(nel*16L)
		for i = 0L,nel-1 do begin
			time1(i*16:i*16+15) = time(i)+findgen(16)*4*2.0^apid86(i).accumper + 2.0^apid86(i).accumper*2.0
		endfor
	endelse

	cc = fltarr(nel*16,48)
	
	for i = 0,nel-1 do begin
		for j = 0,15 do begin
			cc(i*16+j,*) = apid86(i).spectra(j*48:j*48+47)
		endfor
	endfor
	
	if keyword_set(decomp) then mvn_swia_log_decomp,cc
	

	store_data,'apid86',data = {x:time1,y:cc,v:rebin(energy,48),spec:1,no_interp:1,ylog:1}
	
endif

if keyword_set(apid87) then begin
	nel = n_elements(apid87)
	time = apid87.clock1*65536.d + apid87.clock2 + apid87.subsec/65536.d + time_double('2000-01-01/12:00')
	
	time1 = dblarr(nel*1152L)
	for i = 0L,nel-1 do begin
		time1(i*1152:i*1152+1151) = time(i) + findgen(1152)*4.0/1152
	endfor	
	
	divider = [0,0.051,0.00133,0.2,0.000805,0.000805,1,1,-0.001,1,0.001,1,0.001,1,1,1,0,0.901,0.801,0.901,0.801,0.801,0.145,0.332]

	conv = -5.0/(32768)/divider

	uc = fltarr(nel)
	for i = 0,nel-1 do uc(i) = conv(apid87(i).mux)
	
	ucn = rebin(uc,nel*1152,/sample)
	
	
	store_data,'apid87',data = {x:time1,y:reform(apid87.adc,nel*1152)*ucn}
	
endif

end
	
	