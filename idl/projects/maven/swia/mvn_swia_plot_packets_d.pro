;+
;PROCEDURE: 
;	MVN_SWIA_PLOT_PACKETS_D
;PURPOSE: 
;	Routine to generate Tplot variables from SWIA packets (arrays of structures)
;	Unlike MVN_SWIA_PLOT_PACKETS, everything is plotted on a common 4s resolution grid,
;	which works a lot better when modes change, etc.
;	(Will not be typically used once I have everything stored in common blocks)
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_PLOT_PACKETS_D, /DECOMP, APID29=APID29, APID80=APID80, APID82SHORT=APID82SHORT, 
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_plot_packets_d.pro $
;
;-

pro mvn_swia_plot_packets_d, apid29=apid29, apid80=apid80, apid82short=apid82short, apid82long=apid82long, apid84 = apid84, apid85=apid85, apid86=apid86, apid87 = apid87, decomp = decomp
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
	store_data,'dighsk',data = {x:time,y:[[mvn_swia_subword(apid29.dighsk,bit1=7,bit2=7)],[mvn_swia_subword(apid29.dighsk,bit1=3,bit2=3)],[mvn_swia_subword(apid29.dighsk,bit1=2,bit2=2)]],v:[0,1,2],spec:1,no_interp:1,psym:10}
	store_data,'trates',data = {x:time,y:[[apid29.csvy],[apid29.carc],[apid29.fsvy],[apid29.farc],[apid29.msvy],[apid29.ssvy]],labels:['CS','CA','FS','FA','MS','SS'],v:[0,1,2,3,4,5],labflag:1,psym:10}
	store_data,'diagdata',data = {x:time,y:[[mvn_swia_subword(apid29.diagdata,bit1=15,bit2=15)],[mvn_swia_subword(apid29.diagdata,bit1=14,bit2=12)],[mvn_swia_subword(apid29.diagdata,bit1=11,bit2=11)],[mvn_swia_subword(apid29.diagdata,bit1=10,bit2=10)],[mvn_swia_subword(apid29.diagdata,bit1=9,bit2=0)]],v:[0,1,2,3,4],labels:['slut','diag','enbswp','p1mode','mask'],labflag:1,psym:10}
endif

if keyword_set(apid80) then begin
	nel = n_elements(apid80)
	time = apid80.clock1*65536.d + apid80.clock2 + apid80.subsec/65536.d + time_double('2000-01-01/12:00')

	dtime = time(nel-1)-time(0)
	ntime = dtime/4 + 512
	timebase = time(0)-1024 + findgen(ntime)*4.00000116
	espec80 = fltarr(ntime,48)
	aspec80 = fltarr(ntime,16)
	
	
	w = where(apid80.grouping eq 0,nw)
	if nw gt 0 then begin

		for i = 0L,nw-1 do begin
			prod = apid80(w(i)).counts
			if keyword_set(decomp) then mvn_swia_log_decomp,prod
			ind = where(abs(timebase-time(w(i))) lt 1.99) 
			
			iprod = reform(prod,16,4,8)
			
			if ind ne -1 then begin
				step = apid80(w(i)).packetseq
				espec80(ind,step*8:(step+1)*8-1) = transpose(total(total(iprod,1),1))
				aspec80(ind,*) = aspec80(ind,*) + transpose(total(total(iprod,2),2))
			endif			
					
		endfor
	
	
	endif

	w = where(apid80.grouping eq 1,nw)
	if nw gt 0 then begin
		for i = 0L,nw-1 do begin
			prod = apid80(w(i)).counts
			if keyword_set(decomp) then mvn_swia_log_decomp,prod
			ind = where(abs(timebase-time(w(i))) lt 1.99) 
			
			iprod = reform(prod,16,4,8)
			
			if ind ne -1 then begin
				step = apid80(w(i)).packetseq
				espec80(ind,step*16:(step+1)*16-1) = transpose(rebin((total(total(iprod,1),1)),16,/sample))
				aspec80(ind,*) = aspec80(ind,*) + transpose(total(total(iprod,2),2))
			endif			
					
		endfor
	endif


	w = where(apid80.grouping eq 2,nw)
	if nw gt 0 then begin
		for i = 0L,nw-1 do begin
			prod = apid80(w(i)).counts
			if keyword_set(decomp) then mvn_swia_log_decomp,prod
			ind = where(abs(timebase-time(w(i))) lt 1.99) 
			
			iprod = reform(prod,16,4,8)
			
			if ind ne -1 then begin
				step = apid80(w(i)).packetseq
				espec80(ind,step*24:(step+1)*24-1) = transpose(rebin((total(total(iprod,1),1)),24,/sample))
				aspec80(ind,*) = aspec80(ind,*) + transpose(total(total(iprod,2),2))
			endif			
					
		endfor
	endif

	store_data,'apid80especd',data = {x:timebase,y:espec80,v:rebin(energy,48),spec:1,no_interp:1,ylog:1}
	store_data,'apid80aspecd',data = {x:timebase,y:aspec80,v:phi1,spec:1,no_interp:1}


