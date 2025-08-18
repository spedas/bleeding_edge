;+
;Procedure: rbsp_gse2mgse
;
;Purpose:  Transforms from GSE to MGSE (modified GSE coord..defined below)
;
;	If W gse is the spin axis unit vector in GSE coordinates, then
;	(1) Ymgse = -(Wgse x Zgse)
;
;	So Ymgse is now in the spin plane and in the ecliptic plane and duskward. (nearly same as Ygse)
;	(2) Zmgse =  (Wgse x Ymgse)
;
;	So Z mgse points in the spin plane nearly along the positive normal to the ecliptic
;	(3) Xmgse= Ymgse x Zmgse
;
;	This actually the spin axis of the spacecraft X mgse= W gse
;
;	One of the properties of this coordinate system is that if the spin axis points
;	towards the sun, then the MGSE system is exactly the same as the GSE system.
;	This is a real advantage when thinking about the data and comparing to other instruments.
;
;	Second, since on RBSP the spin axis has a large angle relative to the z GSE axis the
;	cross product in equation 1 is well defined. None of the cross products involve nearly
;	parallel vectors- nothing is ever close to degenerate.
;
;
;Input : tname = the tplot variable with data in GSE coord [n,3]
;		 wgse = the w-antenna direction in GSE coord. This can either be a [3] element
;		   	    array or an [n,3] element array.
;		 Here's how to get wgse:
;    1) rbsp_efw_position_velocity_crib.pro
;		 2) rbsp_load_state,probe='a',datatype=['spinper','spinphase','mat_dsc','Lvec']
;		 Whichever way you choose, you'll get the direction from:
;	   get_data,rbspx+'_spinaxis_direction_gse',data=wsc_GSE
;	   wgse = wsc_gse.y
;
;		 newname = name for output tplot variable. If not set then new name is
;					old name + '_mgse'
;
;
;Example:
;	rbsp_gse2mgse,'mag_gse',[1,0,0],/nochange
;
;Written by Aaron Breneman, Oct 31, 2012
;	2013-10-02 -> added a check to make sure the WGSE array is the correct size.
;				  Returns if it isn't.
; 	2022-08-07 -> just use rbsp_mgse2gse with inverse.
;-


pro rbsp_gse2mgse, tname, wgse, probe=probe, $
	newname=newname, inverse=inverse, $
	no_spice_load=no_spice_load, $
	_extra=extra

	if keyword_set(inverse) then begin
		; inverse=1, means we want mgse2gse.
		rbsp_mgse2gse, tname, wgse, probe=probe, newname=newname, inverse=0, no_spice_load=no_spice_load, _extra=extra
	endif else begin
		; inverse=0, means we want gse2mgse.
		rbsp_mgse2gse, tname, wgse, probe=probe, newname=newname, inverse=1, no_spice_load=no_spice_load, _extra=extra
	endelse

end
