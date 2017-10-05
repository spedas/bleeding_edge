;Loads FAST SESA SURVEY l1 Compressed Data
;Keyword /TPLOT makes a quick rate TPLOT.
;Keyword /BYTE leaves the data in a compressed byte format
;This routine by default applies the energy shift calibration.
;	If keyword /NO_SHIFT is set, no energy shift calibration is applied.

pro fa_load_sesa_survey_l1,filenames=filenames, $
							tplot=tplot, $
							spectrum=spectrum, $
							download_only=download_only

;fa_init
fa_esa_init

vxx='v'+fa_config('version','l1_ses')

if NOT keyword_set(filenames) then begin
	
	trange=timerange()
	start_orbit=long(fa_time_to_orbit(trange[0]))
	end_orbit=long(fa_time_to_orbit(trange[1]))
	orbits=indgen(end_orbit-start_orbit+1)+start_orbit
	orbits_str=strcompress(string(orbits,format='(i05)'),/remove_all)
	orbit_dir=strmid(orbits_str,0,2)+'000'
	
	relpathnames='l1/ses/'+orbit_dir+'/fa_l1_ses_'+orbits_str+'_'+vxx+'.cdf'
	filenames=file_retrieve(relpathnames,_extra=!fast)
	
endif

if keyword_set(download_only) then return

for i=0,n_elements(filenames)-1 do begin
	if file_test(filenames[i]) EQ 0 then begin
		print,'Warning: '+filenames[i]+' does not exist!'
		filenames[i]=''
	endif
endfor
where_files=where(filenames NE '')
if where_files[0] EQ -1 then begin
	return
endif
filenames=filenames[where_files]
print,filenames

for j=0,n_elements(filenames)-1 do begin
	cdf_var=['TIME','END_TIME', $
		'INTEG_T','DELTA_T', $
		'VALID', $
		'NBINS','NENERGY', $
		'GEOM_FACTOR', $
		'DATA_IND','GF_IND','BINS_IND','MODE_IND', $
		'ENERGY_IND', 'THETA_IND', $
		'THETA_SHIFT','THETA_MAX','THETA_MIN', $
		'SC_POT','BKG', $
		'DATA0','DATA1','DATA2','DATA3',$
		'ENERGY','BINS','THETA', $
		'GF', $
		'DENERGY','DTHETA', $
		'EFF','DEAD','MASS','CHARGE', $
		'BKG_ARR', $
		'HEADER_BYTES', $
		'SPIN_PHASE','SPIN_NUM','SPIN_PH_HDR','SWEEP_NUM','SWPS_PER_SET', $
		'DATA_QUALITY','GF_SHIFT']
		cdf_load_ptr,filenames[j],cdf_var,ptr_array
		time=*(ptr_array[0])
		end_time=*(ptr_array[1])
		integ_t=*(ptr_array[2])
		delta_t=*(ptr_array[3])
		valid=*(ptr_array[4])
		nbins=*(ptr_array[5])
		nenergy=*(ptr_array[6])
		geom_factor=*(ptr_array[7])
		data_ind=*(ptr_array[8])
		gf_ind=*(ptr_array[9])
		bins_ind=*(ptr_array[10])
		mode_ind=*(ptr_array[11])
		energy_ind=*(ptr_array[12])
		theta_ind=*(ptr_array[13])
		theta_shift=*(ptr_array[14])
		theta_max=*(ptr_array[15])
		theta_min=*(ptr_array[16])
		sc_pot=*(ptr_array[17])
		bkg=*(ptr_array[18])
		data0=*(ptr_array[19])
		data1=*(ptr_array[20])
		data2=*(ptr_array[21])
		data3=*(ptr_array[22])
		energy=*(ptr_array[23])
		bins=*(ptr_array[24])
		theta=*(ptr_array[25])
		gf=*(ptr_array[26])
		denergy=*(ptr_array[27])
		dtheta=*(ptr_array[28])
		eff=*(ptr_array[29])
		dead=*(ptr_array[30])
		mass=*(ptr_array[31])
		charge=*(ptr_array[32])
		bkg_arr=*(ptr_array[33])
		header_bytes=*(ptr_array[34])
		spin_phase=*(ptr_array[35])
		spin_num=*(ptr_array[36])
		spin_ph_hdr=*(ptr_array[37])
		sweep_num=*(ptr_array[38])
		swps_per_set=*(ptr_array[39])
		data_quality=*(ptr_array[40])
		gf_shift=*(ptr_array[41])
		heap_free,ptr_array
		;ntimes=n_elements(time)
		;data_quality=bytarr(ntimes)
		;if NOT keyword_set(no_flag) then begin
		;	for k=0l,ntimes-1 do begin
		;		case mode_ind[k] of
		;			0: if ((where(data0[*,*,data_ind[k]] EQ 255))[0] EQ -1) $
		;				then data_quality[k]=0 $
		;				else data_quality[k]=2
		;			1: if ((where(data1[*,*,data_ind[k]] EQ 255))[0] EQ -1) $
		;				then data_quality[k]=0 $
		;				else data_quality[k]=2
		;			2: if ((where(data2[*,*,data_ind[k]] EQ 255))[0] EQ -1) $
		;				then data_quality[k]=0 $
		;				else data_quality[k]=2
		;			3: if ((where(data3[*,*,data_ind[k]] EQ 255))[0] EQ -1) $
		;				then data_quality[k]=0 $
		;				else data_quality[k]=2
		;			else: begin
		;				print,'Data Quality Error @ fa_load_sesa_survey_l1.pro'
		;				data_quality[k]=0
		;			end
		;		endcase
		;	endfor
		;endif
		all_dat_tmp={project_name:'FAST', $
			data_name:'Sesa Survey', $
			data_level:'Level 1', $
			units_name:'Compressed', $
			units_procedure:'fa_convert_esa_units', $
			valid:valid, $
			data_quality:data_quality, $
			time:time, $
			end_time:end_time, $
			integ_t:integ_t, $
			delta_t:delta_t, $
			nbins:nbins, $
			nenergy:nenergy, $
			geom_factor:geom_factor, $
			data_ind:data_ind, $
			gf_ind:gf_ind, $
			bins_ind:bins_ind, $
			mode_ind:mode_ind, $
			energy_ind:energy_ind, $
			theta_ind:theta_ind, $
			theta_shift:theta_shift, $
			theta_max:theta_max, $
			theta_min:theta_min, $
			sc_pot:sc_pot, $
			bkg:bkg, $
			data0:data0, $
			data1:data1, $
			data2:data2, $
			data3:data3, $
			energy:energy, $
			bins:bins, $
			theta:theta, $
			gf:gf, $
			gf_shift:gf_shift, $
			denergy:denergy, $
			dtheta:dtheta, $
			eff:eff, $
			dead:dead, $
			mass:mass, $
			charge:charge, $
			bkg_arr:bkg_arr, $
			header_bytes:header_bytes, $
			spin_phase:spin_phase, $
			spin_num:spin_num, $
			spin_ph_hdr:spin_ph_hdr, $
			sweep_num:sweep_num, $
			swps_per_set:swps_per_set}
			
		if NOT keyword_set(all_dat) then begin
			all_dat=all_dat_tmp
		endif else begin
			all_dat=fa_sesa_survey_append_l1(all_dat,all_dat_tmp)
		endelse
		
