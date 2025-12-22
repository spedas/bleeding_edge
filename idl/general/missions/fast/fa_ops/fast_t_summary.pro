;+
;PROCEDURE:	fast_t_summary.pro
;INPUT:	none
;
;PURPOSE:
;	Generates ps, gif, cdf summary plots of FAST teams data.
;
;	Plot 1: Hydrogen Differential Energy Flux vs Energy, 0-360    deg pitch angle
;	Plot 2: Oxygen   Differential Energy Flux vs Energy, 0-360  deg pitch angle
;	Plot 3: Hydrogen Differential Energy Flux vs Pitch Angle, < 1 keV
;	Plot 4: Hydrogen Differential Energy Flux vs Pitch Angle, > 1 keV
;	Plot 5: Oxygen   Differential Energy Flux vs Pitch Angle, < 1 keV
;	Plot 6: Oxygen   Differential Energy Flux vs Pitch Angle, > 1 keV
;	Plot 7: MassSpectrum Counts Rate vs Mass, 1eV - 12keV, 4*Pi angles
;
; KEYWORDS
;	BW	Set bw=1 to get black/white postscript
;	k0	keyword passed to gen_fa_k0_tms_gifps.pro
;
;CREATED BY:	J.McFadden		96-8-15
;VERSION:	3.0
;LAST MODIFICATION:        00-06-05
;MOD HISTORY:
;		E.Lund     00-06-05	use all pixels, not just equator
;					pixels, in energy spectrograms
;		E.Lund     97-06-09	fixed crash on data end mismatch
;		E.Lund     97-06-04	added He+ to cdf's
;		J.Loran    97-03-01	re-removed asum, esum keywords that
;					got put back in accidentally
;		L.Tang     96-11-19	removed asum, esum keywords in
;					routine get_tms_hm_spec
;		J.McFadden 96-08-30	added BW keyword, error print statements
;-
pro fast_t_summary,BW=bw,k0=k0

; If no data exists, return to main

	t=0
	dat = get_fa_tsp_sp(t,/st)
	if dat.valid eq 0 then begin
		print,' ERROR: No FAST teams survey data -- get_fa_tsp(t,/st) returned invalid data'
		return
	endif

; Collect data into tplot structures

; Hydrogen and Oxygen differential energy flux - energy spectrograms

	get_en_spec,"fa_tsp_sp",units='eflux',name='H+',gap_time=25
	options,'H+','spec',1
	zlim,'H+',1e2,1e7,1
	ylim,'H+',1,10000,1
	options,'H+','ytitle','H+ 0!Uo!N-360!Uo!N!C!C Energy (eV)'
	options,'H+','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'H+','x_no_interp',1
	options,'H+','y_no_interp',1

	get_en_spec,"fa_tso_sp",units='eflux',name='O+',gap_time=25
	options,'O+','spec',1
	zlim,'O+',1e2,1e7,1
	ylim,'O+',1,10000,1
	options,'O+','ytitle','O+ 0!Uo!N-360!Uo!N!C!C Energy (eV)'
	options,'O+','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'O+','x_no_interp',1
	options,'O+','y_no_interp',1

; Helium differential energy flux - energy spectrogram ***EJL

        get_en_spec,"fa_tsh",units='eflux',name='He+',gap_time=50
        options,'He+','spec',1
        zlim,'He+',1e2,1e7,1
        ylim,'He+',1,10000,1
        options,'He+','ytitle','He+ 0!Uo!N-360!Uo!N!C!C Energy (eV)'
        options,'He+','ztitle','eV/cm!U2!N-s-sr-eV'
        options,'He+','x_no_interp',1
        options,'He+','y_no_interp',1

; Hydrogen differential energy flux - angle spectrograms

	get_pa_spec,"fa_tsp_eq_sp",units='eflux',name='H+_low',energy=[10,1000], $
		gap_time=25,/shift90
	options,'H+_low','spec',1
	zlim,'H+_low',1e2,1e7,1
	ylim,'H+_low',-100,280,0
	options,'H+_low','ytitle','H+ .01-1keV !C!CPitch Angle'
	options,'H+_low','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'H+_low','x_no_interp',1
	options,'H+_low','y_no_interp',1

	get_pa_spec,"fa_tsp_eq_sp",units='eflux',name='H+_high',energy=[1000,15000], $
		gap_time=25,/shift90
	options,'H+_high','spec',1
	zlim,'H+_high',1e2,1e7,1
	ylim,'H+_high',-100,280,0
	options,'H+_high','ytitle','H+ >1keV !C!CPitch Angle'
	options,'H+_high','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'H+_high','x_no_interp',1
	options,'H+_high','y_no_interp',1

