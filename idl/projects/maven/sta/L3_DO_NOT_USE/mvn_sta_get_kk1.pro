;+
;PROCEDURE:	mvn_sta_get_kk1
;PURPOSE:	
;	Returns kk1 - a 4 element array for correcting ion suppression as a function of attenuator state
;INPUT:		
;	time:		dbl		time of data to be returned
;
;KEYWORDS:
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  19/06/14
;MOD HISTORY:
;
;NOTES:	  
;	this function was derived from mvn_sta_get_kk3.pro
;-
FUNCTION mvn_sta_get_kk1,time

common mvn_sta_kk1,kk1,kk1_trange
common mvn_sta_kk3_anode, kk3_anode

; default

kk1 = [1.0,1.0,1.0,1.0]
kk3_anode=1


if time_double(time) gt time_double('2015-11-12/00:00') then kk1 = [4.0,3.8,4.0,3.8]	; 2 ngims, ok agreement, 20180919


if time_double(time) gt time_double('2015-11-16/00:00') then kk1 = [3.7,3.6,3.6,3.0]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw
if time_double(time) gt time_double('2015-11-16/00:00') then kk1 = [3.7,3.5,3.6,3.0]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw


if time_double(time) gt time_double('2016-03-22/00:00') then kk1 = [4.0,3.8,4.0,3.8]		; way too large
if time_double(time) gt time_double('2016-03-22/00:00') then kk1 = [3.0,2.8,2.8,1.7]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw
if time_double(time) gt time_double('2016-03-22/00:00') then kk1 = [3.3,2.7,3.2,2.2]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw
if time_double(time) gt time_double('2016-03-22/00:00') then kk1 = [3.2,2.9,3.1,2.4]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw
if time_double(time) gt time_double('2016-03-22/00:00') then kk1 = [3.2,3.1,3.1,2.5]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw

if time_double(time) gt time_double('2016-03-25/00:00') then kk1 = [3.4,2.9,3.2,2.5]		; sta O2 ok, 3 ngims, checked 20171126, sza=70

if time_double(time) gt time_double('2016-04-09/00:00') then kk1 = [3.0,2.8,2.8,1.7]		; sta O2 ok, 3 ngims, checked 20171123, sza=?

if time_double(time) gt time_double('2016-04-19/00:00') then kk1 = [3.0,2.8,2.8,1.7]		;**sta o2+ ok, 3 ngims, checked 20190521, no lpw?

if time_double(time) gt time_double('2016-05-25/00:00') then kk1 = [3.0,2.2,2.8,1.8]		; sta O2 low, 3 ngims, checked 20180330, sza=75

; Attenuator open for 6 periapsis passes starting 20160526
if time_double(time) gt time_double('2016-05-27/00:00') then kk1 = [3.6,3.2,3.5,2.8]		; assume same as 20160529

if time_double(time) gt time_double('2016-05-29/00:00') then kk1 = [3.0,2.2,2.8,1.8]		; sta O2 low, 3 ngims, checked 20180330, sza=75
if time_double(time) gt time_double('2016-05-29/00:00') then kk1 = [3.6,3.2,3.5,2.8]		;**sta o2+ ok, 3 ngims, checked 20190521, lpw?

;********************************************************************************************************************************************************
;  Nightside periapsis starts	20160615 (ended 20160915)


if time_double(time) gt time_double('2016-06-16/00:00') then kk1 = [3.0,2.2,2.8,1.8]		; sta O2 ok, 3 ngims, checked 20171123, sza=?

if time_double(time) gt time_double('2016-07-16/00:00') then kk1 = [3.2,1.7,2.8,1.5]		; sta O2 ok, 3 ngims, checked 20171123, sza=150

;*********************************************************************************************************************************************************
; 2016-07-26  start deep dip 6

if time_double(time) gt time_double('2016-07-31/00:00') then kk1 = [3.2,1.7,2.8,1.5]		; sta O2 ok, 3 ngims, checked 20190228, sza=165
if time_double(time) gt time_double('2016-07-31/00:00') then kk1 = [3.2,2.0,3.1,2.0]		; sta O2 ok, 3 ngims, checked 20190228, sza=165


; 2016-08-04  end deep dip 6
;*********************************************************************************************************************************************************

if time_double(time) gt time_double('2016-08-24/00:00') then kk1 = [2.8,2.0,2.8,1.5]		; sta o2 ok, 3 ngims, checked 20171123 sza=?

if time_double(time) gt time_double('2016-08-28/00:00') then kk1 = [2.8,2.0,2.8,1.5]		; sta O2 ok, 3 ngims, checked 20171122 sza=130

if time_double(time) gt time_double('2016-09-10/00:00') then kk1 = [2.3,1.8,2.3,1.5]		; tbd
if time_double(time) gt time_double('2016-09-10/00:00') then kk1 = [2.5,1.8,2.5,1.7]		; sta O2 ok, 3 ngims, checked 20171124

;  Nightside periapsis ends	20160915 (started 20160615)
;********************************************************************************************************************************************************

if time_double(time) gt time_double('2016-09-17/00:00') then kk1 = [2.5,1.8,2.5,1.7]		; 
if time_double(time) gt time_double('2016-09-17/00:00') then kk1 = [1.7,1.4,1.6,1.3]		;**sta o2+ ok, 2 ngims, checked 20190521, lpw?


if time_double(time) gt time_double('2016-09-24/00:00') then kk1 = [1.9,1.6,1.8,1.5]		; sta O2 ok, 2 ngims, checked 20171122 sza=87

if time_double(time) gt time_double('2016-09-27/00:00') then kk1 = [1.9,1.6,1.8,1.5]		; sta O2 ok, 3 ngims, checked 20171122 sza=83

;scenario 1 2016-10-04

if time_double(time) gt time_double('2016-10-05/00:00') then kk1 = [1.9,1.6,1.8,1.5]		; sta O2 ok, 5 ngims, 
if time_double(time) gt time_double('2016-10-05/00:00') then kk1 = [1.4,1.1,1.3,1.0]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V, no lpw
if time_double(time) gt time_double('2016-10-05/00:00') then kk1 = [1.7,1.4,1.6,1.3]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V, no lpw

if time_double(time) gt time_double('2016-10-06/00:00') then kk1 = [1.9,1.6,1.8,1.5]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V

if time_double(time) gt time_double('2016-10-07/00:00') then kk1 = [1.9,1.6,1.8,1.5]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V
if time_double(time) gt time_double('2016-10-07/00:00') then kk1 = [1.7,1.4,1.6,1.3]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V

if time_double(time) gt time_double('2016-10-09/00:00') then kk1 = [1.7,1.4,1.6,1.3]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V

;if time_double(time) gt time_double('2016-10-29/00:00') then kk1 = [2.5,2.1,2.3,2.0]		; old
;if time_double(time) gt time_double('2016-10-29/00:00') then kk1 = [2.2,1.9,2.1,1.8]		; sta O2 ok, 3 ngims, checked 20171122
;if time_double(time) gt time_double('2016-10-29/00:00') then kk1 = [1.2,1.1,1.3,1.0]		; sta O2 ok, 3 ngims, checked 20171122
if time_double(time) gt time_double('2016-10-29/00:00') then kk1 = [1.9,1.6,1.8,1.5]		; sta O2 ok, 3 ngims, checked 20171122

