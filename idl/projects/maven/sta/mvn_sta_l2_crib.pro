;+
;NAME:
;mvn_sta_l2_crib
;PURPOSE:
;	Crib for loading MAVEN L2 STATIC data
;-

; Set timespan 

	timespan, '2014-05-10'

; Load static data

	mvn_sta_l2_load

; Generate tplot structures

	mvn_sta_l2_tplot

; View names of STATIC tplot structures

	tplot_names,'*sta*'

; Time series plots of apid c6 data

	window,0
	tplot,'*c6*'

; Plot a variety of data

	tplot,['mvn_sta_c6_att','mvn_sta_c6_tot','mvn_sta_c0_E','mvn_sta_c6_M','mvn_sta_c8_D','mvn_sta_d4_A','mvn_sta_d0_E']

; Zoom in on some data - click on a pair of times

	tlimit
	wait,2

; Zoom back out

	tlimit,/full
	wait,1

; Get a single distribution - click once in the tplot window
	
	dat1=mvn_sta_get_c6()        ; single energy-mass spectra

; Plot the distribution

	window,2
	zscale=1.e0
	contour4d,dat1,/points,/label,/fill,/mass,zrange=zscale*[.1,1.e5],/twt,units='counts'

; Get a distribution averaged over time - click twice in the tplot window for the interval

	dat2=mvn_sta_get('c6')        ; averaged energy-mass spectra

; Plot the averaged distribution

	window,3
	zscale = max(dat2.data)/1.e5 > 1
	contour4d,dat2,/points,/label,/fill,/mass,zrange=zscale*[.1,1.e5],/twt,units='counts'

; Plot the spectra

	window,1
	spec3d,dat2 

; Calculate density and velocity of solar wind protons

	print,nb_4d(dat2,mass=[.5,1.68],m_int=1.)
	print,vb_4d(dat2,mass=[.5,1.68],m_int=1.)

; Load multiple days of l2 data with a subset of STATIC data

	timespan, ['2014-06-01/12:00','2014-06-03/10:00']
	mvn_sta_l2_load, sta_apid = ['c0 d?']

; Generate tplot structures

	mvn_sta_l2_tplot

; Plot apid c0 data

	window,0
	tplot,'*c0*'


End
