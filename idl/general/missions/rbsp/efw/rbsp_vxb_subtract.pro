;RBSP vxB subtraction routine

;Input: tplot variable names. These variables should contain
;	velocity, mag and E-field data in MGSE coord.
;	To get these quantities in MGSE first use cotrans to go from
;	whatever coord system to GSE. Then use rbsp_gse2mgse.pro to go
;	to MGSE

;Velocity and mag data interpolated to times of Esvy data

;Written by Aaron W Breneman   11/2012



pro rbsp_vxb_subtract,velname,magname,esvyname



	get_data,velname,data=vel
	get_data,magname,data=mag
	get_data,esvyname,data=esvy


	;Interpolate data to be on same cadence
	mag1 = interpol(mag.y[*,0],mag.x,esvy.x)/1d9
	mag2 = interpol(mag.y[*,1],mag.x,esvy.x)/1d9
	mag3 = interpol(mag.y[*,2],mag.x,esvy.x)/1d9

	vel1 = interpol(vel.y[*,0],vel.x,esvy.x)*1d6
	vel2 = interpol(vel.y[*,1],vel.x,esvy.x)*1d6
	vel3 = interpol(vel.y[*,2],vel.x,esvy.x)*1d6



	;Calculate the vxB components.
	vxB_x = (vel2*mag3 - vel3*mag2)
	vxB_y = (vel3*mag1 - vel1*mag3)
	vxB_z = (vel1*mag2 - vel2*mag1)

        ;vxb consists of Vsc x B and Vcoro x B
	store_data,'vxb_x',data={x:esvy.x,y:vxb_x}
	store_data,'vxb_y',data={x:esvy.x,y:vxb_y}
	store_data,'vxb_z',data={x:esvy.x,y:vxb_z}

	options,'vxb_x','ytitle','-(vxB)!CmV/m!CMGSEx'
	options,'vxb_y','ytitle','-(vxB)!CmV/m!CMGSEy'
	options,'vxb_z','ytitle','-(vxB)!CmV/m!CMGSEz'



	;---------------------------------------
	;E - vxB
	;---------------------------------------


	diffx = esvy.y[*,0] - vxB_x
	diffy = esvy.y[*,1] - vxB_y
	diffz = esvy.y[*,2] - vxB_z


	store_data,'Esvy_mgse_vxb_removed',data={x:esvy.x,y:[[diffx],[diffy],[diffz]]}


	velmag = sqrt(vxB_x^2 + vxB_y^2 + vxB_z^2)
	store_data,'vxbmag',data={x:esvy.x,y:velmag}




end
