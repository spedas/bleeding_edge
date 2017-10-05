;Loads Fast ESA l1 Compressed Data

pro fa_load_esa_l1,dtype,datatype=datatype,type=type, $
					filenames=filenames, $
					tplot=tplot, $
					download_only=download_only, $
					no_flag=no_flag

if keyword_set(dtype) then type=dtype
if NOT keyword_set(tplot) then tplot=0
;fa_init
fa_esa_init

if keyword_set(datatype) then begin
	type=datatype
endif else begin
	if NOT keyword_set(type) then type=['ees','ies','eeb','ieb']
endelse
if n_elements(type) GT 1 then begin
	for i=0,n_elements(type)-1 do fa_load_esa_l1,type=type[i],tplot=tplot
	return
endif
case strlowcase(type) of
	'ees': begin
		data_name='Eesa Survey'
		;charge=-1
	end
	'eeb': begin
		data_name='Eesa Burst'
		;charge=-1
	end
	'ies': begin
		data_name='Iesa Survey'
		;charge=1
	end
	'ieb': begin
		data_name='Iesa Burst'
		;charge=1
	end
	else: begin
		print,'Error @ fa_load_esa_l1.pro: Invalid Input Type'
		return
	end
endcase
vxx='v'+fa_config('version','l1_'+type)

if NOT keyword_set(filenames) then begin
	
	trange=timerange()
	start_orbit=long(fa_time_to_orbit(trange[0]))
	end_orbit=long(fa_time_to_orbit(trange[1]))
	orbits=indgen(end_orbit-start_orbit+1)+start_orbit
	orbits_str=strcompress(string(orbits,format='(i05)'),/remove_all)
	orbit_dir=strmid(orbits_str,0,2)+'000'
	
	relpathnames='l1/'+type+'/'+orbit_dir+'/fa_l1_'+type+'_'+orbits_str+'_'+vxx+'.cdf'
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
		'NBINS','NENERGY', $
		'GEOM_FACTOR', $
		'DATA_IND','GF_IND','BINS_IND','MODE_IND', $
		'THETA_SHIFT','THETA_MAX','THETA_MIN', $
		'SC_POT','BKG', $
		'DATA0','DATA1','DATA2', $
		'ENERGY','BINS','THETA', $
		'GF', $
		'DENERGY','DTHETA', $
		'EFF','DEAD','MASS','CHARGE', $
		'BKG_ARR', $
		'HEADER_BYTES']
		cdf_load_ptr,filenames[j],cdf_var,ptr_array
		time=*(ptr_array[0])
		end_time=*(ptr_array[1])
		integ_t=*(ptr_array[2])
		delta_t=*(ptr_array[3])
		nbins=*(ptr_array[4])
		nenergy=*(ptr_array[5])
		geom_factor=*(ptr_array[6])
		data_ind=*(ptr_array[7])
		gf_ind=*(ptr_array[8])
		bins_ind=*(ptr_array[9])
		mode_ind=*(ptr_array[10])
		theta_shift=*(ptr_array[11])
		theta_max=*(ptr_array[12])
		theta_min=*(ptr_array[13])
		sc_pot=*(ptr_array[14])
		bkg=*(ptr_array[15])
		data0=*(ptr_array[16])
		data1=*(ptr_array[17])
		data2=*(ptr_array[18])
		energy=*(ptr_array[19])
		bins=*(ptr_array[20])
		theta=*(ptr_array[21])
		gf=*(ptr_array[22])
		denergy=*(ptr_array[23])
		dtheta=*(ptr_array[24])
		eff=*(ptr_array[25])
		dead=*(ptr_array[26])
		mass=*(ptr_array[27])
		charge=*(ptr_array[28])
		bkg_arr=*(ptr_array[29])
		header_bytes=*(ptr_array[30])
		heap_free,ptr_array
		ntimes=n_elements(time)
		data_quality=bytarr(ntimes)
		if NOT keyword_set(no_flag) then begin
			for k=0l,ntimes-1 do begin
				case mode_ind[k] of
					0: if ((where(data0[*,*,data_ind[k]] EQ 255))[0] EQ -1) $
						then data_quality[k]=0 $
						else data_quality[k]=2
					1: if ((where(data1[*,*,data_ind[k]] EQ 255))[0] EQ -1) $
						then data_quality[k]=0 $
						else data_quality[k]=2
					2: if ((where(data2[*,*,data_ind[k]] EQ 255))[0] EQ -1) $
						then data_quality[k]=0 $
						else data_quality[k]=2
					else: begin
						print,'Data Quality Error @ fa_load_esa_l1.pro'
						data_quality[k]=0
					end
				endcase
			endfor
		endif
		all_dat_tmp={project_name:'FAST', $
			data_name:data_name, $
			data_level:'Level 1', $
			units_name:'Compressed', $
			units_procedure:'fa_convert_esa_units', $
			valid:bytarr(ntimes)+1, $
			data_quality:data_quality, $
			time:time, $
			end_time:end_time, $
			integ_t:integ_t, $
			delta_t:delta_t, $
			nbins:nbins, $
			nenergy:nenergy, $
			geom_factor:geom_factor, $
			data_ind:long(data_ind), $
			gf_ind:gf_ind, $
			bins_ind:bins_ind, $
			mode_ind:mode_ind, $
			theta_shift:theta_shift, $
			theta_max:theta_max, $
			theta_min:theta_min, $
			bkg:bkg, $
			data0:data0, $
			data1:data1, $
			data2:data2, $
			energy:energy, $
			bins:bins, $
			theta:theta, $
			gf:gf, $
			denergy:denergy, $
			dtheta:dtheta, $
			eff:eff, $
			dead:dead, $
			mass:mass, $
			charge:charge, $
			sc_pot:sc_pot, $
			bkg_arr:bkg_arr, $
			header_bytes:header_bytes}
			
		if NOT keyword_set(all_dat) then begin
			all_dat=all_dat_tmp
		endif else begin
			all_dat=fa_esa_append_l1(all_dat,all_dat_tmp)
		endelse
		
