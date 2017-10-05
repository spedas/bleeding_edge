;+
; FUNCTION:	auroral_zone
;
; PURPOSE:	IDL function to calculate auroral zone position as a 
;		function of magnetic local time (mlt: 0.0-24.0 hours), 
;		activity index Q (q: 0-6).
;		Returns corrected geomagnetic colatitude in radians.
;
; OPTIONS:	To return poleward edge, set poleward.
;		To return latitude, set latitude.
;		To return value for southern oval, set south.
;		To return value in degrees, set degrees.
;
; See Holzworth & Meng, GRL 2, p. 377, 1975.
;
; Originally written by J. Clemmons, June 1993.
; Corrected by J.Rauchleiba under the direction of Mike Temerin Apr 1997.
;-

function auroral_zone, mlt, q, $
	poleward=pole, $
	latitude=lat, $
	south=south, $
	degrees=deg

; Arrays are indexed (An, Q) where An is the nth
; best-fit constant and Q is the activity index
; n =	  0    1    2     3    4    5    6
apole=[[15.22,2.41,3.34,-0.85,1.01,0.32,0.90], $
       [15.85,2.70,3.32,-0.67,1.15,0.49,1.00], $
       [16.09,2.51,3.27,-0.56,1.30,0.42,0.94], $
       [16.16,1.92,3.14,-0.46,1.43,0.32,0.96], $
       [16.29,1.41,3.06,-0.09,1.35,0.40,1.03], $
       [16.44,0.81,2.99,0.14,1.25,0.48,1.05], $
       [16.71,0.37,2.90,0.63,1.59,0.60,1.00]]
aequa=[[17.36,3.03,3.46,0.42,2.11,-0.25,1.13], $
       [18.66,3.90,3.37,0.16,2.55,-0.13,0.96], $
       [19.73,4.69,3.34,-0.57,-1.41,-0.07,0.75], $
       [20.63,4.95,3.31,-0.66,-1.28,0.30,-0.58], $
       [21.56,4.93,3.31,-0.44,-0.81,-0.07,-0.75], $
       [22.32,4.96,3.29,-0.39,-0.72,-0.16,-0.52], $
       [23.18,4.85,3.34,-0.38,-0.62,-0.53,-0.16]]

; Columns 0, 1, 3, 5 in above arrays are in degrees.
; Columns 2, 4, 6 (args to cos function) are already in radians.

Andeg = [0,1,3,5]	; The An that are in degrees
apole(Andeg,*) = !dtor * apole(Andeg,*)
aequa(Andeg,*) = !dtor * aequa(Andeg,*)

; Phi relative to Sun pointer, in terms of MLT
; Since Holzworth mentions a different definition of phi(MLT)

p=(mlt-12.)/12.0*!pi

; Force i=q to within interval [0,6]

i=(fix(q)>0)<6

; Calculate corrected geomagnetic colattitude

if keyword_set(pole) then begin
  t=apole(0,i) + $
    apole(1,i)*cos(p+apole(2,i)) + $
    apole(3,i)*cos(2*(p+apole(4,i))) + $
    apole(5,i)*cos(3*(p+apole(6,i)))
endif else begin
  t=aequa(0,i) + $
    aequa(1,i)*cos(p+aequa(2,i)) + $
    aequa(3,i)*cos(2*(p+aequa(4,i))) + $
    aequa(5,i)*cos(3*(p+aequa(6,i)))
endelse

; Convert to magnetic lattitude

if keyword_set(lat) then t=!pi/2.0-t

; Southern auroral zone is merely a reflection

if keyword_set(south) then t=-t

; Conver to degrees if desired

if keyword_set(deg) then t=t*!radeg

return,t
end
