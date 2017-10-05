;+
; NAME:	RBSP_UVW_TO_MGSE
;
; SYNTAX:
;   rbsp_uvw_to_mgse,'a','rbspa_efw_esvy'
;   rbsp_uvw_to_mgse,'a','rbspa_efw_esvy',/no_spice_load
;
; PURPOSE:	Transforms from spinning UVW (RBSP SCIENCE) frame to MGSE.
;
;			The MGSE coordinate system is defined:
;				Y_MGSE=-W_SC(GSE) x Z_GSE
;				Z_MGSE=W_SC(GSE) x Y_MGSE
;				X_MGSE=Y_MGSE x Z_MGSE
;			where W_SC(GSE) is the spin axis direction in GSE.
;
;			This is equivalent to the GSE coordinate system if the spin axis
;			lies along the X_GSE direction.
;
; INPUT:
;	probe	- either 'a' or 'b'
;	tvar	- TPLOT variable containing 3-component UVW data
;			(either string or integer tplot variable id) 
;
; OUTPUT: N/A
;	Rotated timeseries is saved in a new tplot var with _mgse suffix..
;
; KEYWORDS:
;	suffix=suffix - suffix for rotated tplot var name (default is _mgse)
;	/no_offset - skip offset removal in spin plane
;	/force_offset - force offset removal for slowly sampled data
;	/nointerp - use SPICE to calculate rotation matrix directly at each timestep
;				instead of default quaternion interpolation rotation matrix
;	nointerp=2 - use SPICE to calculate spin axis pointing at each timestep
;				instead of interpolating from 5m cadence pointing
;				(this may be useful during maneuvers)
;	/no_spice_load - skip loading/unloading of SPICE kernels
;		NOTE: This assumes spice kernels have been manually loaded using:
;			rbsp_load_spice_predict ; (optional)
;			rbsp_load_spice_kernels ; (required)
;	/debug - prints debugging info
;
; NOTES:
;	By default this routine uses SPICE to generate the spin axis pointing
;	direction at a 5 minute cadence, and the despinning matrix at a 1s cadence.
;	These quantities are interpolated (spin axis linearly, and despinning matrix
;	via quaternion interpolation) to the sample times of the input time series.
;	
;	If the input time series is sampled at <= 1S/s, the routine will calculate
;	the SPICE pointing and rotation directly at each time stamp rather than using
;	the interpolation described above.
;
;	The nointerp keyword is provided to bypass the interpolation and calculate the
;	spin axis pointing direction and rotation matrix at the time stamps of the input
;	time series.  Calling the routine with /nointerp or nointerp=1 will cause the
;	rotation matrix to be calculated directly.  Calling with nointerp=2 will cause
;	both the rotation matrix and the spin axis pointing direction to be calculated
;	directly.  This will be VERY time consuming for high time resolution data, but
;	may be useful for debugging or during spacecraft maneuvers.
;
;	SPIN PLANE OFFSETS:
;	By default, offsets in the spin plane quantities are removed.  This is only
;	valid for quantities sampled faster than the spin period (~12s).  The offset
;	removal is automatically skipped for quantities sampled at or below 1S/s.  This
;	can be overridden by using the /force_offset keyword.
;
; HISTORY:
;	1. Created Nov 2012 - Kris Kersten, kris.kersten@gmail.com
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2015-07-10 07:54:25 -0700 (Fri, 10 Jul 2015) $
;   $LastChangedRevision: 18072 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_uvw_to_mgse.pro $
;
;-


