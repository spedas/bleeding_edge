function fa_seb_append_l1,dat1,dat2

ntimes1=n_elements(dat1.time)
ntimes2=n_elements(dat2.time)
ntimes=ntimes1+ntimes2

valid=[dat1.valid,dat2.valid]
time=[dat1.time,dat2.time]
end_time=[dat1.end_time,dat2.end_time]
integ_t=[dat1.integ_t,dat2.integ_t]
delta_t=[dat1.delta_t,dat2.delta_t]
nbins=[dat1.nbins,dat2.nbins]
nenergy=[dat1.nenergy,dat2.nenergy]
geom_factor=[dat1.geom_factor,dat2.geom_factor]
mode_ind=[dat1.mode_ind,dat2.mode_ind]
theta_shift=[dat1.theta_shift,dat2.theta_shift]
theta_max=[dat1.theta_max,dat2.theta_max]
theta_min=[dat1.theta_min,dat2.theta_min]
header_bytes=[[dat1.header_bytes],[dat2.header_bytes]]
bkg=[dat1.bkg,dat2.bkg]
sc_pot=[dat1.sc_pot,dat2.sc_pot]

ndata0=n_elements(where(dat1.mode_ind EQ 0))
ndata1=n_elements(where(dat1.mode_ind EQ 1))
ndata2=n_elements(where(dat1.mode_ind EQ 2))
ndata3=n_elements(where(dat1.mode_ind EQ 3))
ndata4=n_elements(where(dat1.mode_ind EQ 4))
where0=where(dat2.mode_ind EQ 0)
where1=where(dat2.mode_ind EQ 1)
where2=where(dat2.mode_ind EQ 2)
where3=where(dat2.mode_ind EQ 3)
where4=where(dat2.mode_ind EQ 4)
dat2_data_ind=dat2.data_ind

if where0[0] NE -1 then begin
	if (dat1.data0[0] NE dat1.data0[0]) then begin
		data0=dat2.data0
	endif else begin
		if (dat2.data0[0] NE dat2.data0[0]) then begin
			data0=dat1.data0
		endif else begin
			data0=[[[dat1.data0]],[[dat2.data0]]]
			dat2_data_ind[where0]+=ndata0
		endelse
	endelse
endif else begin
	data0=dat1.data0
endelse

if where1[0] NE -1 then begin
	if (dat1.data1[0] NE dat1.data1[0]) then begin
		data1=dat2.data1
	endif else begin
		if (dat2.data1[0] NE dat2.data1[0]) then begin
			data1=dat1.data1
		endif else begin
			data1=[[[dat1.data1]],[[dat2.data1]]]
			dat2_data_ind[where1]+=ndata1
		endelse
	endelse
endif else begin
	data1=dat1.data1
endelse

if where2[0] NE -1 then begin
	if (dat1.data2[0] NE dat1.data2[0]) then begin
		data2=dat2.data2
	endif else begin
		if (dat2.data2[0] NE dat2.data2[0]) then begin
			data2=dat1.data2
		endif else begin
			data2=[[[dat1.data2]],[[dat2.data2]]]
			dat2_data_ind[where2]+=ndata2
		endelse
	endelse
endif else begin
	data2=dat1.data2
endelse

if where3[0] NE -1 then begin
	if (dat1.data3[0] NE dat1.data3[0]) then begin
		data3=dat2.data3
	endif else begin
		if (dat2.data3[0] NE dat2.data3[0]) then begin
			data3=dat1.data3
		endif else begin
			data3=[[[dat1.data3]],[[dat2.data3]]]
			dat2_data_ind[where3]+=ndata3
		endelse
	endelse
endif else begin
	data3=dat1.data3
endelse

if where4[0] NE -1 then begin
	if (dat1.data4[0] NE dat1.data4[0]) then begin
		data4=dat2.data4
	endif else begin
		if (dat2.data4[0] NE dat2.data4[0]) then begin
			data4=dat1.data4
		endif else begin
			data4=[[[dat1.data4]],[[dat2.data4]]]
			dat2_data_ind[where4]+=ndata4
		endelse
	endelse
endif else begin
	data4=dat1.data4
endelse

data_ind=[dat1.data_ind,dat2_data_ind]

;Append arrays. Some are not really necessary.
fa_append_2d,dat1.theta,dat2.theta,dat1.theta_ind,dat2.theta_ind,theta,theta_ind
fa_append_2d,dat1.bins,dat2.bins,dat1.bins_ind,dat2.bins_ind,bins,bins_ind
fa_append_1d,dat1.gf,dat2.gf,dat1.gf_ind,dat2.gf_ind,gf,gf_ind,gf_total,gf_map
fa_append_1d,dat1.energy_shift,dat2.energy_shift,dat1.shift_ind,dat2.shift_ind,energy_shift,shift_ind
fa_append_2d,dat1.energy,dat2.energy,dat1.energy_ind,dat2.energy_ind,energy,energy_ind,energy_total,energy_map
fa_append_2d,dat1.denergy,dat2.denergy,dat1.energy_ind,dat2.energy_ind,denergy
fa_append_2d,dat1.eff,dat2.eff,dat1.energy_ind,dat2.energy_ind,eff
bkg_arr_dimen=size(dat1.bkg_arr,/dimensions)
if n_elements(bkg_arr_dimen) EQ 1 then prev_bkg_tot=0
if n_elements(bkg_arr_dimen) EQ 2 then prev_bkg_tot=bkg_arr_dimen[1]-1
if (prev_bkg_tot EQ gf_total) then begin
	bkg_arr=dat1.bkg_arr
endif else begin
	bkg_arr=fltarr(96,64,gf_total+1)
	bkg_arr[*,0:prev_bkg_tot]=dat1.bkg_arr
	for jjj=prev_bkg_tot+1,gf_total do begin
		old_gf_index=(where(gf_map EQ jjj))[0]
		bkg_arr[*,jjj]=dat2.bkg_arr[*,old_gf_index]
	endfor
endelse

data_quality=[dat1.data_quality,dat2.data_quality]
spin_phase=[dat1.spin_phase,dat2.spin_phase]
spin_num=[dat1.spin_num,dat2.spin_num]
spin_ph_hdr=[dat1.spin_ph_hdr,dat2.spin_ph_hdr]
sweep_num=[dat1.sweep_num,dat2.sweep_num]
swps_per_set=[dat1.swps_per_set,dat2.swps_per_set]

return,{project_name:'FAST', $
		data_name:dat1.data_name, $
		data_level:dat1.data_level, $
		units_name:dat1.units_name, $
		units_procedure:dat1.units_procedure, $
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
		shift_ind:shift_ind, $
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
		data4:data4, $
		energy:energy, $
		bins:bins, $
		theta:theta, $
		gf:gf, $
		denergy:denergy, $
		dtheta:dat1.dtheta, $
		eff:eff, $
		dead:dat1.dead, $
		mass:dat1.mass, $
		charge:dat1.charge, $
		energy_shift:energy_shift, $
		bkg_arr:bkg_arr, $
		header_bytes:header_bytes, $
		spin_phase:spin_phase, $
		spin_num:spin_num, $
		spin_ph_hdr:spin_ph_hdr, $
		sweep_num:sweep_num, $
		swps_per_set:swps_per_set}
		
end