endfor

ntimes=n_elements(all_dat.time)
common fa_information,info_struct
ccvt=info_struct.byteto16_map

common fa_ses_l1, get_ind_ses, all_dat_ses
all_dat_ses=all_dat
get_ind_ses=0l

if keyword_set(tplot) then begin
	
	if size(tplot,/type) EQ 7 then begin
		if (where(strlowcase(type) EQ strlowcase(tplot)))[0] EQ -1 then return
	endif
	
	min_mode=min(all_dat.mode_ind)
	case min_mode of
		0: n_energy=48
		1: n_energy=24
		2: n_energy=12
		3: n_energy=6
	end
	data_tplot=fltarr(ntimes,n_energy)
	energy_tplot=fltarr(ntimes,n_energy)
	
	for i=0l,ntimes-1 do begin
		
		energy_tplot[i,0:n_energy-1]=all_dat.energy[0:n_energy-1,0,all_dat.energy_ind[i]]
		
		if all_dat.mode_ind[i] EQ 0 then $
			data_tplot[i,0:47]=total(ccvt(all_dat.data0[*,*,all_dat.data_ind[i]]),2)/(all_dat.integ_t[i]*all_dat.nbins[i])
		
		if all_dat.mode_ind[i] EQ 1 then $
			data_tplot[i,0:23]=total(ccvt(all_dat.data1[*,*,all_dat.data_ind[i]]),2)/(all_dat.integ_t[i]*all_dat.nbins[i])
	
		if all_dat.mode_ind[i] EQ 2 then $
			data_tplot[i,0:11]=total(ccvt(all_dat.data2[*,*,all_dat.data_ind[i]]),2)/(all_dat.integ_t[i]*all_dat.nbins[i])
		
		if all_dat.mode_ind[i] EQ 3 then $
			data_tplot[i,0:5]=total(ccvt(all_dat.data3[*,*,all_dat.data_ind[i]]),2)/(all_dat.integ_t[i]*all_dat.nbins[i])
		
	endfor
	
	data_tplot=data_tplot>1.e-10
	name_o_tplot='fa_ses_l1_en_quick'
	store_data,name_o_tplot,data={x:(all_dat.time+all_dat.end_time)/2,y:data_tplot,v:energy_tplot}
	options,name_o_tplot,'spec',1
	;if (min_mode NE 0) AND (NOT keyword_set(spectrum)) then begin
	;	options,name_o_tplot,'spec',0
	;	ylim,name_o_tplot,1.e1,1.e6,1
	;	options,name_o_tplot,'ytitle','ses: Rate'
	;	options,name_o_tplot,'x_no_interp',1
	;endif else begin
		options,name_o_tplot,'spec',1
		ylim,name_o_tplot,5.,40000.,1
		zlim,name_o_tplot,1.e1,1.e6,1
		options,name_o_tplot,'ztitle','Rate'
		options,name_o_tplot,'ytitle','ses: eV'
		options,name_o_tplot,'x_no_interp',1
		options,name_o_tplot,'y_no_interp',1
	;endelse
	options,name_o_tplot,datagap=5
	
endif

return
end