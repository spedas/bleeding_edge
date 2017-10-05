;+
;PURPOSE:	To return a data structure for a specific time from a FAST l1 common block.
;USEAGE:	dat=fa_esa_struct_l1(t,all_dat=all_dat,get_ind=get_ind)
;			dat=fa_esa_struct_l1(all_dat=all_dat,get_ind=get_ind) will call ctime.pro to get t.
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
;UPDATES:	Written by Dillon Wong.
;			June 18, 2010 - Fixed /ADVANCE keyword for Electron Burst Data.
;			June 21, 2010 - Minor Update.
;-

function fa_esa_struct_l1,t,datatype=datatype,type=type, $
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
							get_ind=get_ind
							
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
				print,'Error @ fa_esa_struct_1l.pro: CTIME Failure!'
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

nbins=all_dat.nbins[index]
nenergy=all_dat.nenergy[index]
mode_ind=all_dat.mode_ind[index]

if mode_ind EQ 0 then begin
	if (nbins NE 32) OR (nenergy NE 48) then print,'Fatal Error Detected!'
	data=all_dat.data0[0:nenergy-1,0:nbins-1,all_dat.data_ind[index]]
endif

if mode_ind EQ 1 then begin
	if (nbins NE 64) OR (nenergy NE 48) then print,'Fatal Error Detected!'
	data=all_dat.data1[0:nenergy-1,0:nbins-1,all_dat.data_ind[index]]
endif

if mode_ind EQ 2 then begin
	if (nbins NE 32) OR (nenergy NE 96) then print,'Fatal Error Detected!'
	data=all_dat.data2[0:nenergy-1,0:nbins-1,all_dat.data_ind[index]]
endif

end_time=all_dat.end_time[index]
units_procedure=all_dat.units_procedure
valid=all_dat.valid[index]

gf=all_dat.gf[0:nenergy-1,0:nbins-1,all_dat.gf_ind[index]]
theta_shift=all_dat.theta_shift[index]
theta_max=all_dat.theta_max[index]
theta_min=all_dat.theta_min[index]
opp_theta_shift=360.*theta_shift/abs(theta_shift)
theta=all_dat.theta[0:nenergy-1,0:nbins-1,mode_ind]+theta_shift
where_theta_greater=where(theta GT theta_max)
where_theta_lesser=where(theta LT theta_min)
if where_theta_greater[0] NE -1 then theta[where_theta_greater]-=opp_theta_shift
if where_theta_lesser[0] NE -1 then theta[where_theta_lesser]-=opp_theta_shift
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
		nbins:nbins, $
		nenergy:nenergy, $
		data:float(data), $
		energy:all_dat.energy[0:nenergy-1,0:nbins-1,mode_ind], $
		bins:all_dat.bins[0:nenergy-1,0:nbins-1,all_dat.bins_ind[index]], $
		theta:theta, $
		geom:gf, $
		gf:gf, $
		denergy:all_dat.denergy[0:nenergy-1,0:nbins-1,mode_ind], $
		dtheta:all_dat.dtheta[0:nenergy-1,0:nbins-1,mode_ind], $
		eff:all_dat.eff[0:nenergy-1,0:nbins-1,mode_ind], $
		dead:all_dat.dead, $
		mass:all_dat.mass, $
		geom_factor:all_dat.geom_factor[index], $
		geomfactor:all_dat.geom_factor[index], $
		sc_pot:all_dat.sc_pot[index], $
		charge:all_dat.charge, $
		header_bytes:all_dat.header_bytes[*,index], $
		index:index }
		
if keyword_set(units) AND (valid EQ 1) then call_procedure,units_procedure,datastr,units

return,datastr

end