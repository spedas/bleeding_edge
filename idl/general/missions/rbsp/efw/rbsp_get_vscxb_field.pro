;Get the Vsc x B motional electric field for RBSP

;Input: tplot variable names. These variables should contain
;	velocity, and mag data in MGSE coord.
;   (optional) timesinterp --> array of times to interpolate vel and mag data to. 
;                   If not input then the times used are vel or mag, depending on which 
;                   is higher cadence.

;Written by Aaron W Breneman   11/2012


pro rbsp_get_vscxb_field,velname,magname,timesinterp


    if ~keyword_set(timesinterp) then begin 
    	get_data,velname,data=vel
	    get_data,magname,data=mag
        nvel = n_elements(vel.x)
        nmag = n_elements(mag.x)
        if nmag ge nvel then timesint = mag.x else timesint = vel.x
    endif else timesint = timesinterp




	;Interpolate data to be on same cadence
	mag1 = interpol(mag.y[*,0],mag.x,timesint)/1d9
	mag2 = interpol(mag.y[*,1],mag.x,timesint)/1d9
	mag3 = interpol(mag.y[*,2],mag.x,timesint)/1d9

	vel1 = interpol(vel.y[*,0],vel.x,timesint)*1d6
	vel2 = interpol(vel.y[*,1],vel.x,timesint)*1d6
	vel3 = interpol(vel.y[*,2],vel.x,timesint)*1d6



	;Calculate the vxB components.
	vxB_x = (vel2*mag3 - vel3*mag2)
	vxB_y = (vel3*mag1 - vel1*mag3)
	vxB_z = (vel1*mag2 - vel2*mag1)

  ;vxb consists of Vsc x B and Vcoro x B
	store_data,'vxb_x',data={x:timesint,y:vxb_x}
	store_data,'vxb_y',data={x:timesint,y:vxb_y}
	store_data,'vxb_z',data={x:timesint,y:vxb_z}

	options,'vxb_x','ytitle','-(vxB)!CmV/m!CMGSEx'
	options,'vxb_y','ytitle','-(vxB)!CmV/m!CMGSEy'
	options,'vxb_z','ytitle','-(vxB)!CmV/m!CMGSEz'




end

