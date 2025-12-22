;+
;PROCEDURE:	fast_if_summary.pro
;INPUT:	none
;
;PURPOSE:
;	Generates ps, gif, cdf summary plots of FAST ion data.
;
;	Plot 1: Ion Differential Energy Flux vs Energy, 0-30    deg pitch angle 
;	Plot 2: Ion Differential Energy Flux vs Energy, 40-140  deg pitch angle 
;	Plot 3: Ion Differential Energy Flux vs Energy, 150-180 deg pitch angle 
;	Plot 4: Ion Differential Energy Flux vs Pitch Angle, .05-1. keV  
;	Plot 5: Ion Differential Energy Flux vs Pitch Angle, 1.-25. keV  
;	Plot 6: Ion Energy Flux - mapped to 100 km, positive earthward  
;	Plot 7: Ion Flux - mapped to 100 km, positive earthward  
;
;KEYWORDS
;	BW	Set bw=1 to get black/white postscript
;	k0	keyword passed to gen_fa_k0_ies_gifps.pro
;
;CREATED BY:	J.McFadden		96/11/7
;VERSION:	1
;LAST MODIFICATION:  97/03/04
;MOD HISTORY:	
;		96/11/7		made from fast_i_summary.pro
;				uses "make_array_struc.pro" to speed it up
;		97/03/04	Ji,JEi mapped to 100 km, positive for earthward
;-
pro fast_if_summary,BW=bw,k0=k0

; If no data exists, return to main

	t=0
	dat = get_fa_ies(t,/st)
	if dat.valid eq 0 then begin
		print,' ERROR: No FAST ion survey data -- get_fa_ies(t,/st) returned invalid data'
		return
	endif

; Collect data into an array of structures

	make_array_struc,'fa_ies_sp'

; Ion differential energy flux - energy spectrograms

	get_en_spec,"array_struc",units='eflux',name='ion_0',angle=[330,30],retrace=1
	options,'ion_0','spec',1	
	zlim,'ion_0',1e4,1e8,1
	ylim,'ion_0',3,40000,1
	options,'ion_0','ytitle','ions 0!Uo!N-30!Uo!N!C!CEnergy (eV)'
	options,'ion_0','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'ion_0','x_no_interp',1
	options,'ion_0','y_no_interp',1
	options,'ion_0','panel_size',2

	get_en_spec,"array_struc",units='eflux',name='ion_90',angle=[40,140],retrace=1
	options,'ion_90','spec',1	
	zlim,'ion_90',1e4,1e8,1
	ylim,'ion_90',3,40000,1
	options,'ion_90','ytitle','ions 40!Uo!N-140!Uo!N!C!CEnergy (eV)'
	options,'ion_90','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'ion_90','x_no_interp',1
	options,'ion_90','y_no_interp',1
	options,'ion_90','panel_size',2

	get_en_spec,"array_struc",units='eflux',name='ion_180',angle=[150,210],retrace=1
	options,'ion_180','spec',1	
	zlim,'ion_180',1e4,1e8,1
	ylim,'ion_180',3,40000,1
	options,'ion_180','ytitle','ions 150!Uo!N-180!Uo!N!C!CEnergy (eV)'
	options,'ion_180','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'ion_180','x_no_interp',1
	options,'ion_180','y_no_interp',1
	options,'ion_180','panel_size',2

; Ion differential energy flux - angle spectrograms

	get_pa_spec,"array_struc",units='eflux',name='ion_low',energy=[50,1000],retrace=1,/shift90
	options,'ion_low','spec',1	
	zlim,'ion_low',1e4,1e8,1
	ylim,'ion_low',-100,280,0
	options,'ion_low','ytitle','ions .05-1 keV!C!C Pitch Angle'
	options,'ion_low','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'ion_low','x_no_interp',1
	options,'ion_low','y_no_interp',1
	options,'ion_low','panel_size',2

	get_pa_spec,"array_struc",units='eflux',name='ion_high',energy=[1000,40000],retrace=1,/shift90
	options,'ion_high','spec',1	
	zlim,'ion_high',1e4,1e8,1
	ylim,'ion_high',-100,280,0
	options,'ion_high','ytitle','ions >1 keV!C!C Pitch Angle'
	options,'ion_high','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'ion_high','x_no_interp',1
	options,'ion_high','y_no_interp',1
	options,'ion_high','panel_size',2

; Ion energy flux - line plot

	get_2dt,'je_2d',"array_struc",name='JEi',energy=[20,30000]
	ylim,'JEi',1.e-5,1,1
	options,'JEi','ytitle','i+ >20eV!C!Cergs/cm!U2!N-s'
	options,'JEi','tplot_routine','pmplot'
	
; Ion flux - line plot

	get_2dt,'j_2d',"array_struc",name='Ji',energy=[20,30000]
	ylim,'Ji',1.e5,1.e9,1
	options,'Ji','ytitle','i+ >20eV!C!C1/cm!U2!N-s'
	options,'Ji','tplot_routine','pmplot'

; Get the orbit data

	get_data,'ion_0',data=tmp
	orbit_file=fa_almanac_dir()+'/orbit/predicted'
	get_fa_orbit,tmp.x,/time_array,orbit_file=orbit_file,/all
	get_data,'ORBIT',data=tmp
	orbit=tmp.y(0)
	orbit_num=strcompress(string(tmp.y(0)),/remove_all)