; Helium differential energy flux - angle spectrograms ***EJL

	get_pa_spec,"fa_tsh_eq",units='eflux',name='He+_low',energy=[10,1000], $
                gap_time=45,/shift90
        options,'He+_low','spec',1
        zlim,'He+_low',1e2,1e7,1
        ylim,'He+_low',-100,280,0
        options,'He+_low','ytitle','He+ .01-1keV !C!CPitch Angle'
        options,'He+_low','ztitle','eV/cm!U2!N-s-sr-eV'
        options,'He+_low','x_no_interp',1
        options,'He+_low','y_no_interp',1

	get_pa_spec,"fa_tsh_eq",units='eflux',name='He+_high',energy=[1000,15000], $
                gap_time=45,/shift90
        options,'He+_high','spec',1
        zlim,'He+_high',1e2,1e7,1
        ylim,'He+_high',-100,280,0
        options,'He+_high','ytitle','He+ >1keV !C!CPitch Angle'
        options,'He+_high','ztitle','eV/cm!U2!N-s-sr-eV'
        options,'He+_high','x_no_interp',1
        options,'He+_high','y_no_interp',1

; Oxygen differential energy flux - angle spectrograms

	get_pa_spec,"fa_tso_eq_sp",units='eflux',name='O+_low',energy=[10,1000], $
		gap_time=25,/shift90
	options,'O+_low','spec',1
	zlim,'O+_low',1e2,1e7,1
	ylim,'O+_low',-100,280,0
	options,'O+_low','ytitle','O+ .01-1keV !C!CPitch Angle'
	options,'O+_low','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'O+_low','x_no_interp',1
	options,'O+_low','y_no_interp',1

	get_pa_spec,"fa_tso_eq_sp",units='eflux',name='O+_high',energy=[1000,15000], $
		gap_time=25,/shift90
	options,'O+_high','spec',1
	zlim,'O+_high',1e2,1e7,1
	ylim,'O+_high',-100,280,0
	options,'O+_high','ytitle','O+ >1keV !C!CPitch Angle'
	options,'O+_high','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'O+_high','x_no_interp',1
	options,'O+_high','y_no_interp',1



	get_tms_hm_spec,"fa_th_3d",units='RATE',name='hm', $
		energy=[1, 12000], arange = [0, 15], gap_time = 120
	options,'hm','spec',1
	zlim,'hm',1e-2,1e5,1
;	ylim,'hm',0,75,0
	ylim,'hm',.5,65.,1
	options,'hm','ztitle', 'counts/sec'
	options,'hm','ytitle', 'mass (mass unit)'
	options,'hm','x_no_interp',1
	options,'hm','y_no_interp',1


; Get the orbit data

	get_data,'H+',data=tmp
	orbit_file=fa_almanac_dir()+'/orbit/predicted'
	get_fa_orbit,tmp.x,/time_array,orbit_file=orbit_file,/all
	get_data,'ORBIT',data=tmp
	orbit=tmp.y(0)
	orbit_num=strcompress(string(tmp.y(0)),/remove_all)

