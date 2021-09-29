;+
;PROGRAM:	mvn_sta_set_th_offset2
;INPUT:	
;	time:	dbl,		input time
;KEYWORDS
;					0,1=exclude,include
;PURPOSE:
;	Returns parameters [efoldoffset,e0,scale1] for offset2 calculation used by th_4d.pro, th2_4d.pro and vp_4d.pro
;		offset2=efoldoffset*(1.-erf((energy-e0)/(scale1*e0)))
 
;NOTES:	
;	Function normally called by th_4d.pro, th2_4d.pro and vp_4d.pro
;	offset2 is an energy dependent angle offset determined by ion suppression whose functional form is emperical
;
;CREATED BY:
;	J.McFadden	2016-10-28
;LAST MODIFICATION:
;	J.McFadden	2016-10-28
;-
pro mvn_sta_set_th_offset2,time

common mvn_sta_offset2,efoldoffset,e0,scale1,offset1

offset1=0.

scale1 = 2.0 & efoldoffset = 4.0		; 20160616 with offset3 with kk=2.0, att=3, scpot=-3, minimizes upwelling at periapsis


e0=6.0 
;if time gt time_double('2015-05-25/00:00') then e0=6.0  

if time gt time_double('2015-07-22/00:00') then e0=6.0  

if time gt time_double('2015-08-08/00:00') then e0=6.0  
if time gt time_double('2015-08-09/00:00') then e0=6.0  
;if time gt time_double('2015-08-10/00:00') then e0=6.0  		;tbd

;if time gt time_double('2015-08-21/00:00') then e0=5.0  		;????

if time gt time_double('2015-08-28/00:00') then e0=5.0  		;
if time gt time_double('2015-08-29/00:00') then e0=5.0  		;
if time gt time_double('2015-08-30/00:00') then e0=5.0  		;

; algorithm seem to break down after 2015-08-30

if time gt time_double('2015-09-10/00:00') then e0=5.0  		; 22UT, poor fit no reasonable value works
if time gt time_double('2015-09-12/00:00') then e0=5.0  		; 06UT, poor fit no reasonable value works

;if time gt time_double('2015-10-13/00:00') then e0=7.5  		; this seems unreasonable, so assume real wind on this orbit
if time gt time_double('2015-10-13/00:00') then e0=4.0  
if time gt time_double('2015-10-17/00:00') then e0=4.0  

; algorithm seem to break down prior to 2015-10-27

if time gt time_double('2015-10-27/00:00') then e0=3.5  
if time gt time_double('2015-10-28/00:00') then e0=3.5  		; even orbits
if time gt time_double('2015-10-30/00:00') then e0=3.5  		; even orbits 
if time gt time_double('2015-11-01/00:00') then e0=3.5  		; even orbits
if time gt time_double('2015-11-02/00:00') then e0=3.5  		; even orbits

if time gt time_double('2015-11-10/00:00') then e0=2.4  
if time gt time_double('2015-11-13/00:00') then e0=3.0  

if time gt time_double('2015-11-24/00:00') then e0=2.3  		; 
if time gt time_double('2015-11-27/00:00') then e0=2.4  
if time gt time_double('2015-12-01/00:00') then e0=2.4   		;

if time gt time_double('2015-12-08/00:00') then e0=2.8  
if time gt time_double('2015-12-11/00:00') then e0=2.4  

if time gt time_double('2015-12-22/00:00') then e0=2.4  
if time gt time_double('2015-12-24/00:00') then e0=2.4  
if time gt time_double('2015-12-25/00:00') then e0=2.4  

if time gt time_double('2016-01-05/00:00') then e0=1.8    		; att=2

if time gt time_double('2016-01-08/00:00') then e0=1.8    		; att=2

if time gt time_double('2016-01-26/00:00') then e0=2.0    		; att=2
if time gt time_double('2016-01-29/00:00') then e0=1.8   		; att=2
if time gt time_double('2016-02-02/00:00') then e0=1.5  		; att=2
if time gt time_double('2016-02-05/00:00') then e0=2.5  		; att=2
if time gt time_double('2016-02-09/00:00') then e0=2.2  		; att=3, 2.0 works also
if time gt time_double('2016-02-12/00:00') then e0=1.5  		; att=3,
if time gt time_double('2016-02-17/00:00') then e0=1.8   		; att=2,3,
if time gt time_double('2016-02-20/00:00') then e0=1.8  
if time gt time_double('2016-02-24/00:00') then e0=2.2   		; att=3,
if time gt time_double('2016-02-27/00:00') then e0=2.5  

if time gt time_double('2016-04-05/00:00') then e0=2.8  		; 
if time gt time_double('2016-04-08/00:00') then e0=2.8  		; 3.2 might be better
if time gt time_double('2016-04-12/00:00') then e0=2.5  
if time gt time_double('2016-04-15/00:00') then e0=2.5  
if time gt time_double('2016-04-27/00:00') then e0=2.5  
if time gt time_double('2016-04-29/00:00') then e0=2.3  
if time gt time_double('2016-05-04/00:00') then e0=2.0  

if time gt time_double('2016-05-25/00:00') then e0=2.2  		; ram-horz even orbits
;if time gt time_double('2016-05-28/00:00') then e0=2.2  		; ram-horz even orbits 
if time gt time_double('2016-05-29/00:00') then e0=2.0  		; ram-horz even orbits 