endfor

case strlowcase(type) of
	
	'ees': begin
		common fa_ees_l1, get_ind_ees, all_dat_ees
		all_dat_ees=all_dat
		get_ind_ees=0l
	end
	
	'eeb': begin
		common fa_eeb_l1, get_ind_eeb, all_dat_eeb
		all_dat_eeb=all_dat
		get_ind_eeb=0l
	end
	
	'ies': begin
		common fa_ies_l1, get_ind_ies, all_dat_ies
		all_dat_ies=all_dat
		get_ind_ies=0l
	end
	
	'ieb': begin
		common fa_ieb_l1, get_ind_ieb, all_dat_ieb
		all_dat_ieb=all_dat
		get_ind_ieb=0l
	end
	
endcase

if keyword_set(tplot) then begin
	
	if size(tplot,/type) EQ 7 then begin
		if (where(strlowcase(type) EQ strlowcase(tplot)))[0] EQ -1 then return
	endif
	
	ntimes=n_elements(all_dat.time)
	common fa_information,info_struct
	case strlowcase(type) of
		'ees': ccvt=info_struct.byteto16_map
		'eeb': ccvt=info_struct.byteto14_map
		'ies': ccvt=info_struct.byteto16_map
		'ieb': ccvt=info_struct.byteto14_map
		else: begin
			print,'COMPRESSED/COUNTS CONVERSION ERROR'
			return
		end
	endcase
	
	data_tplot=fltarr(ntimes,96)
	energy_tplot=fltarr(ntimes,96)
	
	for i=0,ntimes-1 do begin
		
		if all_dat.mode_ind[i] EQ 0 then begin
			data_tplot[i,0:47]=total(ccvt(all_dat.data0[*,*,all_dat.data_ind[i]]),2)/(all_dat.integ_t[i]*all_dat.nbins[i])
			energy_tplot[i,*]=all_dat.energy[*,0,0]
		endif
		
		if all_dat.mode_ind[i] EQ 1 then begin
			data_tplot[i,0:47]=total(ccvt(all_dat.data1[*,*,all_dat.data_ind[i]]),2)/(all_dat.integ_t[i]*all_dat.nbins[i])
			energy_tplot[i,*]=all_dat.energy[*,0,1]
		endif
	
		if all_dat.mode_ind[i] EQ 2 then begin
			data_tplot[i,0:95]=total(ccvt(all_dat.data2[*,*,all_dat.data_ind[i]]),2)/(all_dat.integ_t[i]*all_dat.nbins[i])
			energy_tplot[i,*]=all_dat.energy[*,0,2]
		endif
		
	endfor
	
	data_tplot=data_tplot>1.e-10
	name_o_tplot='fa_'+type+'_l1_en_quick'
	store_data,name_o_tplot,data={x:(all_dat.time+all_dat.end_time)/2,y:data_tplot,v:energy_tplot}
	zlim,name_o_tplot,1.e1,1.e6,1
	ylim,name_o_tplot,5.,40000.,1
	options,name_o_tplot,'ztitle','Rate'
	options,name_o_tplot,'ytitle',type+': eV'
	options,name_o_tplot,'spec',1
	options,name_o_tplot,'x_no_interp',1
	options,name_o_tplot,'y_no_interp',1
	options,name_o_tplot,datagap=5
	
endif

return
end
