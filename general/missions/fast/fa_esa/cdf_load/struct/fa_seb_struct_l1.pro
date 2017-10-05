;+
;PURPOSE:	To return a data structure for a specific time from a FAST l1 common block.
;USEAGE:	dat=fa_seb_struct_l1(t,all_dat=all_dat,get_ind=get_ind)
;			dat=fa_seb_struct_l1(all_dat=all_dat,get_ind=get_ind) will call ctime.pro to get t.
;			The routine assumes the l1 common block for datatype is already loaded into IDL.
;KEYWORDS:	/START to return data structure for the first time in l1 common block.
;			/EN to return data structure for the last time in l1 common block.
;			/ADVANCE to return the next data structure in the l1 common block.
;			/RETREAT to return the previous data structure in the l1 common block.
;			INDEX=INDEX to return the INDEXth data structure in the l1 common block.
;			/CALIB does nothing.
;			/TIMES returns array of starting times in l1 common block instead of data structure.
;			/SDT is for debugging only.  Don't touch it.
;			UNITS=UNITS allows you to choose the returned data's units.  Default is compressed.
;BUGS:		None that I know of.
;UPDATES:
;-

function fa_seb_struct_l1,t,datatype=datatype,type=type, $
							start=start, $
							en=en, $
							advance=advance, $
							retreat=retreat, $
							index=index, $
							calib=calib, $
							times=times, $
							sdt=sdt, $
							units=units, $
							all_dat=all_dat, $
							get_ind=get_ind, $
							shift_array=shift_array

if keyword_set(datatype) then print,'Warning: Keyword DATATYPE Set!'
if keyword_set(type) then print,'Warning: Keyword TYPE Set!'

if keyword_set(times) then return,all_dat.time
ntimes=n_elements(all_dat.time)

delta_time=all_dat.end_time[0]-all_dat.time[0]
time_threshold=delta_time
if n_elements(index) EQ 0 then begin
	if keyword_set(advance) then begin
		if get_ind EQ ntimes-1 then begin
			print,'Error: End of Data. Cannot Advance.'
			return,{data_name:'', valid:0}
		endif
		index=get_ind+1
	endif
	if keyword_set(retreat) then begin
		if get_ind EQ 0 then begin
			print,'Error: Beginning of Data. Cannot Retreat'
			return,{data_name:'', valid:0}
		endif
		index=get_ind-1
	endif
	if keyword_set(en) AND keyword_set(start) then begin
		print,'Error: Both /EN and /START Keywords Set'
		return,{data_name:'', valid:0}
	endif
	if keyword_set(start) then index=0
	if keyword_set(en) then index=ntimes-1
	if n_elements(index) EQ 0 then begin
		if keyword_set(t) then begin
			t=time_double(t)
			if keyword_set(sdt) then time_tmp=all_dat.time else $
				time_tmp=(all_dat.time+all_dat.end_time)/2
			min_tmp=min(time_tmp-t,index_tmp,/absolute)
			min_tmp=abs(min(all_dat.time-t,index_tmp2,/absolute))
			if min_tmp LT time_threshold then index_tmp=index_tmp2
			original_t=t
			index=index_tmp[0]
			if abs(min_tmp) GT 5 then begin
				print,'Warning: All Data Samples Further than 5 Seconds from t'
				original_flag=1
			endif
		endif else begin
			ctime,t,npoints=1
			if NOT keyword_set(t) then begin
				print,'Error @ fa_seb_struct_1l.pro: CTIME Failure!'
				return,{data_name:'', valid:0}
			endif
			time_tmp=(all_dat.time+all_dat.end_time)/2
			min_tmp=min(time_tmp-t,index_tmp,/absolute)
			min_tmp=abs(min(all_dat.time-t,index_tmp2,/absolute))
			if min_tmp LT time_threshold then index_tmp=index_tmp2
			original_t=t
			index=index_tmp[0]
			if abs(min_tmp) GT 5 then begin
				print,'Warning: All Data Samples Further than 5 Seconds from t'
				original_flag=1
			endif
		endelse
	endif
endif
if (index LT 0) OR (index GE ntimes) then begin
	print,'Error: Index Out of Bounds!'
	return,{data_name:'', valid:0}
endif
;t=all_dat.time[index]
get_ind=long(index)

nenergy=all_dat.nenergy[index]
mode_ind=all_dat.mode_ind[index]