endif

if keyword_set(apid82short) then begin

	nel = n_elements(apid82short)
	time = apid82short.clock1*65536.d + apid82short.clock2 + apid82short.subsec/65536.d + time_double('2000-01-01/12:00') -4.0 ;one cycle shift

	if not keyword_set(apid80) then begin
		dtime = time(nel-1)-time(0)
		ntime = dtime/4 + 512
		timebase = time(0)-1024 + findgen(ntime)*4.00000116
	endif

	espec82 = fltarr(ntime,32)
	aspec82 = fltarr(ntime,6)


	cc = apid82short.counts
	if keyword_set(decomp) then mvn_swia_log_decomp,cc
	
	efull = fltarr(ntime,96)
	esf = fltarr(ntime)

	for i = 0L,nel-1 do begin
		ind = where(abs(timebase-time(i)) lt 1.99) 

		iprod0 = reform(cc(*,i),6,8,32)
		if ind ne -1 then begin
			espec82(ind,*) = transpose(total(total(iprod0,1),1))
			aspec82(ind,*) = transpose(total(total(iprod0,2),2))
			esf(ind) = (apid82short(i).estepfirst >0) <48
			efull(ind,esf(ind)+8:esf(ind)+39) = espec82(ind,*)
		endif
	endfor

	
	store_data,'apid82espec1d',data = {x:timebase,y:espec82,v:findgen(32),spec:1,no_interp:1}
	store_data,'apid82espec1fd',data = {x:timebase,y:efull,v:energy,spec:1,no_interp:1,ylog:1}
	store_data,'estepfirstd',data = {x:timebase,y:energy(esf),psym:10}
	store_data,'apid82espec1fcd',data = "apid82espec1fd estepfirstd"
	options,'apid82espec1fcd','yrange',[5,25000]
	store_data,'apid82aspec1d',data = {x:timebase,y:aspec82,v:phi2(2:7),spec:1,no_interp:1}
	
endif

