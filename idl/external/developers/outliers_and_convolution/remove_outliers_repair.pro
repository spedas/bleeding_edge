;+
; NAME:
;     REMOVE_OUTLIERS_REPAIR
;
; PURPOSE:
;	Routine repairs outliers. Quadratic trend is determined in a hollow
;	vicinity of each point. The data value is compared with the trend 
;	value. If the deviation is statistically improbable, the value is 
;	repaired. There are 6 options for repair.
;
; CATEGORY:
;	Data Processing
;
; CALLING SEQUENCE:
;	repair, valneib, tneib, valiin, nmax, valiout
;
; INPUTS:
;	VALNEIB: array of the data values in the hollow vicinity of the point.
;  TNEIB: array of the observation times for the above values.
;  VALIIN: the value to filter.
;  NMAX: maximal probable deviation from the average in units of standard 
;           deviation
;
; KEYWORDS: None
;
; PARAMETERS: The code has one parameter "sch" setting the way outlier is 
;		repaired.
;
; OUTPUTS:
;	VALIOUT: filtered value.
;
; DEPENDENCIES: None. Called by remove_outliers.pro
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2007/12/28.
;-
;
; THE CODE BEGINS:

pro remove_outliers_repair,valneib,tneib,valiin,nmax,valiout

;Set the way outlier is repaired (see cases below):
sch=5

valiout=valiin

;Find the (quadratic) trend:
dim=n_elements(valneib)
if dim le 1 then return; - not enough points for evaluation
coefs=svdfit(tneib,valneib,3,yfit=modys,/double)
valdev=sqrt(total((valneib-modys)^2)/(dim-1))
valmn=coefs[0]

;apply criteria
allowed=nmax*valdev
uplim=valmn+allowed
lowlim=valmn-allowed
if abs(valiin-valmn) gt allowed then begin
  case sch of
    0: if valiin gt uplim then valiout=uplim else if valiin lt lowlim then valiout=lowlim
    1: valiout=interpol(valneib,tneib,0.) ; linear
    2: valiout=interpol(valneib,tneib,0.,/quadratic)
    3: valiout=interpol(valneib,tneib,0.,/lsquadratic)
    4: valiout=interpol(valneib,tneib,0.,/spline)
    5: valiout=valmn
  endcase
endif

return
end