;if time gt time_double('2016-06-04/00:00') then e0=2.0  
;if time gt time_double('2016-06-16/00:00') then e0=2.0  
;if time gt time_double('2016-06-20/00:00') then e0=2.0  
if time gt time_double('2016-06-22/00:00') then e0=2.5  
if time gt time_double('2016-07-18/00:00') then e0=2.0  
if time gt time_double('2016-08-04/00:00') then e0=2.0  		; ram-horz 1st orbit?

scale1 = 2.0 & efoldoffset = 4.0		; 20160616 with offset3 with kk=2.0, att=3, scpot=-3, minimizes upwelling at periapsis

if time gt time_double('2016-08-31/00:00') then begin
 	e0=2.8 & 	scale1 = 1.0 & 	efoldoffset = 4.0		; requires offset1=0
	offset1= 0.5 
endif

if time gt time_double('2016-09-01/00:00') then begin
; 	e0=2.0 & 	scale1 = 2.0 & 	efoldoffset = 6.0		; requires offset1=-.6		
; 	e0=1.6 & 	scale1 = 2.0 & 	efoldoffset = 6.0		; requires offset1=.4		
; 	e0=1.75 & 	scale1 = 2.0 & 	efoldoffset = 6.0		; requires offset1=0		

; 	e0=2.0 & 	scale1 = 1.5 & 	efoldoffset = 5.3		; requires offset1=.25
; 	e0=2.5 & 	scale1 = 1.5 &	efoldoffset = 5.3		; requires offset1=-.8
; 	e0=2.1 & 	scale1 = 1.5 & 	efoldoffset = 5.3		; requires offset1=0

; 	e0=2.5 & 	scale1 = 1.0 & 	efoldoffset = 4.0		; requires offset1=.5
; 	e0=3.0 & 	scale1 = 1.0 & 	efoldoffset = 4.0		; requires offset1=-.3
 	e0=2.8 & 	scale1 = 1.0 & 	efoldoffset = 4.0		; requires offset1=0

	offset1= 0.5 

; 	expect 4,1 from the following
; 	energy=2.8 & print,efoldoffset*(1.-erf((energy-e0)/(scale1*e0))),efoldoffset*(1.-erf((energy+2.3-e0)/(scale1*e0)))
; 	energy=4.9 & print,efoldoffset*(1.-erf((energy-e0)/(scale1*e0))),efoldoffset*(1.-erf((2.8-e0)/(scale1*e0)))

if 0 then begin
	window,0,xsize=800,ysize=600
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; guess
 	energy=findgen(100)/10. & plot,energy,efoldoffset*(1.-erf((energy-e0)/(scale1*e0))),charsize=1.5,charthick=2,thick=2,title='STATIC Deflection Offset',xtitle='Energy (eV)',ytitle='Offset (degrees)'
		xyouts,4,7,'offset*(1-ERF(energy/e0-1.)/scale))',charsize=1.5,charthick=2 
		xyouts,5,6.5,'offset = 4.0',charsize=1.5,charthick=2 
		xyouts,5,6. ,'e0    = 3.0',charsize=1.5,charthick=2 
		xyouts,5,5.5,'scale  = 0.7',charsize=1.5,charthick=2 
	makepng,'deflection_offset_algorithm'
endif

endif


;**************************************************************************************************************************************
;**************************************************************************************************************************************
; Below are the current calibrations

	e0=3.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; default


; 15-09-02	Deep Dip 4 begins



; 15-09-10	Deep Dip 4 ends

if time gt time_double('2015-09-12/00:00') then begin
	e0=7.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 1 ram horizontal - second periapsis checked 20190218
endif




if time gt time_double('2015-11-24/00:00') then begin
	e0=3.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1, 5th orbit ram horizontal, 20170103
endif

;if time gt time_double('2015-11-27/00:00') then begin
;	e0=3.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1, 6th orbit ram horizontal, 20161230
;endif

if time gt time_double('2015-12-01/00:00') then begin
	e0=3.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1, 5th orbit ram horizontal, 20161223
endif

if time gt time_double('2015-12-08/00:00') then begin
	e0=3.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1, 5th orbit ram horizontal, 20170103
endif

if time gt time_double('2015-12-11/00:00') then begin
;	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1, 5th orbit ram horizontal e0 too small
;	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1, 5th orbit ram horizontal 20161126
	e0=3.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1, 5th orbit ram horizontal 20161126
endif

if time gt time_double('2015-12-22/00:00') then begin
	e0=3.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 (fly-(-Y)), 5th orbit ram horizontal, 20161219
endif

if time gt time_double('2015-12-24/00:00') then begin
	e0=3.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 (fly-(-Y)), 5th orbit ram horizontal - but no contact, 20161223
endif

; for the previous  orbits, att= 3 at periapsis
; for the following orbits, att<=2 at periapsis



if time gt time_double('2016-01-05/00:00') then begin
	e0=2.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1 (fly-(-Y)), 5th orbit ram horizontal, not well determined due to terminator 
endif
if time gt time_double('2016-01-08/00:00') then begin
	e0=2.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1 (fly-(-Y)), 5th orbit ram horizontal, 20161219
endif

;16-01-12		scenario 2, static ion suppression cleaning week - last cleaning week


if time gt time_double('2016-01-22/00:00') then begin
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1 (fly-(-Y)), 4th orbit ram horizontal
endif
if time gt time_double('2016-02-02/00:00') then begin
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 (fly-(-Y)), 1st orbit ram horizontal, 20161122
endif
if time gt time_double('2016-02-17/00:00') then begin
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 (fly-(-Y)), 1st orbit ram horizontal, 20161122
endif

