;+
;PROCEDURE:	mac_lpw_load_pot_c6
;PURPOSE:	
;	Creates a common block with lpw pot into c6 common block structure
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  19/08/28
;MOD HISTORY:
;
;NOTES:	  
;	If there are days where 'mvn_lpw_swp2_V1' dominates the data, and wave mode is used, then we may want add code
;		so that the roles of v1 and v2 are reversed
;	
;-
pro mac_lpw_load_pot_c6

	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
	common mvn_lpw_pot_c6,mvn_lpw_pot_c6_dat 

	get_data,'mvn_lpw_swp2_V1',data=v1
	get_data,'mvn_lpw_swp1_V2',data=v2	; this is the one used most of the time

	get_data,'mvn_lpw_act_V2',data=v3
	get_data,'mvn_lpw_pas_V2',data=v4

	get_data,'mvn_lpw_act_V1',data=v5
	get_data,'mvn_lpw_pas_V1',data=v6

; remove the offset from v1

	if size(v3,/type) eq 8 and size(v4,/type) eq 8 and size(v5,/type) eq 8 and size(v6,/type) eq 8 then begin
		if n_elements(v3.x) eq n_elements(v5.x) and n_elements(v4.x) eq n_elements(v6.x) then begin 	
			v_act_diff = v5.y-v3.y
			v_pas_diff = v6.y-v4.y
			t_combined = [v3.x,v4.x]
			v_combined = [v5.y-v3.y,v6.y-v4.y]
			t_ind = sort(t_combined)
			dv_x = t_combined[t_ind]
			dv_y = v_combined[t_ind]
			v_corr = interp(dv_y,dv_x,v1.x)
			v1.y = v1.y - v_corr 
		endif else begin
			print,'Error - mac_lpw_load_pot_c6 - lpw data inconsistent'
			return
		endelse
	endif

; combine data

	if size(v1,/type) eq 8 and size(v2,/type) eq 8 and size(v3,/type) eq 8 and size(v4,/type) eq 8 then begin
		t_combined = [v1.x,v2.x,v3.x,v4.x]
		v_combined = [v1.y,v2.y,v3.y,v4.y]
		t_ind = sort(t_combined)
		v_x = t_combined[t_ind]
		v_y = v_combined[t_ind]
	endif else if size(v1,/type) eq 8 and size(v2,/type) eq 8 then begin
		t_combined = [v1.x,v2.x]
		v_combined = [v1.y,v2.y]
		t_ind = sort(t_combined)
		v_x = t_combined[t_ind]
		v_y = v_combined[t_ind]
	endif else if size(v1,/type) eq 8 then begin
		v_y=v1.y
		v_x=v1.x
	endif else if size(v2,/type) eq 8 then begin
		v_y=v2.y
		v_x=v2.x
	endif else begin
		print,'Error - must load lpw l0 data for this to work!!'
		return
	endelse

	store_data,'mvn_lpw_pot_c6_raw',data={x:v_x,y:v_y}

	npts = n_elements(mvn_c6_dat.time)
	sta_tt = reform(replicate(1.,32)#mvn_c6_dat.time + ((findgen(32)+.5)/8.)#replicate(1.,npts),1l*npts*32)	

	v_sm = smooth_in_time(v_y,v_x,0.125)		; smooth variations before interpolation

	t_offset=0.
;	lpw_pot = interp(v_sm,v_x+t_offset,sta_tt)>1.1				; 1.2 is a kluge for when the lp goes positive relative to the s/c
	lpw_pot = interp(v_sm,v_x+t_offset,sta_tt)>0.01				; 1.2 is a kluge for when the lp goes positive relative to the s/c
	store_data,'mvn_lpw_pot_c6',data={x:sta_tt,y:lpw_pot}

	pot_str = {time:mvn_c6_dat.time,pot:transpose(reform(lpw_pot,32,npts))}
	mvn_lpw_pot_c6_dat = pot_str
end