if mode_ind EQ 0 then data=all_dat.data0[0:47,0:15,all_dat.data_ind[index]]
if mode_ind EQ 1 then data=all_dat.data1[0:7,0:15,all_dat.data_ind[index]]
if mode_ind EQ 2 then data=all_dat.data2[0:3,0:15,all_dat.data_ind[index]]
if mode_ind EQ 3 then data=all_dat.data3[0:1,0:15,all_dat.data_ind[index]]
if mode_ind EQ 4 then data=all_dat.data4[0,0:15,all_dat.data_ind[index]]

end_time=all_dat.end_time[index]
units_procedure=all_dat.units_procedure
valid=all_dat.valid[index]

gf=transpose(rebin(all_dat.gf[*,all_dat.gf_ind[index]],16,nenergy))
theta_shift=all_dat.theta_shift[index]
theta=all_dat.theta[0:nenergy-1,*,all_dat.theta_ind[index]]+theta_shift
where_gt=where(theta GT all_dat.theta_max[index])
where_lt=where(theta LT all_dat.theta_min[index])
if where_gt[0] NE -1 then theta[where_gt]-=360.
if where_lt[0] Ne -1 then theta[where_lt]+=360.
dtheta=replicate(22.5,nenergy,16)

if keyword_set(original_t) AND (NOT keyword_set(original_flag)) then begin
	if (original_t LT (all_dat.time[index]-time_threshold)) OR $
		(original_t GT (end_time+time_threshold)) then $
		print,'Warning: t Not Between TIME and END_TIME'
endif

datastr={data_name:all_dat.data_name, $
		valid:valid, $
		data_quality:all_dat.data_quality[index], $
		project_name:'FAST', $
		units_name:all_dat.units_name, $
		units_procedure:units_procedure, $
		time:all_dat.time[index], $
		end_time:end_time, $
		integ_t:all_dat.integ_t[index], $
		nbins:16, $
		nenergy:nenergy, $
		data:float(data), $
		energy:all_dat.energy[0:nenergy-1,0:15,all_dat.energy_ind[index]], $
		bins:all_dat.bins[0:nenergy-1,0:15,all_dat.bins_ind[index]], $
		theta:theta, $
		geom:gf, $
		gf:gf, $
		denergy:all_dat.denergy[0:nenergy-1,0:15,all_dat.energy_ind[index]], $
		dtheta:dtheta, $
		eff:all_dat.eff[0:nenergy-1,0:15,all_dat.energy_ind[index]], $
		dead:all_dat.dead, $
		mass:all_dat.mass, $
		geom_factor:all_dat.geom_factor[index], $
		geomfactor:all_dat.geom_factor[index], $
		sc_pot:all_dat.sc_pot[index], $
		charge:all_dat.charge, $
		header_bytes:all_dat.header_bytes[*,index], $
		index:index, $
		spin_phase:all_dat.spin_phase[index], $
		spin_num:all_dat.spin_num[index], $
		spin_ph_hdr:all_dat.spin_ph_hdr[index], $
		sweep_num:all_dat.sweep_num[index], $
		swps_per_set:all_dat.swps_per_set[index] }
		
if keyword_set(shift_array) then begin
	energy_shift=fltarr(nenergy,16)+1.
	if nenergy EQ 48 then begin
		case all_dat.data_name of
			'Sesa 1 Burst': begin
				energy_shift[*,0:7]=rebin(all_dat.energy_shift[*,all_dat.shift_ind[index]],48,8)
			end
			'Sesa 3 Burst': begin
				energy_shift[*,8:15]=rebin(all_dat.energy_shift[*,all_dat.shift_ind[index]],48,8)
			end
			'Sesa 5 Burst': begin
				energy_shift[*,8:15]=rebin(all_dat.energy_shift[*,all_dat.shift_ind[index]],48,8)
			end
			else: begin
				if (all_dat.data_name NE 'Sesa 2 Burst') AND $
					(all_dat.data_name NE 'Sesa 4 Burst') AND $
					(all_dat.data_name NE 'Sesa 6 Burst') then print,'Warning: Type Error Alert!'
			end
		endcase
		if (where(energy_shift EQ 0))[0] NE -1 then energy_shift=fltarr(48,16)+1.
	endif
	str_element,datastr,'energy_shift',energy_shift,/add
endif

if NOT keyword_set(units) then units='Counts'
if valid EQ 1 then call_procedure,units_procedure,datastr,units

return,datastr

end