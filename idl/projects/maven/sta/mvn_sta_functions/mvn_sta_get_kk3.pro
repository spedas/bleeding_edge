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










;***************************************************************************************************
;***************************************************************************************************
;***************************************************************************************************
; All calibrations below this line are final calibrations.
; note that ngi/sta cross-calibration not valid for scpot<-2V due to incorrect ngims sensitivity variation with scpot

kk3 = [2.6,2.6,2.6,2.4]

	; 20150211 	start deep dip 1
	; 20150218 	end deep dip 1

	; 20150221	MCP voltage increased 2700V->2870V, 0504UT

	; 20150404 	Maven Safed - no data

	; 20150414 	PFDPU power on

if time_double(time) gt time_double('2015-04-15/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims

	; 20150416 	start deep dip 2
	; 20150416	deep dip neutrals charge exchange on attenuation grid and detected in sensor at 15-20eV 

	; 20150422 	end deep dip 2

if time_double(time) gt time_double('2015-04-24/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims

if time_double(time) gt time_double('2015-04-27/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims
if time_double(time) gt time_double('2015-04-27/00:00') and kk3_anode then kk3 = [6.0,5.8,5.9,5.2]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims
if time_double(time) gt time_double('2015-04-27/00:00') and kk3_anode then kk3 = [6.3,6.1,6.2,5.5]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims
if time_double(time) gt time_double('2015-04-27/00:00') and kk3_anode then kk3 = [5.9,5.6,5.7,5.0]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims

if time_double(time) gt time_double('2015-05-06/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims
if time_double(time) gt time_double('2015-05-06/00:00') and kk3_anode then kk3 = [4.8,4.6,4.7,4.0]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims

if time_double(time) gt time_double('2015-05-09/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims

if time_double(time) gt time_double('2015-05-14/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims

if time_double(time) gt time_double('2015-05-16/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims
if time_double(time) gt time_double('2015-05-16/00:00') and kk3_anode then kk3 = [4.7,4.5,4.6,3.9]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims

if time_double(time) gt time_double('2015-05-20/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;**sta o2+ ok, lpw calib, checked 20200216, 2 ngims

	; 20150526	no ngims data until 20150702

if time_double(time) gt time_double('2015-06-01/00:00') and kk3_anode then kk3 = [4.3,4.1,4.2,3.5]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims
if time_double(time) gt time_double('2015-06-01/00:00') and kk3_anode then kk3 = [4.8,4.6,4.7,4.0]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims
if time_double(time) gt time_double('2015-06-01/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims

	; 20150603-0702 no periapsis data  solar conjunction
	; 20150702	ngims data resumes

;if time_double(time) gt time_double('2015-07-03/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 3 ngims
;if time_double(time) gt time_double('2015-07-03/00:00') and kk3_anode then kk3 = [5.6,5.4,5.5,4.8]		;screwy result tbd**sta o2+ ok, lpw calib, checked 202002??, 1 ngims

	; 20150705 	nightside peripasis starts

if time_double(time) gt time_double('2015-07-06/00:00') and kk3_anode then kk3 = [4.8,4.6,4.7,4.0]		;tbd**sta o2+ ok, lpw calib, checked 20200103, 3 ngims

	; 20150707 	start deep dip 3

if time_double(time) gt time_double('2015-07-12/00:00') and kk3_anode then kk3 = [4.8,4.6,4.7,4.0]		;tbd**sta o2+ ok, lpw calib, checked 20200103, 3 ngims

	; 20150715 	end deep dip 3

if time_double(time) gt time_double('2015-07-16/00:00') and kk3_anode then kk3 = [4.8,4.6,4.7,4.0]		;tbd**sta o2+ ok, checked 202002??, 3 ngims

if time_double(time) gt time_double('2015-07-28/00:00') and kk3_anode then kk3 = [4.8,4.6,4.7,4.0]		;tbd**sta o2+ ok, checked 202002??, 3 ngims

if time_double(time) gt time_double('2015-08-03/00:00') and kk3_anode then kk3 = [4.8,4.6,4.7,4.0]		;**sta o2+ poor, checked 20200217, 3 ngims

if time_double(time) gt time_double('2015-08-10/00:00') and kk3_anode then kk3 = [5.0,4.8,4.9,4.2]		;**sta o2+ poor, checked 20200217, 2 ngims

if time_double(time) gt time_double('2015-08-12/00:00') and kk3_anode then kk3 = [5.0,4.8,4.9,4.2]		;tbd**sta o2+ ok, lpw calib, checked 20200103, 3 ngims

	; 20150812-0821 no ngims data
if time_double(time) gt time_double('2015-08-15/00:00') and kk3_anode then kk3 = [4.8,4.6,4.7,4.0]		;guess
if time_double(time) gt time_double('2015-08-18/00:00') and kk3_anode then kk3 = [4.6,4.4,4.5,3.8]		;guess
if time_double(time) gt time_double('2015-08-21/00:00') and kk3_anode then kk3 = [4.4,4.1,4.3,3.6]		;guess

if time_double(time) gt time_double('2015-08-22/00:00') and kk3_anode then kk3 = [4.3,4.0,4.2,3.5]		;tbd**sta o2+ ok, lpw calib, checked 20200103, 3 ngims

if time_double(time) gt time_double('2015-08-24/00:00') and kk3_anode then kk3 = [4.3,4.0,4.2,3.5]		;**sta o2+ ok, lpw calib, checked 20200217, 3 ngims

	; 20150820 	nightside peripasis ends

if time_double(time) gt time_double('2015-08-29/00:00') and kk3_anode then kk3 = [4.1,4.0,4.0,3.3]		;**sta o2+ ok, lpw calib, checked 20200215, 3 ngims

	; 20150901 	start deep dip 4

if time_double(time) gt time_double('2015-09-02/00:00') and kk3_anode then kk3 = [4.2,4.0,4.1,3.4]		;**sta o2+ ok, lpw calib, checked 20200213, 2 ngims

if time_double(time) gt time_double('2015-09-07/00:00') and kk3_anode then kk3 = [4.2,4.0,4.1,3.4]		;tbd**sta o2+ ok, lpw calib, checked 20200103, 3 ngims

	; 20150910 	end deep dip 4

if time_double(time) gt time_double('2015-09-11/00:00') and kk3_anode then kk3 = [4.2,4.1,4.1,3.4]		;**sta o2+ ok, lpw calib, checked 20200214, 2 ngims

if time_double(time) gt time_double('2015-09-14/00:00') and kk3_anode then kk3 = [4.1,4.0,4.0,3.3]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 3 ngims

if time_double(time) gt time_double('2015-09-21/00:00') and kk3_anode then kk3 = [4.0,3.9,3.9,3.2]		;**sta o2+ ok, lpw calib, checked 20200213, 3 ngims

	; 20150922-29	Mech Attenuator open for 1 week in protect mode - attempt to reduce ion suppression 

if time_double(time) gt time_double('2015-09-29/00:00') and kk3_anode then kk3 = [4.6,4.5,4.4,4.3]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 3 ngims
if time_double(time) gt time_double('2015-09-30/00:00') and kk3_anode then kk3 = [4.6,4.5,4.4,4.1]		;**sta o2+ ok, lpw calib, checked 20200214, 3 ngims, dropping during day
if time_double(time) gt time_double('2015-09-31/00:00') and kk3_anode then kk3 = [4.5,4.4,4.3,4.0]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 3 ngims
if time_double(time) gt time_double('2015-10-01/00:00') and kk3_anode then kk3 = [4.4,4.3,4.2,3.9]		;**sta o2+ ok, lpw calib, checked 20200215, 2 ngims
if time_double(time) gt time_double('2015-10-02/00:00') and kk3_anode then kk3 = [4.3,4.2,4.1,3.8]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 3 ngims
if time_double(time) gt time_double('2015-10-04/00:00') and kk3_anode then kk3 = [4.3,4.2,4.1,3.7]		;**sta o2+ ok, lpw calib, checked 20200213, 2 ngims
if time_double(time) gt time_double('2015-10-05/00:00') and kk3_anode then kk3 = [4.3,4.2,4.1,3.6]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 3 ngims

	; 20151006-13	Mech Attenuator open for 1 week in protect mode - attempt to reduce ion suppression 

if time_double(time) gt time_double('2015-10-13/00:00') and kk3_anode then kk3 = [4.7,4.6,4.5,4.3]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 1 ngims
if time_double(time) gt time_double('2015-10-14/00:00') and kk3_anode then kk3 = [4.6,4.5,4.4,4.2]		;**sta o2+ ok, lpw calib, checked 20200214, 3 ngims
if time_double(time) gt time_double('2015-10-15/00:00') and kk3_anode then kk3 = [4.4,4.3,4.2,3.9]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims
if time_double(time) gt time_double('2015-10-16/00:00') and kk3_anode then kk3 = [4.2,4.1,4.0,3.6]		;**sta o2+ ok, lpw calib, checked 20200214, 3 ngims
if time_double(time) gt time_double('2015-10-17/00:00') and kk3_anode then kk3 = [4.0,3.9,3.9,3.4]		;tbd**sta o2+ ok, lpw calib, checked 202002??, 2 ngims
if time_double(time) gt time_double('2015-10-18/00:00') and kk3_anode then kk3 = [3.9,3.7,3.8,3.2]		;**sta o2+ ok, lpw calib, checked 20200213, 2 ngims
if time_double(time) gt time_double('2015-10-19/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;tbd**sta o2+ ok, lpw calib, checked 202002??, ? ngims

	; 20151020-27	Mech Attenuator open for 1 week in protect mode - attempt to reduce ion suppression 

if time_double(time) gt time_double('2015-10-28/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;**sta o2+ ok, lpw calib, checked 20200103, 3 ngims

if time_double(time) gt time_double('2015-10-31/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;**sta o2+ ok, lpw calib, checked 20200131, 3 ngims, changing across the day

if time_double(time) gt time_double('2015-11-02/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;tbd **sta o2+ ok, lpw calib, checked 202002??

	; 20151103-10	Mech Attenuator open for 1 week in protect mode - attempt to reduce ion suppression 

if time_double(time) gt time_double('2015-11-10/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;**sta o2+ ok, lpw calib, checked 20200201, 1 ngims

if time_double(time) gt time_double('2015-11-13/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;tbd **sta o2+ ok, lpw calib, checked 202002??

if time_double(time) gt time_double('2015-11-16/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;**sta o2+ ok, lpw calib, checked 20200131, 2 ngims

	; 20151117-24	Mech Attenuator open for 1 week in protect mode - attempt to reduce ion suppression 
	; 20151124	LPW no longer producing wave data at periapsis - next lpw calib 20160322

if time_double(time) gt time_double('2015-11-24/00:00') and kk3_anode then kk3 = [4.2,4.0,4.1,3.5]		;guess same as 20151125
if time_double(time) gt time_double('2015-11-25/00:00') and kk3_anode then kk3 = [4.2,4.0,4.1,3.5]		;**sta o2+ ok, checked 20200202
if time_double(time) gt time_double('2015-11-26/00:00') and kk3_anode then kk3 = [4.1,3.9,4.0,3.4]		;tbd**sta o2+ ok, checked 202002??
if time_double(time) gt time_double('2015-11-27/00:00') and kk3_anode then kk3 = [4.0,3.8,3.9,3.3]		;tbd**sta o2+ ok, checked 202002??
if time_double(time) gt time_double('2015-11-28/00:00') and kk3_anode then kk3 = [3.9,3.7,3.8,3.2]		;**sta o2+ ok, checked 20200202
if time_double(time) gt time_double('2015-11-29/00:00') and kk3_anode then kk3 = [3.8,3.6,3.7,3.1]		;tbd**sta o2+ ok, checked 202002??
if time_double(time) gt time_double('2015-11-30/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;tbd**sta o2+ ok, checked 202002??
if time_double(time) gt time_double('2015-12-01/00:00') and kk3_anode then kk3 = [3.7,3.5,3.6,3.0]		;**sta o2+ ok, checked 20200202

	; 20151203-08	Mech Attenuator open for 1 week in protect mode - attempt to reduce ion suppression 

if time_double(time) gt time_double('2015-12-08/00:00') and kk3_anode then kk3 = [2.3,2.2,2.2,1.6]		;guess same as 20151209, might want to check
if time_double(time) gt time_double('2015-12-09/00:00') and kk3_anode then kk3 = [2.3,2.2,2.2,1.6]		;**sta o2+ ok, checked 20200202, ngims 20% high first orbit 

if time_double(time) gt time_double('2015-12-12/00:00') and kk3_anode then kk3 = [2.0,1.9,1.9,1.3]		;**sta o2+ ok, checked 20200202

if time_double(time) gt time_double('2015-12-14/00:00') and kk3_anode then kk3 = [2.0,1.9,1.9,1.3]		;tbd**sta o2+ ok, checked 202002??

	; 20151215-22	Mech Attenuator open for 1 week in protect mode - attempt to reduce ion suppression 

if time_double(time) gt time_double('2015-12-22/00:00') and kk3_anode then kk3 = [2.6,2.1,2.5,2.0]		;guess same as 20151223

if time_double(time) gt time_double('2015-12-23/00:00') and kk3_anode then kk3 = [2.6,2.1,2.5,2.0]		;tbd**sta o2+ ok, checked 202002??

if time_double(time) gt time_double('2015-12-24/00:00') and kk3_anode then kk3 = [2.6,2.1,2.5,2.0]		;**sta o2+ ok, checked 20200202, strong cross wind

if time_double(time) gt time_double('2015-12-25/00:00') and kk3_anode then kk3 = [2.6,2.1,2.5,2.0]		;**sta o2+ ok, checked 20200202, not well determined

if time_double(time) gt time_double('2015-12-28/00:00') and kk3_anode then kk3 = [2.6,2.1,2.5,2.0]		;tbd**sta o2+ ok, checked 202002??

	; 20151229-20160105	Mech Attenuator open for 1 week in protect mode - attempt to reduce ion suppression 
	; 20160105	periapsis moves to nightside 

if time_double(time) gt time_double('2016-01-05/00:00') and kk3_anode then kk3 = [3.1,3.1,3.1,2.5]		;guess same as 20160106

if time_double(time) gt time_double('2016-01-06/00:00') and kk3_anode then kk3 = [3.1,3.1,3.1,2.5]		;tbd **sta o2+ ok, checked 202002??

if time_double(time) gt time_double('2016-01-10/00:00') and kk3_anode then kk3 = [3.3,3.3,3.3,2.7]		;**sta o2+ ok, checked 20200203, att=0-3

	; 20160112-20160119	Mech Attenuator open for 1 week in protect mode - attempt to reduce ion suppression 

if time_double(time) gt time_double('2016-01-19/00:00') and kk3_anode then kk3 = [3.2,3.2,3.0,2.5]		;guess same as 20160120

if time_double(time) gt time_double('2016-01-20/00:00') and kk3_anode then kk3 = [3.2,3.2,3.0,2.5]		;**sta o2+ ok, checked 20200203, att=0-2 

if time_double(time) gt time_double('2016-01-23/00:00') and kk3_anode then kk3 = [3.1,3.1,3.1,2.5]		;tbd **sta o2+ ok, checked 202002?? 

if time_double(time) gt time_double('2016-01-24/00:00') and kk3_anode then kk3 = [3.1,3.1,3.1,2.5]		;**sta o2+ ok, checked 20200203, att=0-2 

if time_double(time) gt time_double('2016-01-31/00:00') and kk3_anode then kk3 = [3.0,3.0,3.0,2.5]		;tbd **sta o2+ ok, checked 202002?? 

if time_double(time) gt time_double('2016-02-11/00:00') and kk3_anode then kk3 = [3.0,2.9,2.9,2.5]		;**sta o2+ ok, checked 20200203, att=0-3 

if time_double(time) gt time_double('2016-02-20/00:00') and kk3_anode then kk3 = [3.1,2.9,3.1,2.5]		;**sta o2+ ok, checked 20200203 

if time_double(time) gt time_double('2016-03-03/00:00') and kk3_anode then kk3 = [3.1,2.8,3.0,2.5]		;**sta o2+ ok, checked 20200203, ngi 10% high orb 2773

if time_double(time) gt time_double('2016-03-12/00:00') and kk3_anode then kk3 = [3.2,3.0,3.1,2.5]		;tbd **sta o2+ ok, checked 202002?? 

if time_double(time) gt time_double('2016-03-22/00:00') and kk3_anode then kk3 = [3.3,3.2,3.2,2.6]		;**sta o2+ ok, lpw calib, checked 20200130, 2 ngims

if time_double(time) gt time_double('2016-04-01/00:00') and kk3_anode then kk3 = [3.2,3.1,3.1,2.5]		;**sta o2+ ok, checked 20200130, 1 ngims




if time_double(time) gt time_double('2016-04-09/00:00') and kk3_anode then kk3 = [3.2,3.1,3.1,2.0]		;**sta o2+ ok, checked 20200204, 3 ngims

if time_double(time) gt time_double('2016-04-18/00:00') and kk3_anode then kk3 = [3.1,3.0,3.0,2.0]		;**sta o2+ ok, checked 20200204, 3 ngims

if time_double(time) gt time_double('2016-04-23/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,1.9]		;tbd**sta o2+ ok, checked 202002??, ? ngims

if time_double(time) gt time_double('2016-04-27/00:00') and kk3_anode then kk3 = [2.8,2.7,2.7,1.9]		;**sta o2+ ok, checked 20200203, 3 ngims

if time_double(time) gt time_double('2016-05-06/00:00') and kk3_anode then kk3 = [2.8,2.7,2.7,1.9]		;**sta o2+ ok, checked 20200204, 3 ngims

if time_double(time) gt time_double('2016-05-16/00:00') and kk3_anode then kk3 = [3.1,3.0,3.0,2.4]		;tbd**sta o2+ ok, checked 202002??, 3 ngims

if time_double(time) gt time_double('2016-05-25/00:00') and kk3_anode then kk3 = [3.2,3.1,3.1,2.5]		;**sta o2+ ok, checked 20200203, 3 ngims

	; 20160526	Mech Attenuator open for 6 periapsis passes, protect mode fails to close attenuator  

if time_double(time) gt time_double('2016-05-28/00:00') and kk3_anode then kk3 = [3.6,3.5,3.5,2.8]		;tbd**sta o2+ ok, checked 202002??, 3 ngims

if time_double(time) gt time_double('2016-05-29/00:00') and kk3_anode then kk3 = [3.6,3.5,3.5,2.8]		;**sta o2+ ok, lpw calib, 3 ngims, checked 20200130

if time_double(time) gt time_double('2016-06-07/00:00') and kk3_anode then kk3 = [3.6,3.5,3.5,2.8]		;tbd**sta o2+ ok, checked 202002??, 3 ngims

	; 20160607 	start deep dip 5
	; 20160615 	end deep dip 5

	; 20160615 	Nightside periapsis starts (ended 20160915)
	; 20160615	Mech Attenuator open for 2 periapsis passes, protect mode fails to close attenuator  

if time_double(time) gt time_double('2016-06-16/00:00') and kk3_anode then kk3 = [3.0,2.9,2.9,2.0]		;**sta o2+ poor, checked 20200204, 3 ngims

if time_double(time) gt time_double('2016-06-22/00:00') and kk3_anode then kk3 = [2.9,2.6,2.8,2.0]		;**sta o2+ ok, checked 20200206, 2 ngims, att=0-2

if time_double(time) gt time_double('2016-06-23/00:00') and kk3_anode then kk3 = [2.9,2.6,2.8,2.0]		;**sta o2+ poor, checked 20200204, 2 ngims

if time_double(time) gt time_double('2016-07-01/00:00') and kk3_anode then kk3 = [2.9,2.6,2.8,2.0]		;**sta o2+ ok, checked 20200205, 2 ngims, att=0-2

	; 20160702	Mech Attenuator open for 2 periapsis passes, normal ram mode  

if time_double(time) gt time_double('2016-07-05/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,1.9]		;tbd**sta o2+ ok, checked 202002??, 3 ngims

	; 20160707	Mech Attenuator open for 2 periapsis passes, normal ram mode  

if time_double(time) gt time_double('2016-07-07/00:00') and kk3_anode then kk3 = [3.1,2.4,3.0,1.7]		;guess, assume same as 20160710
if time_double(time) gt time_double('2016-07-10/00:00') and kk3_anode then kk3 = [3.1,2.4,3.0,1.7]		;**sta o2+ ok, checked 20200205, 1 ngims, att=2-3

	; 20160714-15	Mech Attenuator open for 7 periapsis passes, protect mode fails to close attenuator  

if time_double(time) gt time_double('2016-07-16/00:00') and kk3_anode then kk3 = [3.1,1.9,3.0,1.5]		;guess - assume same as 20160717
if time_double(time) gt time_double('2016-07-17/00:00') and kk3_anode then kk3 = [3.1,1.9,3.0,1.5]		;**sta o2+ ok, checked 20200205, 2 ngims

	; 20160719-20	Mech Attenuator open for 5 periapsis passes, 
	; 20160722-25	Mech Attenuator open for 8 periapsis passes,  

if time_double(time) gt time_double('2016-07-25/00:00') and kk3_anode then kk3 = [3.2,1.9,3.1,1.5]		;tbd**sta o2+ ok, checked 202002??, 3 ngims

	; 20160726 	start deep dip 6

if time_double(time) gt time_double('2016-07-26/00:00') and kk3_anode then kk3 = [3.2,1.9,3.1,1.5]		;**sta o2+ ok, checked 20200205, 3 ngims

if time_double(time) gt time_double('2016-07-28/00:00') and kk3_anode then kk3 = [3.4,2.1,3.3,1.9]		;tbd**sta o2+ ok, checked 202002??, 3 ngims

if time_double(time) gt time_double('2016-07-30/00:00') and kk3_anode then kk3 = [3.5,2.3,3.4,2.2]		;**sta o2+ ok, checked 20200205, 3 ngims

if time_double(time) gt time_double('2016-08-02/00:00') and kk3_anode then kk3 = [3.5,2.3,3.4,2.2]		;tbd**sta o2+ ok, checked 202002??, 3 ngims

	; 20160804  	end deep dip 6

if time_double(time) gt time_double('2016-08-04/00:00') and kk3_anode then kk3 = [3.3,2.6,3.2,2.0]		;**sta o2+ poor, checked 20200206, 3 ngims, att=2

if time_double(time) gt time_double('2016-08-08/00:00') and kk3_anode then kk3 = [3.0,1.9,2.9,1.4]		;tbd**sta o2+ ok, checked 202002??, 1 ngims

if time_double(time) gt time_double('2016-08-10/00:00') and kk3_anode then kk3 = [3.0,1.9,2.9,1.4]		;tbd**sta o2+ ok, checked 202002??, 1 ngims

if time_double(time) gt time_double('2016-08-12/00:00') and kk3_anode then kk3 = [3.0,1.9,2.9,1.4]		;tbd**sta o2+ ok, checked 202002??, 1 ngims

if time_double(time) gt time_double('2016-08-19/00:00') and kk3_anode then kk3 = [3.0,1.9,2.9,1.4]		;**sta o2+ ok, checked 20200206, 1 ngims

if time_double(time) gt time_double('2016-08-25/00:00') and kk3_anode then kk3 = [3.0,1.9,2.9,1.5]		;**sta o2+ poor, checked 20200205, 2 ngims, att=1-2

if time_double(time) gt time_double('2016-09-05/00:00') and kk3_anode then kk3 = [3.0,1.9,2.9,1.5]		;tbd**sta o2+ ok, checked 202002??, 3 ngims

if time_double(time) gt time_double('2016-09-11/00:00') and kk3_anode then kk3 = [3.0,1.9,2.9,1.5]		;**sta o2+ ok, checked 20200205, 2 ngims, att=1-2

if time_double(time) gt time_double('2016-09-14/00:00') and kk3_anode then kk3 = [2.7,2.0,2.6,1.4]		;**sta o2+ ok, checked 20200206, 2 ngims, att=1-3

	;  20160915	Nightside periapsis ends (started 20160615)

if time_double(time) gt time_double('2016-09-17/00:00') and kk3_anode then kk3 = [2.4,2.2,2.3,1.2]		;**sta o2+ ok, lpw calib, checked 20200129, att=1-3

if time_double(time) gt time_double('2016-10-05/00:00') and kk3_anode then kk3 = [2.5,2.3,2.4,1.5]		;**sta o2+ ok, lpw calib, checked 20200129, att=1-3

if time_double(time) gt time_double('2016-11-02/00:00') and kk3_anode then kk3 = [2.6,2.4,2.5,1.8]		;**sta o2+ ok, lpw calib, checked 20200129, att=1-3

if time_double(time) gt time_double('2016-11-03/00:00') and kk3_anode then kk3 = [2.6,2.4,2.5,1.8]		;**sta o2+ ok, lpw calib, checked 20200129, att=1-3

if time_double(time) gt time_double('2016-11-20/00:00') and kk3_anode then kk3 = [2.6,2.4,2.5,1.8]		;redue**sta o2+ ok, checked 202001??, att=0-3


	; 20161123 static saturation at periapsis due to high spacecraft charging
	; 20161227 static in protect mode due to high spacecraft charging
	; 20170131 static resumes normal ram mode at periapsis last orbit

if time_double(time) gt time_double('2017-01-31/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.2]		; assume the same as 2017-02-01

	; 20170201	mcp voltage increase 2870->3050V, 00:13UT

if time_double(time) gt time_double('2017-02-01/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.2]		;**sta o2+ ok, checked 20200127, att=1-3

if time_double(time) gt time_double('2017-02-16/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.0]		;**sta o2+ ok, checked 20200127, att=0-3

if time_double(time) gt time_double('2017-03-01/00:00') and kk3_anode then kk3 = [2.7,2.5,2.5,1.5]		;**sta o2+ ok, checked 20200126, att=0-3

if time_double(time) gt time_double('2017-03-15/00:00') and kk3_anode then kk3 = [2.6,2.2,2.5,1.5]		;**sta o2+ ok, checked 20200126, att=1-3

if time_double(time) gt time_double('2017-04-01/00:00') and kk3_anode then kk3 = [2.6,2.2,2.5,1.5]		;**sta o2+ ok, lpw calib, checked 20200126, att=1-3

if time_double(time) gt time_double('2017-04-16/00:00') and kk3_anode then kk3 = [2.7,2.3,2.6,1.7]		;**sta o2+ ok, lpw calib, checked 20200127, att=1-3

if time_double(time) gt time_double('2017-05-01/00:00') and kk3_anode then kk3 = [2.6,2.2,2.5,1.5]		;**sta o2+ ok, lpw calib, checked 20200125, att=0-3

if time_double(time) gt time_double('2017-05-08/00:00') and kk3_anode then kk3 = [2.6,2.0,2.5,1.5]		;**sta o2+ ok, checked 20200125, att=0-3

	; 20170510 static saturation at periapsis due to high spacecraft charging
	; 20170525 static in protect mode due to high spacecraft charging
	; 20170712 static in normal mode at periapsis

if time_double(time) gt time_double('2017-07-12/00:00') and kk3_anode then kk3 = [3.4,3.0,3.3,2.4]		;**sta o2+ ok, checked 20200125, att=2-3

if time_double(time) gt time_double('2017-07-16/00:00') and kk3_anode then kk3 = [3.4,3.0,3.3,2.4]		;**sta o2+ ok, checked 20200125, att=0-3

	; 20170717 static in protect mode during conjunction
	; 20170808 static HV turned off from zone alerts
	; 20170815 static HV enabled  

	; 20170815 start deep dip 7 periapsis lowered to 130km at 1UT,

if time_double(time) gt time_double('2017-08-15/00:00') and kk3_anode then kk3 = [3.4,3.0,3.3,2.4]		;**sta o2+ ok, checked 20200124, att=1-3

if time_double(time) gt time_double('2017-08-16/00:00') and kk3_anode then kk3 = [3.4,3.0,3.3,2.5]		;tbd**sta o2+ ok, checked 202001??, att=0-3

if time_double(time) gt time_double('2017-08-17/00:00') and kk3_anode then kk3 = [3.5,3.1,3.4,2.6]		;**sta o2+ ok, checked 20200124, att=1-3

if time_double(time) gt time_double('2017-08-22/00:00') and kk3_anode then kk3 = [3.6,3.2,3.5,2.7]		;**sta o2+ ok, checked 20200124, att=1-3

	; 20170823 periapsis raised  to 140km at 1UT, 

if time_double(time) gt time_double('2017-08-23/00:00') and kk3_anode then kk3 = [3.6,3.2,3.5,2.6]		;**sta o2+ ok, checked 20200124, att=1-3

	; 20170824 periapsis raised  to 150km at 1UT, end deep dip 7

if time_double(time) gt time_double('2017-08-24/00:00') and kk3_anode then kk3 = [3.4,3.1,3.3,2.4]		;tbd**sta o2+ ok, checked 202001??, att=0-3

if time_double(time) gt time_double('2017-08-25/00:00') and kk3_anode then kk3 = [3.1,2.9,3.0,2.2]		;**sta o2+ ok, lpw calib, checked 20200124, att=0-3, scpot<-2V @periapsis

if time_double(time) gt time_double('2017-08-26/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;tbd**sta o2+ ok, checked 202001??, att=0-3

if time_double(time) gt time_double('2017-08-28/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;tbd**sta o2+ ok, checked 202001??, att=0-3

if time_double(time) gt time_double('2017-09-01/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;**sta o2+ ok, lpw calib, checked 20200123, att=0-3

if time_double(time) gt time_double('2017-09-15/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;**sta o2+ ok, checked 20200123?, att=1-3

if time_double(time) gt time_double('2017-10-01/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;**sta o2+ ok, lpw calib, checked 20200123, att=0-3

if time_double(time) gt time_double('2017-10-14/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;**sta o2+ ok, checked 20200123, att=1-3

	; 20171016 start deep dip 8 periapsis lowered to 130km at 1UT, 

if time_double(time) gt time_double('2017-10-16/00:00') and kk3_anode then kk3 = [3.2,3.0,3.0,2.3]		;tbd**sta o2+ ok,  checked 202001??, att=1-3 

	; 20171017 periapsis lowered to 125km at 1UT, deep dip 8

if time_double(time) gt time_double('2017-10-17/00:00') and kk3_anode then kk3 = [3.3,3.2,3.2,2.5]		;**sta o2+ ok, lpw calib, checked 20200124, att=0-3 

if time_double(time) gt time_double('2017-10-19/00:00') and kk3_anode then kk3 = [3.5,3.2,3.4,2.6]		;**sta o2+ ok,  checked 20200124, att=2-3 

	; 20171022 walkout of deep dip 8  periapsis raised  to 140km at 1UT, 

if time_double(time) gt time_double('2017-10-22/00:00') and kk3_anode then kk3 = [3.6,3.2,3.5,2.7]		;**sta o2+ ok,  checked 20200123, att=1-3,

	; 20171023 walkout of deep dip 8  periapsis raised  to 150km at 1UT, 

if time_double(time) gt time_double('2017-10-23/00:00') and kk3_anode then kk3 = [3.6,3.2,3.5,2.7]		;**sta o2+ ok,  checked 20200123, att=1-3,

	; 20171024 end deep dip 8  periapsis raised  to 155km at 1UT, 

if time_double(time) gt time_double('2017-10-24/00:00') and kk3_anode then kk3 = [3.4,3.2,3.3,2.5]		;**sta o2+ ok,  checked 20200124, att=1-3, 

if time_double(time) gt time_double('2017-10-28/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;tbd**sta o2+ ok,  checked 202001??, att=2, terminator no att=3

if time_double(time) gt time_double('2017-11-01/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;**sta o2+ ok, lpw calib, checked 20200122, att=0-3, ratio changing

if time_double(time) gt time_double('2017-11-16/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;**sta o2+ ok, checked 20200123, att=1-3, ngi/sta 15% high on last periapsis

if time_double(time) gt time_double('2017-11-17/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;tbd**sta o2+ ok,  checked 202001??, att=2, terminator no att=3

if time_double(time) gt time_double('2017-11-21/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.0]		;tbd**sta o2+ ok,  checked 202001??, att=2, terminator no att=3

	; 20171122-20171124 mechanical attenuator left closed 

if time_double(time) gt time_double('2017-11-25/00:00') and kk3_anode then kk3 = [2.8,2.5,2.7,1.5]		;tbd**sta o2+ ok,  checked 202001??, att=2, terminator no att=3

if time_double(time) gt time_double('2017-12-01/00:00') and kk3_anode then kk3 = [2.8,2.5,2.7,1.5]		;**sta o2+ ok, lpw calib, checked 20200122, att=0-3

if time_double(time) gt time_double('2017-12-17/00:00') and kk3_anode then kk3 = [2.9,2.4,2.8,1.7]		;**sta o2+ ok, checked 20200123, att=1-3

if time_double(time) gt time_double('2018-01-01/00:00') and kk3_anode then kk3 = [3.1,2.2,3.0,2.0]		;**sta o2+ ok, lpw calib, checked 20200121, att=2, terminator no att=3

if time_double(time) gt time_double('2018-01-07/00:00') and kk3_anode then kk3 = [3.3,2.4,3.2,2.2]		;**sta o2+ poorly determined, checked 20200122, att=2-3, terminator

	; periapsis shifts to nightside 2018-01-10

if time_double(time) gt time_double('2018-01-15/00:00') and kk3_anode then kk3 = [3.5,2.6,3.4,2.5]		;**sta o2+ poorly determined, checked 20200121, att=1-2, no att=3

if time_double(time) gt time_double('2018-01-23/00:00') and kk3_anode then kk3 = [3.5,2.6,3.4,2.5]		;tbd**sta o2+ ok, checked 202001??, att=2, nightside no att=3

if time_double(time) gt time_double('2018-02-03/00:00') and kk3_anode then kk3 = [3.6,2.7,3.5,2.5]		;**sta o2+ ok, checked 20200120, att=2, nightside, no att=3

if time_double(time) gt time_double('2018-02-17/00:00') and kk3_anode then kk3 = [3.6,2.7,3.4,2.6]		;**sta o2+ ok, checked 20200120, att=1-2, nightside, no att=3

if time_double(time) gt time_double('2018-02-26/00:00') and kk3_anode then kk3 = [3.6,3.0,3.5,2.8]		;**sta o2+ ok, checked 20200122, att=1-2, nightside, no att=3

if time_double(time) gt time_double('2018-03-03/00:00') and kk3_anode then kk3 = [3.6,3.3,3.5,3.0]		;**sta o2+ ok, checked 20200120, att=1-3, nightside, no att=3

	; periapsis shifts to daytside 2018-01-10

if time_double(time) gt time_double('2018-03-17/00:00') and kk3_anode then kk3 = [3.5,3.1,3.4,2.9]		;**sta o2+ ok, checked 20200120, att=1-3, terminator

if time_double(time) gt time_double('2018-03-24/00:00') and kk3_anode then kk3 = [3.6,2.9,3.5,2.8]		;tbd**sta o2+ ok, checked 20200120, att=1-3, terminator

if time_double(time) gt time_double('2018-04-01/00:00') and kk3_anode then kk3 = [3.7,2.8,3.6,2.7]		;**sta o2+ ok, lpw calib, checked 20200119, att=1-3, 

if time_double(time) gt time_double('2018-04-02/00:00') and kk3_anode then kk3 = [3.7,2.8,3.6,2.7]		;**sta o2+ ok, checked 20200118, att=1-3, ngims varies 20%

if time_double(time) gt time_double('2018-04-10/00:00') and kk3_anode then kk3 = [3.6,2.9,3.5,2.8]		;**sta o2+ ok, checked 20200119, att=1-3

if time_double(time) gt time_double('2018-04-16/00:00') and kk3_anode then kk3 = [3.5,2.9,3.3,2.8]		;**sta o2+ ok, checked 20200119, att=1-3

if time_double(time) gt time_double('2018-04-19/00:00') and kk3_anode then kk3 = [3.3,2.8,3.1,2.7]		;tbd **sta o2+ ok, checked 20200119, att=1-3

if time_double(time) gt time_double('2018-04-21/00:00') and kk3_anode then kk3 = [3.2,2.7,2.9,2.6]		;**sta o2+ ok, checked 20200117, att=1-3

if time_double(time) gt time_double('2018-04-23/00:00') and kk3_anode then kk3 = [3.2,2.7,2.9,2.6]		;tbd**sta o2+ ok, checked 20200120, att=1-3

	; 20180424 start deep dip 9 periapsis lowered to 125km at 1UT, 

if time_double(time) gt time_double('2018-04-24/00:00') and kk3_anode then kk3 = [3.3,2.9,3.2,2.8]		;**sta o2+ ok, checked 20200120, att=1-3
if time_double(time) gt time_double('2018-04-25/00:00') and kk3_anode then kk3 = [3.4,2.9,3.3,2.9]		;tbd **sta o2+ ok, checked 20200119, att=1-3
if time_double(time) gt time_double('2018-04-26/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,3.0]		;tbd **sta o2+ ok, checked 20200119, att=1-3
if time_double(time) gt time_double('2018-04-27/00:00') and kk3_anode then kk3 = [3.5,3.1,3.5,3.1]		;**sta o2+ ok, checked 20200119, att=1-3

if time_double(time) gt time_double('2018-04-30/00:00') and kk3_anode then kk3 = [3.5,3.1,3.6,3.1]		;**sta o2+ ok, checked 20200119, att=1-3

	; 20180501 end deep dip 9  periapsis raised to 140km at 1UT, 

if time_double(time) gt time_double('2018-05-01/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,2.9]		;tbd **sta o2+ ok, checked 202001??, att=0-3, 

	; 20180502 periapsis raised to 160km at 3UT 

if time_double(time) gt time_double('2018-05-02/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.7]		;tbd **sta o2+ ok, checked 202001??, att=0-3, 

if time_double(time) gt time_double('2018-05-03/00:00') and kk3_anode then kk3 = [3.2,2.7,3.1,2.5]		;**sta o2+ ok, lpw calib, checked 20200115, att=0-3, ngims varies 20%

if time_double(time) gt time_double('2018-05-05/00:00') and kk3_anode then kk3 = [3.2,2.7,3.1,2.5]		;**sta o2+ ok, checked 20200117, att=0-3, ngims varies 20%

if time_double(time) gt time_double('2018-05-13/00:00') and kk3_anode then kk3 = [3.2,2.7,3.1,2.5]		;**sta o2+ ok, checked 20200115, att=0-3

if time_double(time) gt time_double('2018-05-22/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.3]		;**sta o2+ ok, checked 20200116, att=0-3

	; 20180523	STATIC mcp hv set to 2870V after a HV reset - not restored to 3050V until 20180828

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

	; 20180828	STATIC mcp hv restored to 3050V - set to 2870V after a HV reset on 20180523

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

if time_double(time) gt time_double('2019-04-05/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.4]		;**sta o2+ ok, checked 20200221, for att=1-3, pot=-2.4V

if time_double(time) gt time_double('2019-04-18/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.4]		;**sta o2+ ok, lpw calib, checked 20191230, for att=1-3

if time_double(time) gt time_double('2019-05-01/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.4]		;**sta o2+ ok, lpw calib, checked 20191227, for att=3

;if time_double(time) gt time_double('2019-05-03/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.4]		;tbd **sta o2+ ok, checked 2020????, for att=1-3, modulated density, use lower fp values

if time_double(time) gt time_double('2019-05-04/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.4]		;**sta o2+ ok, checked 20200221, for att=1-3, 

if time_double(time) gt time_double('2019-05-11/00:00') and kk3_anode then kk3 = [3.0,2.4,3.0,2.3]		;**sta o2+ ok, checked 20200222, 

if time_double(time) gt time_double('2019-05-15/00:00') and kk3_anode then kk3 = [3.3,2.5,3.2,2.4]		;**sta o2+ ok but some oddities, checked 20191226, lpw calib but density too low

if time_double(time) gt time_double('2019-05-18/00:00') and kk3_anode then kk3 = [3.3,2.5,3.2,2.4]		;**sta o2+ ok, checked 20200221, for att=1-3

	; 20190520 periapsis shifts to nightside 

if time_double(time) gt time_double('2019-05-21/00:00') and kk3_anode then kk3 = [3.4,2.8,3.3,2.4]		;**sta o2+ ok, checked 20200222,for att=1-3, 

if time_double(time) gt time_double('2019-05-24/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,2.4]		;**sta o2+ ok, ngi wind factor of 2 accum, checked 20200221, att=0-2

if time_double(time) gt time_double('2019-05-25/00:00') and kk3_anode then kk3 = [3.6,2.6,3.5,2.3]		;**sta o2+ ok agreement,checked 20191209

if time_double(time) gt time_double('2019-06-01/00:00') and kk3_anode then kk3 = [3.6,2.6,3.5,2.3]		;tbd, 
if time_double(time) gt time_double('2019-06-01/00:00') and kk3_anode then kk3 = [3.8,2.6,3.7,2.5]		;tbd, 

;if time_double(time) gt time_double('2019-06-06/00:00') and kk3_anode then kk3 = [3.7,2.6,3.6,2.4]		;tbd, 
;if time_double(time) gt time_double('2019-06-09/00:00') and kk3_anode then kk3 = [3.7,2.6,3.6,2.5]		;tbd, 
;if time_double(time) gt time_double('2019-06-12/00:00') and kk3_anode then kk3 = [3.7,2.6,3.6,2.5]		;tbd, 

if time_double(time) gt time_double('2019-06-17/00:00') and kk3_anode then kk3 = [3.7,2.6,3.6,2.5]		;**sta o2+ ok,checked 20191209, att=1-3 
if time_double(time) gt time_double('2019-06-18/00:00') and kk3_anode then kk3 = [3.7,2.6,3.6,2.5]		;**sta o2+ poor too variable,checked 20200223, att=1-2 

;if time_double(time) gt time_double('2019-06-20/00:00') and kk3_anode then kk3 = [3.8,2.6,3.7,2.5]		;tbd, 

if time_double(time) gt time_double('2019-06-22/00:00') and kk3_anode then kk3 = [3.6,2.5,3.5,2.5]		;**sta o2+ ok, checked 20200225, att=0-2

if time_double(time) gt time_double('2019-06-25/00:00') and kk3_anode then kk3 = [3.7,2.6,3.6,2.5]		;**sta o2+ ok, checked 20200225, att=0-2

;if time_double(time) gt time_double('2019-06-29/00:00') and kk3_anode then kk3 = [3.8,2.6,3.7,2.5]		;tbd, 

if time_double(time) gt time_double('2019-07-05/00:00') and kk3_anode then kk3 = [3.8,2.6,3.7,2.5]		;**sta o2+ ok, checked 20191203, att=2, 

;if time_double(time) gt time_double('2019-07-08/00:00') and kk3_anode then kk3 = [3.8,2.9,3.7,2.8]		;kk3 poorly determined, att=1-3

;if time_double(time) gt time_double('2019-07-16/00:00') and kk3_anode then kk3 = [3.8,3.1,3.7,3.0]		;kk3 poorly determined

if time_double(time) gt time_double('2019-07-19/00:00') and kk3_anode then kk3 = [3.8,3.1,3.7,3.0]		;tbd

;if time_double(time) gt time_double('2019-07-21/00:00') and kk3_anode then kk3 = [3.8,3.1,3.7,3.0]		;tbd

if time_double(time) gt time_double('2019-07-30/00:00') and kk3_anode then kk3 = [3.8,3.5,3.7,3.0]		;**sta o2+ ok, checked 20191127, 20200226, att=2, 

if time_double(time) gt time_double('2019-08-01/00:00') and kk3_anode then kk3 = [3.6,3.5,3.5,2.9]		;**sta o2+ ok, checked 20200226, att=1-2, 0V 

;if time_double(time) gt time_double('2019-08-02/00:00') and kk3_anode then kk3 = [3.5,3.2,3.4,2.8]		;**sta o2+ poor - not that well determined, checked 20191227, att=1-2, 20V lpw sweeps

	; 20190803 periapsis shifts to dayside 

if time_double(time) gt time_double('2019-08-06/00:00') and kk3_anode then kk3 = [3.3,3.0,3.2,2.8]		; **sta o2+ ok, checked 20191228, 20200226

;if time_double(time) gt time_double('2019-08-11/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		; tbd

;if time_double(time) gt time_double('2019-08-13/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		; tbd

if time_double(time) gt time_double('2019-08-14/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		;**sta o2+ ok, checked 20191125, lpw waves, ngi/sta varies +/-20%

if time_double(time) gt time_double('2019-08-17/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		;**sta o2+ ok, lpw waves, checked 20191115, 20200226

if time_double(time) gt time_double('2019-08-20/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.5]		;**sta o2+ ok, checked 20200226

	; 20190824 to 20190913 no periapsis data due to conjunction and maven safing

if time_double(time) gt time_double('2019-09-14/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.2]		;assume same as 20190918
if time_double(time) gt time_double('2019-09-14/00:00') and kk3_anode then kk3 = [3.3,2.8,3.2,2.7]		;tbd**sta o2+ ok, checked 20200309


if time_double(time) gt time_double('2019-09-18/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.2]		;**sta o2+ ok, checked 20190919, lpw waves, ngims high for some periapses
if time_double(time) gt time_double('2019-09-19/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.2]		;**sta o2+ ok, checked 20191125, lpw waves, ngims high for some periapses 
if time_double(time) gt time_double('2019-09-28/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.2]		;**sta o2+ ok, checked 20200227
if time_double(time) gt time_double('2019-09-30/00:00') and kk3_anode then kk3 = [3.0,2.5,2.9,2.2]		;**sta o2+ ok, checked 20191115, 20% ratio variations across orbits

	; 20191002 to 20191126 no periapsis ram data due to power requirements and fly+Z orientation causing s/c charging
	; STATIC put in protect mode to prevent saturtion due to fly(+Z) s/c attitude which causes charging to -20V
	; 20191106 periapsis shifts to nighside 
	; 20191126 nominal STATIC operations at periapsis

if time_double(time) gt time_double('2019-11-26/00:00') and kk3_anode then kk3 = [2.6,2.1,2.5,1.8]		;**sta o2+ ok, checked 20191203, 

if time_double(time) gt time_double('2019-12-08/00:00') and kk3_anode then kk3 = [2.8,2.1,2.7,1.8]		;**sta o2+ ok, checked 20191213,att=2-3

if time_double(time) gt time_double('2019-12-18/00:00') and kk3_anode then kk3 = [2.8,2.2,2.7,1.8]		;**sta o2+ ok, checked 20200102,

if time_double(time) gt time_double('2019-12-25/00:00') and kk3_anode then kk3 = [2.8,2.7,2.7,2.1]		;tbd**sta o2+ ok, checked 202001??,

	; 20191229 periapsis shifts back to dayside 

; note that 20200101 kk3 is not well determined due to -3V scpot														
if time_double(time) gt time_double('2020-01-01/00:00') and kk3_anode then kk3 = [3.1,3.0,3.0,2.4]		;**sta o2+ ok, lpw calib, att=3 could be 2.0-2.4 due to high scpot, checked 20200124, att=2-3
if time_double(time) gt time_double('2020-01-01/00:00') and kk3_anode then kk3 = [2.8,2.7,2.7,2.2]		;**sta o2+ revised, lpw calib, att=3 could be 2.0-2.4 due to high scpot, checked 20200124, att=2-3

if time_double(time) gt time_double('2020-01-12/00:00') and kk3_anode then kk3 = [2.8,2.7,2.7,2.2]		;**sta o2+ ok, checked 20200213, att=0-3

if time_double(time) gt time_double('2020-01-26/00:00') and kk3_anode then kk3 = [2.8,2.4,2.7,2.0]		;**sta o2+ ok, lpw calib, flyY/flyZ, checked 20200206, att=2-3

if time_double(time) gt time_double('2020-01-27/00:00') and kk3_anode then kk3 = [2.8,2.4,2.7,2.0]		;**sta o2+ ok, lpw calib, flyY/flyZ, checked 20200206, att=2-3

	; 20200212  	high spacecraft charging precludes low altitude measurements 
	; 20200212-25  	co2 mode, mech attenuator open at periapsis - may increase ion suppression
	; 20200226-0326?	protect mode at periapsis
	; 20200324	end fly+Z   	

if time_double(time) gt time_double('2020-03-24/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;assume same as 20200327

if time_double(time) gt time_double('2020-03-27/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ ok, checked 20200330, att=1-3

if time_double(time) gt time_double('2020-04-03/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ ok, checked 20230110, att=1-3
if time_double(time) gt time_double('2020-04-03/00:00') and kk3_anode then kk3 = [3.3,2.7,3.2,2.5]		;**sta o2+ ok, checked 20230110, att=1-3, sza=157, pot=-1

;if time_double(time) gt time_double('2020-04-09/00:00') and kk3_anode then kk3 = [3.3,2.7,3.2,2.5]		;tbd **sta o2+ ok, checked ??, att=1-3

;if time_double(time) gt time_double('2020-04-14/00:00') and kk3_anode then kk3 = [3.4,2.6,3.3,2.4]		;tbd **sta o2+ ok, checked ??, att=1-3

if time_double(time) gt time_double('2020-04-19/00:00') and kk3_anode then kk3 = [3.4,2.6,3.3,2.4]		;**sta o2+ ok, checked 20230110, att=1-2, sza=156, pot=-0.3

if time_double(time) gt time_double('2020-04-25/00:00') and kk3_anode then kk3 = [3.4,2.6,3.3,2.4]		;**sta o2+ ok, checked 20230111, att=1-3, pot=-0.3-1.0V

if time_double(time) gt time_double('2020-04-30/00:00') and kk3_anode then kk3 = [3.4,2.6,3.3,2.4]		;**sta o2+ ok, checked 20230110, att=1-3, sza=155, pot=-0.3

	; 20200501	periapsis allowed to drift higher   	

if time_double(time) gt time_double('2020-05-03/00:00') and kk3_anode then kk3 = [3.4,2.6,3.3,2.4]		;**sta o2+ ok, checked 20230110, att=1-3, sza=154, pot=-0.5-1.0

	; periapis shifts to dayside and scpot is <-2.7V causing NGIMS to overestimate density
	; use the flanks of periapsis for ngi/sta density ratios at pot>-2.7V for comparison

if time_double(time) gt time_double('2020-05-09/00:00') and kk3_anode then kk3 = [3.4,2.6,3.3,2.4]		;**sta o2+ poor-ok due to high pot, checked 20230111, att=1-3

if time_double(time) gt time_double('2020-05-10/00:00') and kk3_anode then kk3 = [3.4,2.6,3.3,2.4]		;**sta o2+ ok, checked 20230111, att=1-3

	; as STATIC moves into sunlight, density goes up and mech attenuator closes at higher altitude
	; reduced atomic oxygen exposure results in change in ion suppression
	; scpot also increases to <-2.7V at periasis which invalidates correction algorithms for ngi
	; for 20200511-20200529, calibrate ion suppression with ratio of ngi/sta density in the flanks where pot>-2.7V 

if time_double(time) gt time_double('2020-05-11/00:00') and kk3_anode then kk3 = [3.3,2.6,3.2,2.4]		; tbd guess

if time_double(time) gt time_double('2020-05-13/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ ok, checked ??, att=1-3
if time_double(time) gt time_double('2020-05-13/00:00') and kk3_anode then kk3 = [3.6,3.2,3.5,3.1]		;**sta o2+ error - use flanks with pot>-2.7V, att=1-3, pot=-3V
if time_double(time) gt time_double('2020-05-13/00:00') and kk3_anode then kk3 = [3.2,2.6,3.1,2.4]		;**sta o2+ ok, checked 20230111, att=1-3

if time_double(time) gt time_double('2020-05-14/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ ok, checked 20230111, att=1-3, pot=-3V
if time_double(time) gt time_double('2020-05-14/00:00') and kk3_anode then kk3 = [3.1,2.6,3.0,2.4]		;**sta o2+ ok-poor >-2.5V required, checked 20230111, att=1-3, pot=-3V

if time_double(time) gt time_double('2020-05-17/00:00') and kk3_anode then kk3 = [3.6,3.2,3.5,3.1]		;**sta o2+ bad, checked 20230111, att=1-3, pot=-3V
if time_double(time) gt time_double('2020-05-17/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ ok, checked 20230111, att=1-3, pot=-3V

if time_double(time) gt time_double('2020-05-19/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ good, lpw calib last orbit, checked 20230111, att=2-3, sza=158, pot=-2.5-3.5V

if time_double(time) gt time_double('2020-05-21/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ poor only one ngims, checked 20230111, att=1-3, pot=-3.3V

if time_double(time) gt time_double('2020-05-23/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ poor high scpot, checked 20230111, att=1-3, pot=-3.-3.5V

if time_double(time) gt time_double('2020-05-31/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ good, lpw calib, flyY/flyZ, checked 20200609

if time_double(time) gt time_double('2020-06-15/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ ok-just 2 orbits, checked 20230112, sza=176, pot=-2-2.9V,

if time_double(time) gt time_double('2020-06-27/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ ok, checked 20230112, sza=176, pot=-2-2.9V,

	; 2020-06-30 fly+Z causes s/c charging - no periapsis data for 7 weeks
	; use flank data for ion suppression estimates

if time_double(time) gt time_double('2020-07-02/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;**sta o2+ bad except for att transitions, checked 20230119 

if time_double(time) gt time_double('2020-07-06/00:00') and kk3_anode then kk3 = [2.9,2.4,2.9,2.4]		;**sta o2+ bad except for att transitions, checked 20230119 

;if time_double(time) gt time_double('2020-07-10/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;
if time_double(time) gt time_double('2020-07-10/00:00') and kk3_anode then kk3 = [2.9,2.4,2.9,2.4]		;**sta o2+ poor, checked 20230118, att=0-3, sza=47, alt=195, high s/c potential,

if time_double(time) gt time_double('2020-07-16/00:00') and kk3_anode then kk3 = [2.8,2.5,2.8,2.5]		;**sta o2+ poor, checked 20230118, att=0-3, sza=57, alt=196, high s/c potential

;if time_double(time) gt time_double('2020-07-24/00:00') and kk3_anode then kk3 = [3.0,2.6,2.9,2.3]		;
if time_double(time) gt time_double('2020-07-24/00:00') and kk3_anode then kk3 = [2.8,2.5,2.8,2.5]		;**sta o2+ poor, checked 20230118, high s/c potential,

	; 2020-08-04 periapsis data resumes

;if time_double(time) gt time_double('2020-08-04/00:00') and kk3_anode then kk3 = [2.8,2.5,2.8,2.5]		;tbd guess
;if time_double(time) gt time_double('2020-08-05/00:00') and kk3_anode then kk3 = [2.8,2.5,2.8,2.5]		;tbd poor

;if time_double(time) gt time_double('2020-08-09/00:00') and kk3_anode then kk3 = [3.0,3.1,3.1,3.1]		;tbd guess
;if time_double(time) gt time_double('2020-08-09/00:00') and kk3_anode then kk3 = [2.8,2.8,2.8,2.8]		;tbd guess
if time_double(time) gt time_double('2020-08-09/00:00') and kk3_anode then kk3 = [2.8,2.5,2.8,2.5]		;**sta o2+ poor, checked 20230118, att=0-3, 


;if time_double(time) gt time_double('2020-08-12/00:00') and kk3_anode then kk3 = [2.8,2.8,2.8,2.8]		;tbd **sta o2+ poor, checked ??, att=

;if time_double(time) gt time_double('2020-08-15/00:00') and kk3_anode then kk3 = [3.0,3.1,3.1,3.1]		;
;if time_double(time) gt time_double('2020-08-15/00:00') and kk3_anode then kk3 = [2.8,2.8,2.8,2.8]		;
if time_double(time) gt time_double('2020-08-15/00:00') and kk3_anode then kk3 = [2.8,2.5,2.8,2.5]		;**sta o2+ ok, checked 20230118, att=0-3, 

	; 2020-08-07 periapsis shifts to nighside 


	; 2020-08-18 end fly+Z 

;if time_double(time) gt time_double('2020-08-19/00:00') and kk3_anode then kk3 = [3.3,3.4,3.4,3.4]		;
if time_double(time) gt time_double('2020-08-19/00:00') and kk3_anode then kk3 = [3.0,3.1,3.1,3.1]		;**sta o2+ ok, checked 20230117, att=0-1

;if time_double(time) gt time_double('2020-08-25/00:00') and kk3_anode then kk3 = [3.3,3.4,3.4,3.4]		;
if time_double(time) gt time_double('2020-08-25/00:00') and kk3_anode then kk3 = [3.1,3.2,3.2,3.2]		;**sta o2+ ok, checked 20230117, att=1, best at 14:06

if time_double(time) gt time_double('2020-08-28/00:00') and kk3_anode then kk3 = [3.2,3.3,3.3,3.3]		;guess - assume linearly changing

if time_double(time) gt time_double('2020-08-30/00:00') and kk3_anode then kk3 = [3.3,3.4,3.4,3.4]		;**sta o2+ ok, checked 20230117

if time_double(time) gt time_double('2020-09-02/00:00') and kk3_anode then kk3 = [3.3,3.4,3.4,3.4]		;**sta o2+ poor, checked 20230117

;if time_double(time) gt time_double('2020-09-05/00:00') and kk3_anode then kk3 = [3.7,3.6,3.7,3.4]		;
;if time_double(time) gt time_double('2020-09-05/00:00') and kk3_anode then kk3 = [3.7,3.6,3.7,3.4]		;
if time_double(time) gt time_double('2020-09-05/00:00') and kk3_anode then kk3 = [3.4,3.5,3.5,3.5]		;**sta o2+ poor only one periapsis 19:50, checked 20230117

if time_double(time) gt time_double('2020-09-06/00:00') and kk3_anode then kk3 = [3.4,3.5,3.5,3.5]		;**sta o2+ poor only one periapsis 19:50, checked 20230117

;if time_double(time) gt time_double('2020-09-08/00:00') and kk3_anode then kk3 = [3.0,3.1,3.1,3.1]		; 
if time_double(time) gt time_double('2020-09-08/00:00') and kk3_anode then kk3 = [3.3,3.4,3.4,3.4]		;**sta o2+ ok nightside, checked 20230117, att=0-1

if time_double(time) gt time_double('2020-09-10/00:00') and kk3_anode then kk3 = [3.2,3.3,3.3,3.3]		;guess bad for testing - ngims wind scans

if time_double(time) gt time_double('2020-09-11/00:00') and kk3_anode then kk3 = [3.1,3.2,3.2,3.2]		;guess bad for testing - ngims wind scans

;if time_double(time) gt time_double('2020-09-12/00:00') and kk3_anode then kk3 = [3.3,3.1,3.2,3.0]		;
;if time_double(time) gt time_double('2020-09-12/00:00') and kk3_anode then kk3 = [3.4,3.3,3.4,3.1]		;
if time_double(time) gt time_double('2020-09-12/00:00') and kk3_anode then kk3 = [3.0,3.1,3.1,3.1]		;**sta o2+ mainly at 20:51, nightside, checked 20230116, att=0-2

;if time_double(time) gt time_double('2020-09-13/00:00') and kk3_anode then kk3 = [3.2,3.1,3.1,3.1]		;
if time_double(time) gt time_double('2020-09-13/00:00') and kk3_anode then kk3 = [3.0,3.1,3.1,3.1]		;**sta o2+ only at 20:51, nightside, checked 20230116, att=1

if time_double(time) gt time_double('2020-09-14/00:00') and kk3_anode then kk3 = [3.0,3.2,3.2,3.2]		;**sta o2+ poor checked 20230116

;if time_double(time) gt time_double('2020-09-16/00:00') and kk3_anode then kk3 = [3.1,2.9,3.0,2.8]		;
if time_double(time) gt time_double('2020-09-16/00:00') and kk3_anode then kk3 = [3.2,3.3,3.3,3.3]		;**sta o2+ poor checked 20230113

if time_double(time) gt time_double('2020-09-17/00:00') and kk3_anode then kk3 = [3.3,3.3,3.3,3.3]		;tbd - guess

;if time_double(time) gt time_double('2020-09-18/00:00') and kk3_anode then kk3 = [3.0,2.8,2.9,2.7]		;the inbound flank on 2 orbits should be the best
;if time_double(time) gt time_double('2020-09-18/00:00') and kk3_anode then kk3 = [3.3,3.2,3.3,3.0]		;
;if time_double(time) gt time_double('2020-09-18/00:00') and kk3_anode then kk3 = [3.4,3.3,3.4,3.1]		;
;if time_double(time) gt time_double('2020-09-18/00:00') and kk3_anode then kk3 = [3.5,3.4,3.4,3.4]		;
if time_double(time) gt time_double('2020-09-18/00:00') and kk3_anode then kk3 = [3.4,3.3,3.3,3.3]		;**sta o2+ ok, nightside, checked 20230117, att=1

;if time_double(time) gt time_double('2020-09-21/00:00') and kk3_anode then kk3 = [2.9,2.7,2.8,2.6]		;
;if time_double(time) gt time_double('2020-09-21/00:00') and kk3_anode then kk3 = [3.2,3.0,3.1,2.8]		; 
;if time_double(time) gt time_double('2020-09-21/00:00') and kk3_anode then kk3 = [3.7,3.6,3.6,3.6]		;
if time_double(time) gt time_double('2020-09-21/00:00') and kk3_anode then kk3 = [3.5,3.4,3.4,3.4]		;
if time_double(time) gt time_double('2020-09-21/00:00') and kk3_anode then kk3 = [3.3,3.2,3.2,3.2]		;**sta o2+ ok, nightside, checked 20230114, att=1-2,sza=112, periapsi=234

;if time_double(time) gt time_double('2020-09-22/00:00') and kk3_anode then kk3 = [3.2,3.0,3.1,2.8]		;
;if time_double(time) gt time_double('2020-09-22/00:00') and kk3_anode then kk3 = [3.4,3.3,3.4,3.1]		;
if time_double(time) gt time_double('2020-09-22/00:00') and kk3_anode then kk3 = [3.7,3.6,3.6,3.6]		;
if time_double(time) gt time_double('2020-09-22/00:00') and kk3_anode then kk3 = [3.5,3.4,3.4,3.4]		;**sta o2+ ok, nightside, checked 20230117, att=1-2,sza=112, periapsi=234

	; the rapid drop in ion suppression at this time is perhaps due to the shift of periapsis to the dayside
	; dayside periapsis has higher flux, larger mech attenuator engagagement, and therefore lower exposure to atomic oxygen

if time_double(time) gt time_double('2020-09-23/00:00') and kk3_anode then kk3 = [3.4,3.3,3.3,3.3]		;tbd 

if time_double(time) gt time_double('2020-09-24/00:00') and kk3_anode then kk3 = [3.4,3.3,3.3,3.3]		;**sta o2+ ok, nightside, checked 20230115, att=0-2, sza=108, periapsi=232

if time_double(time) gt time_double('2020-09-25/00:00') and kk3_anode then kk3 = [3.4,3.3,3.3,3.3]		;tbd check 00:30**

;if time_double(time) gt time_double('2020-09-26/00:00') and kk3_anode then kk3 = [3.1,2.7,3.0,2.4]		; first try bad for att=1,3
;if time_double(time) gt time_double('2020-09-26/00:00') and kk3_anode then kk3 = [3.1,2.9,3.0,2.8]		; improvement
if time_double(time) gt time_double('2020-09-26/00:00') and kk3_anode then kk3 = [3.1,3.0,3.0,3.0]		;**sta o2+ ok, terminator, checked 20230114, att=1-3, sza=104, periapsi=230

if time_double(time) gt time_double('2020-09-27/00:00') and kk3_anode then kk3 = [2.9,2.8,2.8,2.8]		;**sta o2+ ok, terminator, checked 20230114, att=0-2, sza=104, periapsi=230

if time_double(time) gt time_double('2020-09-28/00:00') and kk3_anode then kk3 = [2.7,2.6,2.6,2.6]		;tbd guess

;if time_double(time) gt time_double('2020-09-29/00:00') and kk3_anode then kk3 = [3.1,2.7,3.0,2.4]		;
if time_double(time) gt time_double('2020-09-29/00:00') and kk3_anode then kk3 = [2.7,2.4,2.4,2.4]		;**sta o2+ ok, terminator, checked 20230114, att=1-2, sza=100, periapsi=231
	; Note, mispointing APP 100deg at periapsis from ram on 20200929 at 16:22 may have caused momentary increase in ion suppression on following orbit

	; Note that the above nightside periapsis passes generally have poor cross-calibration due to non-steady and/or large beam deflections
	; 2020-09-30 periapsis shifts to dayside 

if time_double(time) gt time_double('2020-10-01/00:00') and kk3_anode then kk3 = [2.7,2.4,2.4,2.4]		;**sta o2+ poor, nightside, checked 20230111, att=1-2 periapsi=225

if time_double(time) gt time_double('2020-10-05/00:00') and kk3_anode then kk3 = [2.7,2.4,2.4,2.4]		;**sta o2+ ok, checked 20201223, periapsi=225

	; 2020-10-06 	start fly(-Z) - no ram horizontal, APP at mzu45 - s/c blocks NGIMS FOV

if time_double(time) gt time_double('2020-10-15/00:00') and kk3_anode then kk3 = [2.8,2.5,2.6,2.5]		; guess - assume linear change		

if time_double(time) gt time_double('2020-10-25/00:00') and kk3_anode then kk3 = [2.9,2.6,2.8,2.5]		; guess - assume linear change		

if time_double(time) gt time_double('2020-11-05/00:00') and kk3_anode then kk3 = [3.1,2.7,3.0,2.5]		; guess - assume linear change

	; 2020-11-17 	end   fly(-Z) - no ram horizontal, APP at mzu45 - s/c blocks NGIMS FOV

if time_double(time) gt time_double('2020-11-18/00:00') and kk3_anode then kk3 = [3.2,2.8,3.1,2.6]		;**sta o2+ ok, checked 20201226

if time_double(time) gt time_double('2020-11-25/00:00') and kk3_anode then kk3 = [3.2,2.8,3.1,2.6]		;**sta o2+ ok, checked 20201222

if time_double(time) gt time_double('2020-12-05/00:00') and kk3_anode then kk3 = [3.2,2.8,3.1,2.6]		;**sta o2+ ok, lpw calib, flyY/flyZ, checked 20220503

if time_double(time) gt time_double('2020-12-31/00:00') and kk3_anode then kk3 = [3.2,2.8,3.1,2.6]		;**sta o2+ ok, checked 20230123, att=1-3, periapsis=183, sza=89,

; This sudden increase in calculated ion suppression is appears to be due to exposure to atomic oxygen.
; On 20210101 at 0UT there was a periapsis pass with the APP-X pointed exactly in the anti-ram direction at ~180km 
; On 20210106 at 3UT there was a periapsis pass with the APP-X pointed exactly in the anti-ram direction at ~180km 
; There were no anti-ram pointings of the APP-X for the entire month of Dec 2020.
; Since the mechanical attenuator only functions in the APP-X hemisphere, there was maximum exposure to atomic oxygen on the above two orbits 
; This period was partly confusing because there was a change in s/c periapsis attitude from flyY->fly(-Z) on 20210112 and movement of periapsis to eclipse
; Both of these changes resulted in s/c potential changes from -3V prior to 20210112 to <-1V after the orientation change
; In addition, with these high potentials, it is difficult to accurately determine ion suppression using only NGIMS data if scpot<-2.5V
; This was also compounded by lack of NGIMS data from 20210105 to 20210110


;if time_double(time) gt time_double('2021-01-01/00:00') and kk3_anode then kk3 = [3.2,2.8,3.1,2.6]		;**sta o2+ ok, lpw calib fails, checked 20210303
;if time_double(time) gt time_double('2021-01-01/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.3]		;**sta o2+ ok, lpw calib fails, checked 20220504
if time_double(time) gt time_double('2021-01-01/00:00') and kk3_anode then kk3 = [3.4,2.9,3.3,2.8]		;**sta o2+ ok, lpw calib fails, checked 20230123

;if time_double(time) gt time_double('2021-01-02/00:00') and kk3_anode then kk3 = [3.2,2.8,3.1,2.6]		;**sta o2+ ok, checked 20210303
;if time_double(time) gt time_double('2021-01-02/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.3]		;**sta o2+ ok, checked 20220504
if time_double(time) gt time_double('2021-01-02/00:00') and kk3_anode then kk3 = [3.5,3.0,3.4,2.9]		;**sta o2+ ok, att=0-3, pot=-2-3V, checked 20230124

;if time_double(time) gt time_double('2021-01-04/00:00') and kk3_anode then kk3 = [3.2,2.8,3.1,2.6]		;**sta o2+ ok, checked 20220504
;if time_double(time) gt time_double('2021-01-04/00:00') and kk3_anode then kk3 = [3.6,3.0,3.5,3.0]		;**sta o2+ ok, checked 20220504
;if time_double(time) gt time_double('2021-01-04/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.3]		;**sta o2+ ok, checked 20220504
;if time_double(time) gt time_double('2021-01-04/00:00') and kk3_anode then kk3 = [3.4,2.9,3.3,2.8]		;**sta o2+ ok, checked 20230123
if time_double(time) gt time_double('2021-01-04/00:00') and kk3_anode then kk3 = [3.6,3.1,3.5,3.0]		;**sta o2+ ok, checked 20230123

; no ngims data 20210105 to 20210110

;if time_double(time) gt time_double('2021-01-11/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.3]		;**sta o2+ poor, checked 20220503, 
;if time_double(time) gt time_double('2021-01-11/00:00') and kk3_anode then kk3 = [3.7,3.2,3.7,3.1]		;**sta o2+ poor, checked 20230124, 
if time_double(time) gt time_double('2021-01-11/00:00') and kk3_anode then kk3 = [3.7,3.1,3.7,3.0]		;**sta o2+ poor, checked 20230124, 

;if time_double(time) gt time_double('2021-01-15/00:00') and kk3_anode then kk3 = [3.7,3.2,3.7,3.1]		; 
if time_double(time) gt time_double('2021-01-15/00:00') and kk3_anode then kk3 = [3.9,3.1,3.9,3.0]		;**sta o2+ poor - only one periapsis, att=2, checked 20230124, 

if time_double(time) gt time_double('2021-01-17/00:00') and kk3_anode then kk3 = [3.9,3.1,3.9,3.0]		;**sta o2+ ok, checked 20230124, att=1-2, pot=-0.3-2.0V, alt=183, sza=105, 

;if time_double(time) gt time_double('2021-01-19/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.0]		;**sta o2+ poor, checked 20210305
;if time_double(time) gt time_double('2021-01-19/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.3]		;**sta o2+ poor, checked 20220503, 
if time_double(time) gt time_double('2021-01-19/00:00') and kk3_anode then kk3 = [4.1,3.2,4.1,3.1]		;**sta o2+ poor, checked 20230124, 

;if time_double(time) gt time_double('2021-01-24/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.3]		;  checked 20230124, 
if time_double(time) gt time_double('2021-01-24/00:00') and kk3_anode then kk3 = [4.0,3.2,4.0,3.1]		;**sta o2+ poor, checked 20230124, 

if time_double(time) gt time_double('2021-01-28/00:00') and kk3_anode then kk3 = [4.0,3.4,4.0,3.2]		;**sta o2+ poor - only one orbit, checked 20230124, 

if time_double(time) gt time_double('2021-01-30/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.3]		;**sta o2+ ok, ngi calib, checked 20210303,20230123

if time_double(time) gt time_double('2021-02-03/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.3]		;**sta o2+ ok, ngi calib, checked 20220503

if time_double(time) gt time_double('2021-02-07/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.3]		;**sta o2+ ok, checked 20230124

if time_double(time) gt time_double('2021-02-09/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.3]		;**sta o2+ ok, ngi calib, checked 20210304

;if time_double(time) gt time_double('2021-02-15/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.0]		;**sta o2+ ok, ngi calib, checked 20210303
;if time_double(time) gt time_double('2021-02-15/00:00') and kk3_anode then kk3 = [3.9,3.3,3.9,3.3]		;**sta o2+ ok, ngi calib, checked 20220503
if time_double(time) gt time_double('2021-02-15/00:00') and kk3_anode then kk3 = [3.9,3.2,3.9,3.2]		;**sta o2+ ok, ngi calib, checked 20230123

	;  20210216  scenario 2b-  - Fly(-Z) with a 35deg nod. 
	; s/c reflected ions may deflect the ram beam, s/c pot and debye length are too small to deflect beam

;if time_double(time) gt time_double('2021-02-17/00:00') and kk3_anode then kk3 = [3.5,3.5,3.5,3.0]		;**sta o2+ ok, ngi calib, terminator, checked 20210302
;if time_double(time) gt time_double('2021-02-17/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.0]		;**sta o2+ ok, ngi calib, terminator, checked 20210302
if time_double(time) gt time_double('2021-02-17/00:00') and kk3_anode then kk3 = [3.9,3.3,3.9,3.3]		;**sta o2+ ok, ngi calib, terminator, checked 20220503,20220124

if time_double(time) gt time_double('2021-02-21/00:00') and kk3_anode then kk3 = [3.9,3.2,3.9,3.2]		;guess

if time_double(time) gt time_double('2021-02-25/00:00') and kk3_anode then kk3 = [4.0,3.5,4.0,3.0]		;**sta o2+ ok, terminator, checked 20220503
if time_double(time) gt time_double('2021-02-25/00:00') and kk3_anode then kk3 = [3.9,3.1,3.9,3.1]		;**sta o2+ ok, att=1-3, terminator, checked 20230124

;if time_double(time) gt time_double('2021-03-01/00:00') and kk3_anode then kk3 = [3.9,3.2,3.9,3.2]		;**sta o2+ ok, checked 20220503, att=0,2 suspect an imperfect droop correction 
if time_double(time) gt time_double('2021-03-01/00:00') and kk3_anode then kk3 = [3.9,3.2,3.9,3.2]		;**sta o2+ ok, checked 20230123, att=0,2  

;if time_double(time) gt time_double('2021-03-02/00:00') and kk3_anode then kk3 = [3.7,3.3,3.7,3.3]		;**sta o2+ ok, checked 20220502
;if time_double(time) gt time_double('2021-03-02/00:00') and kk3_anode then kk3 = [3.8,3.2,3.8,3.2]		;**sta o2+ ok, checked 20220502
if time_double(time) gt time_double('2021-03-02/00:00') and kk3_anode then kk3 = [3.9,3.2,3.9,3.2]		;**sta o2+ ok, lpw calib fails, checked 20220502

;if time_double(time) gt time_double('2021-03-06/00:00') and kk3_anode then kk3 = [3.8,3.2,3.8,3.2]		;
if time_double(time) gt time_double('2021-03-06/00:00') and kk3_anode then kk3 = [3.9,3.2,3.9,3.1]		;**sta o2+ ok, sza=72, alt=182, checked 20230405

if time_double(time) gt time_double('2021-03-08/00:00') and kk3_anode then kk3 = [3.8,3.2,3.8,3.1]		;**sta o2+ ok, sza=70, alt=180, checked 20230405

if time_double(time) gt time_double('2021-03-10/00:00') and kk3_anode then kk3 = [3.8,3.2,3.8,3.2]		;**sta o2+ ok, checked 20220505
if time_double(time) gt time_double('2021-03-10/00:00') and kk3_anode then kk3 = [3.6,3.1,3.6,3.1]		;**sta o2+ ok, checked 20220505

if time_double(time) gt time_double('2021-03-17/00:00') and kk3_anode then kk3 = [3.7,3.3,3.7,3.3]		;**sta o2+ ok, lpw calib, checked 20210322
if time_double(time) gt time_double('2021-03-17/00:00') and kk3_anode then kk3 = [3.6,3.2,3.6,3.2]		;**sta o2+ ok, lpw calib, checked 20220503

if time_double(time) gt time_double('2021-03-23/00:00') and kk3_anode then kk3 = [3.5,3.1,3.5,3.1]		;**sta o2+ ok, ngi calib, checked 20220505
if time_double(time) gt time_double('2021-03-23/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;**sta o2+ ok, ngi calib, checked 20220505

if time_double(time) gt time_double('2021-04-01/00:00') and kk3_anode then kk3 = [3.6,3.2,3.6,3.2]		;**sta o2+ ok, lpw calib, checked 20210405
if time_double(time) gt time_double('2021-04-01/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;**sta o2+ ok, lpw calib, checked 20210405
if time_double(time) gt time_double('2021-04-01/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.9]		;**sta o2+ ok, lpw calib, checked 20210405
if time_double(time) gt time_double('2021-04-01/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.9]		;**sta o2+ ok, lpw calib, checked 20220505, something odd about 5:25 periapsis

if time_double(time) gt time_double('2021-04-02/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.9]		;**sta o2+ ok, lpw calib, checked 20220505, suppression could be a bit larger

	; 20210405  end of scenario 2b-  - Fly(-Z) with a 35deg nod. 

	; 20210406  scenario 3  	20210406  Sun-Velocity 

	; 20210413  scenario 2  	20210413  fly-Y 

if time_double(time) gt time_double('2021-04-15/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.9]		;**sta o2+ ok, checked 20210425,20230405

if time_double(time) gt time_double('2021-04-19/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.9]		;**sta o2+ ok, ngi, lpw calib failed, flyY-flyZ, checked 20220509
if time_double(time) gt time_double('2021-04-19/00:00') and kk3_anode then kk3 = [3.5,3.0,3.5,3.0]		;**sta o2+ ok, ngi, sza=50, alt=186, flyY-flyZ, checked 20220509,20230405

if time_double(time) gt time_double('2021-04-27/00:00') and kk3_anode then kk3 = [3.3,2.8,3.3,2.8]		;**sta o2+ ok, ngi, sza=58, alt=189, scpot=-1.5-3V, checked 20230405

if time_double(time) gt time_double('2021-05-05/00:00') and kk3_anode then kk3 = [3.1,2.7,3.1,2.7]		;**sta o2+ ok, dayside, scpot=-2V, checked 20210518

if time_double(time) gt time_double('2021-05-11/00:00') and kk3_anode then kk3 = [2.9,2.5,2.9,2.5]		;**sta o2+ ok, dayside, scpot=-2V, checked 20210518
if time_double(time) gt time_double('2021-05-11/00:00') and kk3_anode then kk3 = [3.1,2.7,3.1,2.7]		;**sta o2+ ok, dayside, scpot=-2V, checked 20210518

if time_double(time) gt time_double('2021-05-14/00:00') and kk3_anode then kk3 = [3.1,2.7,3.1,2.7]		;**sta o2+ ok, dayside, scpot=-1-2V, checked 20230111

if time_double(time) gt time_double('2021-05-25/00:00') and kk3_anode then kk3 = [3.1,2.7,3.1,2.7]		;**sta o2+ poor, sza=91, scpot=-1-2V, att=0-3, checked 20220610

if time_double(time) gt time_double('2021-05-28/00:00') and kk3_anode then kk3 = [3.1,2.7,3.1,2.7]		;**sta o2+ very poor, sza=93, scpot=-1-2V, att=0-3, checked 20220611

	; iv4 fails 20210529?-0602?
	; 2021-06-01	periapsis at sza=97

if time_double(time) gt time_double('2021-06-01/00:00') and kk3_anode then kk3 = [3.1,2.7,3.1,2.7]		;**sta o2+ poor no bkg, att=0-2, terminator, scpot=--1-2V, checked 20220610

if time_double(time) gt time_double('2021-06-03/00:00') and kk3_anode then kk3 = [3.1,2.7,3.1,2.7]		;**sta o2+ poor, att=0-2, terminator, scpot=-1-2V, checked 20220610

	; 2021-06-06	some s/c shadow at periapsis 	

if time_double(time) gt time_double('2021-06-15/00:00') and kk3_anode then kk3 = [3.1,2.7,3.1,2.7]		;**sta o2+ poor, att=0-2, terminator, scpot=-1V, checked 20220610
if time_double(time) gt time_double('2021-06-15/00:00') and kk3_anode then kk3 = [3.1,2.9,3.1,2.8]		;**sta o2+ poor, att=0-2, terminator, scpot=-1V, checked 20220610

	; 2021-07-01	wk 346	scenario 2b fly(-Z) mzu0

if time_double(time) gt time_double('2021-07-02/00:00') and kk3_anode then kk3 = [3.1,2.7,3.1,2.7]		;**sta o2+ ok-poor, att=0-2, terminator, scpot=-1V, checked 20220610
if time_double(time) gt time_double('2021-07-02/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.8]		;**sta o2+ ok-poor, att=0-2, terminator, scpot=-1V, checked 20220610

if time_double(time) gt time_double('2021-07-07/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.8]		;**sta o2+ ok, att=0-2, terminator, scpot=0-1V, checked 20220611

	; 2021-07-08	scenario 2b fly(-Z) mzu35 - s/c charging deflects NGIMS FOV reduces sensitivity 
	; the below attempts at NGI-STA cross-calibration are suspect due to mzu35 and mzu45 changes in NGI sensitivity, no LPW fp due to high altitude
	; the NGI changes in sensitivity up to 20210904 appear to be due to ram ion deflection from s/c charging, moving ram flow away from NGIMS bore sight
	; Assume 20210707 measured kk3 is valid thru 20210904 where NGIMS sensitivity compromised and 

;if time_double(time) gt time_double('2021-07-08/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.8]		;**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610

;if time_double(time) gt time_double('2021-07-09/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.8]		;**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610

;if time_double(time) gt time_double('2021-07-23/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.8]		;**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610
;if time_double(time) gt time_double('2021-07-23/00:00') and kk3_anode then kk3 = [3.2,2.8,3.2,2.7]		;**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610
;if time_double(time) gt time_double('2021-07-23/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.8]		;**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610

;if time_double(time) gt time_double('2021-07-25/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.8]		;tbd**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610
;if time_double(time) gt time_double('2021-07-25/00:00') and kk3_anode then kk3 = [3.1,2.7,3.1,2.6]		;tbd**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610
;if time_double(time) gt time_double('2021-07-25/00:00') and kk3_anode then kk3 = [3.0,2.6,3.0,2.5]		;tbd**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610

;if time_double(time) gt time_double('2021-07-29/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.8]		;**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610
;if time_double(time) gt time_double('2021-07-29/00:00') and kk3_anode then kk3 = [3.0,2.6,3.0,2.5]		;**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610
;if time_double(time) gt time_double('2021-07-29/00:00') and kk3_anode then kk3 = [2.8,2.4,2.8,2.3]		;**sta o2+ ngi/sta=.95, 20% ngi blocked by s/c, att=0-2, terminator, scpot=-1V, checked 20220610

;if time_double(time) gt time_double('2021-08-01/00:00') and kk3_anode then kk3 = [2.7,2.3,2.7,2.3]		;tbd **sta o2+ ok, att=0-3, terminator, scpot=-2V, checked 20210518
;if time_double(time) gt time_double('2021-08-01/00:00') and kk3_anode then kk3 = [2.6,2.2,2.6,2.2]		;tbd **sta o2+ ok, att=0-3, terminator, scpot=-2V, checked 20210518

	; 2021-08-05 	start fly(-Z) - no ram horizontal, APP at mzu45 - s/c blocks/deflects NGIMS FOV
	; 20210901  LPW calib - density too low for lpw fp, ngims blocked by s/c
	; 2021-09-02 	end   fly(-Z) - no ram horizontal, APP at mzu45 - s/c blocks/deflects NGIMS FOV

	; no valid calibrations between 20210707 and 20210902
	; note that the difference between kk3 at 20210707 and 20210902 is tiny - at the determination level

if time_double(time) gt time_double('2021-09-02/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;assume 20210904 kk3 changed at this time 

if time_double(time) gt time_double('2021-09-04/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;**sta o2+ ok, scpot=-1.5-2.5V, att=0-3, sza=35, alt=215, checked 20210919,20220616

if time_double(time) gt time_double('2021-09-11/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;**sta o2+ ok, scpot=-1.5-2.5V, att=0-3, sza=45, alt=213, checked 20220616

if time_double(time) gt time_double('2021-09-19/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;**sta o2+ ok, scpot=-1.5-2.5V, att=0-3, sza=57, alt=209, checked 20220616

	; 20210926  LPW calib - density too low for lpw fp

if time_double(time) gt time_double('2021-09-26/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;**sta o2+ ok, no lpw, alt=202, dayside, scpot=-1.5-2.5V, checked 20220313

	; 20210929-20211028  No periapsis data due to commanding screwup 
	; 20211011  Periapsis moves into shadow 

if time_double(time) gt time_double('2021-10-29/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;**sta o2+ very poor, att=0-1, sza=133, alt=188, scpot=0-1V, checked 20220617

if time_double(time) gt time_double('2021-11-07/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;**sta o2+ very poor, att=0-1, sza=149, alt=184, scpot=0-1V, checked 20220617


if time_double(time) gt time_double('2021-11-20/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;tbd **sta o2+ very poor, att=0-1, sza=149, alt=184, scpot=0-1V, checked 20220617

if time_double(time) gt time_double('2021-12-04/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,2.8]		;tbd **sta o2+ very poor, att=0-1, sza=149, alt=184, scpot=0-1V, checked 20220617

if time_double(time) gt time_double('2021-12-13/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,2.8]		;**sta o2+ very poor, att=0-1, sza=122, alt=182, scpot=0-1V, checked 20220617

if time_double(time) gt time_double('2021-12-21/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,2.8]		;tbd **sta o2+ very poor, att=0-1, sza=, alt=, scpot=0-1V, checked 20220617

if time_double(time) gt time_double('2021-12-29/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,3.0]		;**sta o2+ very poor, att=0-1, sza=98, alt=182, scpot=0-1V, checked 20220617
if time_double(time) gt time_double('2021-12-29/00:00') and kk3_anode then kk3 = [3.4,3.0,3.4,2.8]		;**sta o2+ very poor, att=0-3, sza=98, alt=182, scpot=0-1V, checked 20220617


	; 20220101  Periapsis moves into sunlight 

if time_double(time) gt time_double('2022-01-01/00:00') and kk3_anode then kk3 = [3.5,3.1,3.5,3.1]		;
if time_double(time) gt time_double('2022-01-01/00:00') and kk3_anode then kk3 = [3.3,2.9,3.3,2.9]		;
if time_double(time) gt time_double('2022-01-01/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.8]		;**sta o2+ good, att=1-3, sza=95, alt=182, scpot=-2V, checked 20220331

if time_double(time) gt time_double('2022-01-07/00:00') and kk3_anode then kk3 = [3.5,3.1,3.5,3.1]		;
if time_double(time) gt time_double('2022-01-07/00:00') and kk3_anode then kk3 = [3.3,3.0,3.3,2.9]		;**sta o2+ ok, att=1-3, sza=86, alt=183, scpot=-1-2V, checked 20220331

if time_double(time) gt time_double('2022-01-16/00:00') and kk3_anode then kk3 = [3.5,3.1,3.5,3.0]		;**sta o2+ good, att=1-3, sza=77, alt=182, scpot=-1-2V, checked 20220331

if time_double(time) gt time_double('2022-01-24/00:00') and kk3_anode then kk3 = [3.5,3.1,3.5,3.1]		;**sta o2+ ok, lpw calib, scpot=-2V, checked 20220209

if time_double(time) gt time_double('2022-02-05/00:00') and kk3_anode then kk3 = [3.5,3.1,3.5,3.1]		;**sta o2+ good, sza=75, alt=181, scpot=-2V, checked 20220330

if time_double(time) gt time_double('2022-02-15/00:00') and kk3_anode then kk3 = [3.5,3.1,3.5,3.1]		;**sta o2+ ok, att=0-3, sza=85, alt=181, scpot=-2-3V, checked 20220330

if time_double(time) gt time_double('2022-02-20/00:00') and kk3_anode then kk3 = [3.5,3.1,3.5,3.1]		;tbd **sta o2+ ok, sza=?, alt=?, scpot=-2V, checked 2022??

	; 20220222	IMU-1 fails, MAVEN goes into safe mode, instruments off, sun-point

	; periapsis in shadow	

	; 20220422	Instrument turnon - STATIC in protect mode, no APP pointing, no NGIMS l2 data until 20220526

if time_double(time) gt time_double('2022-04-22/00:00') and kk3_anode then kk3 = [3.3,3.0,3.3,3.0]		;guess **sta o2+ ok, 

	; 20220427	first minimum all Stellar science, nominal STATIC, RAM at periapsis, APP pointing within 10-15 deg

	; missing ngims data 2022-04-27 to 2022-05-11 doesn't allow cross-calibration 

if time_double(time) gt time_double('2022-04-30/00:00') and kk3_anode then kk3 = [3.3,3.0,3.3,3.0]		;**sta o2+ poor but last orbit gives rough check
if time_double(time) gt time_double('2022-05-11/00:00') and kk3_anode then kk3 = [3.3,3.0,3.3,3.0]		;**sta o2+ poor but gives rough check

	; 20220526	ngims l2 data resumed, APP pointing restored last orbit	

if time_double(time) gt time_double('2022-05-26/00:00') and kk3_anode then kk3 = [3.3,3.0,3.3,3.0]		;tbd **sta o2+ ok, 

if time_double(time) gt time_double('2022-05-28/00:00') and kk3_anode then kk3 = [3.3,3.0,3.3,3.0]		;**sta o2+ ok, sza=104, alt=234, scpot=0-2V, checked 20230330 

	; 20220602  	periapsis at terminator	

if time_double(time) gt time_double('2022-06-04/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;**sta o2+ good, sza=100, alt=234, scpot=0-2V, checked 20230316 

if time_double(time) gt time_double('2022-06-16/00:00') and kk3_anode then kk3 = [3.5,3.1,3.5,3.1]		;
if time_double(time) gt time_double('2022-06-16/00:00') and kk3_anode then kk3 = [3.2,2.8,3.2,2.8]		;
if time_double(time) gt time_double('2022-06-16/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;**sta o2+ ok, sza=98, alt=235, scpot=-1.2V, checked 20220722

	; 20220623  periapsis at terminator	

if time_double(time) gt time_double('2022-07-11/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;**sta o2+ poor, sza=118, alt=228, scpot=0-3V, checked 20230316

if time_double(time) gt time_double('2022-07-23/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;**sta o2+ ok, sza=140, alt=220, scpot=0-1.5V, checked 20240505

if time_double(time) gt time_double('2022-08-05/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;**sta o2+ poor, sza=162, alt=210, scpot=0-2V, checked 20240506

if time_double(time) gt time_double('2022-08-16/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;**sta o2+ ok, sza=173, alt=203, scpot=0-3V, checked 20230316

	; 20220826-20220829  STATIC off	

if time_double(time) gt time_double('2022-09-05/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;
if time_double(time) gt time_double('2022-09-05/00:00') and kk3_anode then kk3 = [2.7,2.4,2.7,2.4]		;**sta o2+ poor, sza=136, alt=193, scpot=0-2V, checked 20230316

if time_double(time) gt time_double('2022-09-07/00:00') and kk3_anode then kk3 = [2.7,2.4,2.7,2.4]		;**sta o2+ ok, sza=132, alt=191, scpot=0-1.5V, checked 20240505

if time_double(time) gt time_double('2022-09-09/00:00') and kk3_anode then kk3 = [2.7,2.4,2.7,2.4]		;**sta o2+ ok, att=0-2, sza=127, alt=190, scpot=0-1.5V, checked 20230317

if time_double(time) gt time_double('2022-09-10/00:00') and kk3_anode then kk3 = [2.8,2.5,2.8,2.5]		;**sta o2+ good, sza=125, alt=190, scpot=0-1.5V, checked 20240505

if time_double(time) gt time_double('2022-09-11/00:00') and kk3_anode then kk3 = [3.0,2.7,3.0,2.7]		;**sta o2+ ok, sza=125, alt=189, scpot=0-1.5V, checked 20230317

	; 20220912 it appears that kk3 increased during this day, and the value below reflects the last periapsis

if time_double(time) gt time_double('2022-09-12/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;**sta o2+ ok, sza=122, alt=189, scpot=0-1V, checked 20230316

if time_double(time) gt time_double('2022-09-24/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;**sta o2+ good, sza=99, alt=185, scpot=0-3V, checked 20230316 

	; 20220924  periapsis at terminator	

if time_double(time) gt time_double('2022-10-03/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;**sta o2+ ok, lpw calib, sza=84, alt=184, scpot=-3V, checked 20221005, ion suppression correction only about 30%

if time_double(time) gt time_double('2022-10-28/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;**sta o2+ ok, lpw calib, flyY/fly(-Z), sza=55, alt=181, scpot=-2.3/-0.4V, checked 20221103, 

	; 20221104  MAVEN uses fly+Z, sc charging, Static in protect mode - no calibrations possible
	; 20221216  MAVEN uses fly+Z, sc charging but in shadow reduces, Static switches back to science mode 

if time_double(time) gt time_double('2022-12-16/00:00') and kk3_anode then kk3 = [3.7,3.4,3.7,3.4]		;**sta o2+ assume same as 12-17, 
if time_double(time) gt time_double('2022-12-17/00:00') and kk3_anode then kk3 = [3.7,3.4,3.7,3.4]		;**sta o2+ poor, sza=126, alt=181, scpot=0-1V, checked 20230310

if time_double(time) gt time_double('2022-12-21/00:00') and kk3_anode then kk3 = [3.7,3.4,3.7,3.4]		;**sta o2+ poor, sza=126, alt=181, scpot=0-1V, checked 20230310

if time_double(time) gt time_double('2022-12-26/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		;
if time_double(time) gt time_double('2022-12-26/00:00') and kk3_anode then kk3 = [3.7,3.4,3.7,3.4]		;**sta o2+ poor, sza=126, alt=181, scpot=0-1V, checked 20230310

if time_double(time) gt time_double('2023-01-04/00:00') and kk3_anode then kk3 = [3.7,3.4,3.7,3.4]		;**sta o2+ ok, sza=138, alt=181, scpot=-0.5-2V, only two periapsis, checked 20230309

if time_double(time) gt time_double('2023-01-08/00:00') and kk3_anode then kk3 = [3.8,3.5,3.8,3.5]		;**sta o2+ poor, sza=143, alt=181, scpot=-0.5-2V, checked 20240505

if time_double(time) gt time_double('2023-01-11/00:00') and kk3_anode then kk3 = [3.9,3.6,3.9,3.6]		;**sta o2+ ok, sza=144, alt=183, scpot=-0.5-2V, only one periapsis, checked 20230309

if time_double(time) gt time_double('2023-01-15/00:00') and kk3_anode then kk3 = [4.0,3.7,4.0,3.7]		;**sta o2+ ok, sza=143, alt=183, scpot=-0.5-2V, checked 20240505 

if time_double(time) gt time_double('2023-01-18/00:00') and kk3_anode then kk3 = [4.1,3.8,4.1,3.8]		;**sta o2+ ok, sza=141, alt=184, scpot=-0.5-2V, checked 20240505 

if time_double(time) gt time_double('2023-01-20/00:00') and kk3_anode then kk3 = [4.2,3.9,4.2,3.9]		;**sta o2+ ok, sza=140, alt=184, scpot=-0.5-2V, checked 20230309 

if time_double(time) gt time_double('2023-02-02/00:00') and kk3_anode then kk3 = [4.4,4.1,4.4,4.1]		;
if time_double(time) gt time_double('2023-02-02/00:00') and kk3_anode then kk3 = [4.2,3.9,4.2,3.9]		;**sta o2+ ok, sza=126, alt=187, scpot=-0.5-2V, checked 20230309 


if time_double(time) gt time_double('2023-02-09/00:00') and kk3_anode then kk3 = [3.5,3.3,3.5,3.2]		;
if time_double(time) gt time_double('2023-02-09/00:00') and kk3_anode then kk3 = [4.0,3.8,4.0,3.7]		; 
if time_double(time) gt time_double('2023-02-09/00:00') and kk3_anode then kk3 = [4.4,4.1,4.4,4.1]		;**sta o2+ ok, sza=114, alt=193, scpot=-1V, checked 20230308 

if time_double(time) gt time_double('2023-02-15/00:00') and kk3_anode then kk3 = [4.4,4.1,4.4,4.1]		; 
if time_double(time) gt time_double('2023-02-15/00:00') and kk3_anode then kk3 = [4.0,3.8,4.0,3.7]		;**sta o2+ ok, sza=103, alt=193, scpot=-1-3V, checked 20230308 

	; 20230216  MAVEN goes into safe mode during attempted orbit correction, instruments off
	; 20230221  Maven fully recovered from safe mode - PF powered on, STATIC in protect mode
	; 20230224  STATIC in science mode

if time_double(time) gt time_double('2023-02-24/00:00') and kk3_anode then kk3 = [4.4,4.1,4.4,4.1]		; 
if time_double(time) gt time_double('2023-02-24/00:00') and kk3_anode then kk3 = [3.8,3.6,3.8,3.5]		;**sta o2+ good, sza=87, alt=200, scpot=-1-2V, checked 20230308 

	; relay APP orientation is anti-ram at this time - may explain the higher kk3

;if time_double(time) gt time_double('2023-02-26/00:00') and kk3_anode then kk3 = [3.7,3.5,3.7,3.4]		;**sta o2+ ok, sza=84, alt=200, scpot=-2V, checked 20240504 
if time_double(time) gt time_double('2023-02-26/00:00') and kk3_anode then kk3 = [3.8,3.6,3.8,3.5]		;**sta o2+ good, sza=84, alt=200, scpot=-2V, checked 20240505 

;if time_double(time) gt time_double('2023-02-28/00:00') and kk3_anode then kk3 = [3.6,3.4,3.6,3.3]		;**sta o2+ ok, sza=80, alt=201, scpot=-2V, checked 20240504 
if time_double(time) gt time_double('2023-02-28/00:00') and kk3_anode then kk3 = [3.8,3.6,3.8,3.5]		;**sta o2+ good, sza=80, alt=201, scpot=-2V, checked 20240505 

if time_double(time) gt time_double('2023-03-01/00:00') and kk3_anode then kk3 = [3.6,3.4,3.6,3.3]		;**sta o2+ good, sza=79, alt=202, scpot=-2V, checked 20240505 

if time_double(time) gt time_double('2023-03-02/00:00') and kk3_anode then kk3 = [3.2,2.9,3.2,2.9]		; 
if time_double(time) gt time_double('2023-03-02/00:00') and kk3_anode then kk3 = [3.5,3.3,3.5,3.2]		;**sta o2+ good, sza=77, alt=202, scpot=-2V, checked 20230306,20240505 

if time_double(time) gt time_double('2023-03-09/00:00') and kk3_anode then kk3 = [3.5,3.3,3.5,3.2]		;**sta o2+ good, sza=64, alt=207, scpot=-2V, checked 20230313 


if time_double(time) gt time_double('2023-04-04/00:00') and kk3_anode then kk3 = [3.5,3.3,3.5,3.2]		;**sta o2+ good, sza=36, alt=225, scpot=-1.5-2.5V, checked 20240503 


if time_double(time) gt time_double('2023-06-30/00:00') and kk3_anode then kk3 = [3.5,3.3,3.5,3.2]		;**sta o2+ ok, sza=97, alt=213, scpot=-2V, checked 20230806 

if time_double(time) gt time_double('2023-07-26/00:00') and kk3_anode then kk3 = [3.5,3.3,3.5,3.2]		;**sta o2+ good, sza=73, alt=198, scpot=-1-2.3V, flyY/flyZ checked 20230806 

	; 20230804-20230821  fly(+Z) s/c charging cross calibration not possible
	; 20230821-20230831  STATIC HV trip off - no STATIC data
	; 20230831-20231102  fly(+Z) s/c charging cross calibration not possible
	; 20231005  Periapsis moves into shadow - poor for NGIMS calibration
	; 20231108-20231201  Conjunction, Static in protect mode - no calibrations possible
	; 20231202 Periapsis shifts to sunlit, at eclipse boundary near dusk terminator

if time_double(time) gt time_double('2023-12-01/00:00') and kk3_anode then kk3 = [3.7,3.5,3.7,3.4]		;Assume the same as 20231214

if time_double(time) gt time_double('2023-12-05/00:00') and kk3_anode then kk3 = [3.5,3.3,3.5,3.2]		;**sta o2+ good, sza=92, alt=185, scpot=-1.5to-3V, flyY checked 20231218 
if time_double(time) gt time_double('2023-12-05/00:00') and kk3_anode then kk3 = [3.7,3.5,3.7,3.4]		;**sta o2+ good, sza=92, alt=185, scpot=-1.5to-3V, flyY checked 20231220, cross-track wind can slightly reduce NGIMS ion density 

if time_double(time) gt time_double('2023-12-14/00:00') and kk3_anode then kk3 = [3.5,3.3,3.5,3.2]		;**sta o2+ good, sza=77, alt=186, scpot=-.5V, fly(-Z) checked 20231219 
if time_double(time) gt time_double('2023-12-14/00:00') and kk3_anode then kk3 = [3.7,3.5,3.7,3.4]		;**sta o2+ good, sza=77, alt=186, scpot=-.5V, LPW wave calib, fly(-Z) checked 20231219 

if time_double(time) gt time_double('2024-01-15/00:00') and kk3_anode then kk3 = [3.7,3.5,3.7,3.4]		;**sta o2+ good, sza=19, alt=196, scpot=-2.5V, checked 20240501 

	; 20240118-202403014  fly(+Z) or Sun-Velocity s/c charging cross calibration not possible

if time_double(time) gt time_double('2024-01-27/00:00') and kk3_anode then kk3 = [3.6,3.4,3.6,3.3]		;assume linear in time variation for kk3
if time_double(time) gt time_double('2024-01-08/00:00') and kk3_anode then kk3 = [3.5,3.3,3.5,3.2]		;assume linear in time variation for kk3 
if time_double(time) gt time_double('2024-01-19/00:00') and kk3_anode then kk3 = [3.4,3.2,3.4,3.1]		;assume linear in time variation for kk3 
if time_double(time) gt time_double('2024-01-03/00:00') and kk3_anode then kk3 = [3.3,3.1,3.3,3.0]		;assume linear in time variation for kk3 

	; 20240311 periapsis moves to nightside -- cross calibration poor

if time_double(time) gt time_double('2024-03-15/00:00') and kk3_anode then kk3 = [3.2,3.0,3.2,2.9]		;**sta o2+ poor, sza=107, alt=235, scpot=-1-3V, checked 20240501

if time_double(time) gt time_double('2024-03-21/00:00') and kk3_anode then kk3 = [3.2,3.0,3.2,2.9]		;**sta o2+ poor, sza=115, alt=236, scpot=-1-3V, checked 20240501

if time_double(time) gt time_double('2024-04-18/00:00') and kk3_anode then kk3 = [3.2,3.0,3.2,2.9]		;**sta o2+ poor, sza=116, alt=236, scpot=-1-2V, checked 20240501

;if time_double(time) gt time_double('2024-04-28/00:00') and kk3_anode then kk3 = [3.7,3.5,3.7,3.4]		;**sta o2+ kk3 too high
if time_double(time) gt time_double('2024-04-28/00:00') and kk3_anode then kk3 = [3.2,3.0,3.2,2.9]		;**sta o2+ good, sza=103, alt=233, scpot=-1V, checked 20240501 

	; 20240429 periapsis moves to dayside 

tt=timerange()
store_data,'mvn_sta_kk3',data={x:tt,y:transpose([[kk3],[kk3]])}

return,kk3

end






