;+
; NAME:	RBSP_UVW_TO_DSC
;
; SYNTAX:
;   rbsp_uvw_to_dsc,'a',tplot_var
;   rbsp_uvw_to_dsc,'a',tplot_var,/no_spice_load
;
; PURPOSE:	Rotates data from spinning spacecraft (UVW) coordinates into despun
;			spacecraft (DSC) coordinates.
;
;			DSC is defined:
;				Z_DSC is the spin axis direction, W_SC
;				X_DSC is the sun sensor triggering direction, perpendicular to
;					the spin axis
;				Y_DSC completes the RH system in the spin plane
;
; INPUT:
;	probe	- either 'a' or 'b'
;	tvar	- TPLOT variable containing 3-component UVW data (either string or
;				integer).
;          
; KEYWORDS:
;   uangle = degrees, angle between SSH and U
;	suffix = 'string', suffix appended to the tplot variable name. Default is
;			'mgse'
;	/debug - save various quantities for debugging
;
; NOTES:
;	0) This routine does not check that the supplied data is in UVW system.
;
; HISTORY:
;	1. Created Nov 2012 - Kris Kersten, kris.kersten@gmail.com
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2020-09-21 18:16:09 -0700 (Mon, 21 Sep 2020) $
;   $LastChangedRevision: 29174 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_uvw_to_dsc.pro $
;
;-



