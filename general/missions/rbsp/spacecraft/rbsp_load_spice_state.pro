;+
; PRO RBSP_LOAD_SPICE_STATE
;
; SYNTAX:
;	rbsp_load_spice_state,probe='a',coord='GSE'
;	rbsp_load_spice_state,probe='a',coord='GSE',dt=3600. ; hourly
;	rbsp_load_spice_state,probe='a',coord='GSE',times=time_array
;	rbsp_load_spice_state,probe='a',coord='GSE',/no_spice_load ; skip spice load
;
; PURPOSE:	Loads SPICE position and velocity in one of the RBSP SPICE supported
;			coordinate systems:
;				GEI, GEI_TOD, GEI_MOD, MEAN_ECLIP, GEO, GSE, MAG, GSM, or SM
;
; KEYWORDS:
;	probe = 'a' or 'b'  NOTE: single spacecraft only, does not accept ['a b']
;	coord = coordinate system.  Valid coordinate systems are defined in the
;		rbsp general frame kernel (rbsp_generalxxx.tf) and include:
;			GEI, GEI_TOD, GEI_MOD, MEAN_ECLIP, GEO, GSE, MAG, GSM, or SM
;	dt = time step (s).  Generate state every dt seconds for the current TPLOT
;		timespan.  Default dt is 60s.
;	times = times.  Optionally define an array of times at which to return
;		SPICE state (dt keyword is ignored).
;	/no_spice_load - skip loading/unloading of spice kernels
;	abcorr = aberration correction.  See SPICE documentation for description.
;		Default is NONE.
;	obs = SPICE observer. Default is EARTH.
;
; HISTORY:
;	1. Created Oct 2012 - Kris Kersten, kris.kersten@gmail.com
;
; VERSION:
;   $LastChangedBy: kersten $
;   $LastChangedDate: 2012-11-08 12:03:41 -0800 (Thu, 08 Nov 2012) $
;   $LastChangedRevision: 11210 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/spacecraft/rbsp_load_spice_state.pro $
;
;-

pro rbsp_load_spice_state,probe=probe,coord=coord,dt=dt, $
	times=times,no_spice_load=no_spice_load,abcorr=abcorr,obs=obs

	if ~icy_test() then return
	
	if ~keyword_set(probe) then begin
		message,'Probe not set. Returning.',/continue
		return
	endif else begin
		probe=strlowcase(probe)
		if probe ne 'a' and probe ne 'b' then begin
			message,"Invalid probe. Returning.",/continue
			return
		endif
	endelse
	
	; valid RBSP SPICE coordinate systems (as defined in rbsp_general010.tf
	; frame kernel)
	vcoords=['GEI', $
			'GEI_TOD', $
			'GEI_MOD', $
			'MEAN_ECLIP', $
			'GEO', $
			'GSE', $
			'MAG', $
			'GSM', $
			'SM' ]

	if ~keyword_set(coord) then begin
		message,'Coordinate system not set. Returning.',/continue
		message,'Valid coordinate systems: '+ $
				string(vcoords,format='(9(A, :, ", "))'),/continue
		return
	endif else begin
		coord=strupcase(coord)
		xx=where(vcoords eq coord,cfound)
		if cfound eq 0 then begin
			message,'Unknown coordinate system: '+coord+'. Returning.',/continue
			message,'Valid coordinate systems: '+ $
					string(vcoords,format='(9(A, :, ", "))'),/continue
			return
		endif
	endelse
	
	; set default SPICE options
	if ~keyword_set(abcorr) then abcorr='NONE'
	if ~keyword_set(obs) then obs='EARTH'
	
	
	if ~keyword_set(times) then begin

		if ~keyword_set(dt) then dt=60.
		tr=timerange()
		nt=long((tr[1]-tr[0])/dt)+1
		times=tr[0]+(dindgen(nt))*dt
	
	endif else begin
	
		times=time_double(times)
	
	endelse


	if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels

	ts=time_string(times)
	strput,ts,'T',10
	cspice_str2et,ts,et
	
	scid='RADIATION BELT STORM PROBE '+strupcase(probe)
	cspice_spkezr,scid,et,coord,abcorr,obs,state,ltime

	position=transpose(state[0:2,*])
	velocity=transpose(state[3:5,*])

	data_att = {coord_sys:strlowcase(coord),$
		st_type:'pos',$
		units:'km'}

	dl = {spec:0b,$
		log:0b,$
		data_att:data_att,$
		colors:[2,4,6],$
		labels:['x','y','z']+'_'+strlowcase(coord),$
		ysubtitle:'[km]'}
		
	store_data,'rbsp'+probe+'_state_pos_'+strlowcase(coord), $
		data={x:times,y:position,v:[1,2,3]},dlimits=dl

	dl.data_att.st_type='vel'
	dl.data_att.units='km/s'

	dl.labels=['vx','vy','vz']+'_'+strlowcase(coord)
	dl.ysubtitle='[km/s]'

	store_data,'rbsp'+probe+'_state_vel_'+strlowcase(coord), $
		data={x:times,y:velocity,v:[1,2,3]},dlimits=dl

	if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels,/unload

end
