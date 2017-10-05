;+
; NAME:
;     GSM2LMN_WRAP
;
; PURPOSE:
;	Wrapper transforms vector field from GSM to LMN (boundary-normal)
;	coordinate system for magnetopause with help of routine gsm2lmn.pro.
;	It gets the necessary solar wind data with help of routine
;	solarwind_load.pro and passes all necessary keywords to it.
;
; CATEGORY:
;	Coordinate Transformation
;
; CALLING SEQUENCE:
;	gsm2lmn_wrap,txyz,Bxyz,Blmn,SWkeywords
;
; INPUTS:
;	txyz: | t | x  | y  | z | - time and position of the input vector (Bxyz).
;           - 2D array (nvectors,4)
;	Bxyz: | Bx | By | Bz | - vector field to transform (in GSM).
;           - 2D array (nvectors,3)
;
; KEYWORDS: Solarwind_load.pro keywords (Any combination of keywords defining
;           output of solarwind_load.pro)
;
; PARAMETERS: none
;
; OUTPUTS:
;	Blmn: | Bl | Bm | Bn | - vector in LMN at the same space-time points.
;		- 2D array (nvectors,3)
;
; DEPENDENCIES: gsm2lmn.pro, solarwind_load.pro. Intermediate-level part of LMN
;		transform package.
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2007/12/28
;-
;
; THE CODE BEGINS:

pro gsm2lmn_wrap,txyz,bxyz,blmn,_Extra=ex

sizetxyz=size(txyz)
nt=sizetxyz(1)
t1=txyz(0,0)
t2=txyz(nt-1,0)
trange=[t1,t2]

solarwind_load,swdata,dst,trange,_Extra=ex
gsm2lmn,txyz,bxyz,blmn,swdata
dprint, 'gsm2lmn_wrap finished'

return
end