pro rbsp_uvw_to_dsc,probe,tvar,suffix=suffix,$
	sshb=sshb, no_spice_load=no_spice_load,debug=debug,$
	lrphase=lrphase,uangle=uangle
	
	
	rbsp_efw_init
	
	; delta is the angle between RBSP SCIENCE U and the SSH LOOK direction,
	; 10 degrees for SSHA, and 10+180 for SSHB (I BELIEVE THAT SSHA WAS USED OVER ENTIRE MISSION FOR BOTH SC)
	
	if ~keyword_set(sshb) then delta=10. else delta=190.

	; allow override of angle between U and SSH
	if keyword_set(uangle) then delta=uangle
	
	probe=string(probe)
	if probe ne 'a' and probe ne 'b' then begin
		message,'Invalid probe: "'+probe+'". Returning...',/continue
		return
	endif
	
	nvar=size(tvar,/n_elements)
	
	if nvar eq 1 then begin

		tn=tnames(tvar)
		get_data,tvar,data=d,limits=l,dlimits=dl
		s=size(d.y)
		if size(s,/n_elements) ne 5 then begin
			message,'No valid 3-component UVW data found '+$
				'in supplied tplot variable. Returning...',/continue
			return
		endif else if s[0] ne 2 and s[2] ne 3 then begin
			message,'No valid 3-component UVW data found '+$
				'in supplied tplot variable. Returning...',/continue
			return
		endif
		
		times=d.x
		ntimes=size(times,/n_elements)
		du=d.y[*,0]
		dv=d.y[*,1]
		dw=d.y[*,2]
		
	endif else begin
	
		message,'No valid 3-component UVW data found '+$
			'in supplied tplot variable. Returning...',/continue
		return
		
	endelse


	if ~keyword_set(no_spice_load) then begin
		rbsp_load_spice_predict
		rbsp_load_spice_kernels
	endif

	; SPICE body string and integer IDs for RBSPA, RBSPB
	str_id='RADIATION BELT STORM PROBE '+strupcase(probe)
	sc_id='RBSP'+strupcase(probe)+'_SPACECRAFT'
	sci_id='RBSP'+strupcase(probe)+'_SCIENCE'
	
	if keyword_set(sshb) then ssh='SSH_B' else ssh='SSH_A'
	ssh_id='RBSP'+strupcase(probe)+'_'+ssh
	
	case probe of
		'a':n_id=-362
		'b':n_id=-363
	endcase
	nsc_id=n_id*1000L ; integer SC frame id is -36?000
	nsci_id=nsc_id-50L ; integer SCIENCE frame id is -36?050
	nssh_id=nsc_id-150L ; integer SSHA id is -36?150
	if keyword_set(sshb) then nssh_id-=10L ; and SSHB is -36?160

	
	; get SPICE ephemeris time
	dts=times[1:ntimes-1]-times[0:ntimes-2]
	median_dt=median(dts)
	
	t0=time_string(times[0],prec=6)
	strput,t0,'T',10
	cspice_str2et,t0,et0
	ets=et0+dindgen(ntimes)*median_dt


	; get low time resolution ets for retrieving spin axis pointing
	duration=times[ntimes-1]-times[0]
	n5mtimes=long(duration/300)+1
	ets_5m=et0+dindgen(n5mtimes)*300 ; 5 minute 

	; get sun triggering direction in GSE
	tstart=systime(1)
	cspice_pxform,sci_id,'GSE',ets_5m,sc2gse

	; spin axis direction in GSE
	wsc_gse=dblarr(3,n5mtimes)
	for i=0L,n5mtimes-1L do wsc_gse[0:2,i]=sc2gse[0:2,0:2,i]##[0.d,0.d,1.d]

	; The normal to the sun sensor triggering plane, nTsg, is defined as the
	; cross product between X_GSE and the spin axis direction
	nTsg=dblarr(3,n5mtimes)
	for i=0L,n5mtimes-1L do $
		nTsg[0:2,i]=crossp([1.,0.,0.],wsc_gse[0:2,i])/norm(crossp([1.,0.,0.],wsc_gse[0:2,i]))
	
	; The triggering sun sensor look direction perpendicular to the spin axis
	; is defined by the cross product of the spin axis direction and nTsg
	Tsg=dblarr(3,n5mtimes)
	for i=0L,n5mtimes-1L do $
		Tsg[0:2,i]=crossp(wsc_gse[0:2,i],nTsg[0:2,i])/norm(crossp(wsc_gse[0:2,i],nTsg[0:2,i]))
	if keyword_set(debug) then $
		print,'Tsg (5 minute):',systime(1)-tstart,' sec'


	; bump the low res cadence up to 0.5s
	n05stimes=long(duration*2L)+1L
	ets_05s=et0+dindgen(n05stimes)/2. ; 1 second

	
	tstart=systime(1)
	; interpolate Tsg to the higher time cadence	
	Tsghr=transpose([[interpol(Tsg[0,*],ets_5m,ets_05s)],$
		[interpol(Tsg[1,*],ets_5m,ets_05s)],$
		[interpol(Tsg[2,*],ets_5m,ets_05s)]])
	if keyword_set(debug) then $
		print,'Tsg interpol() to high res times:',systime(1)-tstart,' sec'
	
	tstart=systime(1)
	message,'Generating despinning matrix, please be patient...',/continue
	cspice_pxform,'GSE',ssh_id,ets_05s,gse2ssh
	if keyword_set(debug) then $
		print,'cspice_pxform:',n05stimes,' points in ',systime(1)-tstart,' sec'

	Tsg_ssh=dblarr(3,n05stimes)
	for i=0L,n05stimes-1L do Tsg_ssh[0:2,i]=gse2ssh[0:2,0:2,i]##Tsghr[0:2,i]

	Tsg_ssh_hr=transpose([[interpol(Tsg_ssh[0,*],ets_05s,ets)],$
						[interpol(Tsg_ssh[1,*],ets_05s,ets)],$
						[interpol(Tsg_ssh[2,*],ets_05s,ets)]])
	
	
	sphase=dblarr(ntimes)
	for i=0L,ntimes-1L do sphase[i]=atan(tsg_ssh_hr[1,i],tsg_ssh_hr[0,i])/!dtor
	
	nlow=where(sphase lt 0.d)
	sphase[nlow]=sphase[nlow]+360.d
	
	if keyword_set(debug) then begin
		store_data,'rbsp'+probe+'_Tsg_debug',$
			data={x:times,y:transpose(Tsg_ssh_hr)}
		store_data,'rbsp'+probe+'_spice_sphase_debug',$
			data={x:times,y:sphase}
	endif
	
	xm=cos((sphase+delta)*!dtor)
	ym=sin((sphase+delta)*!dtor)

	; LH rotation to SSH triggering
	xdsc=du*xm+dv*ym
	ydsc=-du*ym+dv*xm
	zdsc=dw

	dsc=[[xdsc],[ydsc],[zdsc]]
	str_element,l,'labels',['X_dsc','Y_dsc','Z_dsc'],/add_replace
	if is_struct(dl.data_att) then $
		str_element,dl.data_att,'coord_sys','dsc',/add_replace

	if ~keyword_set(suffix) then suffix='dsc'
	store_data,tn+'_'+suffix,data={x:times,y:dsc},limits=l,dlimits=dl
	
	if ~keyword_set(no_spice_load) then begin
		rbsp_load_spice_predict,/unload
		rbsp_load_spice_kernels,/unload
	endif
end