;+
;PROCEDURE:	fast_ef_summary.pro
;INPUT:	none
;
;PURPOSE:
;	Generates ps, gif, cdf summary plots of FAST electron data.
;
;	Plot 1: Electron Differential Energy Flux vs Energy, 0-30    deg pitch angle 
;	Plot 2: Electron Differential Energy Flux vs Energy, 60-120  deg pitch angle 
;	Plot 3: Electron Differential Energy Flux vs Energy, 150-180 deg pitch angle 
;	Plot 4: Electron Differential Energy Flux vs Pitch Angle, .1-1 keV  
;	Plot 5: Electron Differential Energy Flux vs Pitch Angle, 1-30 keV  
;	Plot 6: Electron Energy Flux - mapped to 100 km, positive earthward  
;	Plot 7: Electron Flux - mapped to 100 km, positive earthward  
;
;KEYWORDS
;	BW	Set bw=1 to get black/white postscript
;	k0	keyword passed to gen_fa_k0_ees_gifps.pro
;
;CREATED BY:	J.McFadden		96/11/7
;VERSION:	1
;LAST MODIFICATION:  97/03/04
;MOD HISTORY:	
;		96/11/7		made from fast_e_summary.pro
;		 		uses "make_array_struc.pro" to speed it up
;		97/03/04	Je,JEe mapped to 100 km, positive for earthward
;-
pro fast_ef_summary,BW=bw,k0=k0

; If no data exists, return to main

	t=0
	dat = get_fa_ees(t,/st)
	if dat.valid eq 0 then begin
		print,' ERROR: No FAST electron survey data -- get_fa_ees(t,/st) returned invalid data'
		return
	endif

; Collect data into an array of structures

	make_array_struc,'fa_ees_sp'

; Electron differential energy flux - energy spectrograms

	get_en_spec,"array_struc",units='eflux',name='el_0',angle=[330,30],retrace=1
	options,'el_0','spec',1	
	zlim,'el_0',1e6,1e9,1
	ylim,'el_0',3,40000,1
	options,'el_0','ytitle','e- 0!Uo!N-30!Uo!N!C!CEnergy (eV)'
	options,'el_0','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'el_0','x_no_interp',1
	options,'el_0','y_no_interp',1
	options,'el_0','panel_size',2

	get_en_spec,"array_struc",units='eflux',name='el_90',angle=[60,120],retrace=1
	options,'el_90','spec',1	
	zlim,'el_90',1e6,1e9,1
	ylim,'el_90',3,40000,1
	options,'el_90','ytitle','e- 60!Uo!N-120!Uo!N!C!CEnergy (eV)'
	options,'el_90','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'el_90','x_no_interp',1
	options,'el_90','y_no_interp',1
	options,'el_90','panel_size',2

	get_en_spec,"array_struc",units='eflux',name='el_180',angle=[150,180],retrace=1
	options,'el_180','spec',1	
	zlim,'el_180',1e6,1e9,1
	ylim,'el_180',3,40000,1
	options,'el_180','ytitle','e- 150!Uo!N-180!Uo!N!C!CEnergy (eV)'
	options,'el_180','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'el_180','x_no_interp',1
	options,'el_180','y_no_interp',1
	options,'el_180','panel_size',2

; Electron differential energy flux - angle spectrograms

	get_pa_spec,"array_struc",units='eflux',name='el_low',energy=[100,1000],retrace=1,/shift90
	options,'el_low','spec',1	
	zlim,'el_low',1e6,1e9,1
	ylim,'el_low',-100,280,0
	options,'el_low','ytitle','e- .1-1 keV!C!C Pitch Angle'
	options,'el_low','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'el_low','x_no_interp',1
	options,'el_low','y_no_interp',1
	options,'el_low','panel_size',2

	get_pa_spec,"array_struc",units='eflux',name='el_high',energy=[1000,40000],retrace=1,/shift90
	options,'el_high','spec',1	
	zlim,'el_high',1e6,1e9,1
	ylim,'el_high',-100,280,0
	options,'el_high','ytitle','e- >1 keV!C!C Pitch Angle'
	options,'el_high','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'el_high','x_no_interp',1
	options,'el_high','y_no_interp',1
	options,'el_high','panel_size',2

; Electron energy flux - line plot

	get_2dt,'je_2d',"array_struc",name='JEe',energy=[25,40000]
	ylim,'JEe',.001,100,1
	options,'JEe','ytitle','e- >25eV!C!Cergs/cm!U2!N-s'
	options,'JEe','tplot_routine','pmplot'
	
