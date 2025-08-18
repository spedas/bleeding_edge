;+
;PROCEDURE: 
;	MVN_SWIA_LOAD_L0_DATA
;PURPOSE: 
;	Routine to load SWIA Level 0 data and produce common blocks and Tplot variables
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_LOAD_L0_DATA, Files, /TPLOT, /SYNC
;INPUTS:
;	Files: An array of filenames containing PF Level 0 data (not needed if using file_retrieve)
;KEYWORDS:
;	TPLOT: Produce Tplot variables
;	SYNC: Sync on the spacecraft header and checksum (speeds performance greatly)
;	QLEVEL: Set this keyword to not plot moments or spectra with a low quality flag
;		or decommutation quality flag.  Default cutoff = 0.5
;	PATH: Set the default data path for file_retrieve functionality if different from standard
;	TRANGE: Set the time range for files to load, if using file_retrieve capability
;		(otherwise the 'timerange' routine will be invoked to determine this)
;	OLDCAL: Use old calibration factors appropriate for original table
;		(appropriate before ~11/25/2014)
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-12-14 14:17:16 -0800 (Mon, 14 Dec 2015) $
; $LastChangedRevision: 19630 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_load_l0_data.pro $
;
;-

pro mvn_swia_load_l0_data, files, tplot = tplot, sync = sync, qlevel = qlevel, trange = trange, path = path, oldcal = oldcal

compile_opt idl2

common mvn_swia_data, info_str, swihsk, swics, swica, swifs, swifa, swim, swis

swihsk = 0
swics = 0
swica = 0
swifs = 0
swifa = 0
swim = 0
swis = 0

if not keyword_set(path) then path = 'maven/data/sci/pfp/l0/mvn_pfp_all_l0_YYYYMMDD_v???.dat'

if not keyword_set(qlevel) then qlevel = 0.5

nfiles = n_elements(files)

if nfiles eq 0 then begin
	files = mvn_pfp_file_retrieve(path, /daily, trange = trange,/valid_only)
	w = where(files ne '',nfiles)
	if nfiles gt 0 then files = files[w]
endif

if nfiles eq 0 then begin
	print,'ERROR: No Files Found'
	return
endif

print,'Reading File: ',files[0]

mvn_swia_read_compressed_packets, files[0], sync = sync, /r29, /r80, /r81, $
/r82s, /r82l, /r83s, /r83l, /r85, /r86, apid29=apid29, apid80=apid80, $
apid81=apid81, apid82short=apid82short, apid82long = apid82long, $
apid83short=apid83short, apid83long=apid83long, apid85=apid85, apid86 = apid86


if nfiles gt 1 then begin

	for file = 1,nfiles-1 do begin

		print,'Reading File: ',files[file]

		;zero out old variables so I don't have "ghosts"

		napid29 = 0
		napid80 = 0
		napid81 = 0
		napid82short = 0
		napid82long = 0
		napid83short = 0
		napid83long = 0
		napid85 = 0
		napid86 =0
		
		mvn_swia_read_compressed_packets, files[file], sync = sync, /r29, /r80, /r81, $
		/r82s, /r82l, /r83s, /r83l, /r85, /r86, apid29=napid29, apid80=napid80, $
		apid81=napid81, apid82short=napid82short, apid82long = napid82long, $
		apid83short=napid83short, apid83long=napid83long, apid85=napid85, apid86 = napid86
	
		if n_elements(apid29) gt 0 and n_elements(napid29) gt 1 then apid29 = [apid29,napid29] 
		if n_elements(apid29) eq 0 and n_elements(napid29) gt 1 then apid29 = napid29
		if n_elements(apid80) gt 0 and n_elements(napid80) gt 1 then apid80 = [apid80,napid80] 
		if n_elements(apid80) eq 0 and n_elements(napid80) gt 1 then apid80 = napid80
		if n_elements(apid81) gt 0 and n_elements(napid81) gt 1 then apid81 = [apid81,napid81] 
		if n_elements(apid81) eq 0 and n_elements(napid81) gt 1 then apid81 = napid81
		if n_elements(apid82short) gt 0 and n_elements(napid82short) gt 1 then apid82short = [apid82short,napid82short] 
		if n_elements(apid82short) eq 0 and n_elements(napid82short) gt 1 then apid82short = napid82short
		if n_elements(apid82long) gt 0 and n_elements(napid82long) gt 1 then apid82long = [apid82long,napid82long] 
		if n_elements(apid82long) eq 0 and n_elements(napid82long) gt 1 then apid82long = napid82long
		if n_elements(apid83short) gt 0 and n_elements(napid83short) gt 1 then apid83short = [apid83short,napid83short] 
		if n_elements(apid83short) eq 0 and n_elements(napid83short) gt 1 then apid83short = napid83short
		if n_elements(apid83long) gt 0 and n_elements(napid83long) gt 1 then apid83long = [apid83long,napid83long] 
		if n_elements(apid83long) eq 0 and n_elements(napid83long) gt 1 then apid83long = napid83long
		if n_elements(apid85) gt 0 and n_elements(napid85) gt 1 then apid85 = [apid85,napid85] 
		if n_elements(apid85) eq 0 and n_elements(napid85) gt 1 then apid85 = napid85
		if n_elements(apid86) gt 0 and n_elements(napid86) gt 1 then apid86 = [apid86,napid86] 
		if n_elements(apid86) eq 0 and n_elements(napid86) gt 1 then apid86 = napid86

	endfor