if time gt time_double('2016-02-20/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 (fly-(-Y)), 1st orbit ram horizontal
endif
if time gt time_double('2016-02-24/00:00') then begin
	e0=2.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 (fly-(-Y)), 1st orbit ram horizontal
endif

if time gt time_double('2016-02-27/00:00') then begin
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 (fly-(-Y)), 1st orbit ram horizontal
endif

if time gt time_double('2016-03-10/00:00') then begin
	e0=3.1 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 4b guess - no ram horizontal
endif

if time gt time_double('2016-03-16/00:00') then begin
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 4b guess - no ram horizontal
endif

if time gt time_double('2016-03-28/00:00') then begin
	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2b guess - no ram horizontal
endif

if time gt time_double('2016-04-08/00:00') then begin
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 fly-(+Y), ram horizontal
endif



if time gt time_double('2016-04-22/00:00') then begin
	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 fly-(+Y), ram horizontal
endif

if time gt time_double('2016-05-04/00:00') then begin
	e0=3.1 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 fly-(+Y), ram horizontal
endif

if time gt time_double('2016-05-25/00:00') then begin
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20180330, scenario 2a fly-(+Y), ram horizontal on even orbits
endif


if time gt time_double('2016-05-29/00:00') then begin
	e0=3.1 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2a fly-(+Y), ram horizontal on even orbits
endif

if time gt time_double('2016-06-04/00:00') then begin
;	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 
	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2a fly-(+Y), ram horizontal on even orbits
endif

if time gt time_double('2016-06-12/00:00') then begin
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2b? fly-(-Z), guess - no ram horizontal
endif

if time gt time_double('2016-06-16/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2*-nod fly-(+Y), ram-horizontal all orbits
endif

if time gt time_double('2016-06-23/00:00') then begin
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2*-nod fly-(+Y), ram-horizontal all orbits
endif

if time gt time_double('2016-07-16/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20171123, ram-horizontal all orbits
endif

; 2016-07-25										; scenario 2*-nod fly-(+Y)
; 2016-07-26										; scenario 2b or 4b fly-(-Z)
; 2016-08-04										; scenario 2** 60 deg nod fly-(+Y)

if time gt time_double('2016-08-08/00:00') then begin
;	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; too large, ram-horizontal all orbits
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2** 60 deg nod fly-(+Y) not well determined, ram-horizontal?? all orbits
endif

if time gt time_double('2016-08-24/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20171123, ram-horizontal even orbits
endif

if time gt time_double('2016-08-28/00:00') then begin
	e0=2.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20171123, ram-horizontal even orbits, sza=130
endif

; 2016-08-24										; scenario 2a fly-(-Y)
; 2016-08-30										; scenario 2 fly-(-Y)

if time gt time_double('2016-09-06/00:00') then begin
	e0=2.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 fly-(-Y), checked 20161201
endif

if time gt time_double('2016-09-10/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20171124, ram-horizontal 1st orbit, terminator crossing
endif

if time gt time_double('2016-09-14/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 fly-(-Y), ram-horizontal first orbit, not well determined 20161121, terminator crossing
endif

if time gt time_double('2016-09-17/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 fly-(-Y), 20161107, not well determined
endif

if time gt time_double('2016-09-20/00:00') then begin
	e0=2.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 fly-(-Y), 20161121, ram horizontal
endif

if time gt time_double('2016-09-24/00:00') then begin
;	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161104, scenario 1, ram horizontal
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 fly-(-Y), checked 20161104 and 20171122, scenario 1, ram horizontal, sza=87, scpot=-2.5
endif

if time gt time_double('2016-09-27/00:00') then begin
; 	e0=2.8 & 	scale1 = 1.0 & 	efoldoffset = 4.0	& offset1= 0.0	 	; works too scenario 2 fly-(-Y), 
;	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; e0 needs to be larger
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161107, ram horizontal
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20171122, ram horizontal, scpot=-2V, sza=83
endif

; A 0.5 error in e0 produces a ~100m/s error in velocity

if time gt time_double('2016-10-01/00:00') then begin
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 2 fly-(-Y), checked 20161107, scenario 1, ram horizontal
endif

if time gt time_double('2016-10-05/00:00') then begin
;	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; a bit off
	e0=3.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; scenario 1 fly-(-Y), checked 20161104, scenario 1, ram horizontal

endif

if time gt time_double('2016-10-08/00:00') then begin
;	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; a bit off
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161104, scenario 1, ram horizontal
endif

if time gt time_double('2016-10-11/00:00') then begin
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161103, scenario 1, ram horizontal
endif


if time gt time_double('2016-10-18/00:00') then begin
; 	e0=2.6 & 	scale1 = 1.0 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161101
	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161103, 
endif

if time gt time_double('2016-10-19/00:00') then begin
;	e0=2.6 & 	scale1 = 1.0 & 	efoldoffset = 4.0	& offset1= 0.0		; off by 1 deg 
;	e0=3.2 & 	scale1 = 0.6 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161102
	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161102, scenario 1 used to estimate scpot variation
endif
if time gt time_double('2016-10-22/00:00') then begin
	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161103, scenario 1, ram horizontal
endif

if time gt time_double('2016-10-25/00:00') then begin
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161206, scenario 1, ram horizontal 5th orbit
endif
if time gt time_double('2016-10-29/00:00') then begin
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161201, scenario 2, ram horizontal 1st orbit
	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20171122, scenario 2, ram horizontal 1st orbit, sza=48, 
endif

if time gt time_double('2016-11-01/00:00') then begin
	e0=3.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161130, scenario 1, ram horizontal 6th orbit
endif

if time gt time_double('2016-11-05/00:00') then begin
	e0=3.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; tbd, scenario 1, ram horizontal 2nd orbit
endif

if time gt time_double('2016-11-08/00:00') then begin
	e0=3.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161129, scenario 1, ram horizontal 5th orbit
endif

if time gt time_double('2016-11-12/00:00') then begin
	e0=3.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161121, scenario 1, ram horizontal
endif

if time gt time_double('2016-11-15/00:00') then begin
	e0=3.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161128, scenario 1, ram horizontal 5th orbit
endif

; 11 periapsis in protect mode 20161116-18 - may increase ion suppression

if time gt time_double('2016-11-18/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20161128, scenario 1, ram horizontal 5th orbit
endif

if time gt time_double('2017-01-31/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170201, scenario 2, ram horizontal all orbits, poor day to check
	e0=2.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170201, scenario 2w/90degnod, ram horizontal all orbits, poor day to check
endif

if time gt time_double('2017-01-09/00:00') then begin
	e0=2.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20171120, scenario 2w/90degnod, ram horizontal all orbits, poor day to check
endif

if time gt time_double('2017-02-14/00:00') then begin
	e0=2.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170228, scenario 2, ram horizontal all orbits, poor day to check
endif

if time gt time_double('2017-03-06/00:00') then begin
	e0=2.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170317, scenario 2, ram horizontal all orbits, 
endif

if time gt time_double('2017-03-09/00:00') then begin
	e0=2.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170317, scenario 2, ram horizontal all orbits, -2.3V=Vsc
endif

if time gt time_double('2017-03-10/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170321, scenario 2, ram horizontal all orbits, -2.3V=Vsc
endif

if time gt time_double('2017-03-11/00:00') then begin
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170320, scenario 2, ram horizontal all orbits, 
endif

if time gt time_double('2017-03-12/00:00') then begin
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170321, scenario 2, ram horizontal all orbits, 
endif

if time gt time_double('2017-03-13/00:00') then begin
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170317, scenario 2, ram horizontal all orbits, -2.1V=Vsc
endif

if time gt time_double('2017-03-15/00:00') then begin
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170317, scenario 2, ram horizontal all orbits, -2.1V=Vsc
endif

if time gt time_double('2017-03-17/00:00') then begin
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20170320, scenario 2, ram horizontal all orbits, -1.7to-2.4V=Vsc
endif

if time gt time_double('2017-03-18/00:00') then begin
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20171117, scenario 2, ram horizontal all orbits, -1.8to-2.5V=Vsc
	e0=3.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked tbd, this should be a better match
endif

if time gt time_double('2017-03-25/00:00') then begin					; checked 20171117, scenario 2, ram horizontal all orbits, -1.3to-2.7V=Vsc
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; split difference, response shifted by 0.8 deg between 4821 and 4822 with periapsis shift????
endif

if time gt time_double('2017-04-01/00:00') then begin					; checked 20171116, scenario 2, sza=64, -1.3to-2.0V=Vsc
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 0.027 
	e0=3.1 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; good agreement
	e0=3.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; good agreement
endif



if time gt time_double('2017-04-15/00:00') then begin
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20171116, scenario 2, ram horizontal 1st orbit
endif

if time gt time_double('2017-04-22/00:00') then begin
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; checked 20171112, scenario 2, ram horizontal 1st orbit
endif

; 17-05-10 to 17-07-11 no low energy periapsis data or s/c charging


if time gt time_double('2017-07-12/00:00') then begin					; checked 20171117, sza=82, scenario 2, ram horizontal 1st orbit, -2.1to-3.3V=Vsc
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is -50 to +75m/s, horizontal winds +/-100m/s
endif

; 17-07-19 to 17-08-14 no low energy periapsis data 

; 20170815 start of deep dip 8
; 20170824   end of deep dip 8

if time gt time_double('2017-08-29/00:00') then begin					; checked 20171026, SZA=81, scenario 2, ram horizontal last orbit, -2.8V=Vsc, 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is 0m/s, horizontal wind is about +100m/s but slopes across periapsis
	e0=0.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 20171027 vertical wind is -50to-150m/s, varies pot of -2.2to-3.0
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s, horizontal wind is about +100m/s but slopes across periapsis
endif

if time gt time_double('2017-08-31/00:00') then begin					; checked 20171026, SZA=80, scenario 1, ram horizontal 3rd orbit, pot=-1.0odd,-2.6Veven, 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is 0m/s, horizontal wind is about +100m/s but slopes across periapsis
	e0=0.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 20171027 vertical wind is -50to-150m/s, varies pot of -2.2to-3.0
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is 0m/s, horizontal wind is about +40m/s +/- 80m/s 
	e0=3.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s, horizontal wind is about +50m/s +/- 50m/s 
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.5		; vertical wind is 0m/s, horizontal wind is about +30m/s +/- 50m/s 
endif

if time gt time_double('2017-09-01/00:00') then begin					; checked 20170929, SZA=104?, scenario 1, ram horizontal first orbit, -2.8V=Vsc, 
;	e0=3.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is   ~0m/s, but scenario 1 odd = even + 60m/s
;	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is -140m/s, but scenario 1 odd = even + 30m/s
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is -100m/s, but scenario 1 odd = even + 40m/s
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; checked 20171026 vertical wind is 0m/s, but scenario 1 odd = even + 40m/s

endif

if time gt time_double('2017-09-09/00:00') then begin					; checked 20171108, SZA=61, scenario 2, ram horizontal first orbit, -2.1 to -2.8V=Vsc, 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is 0m/s
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s, horizontal winds -50 to +75m/s
endif

if time gt time_double('2017-09-16/00:00') then begin					; checked tbd, SZA=?, scenario 2, ram horizontal first orbit, -2.8V=Vsc, 
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; checked tbd vertical wind is 0m/s
endif

if time gt time_double('2017-09-19/00:00') then begin					; checked 20171108, SZA=61, scenario 2, ram horizontal first orbit, -2.1 to -2.8V=Vsc, 
	e0=2.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is 0m/s
	e0=3.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s, horizontal winds -50 to +75m/s
endif

if time gt time_double('2017-10-01/00:00') then begin					; checked 20171020, SZA=40, scenario 2, ram horizontal first orbit, -2.0V=Vsc, 
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is -30m/s, deflection before correction is 3.5 deg - why so large?

endif

if time gt time_double('2017-10-07/00:00') then begin					; checked 20171020, SZA=40, scenario 2, ram horizontal first orbit, -2.0V=Vsc, 
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is -30m/s, deflection before correction is 3.5 deg - why so large?
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.5		; vertical wind is 0m/s, deflection before correction is 3.5 deg - why so large?
endif

if time gt time_double('2017-10-11/00:00') then begin					; checked 20171106, SZA=35, scenario 2, ram horizontal first orbit, -1.1 to -2.3V=Vsc, APP pointing off by 0.7deg for ram horizontal
	e0=2.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is 0m/s, deflection before correction is 2.5-3.5 deg 
	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s, deflection before correction is 2.5-3.5 deg 
endif

if time gt time_double('2017-10-14/00:00') then begin					; checked 20171028, SZA=30, just before deep dip fly-Y, -1.2to-2.9V=Vsc, both give similar result
	e0=2.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is 0m/s, horizontal wind varies from -50m/s to +50m/s
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s, horizontal wind varies from -50m/s to +50m/s

endif

; 20171015 start of deep dip 8

if time gt time_double('2017-10-15/00:00') then begin					; checked 2017103, SZA=30, no vertical wind, just before deep dip fly-Y, -1.2to-2.0V=Vsc, both give similar result
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; horizontal wind varies from -100m/s to +70m/s
endif

if time gt time_double('2017-10-16/00:00') then begin					; not checked 
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.5		; 
endif

if time gt time_double('2017-10-17/00:00') then begin					; checked 20171028, SZA=29, deep dip fly-Z, -0.2V=Vsc, 
;	e0=0.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.5		; horizontal wind varies from -100m/s to +200m/s
endif

; 20171023 end of deep dip 8

if time gt time_double('2017-10-28/00:00') then begin					; checked 20171106, SZA=17, -1.5 to -2.0V = Vsc, 
;	e0=3.1 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is 0m/s,
	e0=3.6 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s,
endif

if time gt time_double('2017-11-01/00:00') then begin					; checked 20171106, SZA=17, -1.4 to -1.9V = Vsc, 
	e0=3.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s,
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is 0m/s,
endif

if time gt time_double('2017-11-07/00:00') then begin					; checked 20171116, SZA=18, -1.4 to -2.0V = Vsc, 
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 1.0		; vertical wind is 0m/s,
	e0=3.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s,
endif


if time gt time_double('2017-11-13/00:00') then begin					; checked 20171121, SZA=27, -1.2 to -2.5V = Vsc, 
	e0=3.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s,
endif

if time gt time_double('2017-11-25/00:00') then begin					; checked 20171207, SZA=37, -1.0 to -2.1V = Vsc, 
	e0=3.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s
endif

if time gt time_double('2017-11-28/00:00') then begin					; checked 20171207, SZA=33, -1.0 to -2.5V = Vsc, 
	e0=3.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s is poorly determined
endif

if time gt time_double('2017-12-12/00:00') then begin					; checked 20171231, SZA=70 rapidly changing, -1.0 to -1.5V = Vsc, 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s is poorly determined
endif

if time gt time_double('2017-12-23/00:00') then begin					; checked 20180119, SZA=85? rapidly changing, -1.0 to -1.5V = Vsc, 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is 0m/s is poorly determined
endif

if time gt time_double('2018-01-06/00:00') then begin					; checked 20180119, SZA=100 rapidly changing, -0.6 to -1.3V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is poorly determined
endif

if time gt time_double('2018-01-24/00:00') then begin					; checked 20180206, SZA=120 rapidly changing, -0.3 to -1.0V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is poorly determined - but horizional winds average near zero for smooth conditions
endif

if time gt time_double('2018-02-13/00:00') then begin					; checked 20180421, SZA=130 rapidly changing, -0.3 to -0.7V = Vsc, 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is ok determined on last periapsis
endif

if time gt time_double('2018-02-17/00:00') then begin					; checked 20180421, SZA=130 rapidly changing, -0.3 to -0.7V = Vsc, 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is ok determined on all periapsis
endif

if time gt time_double('2018-03-03/00:00') then begin					; checked 20180421, SZA=90 rapidly changing, -0.2 to -0.4V = Vsc, 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 1 vertical wind is is 0m/s in att=2 well determined 
endif

;if time gt time_double('2018-03-10/00:00') then begin					; checked 20180321, SZA=110 rapidly changing, -0.3 to -1.0V = Vsc, 
;	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is poorly determined - but horizional winds average near zero for smooth conditions
;endif

if time gt time_double('2018-03-17/00:00') then begin					; checked 20180420, SZA=90 rapidly changing, -0.2 to -1.0V = Vsc, 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is is 0m/s in att=2,3 state well determined on inbound
endif

if time gt time_double('2018-03-21/00:00') then begin					; checked 20180421, SZA=100 rapidly changing, -0.4 to -1.0V = Vsc, 
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is is 0m/s on average in att=2,3 state well determined on inbound
endif

if time gt time_double('2018-03-24/00:00') then begin					; checked 20180420, SZA=90 rapidly changing, -0.2 to -1.0V = Vsc, 
	e0=2.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; vertical wind is is 0m/s in att=2,3 state well determined on inbound
endif

;********************************************************************************************
; it is likely that the below e0 values are incorrect due to drifts - no vert_drift=0 calib
;********************************************************************************************

if time gt time_double('2018-04-01/00:00') then begin					; checked 20180406, SZA=90 rapidly changing, -0.3 to -1.3V = Vsc, 
	e0=2.7 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 
	e0=2.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assume horiz wind is zero in att=3 state at periapsis where counts are high
endif

if time gt time_double('2018-04-05/00:00') then begin					; checked 20180423, SZA=? rapidly changing, -0.3 to -1.3V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assume horiz wind is zero in att=3 state at periapsis where counts are high
endif

if time gt time_double('2018-04-09/00:00') then begin					; checked 20180423, SZA=? rapidly changing, -0.3 to -1.3V = Vsc, 
	e0=2.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		
	e0=3.1 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assume horiz wind is zero in att=3 state at periapsis where counts are high
endif


if time gt time_double('2018-04-14/00:00') then begin					; checked 20180406, SZA=? rapidly changing, -0.3 to -1.3V = Vsc, 
	e0=2.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 
	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assume horiz wind is zero in att=3 state at periapsis where counts are high
endif

if time gt time_double('2018-04-16/00:00') then begin					; checked 20180421, SZA=65 rapidly changing, -0.3 to -0.7V = Vsc, 
	e0=2.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		;
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assumed horiz wind was zero in att=3 for the periapsis that minimizes e0
endif

;********************************************************************************************
; it is likely that deep dip 9 changes e0 values - no vert_drift=0 calib
;********************************************************************************************

; 2018-04-24		deep dip 9 begins

if time gt time_double('2018-04-24/00:00') then begin					; checked 20180425, SZA=55 rapidly changing, -0.1 to -1.0V = Vsc, 
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assumed horiz wind was roughly zero in att=3 
endif

if time gt time_double('2018-04-26/00:00') then begin					; checked 20180509, SZA=55 rapidly changing, -0.1 to -1.0V = Vsc, 
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assumed horiz wind was roughly zero in att=3 
endif

if time gt time_double('2018-04-29/00:00') then begin					; checked 20180510, SZA=52 rapidly changing, -0.1 to -1.0V = Vsc, 
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assumed horiz wind was roughly zero in att=3, e0 might be 3.0 
endif

; 2018-05-01		deep dip 9 ends

if time gt time_double('2018-05-01/00:00') then begin					; checked 20180507, SZA=55 rapidly changing, -0.1 to -1.0V = Vsc, 
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assumed horiz wind was roughly zero in att=3 
endif

if time gt time_double('2018-05-01/00:00') then begin					; checked 20180509, SZA=55 rapidly changing, -0.2 to -0.8V = Vsc, 
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		;  
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assumed horiz wind was roughly zero in att=3 
endif

if time gt time_double('2018-05-04/00:00') then begin					; checked 20180523, SZA=49 rapidly changing, -0.1 to -0.4V = Vsc, 
;	e0=4.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; assumed 2018-05-08 calibration was correct
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assumed horiz wind was roughly zero in att=3 
endif

if time gt time_double('2018-05-05/00:00') then begin					; checked 20180514, SZA=55 rapidly changing, -0.2 to -0.5V = Vsc, 
	e0=3.1 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assumed horiz wind was roughly zero in att=3 
endif

if time gt time_double('2018-05-07/00:00') then begin					; checked 20180512, SZA=50 rapidly changing, -0.1 to -0.1V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assumed horiz wind was roughly zero in att=3 
endif

;********************************************************************************************
; it is likely that the above e0 values are incorrect starting some time during deep dip 9
;********************************************************************************************

if time gt time_double('2018-05-08/00:00') then begin					; checked 20180514, SZA=42 rapidly changing, -0.1 to -0.3V = Vsc, 
	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal last orbit, assumed vert wind was zero in att=3 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal last orbit, assumed vert wind was zero in att=3 
	e0=3.9 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal last orbit, assumed vert wind was zero in att=3 
	e0=4.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal last orbit, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-05-10/00:00') then begin					; checked 20180514, SZA=42 rapidly changing, -0.1 to -0.3V = Vsc, 
;	e0=3.2 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; poorly determined, assumed horiz wind was roughly zero in att=3 
endif

if time gt time_double('2018-05-11/00:00') then begin					; checked 20180517?, SZA=45 rapidly changing, -0.1 to -0.3V = Vsc, 
	e0=4.1 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal first orbit, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-05-12/00:00') then begin					; checked 20180517, SZA=45 rapidly changing, -0.1 to -0.3V = Vsc, 
	e0=4.1 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal first orbit, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-05-18/00:00') then begin					; checked 20180517, SZA=45 rapidly changing, -0.3 to -1.0V = Vsc, 
	e0=4.1 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1 orbit, assumed vert wind was zero in att=3 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1 orbit, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-05-22/00:00') then begin					; checked 20180517, SZA=? rapidly changing, -? to -?V = Vsc, 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1 orbit, ok determined, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-05-26/00:00') then begin					; checked 20180604, SZA=? rapidly changing, -1.0 to -2.7V = Vsc, 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, ok determined, assumed vert wind was zero in att=3 
	e0=3.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, ok determined, assumed vert wind was zero in att=3 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.5		; ram horizontal 1st orbit, ok determined, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-05-29/00:00') then begin					; checked 20180603, SZA=? rapidly changing, -? to -?V = Vsc, 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 5th orbit, ok determined, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-06-01/00:00') then begin					; checked 20180608, SZA=54 rapidly changing, -2 to -4V = Vsc, 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 4th orbit, ok determined, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-06-05/00:00') then begin					; checked 20180tbd, SZA=? rapidly changing, -? to -?V = Vsc, 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 5th orbit, ok determined, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-06-12/00:00') then begin					; checked 20190105, SZA=67 rapidly changing, -2 to -4V = Vsc, 
	e0=3.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 6th orbit, ok determined, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-06-19/00:00') then begin					; checked 20180tbd, SZA=? rapidly changing, -? to -?V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 5th orbit, ok determined, assumed vert wind was zero in att=3 
endif

if time gt time_double('2018-06-22/00:00') then begin					; checked 20180702, SZA=? rapidly changing, -? to -?V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 5th orbit, ok determined, assumed vert wind was zero in att=3 
endif



; may want to redo these nightside passes - e0 may be 3.0 for all these, there appear to be gradients in upward flows - or e0 is changing

if time gt time_double('2018-07-21/00:00') then begin					; checked 20180810, SZA=1?? rapidly changing, -.7 to -1,3V = Vsc, 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 2nd orbit, poorly determined, assumed vert wind was zero in att=2 
endif

if time gt time_double('2018-07-24/00:00') then begin					; checked 20180724, SZA=120 rapidly changing, -.7 to -1,3V = Vsc, 
;	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 6th orbit, poorly determined, assumed vert wind was zero in att=1 
endif

if time gt time_double('2018-07-27/00:00') then begin					; checked 20180810, SZA=134 rapidly changing, -.7 to -1,3V = Vsc, 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 6th orbit, poorly determined, assumed vert wind was zero in att=2 
endif

if time gt time_double('2018-07-31/00:00') then begin					; checked 20180806, SZA=140 rapidly changing, -.7 to -1,3V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 5th orbit, poorly determined, assumed vert wind was zero in att=2 
endif

if time gt time_double('2018-08-02/00:00') then begin					; checked 20180815, SZA=114 rapidly changing, -.7 to -2V = Vsc, 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal all orbits, poorly determined, assumed vert wind was zero in att=2 
endif

if time gt time_double('2018-08-08/00:00') then begin					; checked 20180813, SZA=151 rapidly changing, -.7 to -1,3V = Vsc, 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal even orbits, poorly determined, assumed vert wind was zero in att=2 
endif

if time gt time_double('2018-08-10/00:00') then begin					; checked 20180813, SZA=156 rapidly changing, -.7 to -1,3V = Vsc, 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal even orbits, poorly determined, assumed vert wind was zero in att=2 
endif

if time gt time_double('2018-08-31/00:00') then begin					; checked 20180912, SZA=154 rapidly changing, -.1 to -.3V = Vsc, 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; no ram horizontal, poorly determined, assumed horizontal wind roughly zero in att=2 
endif

if time gt time_double('2018-09-01/00:00') then begin					; checked 20180919, SZA=154 rapidly changing, -.1 to -.3V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal last orbit, poorly determined, assumed vertical wind roughly zero in att=1-2 
endif

if time gt time_double('2018-09-04/00:00') then begin					; checked 20180918, SZA=154 rapidly changing, -.1 to -.3V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal last orbit, poorly determined, assumed vertical wind roughly zero in att=1-2 
endif

if time gt time_double('2018-09-08/00:00') then begin					; checked 20180918, SZA=154 rapidly changing, -.1 to -.3V = Vsc, 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; large vertical wind, poorly determined 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, determined ok, assumed vertical wind roughly zero in att=1 
endif

if time gt time_double('2018-09-12/00:00') then begin					; checked 20181007, SZA=143 rapidly changing, -.1 to -.3V = Vsc, 
	e0=1.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 
	e0=3.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; 
	e0=4.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, determined ok, assumed vertical wind roughly zero in att=1
	e0=1.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; this value for e0 is probably better for att=2, see note below
endif

; Notes: it appears that e0 is attenuator state dependent and this approximation of a single e0 is probably wrong

if time gt time_double('2018-09-15/00:00') then begin					; checked 20181006, SZA=137 rapidly changing, -.1 to -.3V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; bad fit, determined ok, assumed vertical wind roughly zero in att=1 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, determined ok, assumed vertical wind roughly zero in att=2
	e0=1.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, determined ok, assumed vertical wind roughly zero in att=2
endif


if time gt time_double('2018-09-18/00:00') then begin					; checked 20181005, SZA=135 rapidly changing, -.1 to -.9V = Vsc, 
	e0=3.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal last orbit, not zero, assumed vertical wind roughly zero in att=2 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal last orbit, determined ok, assumed vertical wind roughly zero in att=2 
endif

if time gt time_double('2018-09-22/00:00') then begin					; checked 20181006, SZA=130 rapidly changing, -.2 to -.2V = Vsc, 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit,  
	e0=2.4 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, determined ok, assumed vertical wind roughly zero in att=2
endif

if time gt time_double('2018-09-29/00:00') then begin					; checked 20181005, SZA=125 rapidly changing, -.1 to -.3V = Vsc, 
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, determined ok, assumed vertical wind roughly zero in att=2 
endif

if time gt time_double('2018-10-05/00:00') then begin					;  
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; asssume same as 20181006 in att=2 
endif

if time gt time_double('2018-10-06/00:00') then begin					; checked 20181015, SZA=109 rapidly changing, -.1 to -.9V = Vsc, 
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, determined ok, assumed vertical wind roughly zero in att=2 
endif

if time gt time_double('2018-10-09/00:00') then begin					; checked 20181021, SZA=109 rapidly changing, -.1 to -.9V = Vsc, 
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, determined ok, assumed vertical wind roughly zero in att=2 
	e0=2.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 5th orbit, determined ok, assumed vertical wind roughly zero in att=2 
endif

if time gt time_double('2018-11-07/00:00') then begin					; checked tbd, SZA=98, s/c potential alternating on even/odd orbits scenario 1, 
	e0=2.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; tbd ram horizontal 1th orbit, ok determination, assumed vertical wind roughly zero in att=3 
endif


if time gt time_double('2018-11-02/00:00') then begin					; checked 20181130, SZA=99, s/c pot ~ -0.4 to -2.2 
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 6th orbit, ok determination, assumed vertical wind zero in att=2,3 
endif

if time gt time_double('2018-11-13/00:00') then begin					; checked 20181129, SZA=99, s/c pot ~ -0.2 to -2.0 
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 2nd orbit, ok determination, assumed vertical wind zero in att=2,3 
endif

if time gt time_double('2018-11-17/00:00') then begin					; checked 20181129, SZA=100, s/c pot ~ -0.3 
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 2nd orbit, ok determination, assumed vertical wind zero in att=2,3 
endif

if time gt time_double('2018-11-20/00:00') then begin					; checked 20181128, SZA=102, s/c pot ~ -0.5 
	e0=2.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		;  
	e0=2.0 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		;  
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 6th orbit, ok determination, assumed vertical wind roughly zero in att=2 
endif

if time gt time_double('2018-12-18/00:00') then begin					; checked 20190102, SZA=130, s/c pot ~ -0.1-1.0 
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 3 orbits, poor determination, assumed vertical wind roughly zero in att=2 
endif


if time gt time_double('2019-01-02/00:00') then begin					; checked 20190116, SZA=148, s/c pot ~ -0.3 
	e0=2.3 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		;  
	e0=2.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 6 orbits, ok determination, assumed vertical wind roughly zero in att=2 
endif

if time gt time_double('2019-01-25/00:00') then begin					; checked 20190116, SZA=148, s/c pot ~ -0.3 
;	e0=2.8 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 5 orbits, no determination in att=1,2 
endif


if time gt time_double('2019-02-05/00:00') then begin					; checked 20190218, SZA=161, s/c pot ~ -0.3 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 4 orbits, att=1,2
endif

if time gt time_double('2019-02-05/00:00') then begin					; checked 20190226, SZA=130, s/c pot ~ -0.3 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; no ram horizontal, assume roughly zero in att=1,2
endif

;**************************************************************************************************************************************************
; 2019-02-11  aerobraking begins - no ram horizontal data until 19-05-01
; e0 offsets will have to be estimated by assuming winds are near zero - which is not accurate near the terminator
;**************************************************************************************************************************************************

if time gt time_double('2019-02-13/00:00') then begin					; checked 20190220, SZA=150, s/c pot ~ -0.1 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; no ram horizontal, att=1,2 assume wind~0
endif

if time gt time_double('2019-09-18/00:00') then begin					; checked 20190926, SZA=38, s/c pot ~ -2-3V 
	e0=2.5 & 	scale1 = 0.7 & 	efoldoffset = 4.0	& offset1= 0.0		; ram horizontal 1st orbit, att=3 
endif

; Problem - the offsets for different attenuator states may need sc_pot dependence. For 2018-12-18, the att 1->2 needs to be larger for pot=-.7V


;tplot,['mvn_sta_c6_O2+_lpw_sc_pot_all','mvn_sta_c8_P2_D_ram','mvn_sta_o2+_c8_th','mvn_sta_o2+_c8_vperp','mvn_sta_o2+_wind_along_track','mvn_sta_c6_scpot','mvn_sta_c6_att'],var_label=['orbit_mvn','LT','LAT','sza','alt'],title='MAVEN STATIC



; Starting the end of 20161122 scenario 4b Fly minus-Z will preclude any low altitude data

print, efoldoffset,e0,scale1,offset1

cols=get_colors()
tt=timerange()
store_data,'mvn_sta_offsets',data={x:tt,y:transpose([[e0,efoldoffset,scale1,offset1],[e0,efoldoffset,scale1,offset1]])}
ylim,'mvn_sta_offsets',-1,5,0

return

end