pro rbsp_uvw_to_mgse,probe,tvar,suffix=suffix,$
	no_spice_load=no_spice_load,no_offset=no_offset,$
	force_offset=force_offset,nointerp=nointerp,debug=debug
	
	ttstart=systime(1)
	
	rbsp_efw_init
	
	probe=string(strlowcase(probe))
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

	; decide if we're going interpolate up to the timeseries times
	; or use SPICE directly to get the rotation
	if ~keyword_set(nointerp) then nointerp=0
	if nointerp ne 0 and nointerp ne 1 and nointerp ne 2 then begin
		message,'Invalid value for keyword nointerp, returning.'
		return
	endif

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
	duration=times[ntimes-1]-times[0] ; seconds

	; set nointerp=1 to calculate rotation directly if sample rate is <= 1S/s
	if median_dt ge 1. and nointerp ne 2 then begin
		nointerp=1
		message,'Detected sample rate at or below 1S/s, calculating rotation matrix directly from timeseries times (setting keyword nointerp=1).',/continue
	endif
	
	; also turn off the default offset subtraction if data is sampled slowly (1s)
	if median_dt ge 1. then begin
		no_offset=1
		message,'WARNING: Detected sample rate at or below 1S/s, skipping spin plane offset removal!',/continue
		message,'If you really want to remove spin plane offsets, use the /force_offset keyword.',/continue
	endif
	if keyword_set(force_offset) then begin
		no_offset=0
		message,'Forcing spin plane offset removal.',/continue
	endif
	
	case nointerp of
	
		; DEFAULT: use interpolation for both SA pointing and rotation matrix
		0:begin
			message,'Using default interpolation for rotation.',/continue
			t0=time_string(times[0],prec=6)
			strput,t0,'T',10
			cspice_str2et,t0,et0
			ets=et0+dindgen(ntimes)*median_dt

			; use 5m cadence for SA pointing.  if duration is less than 5m, use 1s cadence
			if duration le 300. then cadence=1. else cadence=300.
			n5mtimes=long(duration/cadence)+1
			ets5m=et0+dindgen(n5mtimes)*cadence
			utimes5m=times[0]+dindgen(n5mtimes)*cadence

			; get the low-res UVW -> GSE matrix for spin axis pointing
			dmessage='Running CSPICE_PXFORM, npoints: '+string(n5mtimes,format='(I0)')+'...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			cspice_pxform,sci_id,'GSE',ets5m,uvw2gse5m
			dmessage='CSPICE_PXFORM: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue

			; spin axis direction in GSE
			wsc_gse5m=dblarr(3,n5mtimes)
			for i=0L,n5mtimes-1L do wsc_gse5m[0:2,i]=uvw2gse5m[0:2,0:2,i]##[0.d,0.d,1.d]

			; calculate the MGSE directions
			dmessage='Defining MGSE...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			X_MGSE5m=dblarr(3,n5mtimes)
			Y_MGSE5m=dblarr(3,n5mtimes)
			Z_MGSE5m=dblarr(3,n5mtimes)
	 
			for i=0L,n5mtimes-1L do $
				Y_MGSE5m[0:2,i]=-crossp(wsc_GSE5m[0:2,i],[0,0,1.])/norm(crossp(wsc_GSE5m[0:2,i],[0,0,1.]))
			for i=0L,n5mtimes-1L do $
				Z_MGSE5m[0:2,i]=crossp(wsc_GSE5m[0:2,i],Y_MGSE5m[0:2,i])/norm(crossp(wsc_GSE5m[0:2,i],Y_MGSE5m[0:2,i]))
			for i=0L,n5mtimes-1L do $
				X_MGSE5m[0:2,i]=crossp(Y_MGSE5m[0:2,i],Z_MGSE5m[0:2,i])
			dmessage='Define MGSE: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue
	

			; interpolate to sample times
			X_MGSE=dblarr(3,ntimes)
			Y_MGSE=dblarr(3,ntimes)
			Z_MGSE=dblarr(3,ntimes)

			dmessage='Running INTERPOL(MGSE)...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			for i=0,2 do begin
				X_MGSE[i,*]=interpol(reform(X_MGSE5m[i,*]),utimes5m,times)
				Y_MGSE[i,*]=interpol(reform(Y_MGSE5m[i,*]),utimes5m,times)
				Z_MGSE[i,*]=interpol(reform(Z_MGSE5m[i,*]),utimes5m,times)
			endfor
			tmessage='INTERPOL(MGSE): ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,tmessage,/continue


			; get 1s ets for the despinning matrix
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
			for i=0L,n1stimes-1L do av[i]=norm(avv[0:2,i])
			meansp=2.*!dpi/mean(av)

			; convert uvw2gse matrix to quaternions for interpolation to sample times
			dmessage='Running QSLERP()...'
			if keyword_set(debug) then message,dmessage,/continue
			quvw2gse1s=mtoq(transpose(uvw2gse1s))
			quvw2gse=qslerp(quvw2gse1s,utimes1s,times)
			if n_elements(quvw2gse) eq 1 then begin
				print,'Error in quaternion interpolation.  Returning...'
				return
			endif
			uvw2gse=transpose(qtom(quvw2gse))
			dmessage='QSLERP(): ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue

			; detrend spinning quantities
			if ~keyword_set(no_offset) then begin
				nspin=meansp/median_dt
				duoffset=smooth(du,nspin)
				dvoffset=smooth(dv,nspin)
				du=du-duoffset
				dv=dv-dvoffset
			endif
	
			dmessage='Running UVW -> MGSE...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)	
			dgse=dblarr(3,ntimes)
			for i=0L,ntimes-1L do $
				dgse[0:2,i]=uvw2gse[*,*,i] ## [[du[i]], [dv[i]], [dw[i]]]
	
	
			dx_mgse=dblarr(ntimes)
			dy_mgse=dblarr(ntimes)
			dz_mgse=dblarr(ntimes)
	
			for i=0L,ntimes-1L do $
				dx_mgse[i]=dgse[0,i]*X_MGSE[0,i]+dgse[1,i]*X_MGSE[1,i]+dgse[2,i]*X_MGSE[2,i]
			for i=0L,ntimes-1L do $
				dy_mgse[i]=dgse[0,i]*Y_MGSE[0,i]+dgse[1,i]*Y_MGSE[1,i]+dgse[2,i]*Y_MGSE[2,i]
			for i=0L,ntimes-1L do $
				dz_mgse[i]=dgse[0,i]*Z_MGSE[0,i]+dgse[1,i]*Z_MGSE[1,i]+dgse[2,i]*Z_MGSE[2,i]


			dmessage='UVW -> MGSE: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue
		end
		
		; use interpolation for both SA pointing, calculate rotation matrix directly from timeseries times
		1:begin
			message,'Using interpolation for SA pointing, calculating SPICE rotation directly.',/continue
			tstring=time_string(times,prec=6)
			strput,tstring,'T',10
			ets=dblarr(ntimes)
			for tcount=0L,ntimes-1 do begin
				cspice_str2et,tstring[tcount],et_temp
				ets[tcount]=et_temp
			endfor

			; use 5m cadence for SA pointing.  if duration is less than 5m, use 1s cadence
			if duration le 300. then cadence=1. else cadence=300.
			n5mtimes=long(duration/cadence)+1
			ets5m=ets[0]+dindgen(n5mtimes)*cadence
			utimes5m=times[0]+dindgen(n5mtimes)*cadence

			; get the low-res UVW -> GSE matrix for spin axis pointing
			dmessage='Running CSPICE_PXFORM, npoints: '+string(n5mtimes,format='(I0)')+'...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			cspice_pxform,sci_id,'GSE',ets5m,uvw2gse5m
			dmessage='CSPICE_PXFORM: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue

			; spin axis direction in GSE
			wsc_gse5m=dblarr(3,n5mtimes)
			for i=0L,n5mtimes-1L do wsc_gse5m[0:2,i]=uvw2gse5m[0:2,0:2,i]##[0.d,0.d,1.d]

			; calculate the MGSE directions
			dmessage='Defining MGSE...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			X_MGSE5m=dblarr(3,n5mtimes)
			Y_MGSE5m=dblarr(3,n5mtimes)
			Z_MGSE5m=dblarr(3,n5mtimes)
	 
			for i=0L,n5mtimes-1L do $
				Y_MGSE5m[0:2,i]=-crossp(wsc_GSE5m[0:2,i],[0,0,1.])/norm(crossp(wsc_GSE5m[0:2,i],[0,0,1.]))
			for i=0L,n5mtimes-1L do $
				Z_MGSE5m[0:2,i]=crossp(wsc_GSE5m[0:2,i],Y_MGSE5m[0:2,i])/norm(crossp(wsc_GSE5m[0:2,i],Y_MGSE5m[0:2,i]))
			for i=0L,n5mtimes-1L do $
				X_MGSE5m[0:2,i]=crossp(Y_MGSE5m[0:2,i],Z_MGSE5m[0:2,i])
			dmessage='Define MGSE: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue
	

			; interpolate to sample times
			X_MGSE=dblarr(3,ntimes)
			Y_MGSE=dblarr(3,ntimes)
			Z_MGSE=dblarr(3,ntimes)

			dmessage='Running INTERPOL(MGSE)...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			for i=0,2 do begin
				X_MGSE[i,*]=interpol(reform(X_MGSE5m[i,*]),utimes5m,times)
				Y_MGSE[i,*]=interpol(reform(Y_MGSE5m[i,*]),utimes5m,times)
				Z_MGSE[i,*]=interpol(reform(Z_MGSE5m[i,*]),utimes5m,times)
			endfor
			tmessage='INTERPOL(MGSE): ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,tmessage,/continue


			; get the UVW -> GSE state transformation matrix
			dmessage='Running CSPICE_SXFORM, npoints: '+string(ntimes,format='(I0)')+'...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			cspice_sxform,sci_id,'GSE',ets,suvw2gse
			dmessage='CSPICE_SXFORM: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue


			; get rotation matrix and angular velocity vector
			dmessage='Running CSPICE_XF2RAV, npoints: '+string(ntimes,format='(I0)')+'...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			uvw2gse=dblarr(3,3,ntimes)
			avv=dblarr(3,ntimes)
			for i=0L,ntimes-1L do begin
				cspice_xf2rav, suvw2gse[0:5,0:5,i], $
					uvw2gse_temp, avv_temp
				uvw2gse[0:2,0:2,i]=uvw2gse_temp
				avv[0:2,i]=avv_temp
			endfor
			dmessage='CSPICE_XF2RAV: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue

			; get the angular velocity, mean spin period
			av=dblarr(ntimes)
			for i=0L,ntimes-1L do av[i]=norm(avv[0:2,i])
			meansp=2.*!dpi/mean(av)

			; detrend spinning quantities
			if ~keyword_set(no_offset) then begin
				nspin=meansp/median_dt
				duoffset=smooth(du,nspin)
				dvoffset=smooth(dv,nspin)
				du=du-duoffset
				dv=dv-dvoffset
			endif
	
			dmessage='Running UVW -> MGSE...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)	
			dgse=dblarr(3,ntimes)
			for i=0L,ntimes-1L do $
				dgse[0:2,i]=uvw2gse[*,*,i] ## [[du[i]], [dv[i]], [dw[i]]]
	
	
			dx_mgse=dblarr(ntimes)
			dy_mgse=dblarr(ntimes)
			dz_mgse=dblarr(ntimes)
	
			for i=0L,ntimes-1L do $
				dx_mgse[i]=dgse[0,i]*X_MGSE[0,i]+dgse[1,i]*X_MGSE[1,i]+dgse[2,i]*X_MGSE[2,i]
			for i=0L,ntimes-1L do $
				dy_mgse[i]=dgse[0,i]*Y_MGSE[0,i]+dgse[1,i]*Y_MGSE[1,i]+dgse[2,i]*Y_MGSE[2,i]
			for i=0L,ntimes-1L do $
				dz_mgse[i]=dgse[0,i]*Z_MGSE[0,i]+dgse[1,i]*Z_MGSE[1,i]+dgse[2,i]*Z_MGSE[2,i]


			dmessage='UVW -> MGSE: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue

		end
		
		; calculate both SA pointing and rotation matrix directly from timeseries times
		2:begin
			message,'Calculating SA pointing and SPICE rotation directly. Please be patient.',/continue
			tstring=time_string(times,prec=6)
			strput,tstring,'T',10
			ets=dblarr(ntimes)
			for tcount=0,ntimes-1 do begin
				cspice_str2et,tstring[tcount],et_temp
				ets[tcount]=et_temp
			endfor

			; get spin axis pointing
			dmessage='Running CSPICE_PXFORM, npoints: '+string(ntimes,format='(I0)')+'...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			cspice_pxform,sci_id,'GSE',ets,uvw2gse
			dmessage='CSPICE_PXFORM: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue

			; spin axis direction in GSE
			wsc_gse=dblarr(3,ntimes)
			for i=0L,ntimes-1L do wsc_gse[0:2,i]=uvw2gse[0:2,0:2,i]##[0.d,0.d,1.d]

			; calculate the MGSE directions
			dmessage='Defining MGSE...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			X_MGSE=dblarr(3,ntimes)
			Y_MGSE=dblarr(3,ntimes)
			Z_MGSE=dblarr(3,ntimes)
	 
			for i=0L,ntimes-1L do $
				Y_MGSE[0:2,i]=-crossp(wsc_GSE[0:2,i],[0,0,1.])/norm(crossp(wsc_GSE[0:2,i],[0,0,1.]))
			for i=0L,ntimes-1L do $
				Z_MGSE[0:2,i]=crossp(wsc_GSE[0:2,i],Y_MGSE[0:2,i])/norm(crossp(wsc_GSE[0:2,i],Y_MGSE[0:2,i]))
			for i=0L,ntimes-1L do $
				X_MGSE[0:2,i]=crossp(Y_MGSE[0:2,i],Z_MGSE[0:2,i])
			dmessage='Define MGSE: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue


			; get the UVW -> GSE state transformation matrix
			dmessage='Running CSPICE_SXFORM, npoints: '+string(ntimes,format='(I0)')+'...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			cspice_sxform,sci_id,'GSE',ets,suvw2gse
			dmessage='CSPICE_SXFORM: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue


			; get rotation matrix and angular velocity vector
			dmessage='Running CSPICE_XF2RAV, npoints: '+string(ntimes,format='(I0)')+'...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)
			uvw2gse=dblarr(3,3,ntimes)
			avv=dblarr(3,ntimes)
			for i=0L,ntimes-1L do begin
				cspice_xf2rav, suvw2gse[0:5,0:5,i], $
					uvw2gse_temp, avv_temp
				uvw2gse[0:2,0:2,i]=uvw2gse_temp
				avv[0:2,i]=avv_temp
			endfor
			dmessage='CSPICE_XF2RAV: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue

			; get the angular velocity, mean spin period
			av=dblarr(ntimes)
			for i=0L,ntimes-1L do av[i]=norm(avv[0:2,i])
			meansp=2.*!dpi/mean(av)

			; detrend spinning quantities
			if ~keyword_set(no_offset) then begin
				nspin=meansp/median_dt
				duoffset=smooth(du,nspin)
				dvoffset=smooth(dv,nspin)
				du=du-duoffset
				dv=dv-dvoffset
			endif
	
			dmessage='Running UVW -> MGSE...'
			if keyword_set(debug) then message,dmessage,/continue
			tstart=systime(1)	
			dgse=dblarr(3,ntimes)
			for i=0L,ntimes-1L do $
				dgse[0:2,i]=uvw2gse[*,*,i] ## [[du[i]], [dv[i]], [dw[i]]]
	
	
			dx_mgse=dblarr(ntimes)
			dy_mgse=dblarr(ntimes)
			dz_mgse=dblarr(ntimes)
	
			for i=0L,ntimes-1L do $
				dx_mgse[i]=dgse[0,i]*X_MGSE[0,i]+dgse[1,i]*X_MGSE[1,i]+dgse[2,i]*X_MGSE[2,i]
			for i=0L,ntimes-1L do $
				dy_mgse[i]=dgse[0,i]*Y_MGSE[0,i]+dgse[1,i]*Y_MGSE[1,i]+dgse[2,i]*Y_MGSE[2,i]
			for i=0L,ntimes-1L do $
				dz_mgse[i]=dgse[0,i]*Z_MGSE[0,i]+dgse[1,i]*Z_MGSE[1,i]+dgse[2,i]*Z_MGSE[2,i]


			dmessage='UVW -> MGSE: ' $
				+string(systime(1)-tstart,format='(F0.1)')+' sec.'
			if keyword_set(debug) then message,dmessage,/continue
		end
		
	endcase	
	
	
	mgse=[[dx_mgse],[dy_mgse],[dz_mgse]]
	str_element,l,'labels',['X_MGSE','Y_MGSE','Z_MGSE'],/add_replace


	if is_struct(dl) then begin
		if tag_exist(dl,'data_att') then $
			str_element,dl.data_att,'coord_sys','mgse',/add_replace else $
			str_element,dl,'data_att',{coord_sys:'mgse'},/add_replace
	endif

	if ~keyword_set(suffix) then suffix='mgse'
	store_data,tn+'_'+suffix,data={x:times,y:mgse},limits=l,dlimits=dl
	
	if ~keyword_set(no_spice_load) then begin
		rbsp_load_spice_predict,/unload
		rbsp_load_spice_kernels,/unload
	endif

	dmessage='Execution time: ' $
		+string(systime(1)-ttstart,format='(F0.1)')+' sec.'
	if keyword_set(debug) then message,dmessage,/continue

end