;if time_double(time) gt time_double('2016-11-20/00:00') then kk1 = [2.6,2.3,2.5,2.2]		; old, 3 ngims, checked 20171120
if time_double(time) gt time_double('2016-11-20/00:00') then kk1 = [2.2,1.9,2.1,1.8]		; sta O2 ok, 3 ngims, checked 20171120

if time_double(time) gt time_double('2016-12-01/00:00') then kk1 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, ? ngims, checked 20190520

; s/c charging from 20161122 to 20170131





;if time_double(time) gt time_double('2017-02-09/00:00') then kk1 = [3.5,3.0,3.0,1.8]		; sta O2+ 14% high, 3 ngims, checked 20171120, sza=112, -0.8 to -2.2V
;if time_double(time) gt time_double('2017-02-09/00:00') then kk1 = [2.2,2.0,2.0,1.0]		; sta O2+ closer, 3 ngims, checked 20171120
if time_double(time) gt time_double('2017-02-09/00:00') then kk1 = [2.3,1.8,2.3,0.0]		; sta O2+ ok , 3 ngims, checked 20171120

if time_double(time) gt time_double('2017-02-16/00:00') then kk1 = [2.3,1.8,2.3,0.0]		; ok O2+ ok, 3 ngims, checked 20171120


if time_double(time) gt time_double('2017-03-01/00:00') then kk1 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, 3 ngims, checked 20190519

if time_double(time) gt time_double('2017-03-02/00:00') then kk1 = [2.2,2.0,2.0,1.0]		; ok O2+ poorly determined, 3 ngims, checked 20171117, sza=97

;if time_double(time) gt time_double('2017-03-07/00:00') then kk1 = [3.5,3.0,3.0,2.0]		; ok O2+ O+, 3 ngims, checked 20170307
if time_double(time) gt time_double('2017-03-07/00:00') then kk1 = [2.2,2.0,2.0,1.0]		; ok O2+ O+, 3 ngims, checked 20171117, sza=94

;if time_double(time) gt time_double('2017-03-15/00:00') then kk1 = [3.5,3.0,3.0,2.0]		; ok O2+ O+, 3 ngims, checked 20170324

if time_double(time) gt time_double('2017-03-18/00:00') then kk1 = [3.5,3.0,3.0,2.0]		; sta O2+ 20% high, 3 ngims, checked 20171117
if time_double(time) gt time_double('2017-03-18/00:00') then kk1 = [2.2,2.0,2.0,1.0]		; sta O2+ 10% high, 3 ngims, checked 20171117
if time_double(time) gt time_double('2017-03-18/00:00') then kk1 = [1.2,1.0,1.0,0.0]		; sta O2+ ok, 3 ngims, checked 20171117
if time_double(time) gt time_double('2017-03-18/00:00') then kk1 = [2.0,1.5,1.0,0.0]		; sta O2+ ok, 3 ngims, checked 20171117

if time_double(time) gt time_double('2017-03-22/00:00') then kk1 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, 3 ngims, checked 20190519

if time_double(time) gt time_double('2017-03-25/00:00') then kk1 = [2.0,1.5,1.0,0.0]		; sta O2+ ok, 3 ngims, checked 20171117, sza=73
if time_double(time) gt time_double('2017-03-25/00:00') then kk1 = [2.0,1.5,1.5,0.5]		; sta O2+ ok, 3 ngims, checked 20171117