if keyword_set(apid82long) then begin

	nel = n_elements(apid82long)

	time = apid82long.clock1*65536.d + apid82long.clock2 + apid82long.subsec/65536.d + time_double('2000-01-01/12:00') -4.0 ;one cycle shift

	if not keyword_set(apid80) then begin
		dtime = time(nel-1)-time(0)
		ntime = dtime/4 + 512
		timebase = time(0)-1024 + findgen(ntime)*4.00000116
	endif

	espec82 = fltarr(ntime,48)
	aspec82 = fltarr(ntime,10)


	cc = apid82long.counts
	if keyword_set(decomp) then mvn_swia_log_decomp,cc
	
	efull = fltarr(ntime,96)
	esf = fltarr(ntime)
	order = fltarr(nel)
	
	for i = 0L,nel-1 do begin
		reft = time(i)
		w = where(abs(reft-time) lt 0.01)
		ww = where(w lt i,nww)
		order(i) = nww > 0
	endfor

	for i = 0L,nel-1 do begin
		ind = where(abs(timebase-time(i)) lt 1.99) 

		iprod0 = reform(cc(*,i),10,12,16)
		if ind ne -1 then begin
			step = order(i)
		
			espec82(ind,step*16:(step+1)*16-1) = transpose(total(total(iprod0,1),1))
			aspec82(ind,*) = aspec82(ind,*)+transpose(total(total(iprod0,2),2))
			esf(ind) = (apid82long(i).estepfirst >0) <48
			efull(ind,esf(ind):esf(ind)+47) = espec82(ind,*)
		endif
	endfor

	
	store_data,'apid82espec2d',data = {x:timebase,y:espec82,v:findgen(48),spec:1,no_interp:1}
	store_data,'apid82espec2fd',data = {x:timebase,y:efull,v:energy,spec:1,no_interp:1,ylog:1}
	store_data,'estepfirstd',data = {x:timebase,y:energy(esf),psym:10}
	store_data,'apid82espec2fcd',data = "apid82espec2fd estepfirstd"
	options,'apid82espec2fcd','yrange',[5,25000]
	store_data,'apid82aspec2d',data = {x:timebase,y:aspec82,v:phi2,spec:1,no_interp:1}
	
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
			time1(i*16:i*16+15) = time(i)+findgen(16)*4*2.0^apid85(i).accumper 
		endfor
	endelse

	w = where(apid85.swimode eq 0,nw)
	if w(0) ne -1 then begin
		for j = 0,nw-1 do time1(w(j)*16:w(j)*16+15) = time1(w(j)*16:w(j)*16+15)-4	;shift for p2 moments
	endif
	
	mom = fltarr(ntime,13)
	momt = fltarr(nel*16,13)
	
	sind = fltarr(nel*16)
	
	for i = 0,nel-1 do begin
		for j = 0,15 do begin
			ind = where(abs(timebase-time1(i*16+j)) lt 1.99)
			sind(i*16+j) = ind
			mom(ind,*) = apid85(i).moments(j*13:j*13+12)
			momt(i*16+j,*) = mom(ind,*)
		endfor
	endfor
	
	mvn_swia_moment_decom,mom,momout1
	mvn_swia_moment_decom,momt,momout
	

	store_data,'apid85d',data = {x:timebase,y:momout1,v:indgen(13),spec:0,no_interp:1,labels:['N','NVx','Nvy','Nvz','NPxx','Npyy','Npzz','Npxy','Npxz','Npyz','NHx','NHy','NHz'],labflag:1}
	
	
	
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
	store_data,'densmom',data = {x:timebase(sind),y:dens,ylog:1,psym:-4,yrange:[1e-2,1e4]}
	
	vx = momout(*,1) / mf1 /sf * dang * deovere * 2*!pi/dt/geom * 1e-5/(dens>1e-4)
	vy = momout(*,2) / mf1 /sf * dang * deovere * 2*!pi/dt/geom * 1e-5/(dens>1e-4)
	vz = momout(*,3) / mf1 /sf * dang * deovere * 2*!pi/dt/geom * 1e-5/(dens>1e-4)

	store_data,'velmom',data = {x:timebase(sind),y:[[vx],[vy],[vz]],v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,psym:-4}
	
	pxx = (momout(*,4) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vx*vx*1e10*dens)/1.6e-12
	pyy = (momout(*,5) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vy*vy*1e10*dens)/1.6e-12
	pzz = (momout(*,6) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vz*vz*1e10*dens)/1.6e-12
	pxy = (momout(*,7) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vx*vy*1e10*dens)/1.6e-12
	pxz = (momout(*,8) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vx*vz*1e10*dens)/1.6e-12
	pyz = (momout(*,9) / mf2 /sf * dang * deovere * 2*!pi/dt/geom * mass/intconst - mass*vy*vz*1e10*dens)/1.6e-12

	
	store_data,'pmom',data = {x:timebase(sind),y:[[pxx],[pyy],[pzz],[pxy],[pxz],[pyz]],labels:['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'],psym:-4,labflag:1}
	
	tx = pxx/(dens>1e-4)
	ty = pyy/(dens>1e-4)
	tz = pzz/(dens>1e-4)
	
	store_data,'tmom',data = {x:timebase(sind),y:[[tx],[ty],[tz]],labels:['Tx','Ty','Tz'],labflag:1,psym:-4}
	
	qx = momout(*,10) / mf3 /sf * dang * deovere * 2*!pi/dt/geom * 1.6e-12
	qy = momout(*,11) / mf3 /sf * dang * deovere * 2*!pi/dt/geom * 1.6e-12
	qz = momout(*,12) / mf3 /sf * dang * deovere * 2*!pi/dt/geom * 1.6e-12

	store_data,'qmom',data = {x:timebase(sind),y:[[qx],[qy],[qz]],labels:['Qx','Qy','Qz'],labflag:1,psym:-4}

endif

if keyword_set(apid86) then begin
	
	nel = n_elements(apid86)
	time = apid86.clock1*65536.d + apid86.clock2 + apid86.subsec/65536.d + time_double('2000-01-01/12:00')

	if n_elements(time) eq 1 then begin
		time1 = time(0)+findgen(16)*4*2.0^apid86(0).accumper
	endif else begin
		time1 = dblarr(nel*16L)
		for i = 0L,nel-1 do begin
			time1(i*16:i*16+15) = time(i)+findgen(16)*4*2.0^apid86(i).accumper 
		endfor
	endelse

	cc = fltarr(ntime,48)
	
	for i = 0,nel-1 do begin
		for j = 0,15 do begin
			ind = where(abs(timebase - time1(i*16+j)) lt 1.99)
			cc(ind,*) = apid86(i).spectra(j*48:j*48+47)
		endfor
	endfor
	
	if keyword_set(decomp) then mvn_swia_log_decomp,cc
	

	store_data,'apid86d',data = {x:timebase,y:cc,v:rebin(energy,48),spec:1,no_interp:1,ylog:1}
	
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
	
	