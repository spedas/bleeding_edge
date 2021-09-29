;+
;PROCEDURE:	mvn_sta_get_kk3
;PURPOSE:	
;	Returns kk3 - a 4 element array for correcting ion suppression as a function of attenuator state
;INPUT:		
;	time:		dbl		time of data to be returned
;
;KEYWORDS:
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  16/04/25
;MOD HISTORY:
;
;NOTES:	  
;	kk3 ion suppression correction may be limited to times after 20151101
;-
FUNCTION mvn_sta_get_kk3,time

common mvn_sta_kk3,kk3

common mvn_sta_kk3_anode,kk3_anode			; if kk3_anode is set to 1, then kk3 has anode dependence

kk3 = [1.0,1.0,1.0,1.0]

if time_double(time) gt time_double('2014-10-08') then kk3 = [1.0,1.0,1.0,1.0]				; tbd	 	; guess

if time_double(time) gt time_double('2014-10-20') then kk3 = 0.*[1.0,1.0,1.0,1.0]			; tbd	 	; guess

if time_double(time) gt time_double('2014-11-01') then kk3 = [1.0,1.0,1.0,1.0]				; tbd	 	; guess

; 2014-11-27 eprom load 2 - prior to this load, att=1,3 do not work properly at low energy

if time_double(time) gt time_double('2015-01-02') then kk3 = [3.0,3.0,3.0,3.0]				; tbd		; att=3 guessed

; 2015-01-24 eprom load 3 - prior to this load, att=1,3 may not work properly at low energy

if time_double(time) gt time_double('2015-01-24') then kk3 = [3.5,3.2,3.6,3.0]				; 20150124**	; poorly determined, att=3 guessed

if time_double(time) gt time_double('2015-02-03') then kk3 = [3.5,3.2,3.6,3.0]				; 20150203**	; poorly determined, att=3 guessed

if time_double(time) gt time_double('2015-02-08') then kk3 = [3.5,3.5,3.9,3.3]				; 20150208**	; poorly determined, att=3 guessed

; deep dip 2-10 to 2-19

if time_double(time) gt time_double('2015-02-14') then kk3 = [6.0,4.5,4.5,4.5]				; 20150214**	; poorly determined, att=2,3 guessed
if time_double(time) gt time_double('2015-02-16') then kk3 = [6.0,4.5,5.5,5.5]				; 20150214**	; poorly fits, need to allow corr up to 50, att=2,3 guessed

;if time_double(time) gt time_double('2015-02-22') then kk3 = [5.0,4.5,6.0,4.8]				; 20150222**	; poorly determined,
if time_double(time) gt time_double('2015-02-22') then kk3 = [5.6,5.6,5.4,4.8]				; 20150222**	; poorly determined,
;if time_double(time) gt time_double('2015-02-23') then kk3 = [4.8,4.7,6.2,4.8]				; tbd		; inconsistent inbound/outbound odd/even attempt to make it work at periapsis
if time_double(time) gt time_double('2015-02-23') then kk3 = [5.6,5.6,5.4,4.8]				; tbd		; determined on even orbits with larger scpot, invalid on odd orbits  

if time_double(time) gt time_double('2015-03-03') then kk3 = [5.6,5.6,5.8,4.6]				; 20150303**	; redue		poorly determined, no scpot last orbit, att=3 guessed

if time_double(time) gt time_double('2015-03-09') then kk3 = [5.2,5.2,5.3,4.0]				; 20150309**	; redue		odd orbits used for att=2, even orbits for att=3
															; unexplained hysteresis on even orbits - inbound att=2 too large

if time_double(time) gt time_double('2015-04-02') then kk3 = [5.8,5.8,5.3,4.6]				; 20150402**	; poorly determined, static saturation

if time_double(time) gt time_double('2015-05-02') then kk3 = [5.0,5.0,5.0,5.0]				; 20150502**	; poorly determined, static saturation

if time_double(time) gt time_double('2015-05-25') then kk3 = [5.0,5.0,4.8,4.5]				; 20150525**	; poorly determined
if time_double(time) gt time_double('2015-05-25/00:00') and kk3_anode then kk3 = [3.9,3.4,3.5,3.0]	; checked 20190211 good for mode=1, att=3, conic mode fails to resolve cold beam


if time_double(time) gt time_double('2015-07-04') then kk3 = [6.7,6.7,6.4,6.1]				; 20150704**	; poorly determined, att=3 guessed

; lpw interference - sweeps changing s/c pot - 15-07-05 to 15-08-05

; deep dip 15-07-07 to 15-07-15

if time_double(time) gt time_double('2015-07-19') then kk3 = [5.3,4.8,4.8,4.5]				; 20150719**	; poorly determined, att=3 guessed
if time_double(time) gt time_double('2015-07-20') then kk3 = [5.3,5.0,4.8,4.5]				; 20150720**	; poorly determined, att=3 guessed

if time_double(time) gt time_double('2015-07-30') then kk3 = [4.8,4.8,4.7,4.3]				; 20150730**	; poorly determined, att=3 guessed

if time_double(time) gt time_double('2015-08-03') then kk3 = [4.0,4.0,4.2,3.8]				; 20150803**	; poorly determined, att=3 guessed, redue

; lpw interference - sweeps changing s/c pot - 15-07-05 to 15-08-05

if time_double(time) gt time_double('2015-08-08') then kk3 = [4.2,4.2,4.2,3.8]				; 20150808**	; poorly determined, att=3 guessed
if time_double(time) gt time_double('2015-08-09') then kk3 = [4.2,4.2,4.2,3.8]				; 20150809**	; poorly determined, att=3 guessed

; no ngims data 8-12 to 8-21, static off 8-13 to 8-14

if time_double(time) gt time_double('2015-08-14') then kk3 = [4.0,4.0,4.0,3.5]				; guess

if time_double(time) gt time_double('2015-08-22') then kk3 = [3.8,3.8,3.8,3.3]				; 20150822**	; not well determined

if time_double(time) gt time_double('2015-08-24') then kk3 = [3.8,3.8,3.8,3.2]				; 20150824**	; determined at att 2->3 transition

if time_double(time) gt time_double('2015-08-29') then kk3 = [3.6,3.6,3.6,3.1]				; 20150829**	; 

if time_double(time) gt time_double('2015-08-30') then kk3 = [3.4,3.4,3.4,2.9]				; 20150830**	; 

;*************************************************************************************
; deep dip 4 begins 2015-09-02


if time_double(time) gt time_double('2015-09-05') then kk3 = [3.6,3.6,3.6,3.0]				; 20150905**	; 

if time_double(time) gt time_double('2015-09-06/00:00') and kk3_anode then kk3 = [3.8,3.6,3.8,3.6]	; deepdip checked 20190116
if time_double(time) gt time_double('2015-09-06/00:00') and kk3_anode then kk3 = [4.0,3.8,4.2,3.4]	; deepdip checked 20190116

;*************************************************************************************
; deep dip 4 ends 2015-09-10

if time_double(time) gt time_double('2015-09-10') then kk3 = [3.6,3.6,3.6,3.0]				; 20150913**	; 

if time_double(time) gt time_double('2015-09-12') then kk3 = [3.7,3.7,3.7,3.2]				; 20150912**	; 
if time_double(time) gt time_double('2015-09-12/00:00') and kk3_anode then kk3 = [4.5,4.1,4.5,3.7]	; checked 20190215

;if time_double(time) gt time_double('2015-09-13') then kk3 = [3.6,3.6,3.6,3.0]				; 20150913**	; 
if time_double(time) gt time_double('2015-09-13') then kk3 = [3.5,3.6,3.6,3.1]				; 20150913**	; better fit

if time_double(time) gt time_double('2015-09-16/00:00') and kk3_anode then kk3 = [4.0,3.8,4.2,3.6]	; checked 20190211
if time_double(time) gt time_double('2015-09-16/00:00') and kk3_anode then kk3 = [4.2,3.8,4.2,3.4]	; checked 20190211


if time_double(time) gt time_double('2015-09-19') then kk3 = [3.6,3.6,3.6,2.9]				; 20150919**	; 

;ion suppression cleaning starts 20150922
 
if time_double(time) gt time_double('2015-09-30') then kk3 = [3.6,3.6,3.6,3.2]				; 20150930**	; poor-fit 
if time_double(time) gt time_double('2015-10-01') then kk3 = [3.5,3.5,3.5,3.1]				; 20151001**	; guess
if time_double(time) gt time_double('2015-10-02') then kk3 = [3.4,3.4,3.4,3.0]				; 20151002**	; guess
if time_double(time) gt time_double('2015-10-03') then kk3 = [3.3,3.3,3.3,2.9]				; 20151003**	; 
if time_double(time) gt time_double('2015-10-04') then kk3 = [3.4,3.4,3.4,3.0]				; 20151004**	; guess
if time_double(time) gt time_double('2015-10-05') then kk3 = [3.4,3.4,3.4,3.0]				; 20151005**	; 

;ion suppression cleaning starts 20151006

;if time_double(time) gt time_double('2015-10-13') then kk3 = [4.0,4.0,4.0,3.7]				; tbd	 	; guess
if time_double(time) gt time_double('2015-10-13') then kk3 = [3.8,3.8,3.8,3.5]				; tbd	 	; guess
if time_double(time) gt time_double('2015-10-14') then kk3 = [3.8,3.8,3.8,3.5]				; 20151014** 	; odd sta 2025 periapsis
if time_double(time) gt time_double('2015-10-16') then kk3 = [3.5,3.5,3.5,3.2]				; 20151016** 	; 
if time_double(time) gt time_double('2015-10-17') then kk3 = [3.3,3.3,3.3,3.0]				; 20151017** 	; 
if time_double(time) gt time_double('2015-10-18') then kk3 = [3.1,3.1,3.1,2.8]				; tbd	 	; guess
if time_double(time) gt time_double('2015-10-19') then kk3 = [2.8,2.8,2.8,2.6]				; 20151019** 	;  
if time_double(time) gt time_double('2015-10-20') then kk3 = [2.6,2.6,2.6,2.4]				; tbd	 	; guess

;ion suppression cleaning starts 20151020

if time_double(time) gt time_double('2015-10-27') then kk3 = [3.9,3.9,3.9,3.6]				; tbd	 	; guess
if time_double(time) gt time_double('2015-10-28') then kk3 = [3.6,3.6,3.6,3.3]				; 20151028	; 
if time_double(time) gt time_double('2015-10-29') then kk3 = [3.4,3.4,3.4,3.1]				; tbd	 	; guess
if time_double(time) gt time_double('2015-10-30') then kk3 = [3.4,3.4,3.4,3.1]				; tbd	 	; guess
if time_double(time) gt time_double('2015-10-31') then kk3 = [3.3,3.3,3.3,3.0]				; 20151031	; 
if time_double(time) gt time_double('2015-11-01') then kk3 = [3.0,3.0,3.0,2.8]				; tbd		; guess
if time_double(time) gt time_double('2015-11-02') then kk3 = [2.8,2.8,2.8,2.6]				; 20151102	; 

;ion suppression cleaning starts 20151103

if time_double(time) gt time_double('2015-11-10') then kk3 = [3.4,3.4,3.4,3.4]				; 20151111** 	 
if time_double(time) gt time_double('2015-11-11') then kk3 = [3.2,3.2,3.2,3.2]				; 20151111** 	 
if time_double(time) gt time_double('2015-11-12') then kk3 = [3.1,3.1,3.1,3.1]				; 


if time_double(time) gt time_double('2015-11-12/00:00') and kk3_anode then kk3 = [4.0,3.8,4.0,3.8]	; 2 ngims, ok agreement, 20180919



if time_double(time) gt time_double('2015-11-13') then kk3 = [2.8,2.8,2.8,2.8]				; 20151113** 	; 
if time_double(time) gt time_double('2015-11-14') then kk3 = [2.9,2.9,2.9,2.9]				; 20151114** 	; 
if time_double(time) gt time_double('2015-11-15') then kk3 = [2.9,2.9,2.9,2.9]				; 20151115** 	; 
if time_double(time) gt time_double('2015-11-16') then kk3 = [2.7,2.7,2.7,2.7]				; 20151116** 	; 

;ion suppression cleaning starts 20151117
;ion suppression cleaning ends   20151124

;if time_double(time) gt time_double('2015-11-24') then kk3 = [3.1,3.1,3.1,3.1]				; tbd
if time_double(time) gt time_double('2015-11-24/00:00') and kk3_anode then kk3 = [3.9,3.7,3.8,3.6]	; ok agreement, 20161230
;if time_double(time) gt time_double('2015-11-25') then kk3 = [3.1,3.1,3.1,3.1]				; 20151125**
;if time_double(time) gt time_double('2015-11-26') then kk3 = [3.0,3.0,3.0,3.0]				; 20151126**
if time_double(time) gt time_double('2015-11-26/00:00') and kk3_anode then kk3 = [3.9,3.7,3.8,3.6]	; ok agreement, 20161230
;if time_double(time) gt time_double('2015-11-27') then kk3 = [2.9,2.9,2.9,2.9]				; guess
if time_double(time) gt time_double('2015-11-27/00:00') and kk3_anode then kk3 = [3.9,3.5,3.8,3.4]	; tbd
if time_double(time) gt time_double('2015-11-27/00:00') and kk3_anode then kk3 = [3.9,3.7,3.8,3.6]	; ok agreement, 20161230
;if time_double(time) gt time_double('2015-11-28') then kk3 = [2.85,2.85,2.85,2.85]			; guess
;if time_double(time) gt time_double('2015-11-29') then kk3 = [2.8,2.8,2.8,2.8]				; guess
;if time_double(time) gt time_double('2015-11-30') then kk3 = [2.75,2.75,2.75,2.75]			; 20151130** 	; 

if time_double(time) gt time_double('2015-12-01/00:00') and kk3_anode then kk3 = [2.0,2.0,2.0,2.0]	; way too low
if time_double(time) gt time_double('2015-12-01/00:00') and kk3_anode then kk3 = [3.6,3.1,3.5,3.0]	; too low
if time_double(time) gt time_double('2015-12-01/00:00') and kk3_anode then kk3 = [3.9,3.5,3.8,3.3]	; too low
if time_double(time) gt time_double('2015-12-01/00:00') and kk3_anode then kk3 = [3.9,3.5,3.8,3.4]	; better, 20161223

;ion suppression cleaning starts 20151203 - delayed by a 1.5 days
;ion suppression cleaning ends   20151208

;if time_double(time) gt time_double('2015-12-08') then kk3 = [2.0,2.0,2.0,2.0]				; no overlap	; guessed from first pass 12-09
if time_double(time) gt time_double('2015-12-08/00:00') and kk3_anode then kk3 = [2.7,2.7,2.7,2.7]	; not that well determined 20161126, suppression is small
if time_double(time) gt time_double('2015-12-09/09:00') and kk3_anode then kk3 = [2.0,2.0,2.0,2.0]	; not that well determined 20161126, suppression is small
;if time_double(time) gt time_double('2015-12-09/09:00') then kk3 = [2.0,2.0,2.0,2.0]			; 20151209** 	; 2.0 first periapsis, 1.4 on 3rd,5th
;if time_double(time) gt time_double('2015-12-09') then kk3 = [2.0,2.0,2.0,1.4]				; 20151209** 	; 2.0 first periapsis, 1.4 on 3rd,5th
;if time_double(time) gt time_double('2015-12-10') then kk3 = [2.0,2.0,2.0,1.3]				; 20151210**	; att=2 calib, as beam moves across FOV
;if time_double(time) gt time_double('2015-12-11') then kk3 = [2.0,2.0,2.0,1.3]				; 20151211** 	; 
if time_double(time) gt time_double('2015-12-11/00:00') and kk3_anode then kk3 = [3.6,3.1,3.5,3.0]	; too high
if time_double(time) gt time_double('2015-12-11/00:00') and kk3_anode then kk3 = [2.7,2.4,2.6,2.3]	; guess
if time_double(time) gt time_double('2015-12-11/00:00') and kk3_anode then kk3 = [2.5,2.3,2.4,2.2]	; guess
if time_double(time) gt time_double('2015-12-11/00:00') and kk3_anode then kk3 = [2.0,2.0,2.0,2.0]	; not that well determined 20161126, suppression is small



