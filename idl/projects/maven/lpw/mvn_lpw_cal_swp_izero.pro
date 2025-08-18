
function mvn_lpw_cal_swp_izero,potential,icurr_in,izero,swpn

; this function take the masured current and remove the impact the 
; voltage sweep has on the current
; it operated in digiran numbers (DN)
; if izero is a value that offset is also removed (the stray current from the board measured in the PAS subcycle)
; the value below is based on 
; the following clibration file:
; dir='....../2012-07-18-calib_data/'
; file='cal_swp1_64_20120719_120958_telemetry.dat'   ; dynamic offset disable & 64 sec sweep
; based on this the linear correction at 40 V is ~220-270 DN  and ~32 DN for the quadratic term
; Boom1 uncertanty is +-10 and the tail end of the positive side is +-30 DN
; boom2 uncetranty is +- 20 DN and the tail end on the positive side +-30 DN

; this is updated with some more accuracy on the slope, 
; modified by L. Andersson on 31 Jannuary 2014
;based on no current in shadow the slope might need to be larger.
;with more data this needs to be reevaluated


if swpn EQ 1 then begin ; this is for boom 1
  slope=-5.68  ;[DN]
  offset= (612.+800)*0. ;[DN]
  quadrat_n=-0.01   ;negative side
  quadrat_p= -0.02   ;positive side
endif else begin   ; this is for boom 2
  slope=-6.68  ;[DN]
  offset=(3925.*0+00)*0.  ;[DN]
  quadrat_n=+0.02   ;negative side
  quadrat_p=-0.00   ;positive side
endelse

 
  
   icurr_out = icurr_in  - slope*potential -izero + quadrat_p*potential^2*(potential GT 0) + quadrat_n*potential^2*(potential LT 0) -offset*(izero NE 0)
  
  return,icurr_out

end

