;+
;PROCEDURE:	mvn_sta_l0_crib
;PURPOSE:	
;	crib file to demonstrate static functions and test software 
;
;INPUT:		
;
;KEYWORDS:
;
;CREATED BY:	J. McFadden	
;VERSION:	1
;LAST MODIFICATION:  14-05-16
;MOD HISTORY:
;
;NOTES:	  
;	
;-

pro mvn_sta_l0_crib

; load data for a selected day - select dates starting 2014 3 19

	mvn_sta_l0_load

	init_devices
	tplot_options,verbose=2
	loadct2,43
	cols=get_colors()

; example changing plot limits (default limits are in mvn_sta_prod_cal.pro)

	zlim,'mvn_sta_C0_P1A_E',1,100,1
	zlim,'mvn_sta_D4_P4E_A',1,1000,1
	zlim,'mvn_sta_D0_P4C_D',1,10000,1
	zlim,'mvn_sta_C4_P1C_M',1,1000,1

; time series plots

	window,0,xsize=900,ysize=1000

	tplot,['mvn_sta_C0_P1A_tot','mvn_sta_C2_P1B_tot','mvn_sta_C4_P1C_tot','mvn_sta_D0_P4C_tot','mvn_sta_D4_P4E_tot','mvn_sta_D8_R1_Time_RST','mvn_sta_C0_P1A_E','mvn_sta_D4_P4E_A','mvn_sta_D0_P4C_D','mvn_sta_C4_P1C_M'],title=file

; get the apid c6 (32-energy x 64-mass) distribution

	print,' click on time range for selected c6 data'

	wait,2
	dat_c6=mvn_sta_get('c6')

; get the apid c0 (64-energy x 2-mass) distribution at the same times as c6

	dat_c0=mvn_sta_get('c0',tt=[dat_c6.time,dat_c6.end_time])

; contour energy-mass plot

	wait,2
	window,1
	contour4d,dat_c6,/points,/label,/fill,/mass,zrange=[1.e3,1.e8]

; remove background from straggling

	bkg=mvn_sta_c6_bkg(dat_c6)
	dat2 = dat_c6 & dat2.data=dat2.data-bkg
	wait,4
	contour4d,dat2,/points,/label,/fill,/mass,zrange=[1.e3,1.e8]

; energy spectra at different masses

	wait,2
	window,2
	spec3d,dat_c6

; energy spectra at different masses

	wait,2
	window,3
	spec3d,dat_c0

; get the d0 (32Ex8Mx4Dx16A) energy-mass-angle distribution

	wait,2
	dat_d0=mvn_sta_get('d0')

; make a mass averaged distribution

	wait,2
	md0=sum4m(dat_d0) 
	window,4
	spec3d,md0 

; plot the solid angle distribution
; left click to see spectra in a solid angle, center click to turn off bin, right click to exit 

	wait,2
	window,5
	bins=bytarr(md0.nbins)
	edit3dbins,md0,bins,0,0

; calculate densities

	wait,2
	window,2
	contour4d,dat_c6,/points,/label,/fill,/mass,zrange=[1.e3,1.e8]

	print,'Proton density: ' 	,nb_4d(dat_c6,mass=[.5,1.78],m_int=1)
	print,'Alpha  density: ' 	,nb_4d(dat_c6,mass=[1.76,2.5],m_int=2)
	print,'Proton velocity: '	,vb_4d(dat_c6,mass=[.5,1.78],m_int=1)
	print,'Proton temperature: '	,tb_4d(dat_c6,mass=[.5,1.78],m_int=1)

; calculate densities for the entire interval

	get_4dt,'nb_4d','mvn_sta_get_c6',mass=[.3,1.55],name='mvn_sta_n_p_c6',m_int=1.
		options,'mvn_sta_n_p_c6',ytitle='sta C6!C!CNp!C#/cm!U3'
		ylim,'mvn_sta_n_p_c6',.1,30,1
		options,'mvn_sta_n_p_c6',colors=cols.blue
	tsmooth2,'mvn_sta_n_p_c6',30
		options,'mvn_sta_n_p_c6_sm',ytitle='sta C6!C!CNp!C#/cm!U3'
		ylim,'mvn_sta_n_p_c6_sm',.1,30,1
		options,'mvn_sta_n_p_c6_sm',colors=cols.blue

	tplot,['mvn_sta_n_p_c6_sm','mvn_sta_C0_P1A_tot','mvn_sta_C2_P1B_tot','mvn_sta_C4_P1C_tot','mvn_sta_D0_P4C_tot','mvn_sta_D4_P4E_tot','mvn_sta_D8_R1_Time_RST','mvn_sta_C0_P1A_E','mvn_sta_D4_P4E_A','mvn_sta_D0_P4C_D','mvn_sta_C4_P1C_M'],title=file

end