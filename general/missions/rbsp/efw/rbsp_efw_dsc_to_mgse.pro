;+
; NAME:	RBSP_EFW_DSC_TO_MGSE
;
; SYNTAX:
;   rbsp_dsc_to_mgse,'a',tplot_var,wgse

;
; PURPOSE:	Rotates data from despun spacecraft coordinates (DSC) into the
;			modified GSE (MGSE) coordinate system. 
;
;			DSC is defined:
;				Z_DSC is the spin axis direction, W_SC
;				X_DSC is the sun sensor triggering direction, perpendicular to
;					the spin axis
;				Y_DSC completes the RH system in the spin plane
;
;			MGSE is defined:
;				Y_MGSE=-W_SC(GSE) x Z_GSE
;				Z_MGSE=W_SC(GSE) x Y_MGSE
;				X_MGSE=Y_MGSE x Z_MGSE
;
; INPUT:
;	probe	- either 'a' or 'b'
;	tvar	- TPLOT variable containing 3-component DSC data (either string or
;				integer).
;	tvar_wgse    - TPLOT variable containing the spin axis pointing direction in GSE coord. 
;					Get this from rbsp_load_spice_cdf_file.pro
;
; KEYWORDS:
;	suffix = 'string', suffix appended to the tplot variable name. Default is
;			'mgse'
;	uangle = degrees, angle between sun sensor and +U (EFW 1) boom
;	/debug - save various quantities for debugging
;
; NOTES:
;	0) This routine does not check that the supplied data is in DSC system.
;
; HISTORY:
;	1. Created July 2020 - Aaron Breneman forked from Kris Kersten's rbsp_dsc_to_mgse.pro
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2020-09-11 13:41:36 -0700 (Fri, 11 Sep 2020) $
;   $LastChangedRevision: 29145 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_dsc_to_mgse.pro $
;
;-



pro rbsp_efw_dsc_to_mgse,probe,tvar,tvar_wgse,suffix=suffix,$
	uangle=uangle,debug=debug,_extra=extra


	rbsp_efw_init,_extra=extra



	probe=string(probe)
	if probe ne 'a' and probe ne 'b' then begin
		message,'Invalid probe: "'+probe+'". Returning...',/continue
		return
	endif


	;Extract DSC values from input tplot variable
	nvar=size(tvar,/n_elements)
	if nvar eq 1 then begin

		tn=tnames(tvar)
		get_data,tvar,data=d,limits=l,dlimits=dl
		s=size(d.y)
		if size(s,/n_elements) ne 5 then begin
			message,'No valid 3-component DSC data found '+$
				'in supplied tplot variable. Returning...',/continue
			return
		endif else if s[0] ne 2 and s[2] ne 3 then begin
			message,'No valid 3-component DSC data found '+$
				'in supplied tplot variable. Returning...',/continue
			return
		endif

		times=d.x
		dx=d.y[*,0]
		dy=d.y[*,1]
		dz=d.y[*,2]

	endif else begin

		message,'No valid 3-component DSC data found '+$
			'in supplied tplot variable. Returning...',/continue
		return

	endelse




	;get times based on input tvar
	ntimes=size(times,/n_elements)
	tr=[times[0],times[ntimes-1]]
	duration=tr[1]-tr[0]
	utimes=tr[0]+dindgen(long(duration/60)+1)*60. ; minutes, UNIX time
	nutimes = n_elements(utimes)



	;Interpolate the spin axis pointing direction to times of input tplot variable
	tinterpol_mxn,tvar_wgse,utimes,/quadratic
	get_data,tvar_wgse+'_interp',tt,wsc_gse
	wsc_gse = transpose(wsc_gse)
	store_data,tvar_wgse+'_interp',/del


	;----------------
	;AWB note: only Y-MGSE component is needed. 
	; Now calculate the MGSE unit vectors in terms of GSE
;	X_MGSE=dblarr(3,nutimes)
	Y_MGSE=dblarr(3,nutimes)
;	Z_MGSE=dblarr(3,nutimes)

	for i=0L,nutimes-1L do $
		Y_MGSE[0:2,i]=-1d*crossp(wsc_GSE[0:2,i],[0.,0.,1.])/norm(crossp(wsc_GSE[0:2,i],[0.,0.,1.]))
;	for i=0L,nutimes-1L do $
;		Z_MGSE[0:2,i]=crossp(wsc_GSE[0:2,i],Y_MGSE[0:2,i])/norm(crossp(wsc_GSE[0:2,i],Y_MGSE[0:2,i]))
;	for i=0L,nutimes-1L do $
;		X_MGSE[0:2,i]=crossp(Y_MGSE[0:2,i],Z_MGSE[0:2,i])
	;----------------



	; Calculate the normal to the sun sensor triggering plane, nTsg,
	; defined as the cross product between X_GSE and the spin axis direction
	nTsg=dblarr(3,nutimes)
	for i=0L,nutimes-1L do $
		nTsg[0:2,i]=crossp([1.,0.,0.],wsc_GSE[0:2,i])/norm(crossp([1.,0.,0.],wsc_GSE[0:2,i]))


	; Then the triggering sun sensor look direction perpendicular to the spin axis
	; is defined by the cross product of the spin axis direction and nssh
	Tsg=dblarr(3,nutimes)
	for i=0L,nutimes-1L do $
		Tsg[0:2,i]=crossp(wsc_GSE[0:2,i],nTsg[0:2,i])/norm(crossp(wsc_GSE[0:2,i],nTsg[0:2,i]))


	; Find the angle between the sun sensor triggering direction (X_DSC) and the
	; Y_MGSE direction for rotation from DSC into MGSE.
	alpha_temp=dblarr(nutimes)
	for i=0L,nutimes-1L do $
		alpha_temp[i]=acos(Tsg[0,i]*Y_MGSE[0,i]+Tsg[1,i]*Y_MGSE[1,i]+Tsg[2,i]*Y_MGSE[2,i])
	alpha_temp=alpha_temp/!dtor ; in degrees


	;------------------------------------------
	;AWB change added Sept, 2020.
	;Note that alpha_temp can only be positive. However, when the spinaxis ZMGSE component is 
	;negative then we need to make alpha_temp negative. 
	;Not doing this results in a sign flip in EMGSE components. 
	goo = where(wsc_gse[2,*] lt 0.)
	if goo[0] ne -1 then alpha_temp[goo] *= -1 
	;------------------------------------------



	; interpolate alpha to tplot var data points
	alpha=dblarr(3,nutimes)
	alpha=interpol(alpha_temp,utimes,times)



	if keyword_set(debug) then store_data,'alpha_Tsg_YMGSE',data={x:times,y:alpha}

	; rotation from SSH triggering direction to YMGSE direction is
	; in the opposite sense of DSC despinning and the angle between U_science
	; and SSH triggering direction

	if ~keyword_set(uangle) then uangle=10.

	xm=cos((uangle-alpha)*!dtor)
	ym=sin((uangle-alpha)*!dtor)




	;Calculate and store MGSE variables
	ymgse=dx*xm-dy*ym
	zmgse=dx*ym+dy*xm
	xmgse=dz

	mgse=[[xmgse],[ymgse],[zmgse]]
	str_element,l,'labels',['X_MGSE','Y_MGSE','Z_MGSE'],/add_replace
	if is_struct(dl.data_att) then $
		str_element,dl.data_att,'coord_sys','mgse',/add_replace

	if ~keyword_set(suffix) then suffix='mgse'
	store_data,tn+'_'+suffix,data={x:times,y:mgse},limits=l,dlimits=dl



end
