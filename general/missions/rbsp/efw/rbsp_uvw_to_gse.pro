;+
; NAME:	RBSP_UVW_TO_GSE
;
; SYNTAX:
;   rbsp_uvw_to_gse,'a','rbspa_efw_esvy'
;   rbsp_uvw_to_gse,'a','rbspa_efw_esvy',/no_spice_load
;
; PURPOSE:	Transforms from spinning UVW (RBSP SCIENCE) frame to GSE.
;
; INPUT:
;	probe	- either 'a' or 'b'
;	tvar	- TPLOT variable containing 3-component UVW data
;			(either string or integer tplot variable id) 
;
; KEYWORDS:
;	suffix=suffix - optional suffix for rotated tplot variable names
;	/no_spice_load - skip loading/unloading of SPICE kernels
;		NOTE: This assumes spice kernels have been manually loaded using:
;			rbsp_load_spice_predict ; (optional)
;			rbsp_load_spice_kernels ; (required)
;	/remove_offset - remove slowly varying offsets in spin plane
;	/debug - prints debugging info
;
; NOTES:
;
; HISTORY:
;	1. Created Jan 2013 - Kris Kersten, kris.kersten@gmail.com
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2019-08-14 14:21:17 -0700 (Wed, 14 Aug 2019) $
;   $LastChangedRevision: 27604 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_uvw_to_gse.pro $
;
;-


pro rbsp_uvw_to_gse,probe,tvar,suffix=suffix,$
	no_spice_load=no_spice_load,remove_offset=remove_offset,$
	debug=debug
	
	ttstart=systime(1)
	
	rbsp_efw_init
	
	probe=string(probe)
	if probe ne 'a' and probe ne 'b' then begin
		message,'Invalid probe: "'+probe+'". Returning...',/continue
		return
	endif
	
	nvar=size(tvar,/n_elements)
	
	if nvar eq 1 then begin

		tn=tnames(tvar)
		get_data,tvar,data=d,limits=l,dlimits=dl,index=tindex
		if tindex eq 0 then begin
			message,'TPLOT variable not found.  Returning...',/continue
			return
		endif
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

	; get 1s ets for the despinning matrix
	duration=times[ntimes-1]-times[0] ; seconds
	n1stimes=long(duration)+1L
	ets1s=et0+dindgen(n1stimes) ; 1 second
	utimes1s=times[0]+dindgen(n1stimes) ; 1 second

	; get the 1s UVW -> GSE state transformation matrix
	dmessage='Running CSPICE_SXFORM, npoints: '+string(n1stimes,format='(I0)')+'...'
	if keyword_set(debug) then message,dmessage,/continue
	tstart=systime(1)

	cspice_sxform,sci_id,'GSE',ets1s,suvw2gse1s

	dmessage='CSPICE_SXFORM: ' $
		+string(systime(1)-tstart,format='(F0.1)')+' sec.'
	if keyword_set(debug) then message,dmessage,/continue

	; get rotation matrix and angular velocity vector
	dmessage='Running CSPICE_XF2RAV, npoints: '+string(n1stimes,format='(I0)')+'...'
	if keyword_set(debug) then message,dmessage,/continue
	tstart=systime(1)
	uvw2gse1s=dblarr(3,3,n1stimes)
	avv=dblarr(3,n1stimes)
	for i=0L,n1stimes-1L do begin
		cspice_xf2rav, suvw2gse1s[0:5,0:5,i], $
			uvw2gse1s_temp, avv_temp
		uvw2gse1s[0:2,0:2,i]=uvw2gse1s_temp
		avv[0:2,i]=avv_temp
	endfor
	dmessage='CSPICE_XF2RAV: ' $
		+string(systime(1)-tstart,format='(F0.1)')+' sec.'
	if keyword_set(debug) then message,dmessage,/continue

	; get the angular velocity, mean spin period
	av=dblarr(n1stimes)
	for i=0L,n1stimes-1L do av=norm(avv[0:2,i])
	meansp=2.*!dpi/mean(av)

	; interpolate the uvw2gse matrix to sample times
	dmessage='Running INTERPOL(uvw2gse1s)...'
	if keyword_set(debug) then message,dmessage,/continue
	uvw2gse=dblarr(3,3,ntimes)	
	tstart=systime(1)
	for i=0,2 do $
		for j=0,2 do $
			uvw2gse[i,j,*]= $
				interpol(reform(uvw2gse1s[i,j,*]),utimes1s,times,/quadratic)
	dmessage='INTERPOL(uvw2gse1s): ' $
		+string(systime(1)-tstart,format='(F0.1)')+' sec.'
	if keyword_set(debug) then message,dmessage,/continue


	; detrend spinning quantities? 
	if keyword_set(remove_offset) then begin
		nspin=meansp/median_dt
		duoffset=smooth(du,nspin)
		dvoffset=smooth(dv,nspin)
		du=du-duoffset
		dv=dv-dvoffset
	endif
	
	dmessage='Running UVW -> GSE...'
	if keyword_set(debug) then message,dmessage,/continue
	tstart=systime(1)	
	dgse=dblarr(3,ntimes)
	for i=0L,ntimes-1L do $
		dgse[0:2,i]=[du[i], dv[i], dw[i]] # uvw2gse[*,*,i]
	dmessage='UVW -> GSE: ' $
		+string(systime(1)-tstart,format='(F0.1)')+' sec.'
	if keyword_set(debug) then message,dmessage,/continue
	
	
	str_element,l,'labels',['X_GSE','Y_GSE','Z_GSE'],/add_replace

	if is_struct(dl) then begin
		if tag_exist(dl,'data_att') then $
			str_element,dl.data_att,'coord_sys','gse',/add_replace else $
			str_element,dl,'data_att',{coord_sys:'gse'},/add_replace
	endif

	if ~keyword_set(suffix) then suffix='gse'
	store_data,tn+'_'+suffix,data={x:times,y:transpose(dgse)},limits=l,dlimits=dl
	
	if ~keyword_set(no_spice_load) then begin
		rbsp_load_spice_predict,/unload
		rbsp_load_spice_kernels,/unload
	endif

	dmessage='Execution time: ' $
		+string(systime(1)-ttstart,format='(F0.1)')+' sec.'
	if keyword_set(debug) then message,dmessage,/continue

end