; Scale the flux and energy flux to 100 km and make positive flux earthward

	get_data,'ILAT',data=tmp
	sgn_flx = tmp.y/abs(tmp.y)
	get_data,'B_model',data=tmp1
	get_data,'BFOOT',data=tmp2
	mag1 = (tmp1.y(*,0)*tmp1.y(*,0)+tmp1.y(*,1)*tmp1.y(*,1)+tmp1.y(*,2)*tmp1.y(*,2))
	mag2 = (tmp2.y(*,0)*tmp2.y(*,0)+tmp2.y(*,1)*tmp2.y(*,1)+tmp2.y(*,2)*tmp2.y(*,2))
	ratio = (mag2/mag1)^.5
	get_data,'JEi',data=tmp
	tmp.y = sgn_flx*tmp.y*ratio
	store_data,'JEi',data=tmp
	get_data,'Ji',data=tmp
	tmp.y = sgn_flx*tmp.y*ratio
	store_data,'Ji',data=tmp
		options,'Ji','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'Ji','labflag',3
		options,'Ji','labpos',[3.e8,6.e7]
		options,'JEi','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'JEi','labflag',3
		options,'JEi','labpos',[.30,.04]

; Save the data to a cdf file  

	get_data,'ion_0',data=tp1
	get_data,'ion_90',data=tp2
	get_data,'ion_180',data=tp3
	get_data,'ion_low',data=tp4
	get_data,'ion_high',data=tp5
	get_data,'JEi',data=tp6
	get_data,'Ji',data=tp7
	nd=dimen1(tp1.x)
if nd ne dimen1(tp2.x) or nd ne dimen1(tp3.x) or nd ne dimen1(tp4.x) or nd ne dimen1(tp5.x) or nd ne dimen1(tp6.x) or nd ne dimen1(tp7.x) then begin
	print,' Error in idl/sdt get routines, fast_i_summary -- not returning equal numbers of data points!!!!'
		tplotfile_environvar = 'FAST_TPLOTFILE_HOME'
		dir_tplotfile = getenv(tplotfile_environvar)
		if not keyword_set(dir_tplotfile) then dir_tplotfile='./' $
			else dir_tplotfile = dir_tplotfile + '/ies'
		output=fa_output_path(dir_tplotfile,'k0','ion_0',orbit,'','tplot')
	tplot_file,'ion_0',output,/save
		output=fa_output_path(dir_tplotfile,'k0','ion_90',orbit,'','tplot')
	tplot_file,'ion_90',output,/save
		output=fa_output_path(dir_tplotfile,'k0','ion_180',orbit,'','tplot')
	tplot_file,'ion_180',output,/save
		output=fa_output_path(dir_tplotfile,'k0','ion_low',orbit,'','tplot')
	tplot_file,'ion_low',output,/save
		output=fa_output_path(dir_tplotfile,'k0','ion_high',orbit,'','tplot')
	tplot_file,'ion_high',output,/save
		output=fa_output_path(dir_tplotfile,'k0','JEi',orbit,'','tplot')
	tplot_file,'JEi',output,/save
		output=fa_output_path(dir_tplotfile,'k0','Ji',orbit,'','tplot')
	tplot_file,'Ji',output,/save
endif else begin
	tmp1=reform(tp1.y(0,*))
	nd1=dimen2(tp1.y)
	tmp2=reform(tp4.y(0,*))
	nd2=dimen2(tp4.y)
	cdfdat0={time:tp1.x(0),ion_0:tmp1,ion_90:tmp1,ion_180:tmp1,ion_en:tmp1,$
		ion_low:tmp2,ion_low_pa:tmp2,ion_high:tmp2,ion_high_pa:tmp2,$
		JEi:tp6.y(0),Ji:tp7.y(0)}
	cdfdat=replicate(cdfdat0,nd)
	cdfdat(*).time=tp1.x(*)
	for i=0,nd1-1 do begin
		cdfdat(*).ion_0(i)=tp1.y(*,i)
		cdfdat(*).ion_90(i)=tp2.y(*,i)
		cdfdat(*).ion_180(i)=tp3.y(*,i)
		cdfdat(*).ion_en(i)=tp3.v(*,i)
	endfor
	for i=0,nd2-1 do begin
		cdfdat(*).ion_low(i)=tp4.y(*,i)
		cdfdat(*).ion_low_pa(i)=tp4.v(*,i)
		cdfdat(*).ion_high(i)=tp5.y(*,i)
		cdfdat(*).ion_high_pa(i)=tp5.v(*,i)
	endfor
	cdfdat(*).JEi=tp6.y(*)
	cdfdat(*).Ji=tp7.y(*)
	makecdf,cdfdat,filename='fa_ies_'+orbit_num,overwrite=1,$
	tagsvary=['TIME','ion_0','ion_90','ion_180','ion_en','ion_low', $
	'ion_low_pa','ion_high','ion_high_pa','JEi','Ji']
endelse

; Generate postscript and gif files for 20 minute intervals prior and post the
;	highest invariant latitudes

gen_fa_k0_ies_gifps,bw=bw,k0=k0

return
end