; Save the data to a cdf file
; At this point I assume that dat.x (time) is the same for both H+ and O+
; I also assume that the number of energies/angles is the same for H+ and O+
; He+ data must be duplicated where necessary to match H+/O+ times

	get_data,'H+',data=tp1
	get_data,'He+',data=heold
	get_data,'O+',data=tp2
	get_data,'H+_low',data=tp3
	get_data,'H+_high',data=tp4
	get_data,'He+_low',data=helowold
	get_data,'He+_high',data=hehighold
	get_data,'O+_low',data=tp5
	get_data,'O+_high',data=tp6
	get_data,'hm',data=tp7

	; Convert He+ data to match H+/O+ times ***EJL
	; H+/O+ times are assumed to be monotonic
	datdims = [dimen1(tp1.x), dimen2(tp1.v), dimen2(tp3.v), $
		dimen2(tp4.v)]
	if datdims(0) lt 2 then begin
		message,'Must have at least 2 spectra for TEAMS spectrogram',$
			/continue
		return
	endif
	he = {x:tp1.x, y:fltarr(datdims(0),datdims(1)), v:tp1.v}
	helow = {x:tp1.x, y:fltarr(datdims(0),datdims(2)), v:tp3.v}
	hehigh = {x:tp1.x, y:fltarr(datdims(0),datdims(3)), v:tp4.v}
	tslop = 0.1D ; allowed error in timing
	i = 0
	iold = 0
	if data_type(heold) eq 8 then begin
		while heold.x(0)-tp1.x(i) gt tslop and i lt datdims(0) do begin
			he.y(i,*) = !values.f_nan
			helow.y(i,*) = !values.f_nan
			hehigh.y(i,*) = !values.f_nan
			i = i + 1
		endwhile
		if i eq 0 then dtp_re = tp1.x(1) - tp1.x(0) $
		else dtp_re = tp1.x(i) - tp1.x(i-1)
		if i eq datdims(0) - 1 then dtp_ad = dtp_re $
		else dtp_ad = tp1.x(i+1) - tp1.x(i)
		dth_re = heold.x(1) - heold.x(0)
		dth_ad = heold.x(1) - heold.x(0)
		ioldmax = n_elements(heold.x) - 1
		while iold lt ioldmax and i lt datdims(0) do begin
			he.y(i,*) = heold.y(iold,*)
			helow.y(i,*) = helowold.y(iold,*)
			hehigh.y(i,*) = hehighold.y(iold,*)
			i = i + 1
			if i ge datdims(0) then goto, out
			while heold.x(iold+1) - tp1.x(i) gt tslop do begin
				nextra = 0
				dtp_re = dtp_ad
				if i lt datdims(0)-1 then dtp_ad = tp1.x(i+1)-tp1.x(i)
				if abs(dtp_ad - dtp_re) le 2.0D*tslop and $
					nextra eq 0 then begin
					he.y(i,*) = heold.y(iold,*)
					helow.y(i,*) = helowold.y(iold,*)
					hehigh.y(i,*) = hehighold.y(iold,*)
					nextra = 1
				endif else begin
					he.y(i,*) = !values.f_nan
					helow.y(i,*) = !values.f_nan
					hehigh.y(i,*) = !values.f_nan
				endelse
				i = i + 1
				if i ge datdims(0) then goto, out
			endwhile
			dtp_re = dtp_ad
			if i lt datdims(0)-1 then dtp_ad = tp1.x(i+1)-tp1.x(i)
			repeat begin
				dth_re = dth_ad
				iold = iold + 1
				if iold lt ioldmax then $
					dth_ad = heold.x(iold+1)-heold.x(iold)
			endrep until heold.x(iold) - tp1.x(i) le tslop
		endwhile ; iold lt ioldmax ...
out:
		if iold le ioldmax and i lt datdims(0) then begin
			he.y(i,*) = heold.y(iold,*)
			helow.y(i,*) = helowold.y(iold,*)
			hehigh.y(i,*) = hehighold.y(iold,*)
			i = i + 1
		endif
	endif ; data_type(heold) eq 8
	print, 'Conversion loop ended', iold, i
	if i lt datdims(0) then begin ; He+ data gap at end?
		he.y(i:datdims(0)-1,*) = !values.f_nan
		helow.y(i:datdims(0)-1,*) = !values.f_nan
		hehigh.y(i:datdims(0)-1,*) = !values.f_nan
	endif
	; End He+ conversion ***EJL

		tplotfile_environvar = 'FAST_TPLOTFILE_HOME'
		dir_tplotfile = getenv(tplotfile_environvar)
		if not keyword_set(dir_tplotfile) then dir_tplotfile='./' $
			else dir_tplotfile = dir_tplotfile + '/tms'
		output=fa_output_path(dir_tplotfile,'k0','hm',orbit,'','tplot')
	tplot_file,'hm',output,/save
	nd=dimen1(tp1.x)