if time_double(time) gt time_double('2017-04-01/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta O2+ 10% high, 2 ngims, checked 20171116, sza=48
if time_double(time) gt time_double('2017-04-01/00:00') then kk1 = [2.2,2.0,2.0,1.0]		; sta O2+ ok, 2 ngims, checked 20171116, sza=63
if time_double(time) gt time_double('2017-04-01/00:00') then kk1 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, 3 ngims, checked 20190519


if time_double(time) gt time_double('2017-04-15/00:00') then kk1 = [3.5,3.0,3.0,2.0]		; sta O2+ 20% high, 2 ngims, checked 20171113, sza=29
if time_double(time) gt time_double('2017-04-15/00:00') then kk1 = [2.2,2.0,2.2,1.0]		; sta O2+  6%  low, 2 ngims, checked 20171113, sza=29
if time_double(time) gt time_double('2017-04-15/00:00') then kk1 = [2.5,2.3,2.5,1.3]		; sta O2+  6%  low, 2 ngims, checked 20171113, sza=29
if time_double(time) gt time_double('2017-04-15/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta O2+ ok, 2 ngims, checked 20171116, sza=48


;if time_double(time) gt time_double('2017-04-22/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta O2+ 10% low, 3 ngims, checked 20171117, sza=41
if time_double(time) gt time_double('2017-04-22/00:00') then kk1 = [2.2,2.0,2.2,1.0]		; sta O2+ ok, 3 ngims, checked 20171117, sza=41

if time_double(time) gt time_double('2017-05-01/00:00') then kk1 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, 2 ngims, checked 20190518


;if time_double(time) gt time_double('2017-05-03/00:00') then kk1 = [3.5,3.0,3.0,2.0]		; this used to work, 
;if time_double(time) gt time_double('2017-05-03/00:00') then kk1 = [1.2,1.0,1.0,0.0]		; sta O2+ too small, 
;if time_double(time) gt time_double('2017-05-03/00:00') then kk1 = [2.2,2.0,2.0,1.0]		; sta O2+ ok, 3 ngims, checked 20171113, sza=36
if time_double(time) gt time_double('2017-05-03/00:00') then kk1 = [2.2,2.0,2.2,1.0]		; sta O2+ ok, 3 ngims, checked 20171113, sza=36



;if time_double(time) gt time_double('2017-05-08/00:00') then kk1 = [2.2,2.0,2.2,1.0]		; sta O2+ 5% high, 3 ngims, checked 20171117, sza=30, -0.4 to -1.0V
if time_double(time) gt time_double('2017-05-08/00:00') then kk1 = [1.9,1.7,1.7,0.5]		; sta O2+ ok, 3 ngims, checked 20171117, sza=30, -0.4 to -1.0V


;if time_double(time) gt time_double('2017-05-09/00:00') then kk1 = [3.5,3.0,3.0,2.0]		; this used to work sta O2+ 40% high , 2 ngims, checked 20171113
;if time_double(time) gt time_double('2017-05-09/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta O2+ 20% high , 2 ngims, checked 20171113, sza=29
;if time_double(time) gt time_double('2017-05-09/00:00') then kk1 = [2.2,2.0,2.0,1.0]		; sta O2+ 10% high , 2 ngims, checked 20171113, sza=29
if time_double(time) gt time_double('2017-05-09/00:00') then kk1 = [1.2,1.0,1.0,0.0]		; sta O2+ ok, 2 ngims, checked 20171113, sza=29

; 17-05-10 to 17-07-11 no low energy periapsis data or s/c charging

if time_double(time) gt time_double('2017-07-12/00:00') then kk1 = [3.5,3.0,3.0,2.0]		; O2+ ok, 3 ngims, checked 20171117

if time_double(time) gt time_double('2017-07-15/00:00') then kk1 = [3.5,3.0,3.0,2.0]		; O2+ ok, 3 ngims, checked 20171115
 

if time_double(time) gt time_double('2017-07-16/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; O2+ ok , 2 ngims, checked 20180802

if time_double(time) gt time_double('2017-07-18/00:00') then kk1 = [3.5,3.0,3.0,2.0]		; too high , 2 ngims, checked 20180802
if time_double(time) gt time_double('2017-07-18/00:00') then kk1 = [2.2,2.0,2.0,1.0]		; , 2 ngims, checked 20180802
if time_double(time) gt time_double('2017-07-18/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; O2+ ok , 2 ngims, checked 20180802




; 17-07-19 to 17-08-14 no low energy periapsis data 

; 17-08-15 deep dip 7

if time_double(time) gt time_double('2017-08-14/00:00') then kk1 = [3.7,3.2,3.2,2.2]		; assume continuous

if time_double(time) gt time_double('2017-08-17/00:00') then kk1 = [3.7,3.2,3.2,2.2]		; ok O2+, O+ is very low, 3 ngims, checked 20171029


if time_double(time) gt time_double('2017-08-19/00:00') then kk1 = [3.8,3.3,3.3,2.3]		; ok O2+, O+ is very low, 3 ngims, checked 20171029

;if time_double(time) gt time_double('2017-08-21/00:00') then kk1 = [3.7,3.2,3.2,2.2]		; ok O2+, O+ is very low, 3 ngims, checked 20171030
if time_double(time) gt time_double('2017-08-22/00:00') then kk1 = [3.7,3.2,3.2,2.2]		; ok O2+, O+ is very low, 3 ngims, checked 20171030

;if time_double(time) gt time_double('2017-08-23/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; O2+ 20% low, O+ is very low, 3 ngims, 
if time_double(time) gt time_double('2017-08-23/00:00') then kk1 = [3.7,3.2,3.2,2.2]		; O2+ ok, O+ is very low, 2 ngims, checked tbd

if time_double(time) gt time_double('2017-08-24/00:00') then kk1 = [3.8,3.3,3.3,2.3]		; ok O2+, O+ is very low, 3 ngims, checked 20171030

;17-08-24 end deep dip 7
; there seems to be a sudden change in ion suppression on 2017-08-25, ion suppression recovery

if time_double(time) gt time_double('2017-08-25/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; O2+ 5% low except 1st orbit is 25% lower??, O+ is very low, 3 ngims, checked 20171003
if time_double(time) gt time_double('2017-08-25/00:00') then kk1 = [3.1,2.6,3.1,2.5]		; **sta o2+ ok, 3 ngims, checked 20190517, gf_update=1.4
if time_double(time) gt time_double('2017-08-25/00:00') then kk1 = [2.9,2.6,2.9,2.3]		; **sta o2+ ok, 3 ngims, checked 20190517, gf_update=1.4
if time_double(time) gt time_double('2017-08-25/00:00') then kk1 = [2.8,2.5,2.8,2.2]		; **sta o2+ ok, 3 ngims, checked 20190517, gf_update=1.4
if time_double(time) gt time_double('2017-08-25/00:00') then kk1 = [2.6,2.3,2.6,2.0]		; **sta o2+ ok, 3 ngims, checked 20190517, gf_update=1.4

if time_double(time) gt time_double('2017-08-29/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; O2+ , O+ is very low, 3 ngims, checked 20171027

if time_double(time) gt time_double('2017-09-01/00:00') then kk1 = [3.1,2.9,3.1,2.5]		;**sta o2+ ok, 3 ngims, checked 20190513
if time_double(time) gt time_double('2017-09-01/00:00') then kk1 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, 3 ngims, checked 20190513

if time_double(time) gt time_double('2017-09-02/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; scenario 1, ok O2+, O+ is very low, 3 ngims, checked 20171002

if time_double(time) gt time_double('2017-09-09/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; ok O2+ maybe a bit low, 2 ngims, checked 20171109


if time_double(time) gt time_double('2017-09-16/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; poor O2+ but lp/sta suggest problem is with ngi, O+ is very low, 3 ngims, checked 20171003

if time_double(time) gt time_double('2017-09-19/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; ok O2+, O+ is very low, 3 ngims, checked 20171108

if time_double(time) gt time_double('2017-10-01/00:00') then kk1 = [3.3,3.1,3.3,2.7]		;**sta o2+ ok, 3 ngims, checked 20190513
if time_double(time) gt time_double('2017-10-01/00:00') then kk1 = [3.1,2.9,3.1,2.5]		;**sta o2+ ok, 3 ngims, checked 20190513, gf_update=1.6
if time_double(time) gt time_double('2017-10-01/00:00') then kk1 = [2.3,2.1,2.3,1.7]		;**sta o2+ ok, 3 ngims, checked 20190513, gf_update=1.4

if time_double(time) gt time_double('2017-10-05/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; 3 ngims, checked 20171020

if time_double(time) gt time_double('2017-10-11/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta o2+ high by 12%, 2 ngims, checked 20171028
;if time_double(time) gt time_double('2017-10-11/00:00') then kk1 = [1.2,1.0,1.0,0.0]		; redue sta o2+ tbd, 2 ngims, checked tbd

if time_double(time) gt time_double('2017-10-14/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; 2 ngims, checked 20171028

if time_double(time) gt time_double('2017-10-15/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; 3 ngims, checked 20171030 

; 17-10-16 start deep dip 8

if time_double(time) gt time_double('2017-10-16/00:00') then kk1 = [3.4,3.2,3.2,2.2]		; not well determined, 3 ngims-saturated, checked 20171030

if time_double(time) gt time_double('2017-10-17/00:00') then kk1 = [3.4,3.2,3.2,2.2]		; not well determined, 3 ngims-saturated, checked 20171028
if time_double(time) gt time_double('2017-10-17/00:00') then kk1 = [3.3,2.4,3.3,2.3]		;**sta o2+ ok, 5 ngims, checked 20190513
if time_double(time) gt time_double('2017-10-17/00:00') then kk1 = [3.3,3.1,3.3,2.7]		;**sta o2+ ok, 5 ngims, checked 20190513, gf_update=1.6
if time_double(time) gt time_double('2017-10-17/00:00') then kk1 = [3.0,2.8,3.0,2.4]		;**sta o2+ ok, 5 ngims, checked 20190513, gf_update=1.4

if time_double(time) gt time_double('2017-10-19/00:00') then kk1 = [3.5,3.3,3.3,2.3]		; not well determined, 3 ngims-saturated, checked 20171029

if time_double(time) gt time_double('2017-10-20/00:00') then kk1 = [3.6,3.4,3.4,2.4]		; not well determined, 3 ngims-saturated, checked 20171028

if time_double(time) gt time_double('2017-10-22/00:00') then kk1 = [3.6,3.4,3.4,2.4]		; not well determined, 3 ngims-saturated, checked 20171028

; 17-08-23 end deep dip 8

if time_double(time) gt time_double('2017-10-24/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; 3 ngims, checked 20171105

if time_double(time) gt time_double('2017-11-01/00:00') then kk1 = [3.3,2.4,3.3,2.3]		;**sta o2+ ok, 5 ngims, checked 20190512, gf_update=1.6
if time_double(time) gt time_double('2017-11-01/00:00') then kk1 = [2.8,1.9,2.8,1.8]		;**sta o2+ ok, 5 ngims, checked 20190514, gf_update=1.4

if time_double(time) gt time_double('2017-11-07/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta o2+ ok - may be 10% high, 3 ngims, checked 20171116

if time_double(time) gt time_double('2017-11-13/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta o2+ 10% high, 6 ngims, checked 20171121
if time_double(time) gt time_double('2017-11-13/00:00') then kk1 = [1.2,1.0,1.0,0.0]		; sta o2+ ok, 3 ngims, checked 20171121

if time_double(time) gt time_double('2017-11-25/00:00') then kk1 = [1.2,1.0,1.0,0.0]		; sta o2+ ok - but 20% high at times, perhaps overcorrecting droop?, 5 ngims, checked 20171208

if time_double(time) gt time_double('2017-11-28/00:00') then kk1 = [1.2,1.0,1.0,0.0]		; sta o2+ ok, 4 ngims, checked 20171207

if time_double(time) gt time_double('2017-12-01/00:00') then kk1 = [3.3,2.4,3.3,2.3]		;**sta o2+ ok, 5 ngims, checked 20190512
if time_double(time) gt time_double('2017-12-01/00:00') then kk1 = [3.1,2.2,3.1,2.1]		;**sta o2+ ok, 5 ngims, checked 20190512, gf_update=1.6
if time_double(time) gt time_double('2017-12-01/00:00') then kk1 = [2.7,2.0,2.5,1.5]		;**sta o2+ ok, 5 ngims, checked 20190514, gf_update=1.4

if time_double(time) gt time_double('2017-12-12/00:00') then kk1 = [1.7,1.5,1.5,0.0]		; sta o2+ ok, 4 ngims, checked 20171207

;if time_double(time) gt time_double('2017-12-23/00:00') then kk1 = [2.2,2.0,2.0,0.5]		; sta o2+ ok, 5 ngims, checked 20180119

if time_double(time) gt time_double('2018-01-01/00:00') then kk1 = [3.3,2.4,3.3,2.3]		;**sta o2+ ok, 5 ngims, checked 20190512
if time_double(time) gt time_double('2018-01-01/00:00') then kk1 = [2.8,1.9,2.8,1.8]		;**sta o2+ ok, 5 ngims, checked 20190514, gf_update=1.4

if time_double(time) gt time_double('2018-01-06/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta o2+ ok, 5 ngims, checked 20180119

if time_double(time) gt time_double('2018-01-24/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta o2+ ok, 5 ngims, checked 20180206, nightside no att=3

;if time_double(time) gt time_double('2018-02-13/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta o2+ ok, 5 ngims, checked 20180421, nightside no att=3
if time_double(time) gt time_double('2018-02-13/00:00') then kk1 = [2.9,2.7,2.7,1.7]		; sta o2+ ok, 5 ngims, checked 20180421, nightside no att=3

if time_double(time) gt time_double('2018-02-17/00:00') then kk1 = [3.1,2.9,2.9,1.9]		; sta o2+ ok, 5 ngims, checked 20180421, nightside no att=3

if time_double(time) gt time_double('2018-03-03/00:00') then kk1 = [3.3,2.9,3.1,2.1]		; sta o2+ ok, 5 ngims, checked 20180421, nightside no att=3

;if time_double(time) gt time_double('2018-03-17/00:00') then kk1 = [3.7,3.0,3.5,2.5]		; sta o2+ ok, 5 ngims, checked 20180420, terminator
;if time_double(time) gt time_double('2018-03-17/00:00') then kk1 = [2.7,2.5,2.5,1.5]		; sta o2+ ok, 5 ngims, checked 20180420, terminator
if time_double(time) gt time_double('2018-03-17/00:00') then kk1 = [3.2,2.7,3.0,2.0]		; sta o2+ ok, 5 ngims, checked 20180420, terminator

;if time_double(time) gt time_double('2018-03-21/00:00') then kk1 = [3.2,2.7,3.0,2.0]		; sta o2+ ok, 6 ngims, checked 20180421, terminator
if time_double(time) gt time_double('2018-03-21/00:00') then kk1 = [3.4,2.9,3.2,2.2]		; sta o2+ ok, 6 ngims, checked 20180421, terminator

if time_double(time) gt time_double('2018-03-24/00:00') then kk1 = [3.7,3.0,3.5,2.5]		; sta o2+ ok, 5 ngims, checked 20180420, terminator

;if time_double(time) gt time_double('2018-03-25/00:00') then kk1 = [3.7,3.5,3.5,2.5]		; sta o2+ ok, 5 ngims, checked 20180330, terminator
if time_double(time) gt time_double('2018-03-25/00:00') then kk1 = [3.7,3.0,3.5,2.5]		; sta o2+ ok, 5 ngims, checked 20180330, terminator

if time_double(time) gt time_double('2018-04-01/00:00') then kk1 = [3.4,2.7,3.2,2.2]		; sta o2+ ok, 6 ngims, checked 20180406, terminator, lpw calib
if time_double(time) gt time_double('2018-04-01/00:00') then kk1 = [3.6,3.1,3.6,3.0]		;** sta o2+ ok, 6 ngims, checked 20180406, terminator, lpw calib
if time_double(time) gt time_double('2018-04-01/00:00') then kk1 = [3.6,2.9,3.6,2.8]		;** sta o2+ ok, 6 ngims, checked 20180406, terminator, lpw calib
if time_double(time) gt time_double('2018-04-01/00:00') then kk1 = [3.1,2.6,3.1,2.5]		;**sta o2+ ok, 3 ngims, checked 20190516, gf_update=1.4

if time_double(time) gt time_double('2018-04-05/00:00') then kk1 = [3.4,2.7,3.2,2.2]		; sta o2+ ok, 6 ngims, checked 20180406, terminator, lpw calib
if time_double(time) gt time_double('2018-04-05/00:00') then kk1 = [3.3,2.6,3.1,2.1]		; sta o2+ ok, 6 ngims, checked 20180406, terminator, lpw calib

;if time_double(time) gt time_double('2018-04-09/00:00') then kk1 = [3.4,2.7,3.2,2.2]		; 
;if time_double(time) gt time_double('2018-04-09/00:00') then kk1 = [3.5,2.7,3.3,2.3]		;  
if time_double(time) gt time_double('2018-04-09/00:00') then kk1 = [3.4,2.7,3.3,2.3]		; sta o2+ ok, 5 ngims, checked 20180423, 

; 20180411-12 are ngims wind measurement so no ngims densities for calibration

if time_double(time) gt time_double('2018-04-14/00:00') then kk1 = [3.2,2.5,2.8,2.4]		; sta o2+ ok, 5 ngims, checked tbd 

;if time_double(time) gt time_double('2018-04-16/00:00') then kk1 = [3.4,2.7,3.2,2.2]		; sta o2+ ok, 5 ngims, checked 20180418, 
;if time_double(time) gt time_double('2018-04-16/00:00') then kk1 = [3.2,2.5,3.0,2.4]		; sta o2+ ok, 5 ngims, checked 20180421, 
if time_double(time) gt time_double('2018-04-16/00:00') then kk1 = [3.2,2.5,2.8,2.4]		; sta o2+ ok, 5 ngims, checked 20180421, 

; start of deep dip 9 18-04-24

if time_double(time) gt time_double('2018-04-24/00:00') then kk1 = [3.0,2.5,2.8,2.4]		; sta o2+ ok, 5 ngims, checked 20180421, 

if time_double(time) gt time_double('2018-04-26/00:00') then kk1 = [3.0,2.5,2.8,2.4]		;  
if time_double(time) gt time_double('2018-04-26/00:00') then kk1 = [3.2,2.7,3.0,2.6]		; sta o2+ ok, 5 ngims, checked 20180509, 

if time_double(time) gt time_double('2018-04-28/00:00') then kk1 = [3.2,2.7,3.0,2.6]		; sta o2+ ok, 5 ngims, checked 20180518, 
if time_double(time) gt time_double('2018-04-28/00:00') then kk1 = [3.3,2.8,3.1,2.7]		; sta o2+ ok, 5 ngims, checked 20180518, 

if time_double(time) gt time_double('2018-04-29/00:00') then kk1 = [3.2,2.7,3.0,2.6]		; sta o2+ ok, 5 ngims, checked 20180510, 
if time_double(time) gt time_double('2018-04-29/00:00') then kk1 = [3.4,2.9,3.2,2.8]		; sta o2+ ok, 5 ngims, checked 20180510, 

if time_double(time) gt time_double('2018-04-30/00:00') then kk1 = [3.4,2.9,3.2,2.8]		; sta o2+ ok, 5 ngims, checked 20180510, 

if time_double(time) gt time_double('2018-05-01/00:00') then kk1 = [3.0,2.5,2.8,2.4]		; sta o2+ ok, 3 ngims, checked 20180507, 
if time_double(time) gt time_double('2018-05-01/00:00') then kk1 = [3.0,2.5,3.0,2.4]		; sta o2+ ok, 3 ngims, checked 20180507, 

; end of deep dip 9 18-05-02 - kk1 is changing on this day

if time_double(time) gt time_double('2018-05-02/00:00') then kk1 = [3.0,2.5,3.0,2.4]		; sta o2+ ok, 3 ngims, checked 20180509, 
if time_double(time) gt time_double('2018-05-02/00:00') then kk1 = [2.8,2.3,2.8,2.2]		; sta o2+ ok, 3 ngims, checked 20180509, 



; Note: either kk1 changes significantly on 2018-05-03 during this day or NGIMS changes

if time_double(time) gt time_double('2018-05-03/00:00') then kk1 = [2.8,2.3,2.8,2.2]		; values dropping during this day
if time_double(time) gt time_double('2018-05-03/00:00') then kk1 = [3.0,2.5,3.0,2.4]		; sta o2+ ok, 3 ngims, checked 201805011

if time_double(time) gt time_double('2018-05-03/00:00') then kk1 = [3.4,2.9,3.4,2.8]		;**sta o2+ ok, 5 ngims, checked 20190506, gf_update=1.6 values for periapsis 3,4 - 0.5 smaller for periapsis 1,2
if time_double(time) gt time_double('2018-05-03/00:00') then kk1 = [3.1,2.6,3.1,2.5]		;**sta o2+ ok, 5 ngims, checked 20190516, gf_update=1.4, variations in ngi/sta ratio with periapsis



if time_double(time) gt time_double('2018-05-04/00:00') then kk1 = [3.0,2.5,3.0,2.4]		; values dropping during this day
if time_double(time) gt time_double('2018-05-04/00:00') then kk1 = [2.8,2.3,2.8,2.2]		; sta o2+ ok, 4 ngims, checked 201805023, optimized for 18:20, orb6994

if time_double(time) gt time_double('2018-05-05/00:00') then kk1 = [3.0,2.5,3.0,2.4]		; values dropping during this day
if time_double(time) gt time_double('2018-05-05/00:00') then kk1 = [2.7,2.2,2.7,2.1]		; sta o2+ ok, 4 ngims, checked 201805014, selected for beginning of the day

if time_double(time) gt time_double('2018-05-06/00:00') then kk1 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, 3 ngims, checked tbd - guess

if time_double(time) gt time_double('2018-05-07/00:00') then kk1 = [3.0,2.5,3.0,2.4]		; sta too high
if time_double(time) gt time_double('2018-05-07/00:00') then kk1 = [2.6,2.1,2.6,2.0]		; sta too high
if time_double(time) gt time_double('2018-05-07/00:00') then kk1 = [2.4,1.9,2.4,1.8]		; sta o2+ ok, 3 ngims, checked 20180512

if time_double(time) gt time_double('2018-05-08/00:00') then kk1 = [2.4,1.9,2.4,1.8]		; sta o2+ ok, 3 ngims, checked 20180512
if time_double(time) gt time_double('2018-05-08/00:00') then kk1 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, 3 ngims, checked 20180512

if time_double(time) gt time_double('2018-05-08/00:00') then kk1 = [3.0,2.5,3.0,2.4]		;** sta o2+ ok, 3 ngims, checked 20190508 for gf_scale=1.6


if time_double(time) gt time_double('2018-05-11/00:00') then kk1 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, 4 ngims, checked 20180517

if time_double(time) gt time_double('2018-05-14/00:00') then kk1 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, 5 ngims, checked 20180518

if time_double(time) gt time_double('2018-05-18/00:00') then kk1 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, 5 ngims, checked 20180523

if time_double(time) gt time_double('2018-05-21/00:00') then kk1 = [2.3,1.1,2.3,1.0]		; sta o2+ ok, ? ngims, checked 20190106

if time_double(time) gt time_double('2018-05-21/00:00') then kk1 = [2.3,1.6,2.3,1.5]		; sta o2+ ok, ? ngims, checked 20180503
if time_double(time) gt time_double('2018-05-21/00:00') then kk1 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, ? ngims, checked 20190106
if time_double(time) gt time_double('2018-05-21/00:00') then kk1 = [2.3,1.1,2.3,1.0]		; sta o2+ ok, ? ngims, checked 20190106

;if time_double(time) gt time_double('2018-05-22/00:00') then kk1 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, ? ngims, checked tbd

; looks like a slight change in ngi/sta density between first and second orbits on 2018-05-25
if time_double(time) gt time_double('2018-05-25/00:00') then kk1 = [2.3,1.6,2.3,1.5]		; sta o2+ ok, ? ngims, checked tbd
if time_double(time) gt time_double('2018-05-25/00:00') then kk1 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, 6 ngims, checked 20180925

if time_double(time) gt time_double('2018-05-26/00:00') then kk1 = [2.3,1.6,2.3,1.5]		; sta o2+ ok, ? ngims, checked tbd
if time_double(time) gt time_double('2018-05-26/00:00') then kk1 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, ? ngims, checked tbd

if time_double(time) gt time_double('2018-05-29/00:00') then kk1 = [2.3,1.6,2.3,1.5]		; sta o2+ ok, 3 ngims, checked 20180603, not well determined, lots of variations, could be winds and scpot variations
if time_double(time) gt time_double('2018-05-29/00:00') then kk1 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, 3 ngims, redue, checked 20180603, not well determined, lots of variations, could be winds and scpot variations

if time_double(time) gt time_double('2018-05-31/00:00') then kk1 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, 3 ngims, checked 20180606

if time_double(time) gt time_double('2018-05-31/00:00') then kk1 = [3.3,2.8,3.3,2.7]		;**sta o2+ ok, 3 ngims, checked 20190506, gf_update=1.6
if time_double(time) gt time_double('2018-05-31/00:00') then kk1 = [2.8,2.3,2.8,2.2]		;**sta o2+ ok, 5 ngims, checked 20190514, gf_update=1.4


if time_double(time) gt time_double('2018-06-01/00:00') then kk1 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, 5 ngims, checked 20180608, 

if time_double(time) gt time_double('2018-06-04/00:00') then kk1 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, 5 ngims, checked 20180608, 

if time_double(time) gt time_double('2018-06-22/00:00') then kk1 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, 3 ngims, checked 20180702,   

if time_double(time) gt time_double('2018-07-17/00:00') then kk1 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, 3 ngims, checked 20180702,   
if time_double(time) gt time_double('2018-07-17/00:00') then kk1 = [2.3,1.1,2.3,1.0]		; sta o2+ ok, 3 ngims, checked 20180702, att=0-2 

if time_double(time) gt time_double('2018-07-21/00:00') then kk1 = [2.3,1.1,2.3,1.0]		; sta o2+ ok, 4 ngims, checked 20180810,  att=0-2, one pass at att=3  

if time_double(time) gt time_double('2018-07-27/00:00') then kk1 = [2.3,1.6,2.3,1.5]		; poor at att=3, 4 ngims, checked 20180810,    
if time_double(time) gt time_double('2018-07-27/00:00') then kk1 = [2.3,1.1,2.3,1.0]		; sta o2+ ok, 4 ngims, checked 20180810,  att=0-2, one pass at att=3  

if time_double(time) gt time_double('2018-07-31/00:00') then kk1 = [2.3,1.1,2.3,1.0]		; sta o2+ ok, 3 ngims, checked 20180806, att=0-2 

if time_double(time) gt time_double('2018-08-02/00:00') then kk1 = [2.3,1.1,2.3,1.0]		; sta o2+ ok, 5 ngims, checked 20180815, att=0-2 

; mechanical attenuator not required for some periapsis passes increasing atomic oxygen exposure

if time_double(time) gt time_double('2018-08-05/00:00') then kk1 = [2.5,1.1,2.5,1.0]		; sta too low, checked 20180813, att=0-2 
if time_double(time) gt time_double('2018-08-05/00:00') then kk1 = [2.5,1.3,2.7,1.2]		; sta o2+ ok, 6 ngims, checked 20180813, att=0-3 

if time_double(time) gt time_double('2018-08-08/00:00') then kk1 = [2.3,1.1,2.3,1.0]		; sta too low, checked 20180813, att=0-2 
if time_double(time) gt time_double('2018-08-08/00:00') then kk1 = [2.7,1.5,2.7,1.4]		; sta o2+ ok, 6 ngims, checked 20180813, att=0-3 

if time_double(time) gt time_double('2018-08-10/00:00') then kk1 = [2.7,1.5,2.7,1.4]		; sta o2+ ok, 5 ngims, checked 20180813, att=0-2 

if time_double(time) gt time_double('2018-08-12/00:00') then kk1 = [2.8,1.8,2.8,1.7]		; sta o2+ ok, 5 ngims, checked 20180820, att=0-2 

if time_double(time) gt time_double('2018-08-14/00:00') then kk1 = [2.8,1.8,2.8,1.7]		; sta o2+ ok, 5 ngims, checked 20180821, att=0-2 

if time_double(time) gt time_double('2018-08-31/00:00') then kk1 = [2.8,1.8,2.8,1.7]		; sta o2+ ok, 5 ngims, checked 20180912, att=0-2 

if time_double(time) gt time_double('2018-09-01/00:00') then kk1 = [2.8,1.8,2.8,1.7]		; sta o2+ ok, 5 ngims, checked 20180920, att=0-2 
if time_double(time) gt time_double('2018-09-01/00:00') then kk1 = [2.9,1.9,2.9,1.8]		; sta o2+ ok, 5 ngims, checked 20180920, att=0-2 

if time_double(time) gt time_double('2018-09-04/00:00') then kk1 = [2.9,1.9,2.9,1.8]		; sta o2+ ok, 1 ngims, checked 20180918, att=0-2 

if time_double(time) gt time_double('2018-09-06/00:00') then kk1 = [2.8,1.8,2.8,1.7]		; , 5 ngims, checked 20180912, att=0-2 
if time_double(time) gt time_double('2018-09-06/00:00') then kk1 = [3.0,2.0,3.0,1.9]		; sta o2+ ok, 5 ngims, checked 20180912, att=0-2 

if time_double(time) gt time_double('2018-09-08/00:00') then kk1 = [3.0,2.0,3.0,1.9]		; sta o2+ ok, 5 ngims, checked 20180918, att=0-2 
if time_double(time) gt time_double('2018-09-08/00:00') then kk1 = [3.1,2.1,3.1,2.0]		; sta o2+ ok, 5 ngims, checked 20180918, att=0-3 

if time_double(time) gt time_double('2018-09-12/00:00') then kk1 = [3.0,2.0,3.0,1.9]		; sta o2+ ok, 1 ngims, checked 20180918, att=0-2 


if time_double(time) gt time_double('2018-09-19/00:00') then kk1 = [3.0,2.0,3.0,1.9]		; sta o2+ ok, 1 ngims, checked 20181003, att=0-2 

if time_double(time) gt time_double('2018-09-22/00:00') then kk1 = [3.0,2.0,3.0,1.9]		; sta o2+ ok, 1 ngims, checked 20181006, att=0-2 

if time_double(time) gt time_double('2018-09-27/00:00') then kk1 = [3.0,2.0,3.0,1.9]		; sta o2+ ok, 1 ngims, checked 20181105, att=0-2 

if time_double(time) gt time_double('2018-09-29/00:00') then kk1 = [3.0,2.0,3.0,1.9]		; sta o2+ poorly determined, 5 ngims, checked 20181005, att=0-2 

if time_double(time) gt time_double('2018-10-06/00:00') then kk1 = [3.0,2.0,3.0,1.9]		; sta o2+ poorly determined, 5 ngims, checked 20181015, att=0-2 

if time_double(time) gt time_double('2018-10-09/00:00') then kk1 = [3.0,2.0,3.0,1.9]		; sta o2+ ok, 3 ngims, checked 20181021, att=0-3 

if time_double(time) gt time_double('2018-10-16/00:00') then kk1 = [3.0,2.0,3.0,1.9]		; sta o2+ ok, 4 ngims, checked 20181024, att=0-3 
if time_double(time) gt time_double('2018-10-16/00:00') then kk1 = [3.0,2.6,3.0,2.5]		; sta o2+ ok, 4 ngims, checked 20181024, att=0-3 

if time_double(time) gt time_double('2018-10-18/00:00') then kk1 = [3.0,2.6,3.0,2.5]		; sta o2+ ngi/sta high at 0V and low at -2V, 6 ngims, checked 20181104, att=0-3 
if time_double(time) gt time_double('2018-10-18/00:00') then kk1 = [3.0,2.6,3.0,1.9]		; sta o2+ ngi/sta high at 0V and low at -2V, 6 ngims, checked 20181104, att=0-3 

if time_double(time) gt time_double('2018-10-19/00:00') then kk1 = [3.0,2.6,3.0,2.5]		; sta o2+ ok, 4 ngims, checked 20181025, att=0-3 
if time_double(time) gt time_double('2018-10-19/00:00') then kk1 = [3.0,2.2,3.0,2.1]		; sta o2+ not well determined, 4 ngims, checked 20181025, att=0-3, ngi/sta ratio in att=2 varies with s/c pot


if time_double(time) gt time_double('2018-11-02/00:00') then kk1 = [2.0,1.5,2.0,1.4]		; tbd sta o2+ ok, 5 ngims, ngi/sta ratio in att=2 varies with s/c pot


if time_double(time) gt time_double('2018-11-07/00:00') then kk1 = [3.0,2.2,3.0,2.1]		; sta o2+ too high, 5 ngims, checked 201811114, att=0-3, sza=98
if time_double(time) gt time_double('2018-11-07/00:00') then kk1 = [2.0,1.1,2.0,1.0]		; sta o2+ too low at 0V, 5 ngims, ngi/sta ratio in att=2 varies with s/c pot
if time_double(time) gt time_double('2018-11-07/00:00') then kk1 = [2.0,1.5,2.0,1.4]		; sta o2+ ok, 5 ngims, ngi/sta ratio in att=2 varies with s/c pot

if time_double(time) gt time_double('2018-11-07/00:00') then kk1 = [3.0,2.7,3.0,2.6]		; sta o2+ ok, 5 ngims, recalculated 20190430 

if time_double(time) gt time_double('2018-11-13/00:00') then kk1 = [3.0,2.3,3.0,2.2]		; sta o2+ ok, 5 ngims, checked tbd
if time_double(time) gt time_double('2018-11-13/00:00') then kk1 = [2.4,1.9,2.4,1.8]		; sta o2+ ok, 5 ngims, checked tbd

if time_double(time) gt time_double('2018-11-17/00:00') then kk1 = [3.0,2.3,3.0,2.2]		; sta o2+ ok, 4 ngims, checked 20181129, ngi/sta ratio in att=2 varies with s/c pot

if time_double(time) gt time_double('2018-11-20/00:00') then kk1 = [2.0,1.5,2.0,1.4]		; 
if time_double(time) gt time_double('2018-11-20/00:00') then kk1 = [2.8,2.1,2.8,2.0]		; 
if time_double(time) gt time_double('2018-11-20/00:00') then kk1 = [3.0,2.3,3.0,2.2]		; sta o2+ ok, 4 ngims, checked 20181128, some avariation with scpot 


if time_double(time) gt time_double('2018-12-18/00:00') then kk1 = [2.8,2.1,2.8,2.0]		; checked 20190102

if time_double(time) gt time_double('2019-01-02/00:00') then kk1 = [3.2,2.1,3.0,2.0]		; checked 20190116

; mech attentuator does not always close at periapsis increasing atomic oxygen exposure in January and raising kk1
 
if time_double(time) gt time_double('2019-01-19/00:00') then kk1 = [3.2,2.1,3.0,2.0]		; checked 20190204
if time_double(time) gt time_double('2019-01-19/00:00') then kk1 = [3.4,2.5,3.3,2.4]		; sta o2+ not well determined, checked 20190204

if time_double(time) gt time_double('2019-01-25/00:00') then kk1 = [3.4,2.5,3.3,2.4]		; sta o2+ not well determined, checked 20190204
if time_double(time) gt time_double('2019-01-25/00:00') then kk1 = [3.2,2.3,3.1,2.2]		; sta o2+ not well determined, checked 20190204

if time_double(time) gt time_double('2019-02-05/00:00') then kk1 = [3.2,2.3,3.1,2.2]		; sta o2+ not well determined, checked 20190218

if time_double(time) gt time_double('2019-02-10/00:00') then kk1 = [3.2,2.3,3.1,2.2]		; sta o2+ ok determined, checked 20190218

if time_double(time) gt time_double('2019-02-12/00:00') then kk1 = [3.2,2.3,3.1,2.2]		; guess - can't cross calibrate - assume changes happen in the first few days of aerobraking
if time_double(time) gt time_double('2019-02-13/00:00') then kk1 = [3.3,2.3,3.2,2.2]		; guess - can't cross calibrate - assume changes happen in the first few days of aerobraking
if time_double(time) gt time_double('2019-02-14/00:00') then kk1 = [3.4,2.3,3.3,2.2]		; guess - can't cross calibrate - assume changes happen in the first few days of aerobraking
if time_double(time) gt time_double('2019-02-15/00:00') then kk1 = [3.5,2.3,3.4,2.2]		; guess - can't cross calibrate - assume changes happen in the first few days of aerobraking


if time_double(time) gt time_double('2019-02-23/00:00') then kk1 = [3.5,2.3,3.4,2.2]		; checked tbd, 

if time_double(time) gt time_double('2019-02-24/00:00') then kk1 = [3.5,2.3,3.4,2.2]		; checked 20190228, ngims background high at periapsis due to high neutral density in sensor

;if time_double(time) gt time_double('2019-02-25/00:00') then kk1 = [3.2,2.3,3.1,2.2]		; checked 20190226
if time_double(time) gt time_double('2019-02-25/00:00') then kk1 = [3.4,2.5,3.3,2.4]		; checked 20190226
if time_double(time) gt time_double('2019-02-25/00:00') then kk1 = [3.5,2.6,3.4,2.5]		; checked 20190226
if time_double(time) gt time_double('2019-02-25/00:00') then kk1 = [3.5,2.3,3.4,2.2]		; checked 20190226, ngims background high at periapsis due to high neutral density in sensor

if time_double(time) gt time_double('2019-02-26/00:00') then kk1 = [3.5,2.3,3.4,2.2]		; checked 20190303, poorly determined

if time_double(time) gt time_double('2019-03-03/00:00') then kk1 = [3.5,2.3,3.4,2.2]		; checked 20190304, ok determined for att=2

if time_double(time) gt time_double('2019-03-18/00:00') then kk1 = [3.2,2.3,3.1,2.2]		; checked 20190325, ok determined for att=1-3
;if time_double(time) gt time_double('2019-03-18/00:00') then kk1 = [2.9,2.0,2.8,1.9]		; checked 20190325, ok determined for att=1-3
if time_double(time) gt time_double('2019-03-18/00:00') then kk1 = [2.9,2.3,2.8,2.2]		; checked 20190325, ok determined for att=1-3
if time_double(time) gt time_double('2019-03-18/00:00') then kk1 = [2.9,2.5,2.8,2.2]		; checked 20190325, ok determined for att=1-3

if time_double(time) gt time_double('2019-03-27/00:00') then kk1 = [2.9,2.5,2.8,2.2]		; checked 20190329, ok determined for att=1-3

if time_double(time) gt time_double('2019-03-30/00:00') then kk1 = [2.9,2.5,2.8,2.2]		; checked 20190329, ok determined for att=1-3
if time_double(time) gt time_double('2019-03-30/00:00') then kk1 = [2.8,2.4,2.7,2.1]		; checked 20190329, ok determined for att=1-3

if time_double(time) gt time_double('2019-03-31/00:00') then kk1 = [3.3,3.0,3.3,2.7]		; checked 20190329, ok determined for att=1-3, lpw waves good with gf_scale=1.6
;if time_double(time) gt time_double('2019-03-31/00:00') then kk1 = [3.1,2.8,3.1,2.5]		; checked 20190329, ok determined for att=1-3, lpw waves good with gf_scale=1.4
if time_double(time) gt time_double('2019-03-31/00:00') then kk1 = [3.1,2.8,3.1,2.5]		;**sta o2+ ok, checked 20190516, gf_update=1.4, for att=1-3
if time_double(time) gt time_double('2019-03-31/00:00') then kk1 = [3.0,2.7,3.0,2.4]		;**sta o2+ ok, checked 20190516, gf_update=1.4, for att=1-3

if time_double(time) gt time_double('2019-04-03/00:00') then kk1 = [3.3,3.0,3.3,2.7]		; checked 20190417, based on STATIC only fly-Z to fly-Y scpot change

;if time_double(time) gt time_double('2019-04-04/00:00') then kk1 = [2.8,2.4,2.7,2.1]		; checked 20190412, based on STATIC only fly-Z to fly-Y scpot change for att=1-3

;if time_double(time) gt time_double('2019-04-05/00:00') then kk1 = [2.8,2.4,2.7,2.1]		; checked 20190329, ok determined for att=1-3
;if time_double(time) gt time_double('2019-04-05/00:00') then kk1 = [2.6,2.2,2.5,1.9]		; checked 20190329, ok determined for att=1-3
;if time_double(time) gt time_double('2019-04-05/00:00') then kk1 = [3.3,3.0,3.3,2.7]		; checked 20190412, based on STATIC only fly-Z to fly-Y scpot change for att=1-3
if time_double(time) gt time_double('2019-04-05/00:00') then kk1 = [3.0,2.7,3.0,2.4]		; checked 20190412, based on STATIC only fly-Z to fly-Y scpot change for att=1-3

;if time_double(time) gt time_double('2019-04-06/00:00') then kk1 = [3.1,2.8,3.1,2.5]		;** checked 20190414, att=1-3

if time_double(time) gt time_double('2019-04-18/00:00') then kk1 = [3.0,2.7,3.0,2.4]		; checked 20190412, based on STATIC only fly-Z to fly-Y scpot change for att=1-3
if time_double(time) gt time_double('2019-04-18/00:00') then kk1 = [2.8,2.5,2.8,2.2]		;**sta o2+ ok, checked 20190515, gf_update=1.4, for att=1-3
if time_double(time) gt time_double('2019-04-18/00:00') then kk1 = [2.6,2.3,2.6,2.0]		;**sta o2+ ok, checked 20190515, gf_update=1.4, for att=1-3

if time_double(time) gt time_double('2019-05-01/00:00') then kk1 = [3.0,2.7,3.0,2.4]		; checked 20190412, based on STATIC only fly-Z to fly-Y scpot change for att=1-3
if time_double(time) gt time_double('2019-05-01/00:00') then kk1 = [2.3,2.0,2.3,1.7]		;**sta o2+ ok, checked 20190515, gf_update=1.6, for att=1-3
if time_double(time) gt time_double('2019-05-01/00:00') then kk1 = [2.8,2.5,2.8,2.2]		;**sta o2+ ok, checked 20190515, gf_update=1.4, for att=1-3, modulated density, use lower fp values

if time_double(time) gt time_double('2019-05-03/00:00') then kk1 = [2.8,2.5,2.8,2.2]		;**sta o2+ ok, ratio varies with orbit, checked 20190606, gf_update=1.4, for att=1-3, modulated density, use lower fp values

if time_double(time) gt time_double('2019-05-11/00:00') then kk1 = [2.8,2.5,2.8,2.2]		;**sta o2+ ok, checked 20190605, gf_update=1.4, for att=1-3, modulated density, use lower fp values
if time_double(time) gt time_double('2019-05-11/00:00') then kk1 = [2.9,2.3,2.8,2.1]		;**sta o2+ ok, checked 20190605, gf_update=1.4, for att=1-3, modulated density, use lower fp values


if time_double(time) gt time_double('2019-05-15/00:00') then kk1 = [2.8,2.5,2.8,2.2]		; checked 20190522, for att=1-3 
if time_double(time) gt time_double('2019-05-15/00:00') then kk1 = [3.2,2.7,3.1,2.2]		;**sta o2+ ok, checked 20190522, gf_update=1.4, for att=1-3, no lpw


if time_double(time) gt time_double('2019-05-15/00:00') then kk1 = [3.2,2.7,3.1,2.2]		;**sta o2+ ok, checked 20190522, gf_update=1.4, for att=1-3, no lpw

if time_double(time) gt time_double('2019-05-18/00:00') then kk1 = [3.5,3.0,3.4,2.5]		;**sta o2+ ok, checked 20190605, gf_update=1.4, for att=1-3, no lpw

if time_double(time) gt time_double('2019-05-21/00:00') then kk1 = [3.5,3.0,3.4,2.7]		;**sta o2+ ok, checked 20190607, gf_update=1.4, for att=1-3, no lpw

if time_double(time) gt time_double('2019-05-25/00:00') then kk1 = [3.5,3.0,3.4,2.7]		;tbd, only use ngims where all masses measured, checked 20190605, gf_update=1.4, for att=1-3, no lpw

; periapsis shifts to nightside 2019-05-15


; periapsis shifts to dayside 2019-08-03


if time_double(time) gt time_double('2019-08-10/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,2.7]		;too large, lpw waves only,att=3
if time_double(time) gt time_double('2019-08-10/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		;**sta o2+ ok, checked 20190816, lpw waves
if time_double(time) gt time_double('2019-08-10/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,2.7]		; matches STA data with alternating potentials
;if time_double(time) gt time_double('2019-08-10/00:00') and kk3_anode then kk3 = [3.7,3.2,3.6,2.9]		; matches STA data with alternating potentials

if time_double(time) gt time_double('2019-08-17/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		;**sta o2+ ok, checked 20190816, lpw waves

if time_double(time) gt time_double('2019-09-16/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		;sta o2+ ok, checked 20190919, ngims

if time_double(time) gt time_double('2019-09-18/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.2]		;**sta o2+ ok, checked 20190923, lpw waves


tt=timerange()
store_data,'mvn_sta_kk1',data={x:tt,y:transpose([[kk1],[kk1]])}

delta = 48*3600.
kk1_trange = [time-delta,time+delta]

return,kk1

end






