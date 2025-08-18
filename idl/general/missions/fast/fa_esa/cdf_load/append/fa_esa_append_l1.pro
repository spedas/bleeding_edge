function fa_esa_append_l1,dat1,dat2

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
;header_bytes=bytarr(44,ntimes1+ntimes2)
;header_bytes[44,0:ntimes1-1]=dat1.header_bytes
;header_bytes[44,ntimes1:ntimes-1]=dat2.header_bytes
bkg=[dat1.bkg,dat2.bkg]
sc_pot=[dat1.sc_pot,dat2.sc_pot]

ndata0=n_elements(where(dat1.mode_ind EQ 0))
ndata1=n_elements(where(dat1.mode_ind EQ 1))
ndata2=n_elements(where(dat1.mode_ind EQ 2))
where00=where(dat2.mode_ind EQ 0)
where11=where(dat2.mode_ind EQ 1)
where10=where(dat2.mode_ind EQ 2)
dat2_data_ind=dat2.data_ind
dat2_gf_ind=dat2.gf_ind

if where00[0] NE -1 then begin
	if (dat1.data0[0] NE dat1.data0[0]) then begin
		data0=dat2.data0
		;gf_48_32=dat2.gf_48_32
	endif else begin
		if (dat2.data0[0] NE dat2.data0[0]) then begin
			data0=dat1.data0
		endif else begin
			data0=[[[dat1.data0]],[[dat2.data0]]]
			;gf_48_32=[[[dat1.gf_48_32]],[[dat2.gf_48_32]]]
			dat2_data_ind[where00]+=ndata0
			;dat2_gf_ind[where00]+=n_elements(dat1.gf_48_32)
		endelse
	endelse
endif else begin
	data0=dat1.data0
	;gf_48_32=dat1.gf_48_32
endelse

if where11[0] NE -1 then begin
	if (dat1.data1[0] NE dat1.data1[0]) then begin
		data1=dat2.data1
		;gf_48_64=dat2.gf_48_64
	endif else begin
		if (dat2.data1[0] NE dat2.data1[0]) then begin
			data1=dat1.data1
		endif else begin
			data1=[[[dat1.data1]],[[dat2.data1]]]
			;gf_48_64=[[[dat1.gf_48_64]],[[dat2.gf_48_64]]]
			dat2_data_ind[where11]+=ndata1
			;dat2_gf_ind[where11]+=n_elements(dat1.gf_48_64)
		endelse
	endelse
endif else begin
	data1=dat1.data1
	;gf_48_32=dat1.gf_48_64
endelse

if where10[0] NE -1 then begin
	if (dat1.data2[0] NE dat1.data2[0]) then begin
		data2=dat2.data2
		;gf_96_32=dat2.gf_96_32
	endif else begin
		if (dat2.data2[0] NE dat2.data2[0]) then begin
			data2=dat1.data2
		endif else begin
			data2=[[[dat1.data2]],[[dat2.data2]]]
			;gf_96_32=[[[dat1.gf_96_32]],[[dat2.gf_96_32]]]
			dat2_data_ind[where10]+=ndata2
			;dat2_gf_ind[where10]+=n_elements(dat1.gf_96_32)
		endelse
	endelse
endif else begin
	data2=dat1.data2
	;gf_96_32=dat1.gf_96_32
endelse

data_ind=[dat1.data_ind,dat2_data_ind]
gf_ind=[dat1.gf_ind,dat2_gf_ind]

;if (n_elements(dat1.energy) GE n_elements(dat2.energy)) then begin
;	energy=dat1.energy
;endif else begin
;	energy=dat2.energy
;endelse

energy=dat1.energy
theta=dat1.theta
denergy=dat1.denergy
dtheta=dat1.dtheta
eff=dat1.eff

;bins_ind1=dat1.bins_ind
;bins_ind2=dat2.bins_ind
;nbins1=max(bins_ind1)
;nbins2=max(bins_ind2)
;bins_index=nbins1
;bins=bytarr(96,64,bins1+bins2+2)
;bins_ind=intarr(ntimes)
;bins[*,*,0:bins_index]=dat1.bins
;for i=0,nbins2 do begin
;	bins_test=0
;	bin_id=0
;	for j=0,nbins1 do begin
;		bins_test=equal_arrays(dat1.bins[*,*,j],dat2.bins[*,*,i])
;		if bins_test EQ 1 then begin
;			bins_ind2[where(dat2.bins_ind EQ i)]=j
;			bin_id=1
;			break
;		endif
;	endfor
;	if NOT bin_id then begin
;		++bins_index
;		bins_ind2[where(dat2.bins_ind EQ i)]=bins_index
;		bins[*,*,bins_index]=dat2.bins[*,*,i]
;	endif
;endfor
;bins=bins[*,*,0:bins_index]
;bins_ind=[bins_ind1,bins_ind2]

;bins_ind1=dat1.bins_ind
;bins_ind2=dat2.bins_ind
;gf_ind1=dat1.gf_ind
;gf_ind2=dat2.gf_ind
fa_append_2d,dat1.bins,dat2.bins,dat1.bins_ind,dat2.bins_ind,bins,bins_ind
fa_append_2d,dat1.gf,dat2.gf,dat1.gf_ind,dat2.gf_ind,gf,gf_ind,gf_total,gf_map
bkg_arr_dimen=size(dat1.bkg_arr,/dimensions)
if n_elements(bkg_arr_dimen) EQ 2 then prev_bkg_tot=0
if n_elements(bkg_arr_dimen) EQ 3 then prev_bkg_tot=bkg_arr_dimen[2]-1
if (prev_bkg_tot EQ gf_total) then begin
	bkg_arr=dat1.bkg_arr
endif else begin
	bkg_arr=fltarr(96,64,gf_total+1)
	bkg_arr[*,*,0:prev_bkg_tot]=dat1.bkg_arr
	for jjj=prev_bkg_tot+1,gf_total do begin
;		old_gf_index=dat2.gf_ind[gf_index(where(gf_ind2 EQ jjj))[0]]
		old_gf_index=(where(gf_map EQ jjj))[0]
		bkg_arr[*,*,jjj]=dat2.bkg_arr[*,*,old_gf_index]
	endfor
endelse

data_quality=[dat1.data_quality,dat2.data_quality]

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
		theta_shift:theta_shift, $
		theta_max:theta_max, $
		theta_min:theta_min, $
		bkg:bkg, $
		data0:data0, $
		data1:data1, $
		data2:data2, $
		energy:dat1.energy, $
		bins:bins, $
		theta:dat1.theta, $
		gf:gf, $
		denergy:dat1.denergy, $
		dtheta:dat1.dtheta, $
		eff:dat1.eff, $
		dead:dat1.dead, $
		mass:dat1.mass, $
		charge:dat1.charge, $
		sc_pot:sc_pot, $
		bkg_arr:bkg_arr, $
		header_bytes:header_bytes}
		
end