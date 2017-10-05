;+
; NAME:	RBSP_LOAD_SA_POINTING
;
; SYNTAX:
;   rbsp_load_sa_pointing,probe='a',coord='GSM'
;   rbsp_load_sa_pointing,/no_spice_load
;
; PURPOSE:	Loads the spin axis pointing unit vector in GSE (default) or other
;			SPICE supported coordinate system.  Default cadence is 1 minute.
;
;
; INPUT:
;
; KEYWORDS:
;	probe	- either 'a', 'b', 'a b', or ['a','b']
;	coord=spice_coord_sys - default is GSE, but can be any of the coordinate
;			systems (frame name) supported by the RBSP general frame kernels:
;           Frame Name                Relative To              Type     NAIF ID
;           =======================   ===================      =======  =======
;           GEI                       J2000                    FIXED    -362900
;           GEI_TOD                   J2000                    DYNAMIC  -362901
;           GEI_MOD                   J2000                    DYNAMIC  -362902
;           MEAN_ECLIP                J2000                    DYNAMIC  -362903
;           GEO                       IAU_EARTH                FIXED    -362920
;           GSE                       J2000                    DYNAMIC  -362930
;           MAG                       J2000                    DYNAMIC  -362940
;           GSM                       J2000                    DYNAMIC  -362945
;           SM                        J2000                    DYNAMIC  -362950
;	times=times - array of times at which to return pointing direction
;		NOTE: this can be in any format accepted by time_double(), time_string()
;	/no_spice_load - skip loading/unloading of SPICE kernels
;		NOTE: This assumes spice kernels have been manually loaded using:
;			rbsp_load_spice_predict ; (optional)
;			rbsp_load_spice_kernels ; (required)
;	/debug - prints debugging info
;
; NOTES:
;
; HISTORY:
;	1. Created Oct 2013 - Kris Kersten, kris.kersten@gmail.com
;
; VERSION:
;   $LastChangedBy: kersten $
;   $LastChangedDate: 2013-10-09 15:54:28 -0700 (Wed, 09 Oct 2013) $
;   $LastChangedRevision: 13295 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/spacecraft/rbsp_load_sa_pointing.pro $
;
;-

pro rbsp_load_sa_pointing,probe=probe,coord=coord,times=times, $
	no_spice_load=no_spice_load,debug=debug

	if keyword_set(coord) then coord=strupcase(coord) else coord='GSE'
	coords=['GEI','GEI_TOD','GEI_MOD','MEAN_ECLIP','GEO','GSE','MAG','GSM','SM']
	vcoord=where(coord eq coords)
	if vcoord[0] eq -1 then begin
		message,'Invalid coordinate system.  Returning...',/continue
		return
	endif
	
	if ~keyword_set(times) then begin
		tr=timerange()
		ntimes=long((tr[1]-tr[0])/60)+1
		times=dindgen(ntimes)*60+tr[0]
	endif else begin
		ntimes=n_elements(times)
		times=time_double(times) ; make sure we have the times in unix format
	endelse
	
	if ~keyword_set(no_spice_load) then begin
		rbsp_load_spice_predict
		rbsp_load_spice_kernels
	endif

	vprobes = ['a','b']
	if keyword_set(probe) then p_var = probe
	if not keyword_set(p_var) then p_var='*'
	p_var = strfilter(vprobes, p_var ,delimiter=' ',/string)

	for s=0,n_elements(p_var)-1 do begin

		; SPICE body string and integer IDs for RBSPA, RBSPB
		str_id='RADIATION BELT STORM PROBE '+strupcase(p_var[s])
		sc_id='RBSP'+strupcase(p_var[s])+'_SPACECRAFT'
		sci_id='RBSP'+strupcase(p_var[s])+'_SCIENCE'
		
		case p_var[s] of
			'a':n_id=-362
			'b':n_id=-363
		endcase
		nsc_id=n_id*1000L ; integer SC frame id is -36?000
		nsci_id=nsc_id-50L ; integer SCIENCE frame id is -36?050

	
		; get SPICE ephemeris time
		dts=times[1:ntimes-1]-times[0:ntimes-2]
		median_dt=median(dts)
	
		; see if we have an irregular time cadence
		tjumps=where(dts ne median_dt)
	
		; if not, get ets the easy (quick) way
		if tjumps[0] eq -1 then begin
			t0=time_string(times[0],prec=6)
			strput,t0,'T',10
			cspice_str2et,t0,et0
			ets=et0+dindgen(ntimes)*median_dt
		endif else begin
			ets=dblarr(ntimes)
			tstr=time_string(times,prec=6)
			for tcount=0L,ntimes-1L do begin
				strput,tstr[ncount],'T',10
				cspice_str2et,tstr[tcount],et0
				ets[tcount]=et0
			endfor
		endelse
	

		; get the low-res UVW -> GSE (or other coord) matrix for spin axis pointing
		dmessage='Running CSPICE_PXFORM, npoints: '+string(ntimes,format='(I0)')+'...'
		if keyword_set(debug) then message,dmessage,/continue
		tstart=systime(1)
		cspice_pxform,sci_id,coord,ets,pxform
		dmessage='CSPICE_PXFORM: ' $
			+string(systime(1)-tstart,format='(F0.1)')+' sec.'
		if keyword_set(debug) then message,dmessage,/continue

		; spin axis direction in GSE
		wsc=dblarr(3,ntimes)
		for i=0L,ntimes-1L do wsc[0:2,i]=pxform[0:2,0:2,i]##[0.d,0.d,1.d]
		
		str_element,l,'labels',['X_','Y_','Z_']+coord,/add_replace
		str_element,dl,'data_att',{coord_sys:coord},/add_replace
		tname='rbsp'+p_var[s]+'_sa_pointing'		
		store_data,tname,data={x:times,y:transpose(wsc)},limits=l,dlimits=dl
		options,tname,labflag,-1
	endfor
	
end