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
;		 Here's how to get wgse
;    rbsp_load_state,probe='a',datatype=['spinper','spinphase','mat_dsc','Lvec']
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
;-


pro rbsp_gse2mgse,tname,wgse,newname=newname



	get_data,tname,data=dat,dlimits=dlim,limits=lim
	zgse = [0,0,1d]
	datx = dblarr(n_elements(dat.x))
	daty = datx
	datz = datx


	test = size(wgse)


	;Loop for single value of wgse. This value will be applied to the rotation of
	;every data point

	if test[0] eq 1 then begin

		;Normalize wgse..just in case
		wgse = wgse/sqrt(wgse[0]^2 + wgse[1]^2 + wgse[2]^2)

		;MGSE axes in terms of GSE coord
		Ymgse = -1d*crossp(wgse,zgse)
		Ymgse = Ymgse/sqrt(Ymgse[0]^2 + Ymgse[1]^2 + Ymgse[2]^2)

		Zmgse = crossp(wgse,Ymgse)
		Zmgse = Zmgse/sqrt(Zmgse[0]^2 + Zmgse[1]^2 + Zmgse[2]^2)

		Xmgse = crossp(Ymgse,Zmgse)
		Xmgse = Xmgse/(sqrt(Xmgse[0]^2 + Xmgse[1]^2 + Xmgse[2]^2))


		for j=0L,n_elements(dat.x)-1 do begin
			;Project data along MGSE axes
			datx[j] = total(dat.y[j,*]*Xmgse)
			daty[j] = total(dat.y[j,*]*Ymgse)
			datz[j] = total(dat.y[j,*]*Zmgse)
		endfor

	endif



	if test[0] ne 1 then begin

		;Make sure that the Wgse vector has the same number of elements as tname
		if test[1] ne n_elements(dat.x) then begin
			print,'****************************************************'
			print,"'WGSE ARRAY [n,3] DOESN'T HAVE THE CORRECT SIZE....'"
			print,'THE n MUST BE THE SAME AS THE NUMBER OF TIMES IN TNAME'
			print,'OR BE SIZE [3] ARRAY'
			print,'****************************************************'
			return
		endif


		for j=0L,n_elements(dat.x)-1 do begin

			;Normalize wgse..just in case
			wgse[j,*] = wgse[j,*]/sqrt(wgse[j,0]^2 + wgse[j,1]^2 + wgse[j,2]^2)


			;MGSE axes in terms of GSE coord
			Ymgse = -1d*crossp(wgse[j,*],zgse)
			Ymgse = Ymgse/(sqrt(Ymgse[0]^2 + Ymgse[1]^2 + Ymgse[2]^2))
			Zmgse = crossp(wgse[j,*],Ymgse)
			Zmgse = Zmgse/(sqrt(Zmgse[0]^2 + Zmgse[1]^2 + Zmgse[2]^2))
			Xmgse = crossp(Ymgse,Zmgse)
			Xmgse = Xmgse/(sqrt(Xmgse[0]^2 + Xmgse[1]^2 + Xmgse[2]^2))



			;Project data along MGSE axes

			datx[j] = total(dat.y[j,*]*Xmgse)
			daty[j] = total(dat.y[j,*]*Ymgse)
			datz[j] = total(dat.y[j,*]*Zmgse)

		endfor
	endif


	if ~keyword_set(newname) then name = tname+'_mgse' else name = newname
	store_data,name,data={x:dat.x,y:[[datx],[daty],[datz]]}


end
