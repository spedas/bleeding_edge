pro get_fa1_common,dtype,type=type,data=data,save=save

if keyword_set(dtype) then type=dtype
if NOT keyword_set(type) then begin
	print,'Error: No Type Input'
	return
endif

case strlowcase(type) of

	'ees': begin
		common fa_ees_l1,get_ind_ees,all_dat_ees
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
		common fa_ies_l1,get_ind_ies,all_dat_ies
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
		common fa_eeb_l1,get_ind_eeb,all_dat_eeb
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
		common fa_ieb_l1,get_ind_ieb,all_dat_ieb
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
	
	'ses': begin
		common fa_ses_l1,get_ind_ses,all_dat_ses
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_ses=data
			return
		endif
		if NOT keyword_set(all_dat_ses) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_ses
	end
	
	'seb': begin
		common fa_seb_l1,get_ind_seb,all_dat_seb
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_seb=data
			return
		endif
		if NOT keyword_set(all_dat_seb) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_seb
	end
	
	'seb1': begin
		common fa_seb1_l1,get_ind_seb1,all_dat_seb1
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_seb1=data
			return
		endif
		if NOT keyword_set(all_dat_seb1) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_seb1
	end
	
	'seb2': begin
		common fa_seb2_l1,get_ind_seb2,all_dat_seb2
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_seb2=data
			return
		endif
		if NOT keyword_set(all_dat_seb2) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_seb2
	end
	
	'seb3': begin
		common fa_seb3_l1,get_ind_seb3,all_dat_seb3
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_seb3=data
			return
		endif
		if NOT keyword_set(all_dat_seb3) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_seb3
	end
	
	'seb4': begin
		common fa_seb4_l1,get_ind_seb4,all_dat_seb4
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_seb4=data
			return
		endif
		if NOT keyword_set(all_dat_seb4) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_seb4
	end
	
	'seb5': begin
		common fa_seb5_l1,get_ind_seb5,all_dat_seb5
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_seb5=data
			return
		endif
		if NOT keyword_set(all_dat_seb5) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_seb5
	end
	
	'seb6': begin
		common fa_seb6_l1,get_ind_seb6,all_dat_seb6
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_seb6=data
			return
		endif
		if NOT keyword_set(all_dat_seb6) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_seb6
	end
	
	'seb': begin
		common fa_seb_l1,get_ind_seb,all_dat_seb
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_seb=data
			return
		endif
		if NOT keyword_set(all_dat_seb) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_seb
	end
	
	'ses': begin
		common fa_ses_l1,get_ind_ses,all_dat_ses
		if keyword_set(save) then begin
			if NOT keyword_set(data) then begin
				print,'Error: No Data Input'
				return
			endif
			all_dat_ses=data
			return
		endif
		if NOT keyword_set(all_dat_ses) then begin
			print,'Error: No Data in Common Block'
			return
		endif
		data=all_dat_ses
	end
	
	else: begin
		print,'Error: Invalid Type'
		return
	end
	
endcase

return
end