;+
;PROCEDURE:	mvn_sta_get_kk2
;PURPOSE:	
;	Returns kk2 parameter for correcting ion suppression
;INPUT:		
;	time:		dbl		time of data to be returned
;
;KEYWORDS:
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  16/02/08
;MOD HISTORY:
;
;NOTES:	  
;	kk2 ion suppression correction may be limited to times after 20151101
;-
FUNCTION mvn_sta_get_kk2,time

kk2 = 3.5
if time_double(time) lt time_double('2016-01-13') then begin
	kk2= 3.5
endif
if time_double(time) lt time_double('2015-12-30') then begin				; this works for 
	t0 = time_double('2015-12-23')
	t1 = time_double('2015-12-30')
	kk2= 3.5
endif
if time_double(time) lt time_double('2015-12-16') then begin				; this works for 12-09,12-10
	t0 = time_double('2015-12-09')
	t1 = time_double('2015-12-16')
	kk2= 2.5 + (-4.0)*(time_double(time)-t0)/(t1-t0)	> 1.5				; works for 20151209-10 and 1.2*ngi_o2_cnts/(500.-45.*(pot<3.))
;	kk2= 3.5
endif
if time_double(time) lt time_double('2015-12-02') then begin				; this works for 11-25,11-30
	t0 = time_double('2015-11-25')
	t1 = time_double('2015-12-02')
	kk2= (3.5 + (-.8)*(time_double(time)-t0)/(t1-t0)) >3.0
;	kk2= 3.8
endif
if time_double(time) lt time_double('2015-11-18') then begin				; this works for 11-11 to 11-18
	t0 = time_double('2015-11-11')
	t1 = time_double('2015-11-18')
	kk2= (3.8 + (-1.6)*(time_double(time)-t0)/(t1-t0)) >3.0
endif
if time_double(time) lt time_double('2015-11-04') then begin				; this works for 11-01 to 11-03
	t0 = time_double('2015-10-28')
	t1 = time_double('2015-11-04')
	kk2= (3.8 + (-1.6)*(time_double(time)-t0)/(t1-t0)) >3.3
;	kk2=3.3
;	if time_double(time) lt time_double('2015-11-01') then kk2=3.8
endif
if time_double(time) lt time_double('2015-10-21') then begin				; this works for 
	t0 = time_double('2015-10-14')
	t1 = time_double('2015-10-21')
	kk2= (4.0 + (-1.0)*(time_double(time)-t0)/(t1-t0)) >3.4
endif
if time_double(time) lt time_double('2015-10-07') then begin				; this works for 
	t0 = time_double('2015-09-30')
	t1 = time_double('2015-10-07')
	kk2= (3.8 + (-1.6)*(time_double(time)-t0)/(t1-t0)) >3.5
;	kk2=3.5
endif
if time_double(time) lt time_double('2015-09-23') then kk2=3.5
if time_double(time) lt time_double('2015-09-09') then kk2=3.8
if time_double(time) lt time_double('2015-08-26') then kk2=4.0
if time_double(time) lt time_double('2015-08-12') then kk2=4.5

if time_double(time) lt time_double('2015-08-10') then kk2=4.5				; works ok   for 20150809

if time_double(time) lt time_double('2015-08-05') then kk2=4.7				; guess

if time_double(time) lt time_double('2015-07-31') then kk2=5.0				; works ok   for 20150730

if time_double(time) lt time_double('2015-07-25') then kk2=5.2				; guess

if time_double(time) lt time_double('2015-07-20') then kk2=5.5				; works ok   for 20150719

if time_double(time) lt time_double('2015-07-16') then kk2=5.5				; guess
if time_double(time) lt time_double('2015-07-13') then kk2=6.0				; guess
if time_double(time) lt time_double('2015-07-10') then kk2=6.5				; guess 

if time_double(time) lt time_double('2015-07-07') then kk2=7.0				; works poorly   20150704 

if time_double(time) lt time_double('2015-06-26') then kk2=6.5				; guess 
if time_double(time) lt time_double('2015-06-16') then kk2=6.0				; guess 
if time_double(time) lt time_double('2015-06-06') then kk2=5.5				; guess 


if time_double(time) lt time_double('2015-05-26') then kk2=5.0				; works ok   for 20150525 on orbits where -1.5V>pot

if time_double(time) lt time_double('2015-04-27') then kk2=5.0				; works ok   for 20150426 on orbits where -1.5V>pot

if time_double(time) lt time_double('2015-03-20') then kk2=4.7				; works ok   for 20150319 on even orbits where -1.5V=pot
if time_double(time) lt time_double('2015-03-13') then kk2=4.7				; works ok   for 20150312 -1.5V=pot
if time_double(time) lt time_double('2015-02-23') then kk2=4.6				; works ok   for 20150222 on even orbits where -1.5V=pot
if time_double(time) lt time_double('2015-02-11') then kk2=4.5				; works well for 20150209


if time_double(time) lt time_double('2015-01-24') then kk2=4.1				; works well for 20150123

if time_double(time) lt time_double('2015-01-19') then kk2=3.6				; works well for 20150118

if time_double(time) lt time_double('2015-01-09') then kk2=3.1				; works well for 20150108

if time_double(time) lt time_double('2015-01-03') then kk2=3.0				; works well for 20150102

if time_double(time) lt time_double('2014-12-26') then kk2=2.5				; guess

if time_double(time) lt time_double('2014-12-21') then kk2=2.0				; works well for 20141220

if time_double(time) lt time_double('2014-12-15') then kk2=1.5				; guess

;if time_double(time) lt time_double('2014-12-10') then kk2=1.0				; works well for 20141209, check this later

if time_double(time) lt time_double('2014-12-01') then kk2=1.5				; works well for 20141130

if time_double(time) lt time_double('2014-11-27') then kk2=0.5				; guess

if time_double(time) lt time_double('2014-11-17') then kk2=0.				; attE is leaking - no obvious ion suppression


return,kk2

end