endif


if keyword_set(oldcal) then begin
	print,'Using Calibration Factors for 5 eV - 25 keV sweep (Valid before 11/20/2014)'
	print,'If your table does not match your time range, this program will crash'
	mvn_swia_make_info_str, info_str
endif else begin
	print,'Using Calibration Factors for 25 eV - 25 keV sweep (Valid after 11/20/2014)'
	print,'If your table does not match your time range, this program will crash'
	mvn_swia_make_info_str_2,info_str
endelse

if n_elements(apid29) gt 0 then mvn_swia_make_swihsk_str, apid29, swihsk

if n_elements(apid80) gt 0 then mvn_swia_make_swic_str, apid80, info_str, swics

if n_elements(apid81) gt 0 then mvn_swia_make_swic_str, apid81, info_str, swica

if n_elements(apid82short) gt 0 or n_elements(apid82long) gt 0 then mvn_swia_make_swif_str, shortpackets = apid82short, longpackets = apid82long, info_str, swifs

if n_elements(apid83short) gt 0 or n_elements(apid83long) gt 0 then mvn_swia_make_swif_str, shortpackets = apid83short, longpackets = apid83long, info_str, swifa

if n_elements(apid85) gt 0 then mvn_swia_make_swim_str, apid85, info_str, swim

if n_elements(apid86) gt 0 then mvn_swia_make_swis_str, apid86, info_str, swis


;kluge fix for coarse attenuator state

if n_elements(swics) gt 1 and n_elements(swis) gt 0 then begin
	waswitch = where(swics.atten_state ne shift(swics.atten_state,1) or swics.atten_state ne shift(swics.atten_state,-1),nw)
	if nw gt 0 then swics[waswitch].atten_state = round(interpol(swis.atten_state,swis.time_unix,swics[waswitch].time_unix))
	print,'Fixing Coarse Atten State, ',nw
endif

if n_elements(swica) gt 1 and n_elements(swis) gt 0 then begin
	waswitch = where(swica.atten_state ne shift(swica.atten_state,1) or swica.atten_state ne shift(swica.atten_state,-1),nw)
	if nw gt 0 then swica[waswitch].atten_state = round(interpol(swis.atten_state,swis.time_unix,swica[waswitch].time_unix))
	print,'Fixing Coarse Atten State, ',nw
endif

;kluge fix for fine attenuator state

if n_elements(swifs) gt 1 and n_elements(swis) gt 0 then begin
	waswitch = where(swifs.atten_state ne shift(swifs.atten_state,1) or swifs.atten_state ne shift(swifs.atten_state,-1),nw)
	if nw gt 0 then swifs[waswitch].atten_state = round(interpol(swis.atten_state,swis.time_unix,swifs[waswitch].time_unix))
	print,'Fixing Fine Atten State, ',nw
endif