if nd ne dimen1(tp2.x) or nd ne dimen1(tp3.x) or nd ne dimen1(tp4.x) or nd ne dimen1(tp5.x) or nd ne dimen1(tp6.x) then begin
	print,' Error in idl/sdt get routines, fast_t_summary -- not returning equal numbers of data points!!!!'
	output=fa_output_path(dir_tplotfile,'k0','H+',orbit,'','tplot')
	tplot_file,'H+',output,/save
	output=fa_output_path(dir_tplotfile,'k0','He+',orbit,'','tplot')
	tplot_file,'He+',output,/save
	output=fa_output_path(dir_tplotfile,'k0','O+',orbit,'','tplot')
	tplot_file,'O+',output,/save
	output=fa_output_path(dir_tplotfile,'k0','H+_low',orbit,'','tplot')
	tplot_file,'H+_low',output,/save
	output=fa_output_path(dir_tplotfile,'k0','H+_high',orbit,'','tplot')
	tplot_file,'H+_high',output,/save
	output=fa_output_path(dir_tplotfile,'k0','He+_low',orbit,'','tplot')
	tplot_file,'He+_low',output,/save
	output=fa_output_path(dir_tplotfile,'k0','He+_high',orbit,'','tplot')
	tplot_file,'He+_high',output,/save
	output=fa_output_path(dir_tplotfile,'k0','O+_low',orbit,'','tplot')
	tplot_file,'O+_low',output,/save
	output=fa_output_path(dir_tplotfile,'k0','O+_high',orbit,'','tplot')
	tplot_file,'O+_high',output,/save
endif else begin
	nd=dimen1(tp1.x)
	tmp1=reform(tp1.y(0,*))
	nd1=dimen2(tp1.y)
	tmp2=reform(tp4.y(0,*))
	nd2=dimen2(tp4.y)
	cdfdat0={time:tp1.x(0),H:tmp1,H_en:tmp1,$
		He:tmp1,He_en:tmp1,O:tmp1,$
		O_en:tmp1,H_low:tmp2,H_low_pa:tmp2,$
		H_high:tmp2,H_high_pa:tmp2,He_low:tmp2,He_low_pa:tmp2,$
		He_high:tmp2,He_high_pa:tmp2,O_low:tmp2,$
		O_low_pa:tmp2,O_high:tmp2,O_high_pa:tmp2}
	cdfdat=replicate(cdfdat0,nd)
	cdfdat(*).time=tp1.x(*)
	for i=0,nd1-1 do begin
		cdfdat(*).H(i)=tp1.y(*,i)
		cdfdat(*).H_en(i)=tp1.v(*,i)
		cdfdat(*).He(i)=he.y(*,i)
		cdfdat(*).He_en(i)=he.v(*,i)
		cdfdat(*).O(i)=tp2.y(*,i)
		cdfdat(*).O_en(i)=tp2.v(*,i)
	endfor
	for i=0,nd2-1 do begin
		cdfdat(*).H_low(i)=tp3.y(*,i)
		cdfdat(*).H_low_pa(i)=tp3.v(*,i)
		cdfdat(*).H_high(i)=tp4.y(*,i)
		cdfdat(*).H_high_pa(i)=tp4.v(*,i)
		cdfdat(*).He_low(i)=helow.y(*,i)
		cdfdat(*).He_low_pa(i)=helow.v(*,i)
		cdfdat(*).He_high(i)=hehigh.y(*,i)
		cdfdat(*).He_high_pa(i)=hehigh.v(*,i)
		cdfdat(*).O_low(i)=tp5.y(*,i)
		cdfdat(*).O_low_pa(i)=tp5.v(*,i)
		cdfdat(*).O_high(i)=tp6.y(*,i)
		cdfdat(*).O_high_pa(i)=tp6.v(*,i)
	endfor
	makecdf,cdfdat,filename='fa_tms_'+orbit_num,overwrite=1, $
		tagsvary=['TIME','H+','H+_en','He+','He+_en','O+','O+_en', $
		'H+_low','H+_low_pa','H+_high','H+_high_pa','He+_low', $
		'He+_low_pa','He+_high','He+_high_pa','O+_low', $
		'O+_low_pa','O+_high','O+_high_pa']
endelse

; Generate postscript and gif files for 20 minute intervals prior and post the
;	highest invariant latitudes

gen_fa_k0_tms_gifps,bw=bw,k0=k0

return
end
