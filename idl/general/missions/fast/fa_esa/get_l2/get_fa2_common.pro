pro get_fa2_common,dtype,type=type,data=data,save=save

if keyword_set(dtype) then type=dtype
if NOT keyword_set(type) then begin
	print,'Error: No Type Input'
	return
endif

case strlowcase(type) of

	'ees': begin
		common fa_ees_l2,get_ind_ees,all_dat_ees
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_ees=data
			return
		endif
		if NOT keyword_set(all_dat_ees) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_ees
	end
	
	'ies': begin
		common fa_ies_l2,get_ind_ies,all_dat_ies
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_ies=data
			return
		endif
		if NOT keyword_set(all_dat_ies) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_ies
	end
	
	'eeb': begin
		common fa_eeb_l2,get_ind_eeb,all_dat_eeb
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_eeb=data
			return
		endif
		if NOT keyword_set(all_dat_eeb) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_eeb
	end
	
	'ieb': begin
		common fa_ieb_l2,get_ind_ieb,all_dat_ieb
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_ieb=data
			return
		endif
		if NOT keyword_set(all_dat_ieb) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_ieb
	end
	
	else: begin
		print,'Error: Invalid Type'
		return
	end
	
endcase

return
end