; Electron flux - line plot

	get_2dt,'j_2d',"array_struc",name='Je',energy=[25,40000]
	ylim,'Je',1.e6,1.e10,1
	options,'Je','ytitle','e- >25eV!C!C1/cm!U2!N-s'
	options,'Je','tplot_routine','pmplot'

; Get the orbit data

	get_data,'el_0',data=tmp
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
	get_data,'JEe',data=tmp
	tmp.y = sgn_flx*tmp.y*ratio
	store_data,'JEe',data=tmp
	get_data,'Je',data=tmp
	tmp.y = sgn_flx*tmp.y*ratio
	store_data,'Je',data=tmp
		options,'Je','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'Je','labflag',3
		options,'Je','labpos',[3.e9,6.e8]
		options,'JEe','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'JEe','labflag',3
		options,'JEe','labpos',[30.,4.]

; Save the data to a cdf file  

	get_data,'el_0',data=tp1
	get_data,'el_90',data=tp2
	get_data,'el_180',data=tp3
	get_data,'el_low',data=tp4
	get_data,'el_high',data=tp5
	get_data,'JEe',data=tp6
	get_data,'Je',data=tp7
	nd=dimen1(tp1.x)
if nd ne dimen1(tp2.x) or nd ne dimen1(tp3.x) or nd ne dimen1(tp4.x) or nd ne dimen1(tp5.x) or nd ne dimen1(tp6.x) or nd ne dimen1(tp7.x) then begin
	print,' Error in idl/sdt get routines, fast_e_summary -- not returning equal numbers of data points!!!!'
		tplotfile_environvar = 'FAST_TPLOTFILE_HOME'
		dir_tplotfile = getenv(tplotfile_environvar)
		if not keyword_set(dir_tplotfile) then dir_tplotfile='./' $
			else dir_tplotfile = dir_tplotfile + '/ees'
		output=fa_output_path(dir_tplotfile,'k0','el_0',orbit,'','tplot')
	tplot_file,'el_0',output,/save
		output=fa_output_path(dir_tplotfile,'k0','el_90',orbit,'','tplot')
	tplot_file,'el_90',output,/save
		output=fa_output_path(dir_tplotfile,'k0','el_180',orbit,'','tplot')
	tplot_file,'el_180',output,/save
		output=fa_output_path(dir_tplotfile,'k0','el_low',orbit,'','tplot')
	tplot_file,'el_low',output,/save
		output=fa_output_path(dir_tplotfile,'k0','el_high',orbit,'','tplot')
	tplot_file,'el_high',output,/save
		output=fa_output_path(dir_tplotfile,'k0','JEe',orbit,'','tplot')
	tplot_file,'JEe',output,/save
		output=fa_output_path(dir_tplotfile,'k0','Je',orbit,'','tplot')
	tplot_file,'Je',output,/save
endif else begin
	tmp1=reform(tp1.y(0,*))
	nd1=dimen2(tp1.y)
	tmp2=reform(tp4.y(0,*))
	nd2=dimen2(tp4.y)
	cdfdat0={time:tp1.x(0),el_0:tmp1,el_90:tmp1,el_180:tmp1,el_en:tmp1,$
		el_low:tmp2,el_low_pa:tmp2,el_high:tmp2,el_high_pa:tmp2,$
		JEe:tp6.y(0),Je:tp7.y(0)}
	cdfdat=replicate(cdfdat0,nd)
	cdfdat(*).time=tp1.x(*)
	for i=0,nd1-1 do begin
		cdfdat(*).el_0(i)=tp1.y(*,i)
		cdfdat(*).el_90(i)=tp2.y(*,i)
		cdfdat(*).el_180(i)=tp3.y(*,i)
		cdfdat(*).el_en(i)=tp3.v(*,i)
	endfor
	for i=0,nd2-1 do begin
		cdfdat(*).el_low(i)=tp4.y(*,i)
		cdfdat(*).el_low_pa(i)=tp4.v(*,i)
		cdfdat(*).el_high(i)=tp5.y(*,i)
		cdfdat(*).el_high_pa(i)=tp5.v(*,i)
	endfor
	cdfdat(*).JEe=tp6.y(*)
	cdfdat(*).Je=tp7.y(*)
	makecdf,cdfdat,filename='fa_ees_'+orbit_num,overwrite=1, $
	tagsvary=['TIME','el_0','el_90','el_180','el_en','el_low', $
	'el_low_pa','el_high','el_high_pa','JEe','Je']
endelse

; Generate postscript and gif files for 20 minute intervals prior and post the
;	highest invariant latitudes

gen_fa_k0_ees_gifps,bw=bw,k0=k0

return
end