;if time_double(time) gt time_double('2015-12-12') then kk3 = [2.0,2.0,2.0,1.3]					; 20151212** 	; 
;if time_double(time) gt time_double('2015-12-13') then kk3 = [2.0,2.0,2.0,1.3]					; 20151213** 	; 
;if time_double(time) gt time_double('2015-12-14') then kk3 = [2.0,2.0,2.0,1.3]					; 20151214** 	; 
;if time_double(time) gt time_double('2015-12-14/00:00') and kk3_anode then kk3 = [3.6,3.1,3.5,3.0]		; tbd
;if time_double(time) gt time_double('2015-12-14/00:00') and kk3_anode then kk3 = [3.1,2.6,3.0,2.5]		; tbd
;if time_double(time) gt time_double('2015-12-14/00:00') and kk3_anode then kk3 = [3.0,2.8,2.9,2.7]		; wrong direction
;if time_double(time) gt time_double('2015-12-14/00:00') and kk3_anode then kk3 = [2.3,2.3,2.3,2.3]		; tbd
if time_double(time) gt time_double('2015-12-14/00:00') and kk3_anode then kk3 = [2.0,2.0,2.0,2.0]		; good o2+ fit, 20161221

;ion suppression cleaning starts 20151215
;ion suppression cleaning ends   20151221

;if time_double(time) gt time_double('2015-12-22') then kk3 = [2.2,2.2,2.2,1.6]					; guessed from 12-24
;if time_double(time) gt time_double('2015-12-22/00:00') and kk3_anode then kk3 = [3.6,3.1,3.5,3.0]		; no way to verify with ngims, check nearby days
;if time_double(time) gt time_double('2015-12-24') then kk3 = [2.2,2.2,2.2,1.6]					; 20151224** 	; poorly defined
if time_double(time) gt time_double('2015-12-22/00:00') and kk3_anode then kk3 = [3.6,3.1,3.5,3.0]		; 20161223, ok agreement
;if time_double(time) gt time_double('2015-12-26') then kk3 = [2.2,2.2,2.2,1.6]					; 20151226** 	; poorly defined
;if time_double(time) gt time_double('2015-12-27') then kk3 = [2.2,2.2,2.2,1.6]					; 20151228** 	; poorly defined, ratio>1 assoc. w/ droop>3
;if time_double(time) gt time_double('2015-12-28') then kk3 = [2.2,2.2,2.2,1.6]					; 20151228** 	; poorly defined
if time_double(time) gt time_double('2015-12-28/00:00') and kk3_anode then kk3 = [4.1,3.6,4.0,3.5]		; tbd
if time_double(time) gt time_double('2015-12-28/00:00') and kk3_anode then kk3 = [3.6,3.1,3.5,3.0]	 	; tbd

;ion suppression cleaning starts 20151229
;ion suppression cleaning ends   20160105
; scenario 1

;if time_double(time) gt time_double('2016-01-05') then kk3 = [2.4,2.4,2.4,2.0]					; 	 	; guessed from 1-6
;if time_double(time) gt time_double('2016-01-06') then kk3 = [2.4,2.4,2.4,2.0]					; 20160106** 	; poorly defined
;if time_double(time) gt time_double('2016-01-07') then kk3 = [2.4,2.4,2.4,2.0]					; 20160107** 	; ngims ion mode consecutive orbits
;if time_double(time) gt time_double('2016-01-08') then kk3 = [2.4,2.4,2.4,2.0]					; 20160108** 	; poorly defined
;if time_double(time) gt time_double('2016-01-09') then kk3 = [2.4,2.4,2.4,2.0]					; 20160109** 	; poorly defined
;if time_double(time) gt time_double('2016-01-10') then kk3 = [2.4,2.4,2.4,2.0]					; 20160110** 	; poorly defined
;if time_double(time) gt time_double('2016-01-10/00:00') and kk3_anode then kk3 = [3.8,3.3,3.6,3.1]		; too low
;if time_double(time) gt time_double('2016-01-10/00:00') and kk3_anode then kk3 = [4.1,3.6,3.9,3.3]		; too low
;if time_double(time) gt time_double('2016-01-10/00:00') and kk3_anode then kk3 = [4.1,3.6,4.0,3.5]		;*ok agreement with lpw - redue


;if time_double(time) gt time_double('2016-01-11') then kk3 = [2.4,2.4,2.4,2.0]					; tbd	 	; guessed from 1-10
;if time_double(time) gt time_double('2016-01-12') then kk3 = [2.4,2.4,2.4,2.0]					; tbd	 	; guessed from 1-10

if time_double(time) gt time_double('2016-01-05/00:00') and kk3_anode then kk3 = [3.6,3.3,3.6,2.9]		; assume same as 2016-01-06

if time_double(time) gt time_double('2016-01-06/00:00') and kk3_anode then kk3 = [3.6,3.3,3.6,2.9]		; 20161220 5 ngims
if time_double(time) gt time_double('2016-01-07/00:00') and kk3_anode then kk3 = [3.5,3.3,3.4,3.0]		; 20161220 5 ngims

if time_double(time) gt time_double('2016-01-08/00:00') and kk3_anode then kk3 = [3.4,2.9,3.3,2.8]		; 20161219 good agreement w/ ngi o2+ att=3

;ion suppression cleaning starts 20160112
;ion suppression cleaning ends   20160119
; no more cleaning after 20160119

;if time_double(time) gt time_double('2016-01-19/00:00') then kk3 = [2.3,2.3,2.2,1.8]				; 20160121** 	; 1.8 estimated

;if time_double(time) gt time_double('2016-01-21/00:00') then kk3 = [2.3,2.3,2.2,1.8]				; 20160121** 	; 1.8 estimated
if time_double(time) gt time_double('2016-01-21/00:00') and kk3_anode then kk3 = [4.1,3.6,3.9,3.3]		; to high
if time_double(time) gt time_double('2016-01-21/00:00') and kk3_anode then kk3 = [3.8,3.3,3.6,3.1]		; att=1 too low from ngims
if time_double(time) gt time_double('2016-01-21/00:00') and kk3_anode then kk3 = [3.8,3.6,3.6,3.1]		;*good agreement

;if time_double(time) gt time_double('2016-01-22/00:00') then kk3 = [2.4,2.4,2.4,2.0]				; 20160122** 	; 
if time_double(time) gt time_double('2016-01-22/00:00') and kk3_anode then kk3 = [3.6,3.1,3.4,2.9]		; sta too high
if time_double(time) gt time_double('2016-01-22/00:00') and kk3_anode then kk3 = [3.4,2.9,3.2,2.7]		; sta att=1 too low
if time_double(time) gt time_double('2016-01-22/00:00') and kk3_anode then kk3 = [3.4,3.1,3.2,2.7]		;v7 good o2+ agreement 20161122

;if time_double(time) gt time_double('2016-01-26/00:00') then kk3 = [2.4,2.4,2.4,2.0]				; 20160126** 	; not well determined

;if time_double(time) gt time_double('2016-01-29/00:00') then kk3 = [2.5,2.5,2.5,2.1]				; 20160129**	; att=2

;if time_double(time) gt time_double('2016-01-30/00:00') then kk3 = [2.4,2.4,2.4,2.0]				;  		; tbd
if time_double(time) gt time_double('2016-01-30/00:00') and kk3_anode then kk3 = [3.8,3.3,3.6,3.1]		;*ok fit to lpw

;if time_double(time) gt time_double('2016-02-02/00:00') then kk3 = [2.4,2.4,2.4,2.0]				; 20160202**	; not well determined
if time_double(time) gt time_double('2016-02-02/00:00') and kk3_anode then kk3 = [3.8,3.3,3.6,3.1]		; sta too large
if time_double(time) gt time_double('2016-02-02/00:00') and kk3_anode then kk3 = [3.6,3.1,3.4,2.9]		;v7 good o2+ agreement 20161122

;if time_double(time) gt time_double('2016-02-04/00:00') then kk3 = [2.5,2.5,2.5,2.1]				; 20160204** 	; 
;if time_double(time) gt time_double('2016-02-05/00:00') then kk3 = [2.5,2.5,2.5,2.1]				; 20160204** 	; 

;if time_double(time) gt time_double('2016-02-09/00:00') then kk3 = [2.5,2.5,2.5,2.1]				; 20160209** 	; 

if time_double(time) gt time_double('2016-02-14/00:00') and kk3_anode then kk3 = [3.6,3.1,3.4,2.9]		; too low
if time_double(time) gt time_double('2016-02-14/00:00') and kk3_anode then kk3 = [3.8,3.3,3.6,3.1]		;*good lpw agreement - redue

;if time_double(time) gt time_double('2016-02-17/00:00') then kk3 = [2.5,2.5,2.5,2.1]				; 20160217** 	; 
if time_double(time) gt time_double('2016-02-17/00:00') and kk3_anode then kk3 = [3.7,3.2,3.5,3.0]		; too large
if time_double(time) gt time_double('2016-02-17/00:00') and kk3_anode then kk3 = [3.6,3.2,3.3,2.9]		; too large

;if time_double(time) gt time_double('2016-02-20/00:00') then kk3 = [2.7,2.7,2.7,2.3]				; 20160220** 	; 
;if time_double(time) gt time_double('2016-02-20/00:00') then kk3 = [3.1,3.1,3.1,2.7]				; 20160220*****	; 
;if time_double(time) gt time_double('2016-02-20/00:00') then kk3 = [3.6,3.6,3.6,3.2]				; 20160220*****	; 
if time_double(time) gt time_double('2016-02-20/00:00') and kk3_anode then kk3 = [3.7,3.2,3.5,3.0]		; good for o2+, not well determined

if time_double(time) gt time_double('2016-02-24/00:00') and kk3_anode then kk3 = [3.7,3.2,3.5,3.0]		; tbd


;if time_double(time) gt time_double('2016-02-21/00:00') then kk3 = [2.7,2.7,2.8,2.3]				; 20160221** 	; 
;if time_double(time) gt time_double('2016-02-27/00:00') and kk3_anode then kk3 = [3.6,3.1,3.4,2.9]		; a bit low
if time_double(time) gt time_double('2016-02-27/00:00') and kk3_anode then kk3 = [3.7,3.2,3.5,3.0]		; good for o2+, lpw wrong

;if time_double(time) gt time_double('2016-03-03/00:00') then kk3 = [2.9,2.9,3.1,2.8]				; 20160307** 	; 
;if time_double(time) gt time_double('2016-03-03/00:00') then kk3 = [3.1,3.1,3.3,3.0]				; 20160307** 	; this is too low if one uses anode dependent kk3
;if time_double(time) gt time_double('2016-03-03/00:00') then kk3 = [3.6,3.6,3.8,3.5]				; 20160307** 	; this is too large
;if time_double(time) gt time_double('2016-03-03/00:00') then kk3 = [3.2,3.2,3.4,3.1]				; 20160307*****	; this is just right for O2+ if one uses anode dependent kk3, underestimates O+
;if time_double(time) gt time_double('2016-03-03/00:00') and kk3_anode then kk3 = [3.4,2.9,3.2,2.7]		; sta too low
if time_double(time) gt time_double('2016-03-03/00:00') and kk3_anode then kk3 = [3.6,3.1,3.4,2.9]		;*good for lpw/sta agreement, ngims too high

;if time_double(time) gt time_double('2016-03-07/00:00') then kk3 = [2.5,2.5,2.6,2.0]				; 20160307** 	; 

;if time_double(time) gt time_double('2016-03-10/00:00') then kk3 = [2.5,2.5,2.6,2.3]				; 20160307** 	; 
;if time_double(time) gt time_double('2016-03-10/00:00') and kk3_anode then kk3 = [3.4,2.9,3.2,2.7]		; too low
if time_double(time) gt time_double('2016-03-10/00:00') and kk3_anode then kk3 = [3.6,3.1,3.4,2.9]		; 