if n_elements(swifa) gt 1 and n_elements(swis) gt 0 then begin
	waswitch = where(swifa.atten_state ne shift(swifa.atten_state,1) or swifa.atten_state ne shift(swifa.atten_state,-1),nw)
	if nw gt 0 then swifa[waswitch].atten_state = round(interpol(swis.atten_state,swis.time_unix,swifa[waswitch].time_unix))
	print,'Fixing Fine Atten State, ',nw
endif


if keyword_set(tplot) then begin
	if n_elements(swihsk) gt 0 then begin
		store_data,'mvn_swia_temps', data = {x:swihsk.time_unix, y: [[swihsk.lvpst],[swihsk.digt]], v:[0,1], $
		labels: ['LVPS','DIG'],labflag:1, ytitle: 'SWIA!cTemp'}
		store_data,'mvn_swia_imons', data = {x:swihsk.time_unix, y: [[swihsk.imon_mcp],[swihsk.imon_raw]], $
		v:[0,1], labels: ['MCP','RAW'],labflag:1, ytitle: 'SWIA!cHV Imon'}
		store_data,'mvn_swia_vmon_fixed', data = {x:swihsk.time_unix, y: [[swihsk.vmon_mcp],[swihsk.vmon_raw_def], $
		[swihsk.vmon_raw_swp]], v:[0,1,2], labels: ['MCP','DEF','SWP'],labflag:1, ytitle: 'SWIA!cHV RAW'}
		store_data,'mvn_swia_vmon_sweep', data = {x:swihsk.time_unix, y: [[swihsk.vmon_swp],[swihsk.vmon_def1], $
		[swihsk.vmon_def2]], v:[0,1,2], labels: ['SWP','DEF1','DEF2'],labflag:1, ytitle: 'SWIA!cHV SWEEP'}
		store_data,'mvn_swia_voltages', data = {x:swihsk.time_unix, y: [[swihsk.v25d],[swihsk.v5d],[swihsk.v33d], $
		[swihsk.v5a],[swihsk.vn5a],[swihsk.v12],[swihsk.v28]], v:[0,1,2,3,4,5,6], $
		labels: ['2.5d','5d','3.3d','5a','-5a','12','28'],var_label:1, ytitle: 'SWIA!cVoltages'}
		store_data,'mvn_swia_voltages_sub', data = {x:swihsk.time_unix, y: [[swihsk.v25d-2.5],[swihsk.v5d-5], $
		[swihsk.v33d-3.3],[swihsk.v5a-5],[swihsk.vn5a+5],[swihsk.v12-12]], v:[0,1,2,3,4,5], $
		labels:['2.5d','5d','3.3d','5a','-5a','12'],labflag:1, ytitle: 'SWIA!cOffsets'}
		store_data,'mvn_swia_dighsk', data = {x:swihsk.time_unix,y:[[mvn_swia_subword(swihsk.dighsk,bit1=7,bit2=7)], $
		[mvn_swia_subword(swihsk.dighsk,bit1=3,bit2=3)],[mvn_swia_subword(swihsk.dighsk,bit1=2,bit2=2)]],v:[0,1,2], $
		spec:1,no_interp:1,psym:10, ytitle: 'SWIA!cDigHSK'}
		store_data,'mvn_swia_trates',data = {x:swihsk.time_unix,y:[[swihsk.coarse_options[0]],[swihsk.coarse_options[1]], $
		[swihsk.fine_options[0]],[swihsk.fine_options[1]],[swihsk.mom_options],[swihsk.spec_options]], $
		labels:['CS','CA','FS','FA','MS','SS'],v:[0,1,2,3,4,5],labflag:1,psym:10, ytitle: 'SWIA!cOptions'}
		store_data,'mvn_swia_diagdata',data = {x:swihsk.time_unix,y:[[mvn_swia_subword(swihsk.diagdata,bit1=15,bit2=15)], $
		[mvn_swia_subword(swihsk.diagdata,bit1=14,bit2=12)],[mvn_swia_subword(swihsk.diagdata,bit1=11,bit2=11)], $
		[mvn_swia_subword(swihsk.diagdata,bit1=10,bit2=10)],[mvn_swia_subword(swihsk.diagdata,bit1=9,bit2=0)]], $
		v:[0,1,2,3,4],labels:['slut','diag','enbswp','p1mode','mask'],labflag:1,psym:10, ytitle: 'SWIA!cDiag'}



	endif

	if n_elements(swics) gt 1 then begin

		ctime = swics.time_unix +4.0*swics.num_accum/2	;center time of sample/sum

		espec = transpose(total(total(swics.data,2),2))
		energies = transpose(info_str[swics.info_index].energy_coarse)
		store_data,'mvn_swics_en_counts',data = {x:ctime, y: espec, v:energies, ylog:1, zlog:1, spec:1, $
		no_interp:1,yrange:[4,30000],ystyle:1,zrange:[10,1e6],ytitle:'Energy (eV)',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}

		phspec = transpose(total(total(swics.data,1),1))
		phis = transpose(info_str[swics.info_index].phi_coarse)
		for i = 0,n_elements(swics)-1 do begin
			s = sort(phis[i,*])
			phis[i,*] = phis[i,s]
			phspec[i,*] = phspec[i,s]
		endfor
		store_data,'mvn_swics_ph_counts',data = {x:ctime, y: phspec, v:phis, spec:1, no_interp:1, ytitle:'Phi', $
		ztitle:'SWIA!cCounts',zlog:1}, dlimits = {datagap:180}


		thspec = transpose(total(total(swics.data,3),1))
		thetas = transpose(info_str[swics.info_index].theta_coarse[47,*,*])
		store_data,'mvn_swics_th_counts',data = {x:ctime,y:thspec,v:thetas,spec:1, no_interp:1, ytitle:'Theta', $
		ztitle:'SWIA!cCounts',zlog:1}, dlimits = {datagap:180}

	endif

	if n_elements(swica) gt 1 then begin
		ctime = swica.time_unix +4.0*swica.num_accum/2	;center time of sample/sum

		espec = transpose(total(total(swica.data,2),2))
		energies = transpose(info_str[swica.info_index].energy_coarse)
		store_data,'mvn_swica_en_counts',data = {x:ctime, y: espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1, $
		yrange:[4,30000],ystyle:1,zrange:[1,1e4],ytitle:'Energy (eV)',ztitle:'SWIA!cCounts'}

		phspec = transpose(total(total(swica.data,1),1))
		phis = transpose(info_str[swica.info_index].phi_coarse)
		for i = 0,n_elements(swica)-1 do begin
			s = sort(phis[i,*])
			phis[i,*] = phis[i,s]
			phspec[i,*] = phspec[i,s]
		endfor
		store_data,'mvn_swica_ph_counts',data = {x:ctime, y: phspec, v: phis, spec:1, no_interp:1, ytitle:'Phi', $
		ztitle:'SWIA!cCounts',zlog:1}, dlimits = {datagap:180}


		thspec = transpose(total(total(swica.data,3),1))
		thetas = transpose(info_str[swica.info_index].theta_coarse[47,*,*])
		store_data,'mvn_swica_th_counts',data = {x:ctime,y:thspec,v:thetas,spec:1, no_interp:1, ytitle:'Theta', $
		ztitle:'SWIA!cCounts',zlog:1}, dlimits = {datagap:180}


	endif

	if n_elements(swifs) gt 1 then begin
		ctime = swifs.time_unix + 2.0				;center time of sample
		nsw = n_elements(swifs)

		espec = transpose(total(total(swifs.data,2),2))
		energy_all = transpose(info_str[swifs.info_index].energy_fine)
		energies = fltarr(nsw,48)
		for i = 0,nsw-1 do energies[i,*] =  energy_all[i,swifs[i].estep_first:swifs[i].estep_first+47]
		store_data,'mvn_swifs_en_counts',data = {x:ctime, y:espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1, $
		yrange:[4,30000],ystyle:1,zrange:[1,1e4],ytitle:'Energy (eV)',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}

		phspec = transpose(total(total(swifs.data,1),1))
		phis = transpose(info_str[swifs.info_index].phi_fine)
		store_data,'mvn_swifs_ph_counts',data = {x:ctime, y:phspec, v:phis, spec:1, no_interp:1, ytitle:'Phi', $
		ztitle:'SWIA!cCounts',zlog:1}, dlimits = {datagap:180}


		thspec = transpose(total(total(swifs.data,3),1))
		theta_all = transpose(info_str[swifs.info_index].theta_fine[95,*,*])
		thetas = fltarr(nsw,12)
		for i = 0,nsw-1 do thetas[i,*] = theta_all[i,swifs[i].dstep_first:swifs[i].dstep_first+11]
		store_data,'mvn_swifs_th_counts',data = {x:ctime,y: thspec, v: thetas, spec:1, no_interp:1, $
		ytitle:'Theta',ztitle:'SWIA!cCounts',zlog:1}, dlimits = {datagap:180}

	endif

	if n_elements(swifa) gt 1 then begin
		ctime = swifa.time_unix + 2.0				;center time of sample
		nsw = n_elements(swifa)

		espec = transpose(total(total(swifa.data,2),2))
		energy_all = transpose(info_str[swifa.info_index].energy_fine)
		energies = fltarr(nsw,48)
		for i = 0,nsw-1 do energies[i,*] =  energy_all[i,swifa[i].estep_first:swifa[i].estep_first+47]	
		store_data,'mvn_swifa_en_counts',data = {x:ctime, y:espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1, $
		yrange:[4,30000],ystyle:1,zrange:[1,1e4],ytitle:'Energy (eV)',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}

		phspec = transpose(total(total(swifa.data,1),1))
		phis = transpose(info_str[swifa.info_index].phi_fine)
		store_data,'mvn_swifa_ph_counts',data = {x:ctime, y:phspec, v:phis, spec:1, no_interp:1, ytitle:'Phi', $
		ztitle:'SWIA!cCounts',zlog:1}, dlimits = {datagap:180}


		thspec = transpose(total(total(swifa.data,3),1))
		theta_all = transpose(info_str[swifa.info_index].theta_fine[95,*,*])
		thetas = fltarr(nsw,12)
		for i = 0,nsw-1 do thetas[i,*] = theta_all[i,swifa[i].dstep_first:swifa[i].dstep_first+11]
		store_data,'mvn_swifa_th_counts',data = {x:ctime,y: thspec, v: thetas, spec:1, no_interp:1, ytitle:'Theta',ztitle:'SWIA!cCounts',zlog:1}, dlimits = {datagap:180}


	endif
	
	if n_elements(swim) gt 1 then begin
		w = where(swim.quality_flag ge qlevel and swim.decom_flag ge qlevel)
		ctime = swim[w].time_unix + 2.0				;center time of sample

		store_data,'mvn_swim_density',data = {x:ctime,y:swim[w].density,ytitle:'SWIA!cDensity!c[cm!E-3!N]'}
		store_data,'mvn_swim_velocity',data = {x:ctime,y:transpose(swim[w].velocity),v:[0,1,2],labels:['Vx','Vy','Vz'], $
		labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}, limits = {SPICE_FRAME: 'MAVEN_SWIA'}

		store_data,'mvn_swim_pressure',data = {x:ctime,y:transpose(swim[w].pressure), v:[0,1,2,3,4,5], $
		labels: ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}, $
		limits = {SPICE_FRAME: 'MAVEN_SWIA'}

		store_data, 'mvn_swim_temperature', data = {x:ctime,y:transpose(swim[w].temperature), v:[0,1,2], $
		labels: ['Tx','Ty','Tz'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}, limits = {SPICE_FRAME: 'MAVEN_SWIA'}

		store_data,'mvn_swim_heatflux', data = {x:ctime,y:transpose(swim[w].heat_flux), v:[0,1,2], $
		labels: ['Qx','Qy','Qz'], labflag:1, ytitle: 'SWIA!cHeat Flux!c[ergs/cm!E2!N s]'}, $
		limits = {SPICE_FRAME: 'MAVEN_SWIA'}


	endif

	if n_elements(swis) gt 1 then begin
		w = where(swis.decom_flag ge qlevel)
		ctime = swis[w].time_unix + 4.0*swis[w].num_accum/2		;center time of sample
		energies = transpose(info_str[swis[w].info_index].energy_coarse)
		store_data,'mvn_swis_en_counts',data = {x:ctime,y:transpose(swis[w].data),v:energies, ylog:1, zlog:1, spec:1, no_interp:1, yrange:[4,30000], ystyle:1,zrange:[1,1e4],ytitle:'Energy (eV)',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}
	endif

endif

end