;if time_double(time) gt time_double('2016-03-13/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		; too low
if time_double(time) gt time_double('2016-03-13/00:00') and kk3_anode then kk3 = [3.4,2.9,3.2,2.7]		;*pretty good lpw agreement



;if time_double(time) gt time_double('2016-03-16/00:00') then kk3 = [2.5,2.5,2.6,2.0]				; 20160307** 	; 
;if time_double(time) gt time_double('2016-03-16/00:00') and kk3_anode then kk3 = [3.6,3.1,3.4,2.9]		; too high
if time_double(time) gt time_double('2016-03-16/00:00') and kk3_anode then kk3 = [3.2,2.7,3.0,2.4]		; good agreement o2+ 

;if time_double(time) gt time_double('2016-03-19/00:00') then kk3 = [2.7,2.7,2.8,2.4]				; 20160307** 	; 
;if time_double(time) gt time_double('2016-03-19/00:00') and kk3_anode then kk3 = [3.1,3.1,3.2,2.8]		; 20160319*****	; anode dependent kk3, O+ poor agreement 
;if time_double(time) gt time_double('2016-03-19/00:00') and kk3_anode then kk3 = [3.4,2.9,3.2,2.7]		; need to be a bit higher
if time_double(time) gt time_double('2016-03-19/00:00') and kk3_anode then kk3 = [3.6,3.1,3.4,2.9]		;*pretty good lpw agreement




;if time_double(time) gt time_double('2016-03-25/00:00') then kk3 = [2.5,2.5,2.6,2.2]				; 20160307** 	; 
if time_double(time) gt time_double('2016-03-28/00:00') and kk3_anode then kk3 = [3.5,3.0,3.3,2.7]		;*pretty good lpw agreement

;if time_double(time) gt time_double('2016-03-30/00:00') then kk3 = [2.5,2.5,2.6,2.1]				; 20160307** 	; 
;if time_double(time) gt time_double('2016-03-30/00:00') and kk3_anode then kk3 = [3.6,3.1,3.4,2.9]		; tbd
if time_double(time) gt time_double('2016-03-30/00:00') and kk3_anode then kk3 = [3.5,3.0,3.3,2.8]		;*pretty good lpw agreement



;if time_double(time) gt time_double('2016-03-31/00:00') then kk3 = [2.5,2.5,2.6,1.95]				; 20160331** 	; 

;if time_double(time) gt time_double('2016-04-03/00:00') then kk3 = [2.5,2.5,2.6,2.15]				; 20160403** 	; 
;if time_double(time) gt time_double('2016-04-03/00:00') and kk3_anode then kk3 = [4.4,4.2,4.0,3.3]		; 20160403***** ; too large,  
;if time_double(time) gt time_double('2016-04-03/00:00') and kk3_anode then kk3 = [3.2,2.7,3.0,2.5]		; too low
if time_double(time) gt time_double('2016-04-03/00:00') and kk3_anode then kk3 = [3.5,3.0,3.3,2.8]		; tbd- from 5-6




;if time_double(time) gt time_double('2016-04-04/00:00') then kk3 = [2.4,2.4,2.5,2.1]				; 20160406** 	; 

;if time_double(time) gt time_double('2016-04-05/00:00') then kk3 = [2.4,2.4,2.5,2.1]				; 20160405** 	; 
;if time_double(time) gt time_double('2016-04-05/20:00') then kk3 = [2.1,2.1,2.2,1.4]				; 20160406** 	; drops after contacts on 4-5
;if time_double(time) gt time_double('2016-04-05/00:00') and kk3_anode then kk3 = [3.5,3.0,3.3,2.8]		;*not checked but likely 
if time_double(time) gt time_double('2016-04-05/20:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		;*not checked but likely

;if time_double(time) gt time_double('2016-04-06/00:00') and kk3_anode then kk3 = [3.2,2.7,3.0,2.5]		; too high
if time_double(time) gt time_double('2016-04-06/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		;*pretty good lpw agreement




;if time_double(time) gt time_double('2016-04-08/00:00') then kk3 = [2.1,2.1,2.2,1.4]				; 20160408** 	; 
;if time_double(time) gt time_double('2016-04-08/15:00') then kk3 = [1.9,1.9,2.0,1.2]				; 20160408** 	; 
;if time_double(time) gt time_double('2016-04-08/00:00') then kk3 = [2.5,2.0,2.5,2.0]				; 20160517** 	; 
;if time_double(time) gt time_double('2016-04-08/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		;*20160409*****
if time_double(time) gt time_double('2016-04-08/00:00') and kk3_anode then kk3 = [3.4,2.9,3.2,2.5]		;$ 7 ok agreement sta O2, O is low



;if time_double(time) gt time_double('2016-04-09/00:00') then kk3 = [1.9,1.9,2.0,1.2]				; 20160409** 	; 
;if time_double(time) gt time_double('2016-04-09/00:00') and kk3_anode then kk3 = [4.0,3.8,3.6,3.3]		; 20160409***** ; lp/sta density way off
if time_double(time) gt time_double('2016-04-09/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		;*20160409*****

;if time_double(time) gt time_double('2016-04-12/00:00') and kk3_anode then kk3 = [4.0,3.8,3.6,3.3]		; 20160412***** ; 7a  too large
;if time_double(time) gt time_double('2016-04-12/00:00') and kk3_anode then kk3 = [3.5,3.3,3.1,2.8]		; 20160412***** ; 
;if time_double(time) gt time_double('2016-04-12/00:00') and kk3_anode then kk3 = [3.5,3.3,3.3,2.6]		; 20160412***** ; 7 good lp/sta agreement




;if time_double(time) gt time_double('2016-04-17/00:00') and kk3_anode then kk3 = [3.3,3.1,3.1,2.8]		; 20160417***** ; tbd 
;if time_double(time) gt time_double('2016-04-17/00:00') and kk3_anode then kk3 = [3.5,3.3,3.1,2.8]		; 20160417***** ; 7a, pretty good 
;if time_double(time) gt time_double('2016-04-17/00:00') and kk3_anode then kk3 = [4.0,3.8,3.6,3.3]		; 20160417***** ; 7b, this gives more consistent ratio for O+ and O2+ between ngims and static
if time_double(time) gt time_double('2016-04-17/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		; tbd

;if time_double(time) gt time_double('2016-04-18/00:00') then kk3 = [1.7,1.7,1.8,1.3]				; 20160418** 	; 

;if time_double(time) gt time_double('2016-04-22/00:00') then kk3 = [1.7,1.7,1.8,1.3]				; 20160422** 	; this clearly underestimates O+
;if time_double(time) gt time_double('2016-04-22/00:00') then kk3 = [2.2,2.2,2.2,1.8]				; 20160422*** 	; using O+, still too low for att=3
;if time_double(time) gt time_double('2016-04-22/00:00') then kk3 = [2.5,2.5,2.5,2.2]				; 20160422**** 	; using O+, still too low
;if time_double(time) gt time_double('2016-04-22/00:00') then kk3 = [2.8,2.8,2.8,2.2]				; 20160422**** 	; using O+, still too low
;if time_double(time) gt time_double('2016-04-22/00:00') then kk3 = [2.8,2.8,2.8,2.0]				; 20160422**** 	; using O+, still too low
if time_double(time) gt time_double('2016-04-22/00:00') and kk3_anode then kk3 = [2.9,2.4,2.7,2.2]		;*a bit better fit to lpw

;*****************************************************************************************
; deep dip 2 ends


;if time_double(time) gt time_double('2016-04-23/00:00') then kk3 = [1.7,1.7,1.8,1.3]				; 20160423** 	; 
;if time_double(time) gt time_double('2016-04-24/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		; tbd
if time_double(time) gt time_double('2016-04-24/00:00') and kk3_anode then kk3 = [2.9,2.4,2.7,2.2]		;*a bit better fit to lpw

;if time_double(time) gt time_double('2016-04-25/00:00') then kk3 = [2.0,1.5,2.0,1.5]				; 20160425*** 	; better fit to LP I-V, but suspect LP calib is low in these high density cases
;if time_double(time) gt time_double('2016-04-25/00:00') then kk3 = [2.5,2.0,2.5,2.0]				; 20160425*** 	; best fit to ngims

;if time_double(time) gt time_double('2016-04-27/00:00') then kk3 = [2.5,2.0,2.5,2.0]				; 20160418** 	; 

;if time_double(time) gt time_double('2016-05-04/00:00') then kk3 = [1.9,1.9,2.0,1.5]				; 20160504** 	; ngims varies
if time_double(time) gt time_double('2016-05-04/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		; tbd

;if time_double(time) gt time_double('2016-05-06/00:00') then kk3 = [2.0,2.0,2.0,1.2]				; 20160506 	; att=1-3, att=3 not well determined due to high pot
;if time_double(time) gt time_double('2016-05-06/00:00') then kk3 = [2.0,2.0,2.0,1.5]				; 20160506*** 	; att=1-3, att=3 not well determined due to high pot
;if time_double(time) gt time_double('2016-05-06/00:00') and kk3_anode then kk3 = [3.3,3.1,2.5,2.0]		; 20160506***** ; tbd
;if time_double(time) gt time_double('2016-05-06/00:00') and kk3_anode then kk3 = [3.3,3.1,2.8,2.0]		; 20160506***** ; tbd
;if time_double(time) gt time_double('2016-05-06/00:00') and kk3_anode then kk3 = [3.3,3.1,2.8,2.5]		; 20160506***** ; this works
;if time_double(time) gt time_double('2016-05-06/00:00') and kk3_anode then kk3 = [3.3,3.1,3.1,2.8]		; 20160506***** ; seems a bit low for lp, bad O+
;if time_double(time) gt time_double('2016-05-06/00:00') and kk3_anode then kk3 = [3.0,2.8,2.8,2.5]		; 20160506***** ; a bit better
;if time_double(time) gt time_double('2016-05-06/00:00') and kk3_anode then kk3 = [2.8,2.5,2.8,2.0]		; 20160506***** ; the same - within error bar of absolute
if time_double(time) gt time_double('2016-05-06/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		;*20160506***** ; best fit to lpw and new lpiv-sta calibration




;if time_double(time) gt time_double('2016-05-10/00:00') then kk3 = [2.5,2.0,2.5,2.0]				; 20160517** 	; 

;if time_double(time) gt time_double('2016-05-12/00:00') then kk3 = [1.9,1.9,2.0,1.5]				; 20160512** 	; s/c charging causes static to saturate

;if time_double(time) gt time_double('2016-05-17/00:00') then kk3 = 2.0*[1.,1.,1.,1.]				; 20160517** 	; 
;if time_double(time) gt time_double('2016-05-17/00:00') then kk3 = [2.5,2.0,2.5,2.0]				; 20160517** 	; 

;if time_double(time) gt time_double('2016-05-18/00:00') then kk3 = [1.9,1.9,2.0,1.5]				; 20160518** 	; s/c charging causes static to saturate

;if time_double(time) gt time_double('2016-05-21/00:00') then kk3 = [2.5,1.5,2.5,1.2]				; 20160521*** 	; looks good





; 20160526-20160527 5 orbits in protect mode enhanced exposure to atomic oxygen

;if time_double(time) gt time_double('2016-05-28/00:00') then kk3 = [1.9,1.9,2.0,1.5]				; 20160528** 	; tbd

;if time_double(time) gt time_double('2016-05-29/00:00') then kk3 = [1.9,1.9,2.0,3.0]				; 20160529** 	; tbd
;if time_double(time) gt time_double('2016-05-29/00:00') then kk3 = [1.9,1.9,2.0,2.0]				; 20160529** 	; tbd
;if time_double(time) gt time_double('2016-05-29/00:00') then kk3 = [2.5,1.2,2.5,1.2]				; 20160529** 	; tbd
;if time_double(time) gt time_double('2016-05-29/00:00') then kk3 = [1.5,1.5,1.5,1.5]				; 20160529** 	; 
;if time_double(time) gt time_double('2016-05-29/00:00') then kk3 = [2.0,2.0,1.5,1.5]				; 20160529** 	; 
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [2.5,2.5,2.0,2.0]		; 20160529** 	; with default anode variation
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.4,3.4,2.9,2.9]		; 20160529** 	; with default anode variation
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [2.8,2.6,2.0,1.5]		; 20160529** 	; O2+ low, O+ lower, 
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.8,3.6,3.0,2.5]		; 20160529** 	; too large for LP
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.3,3.1,2.5,2.0]		; too small
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [4.0,3.5,3.5,3.0]		; too small  
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [4.5,4.0,4.0,4.0]		; 7a good agreement for ngi/sta, but over estimates lp and waves by 20%
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.5]		; 7  works best for lp, ngi way off - not sure why
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		; seem to work fine for uncorrected lp
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.5]		; tbd  
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [4.5,4.0,4.5,4.0]		; ok for o2+,o+ but too high for lpw-waves  
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.5]		; 7  works best for lp, ngi way off - not sure why
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.7,3.2,3.5,3.0]		; 7  works best for lp, ngi way off - not sure why
;if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.9,3.4,3.5,3.0]		;*7b works for wp and lp, o2+ a bit low relative to ngi, o+ ~0.5*ngi
if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.9,3.4,3.5,3.0]		;$ 7 works for wp and lp, ngi o2+,o+ for new cnts_per_cc2

; the following calibrations may be overestimating kk3[3] due to underestimation of droop

;if time_double(time) gt time_double('2016-06-01/00:00') then kk3 = [2.5,1.2,2.5,1.2]				; 20160601*** 	; 6a, att=1-3, good agreement
;if time_double(time) gt time_double('2016-06-01/00:00') then kk3 = [2.5,2.5,2.5,2.0]				; 20160601**** 	; att=1-3, good agreement

;if time_double(time) gt time_double('2016-06-04/00:00') then kk3 = [2.5,2.5,2.5,2.0]				;$ 7 ok agreement sta o2 < ngi o2 at periapsis due to large pot, large suppression corrections

;if time_double(time) gt time_double('2016-06-05/00:00') then kk3 = [2.5,1.2,2.5,1.2]				; 20160605*** 	; much better agreement
;if time_double(time) gt time_double('2016-06-05/00:00') then kk3 = [2.0,2.0,2.5,1.2]				; 20160605*** 	; much better agreement
;if time_double(time) gt time_double('2016-06-05/00:00') then kk3 = [2.0,2.0,2.0,2.0]				; 20160605*** 	; better for O+, att=3 not well determined due to high scpot 

;if time_double(time) gt time_double('2016-06-06/00:00') then kk3 = [2.0,2.0,2.5,1.2]				; 20160606*** 	; use O+ to get kk3 for att=0-1
;if time_double(time) gt time_double('2016-06-06/00:00') then kk3 = [2.0,2.0,2.2,1.2]				; 20160606*** 	; 6a, use O+ to get kk3 for att=0-1
;if time_double(time) gt time_double('2016-06-06/00:00') then kk3 = [2.5,2.5,2.5,1.2]				; 20160606*** 	; 6b, use O+ att=3 not well determined
;if time_double(time) gt time_double('2016-06-06/00:00') then kk3 = [2.5,2.5,2.5,1.5]				; 20160606*** 	; 6c, use O+ att=3 not well determined
;if time_double(time) gt time_double('2016-06-06/00:00') then kk3 = [2.5,2.5,2.5,2.0]				; 20160606**** 	; 6 , use O+ att=3 not well determined

; pot and droop are smaller in fly-Z orientation for deep dip - allowing better kk3 estimates

;if time_double(time) gt time_double('2016-06-07/00:00') then kk3 = [2.5,1.2,2.5,1.2]				; 20160607*** 	; much better agreement
;if time_double(time) gt time_double('2016-06-07/00:00') then kk3 = [2.0,2.0,2.2,1.2]				; 20160607*** 	; 6a,better for O+, att=3 not well determined due to high scpot 
;if time_double(time) gt time_double('2016-06-07/00:00') then kk3 = [2.5,2.5,2.5,1.2]				; 20160607*** 	; 6,better for O+, att=3 not well determined due to high scpot 
if time_double(time) gt time_double('2016-06-07/00:00') and kk3_anode then kk3 = [3.3,3.1,3.0,2.0]		; 20160607***** ; from 5-29, close to being right, O+ a bit low
if time_double(time) gt time_double('2016-06-07/00:00') and kk3_anode then kk3 = [3.5,3.3,3.2,2.5]		; 20160607***** ; from 5-29, close to being right, O+ a bit low


; deep dip 5: starts 6-8 
;if time_double(time) gt time_double('2016-06-08/00:00') then kk3 = [2.5,2.0,2.5,1.5]				; 20160608*** 	; good agreement
if time_double(time) gt time_double('2016-06-08/00:00') and kk3_anode then kk3 = [3.2,2.6,3.0,2.0]		; low for att=1
if time_double(time) gt time_double('2016-06-08/00:00') and kk3_anode then kk3 = [3.5,3.3,3.2,2.5]		; guess

;if time_double(time) gt time_double('2016-06-11/00:00') then kk3 = [2.5,2.0,2.5,1.5]				; 20160611*** 	; better

;if time_double(time) gt time_double('2016-06-12/00:00') then kk3 = [2.5,2.0,2.5,1.5]				; 20160612*** 	; better
;if time_double(time) gt time_double('2016-06-12/00:00') then kk3 = [2.0,2.0,2.0,1.3]				; 20160612*** 	; O+ indicates this is better
;if time_double(time) gt time_double('2016-06-12/00:00') then kk3 = [2.0,2.0,2.0,1.0]				; 20160612*** 	; O+ indicates this is better
;if time_double(time) gt time_double('2016-06-12/00:00') then kk3 = [2.2,2.2,2.2,1.0]				; 20160612*** 	; O+ indicates this is better
;if time_double(time) gt time_double('2016-06-12/00:00') then kk3 = [2.2,2.2,2.5,1.5]				; 20160612**** 	; O+ indicates this is better

if time_double(time) gt time_double('2016-06-12/00:00') and kk3_anode then kk3 = [2.2,2.2,2.5,1.5]		; too low
if time_double(time) gt time_double('2016-06-12/00:00') and kk3_anode then kk3 = [3.2,2.8,3.0,2.0]		;*
if time_double(time) gt time_double('2016-06-12/00:00') and kk3_anode then kk3 = [3.2,2.6,3.0,2.0]		; ok agreement for o2, low for o+



;if time_double(time) gt time_double('2016-06-14/00:00') then kk3 = [2.5,2.0,2.5,1.5]				; 20160614*** 	; better

; deep dip 5: ends 6-15 

;if time_double(time) gt time_double('2016-06-16/00:00') then kk3 = [2.8,1.8,2.5,1.5]				; 20160616*** 	; better agreement
if time_double(time) gt time_double('2016-06-16/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.3]		; tbd
if time_double(time) gt time_double('2016-06-16/00:00') and kk3_anode then kk3 = [2.7,2.2,2.5,2.0]		;*

if time_double(time) gt time_double('2016-06-23/00:00') and kk3_anode then kk3 = [2.7,2.2,2.5,2.0]		; too low
if time_double(time) gt time_double('2016-06-23/00:00') and kk3_anode then kk3 = [3.2,2.8,3.0,2.5]		; too low
if time_double(time) gt time_double('2016-06-23/00:00') and kk3_anode then kk3 = [3.7,3.2,3.5,3.0]		; poortly determined
if time_double(time) gt time_double('2016-06-23/00:00') and kk3_anode then kk3 = [3.7,3.0,3.5,2.5]		; ok agreement

;if time_double(time) gt time_double('2016-06-25/00:00') then kk3 = [2.8,1.8,2.8,1.8]				; 20160625***	; valid for att=0-3, not great fit
if time_double(time) gt time_double('2016-06-25/00:00') and kk3_anode then kk3 = [2.7,2.2,2.5,2.0]		; too low
if time_double(time) gt time_double('2016-06-25/00:00') and kk3_anode then kk3 = [3.5,3.0,3.3,2.8]		;*
if time_double(time) gt time_double('2016-06-25/00:00') and kk3_anode then kk3 = [3.7,3.2,3.5,3.0]		;*ok agreement




;if time_double(time) gt time_double('2016-07-04/00:00') then kk3 = [2.8,1.8,2.8,1.8]				; 20160704*** 	; valid for att=1,2
if time_double(time) gt time_double('2016-07-04/00:00') and kk3_anode then kk3 = [2.9,2.4,2.7,2.2]		; tbd
if time_double(time) gt time_double('2016-07-04/00:00') and kk3_anode then kk3 = [3.9,3.4,3.7,3.2]		;*ok fitting lpw, ngims - some oddities
if time_double(time) gt time_double('2016-07-05/00:00') and kk3_anode then kk3 = [3.9,3.4,3.7,3.2]		;*

;if time_double(time) gt time_double('2016-07-11/00:00') then kk3 = [2.8,1.8,2.8,1.8]				; 20160711*** 	; valid for att=1,2

;if time_double(time) gt time_double('2016-07-14/00:00') then kk3 = [2.7,1.6,2.7,1.6]				; 20160714*** 	; valid for att=1,2

;if time_double(time) gt time_double('2016-07-16/00:00') then kk3 = [2.6,1.4,2.6,1.4]				; 20160716*** 	; valid for att=1,2
if time_double(time) gt time_double('2016-07-16/00:00') and kk3_anode then kk3 = [3.9,3.4,3.9,3.5]		; att=3 not determined 
if time_double(time) gt time_double('2016-07-16/00:00') and kk3_anode then kk3 = [3.9,3.2,3.7,3.0]		; att=3 not determined, slightly better for lpw?? 
if time_double(time) gt time_double('2016-07-16/00:00') and kk3_anode then kk3 = [3.4,2.7,3.2,2.5]		; guess 
if time_double(time) gt time_double('2016-07-16/00:00') and kk3_anode then kk3 = [3.6,2.5,3.2,2.5]		; guess 

;if time_double(time) gt time_double('2016-07-18/00:00') then kk3 = [2.5,1.2,2.5,1.2]				; 20160718*** 	; valid for att=1,2

; deep dip 6 walk in: starts 7-26 
;if time_double(time) gt time_double('2016-07-26/00:00') then kk3 = [2.5,1.2,2.5,1.2]				; 20160726*** 	; valid for att=1,2 walkin deep dip 6
;if time_double(time) gt time_double('2016-07-27/00:00') then kk3 = [2.9,2.0,2.9,2.0]				; 20160727*** 	; valid for att=1,2 start deep dip 6
; deep dip 6: starts 7-28 
;if time_double(time) gt time_double('2016-07-28/00:00') then kk3 = [3.2,2.5,2.9,2.5]				; 20160728*** 	; valid for att=1,2 deep dip 6
;if time_double(time) gt time_double('2016-07-29/00:00') then kk3 = [3.2,2.5,3.2,2.5]				; 20160729*** 	; valid for att=1,2 deep dip 6

;if time_double(time) gt time_double('2016-07-30/00:00') then kk3 = [2.9,2.0,2.9,2.0]				; 20160730*** 	; att=0-2
if time_double(time) gt time_double('2016-07-30/00:00') and kk3_anode then kk3 = [3.9,3.2,3.7,3.0]		; ngi/sta o2+ high, lpw/sta low, no lpw swps, 
if time_double(time) gt time_double('2016-07-30/00:00') and kk3_anode then kk3 = [3.9,3.2,4.0,3.0]		; can't trust lpw, ngi/sta o2+ high
if time_double(time) gt time_double('2016-07-30/00:00') and kk3_anode then kk3 = [4.2,3.5,4.0,3.0]		; redue, ok for ngi/sta o2+, no o+, lp/sta is low, no I-V, suspect ngims
;if time_double(time) gt time_double('2016-07-30/00:00') and kk3_anode then kk3 = [3.8,3.1,3.6,2.9]		; tbd, expected for lp/sta agreement, att=3 not determined



;if time_double(time) gt time_double('2016-07-31/00:00') then kk3 = [2.9,2.0,2.9,2.0]				; 20160730*** 	; att=0-2, poor agreement

;if time_double(time) gt time_double('2016-08-01/00:00') then kk3 = [2.9,1.8,2.8,1.8]				; 20160801**** 	; att=0-2
;if time_double(time) gt time_double('2016-08-02/00:00') then kk3 = [2.9,1.8,2.8,1.8]				; 20160802*** 	; att=0-2
;if time_double(time) gt time_double('2016-08-03/00:00') then kk3 = [2.9,1.8,2.8,1.8]				; 20160802*** 	; att=0-2
; deep dip 6: ends 8-4 
;if time_double(time) gt time_double('2016-08-04/00:00') then kk3 = [2.9,2.9,2.9,2.5]				; 20160804**** 	; att=0-2, no O+, att=3 not determined

if time_double(time) gt time_double('2016-08-08/00:00') and kk3_anode then kk3 = [3.8,3.1,3.6,2.9]		; guess
if time_double(time) gt time_double('2016-08-08/00:00') and kk3_anode then kk3 = [3.2,2.5,3.0,2.3]		; guess

;if time_double(time) gt time_double('2016-08-11/00:00') then kk3 = [2.5,1.8,2.5,1.8]				; 20160804*** 	; att=1-2

;if time_double(time) gt time_double('2016-08-16/00:00') then kk3 = [2.5,1.6,2.5,1.6]				; 20160816*** 	; att=1-2
;if time_double(time) gt time_double('2016-08-16/00:00') then kk3 = [2.5,1.4,2.5,1.4]				; 20160816*** 	; att=0-3, 1.4 not well determined, O+ disagreements

if time_double(time) gt time_double('2016-08-24/00:00') and kk3_anode then kk3 = [3.9,3.4,3.9,3.0]		; too large
if time_double(time) gt time_double('2016-08-24/00:00') and kk3_anode then kk3 = [3.3,2.8,3.3,2.4]		; too large
if time_double(time) gt time_double('2016-08-24/00:00') and kk3_anode then kk3 = [3.2,2.4,3.1,2.2]		; not determined very well

;if time_double(time) gt time_double('2016-08-28/00:00') then kk3 = [2.5,1.4,2.5,1.4]				; 20160828**** 	; att=?-?, anode dependent kk
;if time_double(time) gt time_double('2016-08-28/00:00') then kk3 = [2.9,2.9,2.9,2.5]				; 20160828**** 	; att=?-?, anode dependent kk
;if time_double(time) gt time_double('2016-08-28/00:00') then kk3 = [2.9,2.7,3.1,2.3]				; 20160828*****	; att=?-?, anode dependent kk
;if time_double(time) gt time_double('2016-08-28/00:00') then kk3 = [3.1,2.5,3.2,2.2]				; 20160828*****	; att=0-3, anode dependent kk,  O+ disagreements
if time_double(time) gt time_double('2016-08-28/00:00') and kk3_anode then kk3 = [3.9,3.4,3.9,3.0]		; works well


;if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [3.3,3.1,2.5,2.0]		; tbd** 	 
;if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [2.5,2.5,2.5,2.5]		; tbd** 	 
;if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [2.0,2.0,2.5,2.5]		; tbd** 	 
;if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [1.5,1.5,2.5,2.5]		; att=1  O2+ too high?\; att=2 too low for O+, good for O2+; att=0 too low for O2+	 
;if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [2.5,1.5,2.5,1.5]		; this is best agreement for O2+ att=0-2, but lpw doesn't agree	 
;if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [4.0,3.8,3.7,3.0]		; too low for ngims at att=3 
;if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [4.0,3.8,3.7,3.5]		; att=2 too low, att=1 too high
;if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [3.8,3.6,3.8,3.5]		; att=3 not determined 
if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [3.9,3.4,3.9,3.0]		; att=3 not determined, ok for o+,o2+ ngims, not well determined

if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [2.7,2.4,2.6,2.0]		; tbd
if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [3.2,2.9,3.1,2.5]		; att=1 sta>ngi
if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [3.2,2.6,3.1,2.5]		; att=1 sta>ngi
if time_double(time) gt time_double('2016-08-31/00:00') and kk3_anode then kk3 = [3.2,2.4,3.1,2.2]		;$ good agreement w/ ngi o2+, o+ ngi>sta, no att=3,poor agreement with lpw, in shadow


if time_double(time) gt time_double('2016-09-06/00:00') and kk3_anode then kk3 = [3.2,2.4,3.1,2.2]		;$ 7, suppression too high to use O+



;if time_double(time) gt time_double('2016-09-10/00:00') and kk3_anode then kk3 = [3.0,2.4,2.9,2.0]		; tbd , guess
;if time_double(time) gt time_double('2016-09-10/00:00') and kk3_anode then kk3 = [3.0,2.4,2.9,2.2]		; good agreement w/ ngi O2+att=3,4, o+ poor
;if time_double(time) gt time_double('2016-09-10/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.2]		; 7a not enough
;if time_double(time) gt time_double('2016-09-10/00:00') and kk3_anode then kk3 = [3.2,2.9,2.9,2.2]		; better agreement w/ ngi o+
;if time_double(time) gt time_double('2016-09-10/00:00') and kk3_anode then kk3 = [3.2,2.9,3.1,2.5]		;$ 7b better agreement w/ ngi o+
;if time_double(time) gt time_double('2016-09-10/00:00') and kk3_anode then kk3 = [3.5,3.3,3.3,2.9]		;  better agreement w/ ngi o+
;if time_double(time) gt time_double('2016-09-10/00:00') and kk3_anode then kk3 = [3.4,3.2,3.2,2.9]		;$ 7 better agreement w/ ngi o+
if time_double(time) gt time_double('2016-09-10/00:00') and kk3_anode then kk3 = [3.0,2.4,2.8,2.3]		;$ 7 checked 20161201




;if time_double(time) gt time_double('2016-09-13/00:00') and kk3_anode then kk3 = [3.0,2.8,2.8,2.4]		; sta<ngi
;if time_double(time) gt time_double('2016-09-13/00:00') and kk3_anode then kk3 = [3.2,3.0,3.0,2.6]		; sta<ngi
;if time_double(time) gt time_double('2016-09-13/00:00') and kk3_anode then kk3 = [3.4,3.2,3.2,2.9]		;$ 7 good agreement on inbound, outbound sta>ngi, not sure why

;if time_double(time) gt time_double('2016-09-14/00:00') and kk3_anode then kk3 = [3.1,2.8,2.8,2.3]		; tbd guess, better agreement w/ ngi o+
;if time_double(time) gt time_double('2016-09-14/00:00') and kk3_anode then kk3 = [3.0,2.5,2.7,2.2]		; tbd guess, better agreement w/ ngi o+



;if time_double(time) gt time_double('2016-09-15/00:00') and kk3_anode then kk3 = [3.2,2.9,2.9,2.4]		; this does a poor job on outbound when pot=0, ngi_emin = 5.0
;if time_double(time) gt time_double('2016-09-15/00:00') and kk3_anode then kk3 = [3.5,2.7,2.9,2.0]		; works for o2+ over entire pass for cc2=340
;if time_double(time) gt time_double('2016-09-15/00:00') and kk3_anode then kk3 = [3.6,2.9,3.1,2.2]		; works for o2+ over entire pass for cc2=340
;if time_double(time) gt time_double('2016-09-15/00:00') and kk3_anode then kk3 = [3.2,2.4,3.1,2.2]		;$ 7b, suppression too high to use O+
;if time_double(time) gt time_double('2016-09-15/00:00') and kk3_anode then kk3 = [2.2,1.5,2.2,1.5]		; testing
;if time_double(time) gt time_double('2016-09-15/00:00') and kk3_anode then kk3 = [3.0,2.7,2.7,2.2]		;$ 7, doesn't match second half of pass, this may be a problem with ngims sc_pot calib
if time_double(time) gt time_double('2016-09-15/00:00') and kk3_anode then kk3 = [3.1,2.8,2.8,2.3]		; provides better match over orbit with ngi cc2=370




if time_double(time) gt time_double('2016-09-16/00:00') and kk3_anode then kk3 = [3.4,3.2,3.2,2.9]		; sta>ngi
if time_double(time) gt time_double('2016-09-16/00:00') and kk3_anode then kk3 = [3.0,2.8,2.8,2.4]		; sta>ngi
if time_double(time) gt time_double('2016-09-16/00:00') and kk3_anode then kk3 = [3.0,2.7,2.7,2.2]		;$ 7 good agreement on inbound, outbound sta>ngi, not sure why


if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [3.9,3.4,3.9,3.2]		; sta>ngi
if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [3.7,3.2,3.5,3.0]		; sta~ngi, lpw~0.75sta 
if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [3.2,2.7,3.0,2.5]		; sta>lpw-waves 
if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [2.7,2.2,2.5,2.0]		; sta~lpw, sta<ngi o+ 
if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [3.5,3.2,3.3,2.8]		;*sta~ngi good agreement o+,o2+, lpw~0.75sta 
if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [2.7,2.4,2.6,2.0]		;  good agreement w/ ngi and lpw and waves
if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [2.9,2.6,2.6,2.0]		; ok agreement
if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [2.7,2.2,2.4,1.8]		;$ 7 good agreement w/ ngi and lpw and waves


;if time_double(time) gt time_double('2016-09-18/00:00') and kk3_anode then kk3 = [3.9,3.4,3.9,3.2]		; 
;if time_double(time) gt time_double('2016-09-18/00:00') and kk3_anode then kk3 = [3.9,3.4,3.9,3.0]		; ngi/sta ratios a bit low, 
;if time_double(time) gt time_double('2016-09-18/00:00') and kk3_anode then kk3 = [3.7,3.2,3.7,2.8]		; ngim crib was screwed up
if time_double(time) gt time_double('2016-09-18/00:00') and kk3_anode then kk3 = [2.9,2.6,2.6,2.0]		;$ 7 good agreement w/ ngi and lpw and waves

if time_double(time) gt time_double('2016-09-19/00:00') and kk3_anode then kk3 = [2.5,1.5,2.5,1.5]		; too low for all attenuator states 
if time_double(time) gt time_double('2016-09-19/00:00') and kk3_anode then kk3 = [3.5,3.3,3.2,2.5]		; poor agreement with ngims 
if time_double(time) gt time_double('2016-09-19/00:00') and kk3_anode then kk3 = [4.0,3.8,3.7,3.0]		; redue - good agreement with ngims 
if time_double(time) gt time_double('2016-09-19/00:00') and kk3_anode then kk3 = [4.0,3.8,3.7,3.0]		; good agreement with ngims o+ 
if time_double(time) gt time_double('2016-09-19/00:00') and kk3_anode then kk3 = [4.0,3.5,3.7,3.0]		; better agreement with ngims o+ - I think ngim crib was screwed up
if time_double(time) gt time_double('2016-09-19/00:00') and kk3_anode then kk3 = [2.9,2.6,2.6,2.0]		;$ 7, good agreement

if time_double(time) gt time_double('2016-09-20/00:00') and kk3_anode then kk3 = [2.9,2.5,2.6,2.0]		; testing


; 9 periapsis passes with static in protect mode 9-21 to 9-23 -- did this exposure change kk3
; the last 5 orbits pointed static in ram direction with attenuator open during ngi neutral wind measurements

if time_double(time) gt time_double('2016-09-23/00:00') and kk3_anode then kk3 = [2.9,2.5,2.6,2.0]		;$ 7, good agreement

if time_double(time) gt time_double('2016-09-24/00:00') and kk3_anode then kk3 = [2.9,2.5,2.6,2.0]		;* 7, good agreement scenario 1, ngi_o2

;if time_double(time) gt time_double('2016-09-25/00:00') and kk3_anode then kk3 = [3.2,3.0,3.2,3.0]		; 
;if time_double(time) gt time_double('2016-09-25/00:00') and kk3_anode then kk3 = [3.2,3.0,3.2,3.0]-1.0		;  
;if time_double(time) gt time_double('2016-09-25/00:00') and kk3_anode then kk3 = [3.5,3.2,3.5,3.0]		;*  
;if time_double(time) gt time_double('2016-09-25/00:00') and kk3_anode then kk3 = [3.5,3.2,3.3,2.8]		;  test
;if time_double(time) gt time_double('2016-09-25/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;* 7a good agreement with ngims o+ 
;if time_double(time) gt time_double('2016-09-25/00:00') and kk3_anode then kk3 = [3.0,3.0,3.0,3.0]		;* better agreement with lpw on flanks where ngims o+ is poor, suppression large 
;if time_double(time) gt time_double('2016-09-25/00:00') and kk3_anode then kk3 = [2.9,2.6,2.6,2.0]		;$ 7b same as 9-17
;if time_double(time) gt time_double('2016-09-25/00:00') and kk3_anode then kk3 = [3.3,3.0,3.0,2.4]		;$ 7 works better, higher suppression due to 9 orbits in protect mode 9-21 to 9-23

;if time_double(time) gt time_double('2016-09-27/00:00') and kk3_anode then kk3 = [3.0,2.7,2.7,2.2]		;$ 7, good agreement, ngi a bit >sta for att=3
if time_double(time) gt time_double('2016-09-24/00:00') and kk3_anode then kk3 = [2.9,2.5,2.6,2.0]		;* 7, good agreement scenario 1, ngi_o2


if time_double(time) gt time_double('2016-09-29/00:00') and kk3_anode then kk3 = [3.7,3.2,3.5,3.0]		;* 7a good agreement with ngims o+,o2+, lpw 15% low 
if time_double(time) gt time_double('2016-09-29/00:00') and kk3_anode then kk3 = [3.2,2.7,3.0,2.5]		;* 7 good agreement with lpw,ngi-o2+, 20% low for o+
if time_double(time) gt time_double('2016-09-29/00:00') and kk3_anode then kk3 = [2.7,2.4,2.6,1.8]		;  works for ngi o+,O2+, and lpw
if time_double(time) gt time_double('2016-09-29/00:00') and kk3_anode then kk3 = [2.7,2.4,2.6,2.0]		;$ good agreement w/ ngi and lpw

if time_double(time) gt time_double('2016-10-01/00:00') and kk3_anode then kk3 = [2.7,2.4,2.6,2.0]		;$ good agreement w/ ngi and lpw

; the following give the better agreement for sta in scenario 1 - sta_o < ngi_o probably due to suppression falling off faster than modeled.

if time_double(time) gt time_double('2016-10-05/00:00') and kk3_anode then kk3 = [2.7,2.3,2.5,1.8]		;* 7, good agreement scenario 1, ngi_o2
if time_double(time) gt time_double('2016-10-06/00:00') and kk3_anode then kk3 = [2.7,2.3,2.5,1.8]		; testing
if time_double(time) gt time_double('2016-10-07/00:00') and kk3_anode then kk3 = [2.6,2.2,2.4,1.7]		; testing
if time_double(time) gt time_double('2016-10-08/00:00') and kk3_anode then kk3 = [2.6,2.2,2.4,1.7]		; testing
if time_double(time) gt time_double('2016-10-09/00:00') and kk3_anode then kk3 = [2.6,2.2,2.4,1.7]		; testing
if time_double(time) gt time_double('2016-10-10/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]		; testing
if time_double(time) gt time_double('2016-10-11/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]		; testing

;if time_double(time) gt time_double('2016-10-18/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]+.7		; needed to get sta O+ ~ ngi O+
if time_double(time) gt time_double('2016-10-18/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]		; testing

if time_double(time) gt time_double('2016-10-22/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]		; poor for O+

if time_double(time) gt time_double('2016-10-25/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]		; checked 20161206, pot gradient

if time_double(time) gt time_double('2016-10-29/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]		; sta too small
if time_double(time) gt time_double('2016-10-29/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,2.0]		; tbd


if time_double(time) gt time_double('2016-10-31/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]		; ok agreement, 3 ngims, checked 20161129

if time_double(time) gt time_double('2016-11-01/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]		;   
if time_double(time) gt time_double('2016-11-01/00:00') and kk3_anode then kk3 = [2.6,2.3,2.5,2.2]		;  
if time_double(time) gt time_double('2016-11-01/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,2.0]		; 3 ngims, checked 20161130

;if time_double(time) gt time_double('2016-11-03/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,2.0]		; tbd consecutive ngi


if time_double(time) gt time_double('2016-11-08/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]		; 
if time_double(time) gt time_double('2016-11-08/00:00') and kk3_anode then kk3 = [2.4,2.1,2.3,2.0]		; 
if time_double(time) gt time_double('2016-11-08/00:00') and kk3_anode then kk3 = [2.6,2.3,2.5,2.2]		; ok agreement, 1 ngims, checked 20161129


if time_double(time) gt time_double('2016-11-15/00:00') and kk3_anode then kk3 = [2.6,2.3,2.5,2.2]		; ok agreement, 1 ngims, checked 20161128

; 11 periapsis in protect mode 20161116-18 - may increase ion suppression

if time_double(time) gt time_double('2016-11-18/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,1.6]		; sta too low
if time_double(time) gt time_double('2016-11-18/00:00') and kk3_anode then kk3 = [2.6,2.3,2.5,2.2]		; ok agreement, 2 ngims, checked 20161128


; s/c charging from 20161122 to 20170131


if time_double(time) gt time_double('2017-01-31/00:00') and kk3_anode then kk3 = [2.6,2.1,2.5,1.0]		; ok O2+ poor O+, 2 ngims, checked 20170221
if time_double(time) gt time_double('2017-01-31/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.5]		; tbd - needs to be checked
if time_double(time) gt time_double('2017-01-31/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,1.5]		; ok O2+ O+, 3 ngims, checked 20170308

if time_double(time) gt time_double('2017-02-09/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,1.8]		; ok O2+ O+, 3 ngims, checked 20170308

if time_double(time) gt time_double('2017-02-12/00:00') and kk3_anode then kk3 = [2.6,2.1,2.5,1.0]		; ok for O2+, 2 ngims, checked 20170222
if time_double(time) gt time_double('2017-02-12/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.5]		; ok O2+ O+, 3 ngims, checked 20170222

if time_double(time) gt time_double('2017-02-14/00:00') and kk3_anode then kk3 = [3.5,3.5,3.0,2.5]		; ok O2+ O+, 3 ngims, checked 20170222

if time_double(time) gt time_double('2017-02-16/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.5]		; ok O2+ O+, 3 ngims, checked 20170222

if time_double(time) gt time_double('2017-02-16/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.1]		; ok O2+ O+, 3 ngims, checked 20170222

if time_double(time) gt time_double('2017-02-20/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,1.8]		; ok O2+ O+, 3 ngims, checked 20170308

if time_double(time) gt time_double('2017-02-25/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.1]		; ok O2+ O+, 3 ngims, checked 20170222
if time_double(time) gt time_double('2017-02-25/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,1.8]		; ok O2+ O+, 3 ngims, checked 20170308

if time_double(time) gt time_double('2017-02-27/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.1]		; ok O2+ O+, 3 ngims, checked 20170307








;********************************************************************************************************************************************************
;********************************************************************************************************************************************************
;********************************************************************************************************************************************************
;********************************************************************************************************************************************************
; values above this line need to be recommputed 

if time_double(time) gt time_double('2015-11-12/00:00') and kk3_anode then kk3 = [4.0,3.8,4.0,3.8]	; 2 ngims, ok agreement, 20180919


if time_double(time) gt time_double('2015-11-16/00:00') and kk3_anode then kk3 = [3.7,3.6,3.6,3.0]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw
if time_double(time) gt time_double('2015-11-16/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw


if time_double(time) gt time_double('2016-03-22/00:00') and kk3_anode then kk3 = [4.0,3.8,4.0,3.8]		; way too large
if time_double(time) gt time_double('2016-03-22/00:00') and kk3_anode then kk3 = [3.0,2.8,2.8,1.7]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw
if time_double(time) gt time_double('2016-03-22/00:00') and kk3_anode then kk3 = [3.3,2.7,3.2,2.2]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw
if time_double(time) gt time_double('2016-03-22/00:00') and kk3_anode then kk3 = [3.2,2.9,3.1,2.4]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw
if time_double(time) gt time_double('2016-03-22/00:00') and kk3_anode then kk3 = [3.2,3.1,3.1,2.5]		;**sta o2+ ok, 2 ngims, checked 20190522, lpw

if time_double(time) gt time_double('2016-03-25/00:00') and kk3_anode then kk3 = [3.4,2.9,3.2,2.5]		; sta O2 ok, 3 ngims, checked 20171126, sza=70

if time_double(time) gt time_double('2016-03-30/00:00') and kk3_anode then kk3 = [3.1,2.6,2.9,2.2]		; sta O2 ok, 2 ngims, checked 20191023, sza=68

if time_double(time) gt time_double('2016-04-09/00:00') and kk3_anode then kk3 = [3.0,2.8,2.8,1.7]		; sta O2 ok, 3 ngims, checked 20171123, sza=?

if time_double(time) gt time_double('2016-04-19/00:00') and kk3_anode then kk3 = [3.0,2.8,2.8,1.7]		;**sta o2+ ok, 3 ngims, checked 20190521, no lpw?

if time_double(time) gt time_double('2016-05-25/00:00') and kk3_anode then kk3 = [3.0,2.2,2.8,1.8]		; sta O2 low, 3 ngims, checked 20180330, sza=75

; Attenuator open for 6 periapsis passes starting 20160526
if time_double(time) gt time_double('2016-05-27/00:00') and kk3_anode then kk3 = [3.6,3.2,3.5,2.8]		; assume same as 20160529

if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.0,2.2,2.8,1.8]		; sta O2 low, 3 ngims, checked 20180330, sza=75
if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.6,3.2,3.5,2.8]		;**sta o2+ ok, 3 ngims, checked 20190521, lpw?

;********************************************************************************************************************************************************
;  Nightside periapsis starts	20160615 (ended 20160915)


if time_double(time) gt time_double('2016-06-16/00:00') and kk3_anode then kk3 = [3.0,2.2,2.8,1.8]		; sta O2 ok, 3 ngims, checked 20171123, sza=?

if time_double(time) gt time_double('2016-07-16/00:00') and kk3_anode then kk3 = [3.2,1.7,2.8,1.5]		; sta O2 ok, 3 ngims, checked 20171123, sza=150

;*********************************************************************************************************************************************************
; 2016-07-26  start deep dip 6

if time_double(time) gt time_double('2016-07-31/00:00') and kk3_anode then kk3 = [3.2,1.7,2.8,1.5]		; sta O2 ok, 3 ngims, checked 20190228, sza=165
if time_double(time) gt time_double('2016-07-31/00:00') and kk3_anode then kk3 = [3.2,2.0,3.1,2.0]		; sta O2 ok, 3 ngims, checked 20190228, sza=165


; 2016-08-04  end deep dip 6
;*********************************************************************************************************************************************************

if time_double(time) gt time_double('2016-08-24/00:00') and kk3_anode then kk3 = [2.8,2.0,2.8,1.5]		; sta o2 ok, 3 ngims, checked 20171123 sza=?

if time_double(time) gt time_double('2016-08-28/00:00') and kk3_anode then kk3 = [2.8,2.0,2.8,1.5]		; sta O2 ok, 3 ngims, checked 20171122 sza=130

if time_double(time) gt time_double('2016-09-10/00:00') and kk3_anode then kk3 = [2.3,1.8,2.3,1.5]		; tbd
if time_double(time) gt time_double('2016-09-10/00:00') and kk3_anode then kk3 = [2.5,1.8,2.5,1.7]		; sta O2 ok, 3 ngims, checked 20171124

;  Nightside periapsis ends	20160915 (started 20160615)
;********************************************************************************************************************************************************

if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [2.5,1.8,2.5,1.7]		; 
if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [1.7,1.4,1.6,1.3]		;**sta o2+ ok, 2 ngims, checked 20190521, lpw?


if time_double(time) gt time_double('2016-09-24/00:00') and kk3_anode then kk3 = [1.9,1.6,1.8,1.5]		; sta O2 ok, 2 ngims, checked 20171122 sza=87

if time_double(time) gt time_double('2016-09-27/00:00') and kk3_anode then kk3 = [1.9,1.6,1.8,1.5]		; sta O2 ok, 3 ngims, checked 20171122 sza=83

;scenario 1 2016-10-04

if time_double(time) gt time_double('2016-10-05/00:00') and kk3_anode then kk3 = [1.9,1.6,1.8,1.5]		; sta O2 ok, 5 ngims, 
if time_double(time) gt time_double('2016-10-05/00:00') and kk3_anode then kk3 = [1.4,1.1,1.3,1.0]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V, no lpw
if time_double(time) gt time_double('2016-10-05/00:00') and kk3_anode then kk3 = [1.7,1.4,1.6,1.3]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V, no lpw

if time_double(time) gt time_double('2016-10-06/00:00') and kk3_anode then kk3 = [1.9,1.6,1.8,1.5]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V

if time_double(time) gt time_double('2016-10-07/00:00') and kk3_anode then kk3 = [1.9,1.6,1.8,1.5]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V
if time_double(time) gt time_double('2016-10-07/00:00') and kk3_anode then kk3 = [1.7,1.4,1.6,1.3]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V

if time_double(time) gt time_double('2016-10-09/00:00') and kk3_anode then kk3 = [1.7,1.4,1.6,1.3]		;**sta o2+ ok, 5 ngims, checked 20190520, scenario 1 -0.1/-2.5V

;if time_double(time) gt time_double('2016-10-29/00:00') and kk3_anode then kk3 = [2.5,2.1,2.3,2.0]		; old
;if time_double(time) gt time_double('2016-10-29/00:00') and kk3_anode then kk3 = [2.2,1.9,2.1,1.8]		; sta O2 ok, 3 ngims, checked 20171122
;if time_double(time) gt time_double('2016-10-29/00:00') and kk3_anode then kk3 = [1.2,1.1,1.3,1.0]		; sta O2 ok, 3 ngims, checked 20171122
if time_double(time) gt time_double('2016-10-29/00:00') and kk3_anode then kk3 = [1.9,1.6,1.8,1.5]		; sta O2 ok, 3 ngims, checked 20171122

;if time_double(time) gt time_double('2016-11-20/00:00') and kk3_anode then kk3 = [2.6,2.3,2.5,2.2]		; old, 3 ngims, checked 20171120
if time_double(time) gt time_double('2016-11-20/00:00') and kk3_anode then kk3 = [2.2,1.9,2.1,1.8]		; sta O2 ok, 3 ngims, checked 20171120

if time_double(time) gt time_double('2016-12-01/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, ? ngims, checked 20190520

; s/c charging from 20161122 to 20170131





;if time_double(time) gt time_double('2017-02-09/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,1.8]		; sta O2+ 14% high, 3 ngims, checked 20171120, sza=112, -0.8 to -2.2V
;if time_double(time) gt time_double('2017-02-09/00:00') and kk3_anode then kk3 = [2.2,2.0,2.0,1.0]		; sta O2+ closer, 3 ngims, checked 20171120
if time_double(time) gt time_double('2017-02-09/00:00') and kk3_anode then kk3 = [2.3,1.8,2.3,0.0]		; sta O2+ ok , 3 ngims, checked 20171120

if time_double(time) gt time_double('2017-02-16/00:00') and kk3_anode then kk3 = [2.3,1.8,2.3,0.0]		; ok O2+ ok, 3 ngims, checked 20171120


if time_double(time) gt time_double('2017-03-01/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, 3 ngims, checked 20190519

if time_double(time) gt time_double('2017-03-02/00:00') and kk3_anode then kk3 = [2.2,2.0,2.0,1.0]		; ok O2+ poorly determined, 3 ngims, checked 20171117, sza=97

;if time_double(time) gt time_double('2017-03-07/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.0]		; ok O2+ O+, 3 ngims, checked 20170307
if time_double(time) gt time_double('2017-03-07/00:00') and kk3_anode then kk3 = [2.2,2.0,2.0,1.0]		; ok O2+ O+, 3 ngims, checked 20171117, sza=94

;if time_double(time) gt time_double('2017-03-15/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.0]		; ok O2+ O+, 3 ngims, checked 20170324

if time_double(time) gt time_double('2017-03-18/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.0]		; sta O2+ 20% high, 3 ngims, checked 20171117
if time_double(time) gt time_double('2017-03-18/00:00') and kk3_anode then kk3 = [2.2,2.0,2.0,1.0]		; sta O2+ 10% high, 3 ngims, checked 20171117
if time_double(time) gt time_double('2017-03-18/00:00') and kk3_anode then kk3 = [1.2,1.0,1.0,0.0]		; sta O2+ ok, 3 ngims, checked 20171117
if time_double(time) gt time_double('2017-03-18/00:00') and kk3_anode then kk3 = [2.0,1.5,1.0,0.0]		; sta O2+ ok, 3 ngims, checked 20171117

if time_double(time) gt time_double('2017-03-22/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, 3 ngims, checked 20190519

if time_double(time) gt time_double('2017-03-25/00:00') and kk3_anode then kk3 = [2.0,1.5,1.0,0.0]		; sta O2+ ok, 3 ngims, checked 20171117, sza=73
if time_double(time) gt time_double('2017-03-25/00:00') and kk3_anode then kk3 = [2.0,1.5,1.5,0.5]		; sta O2+ ok, 3 ngims, checked 20171117



if time_double(time) gt time_double('2017-04-01/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta O2+ 10% high, 2 ngims, checked 20171116, sza=48
if time_double(time) gt time_double('2017-04-01/00:00') and kk3_anode then kk3 = [2.2,2.0,2.0,1.0]		; sta O2+ ok, 2 ngims, checked 20171116, sza=63
if time_double(time) gt time_double('2017-04-01/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, 3 ngims, checked 20190519


if time_double(time) gt time_double('2017-04-15/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.0]		; sta O2+ 20% high, 2 ngims, checked 20171113, sza=29
if time_double(time) gt time_double('2017-04-15/00:00') and kk3_anode then kk3 = [2.2,2.0,2.2,1.0]		; sta O2+  6%  low, 2 ngims, checked 20171113, sza=29
if time_double(time) gt time_double('2017-04-15/00:00') and kk3_anode then kk3 = [2.5,2.3,2.5,1.3]		; sta O2+  6%  low, 2 ngims, checked 20171113, sza=29
if time_double(time) gt time_double('2017-04-15/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta O2+ ok, 2 ngims, checked 20171116, sza=48


;if time_double(time) gt time_double('2017-04-22/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta O2+ 10% low, 3 ngims, checked 20171117, sza=41
if time_double(time) gt time_double('2017-04-22/00:00') and kk3_anode then kk3 = [2.2,2.0,2.2,1.0]		; sta O2+ ok, 3 ngims, checked 20171117, sza=41

if time_double(time) gt time_double('2017-05-01/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, 2 ngims, checked 20190518


;if time_double(time) gt time_double('2017-05-03/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.0]		; this used to work, 
;if time_double(time) gt time_double('2017-05-03/00:00') and kk3_anode then kk3 = [1.2,1.0,1.0,0.0]		; sta O2+ too small, 
;if time_double(time) gt time_double('2017-05-03/00:00') and kk3_anode then kk3 = [2.2,2.0,2.0,1.0]		; sta O2+ ok, 3 ngims, checked 20171113, sza=36
if time_double(time) gt time_double('2017-05-03/00:00') and kk3_anode then kk3 = [2.2,2.0,2.2,1.0]		; sta O2+ ok, 3 ngims, checked 20171113, sza=36



;if time_double(time) gt time_double('2017-05-08/00:00') and kk3_anode then kk3 = [2.2,2.0,2.2,1.0]		; sta O2+ 5% high, 3 ngims, checked 20171117, sza=30, -0.4 to -1.0V
if time_double(time) gt time_double('2017-05-08/00:00') and kk3_anode then kk3 = [1.9,1.7,1.7,0.5]		; sta O2+ ok, 3 ngims, checked 20171117, sza=30, -0.4 to -1.0V


;if time_double(time) gt time_double('2017-05-09/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.0]		; this used to work sta O2+ 40% high , 2 ngims, checked 20171113
;if time_double(time) gt time_double('2017-05-09/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta O2+ 20% high , 2 ngims, checked 20171113, sza=29
;if time_double(time) gt time_double('2017-05-09/00:00') and kk3_anode then kk3 = [2.2,2.0,2.0,1.0]		; sta O2+ 10% high , 2 ngims, checked 20171113, sza=29
if time_double(time) gt time_double('2017-05-09/00:00') and kk3_anode then kk3 = [1.2,1.0,1.0,0.0]		; sta O2+ ok, 2 ngims, checked 20171113, sza=29

; 17-05-10 to 17-07-11 no low energy periapsis data or s/c charging

if time_double(time) gt time_double('2017-07-12/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.0]		; O2+ ok, 3 ngims, checked 20171117

if time_double(time) gt time_double('2017-07-15/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.0]		; O2+ ok, 3 ngims, checked 20171115
 

if time_double(time) gt time_double('2017-07-16/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; O2+ ok , 2 ngims, checked 20180802

if time_double(time) gt time_double('2017-07-18/00:00') and kk3_anode then kk3 = [3.5,3.0,3.0,2.0]		; too high , 2 ngims, checked 20180802
if time_double(time) gt time_double('2017-07-18/00:00') and kk3_anode then kk3 = [2.2,2.0,2.0,1.0]		; , 2 ngims, checked 20180802
if time_double(time) gt time_double('2017-07-18/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; O2+ ok , 2 ngims, checked 20180802




; 17-07-19 to 17-08-14 no low energy periapsis data 

; 17-08-15 deep dip 7

if time_double(time) gt time_double('2017-08-14/00:00') and kk3_anode then kk3 = [3.7,3.2,3.2,2.2]		; assume continuous

if time_double(time) gt time_double('2017-08-17/00:00') and kk3_anode then kk3 = [3.7,3.2,3.2,2.2]		; ok O2+, O+ is very low, 3 ngims, checked 20171029


if time_double(time) gt time_double('2017-08-19/00:00') and kk3_anode then kk3 = [3.8,3.3,3.3,2.3]		; ok O2+, O+ is very low, 3 ngims, checked 20171029

;if time_double(time) gt time_double('2017-08-21/00:00') and kk3_anode then kk3 = [3.7,3.2,3.2,2.2]		; ok O2+, O+ is very low, 3 ngims, checked 20171030
if time_double(time) gt time_double('2017-08-22/00:00') and kk3_anode then kk3 = [3.7,3.2,3.2,2.2]		; ok O2+, O+ is very low, 3 ngims, checked 20171030

;if time_double(time) gt time_double('2017-08-23/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; O2+ 20% low, O+ is very low, 3 ngims, 
if time_double(time) gt time_double('2017-08-23/00:00') and kk3_anode then kk3 = [3.7,3.2,3.2,2.2]		; O2+ ok, O+ is very low, 2 ngims, checked tbd

if time_double(time) gt time_double('2017-08-24/00:00') and kk3_anode then kk3 = [3.8,3.3,3.3,2.3]		; ok O2+, O+ is very low, 3 ngims, checked 20171030

;17-08-24 end deep dip 7
; there seems to be a sudden change in ion suppression on 2017-08-25, ion suppression recovery

if time_double(time) gt time_double('2017-08-25/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; O2+ 5% low except 1st orbit is 25% lower??, O+ is very low, 3 ngims, checked 20171003
if time_double(time) gt time_double('2017-08-25/00:00') and kk3_anode then kk3 = [3.1,2.6,3.1,2.5]		; **sta o2+ ok, 3 ngims, checked 20190517, gf_update=1.4
if time_double(time) gt time_double('2017-08-25/00:00') and kk3_anode then kk3 = [2.9,2.6,2.9,2.3]		; **sta o2+ ok, 3 ngims, checked 20190517, gf_update=1.4
if time_double(time) gt time_double('2017-08-25/00:00') and kk3_anode then kk3 = [2.8,2.5,2.8,2.2]		; **sta o2+ ok, 3 ngims, checked 20190517, gf_update=1.4
if time_double(time) gt time_double('2017-08-25/00:00') and kk3_anode then kk3 = [2.6,2.3,2.6,2.0]		; **sta o2+ ok, 3 ngims, checked 20190517, gf_update=1.4

if time_double(time) gt time_double('2017-08-29/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; O2+ , O+ is very low, 3 ngims, checked 20171027




if time_double(time) gt time_double('2017-08-30/00:00') and kk3_anode then kk3 = [3.8,3.3,3.3,2.3]		; **sta o2+ o, O+ is very low, 2 ngims, checked 20191021
if time_double(time) gt time_double('2017-08-30/00:00') and kk3_anode then kk3 = [3.0,2.8,2.8,1.8]		; **sta o2+ o, O+ is very low, 2 ngims, checked 20191021
if time_double(time) gt time_double('2017-08-30/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; **sta o2+ o, O+ is very low, 2 ngims, checked 20191021




if time_double(time) gt time_double('2017-09-01/00:00') and kk3_anode then kk3 = [3.1,2.9,3.1,2.5]		;**sta o2+ ok, 3 ngims, checked 20190513
if time_double(time) gt time_double('2017-09-01/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, 3 ngims, checked 20190513

if time_double(time) gt time_double('2017-09-02/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; scenario 1, ok O2+, O+ is very low, 3 ngims, checked 20171002

if time_double(time) gt time_double('2017-09-09/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; ok O2+ maybe a bit low, 2 ngims, checked 20171109


if time_double(time) gt time_double('2017-09-16/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; poor O2+ but lp/sta suggest problem is with ngi, O+ is very low, 3 ngims, checked 20171003

if time_double(time) gt time_double('2017-09-19/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; ok O2+, O+ is very low, 3 ngims, checked 20171108

if time_double(time) gt time_double('2017-10-01/00:00') and kk3_anode then kk3 = [3.3,3.1,3.3,2.7]		;**sta o2+ ok, 3 ngims, checked 20190513
if time_double(time) gt time_double('2017-10-01/00:00') and kk3_anode then kk3 = [3.1,2.9,3.1,2.5]		;**sta o2+ ok, 3 ngims, checked 20190513, gf_update=1.6
if time_double(time) gt time_double('2017-10-01/00:00') and kk3_anode then kk3 = [2.3,2.1,2.3,1.7]		;**sta o2+ ok, 3 ngims, checked 20190513, gf_update=1.4

if time_double(time) gt time_double('2017-10-05/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; 3 ngims, checked 20171020

if time_double(time) gt time_double('2017-10-11/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta o2+ high by 12%, 2 ngims, checked 20171028
;if time_double(time) gt time_double('2017-10-11/00:00') and kk3_anode then kk3 = [1.2,1.0,1.0,0.0]		; redue sta o2+ tbd, 2 ngims, checked tbd

if time_double(time) gt time_double('2017-10-14/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; 2 ngims, checked 20171028

if time_double(time) gt time_double('2017-10-15/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; 3 ngims, checked 20171030 

; 17-10-16 start deep dip 8

if time_double(time) gt time_double('2017-10-16/00:00') and kk3_anode then kk3 = [3.4,3.2,3.2,2.2]		; not well determined, 3 ngims-saturated, checked 20171030

if time_double(time) gt time_double('2017-10-17/00:00') and kk3_anode then kk3 = [3.4,3.2,3.2,2.2]		; not well determined, 3 ngims-saturated, checked 20171028
if time_double(time) gt time_double('2017-10-17/00:00') and kk3_anode then kk3 = [3.3,2.4,3.3,2.3]		;**sta o2+ ok, 5 ngims, checked 20190513
if time_double(time) gt time_double('2017-10-17/00:00') and kk3_anode then kk3 = [3.3,3.1,3.3,2.7]		;**sta o2+ ok, 5 ngims, checked 20190513, gf_update=1.6
if time_double(time) gt time_double('2017-10-17/00:00') and kk3_anode then kk3 = [3.0,2.8,3.0,2.4]		;**sta o2+ ok, 5 ngims, checked 20190513, gf_update=1.4

if time_double(time) gt time_double('2017-10-19/00:00') and kk3_anode then kk3 = [3.5,3.3,3.3,2.3]		; not well determined, 3 ngims-saturated, checked 20171029

if time_double(time) gt time_double('2017-10-20/00:00') and kk3_anode then kk3 = [3.6,3.4,3.4,2.4]		; not well determined, 3 ngims-saturated, checked 20171028

if time_double(time) gt time_double('2017-10-22/00:00') and kk3_anode then kk3 = [3.6,3.4,3.4,2.4]		; not well determined, 3 ngims-saturated, checked 20171028

; 17-08-23 end deep dip 8

if time_double(time) gt time_double('2017-10-24/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; 3 ngims, checked 20171105

if time_double(time) gt time_double('2017-11-01/00:00') and kk3_anode then kk3 = [3.3,2.4,3.3,2.3]		;**sta o2+ ok, 5 ngims, checked 20190512, gf_update=1.6
if time_double(time) gt time_double('2017-11-01/00:00') and kk3_anode then kk3 = [2.8,1.9,2.8,1.8]		;**sta o2+ ok, 5 ngims, checked 20190514, gf_update=1.4

if time_double(time) gt time_double('2017-11-07/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta o2+ ok - may be 10% high, 3 ngims, checked 20171116

if time_double(time) gt time_double('2017-11-13/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta o2+ 10% high, 6 ngims, checked 20171121
if time_double(time) gt time_double('2017-11-13/00:00') and kk3_anode then kk3 = [1.2,1.0,1.0,0.0]		; sta o2+ ok, 3 ngims, checked 20171121

if time_double(time) gt time_double('2017-11-25/00:00') and kk3_anode then kk3 = [1.2,1.0,1.0,0.0]		; sta o2+ ok - but 20% high at times, perhaps overcorrecting droop?, 5 ngims, checked 20171208

if time_double(time) gt time_double('2017-11-28/00:00') and kk3_anode then kk3 = [1.2,1.0,1.0,0.0]		; sta o2+ ok, 4 ngims, checked 20171207

if time_double(time) gt time_double('2017-12-01/00:00') and kk3_anode then kk3 = [3.3,2.4,3.3,2.3]		;**sta o2+ ok, 5 ngims, checked 20190512
if time_double(time) gt time_double('2017-12-01/00:00') and kk3_anode then kk3 = [3.1,2.2,3.1,2.1]		;**sta o2+ ok, 5 ngims, checked 20190512, gf_update=1.6
if time_double(time) gt time_double('2017-12-01/00:00') and kk3_anode then kk3 = [2.7,2.0,2.5,1.5]		;**sta o2+ ok, 5 ngims, checked 20190514, gf_update=1.4

if time_double(time) gt time_double('2017-12-12/00:00') and kk3_anode then kk3 = [1.7,1.5,1.5,0.0]		; sta o2+ ok, 4 ngims, checked 20171207

;if time_double(time) gt time_double('2017-12-23/00:00') and kk3_anode then kk3 = [2.2,2.0,2.0,0.5]		; sta o2+ ok, 5 ngims, checked 20180119

if time_double(time) gt time_double('2018-01-01/00:00') and kk3_anode then kk3 = [3.3,2.4,3.3,2.3]		;**sta o2+ ok, 5 ngims, checked 20190512
if time_double(time) gt time_double('2018-01-01/00:00') and kk3_anode then kk3 = [2.8,1.9,2.8,1.8]		;**sta o2+ ok, 5 ngims, checked 20190514, gf_update=1.4

if time_double(time) gt time_double('2018-01-06/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta o2+ ok, 5 ngims, checked 20180119

if time_double(time) gt time_double('2018-01-24/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta o2+ ok, 5 ngims, checked 20180206, nightside no att=3

;if time_double(time) gt time_double('2018-02-13/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta o2+ ok, 5 ngims, checked 20180421, nightside no att=3
if time_double(time) gt time_double('2018-02-13/00:00') and kk3_anode then kk3 = [2.9,2.7,2.7,1.7]		; sta o2+ ok, 5 ngims, checked 20180421, nightside no att=3

if time_double(time) gt time_double('2018-02-17/00:00') and kk3_anode then kk3 = [3.1,2.9,2.9,1.9]		; sta o2+ ok, 5 ngims, checked 20180421, nightside no att=3

if time_double(time) gt time_double('2018-03-03/00:00') and kk3_anode then kk3 = [3.3,2.9,3.1,2.1]		; sta o2+ ok, 5 ngims, checked 20180421, nightside no att=3

;if time_double(time) gt time_double('2018-03-17/00:00') and kk3_anode then kk3 = [3.7,3.0,3.5,2.5]		; sta o2+ ok, 5 ngims, checked 20180420, terminator
;if time_double(time) gt time_double('2018-03-17/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		; sta o2+ ok, 5 ngims, checked 20180420, terminator
if time_double(time) gt time_double('2018-03-17/00:00') and kk3_anode then kk3 = [3.2,2.7,3.0,2.0]		; sta o2+ ok, 5 ngims, checked 20180420, terminator

;if time_double(time) gt time_double('2018-03-21/00:00') and kk3_anode then kk3 = [3.2,2.7,3.0,2.0]		; sta o2+ ok, 6 ngims, checked 20180421, terminator
if time_double(time) gt time_double('2018-03-21/00:00') and kk3_anode then kk3 = [3.4,2.9,3.2,2.2]		; sta o2+ ok, 6 ngims, checked 20180421, terminator

if time_double(time) gt time_double('2018-03-24/00:00') and kk3_anode then kk3 = [3.7,3.0,3.5,2.5]		; sta o2+ ok, 5 ngims, checked 20180420, terminator

;if time_double(time) gt time_double('2018-03-25/00:00') and kk3_anode then kk3 = [3.7,3.5,3.5,2.5]		; sta o2+ ok, 5 ngims, checked 20180330, terminator
if time_double(time) gt time_double('2018-03-25/00:00') and kk3_anode then kk3 = [3.7,3.0,3.5,2.5]		; sta o2+ ok, 5 ngims, checked 20180330, terminator

if time_double(time) gt time_double('2018-04-01/00:00') and kk3_anode then kk3 = [3.4,2.7,3.2,2.2]		; sta o2+ ok, 6 ngims, checked 20180406, terminator, lpw calib
if time_double(time) gt time_double('2018-04-01/00:00') and kk3_anode then kk3 = [3.6,3.1,3.6,3.0]		;** sta o2+ ok, 6 ngims, checked 20180406, terminator, lpw calib
if time_double(time) gt time_double('2018-04-01/00:00') and kk3_anode then kk3 = [3.6,2.9,3.6,2.8]		;** sta o2+ ok, 6 ngims, checked 20180406, terminator, lpw calib
if time_double(time) gt time_double('2018-04-01/00:00') and kk3_anode then kk3 = [3.1,2.6,3.1,2.5]		;**sta o2+ ok, 3 ngims, checked 20190516, gf_update=1.4

if time_double(time) gt time_double('2018-04-05/00:00') and kk3_anode then kk3 = [3.4,2.7,3.2,2.2]		; sta o2+ ok, 6 ngims, checked 20180406, terminator, lpw calib
if time_double(time) gt time_double('2018-04-05/00:00') and kk3_anode then kk3 = [3.3,2.6,3.1,2.1]		; sta o2+ ok, 6 ngims, checked 20180406, terminator, lpw calib

;if time_double(time) gt time_double('2018-04-09/00:00') and kk3_anode then kk3 = [3.4,2.7,3.2,2.2]		; 
;if time_double(time) gt time_double('2018-04-09/00:00') and kk3_anode then kk3 = [3.5,2.7,3.3,2.3]		;  
if time_double(time) gt time_double('2018-04-09/00:00') and kk3_anode then kk3 = [3.4,2.7,3.3,2.3]		; sta o2+ ok, 5 ngims, checked 20180423, 

; 20180411-12 are ngims wind measurement so no ngims densities for calibration

if time_double(time) gt time_double('2018-04-14/00:00') and kk3_anode then kk3 = [3.2,2.5,2.8,2.4]		; sta o2+ ok, 5 ngims, checked tbd 

;if time_double(time) gt time_double('2018-04-16/00:00') and kk3_anode then kk3 = [3.4,2.7,3.2,2.2]		; sta o2+ ok, 5 ngims, checked 20180418, 
;if time_double(time) gt time_double('2018-04-16/00:00') and kk3_anode then kk3 = [3.2,2.5,3.0,2.4]		; sta o2+ ok, 5 ngims, checked 20180421, 
if time_double(time) gt time_double('2018-04-16/00:00') and kk3_anode then kk3 = [3.2,2.5,2.8,2.4]		; sta o2+ ok, 5 ngims, checked 20180421, 

; start of deep dip 9 18-04-24

if time_double(time) gt time_double('2018-04-24/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.4]		; sta o2+ ok, 5 ngims, checked 20180421, 

if time_double(time) gt time_double('2018-04-26/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.4]		;  
if time_double(time) gt time_double('2018-04-26/00:00') and kk3_anode then kk3 = [3.2,2.7,3.0,2.6]		; sta o2+ ok, 5 ngims, checked 20180509, 

if time_double(time) gt time_double('2018-04-28/00:00') and kk3_anode then kk3 = [3.2,2.7,3.0,2.6]		; sta o2+ ok, 5 ngims, checked 20180518, 
if time_double(time) gt time_double('2018-04-28/00:00') and kk3_anode then kk3 = [3.3,2.8,3.1,2.7]		; sta o2+ ok, 5 ngims, checked 20180518, 

if time_double(time) gt time_double('2018-04-29/00:00') and kk3_anode then kk3 = [3.2,2.7,3.0,2.6]		; sta o2+ ok, 5 ngims, checked 20180510, 
if time_double(time) gt time_double('2018-04-29/00:00') and kk3_anode then kk3 = [3.4,2.9,3.2,2.8]		; sta o2+ ok, 5 ngims, checked 20180510, 

if time_double(time) gt time_double('2018-04-30/00:00') and kk3_anode then kk3 = [3.4,2.9,3.2,2.8]		; sta o2+ ok, 5 ngims, checked 20180510, 

if time_double(time) gt time_double('2018-05-01/00:00') and kk3_anode then kk3 = [3.0,2.5,2.8,2.4]		; sta o2+ ok, 3 ngims, checked 20180507, 
if time_double(time) gt time_double('2018-05-01/00:00') and kk3_anode then kk3 = [3.0,2.5,3.0,2.4]		; sta o2+ ok, 3 ngims, checked 20180507, 

; end of deep dip 9 18-05-02 - kk3 is changing on this day

if time_double(time) gt time_double('2018-05-02/00:00') and kk3_anode then kk3 = [3.0,2.5,3.0,2.4]		; sta o2+ ok, 3 ngims, checked 20180509, 
if time_double(time) gt time_double('2018-05-02/00:00') and kk3_anode then kk3 = [2.8,2.3,2.8,2.2]		; sta o2+ ok, 3 ngims, checked 20180509, 



; Note: either kk3 changes significantly on 2018-05-03 during this day or NGIMS changes

if time_double(time) gt time_double('2018-05-03/00:00') and kk3_anode then kk3 = [2.8,2.3,2.8,2.2]		; values dropping during this day
if time_double(time) gt time_double('2018-05-03/00:00') and kk3_anode then kk3 = [3.0,2.5,3.0,2.4]		; sta o2+ ok, 3 ngims, checked 201805011

if time_double(time) gt time_double('2018-05-03/00:00') and kk3_anode then kk3 = [3.4,2.9,3.4,2.8]		;**sta o2+ ok, 5 ngims, checked 20190506, gf_update=1.6 values for periapsis 3,4 - 0.5 smaller for periapsis 1,2
if time_double(time) gt time_double('2018-05-03/00:00') and kk3_anode then kk3 = [3.1,2.6,3.1,2.5]		;**sta o2+ ok, 5 ngims, lpw calib, checked 20190516, gf_update=1.4, variations in ngi/sta ratio with periapsis



if time_double(time) gt time_double('2018-05-04/00:00') and kk3_anode then kk3 = [3.0,2.5,3.0,2.4]		; values dropping during this day
if time_double(time) gt time_double('2018-05-04/00:00') and kk3_anode then kk3 = [2.8,2.3,2.8,2.2]		; sta o2+ ok, 4 ngims, checked 201805023, optimized for 18:20, orb6994

if time_double(time) gt time_double('2018-05-05/00:00') and kk3_anode then kk3 = [3.0,2.5,3.0,2.4]		; values dropping during this day
if time_double(time) gt time_double('2018-05-05/00:00') and kk3_anode then kk3 = [2.7,2.2,2.7,2.1]		; sta o2+ ok, 4 ngims, checked 201805014, selected for beginning of the day

if time_double(time) gt time_double('2018-05-06/00:00') and kk3_anode then kk3 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, 3 ngims, checked tbd - guess

if time_double(time) gt time_double('2018-05-07/00:00') and kk3_anode then kk3 = [3.0,2.5,3.0,2.4]		; sta too high
if time_double(time) gt time_double('2018-05-07/00:00') and kk3_anode then kk3 = [2.6,2.1,2.6,2.0]		; sta too high
if time_double(time) gt time_double('2018-05-07/00:00') and kk3_anode then kk3 = [2.4,1.9,2.4,1.8]		; sta o2+ ok, 3 ngims, checked 20180512

if time_double(time) gt time_double('2018-05-08/00:00') and kk3_anode then kk3 = [2.4,1.9,2.4,1.8]		; sta o2+ ok, 3 ngims, checked 20180512
if time_double(time) gt time_double('2018-05-08/00:00') and kk3_anode then kk3 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, 3 ngims, checked 20180512

if time_double(time) gt time_double('2018-05-08/00:00') and kk3_anode then kk3 = [3.0,2.5,3.0,2.4]		;** sta o2+ ok, 3 ngims, checked 20190508 for gf_scale=1.6


if time_double(time) gt time_double('2018-05-11/00:00') and kk3_anode then kk3 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, 4 ngims, checked 20180517

if time_double(time) gt time_double('2018-05-14/00:00') and kk3_anode then kk3 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, 5 ngims, checked 20180518

if time_double(time) gt time_double('2018-05-18/00:00') and kk3_anode then kk3 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, 5 ngims, checked 20180523

if time_double(time) gt time_double('2018-05-21/00:00') and kk3_anode then kk3 = [2.3,1.1,2.3,1.0]		; sta o2+ ok, ? ngims, checked 20190106

if time_double(time) gt time_double('2018-05-21/00:00') and kk3_anode then kk3 = [2.3,1.6,2.3,1.5]		; sta o2+ ok, ? ngims, checked 20180503
if time_double(time) gt time_double('2018-05-21/00:00') and kk3_anode then kk3 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, ? ngims, checked 20190106
if time_double(time) gt time_double('2018-05-21/00:00') and kk3_anode then kk3 = [2.3,1.1,2.3,1.0]		; sta o2+ ok, ? ngims, checked 20190106

;if time_double(time) gt time_double('2018-05-22/00:00') and kk3_anode then kk3 = [2.5,2.0,2.5,1.9]		; sta o2+ ok, ? ngims, checked tbd

; looks like a slight change in ngi/sta density between first and second orbits on 2018-05-25
if time_double(time) gt time_double('2018-05-25/00:00') and kk3_anode then kk3 = [2.3,1.6,2.3,1.5]		; sta o2+ ok, ? ngims, checked tbd
if time_double(time) gt time_double('2018-05-25/00:00') and kk3_anode then kk3 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, 6 ngims, checked 20180925

if time_double(time) gt time_double('2018-05-26/00:00') and kk3_anode then kk3 = [2.3,1.6,2.3,1.5]		; sta o2+ ok, ? ngims, checked tbd
if time_double(time) gt time_double('2018-05-26/00:00') and kk3_anode then kk3 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, ? ngims, checked tbd

if time_double(time) gt time_double('2018-05-29/00:00') and kk3_anode then kk3 = [2.3,1.6,2.3,1.5]		; sta o2+ ok, 3 ngims, checked 20180603, not well determined, lots of variations, could be winds and scpot variations
if time_double(time) gt time_double('2018-05-29/00:00') and kk3_anode then kk3 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, 3 ngims, redue, checked 20180603, not well determined, lots of variations, could be winds and scpot variations

if time_double(time) gt time_double('2018-05-31/00:00') and kk3_anode then kk3 = [1.8,1.1,1.8,1.0]		; sta o2+ ok, 3 ngims, checked 20180606








;***************************************************************************************************
; All calibrations below this line are final calibrations.

	; note that ngi/sta cross-calibration not valid for scpot<-2V due to incorrect ngims sensitivity variation with scpot

if time_double(time) gt time_double('2018-05-01/00:00') and kk3_anode then kk3 = [3.4,2.9,3.4,2.8]		;tbd checked 2020

if time_double(time) gt time_double('2018-05-03/00:00') and kk3_anode then kk3 = [3.4,2.9,3.4,2.8]		;tbd checked 2020
if time_double(time) gt time_double('2018-05-03/00:00') and kk3_anode then kk3 = [3.2,2.7,3.1,2.5]		;tbd checked 2020


if time_double(time) gt time_double('2018-05-31/00:00') and kk3_anode then kk3 = [2.9,2.3,2.8,2.2]		;**sta o2+ ok, lpw calib, checked 20200105, att=1-3

if time_double(time) gt time_double('2018-06-02/00:00') and kk3_anode then kk3 = [2.9,2.3,2.8,2.2]		;**sta o2+ ok, assume same as 5-31, checked 20200105, att=1-3

if time_double(time) gt time_double('2018-06-12/00:00') and kk3_anode then kk3 = [2.9,2.3,2.8,2.2]		;**sta o2+ ok, assume same as 5-31, checked 20200105

if time_double(time) gt time_double('2018-06-21/00:00') and kk3_anode then kk3 = [2.9,2.3,2.8,2.2]		;**sta o2+ ok, assume same as 5-31, checked 20200105

if time_double(time) gt time_double('2018-06-29/00:00') and kk3_anode then kk3 = [2.9,2.3,2.8,2.2]		;**sta o2+ ok, assume same as 5-31, checked 20200105

if time_double(time) gt time_double('2018-07-01/00:00') and kk3_anode then kk3 = [3.1,2.2,3.0,2.1]		;**sta o2+ ok, lpw calib, checked 20200105, att=0-3

if time_double(time) gt time_double('2018-07-04/00:00') and kk3_anode then kk3 = [3.1,2.1,3.0,1.9]		;tbd checked 2020

if time_double(time) gt time_double('2018-07-08/00:00') and kk3_anode then kk3 = [3.1,2.1,3.0,1.8]		;**sta o2+ inconsistent used 1657UT, checked 20200105, att=1-3,

if time_double(time) gt time_double('2018-07-15/00:00') and kk3_anode then kk3 = [3.1,2.1,3.0,1.8]		;**sta o2+ ok, checked 20200104, att=1-2

;if time_double(time) gt time_double('2018-07-22/00:00') and kk3_anode then kk3 = [3.1,2.1,3.0,1.8]		; tbd, probably not needed
;if time_double(time) gt time_double('2018-07-24/00:00') and kk3_anode then kk3 = [3.1,2.1,3.0,1.8]		; tbd, probably not needed

if time_double(time) gt time_double('2018-07-28/00:00') and kk3_anode then kk3 = [3.1,2.1,3.0,1.8]		;**sta o2+ ok, checked 20200104, att=1-2

;if time_double(time) gt time_double('2018-08-02/00:00') and kk3_anode then kk3 = [3.2,2.2,3.1,1.9]		;tbd checked 2020
;if time_double(time) gt time_double('2018-08-06/00:00') and kk3_anode then kk3 = [3.2,2.2,3.1,1.9]		;tbd checked 2020

if time_double(time) gt time_double('2018-08-11/00:00') and kk3_anode then kk3 = [3.3,2.3,3.2,2.0]		;**sta o2+ ok, checked 20200103, att=1-2

if time_double(time) gt time_double('2018-08-19/00:00') and kk3_anode then kk3 = [3.3,2.3,3.2,2.0]		;**sta o2+ ok, checked 20200103, att=1-2

;if time_double(time) gt time_double('2018-08-22/00:00') and kk3_anode then kk3 = [3.3,2.3,3.2,2.0]		; tbd, probably not needed

if time_double(time) gt time_double('2018-08-24/00:00') and kk3_anode then kk3 = [3.2,2.2,3.1,2.0]		;**sta o2+ ok, checked 20200104, att=1-2

;if time_double(time) gt time_double('2018-08-30/00:00') and kk3_anode then kk3 = [3.3,2.3,3.2,2.1]		;tbd checked 2020

if time_double(time) gt time_double('2018-09-03/00:00') and kk3_anode then kk3 = [3.5,2.5,3.4,2.2]		;**sta o2+ ok, checked 20200103, att=0-2

if time_double(time) gt time_double('2018-09-15/00:00') and kk3_anode then kk3 = [3.5,2.6,3.4,2.3]		;**sta o2+ ok, checked 20200103, att=1-2

if time_double(time) gt time_double('2018-09-23/00:00') and kk3_anode then kk3 = [3.5,2.8,3.4,2.5]		;**sta o2+ ok, checked 20200103, att=1-2

if time_double(time) gt time_double('2018-10-04/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,2.7]		;**sta o2+ ok, checked 20200102, att=2-3

;if time_double(time) gt time_double('2018-10-10/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,2.7]		; tbd, probably not needed

if time_double(time) gt time_double('2018-10-20/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,2.7]		;**sta o2+ ok, checked 20200103, att=2

if time_double(time) gt time_double('2018-10-26/00:00') and kk3_anode then kk3 = [3.4,2.9,3.3,2.6]		;**sta o2+ ok, checked 20200103, att=2-3

if time_double(time) gt time_double('2018-10-29/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		;**sta o2+ ok, checked 20200102, att=2-3

if time_double(time) gt time_double('2018-11-14/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		;**sta o2+ ok, checked 20200102

if time_double(time) gt time_double('2018-11-23/00:00') and kk3_anode then kk3 = [3.5,2.9,3.4,2.6]		;**sta o2+ ok, checked 20200103, att=1-2

if time_double(time) gt time_double('2018-11-27/00:00') and kk3_anode then kk3 = [3.8,3.1,3.7,2.7]		;**sta o2+ ok, checked 20200103

;if time_double(time) gt time_double('2018-11-29/00:00') and kk3_anode then kk3 = [3.8,3.1,3.7,2.7]		; tbd, probably not needed

	; periapsis shifts to nightside 2018-11-25

;if time_double(time) gt time_double('2018-12-02/00:00') and kk3_anode then kk3 = [3.7,3.0,3.6,2.6]		; tbd, probably not needed

if time_double(time) gt time_double('2018-12-07/00:00') and kk3_anode then kk3 = [3.7,3.0,3.6,2.6]		;**sta o2+ ok, checked 20200102

;if time_double(time) gt time_double('2018-12-24/00:00') and kk3_anode then kk3 = [3.7,3.0,3.6,2.6]		; tbd, probably not needed

;if time_double(time) gt time_double('2018-12-30/00:00') and kk3_anode then kk3 = [3.8,3.1,3.7,2.7]		; tbd, probably not needed

	; below are final calibrations for 2019	

	; mech attentuator does not always close at periapsis increasing atomic oxygen exposure in January and raising kk3

if time_double(time) gt time_double('2019-01-02/00:00') and kk3_anode then kk3 = [3.8,3.1,3.7,2.7]		; tbd, probably not needed

if time_double(time) gt time_double('2019-01-12/00:00') and kk3_anode then kk3 = [3.8,3.1,3.7,2.7]		;**sta o2+ ok, checked 20191230

if time_double(time) gt time_double('2019-01-18/00:00') and kk3_anode then kk3 = [3.7,3.0,3.6,2.6]		;**sta o2+ ok, checked 20191230

if time_double(time) gt time_double('2019-01-29/00:00') and kk3_anode then kk3 = [3.7,2.9,3.6,2.6]		;**sta o2+ ok, checked 20200101 for att=1-2

if time_double(time) gt time_double('2019-01-31/00:00') and kk3_anode then kk3 = [3.9,3.0,3.8,2.7]		;**sta o2+ ok, checked 20200101 for att=1-2

if time_double(time) gt time_double('2019-02-02/00:00') and kk3_anode then kk3 = [3.7,2.9,3.6,2.6]		; tbd, guess 

if time_double(time) gt time_double('2019-02-04/00:00') and kk3_anode then kk3 = [3.5,2.7,3.4,2.4]		; sta o2+ ok, checked 20191230

if time_double(time) gt time_double('2019-02-11/00:00') and kk3_anode then kk3 = [3.5,2.7,3.4,2.4]		; tbd, guess

	; 20190211 aerobraking begins - long deep dip - high background in NGIMS at periapsis can distort density
	; 20190211 ngims detuned - ngims densities wrong till 20190223, orb 8597

if time_double(time) gt time_double('2019-02-12/00:00') and kk3_anode then kk3 = [3.6,2.8,3.5,2.5]		; guess, assume the change over 3 days
if time_double(time) gt time_double('2019-02-13/00:00') and kk3_anode then kk3 = [3.7,2.9,3.6,2.6]		; guess, 
if time_double(time) gt time_double('2019-02-14/00:00') and kk3_anode then kk3 = [3.8,3.0,3.7,2.7]		; guess, 

	; 20190223 ngims detuned ends orb 8596

if time_double(time) gt time_double('2019-02-23/00:00') and kk3_anode then kk3 = [3.8,3.0,3.7,2.7]		;**sta o2+ ok, checked 20200101 for att=1-2

if time_double(time) gt time_double('2019-02-25/00:00') and kk3_anode then kk3 = [3.9,3.0,3.8,2.7]		;**sta o2+ ok, checked 20200101 for att=1-2

if time_double(time) gt time_double('2019-02-28/00:00') and kk3_anode then kk3 = [3.9,3.0,3.8,2.7]		;**sta o2+ ok, checked 20200101 for att=1-2

if time_double(time) gt time_double('2019-03-03/00:00') and kk3_anode then kk3 = [3.8,3.0,3.7,2.7]		;**sta o2+ ok, checked 20191230 for att=2

	; 20190316 periapsis shifts to dayside 

if time_double(time) gt time_double('2019-03-16/00:00') and kk3_anode then kk3 = [3.6,3.1,3.5,2.6]		;**sta o2+ ok, checked 20191231, for att=1-3, 

if time_double(time) gt time_double('2019-03-28/00:00') and kk3_anode then kk3 = [3.4,3.0,3.3,2.6]		;**sta o2+ ok, checked 20191231, for att=0-3, 

	; 20190329 aerobraking slow walkout - high background in NGIMS at periapsis can distort density 

if time_double(time) gt time_double('2019-03-30/00:00') and kk3_anode then kk3 = [3.3,2.9,3.2,2.6]		;**sta o2+ ok, checked 20191231, for att=0-3, 
if time_double(time) gt time_double('2019-03-31/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.4]		;**sta o2+ ok, checked 20191228, for att=1-3, lpw calib

	; 20190401 aerobraking ends walkout 

if time_double(time) gt time_double('2019-04-05/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.4]		;**sta o2+ ok, checked 20191230, for att=1-3, flyZ->flyY

if time_double(time) gt time_double('2019-04-18/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.4]		;**sta o2+ ok, checked 20191230, for att=1-3, lpw calib

if time_double(time) gt time_double('2019-05-01/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.4]		;**sta o2+ ok, checked 20191227, for att=3, lpw calib

;if time_double(time) gt time_double('2019-05-03/00:00') and kk3_anode then kk3 = [2.8,2.5,2.8,2.2]		;tbd **sta o2+ ok, ratio varies with orbit, checked 20190606, gf_update=1.4, for att=1-3, modulated density, use lower fp values

;if time_double(time) gt time_double('2019-05-04/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.4]		;tbd **sta o2+ ok, checked 201912??, for att=3, 

if time_double(time) gt time_double('2019-05-11/00:00') and kk3_anode then kk3 = [3.0,2.4,3.0,2.3]		;**sta o2+ ok, checked 20191126, 

if time_double(time) gt time_double('2019-05-15/00:00') and kk3_anode then kk3 = [3.3,2.5,3.2,2.4]		;ok agreement but some oddities, checked 20191226, lpw calib but density too low

;if time_double(time) gt time_double('2019-05-18/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,2.5]		;tbd, **sta o2+ ok, checked 20190605, for att=1-3

	; 20190520 periapsis shifts to nightside 

;if time_double(time) gt time_double('2019-05-21/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,2.7]		;tbd, **sta o2+ ok, checked 20190607, gf_update=1.4, for att=1-3, no lpw

if time_double(time) gt time_double('2019-05-25/00:00') and kk3_anode then kk3 = [3.6,2.6,3.5,2.3]		;**sta o2+ ok agreement,checked 20191209

;if time_double(time) gt time_double('2019-06-06/00:00') and kk3_anode then kk3 = [3.8,2.6,3.7,2.5]		;tbd, 
;if time_double(time) gt time_double('2019-06-09/00:00') and kk3_anode then kk3 = [3.8,2.6,3.7,2.5]		;tbd, 
;if time_double(time) gt time_double('2019-06-12/00:00') and kk3_anode then kk3 = [3.8,2.6,3.7,2.5]		;tbd, 

if time_double(time) gt time_double('2019-06-17/00:00') and kk3_anode then kk3 = [3.7,2.6,3.6,2.5]		;ok agreement,checked 20191209, att=1-3 

;if time_double(time) gt time_double('2019-06-20/00:00') and kk3_anode then kk3 = [3.8,2.6,3.7,2.5]		;tbd, 
;if time_double(time) gt time_double('2019-06-29/00:00') and kk3_anode then kk3 = [3.8,2.6,3.7,2.5]		;tbd, 

if time_double(time) gt time_double('2019-07-05/00:00') and kk3_anode then kk3 = [3.8,2.6,3.7,2.5]		;**sta o2+ ok, checked 20191203, att=2, 

;if time_double(time) gt time_double('2019-07-08/00:00') and kk3_anode then kk3 = [3.8,2.9,3.7,2.8]		;kk3 poorly determined, att=1-3

;if time_double(time) gt time_double('2019-07-16/00:00') and kk3_anode then kk3 = [3.8,3.1,3.7,3.0]		;kk3 poorly determined

;if time_double(time) gt time_double('2019-07-21/00:00') and kk3_anode then kk3 = [3.8,3.1,3.7,3.0]		;tbd

if time_double(time) gt time_double('2019-07-30/00:00') and kk3_anode then kk3 = [3.8,3.5,3.7,3.0]		;**sta o2+ ok, checked 20191127, att=2, 

if time_double(time) gt time_double('2019-08-02/00:00') and kk3_anode then kk3 = [3.5,3.2,3.4,2.8]		;**sta o2+ ok - not that well determined, checked 20191227, att=1-2, 20V lpw sweeps

	; 20190803 periapsis shifts to dayside 

if time_double(time) gt time_double('2019-08-06/00:00') and kk3_anode then kk3 = [3.3,3.0,3.2,2.8]		; **sta o2+ not that well determined, checked 20191228

;if time_double(time) gt time_double('2019-08-11/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		; tbd

if time_double(time) gt time_double('2019-08-14/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		;**sta o2+ ok, checked 20191125, lpw waves, ngi/sta varies +/-20%
if time_double(time) gt time_double('2019-08-17/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		;**sta o2+ ok, checked 20191115, lpw waves

	; no periapsis data from 20190824 to 20190913 due to conjunction and maven safing

if time_double(time) gt time_double('2019-09-14/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.2]		;assume same as 20190918
if time_double(time) gt time_double('2019-09-18/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.2]		;**sta o2+ ok, checked 20190919, lpw waves, ngims high for some periapses
if time_double(time) gt time_double('2019-09-19/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.2]		;**sta o2+ ok, checked 20191125, lpw waves, ngims high for some periapses 
if time_double(time) gt time_double('2019-09-30/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.2]		;**sta o2+ ok, checked 20191115, 20% ratio variations across orbits

	; STATIC put in protect mode to prevent saturtion due to fly(+Z) s/c attitude which causes charging to -20V
	; no periapsis data from 20191002 to 20191126 due to power requirements and fly+Z orientation causing s/c charging
	; periapsis shifts to nighside 2019-11-06 to 2020-01-01?

if time_double(time) gt time_double('2019-11-26/00:00') and kk3_anode then kk3 = [2.6,2.1,2.5,1.8]		;**sta o2+ ok, checked 20191203, 

if time_double(time) gt time_double('2019-12-08/00:00') and kk3_anode then kk3 = [2.8,2.1,2.7,1.8]		;**sta o2+ ok, checked 20191213,att=2-3

if time_double(time) gt time_double('2019-12-18/00:00') and kk3_anode then kk3 = [2.8,2.2,2.7,1.8]		; **sta o2+ ok, checked 20200102,



	; 20191229 periapsis shifts back to dayside 


tt=timerange()
store_data,'mvn_sta_kk3',data={x:tt,y:transpose([[kk3],[kk3]])}

return,kk3

end






